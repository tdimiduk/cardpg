{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Core.Layout
  ( LayoutItem (..)
  , layoutRule
  , layoutAttackDef
  , layoutGeneralDef
  , layoutOngoingDef
  , layoutPassiveDef
  , layoutTaskDef
  , layoutTriggerDef
  , layoutStackPower
  , layoutDifficulty
  ) where

import Data.Maybe (catMaybes)
import Data.Text (Text)

import Core.Language
  ( cmdAction
  , cmdAttack
  , cmdOngoing
  , cmdPassive
  , cmdTask
  , cmdWhen
  , kwCheck
  , kwCost
  , kwStr
  , kwTime
  , sepArrow
  , sepColon
  , sepSemi
  )
import Core.NonEmptyText (getRawText)
import Core.RichText (RichText)
import Core.RuleDefs
  ( AttackDef (..)
  , GeneralDef (..)
  , OngoingDef (..)
  , PassiveDef (..)
  , Rule (..)
  , TaskDef (..)
  , TriggerDef (..)
  )
import Core.Stats
  ( Difficulty (..)
  , ResourceType (..)
  , StackPower (..)
  , prettyModifier
  )
import Core.Util (tshow)

-- | Abstract representation of a rule's display components.
data LayoutItem
  = -- | Keywords like "Action:", "When", "Check", etc.
    Keyword Text
  | -- | A resource icon, potentially with text inside
    Symbol ResourceType (Maybe Text)
  | -- | Plain text literals (names, separators like "->")
    Literal Text
  | -- | Rich text content
    RichContent RichText
  | -- | Logical grouping (often rendered with parens)
    Group [LayoutItem]
  | -- | Explicit spacing
    Space
  deriving (Eq, Show)

--------------------------------------------------------------------------------
-- Layout Functions
--------------------------------------------------------------------------------

layoutRule :: Rule -> [LayoutItem]
layoutRule (RuleGeneral def) = layoutGeneralDef def
layoutRule (RuleOngoing def) = layoutOngoingDef def
layoutRule (RulePassive def) = layoutPassiveDef def
layoutRule (RuleTask def) = layoutTaskDef def
layoutRule (RuleTrigger def) = layoutTriggerDef def
layoutRule (RuleNarrative rt) = [RichContent rt]

layoutAttackDef :: AttackDef -> [LayoutItem]
layoutAttackDef def =
  [ Keyword cmdAttack
  , Space
  , Symbol def.resistedBy Nothing
  , Literal sepColon
  , Space
  , Keyword kwStr
  , Literal " = "
  ]
    <> layoutStackPower def.power
    <> case def.effect of
      Nothing -> []
      Just e ->
        [ Space
        , Literal sepArrow
        , Space
        , RichContent e
        ]

layoutGeneralDef :: GeneralDef -> [LayoutItem]
layoutGeneralDef def =
  [ Keyword cmdAction
  , Space
  , Literal (getRawText def.name)
  ]
    <> maybe [] (\c -> [Space, Group (layoutWrapper [RichContent c])]) def.cost
    <> maybe [] (\d -> [Space] <> layoutDifficulty d) def.difficulty
    <> [Space, Literal sepArrow, Space, RichContent def.effect]

layoutOngoingDef :: OngoingDef -> [LayoutItem]
layoutOngoingDef def =
  [ Keyword cmdOngoing
  , Space
  , Group (layoutWrapper [RichContent def.life])
  , Literal sepArrow
  , Space
  , RichContent def.effect
  ]

layoutPassiveDef :: PassiveDef -> [LayoutItem]
layoutPassiveDef def =
  [ Keyword cmdPassive
  , Space
  ]
    <> layoutStackPower def.bonus
    <> maybe [] (\c -> [Space, Literal (getRawText c)]) def.condition

layoutTaskDef :: TaskDef -> [LayoutItem]
layoutTaskDef def =
  [ Keyword cmdTask
  , Space
  , Literal (getRawText def.name)
  ]
    <> renderTaskParts
    <> [Space, Literal sepArrow, Space, RichContent def.effect]
  where
    renderTaskParts =
      let parts =
            catMaybes
              [ fmap (\c -> [Keyword kwCheck, Space] <> layoutDifficulty c) def.check
              , fmap (\t -> [Keyword kwTime, Space, RichContent t]) def.time
              , fmap (\c -> [Keyword kwCost, Space, RichContent c]) def.cost
              ]
       in if null parts
            then []
            else [Space, Group (layoutWrapper (intercalateLayout [Literal sepSemi, Space] parts))]

layoutTriggerDef :: TriggerDef -> [LayoutItem]
layoutTriggerDef def =
  [ Keyword cmdWhen
  , Space
  , Literal (getRawText def.trigger)
  , Space
  , Literal sepArrow
  , Space
  , RichContent def.effect
  ]

--------------------------------------------------------------------------------
-- Component Layouts
--------------------------------------------------------------------------------

layoutStackPower :: StackPower -> [LayoutItem]
layoutStackPower (StackPower base 0 Nothing) = [Symbol base Nothing]
layoutStackPower (StackPower base modifier conditional) =
  [ Symbol base Nothing
  , Space
  , Literal (prettyModifier modifier)
  ]
    <> maybe [] (\c -> [Space, Literal c]) conditional

layoutDifficulty :: Difficulty -> [LayoutItem]
layoutDifficulty (Difficulty base val) = [Symbol base (Just $ tshow val)]

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

-- | Wraps items in parentheses (abstractly, though Group often implies this)
-- Here we make it explicit for the Group content.
-- Actually, the TextRep logic puts parens around cost/time/etc.
-- We can define `Group` to MEAN "wrapped in parens" or just generic grouping.
-- Let's stick to the current usages: " (" <> content <> ")"
layoutWrapper :: [LayoutItem] -> [LayoutItem]
layoutWrapper items = items

intercalateLayout :: [LayoutItem] -> [[LayoutItem]] -> [LayoutItem]
intercalateLayout _ [] = []
intercalateLayout _ [x] = x
intercalateLayout sep (x : xs) = x <> sep <> intercalateLayout sep xs
