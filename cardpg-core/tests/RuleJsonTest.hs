{-# LANGUAGE OverloadedStrings #-}

module RuleJsonTest where

import Data.Aeson (eitherDecode)
import Data.ByteString.Lazy ()
import Test.Tasty.QuickCheck

import CardPG.Core.NonEmptyText (unsafeNonEmptyText)
import CardPG.Core.RichText (unsafeSimpleString)
import CardPG.Core.RuleDefs (DSLBase, GeneralDefT (..), RuleT (..))
import CardPG.Core.RuleInstances ()

prop_ruleJsonParsing :: Property
prop_ruleJsonParsing =
  let json = "{\"type\": \"general\", \"data\": {\"effect\": \"Test Effect\", \"name\": \"Test Action\"}}"
      decoded = eitherDecode json :: Either String DSLBase
      expected =
        RuleGeneral $
          GeneralDef (unsafeNonEmptyText "Test Action") Nothing Nothing (unsafeSimpleString "Test Effect")
   in counterexample ("JSON: " ++ show json ++ "\nDecoded: " ++ show decoded) $ decoded === Right expected
