module Main where

import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.IO qualified as T
import Web.Atomic
import Web.Atomic.CSS
import Web.Atomic.Types

import Frontend.Style.Atomic (allStyles)

main :: IO ()
main = do
  putStrLn "Generating CSS..."
  let cssText = renderCss allStyles
  T.writeFile "static/atomic.css" cssText
  putStrLn "Done. Wrote static/atomic.css"

renderCss :: CSS [Rule] -> Text
renderCss (CSS rulesList) = T.unlines $ map renderRule rulesList

renderRule :: Rule -> Text
renderRule r =
  let cName = renderClassName r.className
      props = map renderDecl r.properties
      -- Simple rendering: .classname { prop: val; ... }
      -- Note: simplified, doesn't handle media queries or complex selectors fully yet
      body = T.intercalate " " props
   in "." <> cName <> " { " <> body <> " }"

renderClassName :: ClassName -> Text
renderClassName (ClassName t) = escapeCssClass t

escapeCssClass :: Text -> Text
escapeCssClass = T.concatMap escapeChar
  where
    escapeChar c
      | c `elem` ("!\"#$%&'()*+,./:;<=>?@[\\]^`{|}~" :: String) = "\\" <> T.singleton c
      | otherwise = T.singleton c

renderDecl :: Declaration -> Text
renderDecl (Property p :. Style s) = p <> ": " <> T.pack s <> ";"
