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
import Frontend.Style

equippedWidget
  :: (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m, Adjustable t m)
  => Dynamic t ActorState
  -> m ()
equippedWidget actorState = do
  let equippedDyn = fmap getEquippedItems actorState
  assetSectionWidget "Equipped" equippedDyn $ \itemDyn -> do
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
  assetSectionWidget "Traits" traitsDyn $ \itemDyn -> do
    dynText $ fmap (cardType . fst) itemDyn

assetSectionWidget
  :: (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m, Adjustable t m, Eq a)
  => Text
  -> Dynamic t [(TableCard, a)]
  -> (Dynamic t (TableCard, a) -> m ())
  -> m ()
assetSectionWidget headerText itemsDyn renderDetail = do
  -- Optimally only rebuild the container when ensuring empty/non-empty state changes
  hasItems <- holdUniqDyn $ fmap (not . null) itemsDyn

  dyn_ $ ffor hasItems $ \showItems ->
    if not showItems
      then blank
      else do
        divStyle ["flex", "flex-col", "gap-2", "p-2", "bg-slate-800", rounded, "text-slate-100", "mt-2"] $ do
          elStyle "h2" [textSm, fontBold, uppercase, "text-slate-400"] $ text headerText

          void $ simpleList itemsDyn $ \itemDyn -> do
            divStyle ["flex", "flex-row", justifyBetween, itemsCenter, "bg-slate-700", "p-1", rounded, "mb-1"] $ do
              -- Display Name
              let nameDyn = fmap fst itemDyn
              divStyle [textXs, "px-1"] $
                dynText $
                  fmap
                    ( \case
                        TCItem (ItemCard{name}) -> getRawText name
                        TCNature (NatureCard{name}) -> getRawText name
                        TCTalent (TalentCard{name}) -> getRawText name
                    )
                    nameDyn

              -- Display Detail (Slot or Type)
              divStyle [textXs, "text-slate-400", "italic"] $
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
