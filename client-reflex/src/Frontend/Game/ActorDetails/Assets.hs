{-# LANGUAGE OverloadedRecordDot #-}

module Frontend.Game.ActorDetails.Assets
  ( equippedWidget
  , traitsWidget
  ) where

import Control.Monad (void)
import Control.Monad.Fix (MonadFix)
import Data.Map qualified as Map
import Data.Text (Text)
import Reflex.Dom.Core
import Prelude hiding (filter, id, map)

import Core.Card (ItemCard (..), NatureCard (..), TalentCard (..))
import Core.NonEmptyText (getRawText)
import Core.Primitives (EquipSlot (..), Identified (..))
import Core.State (ActorState (..), AssetState (..), TableCard (..), TableState (..))
import Core.Util (tshow)
import Frontend.Style.Common
import Frontend.Style.DSL qualified as S

equippedWidget
  :: (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m, Adjustable t m)
  => Dynamic t ActorState
  -> m ()
equippedWidget actorState = do
  let equippedDyn = fmap getEquippedItems actorState
      goldFrameStyle =
        S.css "bg-stone-med" "background-color" "var(--color-stone-med)"
          . S.border1
          . S.border S.Yellow 5
          . S.shadowSm
  assetSectionWidget "Equipped" goldFrameStyle equippedDyn $ \itemDyn -> do
    dyn_ $ ffor itemDyn $ \(_, slot) -> do
      case slot of
        SlotUnspecified -> return ()
        _ -> text (tshow slot)

traitsWidget
  :: (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m, Adjustable t m)
  => Dynamic t ActorState
  -> m ()
traitsWidget actorState = do
  let traitsDyn = fmap getTraits actorState
      mysticAuraStyle = S.cls "mystic-traits-aura"
  assetSectionWidget "Traits" mysticAuraStyle traitsDyn $ \itemDyn -> do
    dynText $ fmap (cardType . fst) itemDyn

assetSectionWidget
  :: (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m, Adjustable t m, Eq a)
  => Text
  -> Style
  -> Dynamic t [(TableCard, a)]
  -> (Dynamic t (TableCard, a) -> m ())
  -> m ()
assetSectionWidget headerText rowStyle itemsDyn renderDetail = do
  -- Optimally only rebuild the container when ensuring empty/non-empty state changes
  hasItems <- holdUniqDyn $ fmap (not . null) itemsDyn

  dyn_ $ ffor hasItems $ \showItems ->
    if not showItems
      then blank
      else do
        divS
          ( S.flexCol
              . S.gap S.S2
              . S.p S.S2
              . S.cls "obsidian-panel"
              . S.rounded
              . S.text S.Gray 1
              . S.mt S.S2
          )
          $ do
            elS
              "h2"
              ( S.textSm
                  . S.fontBold
                  . S.uppercase
                  . S.cls "fantasy-font"
                  . S.css "text-gold-bright" "color" "var(--color-gold-bright)"
              )
              $ text headerText

            void $ simpleList itemsDyn $ \itemDyn -> do
              divS
                (S.flex . S.justifyBetween . S.itemsCenter . rowStyle . S.p S.S1 . S.rounded . S.mb S.S1)
                $ do
                  -- Display Name
                  let nameDyn = fmap fst itemDyn
                  divS (S.textXs . S.px S.S1 . S.fontBold) $
                    dynText $
                      fmap (\c -> getRawText c.name) nameDyn

                  -- Display Detail (Slot or Type)
                  divS (S.textXs . S.text S.Gray 4 . S.css "italic" "font-style" "italic") $
                    renderDetail itemDyn

getEquippedItems :: ActorState -> [(TableCard, EquipSlot)]
getEquippedItems as =
  [ (c, slot)
  | (_, (Identified _ c, Equipped slot)) <- Map.toList as.tableState.assets
  ]

getTraits :: ActorState -> [(TableCard, AssetState)]
getTraits as =
  [ (c, state)
  | (_, (Identified _ c, state)) <- Map.toList as.tableState.assets
  , state == Trait
  ]

cardType :: TableCard -> Text
cardType (TCItem _) = "Item"
cardType (TCNature _) = "Nature"
cardType (TCTalent _) = "Talent"
