{-# LANGUAGE OverloadedStrings #-}

module PlanningTest where

import Data.Set qualified as Set
import Data.UUID.Types qualified as UUID
import Test.Tasty
import Test.Tasty.HUnit

import Core.Primitives (CardInstanceId (..))
import Frontend.Game.Planning

tests :: TestTree
tests =
  testGroup
    "Frontend.Game.Planning"
    [ testCase "Select Action - Sets Action" $ do
        let cid = CardInstanceId UUID.nil
            st = emptyStaging
            st' = applyUpdate (SelectAction cid) st
        st'.stagedActionId @?= Just cid
    , testCase "Select Action - Deselects if same" $ do
        let cid = CardInstanceId UUID.nil
            st = StagingState (Just cid) Set.empty
            st' = applyUpdate (SelectAction cid) st
        st'.stagedActionId @?= Nothing
    , testCase "Toggle Resource - Adds" $ do
        let cid = CardInstanceId UUID.nil
            st = emptyStaging
            st' = applyUpdate (ToggleResource cid) st
        Set.member cid st'.stagedResourceIds @?= True
    , testCase "Toggle Resource - Removes" $ do
        let cid = CardInstanceId UUID.nil
            st = StagingState Nothing (Set.singleton cid)
            st' = applyUpdate (ToggleResource cid) st
        Set.member cid st'.stagedResourceIds @?= False
    , testCase "Clear - Resets" $ do
        let cid = CardInstanceId UUID.nil
            st = StagingState (Just cid) (Set.singleton cid)
            st' = applyUpdate Clear st
        st' @?= emptyStaging
    ]

emptyStaging :: StagingState
emptyStaging = StagingState Nothing Set.empty
