{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module ManageCards.Deduplicate
  ( groupCards
  , determineCardCategory
  , beastMonsters
  , assignUniqueSlugs
  , toConceptKey
  , ConceptKey
  ) where

import Core.Card (CoreCard (..), Stats (..))
import Core.DSL (toText)
import Core.Glossary (toSlug)
import Core.NonEmptyText (getRawText)
import Data.List (sortOn)
import Data.List.NonEmpty qualified as NE
import Data.Map.Strict qualified as Map
import Data.Ord (Down (..))
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as T
import System.FilePath (splitDirectories, takeBaseName)

import ManageCards.Classifier (classifyLegacy)
import ManageCards.Types
  ( CardCategory (..)
  , CardGroup (..)
  , CardOccurrence (..)
  )

-- | Set of known beast/animal monster file base names.
beastMonsters :: Set.Set String
beastMonsters =
  Set.fromList
    [ "ant_queen"
    , "ant_soldier"
    , "basilisk"
    , "bear"
    , "bread_wolf"
    , "cave_bat"
    , "crystal_shard"
    , "wasp_queen"
    , "wasp_soldier"
    , "wolf"
    ]

type ConceptKey = (Text, Maybe Text, Maybe [Text], Maybe Int, Maybe Text)

-- | Convert a CoreCard to a concept key identifying its rules, name, attack, and cost.
toConceptKey :: CoreCard -> ConceptKey
toConceptKey c =
  let CoreCard
        { name = cName
        , attack = cAttack
        , rules = cRules
        , cost = cCost
        , flavor = cFlavor
        } = c
   in ( getRawText cName
      , fmap toText cAttack
      , fmap (map toText . NE.toList) cRules
      , cCost
      , fmap toText cFlavor
      )

-- | Determine the appropriate category for a card given its occurrences and properties.
determineCardCategory :: [FilePath] -> CoreCard -> CardCategory
determineCardCategory files card =
  let CoreCard{name = cName} = card
      lowerName = T.toLower (getRawText cName)
      isCoreCard =
        lowerName
          `elem` [ "athletics"
                 , "conditioning"
                 , "dodge"
                 , "brace"
                 , "defend"
                 , "focus"
                 , "rest"
                 , "basic attack"
                 , "basic defense"
                 ]
      isWizardFile f = takeBaseName f == "wizard"
      isPcFile f = "pc" `elem` splitDirectories f
      isBeastFile f = takeBaseName f `Set.member` beastMonsters
      isArcaneCard =
        any
          (`T.isInfixOf` lowerName)
          [ "spell"
          , "fireball"
          , "magic"
          , "polymorph"
          , "telekenetic"
          , "ghostform"
          , "flicker"
          , "mind crush"
          , "slow ray"
          ]
   in if
        | isCoreCard -> CategoryCore
        | any isWizardFile files || isArcaneCard -> CategoryArcane
        | any isPcFile files -> CategoryMartial
        | any isBeastFile files -> CategoryBeasts
        | otherwise -> CategoryHumanoids

-- | Pick the modal (most frequent) stats among cards in a group.
pickModalStats :: [CoreCard] -> Stats Int
pickModalStats cards =
  let toTuple (CoreCard{stats = Stats r y b}) = (r, y, b)
      statCounts = Map.fromListWith (+) [(toTuple c, 1 :: Int) | c <- cards]
      sorted = sortOn (\(_, cnt) -> Down cnt) (Map.toList statCounts)
   in case sorted of
        (((r, y, b), _) : _) -> Stats r y b
        [] -> case cards of
          (CoreCard{stats = s} : _) -> s
          [] -> Stats 0 0 0

-- | Assign globally unique slugs to raw card clusters.
assignUniqueSlugs :: [(CardCategory, CoreCard, [CardOccurrence])] -> [CardGroup]
assignUniqueSlugs rawGroups =
  let (groups, _) = foldl' assign ([], Set.empty) rawGroups
   in reverse groups
  where
    assign (acc, usedSlugs) (cat, bCard, occs) =
      let CoreCard{name = bName} = bCard
          baseSlug =
            let s = toSlug (getRawText bName)
             in if T.null s then "card" else s
          uniqueSlug = findUnique baseSlug (1 :: Int) usedSlugs
          (status, notes) = classifyLegacy bCard
          grp =
            CardGroup
              { canonicalSlug = uniqueSlug
              , baseCard = bCard
              , occurrences = occs
              , category = cat
              , rulesStatus = status
              , legacyNotes = notes
              }
       in (grp : acc, Set.insert uniqueSlug usedSlugs)

    findUnique base 1 used
      | not (Set.member base used) = base
      | otherwise = findUnique base 2 used
    findUnique base n used =
      let cand = base <> "-" <> T.pack (show n)
       in if not (Set.member cand used)
            then cand
            else findUnique base (n + 1) used

-- | Group a list of card occurrences into candidate master card clusters with unique slugs.
groupCards :: [(FilePath, CoreCard)] -> [CardGroup]
groupCards rawPairs =
  let groupedMap =
        foldl'
          ( \acc (path, card) ->
              let key = toConceptKey card
                  occ = CardOccurrence{sourceFile = path, card = card}
               in Map.insertWith (++) key [occ] acc
          )
          Map.empty
          rawPairs

      -- Stable sort by card name and key
      sortedConcepts =
        sortOn
          ( \(_, occs) ->
              case occs of
                (o : _) ->
                  let CoreCard{name = n} = o.card
                   in (getRawText n, toConceptKey o.card)
                [] -> ("", ("", Nothing, Nothing, Nothing, Nothing))
          )
          (Map.toList groupedMap)

      rawClusters =
        map
          ( \(_, occs) ->
              let cards = map (\o -> o.card) occs
                  files = map (\o -> o.sourceFile) occs
                  sampleCard = case occs of
                    (o : _) -> o.card
                    [] -> error "groupCards: empty occurrence list"
                  modalStats = pickModalStats cards
                  baseCard = sampleCard{stats = modalStats}
                  cat = determineCardCategory files baseCard
               in (cat, baseCard, occs)
          )
          sortedConcepts
   in assignUniqueSlugs rawClusters
