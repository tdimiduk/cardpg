module Rules.Codegen where

import Development.Shake

import Common (getPackageSources)

getCodegenSources :: Action [FilePath]
getCodegenSources = getPackageSources "tools/codegen" "."

getCardCompilerSources :: Action [FilePath]
getCardCompilerSources = getPackageSources "tools/card-compiler" "."

buildGenTypes :: Action ()
buildGenTypes =
  need
    [ "vtt-react/src/generated/types.ts"
    , "vtt-react/src/generated/types.zod.ts"
    ]

defineCodegenRules :: Rules ()
defineCodegenRules = do
  "_build/codegen" %> \out -> do
    -- We need core and server sources too.
    -- Safe replacement for head
    srcs <- getDirectoryFiles "" ["tools/codegen//*.hs"]
    case srcs of
      [] -> fail "No source files found for codegen"
      (s : _) -> need [s] -- We just need to trigger on some source change, though ideally we explicitly list mainverSrcs ++ codegenSrcs)
    cmd_ (["cabal", "build", "codegen"] :: [String])
    Stdout binPath <- cmd (["cabal", "list-bin", "codegen"] :: [String])
    let binPath' = case lines binPath of
          (p : _) -> p
          [] -> error "No bin path returned"
    copyFile' binPath' out

  "vtt-react/src/generated/types.ts" %> \out -> do
    need ["_build/codegen"]
    cmd_ (["_build/codegen", out] :: [String])
    cmd_ (["npm", "exec", "prettier", "--", "--write", out] :: [String])

  "vtt-react/src/generated/types.zod.ts" %> \out -> do
    let src = "vtt-react/src/generated/types.ts"
    let config = "vtt-react/ts-to-zod.config.cjs"
    need [src, config]
    -- Run ts-to-zod in vtt-react directory
    cmd_ (Cwd "vtt-react") (["npm", "exec", "ts-to-zod"] :: [String])
    cmd_ (["npm", "exec", "prettier", "--", "--write", out] :: [String])
