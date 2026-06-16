{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}

module Frontend.Editor
  ( editorWidget
  ) where

import Control.Monad (join)
import Control.Monad.Fix (MonadFix)
import Data.Aeson (toJSON)
import Data.Default (def)
import Data.List.NonEmpty (NonEmpty, nonEmpty)
import Data.Map qualified as Map
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Text qualified as T
import Text.Read (readMaybe)

import Reflex.Dom.Core hiding (button)

-- Core imports
import Core.Card
import Core.DSL (TextRep, parseText)
import Core.NonEmptyText (getRawText, mkNonEmptyText, unsafeNonEmptyText)
import Core.RichText (unsafeSimpleString)
import Core.Rules (AttackDef, Rule (..))
import Core.Stats (Stats (..))
import Core.Util (tshow)

-- Styling & UI imports

import Api.Request (ApiRequest (SaveCustomCard))
import Frontend.Card
  ( CardSettings (..)
  , renderConsequenceCardWith
  , renderCoreCardWith
  , renderEncounterCardWith
  , renderItemCardWith
  , renderNatureCardWith
  , renderTalentCardWith
  )
import Frontend.Game.Class (MonadGame (..))
import Frontend.Style (Style)
import Frontend.Style qualified as Style
import Frontend.Style.Common (classNames, componentS, divS, elS)
import Frontend.Style.DSL qualified as S
import Frontend.Style.Layout (col, colWith, row)
import Frontend.UI.Button (ButtonConfig (..), ButtonSize (..), ButtonVariant (..), button)

data CardCategory
  = CatCore
  | CatItem
  | CatNature
  | CatTalent
  | CatEncounter
  | CatConsequence
  deriving (Eq, Ord, Show, Read, Enum, Bounded)

-- | Shared input style
inputStyle :: Style
inputStyle =
  S.wFull
    <> S.css "bg-stone-med" "background-color" "var(--color-stone-med)"
    <> S.border1
    <> S.border S.Gray 10
    <> S.rounded
    <> S.px S.S3
    <> S.p S.S2
    <> S.textSm
    <> S.textWhite
    <> S.css "focus:outline-none" "outline" "none"
    <> S.pseudo "focus" (S.border S.Yellow 5)

textareaStyle :: Style
textareaStyle = inputStyle <> S.h (S.Rem 6)

textField :: (DomBuilder t m) => Text -> Text -> m (Dynamic t Text)
textField labelText placeholderVal = col $ do
  elS "label" (S.textSm <> S.fontBold <> S.text S.Gray 5 <> S.mb S.S1) $ text labelText
  ie <-
    inputElement $
      def
        & initialAttributes
        .~ ("class" =: classNames inputStyle <> "placeholder" =: placeholderVal)
  return $ _inputElement_value ie

textareaField :: (DomBuilder t m) => Text -> Text -> m (Dynamic t Text)
textareaField labelText placeholderVal = col $ do
  elS "label" (S.textSm <> S.fontBold <> S.text S.Gray 5 <> S.mb S.S1) $ text labelText
  ta <-
    textAreaElement $
      def
        & textAreaElementConfig_elementConfig
        . elementConfig_initialAttributes
        .~ ("class" =: classNames textareaStyle <> "placeholder" =: placeholderVal <> "rows" =: "4")
  return $ _textAreaElement_value ta

parseNum :: Text -> Int
parseNum t = fromMaybe 0 (readMaybe (T.unpack t))

parseSingleRule :: Text -> Either String Rule
parseSingleRule = parseText

-- | Visual Card Editor
editorWidget
  :: forall t m
   . ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , MonadGame t m
     )
  => m ()
editorWidget = componentS
  "card-editor"
  (S.flexRow <> S.hFull <> S.gap S.S4 <> S.p S.S4 <> S.cls "cursed-lava-stone")
  $ do
    rec -- Left Form Panel
        (saveTriggerEvt, cardDyn) <- colWith
          ( S.w (S.Rem 28)
              <> S.gap S.S3
              <> S.overflowYAuto
              <> S.pr S.S2
              <> S.cls "obsidian-panel"
              <> S.p S.S4
              <> S.rounded
          )
          $ do
            elS
              "h1"
              ( S.textLg
                  <> S.fontBold
                  <> S.cls "fantasy-font"
                  <> S.css "text-gold-bright" "color" "var(--color-gold-bright)"
              )
              $ text "Card Authoring Tool"

            -- Category selector
            elS "label" (S.textSm <> S.fontBold <> S.text S.Gray 5 <> S.mb S.S1) $ text "Card Type"
            let categories =
                  Map.fromList
                    [ (CatCore, "Core Card")
                    , (CatItem, "Item Card")
                    , (CatNature, "Nature Card")
                    , (CatTalent, "Talent Card")
                    , (CatEncounter, "Encounter Card")
                    , (CatConsequence, "Consequence Card")
                    ]
            catDropdown <-
              dropdown CatCore (constDyn categories) $
                def
                  & dropdownConfig_attributes
                  .~ constDyn ("class" =: classNames inputStyle)
            let catDyn = _dropdown_value catDropdown

            -- Common Fields
            nameDyn <- textField "Card Name" "e.g., Strike"
            sourceFileDyn <- textField "Target File Path" "e.g., pc/vallhach.yaml"

            -- Render sub-form reactively
            cardFieldsDyn <- widgetHold (coreFieldsWidget nameDyn) $ ffor (updated catDyn) $ \case
              CatCore -> coreFieldsWidget nameDyn
              CatItem -> itemFieldsWidget nameDyn
              CatNature -> natureFieldsWidget nameDyn
              CatTalent -> talentFieldsWidget nameDyn
              CatEncounter -> encounterFieldsWidget nameDyn
              CatConsequence -> consequenceFieldsWidget nameDyn

            let customCardDyn = fst =<< cardFieldsDyn
                hasErrorDyn = snd =<< cardFieldsDyn

            -- Save Button
            saveClick <-
              button
                (def :: ButtonConfig t)
                  { variant = VariantPrimary
                  , fullWidth = True
                  , size = SizeMedium
                  , extraStyle = S.mt S.S4
                  , disabled = hasErrorDyn
                  }
                $ text "Save Card to DB"

            let jsonCardDyn = fmap toJSON customCardDyn
                saveEvt = tag (current (zipDyn jsonCardDyn sourceFileDyn)) saveClick

            return (saveEvt, customCardDyn)

        -- Right Preview Panel
        colWith
          ( S.flex1
              <> S.flexCol
              <> S.itemsCenter
              <> S.justifyCenter
              <> S.bgAlpha S.Black 12 50
              <> S.rounded
              <> S.p S.S4
          )
          $ do
            elS "h2" (S.textSm <> S.fontBold <> S.text S.Gray 5 <> S.uppercase <> S.mb S.S4 <> S.trackingWider) $
              text "Live Preview"
            divS Style.standardCardSize $ do
              dyn_ $ ffor cardDyn $ \card -> do
                case card of
                  CustomCore cc -> renderCoreCardWith def cc
                  CustomItem ic -> renderItemCardWith def ic
                  CustomNature nc -> renderNatureCardWith def nc
                  CustomTalent tc -> renderTalentCardWith def tc
                  CustomConsequence cc -> renderConsequenceCardWith def cc
                  CustomEncounter ec -> renderEncounterCardWith def ec

    -- Network Response handler
    responses <- requestGame $ uncurry SaveCustomCard <$> saveTriggerEvt
    widgetHold_ blank $ ffor responses $ \case
      Left err ->
        divS (S.p S.S2 <> S.bgAlpha S.Red 11 50 <> S.textWhite <> S.rounded <> S.mt S.S2 <> S.textSm) $
          text $
            "Network Error: " <> err
      Right (Left err) ->
        divS (S.p S.S2 <> S.bgAlpha S.Red 11 50 <> S.textWhite <> S.rounded <> S.mt S.S2 <> S.textSm) $
          text $
            "Error: " <> err
      Right (Right ()) ->
        divS (S.p S.S2 <> S.bgAlpha S.Green 11 50 <> S.textWhite <> S.rounded <> S.mt S.S2 <> S.textSm) $
          text "Card saved successfully!"

    pure ()

-- | Fields for Core Cards
coreFieldsWidget
  :: (DomBuilder t m, MonadHold t m, PostBuild t m, MonadFix m)
  => Dynamic t Text
  -> m (Dynamic t CustomCard, Dynamic t Bool)
coreFieldsWidget nameDyn = do
  redDyn <- textField "Red Stat" "3"
  yellowDyn <- textField "Yellow Stat" "2"
  blueDyn <- textField "Blue Stat" "2"
  costDyn <- textField "Play Cost" "2"
  attackDyn <- textField "Attack (DSL)" "e.g., {Red}: Str = {Red} + 2"
  rulesDyn <- textareaField "Rules (One DSL rule per line)" "Passive: +1 {Yellow} when defending"
  flavorDyn <- textareaField "Flavor Text" "A solid strike..."
  tagsDyn <- textField "Tags (Comma-separated)" "Melee, Attack"

  -- Attack Parser validation
  let parsedAttackDyn = ffor attackDyn $ \val ->
        let cleanVal = T.strip val
         in if T.null cleanVal
              then Right Nothing
              else case parseText cleanVal :: Either String AttackDef of
                Left err -> Left $ "Attack parse error: " <> T.pack err
                Right a -> Right (Just a)

  dyn_ $ ffor parsedAttackDyn $ \case
    Left err -> divS (S.p S.S1 <> S.textSm <> S.text S.Red 5 <> S.fontBold <> S.mt S.S1) $ text err
    Right _ -> blank

  -- DSL Parser Errors display
  let parsedRulesDyn = ffor rulesDyn $ \rulesVal ->
        let linesOfRules = filter (not . T.null . T.strip) (T.lines rulesVal)
         in mapM
              ( \(idx, line) -> case parseSingleRule line of
                  Left err -> Left $ "Line " <> tshow idx <> ": " <> T.pack err
                  Right r -> Right r
              )
              (zip [1 ..] linesOfRules)

  dyn_ $ ffor parsedRulesDyn $ \case
    Left err -> divS (S.p S.S1 <> S.textSm <> S.text S.Red 5 <> S.fontBold <> S.mt S.S1) $ text err
    Right _ -> blank

  let hasErrorDyn = do
        pAttack <- parsedAttackDyn
        pRules <- parsedRulesDyn
        pure $ case (pAttack, pRules) of
          (Right _, Right _) -> False
          _ -> True

  let customCardDyn = do
        nameVal <- nameDyn
        redVal <- redDyn
        yellowVal <- yellowDyn
        blueVal <- blueDyn
        costVal <- costDyn
        attackVal <- attackDyn
        rulesVal <- rulesDyn
        flavorVal <- flavorDyn
        tagsVal <- tagsDyn

        let neName = fromMaybe (unsafeNonEmptyText "Draft Card") (mkNonEmptyText nameVal)
            stats = Stats (parseNum redVal) (parseNum yellowVal) (parseNum blueVal)
            cost = readMaybe (T.unpack costVal)
            tags = nonEmpty (filter (not . T.null) (map T.strip (T.splitOn "," tagsVal)))
            flavor = unsafeSimpleString . getRawText <$> mkNonEmptyText flavorVal

            -- Forgiving parsing for live preview:
            linesOfRules = filter (not . T.null . T.strip) (T.lines rulesVal)
            rules = nonEmpty $ flip map linesOfRules $ \line ->
              case parseSingleRule line of
                Right r -> r
                Left _ -> RuleNarrative (unsafeSimpleString line)

            cleanAttack = T.strip attackVal
            attack =
              if T.null cleanAttack
                then Nothing
                else case parseText cleanAttack of
                  Right a -> Just a
                  Left _ -> Nothing

        return $ CustomCore $ CoreCard neName tags stats cost attack rules flavor

  return (customCardDyn, hasErrorDyn)

-- | Fields for Item Cards
itemFieldsWidget
  :: (DomBuilder t m, MonadHold t m, PostBuild t m, MonadFix m)
  => Dynamic t Text
  -> m (Dynamic t CustomCard, Dynamic t Bool)
itemFieldsWidget nameDyn = do
  passiveDyn <- textField "Passive Text" "+1 Defense"
  traitsDyn <- textField "Traits (Comma-separated)" "Shield, Metal"
  defenseDyn <- textField "Defense" "2"
  resilienceDyn <- textField "Resilience" "3"
  flavorDyn <- textareaField "Flavor Text" "A heavy iron shield."

  let customCardDyn = do
        nameVal <- nameDyn
        passiveVal <- passiveDyn
        traitsVal <- traitsDyn
        defVal <- defenseDyn
        resVal <- resilienceDyn
        flavorVal <- flavorDyn

        let neName = fromMaybe (unsafeNonEmptyText "Draft Item") (mkNonEmptyText nameVal)
            passive = if T.null passiveVal then Nothing else Just passiveVal
            traits = nonEmpty (filter (not . T.null) (map T.strip (T.splitOn "," traitsVal)))
            defense = readMaybe (T.unpack defVal)
            resilience = readMaybe (T.unpack resVal)
            flavor = unsafeSimpleString . getRawText <$> mkNonEmptyText flavorVal

        return $
          CustomItem $
            ItemCard neName Nothing flavor Nothing Nothing traits passive defense resilience Nothing

  return (customCardDyn, constDyn False)

-- | Fields for Nature Cards
natureFieldsWidget
  :: (DomBuilder t m, MonadHold t m, PostBuild t m, MonadFix m)
  => Dynamic t Text
  -> m (Dynamic t CustomCard, Dynamic t Bool)
natureFieldsWidget nameDyn = do
  passiveDyn <- textField "Passive Text" "An elf mage"
  traitsDyn <- textField "Traits (Comma-separated)" "Elf, Spellcaster"
  defenseDyn <- textField "Defense" "1"
  resilienceDyn <- textField "Resilience" "2"
  flavorDyn <- textareaField "Flavor Text" ""

  let customCardDyn = do
        nameVal <- nameDyn
        passiveVal <- passiveDyn
        traitsVal <- traitsDyn
        defVal <- defenseDyn
        resVal <- resilienceDyn
        flavorVal <- flavorDyn

        let neName = fromMaybe (unsafeNonEmptyText "Draft Nature") (mkNonEmptyText nameVal)
            passive = if T.null passiveVal then Nothing else Just passiveVal
            traits = nonEmpty (filter (not . T.null) (map T.strip (T.splitOn "," traitsVal)))
            defense = readMaybe (T.unpack defVal)
            resilience = readMaybe (T.unpack resVal)
            flavor = unsafeSimpleString . getRawText <$> mkNonEmptyText flavorVal

        return $ CustomNature $ NatureCard neName Nothing flavor traits passive defense resilience Nothing

  return (customCardDyn, constDyn False)

-- | Fields for Talent Cards
talentFieldsWidget
  :: (DomBuilder t m, MonadHold t m, PostBuild t m, MonadFix m)
  => Dynamic t Text
  -> m (Dynamic t CustomCard, Dynamic t Bool)
talentFieldsWidget nameDyn = do
  passiveDyn <- textField "Passive Text" "Sword training"
  traitsDyn <- textField "Traits (Comma-separated)" "Sword"
  defenseDyn <- textField "Defense" "1"
  resilienceDyn <- textField "Resilience" "1"
  flavorDyn <- textareaField "Flavor Text" ""

  let customCardDyn = do
        nameVal <- nameDyn
        passiveVal <- passiveDyn
        traitsVal <- traitsDyn
        defVal <- defenseDyn
        resVal <- resilienceDyn
        flavorVal <- flavorDyn

        let neName = fromMaybe (unsafeNonEmptyText "Draft Talent") (mkNonEmptyText nameVal)
            passive = if T.null passiveVal then Nothing else Just passiveVal
            traits = nonEmpty (filter (not . T.null) (map T.strip (T.splitOn "," traitsVal)))
            defense = readMaybe (T.unpack defVal)
            resilience = readMaybe (T.unpack resVal)
            flavor = unsafeSimpleString . getRawText <$> mkNonEmptyText flavorVal

        return $ CustomTalent $ TalentCard neName Nothing flavor traits passive defense resilience

  return (customCardDyn, constDyn False)

-- | Fields for Encounter Cards
encounterFieldsWidget
  :: (DomBuilder t m, MonadHold t m, PostBuild t m, MonadFix m)
  => Dynamic t Text
  -> m (Dynamic t CustomCard, Dynamic t Bool)
encounterFieldsWidget nameDyn = do
  narrativeDyn <- textareaField "Narrative Text" "A low growl echoes from the shadows..."
  optionsDyn <- textField "Options (Comma-separated)" "Draw Sword, Back Away"

  let customCardDyn = do
        nameVal <- nameDyn
        narrativeVal <- narrativeDyn
        optionsVal <- optionsDyn

        let neName = fromMaybe (unsafeNonEmptyText "Draft Encounter") (mkNonEmptyText nameVal)
            narrative = unsafeSimpleString (if T.null (T.strip narrativeVal) then "..." else narrativeVal)
            options = nonEmpty (filter (not . T.null) (map T.strip (T.splitOn "," optionsVal)))

        return $ CustomEncounter $ EncounterCard neName Nothing narrative options Nothing

  return (customCardDyn, constDyn False)

-- | Fields for Consequence Cards
consequenceFieldsWidget
  :: (DomBuilder t m, MonadHold t m, PostBuild t m, MonadFix m)
  => Dynamic t Text
  -> m (Dynamic t CustomCard, Dynamic t Bool)
consequenceFieldsWidget nameDyn = do
  severityDyn <- textField "Severity (1-3)" "1"
  passiveDyn <- textField "Passive effect" "Attack cost increases by 1"
  rulesDyn <- textareaField "Rules" "e.g., Task: First Aid (Check {Blue} 3; Time 1 min) → Remove this"
  effectsDyn <- textField "Instant effects (Comma-separated)" "Put 2 Injury cards on top of deck"

  -- DSL Parser Errors display
  let parsedRulesDyn = ffor rulesDyn $ \rulesVal ->
        let linesOfRules = filter (not . T.null . T.strip) (T.lines rulesVal)
         in mapM
              ( \(idx, line) -> case parseSingleRule line of
                  Left err -> Left $ "Line " <> tshow idx <> ": " <> T.pack err
                  Right r -> Right r
              )
              (zip [1 ..] linesOfRules)

  dyn_ $ ffor parsedRulesDyn $ \case
    Left err -> divS (S.p S.S1 <> S.textSm <> S.text S.Red 5 <> S.fontBold <> S.mt S.S1) $ text err
    Right _ -> blank

  let hasErrorDyn = ffor parsedRulesDyn $ \case
        Left _ -> True
        Right _ -> False

  let customCardDyn = do
        nameVal <- nameDyn
        sevVal <- severityDyn
        passiveVal <- passiveDyn
        rulesVal <- rulesDyn
        effVal <- effectsDyn

        let neName = fromMaybe (unsafeNonEmptyText "Draft Consequence") (mkNonEmptyText nameVal)
            severity = parseNum sevVal
            passive = if T.null passiveVal then Nothing else Just passiveVal
            effects = nonEmpty (filter (not . T.null) (map T.strip (T.splitOn "," effVal)))

            linesOfRules = filter (not . T.null . T.strip) (T.lines rulesVal)
            rules = nonEmpty $ flip map linesOfRules $ \line ->
              case parseSingleRule line of
                Right r -> r
                Left _ -> RuleNarrative (unsafeSimpleString line)

        return $ CustomConsequence $ ConsequenceCard neName Nothing passive effects severity Nothing rules

  return (customCardDyn, hasErrorDyn)
