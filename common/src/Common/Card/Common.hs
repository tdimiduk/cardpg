module Common.Card.Common
  ( CardBlocks
  , CardText
  , CardBlock(..)
  , CardInline(..)
  , asCardBlocks
  , asCardText
  , ResourceType(..)
  , ResourceValue
  , prependToFirstParagraph
  )
where

import Data.Aeson (ToJSON, FromJSON)
import Data.List.NonEmpty (NonEmpty(..), (<|))
import Data.Text (Text)
import GHC.Generics (Generic)

data ResourceType = Red | Yellow | Blue
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

-- TODO this should be a more sophisticated type. These are mostly int's, sometimes absent, eventually maybe text or number + text
type ResourceValue = Maybe Text

data CardInline
  = Txt Text
  | ResourceIcon ResourceType
  | ResourceValue ResourceType ResourceValue
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

type CardText = NonEmpty CardInline

data CardBlock
  = Paragraph CardText
  | ThematicBreak
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

asCardBlocks :: Text -> CardBlocks
asCardBlocks = pure . Paragraph . pure . Txt

asCardText :: Text -> CardText
asCardText = pure . Txt

prependToFirstParagraph :: CardText -> CardBlocks -> CardBlocks
prependToFirstParagraph t bs = case bs of
  ThematicBreak :| _ -> Paragraph t <| bs
  Paragraph p :| rest -> (Paragraph $ t <> p) :| rest

type CardBlocks = NonEmpty CardBlock
