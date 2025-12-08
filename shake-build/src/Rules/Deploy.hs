module Rules.Deploy where

import Development.Shake
import System.Environment (lookupEnv)
import System.Exit (ExitCode(..))

serverHost :: String
serverHost = "tgd.me"

rootAt :: String
rootAt = "root" <> "@" <> serverHost

-- | Deploy routine
deploy :: Bool -> Action ()
deploy forceRebuild = do
    -- 1. Check for NIX_SIGNING_KEY
    key <- liftIO $ lookupEnv "NIX_SIGNING_KEY"
    case key of
        Nothing -> fail "NIX_SIGNING_KEY must be set to deploy"
        Just k ->  do
            putInfo $ "Deploying with key: " ++ k

            -- 2. Build package
            putInfo "Building default.nix..."
            cmd_ (["nix-build", "default.nix"] :: [String])
            Stdout packageOut <- cmd (["nix-build", "default.nix", "--no-out-link"] :: [String])
            let packageLines = lines packageOut
            if null packageLines
                then fail "No package output from nix-build"
                else return ()
            let package = head packageLines
            putInfo $ "Built package: " ++ package

            -- 3. Sign package
            putInfo "Signing package..."
            cmd_ (EchoStdout True) (EchoStderr True) (["nix", "store", "sign", "-r", "--key-file", k, package] :: [String])

            -- 4. Copy to server
            putInfo "Copying to server..."
            cmd_ (EchoStdout True) (EchoStderr True) (["nix", "copy", "--to", "ssh://" <> rootAt, "--verbose", package] :: [String])

            -- 5. Detect change in cardpg-service.nix
            let serviceFile = "deploy/cardpg-service.nix"
            let lastServiceFile = "_build/deploy/cardpg-service.nix.last"
            
            -- We can't easily use diff in pure Shake Action without just running diff
            -- Return codes: 0 = same, 1 = different, 2 = trouble
            -- We want to ignore exit code 1
            (Exit code, Stderr _, Stdout _) <- cmd (["cmp", "-s", serviceFile, lastServiceFile] :: [String]) :: Action (Exit, Stderr String, Stdout String)
            let changed = code /= ExitSuccess
            
            let shouldRebuild = forceRebuild || changed

            -- 6. Update symlink
            putInfo "Updating symlink..."
            let targetLink = "/sites/cardpg.tgd.me"
            cmd_ (EchoStdout True) (EchoStderr True) (["ssh", rootAt, "mkdir", "-p", "/sites"] :: [String])
            cmd_ (EchoStdout True) (EchoStderr True) (["ssh", rootAt, "ln", "-sfn", package, targetLink] :: [String])

            if shouldRebuild
                then do
                    putInfo "Service changed or rebuild forced. Rebuilding NixOS..."
                    -- Rsync service file
                    cmd_ (EchoStdout True) (EchoStderr True) (["rsync", "-rav", serviceFile, rootAt <> ":/etc/nixos/"] :: [String])
                    
                    -- Rebuild
                    cmd_ (EchoStdout True) (EchoStderr True) (["ssh", rootAt, "nixos-rebuild", "switch"] :: [String])
                    
                    -- Update last file
                    cmd_ (["mkdir", "-p", "_build/deploy"] :: [String])
                    cmd_ (["cp", serviceFile, lastServiceFile] :: [String])
                else
                    putInfo "Service file unchanged. Skipping nixos-rebuild."

            -- 7. Restart service
            putInfo "Restarting service..."
            cmd_ (EchoStdout True) (EchoStderr True) (["ssh", rootAt, "systemctl", "restart", "cardpg"] :: [String])

            -- 8. Log deployment
            Stdout githash <- cmd (["git", "rev-parse", "--verify", "HEAD"] :: [String])
            Stdout gitmsg <- cmd (["git", "log", "-1", "--pretty=%B"] :: [String])
            let githashStr = case lines githash of
                    (x:_) -> x
                    [] -> "unknown"
            let gitmsgStr = case lines gitmsg of
                    (x:_) -> x
                    [] -> "unknown"
            putInfo $ "Deployed " ++ githashStr ++ ": " ++ gitmsgStr
