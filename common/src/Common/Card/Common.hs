module Common.Card.Common
  ( CardText(..)
  , CardBlock(..)
  , CardInline(..)
  , asCardText
  , ResourceType(..)
  )
where

import Data.Aeson (ToJSON, FromJSON)
import Data.List.NonEmpty (NonEmpty(..))
import Data.Text (Text)
import GHC.Generics (Generic)

data FancyToken = FancyTextToken Text | ResourceToken ResourceType
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

data FancyText = FancyText (NonEmpty FancyLine)
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

data FancyLine = FancyLine (NonEmpty FancyToken)
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

data ResourceType = Red | Yellow | Blue
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

data CardInline
  = Txt Text
  | ResourceIcon ResourceType
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

data CardBlock
  = Paragraph (NonEmpty CardInline)
  | ThematicBreak
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

asCardText :: Text -> CardText
asCardText t = CardText (pure $ Paragraph $ pure $ Txt t)

data CardText = CardText (NonEmpty CardBlock)
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

instance Semigroup CardText where
  (CardText a) <> (CardText b) = CardText $ a <> b
