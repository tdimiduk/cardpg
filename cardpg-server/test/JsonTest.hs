{-# LANGUAGE OverloadedStrings #-}

module JsonTest where

import Data.Aeson (decode, encode)
import Data.ByteString.Lazy.Char8 qualified as B
import Data.List qualified
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import CardPG.Api.Frontend qualified as Frontend
import CardPG.Core.Primitives (ActorId (..))
import CardPG.Server.Types (ActorGameEvent (..), ServerMessage (..))

test_json :: TestTree
test_json =
  testGroup
    "JSON Serialization"
    [ testCase "MultiMessage Serialization" $ do
        let actorId = ActorId (read "00000000-0000-0000-0000-000000000001")
        let evt = ActorGameEvent actorId Frontend.DeckShuffled
        let msg1 = BroadcastMessage (read "00000000-0000-0000-0000-000000000001") [evt]
        let msg2 = ErrorMessage "Test Error"
        let batch = MultiMessage [msg1, msg2]

        let json = encode batch
        let jsonStr = B.unpack json
        -- Check if it contains "type":"multiMessage"
        ("type\":\"multiMessage\"" `Data.List.isInfixOf` jsonStr) @?= True
        -- Check if it contains "messages" array
        ("messages\":[" `Data.List.isInfixOf` jsonStr) @?= True
    ]
