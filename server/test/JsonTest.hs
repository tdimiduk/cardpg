{-# LANGUAGE OverloadedStrings #-}

module JsonTest where

import Data.Aeson (decode, encode)
import Data.ByteString.Lazy.Char8 qualified as B
import Data.List qualified
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Api.Types (LogSender (..))
import Core.Primitives (ActorId (..))
import Core.State (GameEvent (..))
import Server.Types ()

test_json :: TestTree
test_json =
  testGroup
    "JSON Serialization"
    [ testCase "LogSender Serialization" $ do
        let systemSender = SenderSystem
        let gmSender = SenderGM
        let actorId = ActorId (read "00000000-0000-0000-0000-000000000001")
        let actorSender = SenderActor actorId "Hero"

        let jsonSystem = encode systemSender
        let jsonStrSystem = B.unpack jsonSystem
        jsonStrSystem @?= "{\"type\":\"senderSystem\"}"

        let jsonGM = encode gmSender
        let jsonStrGM = B.unpack jsonGM
        jsonStrGM @?= "{\"type\":\"senderGM\"}"

        let jsonActor = encode actorSender
        let jsonStrActor = B.unpack jsonActor
        -- SenderActor is a sum constructor with fields, so it uses "data" (from cardpgJsonDef)
        ("type\":\"senderActor\"" `Data.List.isInfixOf` jsonStrActor) @?= True
        ("data\":[" `Data.List.isInfixOf` jsonStrActor) @?= True
        ("Hero" `Data.List.isInfixOf` jsonStrActor) @?= True
    ]
