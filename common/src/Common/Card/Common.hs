module Common.Card.Common
  ( CardBlocks
  , CardText
  , CardBlock(..)
  , CardInline(..)
  , asCardBlocks
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

instance Semigroup FancyLine where
  (FancyLine a) <> (FancyLine b) = FancyLine $ a <> b

data ResourceType = Red | Yellow | Blue
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

data CardInline
  = Txt Text
  | ResourceIcon ResourceType
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

type CardText = NonEmpty CardInline

data CardBlock
  = Paragraph CardText
  | ThematicBreak
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

asCardBlocks :: Text -> CardBlocks
asCardBlocks t = pure $ Paragraph $ pure $ Txt t

type CardBlocks = NonEmpty CardBlock
