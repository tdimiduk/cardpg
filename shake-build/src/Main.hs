{-# LANGUAGE OverloadedStrings #-}

module Main where

import Development.Shake
import Control.Monad (forM_)
import qualified Rules.Cards as Cards
import qualified Rules.Codegen as Codegen
import qualified Rules.Deploy as Deploy
import qualified Rules.Frontend as Frontend
import qualified Rules.Haskell as Haskell
import qualified Rules.Justfile as Justfile
import qualified Rules.Orchestration as Orchestration
import Common (buildDir)

main :: IO ()
main = do
    -- Parse manifest and extract decks
    (pcDecks, monsterDecks) <- Cards.getDecks

    -- Define phony targets
    let defs = 
            [ ("card-data", "Compiles all card data to VTT JSON", Cards.buildCardData)
            , ("sync",      "Syncs card data from Google Sheets", Cards.runSync)
            , ("clean",     "Clean build artifacts",              Orchestration.cleanBuild)
            , ("gen-just",  "Regenerate the Justfile",            Justfile.generateJustfile defs)
            , ("gen-types", "Generate TypeScript types",          Codegen.buildGenTypes)
            , ("build-core", "Build cardpg-core",                 Haskell.buildCore)
            , ("build-server", "Build cardpg-server",             Haskell.buildServer)
            , ("build",       "Build all targets",                Orchestration.buildAll)
            , ("dev",         "Run dev servers",                  Orchestration.runDev)
            , ("test",        "Run all tests",                    Orchestration.testAll)
            , ("lint-frontend", "Lint frontend code",             need ["_build/frontend/.lint.timestamp"])
            , ("check-types",   "Typecheck frontend code",        need ["_build/frontend/.typecheck.timestamp"])
            , ("test-core",   "Test cardpg-core",                 need ["_build/tests/.cardpg-core.timestamp"])
            , ("test-compiler","Test card-compiler",              need ["_build/tests/.card-compiler.timestamp"])
            , ("repl-core",   "REPL for cardpg-core",             Haskell.replCore)
            , ("repl-server", "REPL for cardpg-server",           Haskell.replServer)
            , ("deploy-prod", "Deploy to prod (smart rebuild)",   Deploy.deploy False)
            , ("deploy-rebuild", "Deploy to prod (force rebuild)", Deploy.deploy True)
            ]

    shakeArgs shakeOptions{shakeFiles=buildDir, shakeColor=True, shakeThreads=0} $ do
        
        want ["card-data"]

        -- Register all phony rules from the definitions
        forM_ defs $ \(name, _, ruleAction) -> phony name ruleAction

        -- Define build rules
        Cards.defineVttRule pcDecks monsterDecks
        Cards.defineDeckRules "pc" "data/cards/pc"
        Cards.defineDeckRules "monster" "data/cards/monsters"
        Codegen.defineCodegenRules
        Haskell.defineHaskellTestRules Codegen.getCardCompilerSources
        Frontend.defineFrontendRules
        Frontend.defineFrontendTestRules
