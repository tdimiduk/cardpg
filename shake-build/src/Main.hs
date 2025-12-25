{-# LANGUAGE OverloadedStrings #-}

module Main where

import Common (buildDir)
import Control.Monad (forM_)
import Development.Shake
import qualified Rules.Cards as Cards
import qualified Rules.Codegen as Codegen
import qualified Rules.Deploy as Deploy
import qualified Rules.Frontend as Frontend
import qualified Rules.Haskell as Haskell
import qualified Rules.Integration as Integration
import qualified Rules.Justfile as Justfile
import qualified Rules.Orchestration as Orchestration

main :: IO ()
main = do
  -- Define phony targets
  let defs =
        [ ("card-data", "Compiles all card data to VTT JSON", Cards.buildCardData)
        , ("compile-legacy-cards", "Compiles legacy cards (JSON -> YAML)", Cards.compileLegacyCards)
        , ("sync", "Syncs card data from Google Sheets", Cards.runSync)
        , ("clean", "Clean build artifacts", Orchestration.cleanBuild)
        , ("gen-just", "Regenerate the Justfile", Justfile.generateJustfile defs)
        , ("gen-types", "Generate TypeScript types", Codegen.buildGenTypes)
        , ("codegen", "Alias for gen-types", Codegen.buildGenTypes)
        , ("build-api", "Build cardpg-api", Haskell.buildApi)
        , ("build-core", "Build cardpg-core", Haskell.buildCore)
        , ("build-server", "Build cardpg-server", Haskell.buildServer)
        , ("build", "Build all targets", Orchestration.buildAll)
        , ("dev", "Run dev servers", Orchestration.runDev)
        , ("test", "Run all tests", need ["test-core", "test-server", "test-compiler", "check-types"])
        , ("lint-backend", "Lint backend code", need ["_build/haskell/.lint.timestamp"])
        , ("lint", "Lint all code", need ["lint-backend", "lint-frontend"])
        , ("lint-frontend", "Lint frontend code", need ["_build/frontend/.lint.timestamp"])
        , ("check-types", "Typecheck frontend code", need ["_build/frontend/.typecheck.timestamp"])
        , ("test-core", "Test cardpg-core", need ["_build/tests/.cardpg-core.timestamp"])
        , ("test-server", "Test cardpg-server", need ["_build/tests/.cardpg-server.timestamp"])
        , ("test-compiler", "Test card-compiler", need ["_build/tests/.card-compiler.timestamp"])
        , ("repl-api", "REPL for cardpg-api", Haskell.replApi)
        , ("repl-core", "REPL for cardpg-core", Haskell.replCore)
        , ("repl-server", "REPL for cardpg-server", Haskell.replServer)
        , ("deploy-prod", "Deploy to prod (smart rebuild)", Deploy.deploy False)
        , ("deploy-rebuild", "Deploy to prod (force rebuild)", Deploy.deploy True)
        ,
          ( "format"
          , "Format code"
          , need ["_build/haskell/.format.timestamp", "_build/frontend/.format.timestamp"]
          )
        ,
          ( "format-check"
          , "Check code formatting"
          , need ["_build/haskell/.format-check.timestamp", "_build/frontend/.format-check.timestamp"]
          )
        , ("test-integration", "Run integration tests", Integration.runIntegrationTests)
        ]

  shakeArgs shakeOptions{shakeFiles = buildDir, shakeColor = True, shakeThreads = 0} $ do
    want ["card-data"]

    -- Register all phony rules from the definitions
    forM_ defs $ \(name, _, ruleAction) -> phony name ruleAction

    -- Define build rules
    Cards.defineVttRule
    Codegen.defineCodegenRules
    Haskell.defineCardCompilerRule
    Haskell.defineHaskellLibraryRules
    Haskell.defineHaskellTestRules Codegen.getCardCompilerSources
    Haskell.defineHaskellLintRules
    Haskell.defineHaskellFormatRules
    Frontend.defineFrontendRules
    Frontend.defineFrontendTestRules
    Frontend.defineFrontendFormatRules
