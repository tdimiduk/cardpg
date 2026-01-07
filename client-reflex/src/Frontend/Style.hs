{-# LANGUAGE OverloadedStrings #-}

module Frontend.Style where

import Data.String (IsString (..))
import Data.Text (Text)
import Data.Text qualified as T
import Reflex.Dom.Core (DomBuilder, divClass, elClass)

-- | A newtype wrapper for a single Tailwind class (or a small group of classes that always go together)
newtype Class = Class {unClass :: Text}
  deriving (Eq, Show, Ord)

instance IsString Class where
  fromString = Class . T.pack

-- | Convert a list of classes to a space-separated Text for use in DOM attributes
classes :: [Class] -> Text
classes = T.intercalate " " . map (.unClass)

-- | Helper to create a div with a list of typed classes
divStyle :: (DomBuilder t m) => [Class] -> m a -> m a
divStyle cls = divClass (classes cls)

-- | Helper to create an element with a list of typed classes
elStyle :: (DomBuilder t m) => Text -> [Class] -> m a -> m a
elStyle tag cls = elClass tag (classes cls)

-- * Layout

flex :: Class
flex = "flex"

flexCol :: Class
flexCol = "flex-col"

flexRow :: Class
flexRow = "flex-row"

itemsCenter :: Class
itemsCenter = "items-center"

itemsEnd :: Class
itemsEnd = "items-end"

justifyBetween :: Class
justifyBetween = "justify-between"

justifyCenter :: Class
justifyCenter = "justify-center"

grow :: Class
grow = "grow"

wFull :: Class
wFull = "w-full"

hAuto :: Class
hAuto = "h-auto"

hFull :: Class
hFull = "h-full"

relative :: Class
relative = "relative"

absolute :: Class
absolute = "absolute"

overflowHidden :: Class
overflowHidden = "overflow-hidden"

hidden :: Class
hidden = "hidden"

bottom0 :: Class
bottom0 = "bottom-0"

left0 :: Class
left0 = "left-0"

right0 :: Class
right0 = "right-0"

pointerEventsNone :: Class
pointerEventsNone = "pointer-events-none"

pointerEventsAuto :: Class
pointerEventsAuto = "pointer-events-auto"

cursorPointer :: Class
cursorPointer = "cursor-pointer"

group :: Class
group = "group"

-- * Spacing

-- (We can add typed helpers here if we assume standard tailwind scale, but for now we often use arbitrary values)

p1 :: Class
p1 = "p-1"

p1_5 :: Class
p1_5 = "p-1.5"

-- * Appearance

rounded :: Class
rounded = "rounded"

roundedNone :: Class
roundedNone = "rounded-none"

roundedSm :: Class
roundedSm = "rounded-sm"

border :: Class
border = "border"

border2 :: Class
border2 = "border-2"

borderB :: Class
borderB = "border-b"

borderT :: Class
borderT = "border-t"

borderL :: Class
borderL = "border-l"

borderR :: Class
borderR = "border-r"

shadowXl :: Class
shadowXl = "shadow-xl"

shadowNone :: Class
shadowNone = "shadow-none"

truncateText :: Class
truncateText = "truncate"

-- * Colors (Common Palette)

bgSlate900 :: Class
bgSlate900 = "bg-slate-900"

bgSlate800 :: Class
bgSlate800 = "bg-slate-800"

bgWhite :: Class
bgWhite = "bg-white"

bgTransparent :: Class
bgTransparent = "bg-transparent"

textSlate100 :: Class
textSlate100 = "text-slate-100"

textSlate200 :: Class
textSlate200 = "text-slate-200"

textBlack :: Class
textBlack = "text-black"

-- * Typography

textBase :: Class
textBase = "text-base"

textXs :: Class
textXs = "text-xs"

textSm :: Class
textSm = "text-sm"

fontBold :: Class
fontBold = "font-bold"

borderSlate600 :: Class
borderSlate600 = "border-slate-600"

borderSlate700 :: Class
borderSlate700 = "border-slate-700"

borderBlack :: Class
borderBlack = "border-black"
