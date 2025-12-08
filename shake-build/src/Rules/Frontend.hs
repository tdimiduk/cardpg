module Rules.Frontend (defineFrontendRules, defineFrontendTestRules, format) where

import Development.Shake
import Development.Shake.FilePath

getFrontendSources :: Action [FilePath]
getFrontendSources = do
  let dir = "vtt-react"
  srcs <-
    getDirectoryFiles dir ["src//*.ts", "src//*.tsx", "package.json", "tsconfig.json", "vite.config.ts"]
  return $ map (dir </>) srcs

defineFrontendRules :: Rules ()
defineFrontendRules = do
  "_build/frontend/.lint.timestamp" %> \out -> do
    srcs <- getFrontendSources
    need srcs
    cmd_ (Cwd "vtt-react") (["npm", "run", "lint"] :: [String])
    cmd_ (["mkdir", "-p", takeDirectory out] :: [String])
    cmd_ (["touch", out] :: [String])

  "_build/frontend/.typecheck.timestamp" %> \out -> do
    srcs <- getFrontendSources
    need srcs
    cmd_ (Cwd "vtt-react") (["npm", "exec", "tsc", "--", "--noEmit"] :: [String])
    cmd_ (["mkdir", "-p", takeDirectory out] :: [String])
    cmd_ (["touch", out] :: [String])

defineFrontendTestRules :: Rules ()
defineFrontendTestRules = do
  "_build/tests/.vtt-react.timestamp" %> \out -> do
    srcs <- getFrontendSources
    need srcs
    cmd_ (Cwd "vtt-react") (["npm", "exec", "vitest", "run"] :: [String])
    cmd_ (["touch", out] :: [String])

format :: Bool -> Action ()
format checkOnly = do
  let args = if checkOnly then ["--check"] else ["--write"]
  let files = ["src/**/*.{ts,tsx,css,md}"]
  cmd_ (Cwd "vtt-react") (["npm", "exec", "prettier", "--"] ++ args ++ files)
