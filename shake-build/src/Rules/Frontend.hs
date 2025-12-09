module Rules.Frontend (defineFrontendRules, defineFrontendTestRules, defineFrontendFormatRules) where

import Common (persistentTask)
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
  persistentTask "_build/frontend/.lint.timestamp" getFrontendSources $
    cmd_ (Cwd "vtt-react") (["npm", "run", "lint"] :: [String])

  persistentTask "_build/frontend/.typecheck.timestamp" getFrontendSources $
    cmd_ (Cwd "vtt-react") (["npm", "exec", "tsc", "--", "--noEmit"] :: [String])

defineFrontendTestRules :: Rules ()
defineFrontendTestRules = do
  persistentTask "_build/tests/.vtt-react.timestamp" getFrontendSources $
    cmd_ (Cwd "vtt-react") (["npm", "exec", "vitest", "run"] :: [String])

defineFrontendFormatRules :: Rules ()
defineFrontendFormatRules = do
  -- Formatter
  persistentTask "_build/frontend/.format.timestamp" getFrontendSources $ do
    let files = ["src/**/*.{ts,tsx,css,md}", "!src/generated/**"]
    cmd_ (Cwd "vtt-react") (["npm", "exec", "prettier", "--", "--write"] ++ files)

  -- Format checker
  persistentTask "_build/frontend/.format-check.timestamp" getFrontendSources $ do
    let files = ["src/**/*.{ts,tsx,css,md}", "!src/generated/**"]
    cmd_ (Cwd "vtt-react") (["npm", "exec", "prettier", "--", "--check"] ++ files)
