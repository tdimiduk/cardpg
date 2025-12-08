module Rules.Codegen where

import Development.Shake

import Common (getPackageSources)

getCodegenSources :: Action [FilePath]
getCodegenSources = getPackageSources "tools/codegen" "."

getCardCompilerSources :: Action [FilePath]
getCardCompilerSources = getPackageSources "tools/card-compiler" "."


buildGenTypes :: Action ()
buildGenTypes = need 
    [ "vtt-react/src/generated/types.ts"
    , "vtt-react/src/generated/types.zod.ts"
    ]

defineCodegenRules :: Rules ()
defineCodegenRules = do
    "_build/codegen" %> \out -> do
        -- We need core and server sources too.
        -- Usage of `getPackageSources` directly here:
        coreSrcs <- getPackageSources "cardpg-core" "src"
        serverSrcs <- getPackageSources "cardpg-server" "src"
        codegenSrcs <- getPackageSources "tools/codegen" "."
        
        need (coreSrcs ++ serverSrcs ++ codegenSrcs)
        
        cmd_ (["cabal", "build", "codegen"] :: [String])
        Stdout binPath <- cmd (["cabal", "list-bin", "codegen"] :: [String])
        copyFile' (head $ lines binPath) out

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
