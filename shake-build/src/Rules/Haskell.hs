module Rules.Haskell (buildCore, buildServer, replCore, replServer, defineHaskellTestRules, format, lint) where

import Common (getPackageSources)
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
  "_build/tests/.cardpg-core.timestamp" %> \out -> do
    srcs <- getCoreSources
    need srcs
    cmd_ (["cabal", "test", "cardpg-core"] :: [String])
    cmd_ (["touch", out] :: [String])

  "_build/tests/.card-compiler.timestamp" %> \out -> do
    srcs <- getCardCompilerSources
    need srcs
    cmd_ (["cabal", "test", "card-compiler"] :: [String])
    cmd_ (["touch", out] :: [String])

-- | Format Haskell code using fourmolu
format :: Bool -> Action ()
format checkOnly = do
  let mode = if checkOnly then "--mode=check" else "--mode=inplace"
  let srcDirs =
        [ "cardpg-core/src"
        , "cardpg-core/tests"
        , "cardpg-server/src"
        , "cardpg-server/tests"
        , "shake-build/src"
        , "tools"
        ]
  srcFiles <- getDirectoryFiles "" [d ++ "/**/*.hs" | d <- srcDirs]
  cmd_ (["fourmolu", mode] ++ srcFiles)

-- | Lint Haskell code using hlint
lint :: Action ()
lint = do
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
  srcFiles <- getDirectoryFiles "" [d ++ "/**/*.hs" | d <- srcDirs]
  cmd_ ("hlint" : srcFiles)
