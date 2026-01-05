{-# LANGUAGE OverloadedStrings #-}

-- Legacy. We are moving styling to tailwind. Delete this once we are confident we get good enough styling from the tailwind styling.

module Frontend.Style where

import Data.Text (Text)

appCss :: Text
appCss =
  ".name {\n\
  \  font-size: 10;\n\
  \}\n\
  \\n\
  \body {\n\
  \  margin: 0;\n\
  \}\n\
  \\n\
  \.card {\n\
  \  width: 56mm;\n\
  \  /* height: 83mm; */\n\
  \  height: 80mm;\n\
  \  border: solid 0.2mm;\n\
  \  break-inside: avoid;\n\
  \  display: flex;\n\
  \  flex-direction: column;\n\
  \  padding: 3mm;\n\
  \}\n\
  \\n\
  \.art {\n\
  \  flex-grow: 1;\n\
  \  height: 33mm;\n\
  \}\n\
  \\n\
  \.art-short {\n\
  \  height: 22.849mm;\n\
  \}\n\
  \\n\
  \.cost {\n\
  \  display: flex;\n\
  \  /* Aim for the aspect ratio of a magic card */\n\
  \  min-height: 1.117em;\n\
  \  min-width: 0.8em;\n\
  \  border-style: solid;\n\
  \  border-width: 0.15em;\n\
  \  border-radius: 1mm;\n\
  \  justify-content: center;\n\
  \}\n\
  \\n\
  \.outline {\n\
  \  outline: solid 0.2mm;\n\
  \  padding: 1mm;\n\
  \  border-radius: 1mm;\n\
  \}\n\
  \\n\
  \.textbox {\n\
  \  flex-grow: 1;\n\
  \  border: solid 0.2mm;\n\
  \  margin-top: 2mm;\n\
  \  padding: 1mm;\n\
  \  border-radius: 1mm;\n\
  \}\n\
  \\n\
  \.textbox p {\n\
  \  margin-top: 0;\n\
  \  margin-bottom: 0.1em;\n\
  \}\n\
  \\n\
  \.numbers {\n\
  \  display: flex;\n\
  \  /* height: 4.5em; */\n\
  \  flex-direction: column;\n\
  \  justify-content: space-between;\n\
  \  margin-top: 1mm;\n\
  \  margin-bottom: 3mm;\n\
  \  vertical-align: middle;\n\
  \  align-items: center;\n\
  \}\n\
  \\n\
  \.numbers .resource-symbol {\n\
  \  width: 1em;\n\
  \  height: 1em;\n\
  \}\n\
  \\n\
  \.textbox .resource-symbol {\n\
  \  width: 0.8em;\n\
  \  height: 0.8em;\n\
  \  margin-right: 0.15em;\n\
  \}\n\
  \\n\
  \.textbox .resource-symbol.blue {\n\
  \  width: 0.65em;\n\
  \  height: 0.65em;\n\
  \  margin-right: 0.15em;\n\
  \}\n\
  \\n\
  \.cards {\n\
  \  display: flex;\n\
  \  flex: 60mm;\n\
  \  flex-wrap: wrap;\n\
  \}\n\
  \\n\
  \.red {\n\
  \  border-color: red;\n\
  \}\n\
  \\n\
  \.yellow {\n\
  \  border-color: gold;\n\
  \}\n\
  \\n\
  \.blue {\n\
  \  border-color: blue;\n\
  \}\n\
  \\n\
  \.resource-symbol {\n\
  \  display: inline-block;\n\
  \  vertical-align: middle;\n\
  \  border-style: solid;\n\
  \  border-width: 0.15em;\n\
  \  border-radius: 0.15em;\n\
  \}\n\
  \\n\
  \textarea {\n\
  \  width: 90%;\n\
  \  min-height: 40em;\n\
  \}\n\
  \\n\
  \.flex {\n\
  \  display: flex;\n\
  \}\n\
  \\n\
  \.flex-row {\n\
  \  flex-direction: row;\n\
  \}\n\
  \\n\
  \.flex-col {\n\
  \  flex-direction: column;\n\
  \}\n\
  \\n\
  \.expand {\n\
  \  flex-grow: 1;\n\
  \}\n\
  \\n\
  \.resource-number {\n\
  \  vertical-align: middle;\n\
  \  text-align: center;\n\
  \  width: inherit;\n\
  \  height: inherit;\n\
  \}\n\
  \\n\
  \.resource-symbol.blue {\n\
  \  transform:rotate(45deg);\n\
  \  margin: 0.1em;\n\
  \}\n\
  \\n\
  \.resource-symbol.blue > .resource-number {\n\
  \  transform: rotate(-45deg);\n\
  \}\n\
  \\n\
  \.resource-symbol.yellow {\n\
  \  border-radius: 50%;\n\
  \}\n\
  \\n\
  \.numbers .resource-symbol.yellow {\n\
  \  margin-bottom: 0.1em;\n\
  \}\n\
  \\n\
  \.w-18 {\n\
  \  width: 4.5rem;\n\
  \}\n\
  \\n\
  \.h-18 {\n\
  \  height: 4.5rem;\n\
  \}\n\
  \"
