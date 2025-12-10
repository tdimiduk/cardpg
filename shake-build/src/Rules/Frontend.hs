module Rules.Frontend (defineFrontendRules, defineFrontendTestRules, defineFrontendFormatRules) where

import Common (persistentTask)
import Data.List (isInfixOf)
import Development.Shake
import Development.Shake.FilePath

getFrontendSources :: Action [FilePath]
getFrontendSources = do
  let dir = "vtt-react"
  srcs <-
    getDirectoryFiles dir ["src//*.ts", "src//*.tsx", "package.json", "tsconfig.json", "vite.config.ts"]
  return $ map (dir </>) srcs

getFrontendFormatSources :: Action [FilePath]
getFrontendFormatSources = filter (not . ("/src/generated/" `isInfixOf`)) <$> getFrontendSources

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
  -- We use a filtered source list here to avoid triggering the generation of types
  -- which would require building the codegen tool and thus all of Haskell.
  persistentTask "_build/frontend/.format.timestamp" getFrontendFormatSources $ do
    let files = ["src/**/*.{ts,tsx,css,md}", "!src/generated/**"]
    cmd_ (Cwd "vtt-react") (["npm", "exec", "prettier", "--", "--write"] ++ files)

  -- Format checker
  persistentTask "_build/frontend/.format-check.timestamp" getFrontendFormatSources $ do
    let files = ["src/**/*.{ts,tsx,css,md}", "!src/generated/**"]
    cmd_ (Cwd "vtt-react") (["npm", "exec", "prettier", "--", "--check"] ++ files)
