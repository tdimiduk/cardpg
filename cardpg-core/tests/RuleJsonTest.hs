{-# LANGUAGE OverloadedStrings #-}
module RuleJsonTest where

import Data.Aeson (eitherDecode)
import Data.ByteString.Lazy ()
import Test.Tasty.QuickCheck
import CardPG.Core.RuleDefs (Rule(..), GeneralDef(..))
import CardPG.Core.RuleInstances ()
import CardPG.Core.RichText (unsafeSimpleString)
import CardPG.Core.NonEmptyText (unsafeNonEmptyText)

prop_ruleJsonParsing :: Property
prop_ruleJsonParsing = 
  let json = "{\"type\": \"general\", \"data\": {\"effect\": \"Test Effect\", \"name\": \"Test Action\"}}"
      decoded = eitherDecode json :: Either String Rule
      expected = RuleGeneral $ GeneralDef (unsafeNonEmptyText "Test Action") Nothing Nothing (unsafeSimpleString "Test Effect")
  in counterexample ("JSON: " ++ show json ++ "\nDecoded: " ++ show decoded) $ decoded === Right expected
