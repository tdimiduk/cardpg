module Common (getPackageSources, persistentTask, persistentTaskWithSrcs, buildDir) where

import Development.Shake
import Development.Shake.FilePath

-- | Directory for build artifacts
buildDir :: FilePath
buildDir = "_build"

-- | Generic source helper
getPackageSources :: FilePath -> FilePath -> Action [FilePath]
getPackageSources pkgDir srcSub = do
  let srcDir = pkgDir </> srcSub
  hs <- getDirectoryFiles srcDir ["//*.hs"]
  cabal <- getDirectoryFiles pkgDir ["*.cabal"]
  return $ map (srcDir </>) hs ++ map (pkgDir </>) cabal

-- | Helper for running a task only when dependencies change
-- The action should produce the stamp file.
-- Note: 'runAction' often just runs a command, so we explicitly handle touching the stamp file here.
persistentTask :: FilePath -> Action [FilePath] -> Action () -> Rules ()
persistentTask stamp getSrcs act = persistentTaskWithSrcs stamp getSrcs (const act)

-- | Helper for running a task only when dependencies change, passing the sources to the action
persistentTaskWithSrcs :: FilePath -> Action [FilePath] -> ([FilePath] -> Action ()) -> Rules ()
persistentTaskWithSrcs stamp getSrcs act = do
  stamp %> \out -> do
    srcs <- getSrcs
    need srcs
    act srcs
    -- Ensure directory exists and touch the stamp file
    cmd_ (["mkdir", "-p", takeDirectory out] :: [String])
    cmd_ (["touch", out] :: [String])
