{-# LANGUAGE OverloadedStrings #-}

module PlanningTest where

import Data.Maybe (fromMaybe)
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
            st = Nothing
            st' = applyUpdate (SelectAction cid) st
        st' @?= Just (StagingState cid Set.empty)
    , testCase "Select Action - Deselects if same" $ do
        let cid = CardInstanceId UUID.nil
            st = Just (StagingState cid Set.empty)
            st' = applyUpdate (SelectAction cid) st
        st' @?= Nothing
    , testCase "Toggle Resource - Adds" $ do
        let cid = CardInstanceId UUID.nil
            resId =
              CardInstanceId . fromMaybe (error "bad uuid") $
                UUID.fromString "00000000-0000-0000-0000-000000000002"
            st = Just (StagingState cid Set.empty)
            st' = applyUpdate (ToggleResource resId) st
        st' @?= Just (StagingState cid (Set.singleton resId))
    , testCase "Toggle Resource - Removes" $ do
        let cid = CardInstanceId UUID.nil
            resId =
              CardInstanceId . fromMaybe (error "bad uuid") $
                UUID.fromString "00000000-0000-0000-0000-000000000002"
            st = Just (StagingState cid (Set.singleton resId))
            st' = applyUpdate (ToggleResource resId) st
        st' @?= Just (StagingState cid Set.empty)
    , testCase "Clear - Resets" $ do
        let cid = CardInstanceId UUID.nil
            resId =
              CardInstanceId . fromMaybe (error "bad uuid") $
                UUID.fromString "00000000-0000-0000-0000-000000000002"
            st = Just (StagingState cid (Set.singleton resId))
            st' = applyUpdate Clear st
        st' @?= Nothing
    ]
