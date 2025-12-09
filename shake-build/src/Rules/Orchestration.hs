module Rules.Orchestration where

import Development.Shake

import Common (buildDir)

-- | Clean build artifacts
cleanBuild :: Action ()
cleanBuild = removeFilesAfter "." [buildDir, "dist-shake", "dist-newstyle"]

-- | Build everything
buildAll :: Action ()
buildAll = do
  need ["vtt-react/src/generated/types.ts"] -- Ensure types are gen'd first usually?
  -- Build Haskell
  cmd_ (["cabal", "build", "all"] :: [String])
  -- Build Frontend
  cmd_ (Cwd "vtt-react") (["npm", "run", "build"] :: [String])

-- | Run dev servers
runDev :: Action ()
runDev = do
  -- We want to run both the haskell server and the vite dev server

  -- We also want to make sure generated types exist before starting frontend?
  need ["gen-types"]

  let runServer = do
        need ["vtt-react/src/data/generated_cards.json"]
        putInfo "Starting cardpg-server..."
        cmd_ (["cabal", "run", "cardpg-server"] :: [String])

  let runFrontend = do
        putInfo "Starting Vite dev server..."
        cmd_ (Cwd "vtt-react") (["npm", "run", "dev"] :: [String])

  -- Actions in the list passed to 'parallel' run in parallel
  _ <- parallel [runServer, runFrontend]
  return ()

-- | Run all tests
testAll :: Action ()
testAll = do
  need
    [ "_build/tests/.cardpg-core.timestamp"
    , "_build/tests/.card-compiler.timestamp"
    , "_build/tests/.vtt-react.timestamp"
    , "_build/frontend/.lint.timestamp"
    , "_build/frontend/.typecheck.timestamp"
    ]
