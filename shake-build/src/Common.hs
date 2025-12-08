module Common where

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
