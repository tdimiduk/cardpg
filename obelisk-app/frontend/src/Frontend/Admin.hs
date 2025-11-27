module Frontend.Admin where

import Control.Lens
import Data.Either.Combinators
import Data.Text (Text, pack)
import qualified Data.Text as T

import Reflex.Dom.Core hiding (textInput)

import Common.Api
import Common.Card.Common

admin
  :: ( DomBuilder t m
     , Request m ~ Api
     , Response m ~ Either Text
     , Requester t m
     , MonadHold t m
     )
  => m ()
admin = do
  refresh <- button  "Refresh deck"
  deckName <- snd <$> textInput "deck name" "deck-name" never
  docKey <- snd <$> textInput "Sheet Id" "sheet-id" never
  sheetName <- snd <$> textInput "sheet name" "sheet-name" never
  addConsequences <- button "add consequences"
  addCondition <- button "add conditions"
  resp <- requesting $ Api_RefreshDeck <$> tag (current deckName) refresh
  let
    mkAdd dn key sheet = \t -> Api_AddDeck t dn key sheet
    addSpec = ffor3 deckName docKey sheetName mkAdd
  addResp <- requesting $ attachWith ($) (current addSpec) $ leftmost [ConsequenceCardType <$ addConsequences,
                                                            ConditionCardType <$ addCondition]
  el "div" $ widgetHold_ blank $ either text text <$> leftmost [mapRight (pack . show) <$> resp,
                                                                mapRight (const "success") <$> addResp]
  pure ()

textInput :: (DomBuilder t m) => Text -> Text -> Event t Text -> m (Event t (), Dynamic t Text)
textInput placeholder cls setText = do
  input <- inputElement $ def & setInputClass ("input " <> cls) & setSetValue setText & setPlaceholder placeholder
  let val = T.strip <$> _inputElement_value input
  pure (gateTextEvent (current val) $ keypress Enter input, val)

setPlaceholder :: Text -> InputElementConfig e t s -> InputElementConfig e t s
setPlaceholder val =
  inputElementConfig_elementConfig
    . elementConfig_initialAttributes
    . at "placeholder"
    ?~ val

setInputClass :: Text -> InputElementConfig e t s -> InputElementConfig e t s
setInputClass cls =
  inputElementConfig_elementConfig
    . elementConfig_initialAttributes
    . at "class"
    ?~ cls

setSetValue :: Reflex t => Event t Text -> InputElementConfig e t s -> InputElementConfig e t s
setSetValue event = inputElementConfig_setValue .~ event

gateTextEvent :: (Reflex t) => Behavior t Text -> Event t a -> Event t a
gateTextEvent s = gate (("" /=) <$> s)
