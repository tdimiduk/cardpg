module Rules.Haskell
  ( buildCore
  , buildServer
  , replCore
  , replServer
  , defineHaskellTestRules
  , defineHaskellLintRules
  , defineHaskellFormatRules
  ) where

import Common (getPackageSources, persistentTask)
import Development.Shake

getCoreSources :: Action [FilePath]
getCoreSources = getPackageSources "cardpg-core" "src"

getServerSources :: Action [FilePath]
getServerSources = getPackageSources "cardpg-server" "src"

buildCore :: Action ()
buildCore = do
  srcs <- getCoreSources
  need srcs
  cmd_ (["cabal", "build", "cardpg-core"] :: [String])

buildServer :: Action ()
buildServer = do
  srcs <- getServerSources
  need srcs
  cmd_ (["cabal", "build", "cardpg-server"] :: [String])

replCore :: Action ()
replCore = cmd_ (["cabal", "repl", "cardpg-core"] :: [String])

replServer :: Action ()
replServer = cmd_ (["cabal", "repl", "cardpg-server"] :: [String])

defineHaskellTestRules :: Action [FilePath] -> Rules ()
defineHaskellTestRules getCardCompilerSources = do
  persistentTask "_build/tests/.cardpg-core.timestamp" getCoreSources $
    cmd_ (["cabal", "test", "cardpg-core"] :: [String])

  persistentTask "_build/tests/.card-compiler.timestamp" getCardCompilerSources $
    cmd_ (["cabal", "test", "card-compiler"] :: [String])

  persistentTask "_build/tests/.cardpg-server.timestamp" getServerSources $
    cmd_ (["cabal", "test", "cardpg-server"] :: [String])

getHaskellSources :: Action [FilePath]
getHaskellSources = do
  let srcDirs =
        [ "cardpg-core/src"
        , "cardpg-core/tests"
        , "cardpg-server/src"
        , "cardpg-server/tests"
        , "shake-build/src"
        , "tools/card-compiler/src"
        , "tools/card-compiler/test"
        , "tools/codegen"
        ]
  getDirectoryFiles "" [d ++ "/**/*.hs" | d <- srcDirs]

-- | Format Haskell code using fourmolu
defineHaskellFormatRules :: Rules ()
defineHaskellFormatRules = do
  -- Formatter
  persistentTask "_build/haskell/.format.timestamp" getHaskellSources $ do
    srcFiles <- getHaskellSources
    cmd_ (["fourmolu", "--mode=inplace"] ++ srcFiles)

  -- Format checker
  persistentTask "_build/haskell/.format-check.timestamp" getHaskellSources $ do
    srcFiles <- getHaskellSources
    cmd_ (["fourmolu", "--mode=check"] ++ srcFiles)

-- | Lint Haskell code using hlint
defineHaskellLintRules :: Rules ()
defineHaskellLintRules = do
  persistentTask "_build/haskell/.lint.timestamp" getHaskellSources $ do
    srcFiles <- getHaskellSources
    cmd_ ("hlint" : srcFiles)
