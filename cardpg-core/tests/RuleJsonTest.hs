{-# LANGUAGE OverloadedStrings #-}

module RuleJsonTest where

import Data.Aeson (eitherDecode, encode)
import Data.ByteString.Lazy.Char8 (unpack)
import Data.List (isInfixOf)
import Data.Map.Strict qualified as Map
import Data.UUID qualified as UUID
import Test.Tasty.QuickCheck

import CardPG.Core.Card (ItemCardT (..))
import CardPG.Core.NonEmptyText (unsafeNonEmptyText)
import CardPG.Core.Primitives (CardInstanceId (..), EquipSlot (..))
import CardPG.Core.RichText (unsafeSimpleString)
import CardPG.Core.RuleDefs (DSLBase, GeneralDefT (..), RuleT (..))
import CardPG.Core.RuleInstances ()
import CardPG.Core.State (AssetState (..), TableCard (..), TableState (..))

prop_ruleJsonParsing :: Property
prop_ruleJsonParsing =
  let json = "{\"type\": \"general\", \"data\": {\"effect\": \"Test Effect\", \"name\": \"Test Action\"}}"
      decoded = eitherDecode json :: Either String DSLBase
      expected =
        RuleGeneral $
          GeneralDef (unsafeNonEmptyText "Test Action") Nothing Nothing (unsafeSimpleString "Test Effect")
   in counterexample ("JSON: " ++ show json ++ "\nDecoded: " ++ show decoded) $ decoded === Right expected

prop_tableStateJsonStructure :: Property
prop_tableStateJsonStructure =
  let
    -- Manually construct a specific TableState to verify encoding
    uuid1 = UUID.fromWords 1 2 3 4
    cid1 = CardInstanceId uuid1
    itemCard =
      ItemCard
        (unsafeNonEmptyText "Sword")
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
    tableCard = TCItem itemCard
    asset = Equipped SlotMainHand

    ts =
      TableState
        (Map.singleton cid1 asset)
        (Map.singleton cid1 tableCard)
        []
        Map.empty

    encoded = encode ts
    encodedStr = unpack encoded

    -- Verify expected JSON structure
    -- "assets": { "UUID...": { "type": "equipped", "data": "slotMainHand" } }
    hasEquipped = "\"type\":\"equipped\"" `isInfixOf` encodedStr
    hasSlot = "\"data\":\"slotMainHand\"" `isInfixOf` encodedStr
    -- "registry": { "UUID...": { "type": "tCItem", "data": { ... } } }
    hasItemType = "\"type\":\"tCItem\"" `isInfixOf` encodedStr
    -- Check that keys match (UUID should be present at least twice)
    uuidStr = show uuid1
    hasUUID = uuidStr `isInfixOf` encodedStr
   in
    counterexample ("Encoded: " ++ encodedStr) $
      hasEquipped .&&. hasSlot .&&. hasItemType .&&. hasUUID
