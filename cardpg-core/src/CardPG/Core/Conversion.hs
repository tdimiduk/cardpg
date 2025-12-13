{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards #-}

module CardPG.Core.Conversion
  ( compileCoreCard
  , compileItemCard
  , compileNatureCard
  , compileTalentCard
  , compileEncounterCard
  , compileConsequenceCard
  , compileActorDefinition
  ) where

import Data.List.NonEmpty (NonEmpty)
import qualified Data.List.NonEmpty as NE

import CardPG.Core.Card
import CardPG.Core.RichText (RichString, RichText, getRichText)
import CardPG.Core.RuleDefs (DSLRule(..), Rule)

-- | Compile a Rule from DSL (String) to Machine (RichText)
compileRule :: DSLRule -> Rule
compileRule (DSLRule r) = fmap getRichText r

-- | Helper to map conversion over optional lists
convertRules :: Maybe (NonEmpty DSLRule) -> Maybe (NonEmpty Rule)
convertRules = fmap (fmap compileRule)

convertRichText :: RichString -> RichText
convertRichText = getRichText

convertMaybeRichText :: Maybe RichString -> Maybe RichText
convertMaybeRichText = fmap convertRichText

-- | Core Card Conversion
compileCoreCard :: CoreCardDSL -> CoreCard
compileCoreCard CoreCard{..} =
  CoreCard
    { rules = convertRules rules
    , flavor = convertMaybeRichText flavor
    , ..
    }

-- | Item Card Conversion
compileItemCard :: ItemCardDSL -> ItemCard
compileItemCard ItemCard{..} =
  ItemCard
    { flavor = convertMaybeRichText flavor
    , ..
    }

-- | Nature Card Conversion
compileNatureCard :: NatureCardDSL -> NatureCard
compileNatureCard NatureCard{..} =
  NatureCard
    { flavor = convertMaybeRichText flavor
    , ..
    }

-- | Talent Card Conversion
compileTalentCard :: TalentCardDSL -> TalentCard
compileTalentCard TalentCard{..} =
  TalentCard
    { flavor = convertMaybeRichText flavor
    , ..
    }

-- | Encounter Card Conversion
compileEncounterCard :: EncounterCardDSL -> EncounterCard
compileEncounterCard EncounterCard{..} =
  EncounterCard
    { narrative = convertRichText narrative
    , ..
    }

-- | Consequence Card Conversion
compileConsequenceCard :: ConsequenceCardDSL -> ConsequenceCard
compileConsequenceCard ConsequenceCard{..} =
  ConsequenceCard
    { rules = convertRules rules
    , ..
    }

-- | Actor Definition Conversion
compileActorDefinition :: ActorDefinitionDSL -> ActorDefinition
compileActorDefinition ActorDefinition{..} =
  ActorDefinition
    { items = map compileItemCard items
    , nature = map compileNatureCard nature
    , deck = map compileCoreCard deck
    , ..
    }
