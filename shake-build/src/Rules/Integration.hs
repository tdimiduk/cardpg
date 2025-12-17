module Rules.Integration (runIntegrationTests) where

import Control.Exception (bracket)
import Control.Monad (unless, void)
import Data.List (isInfixOf)
import Development.Shake
import System.Environment (getEnvironment)
import System.Exit (ExitCode (..))
import System.IO (BufferMode (..), Handle, hGetLine, hIsEOF, hSetBuffering, stdout)
import System.Process
  ( CreateProcess (..)
  , StdStream (..)
  , createProcess
  , proc
  , readProcessWithExitCode
  , terminateProcess
  , waitForProcess
  )

-- | Run integration tests
-- This action starts the server, runs the frontend integration tests, and then shuts down the server.
runIntegrationTests :: Action ()
runIntegrationTests = do
  -- Ensure clean state dependencies
  need ["gen-types", "vtt-react/src/data/generated_cards.json"]

  -- Build the server first to ensure it's ready
  cmd_ (["cabal", "build", "cardpg-server"] :: [String])

  -- Run the orchestration in IO
  liftIO runIntegrationTestsIO

runIntegrationTestsIO :: IO ()
runIntegrationTestsIO = do
  hSetBuffering stdout NoBuffering
  putStrLn "Starting integration tests..."

  -- Pick a port for testing
  let port = "3001"

  -- Setup server process
  let serverProc =
        (proc "cabal" ["run", "cardpg-server"])
          { env = Just [("PORT", port)] -- We rely on inheriting other envs or just setting this one?
          -- Ideally we inherit PATH etc. proc does inherit if env is nothing, but replaces if Just.
          -- We need to merge.
          , std_out = CreatePipe
          , std_err = Inherit
          }

  -- Capture current environment to merge
  currEnv <- System.Environment.getEnvironment
  let testEnv = ("PORT", port) : ("CARDPG_USE_IN_MEMORY_DB", "true") : currEnv
  let serverProcWithEnv = serverProc{env = Just testEnv}

  bracket
    (createProcess serverProcWithEnv)
    ( \(_, _, _, ph) -> do
        putStrLn "Stopping test server..."
        terminateProcess ph
        -- maybe wait for it to die?
        void $ waitForProcess ph
    )
    ( \(_, Just hOut, _, _) -> do
        putStrLn "Waiting for server to start..."
        waitForServer hOut

        putStrLn "Server ready. Running frontend tests..."
        -- Run vitest
        -- We run npm run test:integration
        -- We assume the test config hardcodes 3001 or reads TEST_PORT.

        callProcess "npm" ["run", "test:integration", "--prefix", "vtt-react"]
    )

waitForServer :: System.IO.Handle -> IO ()
waitForServer hOut = go
  where
    go = do
      isEof <- hIsEOF hOut
      if isEof
        then fail "Server process ended unexpectedly"
        else do
          line <- hGetLine hOut
          putStrLn $ "[SERVER] " ++ line
          unless ("Starting CardPG Server on port" `isInfixOf` line) go

callProcess :: String -> [String] -> IO ()
callProcess exe args = do
  (exitCode, out, err) <- readProcessWithExitCode exe args ""
  putStrLn out
  putStrLn err
  case exitCode of
    ExitSuccess -> return ()
    ExitFailure c -> fail $ "Command failed with code " ++ show c ++ "\nSTDOUT:\n" ++ out ++ "\nSTDERR:\n" ++ err
