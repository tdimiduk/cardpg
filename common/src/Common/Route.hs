{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Common.Route where

{- -- You will probably want these imports for composing Encoders.
import Prelude hiding (id, (.))
import Control.Category
-}

import Data.Text (Text)
import Data.Functor.Identity
import Data.Aeson.GADT.TH (deriveJSONGADT)
import Data.Constraint.Extras.TH (deriveArgDict)


import Obelisk.Route
import Obelisk.Route.TH

import Common.Api

data BackendRoute :: * -> * where
  -- | Used to handle unparseable routes.
  BackendRoute_Missing :: BackendRoute ()
  -- You can define any routes that will be handled specially by the backend here.
  -- i.e. These do not serve the frontend, but do something different, such as serving static files.
  BackendRoute_WebSocket :: BackendRoute ()

data FrontendRoute :: * -> * where
  FrontendRoute_Main :: FrontendRoute ()
  FrontendRoute_Deck :: FrontendRoute (Maybe Text)
  FrontendRoute_Adhoc :: FrontendRoute (Maybe Text)
  FrontendRoute_Demo :: FrontendRoute ()
  FrontendRoute_Consequences :: FrontendRoute ()
  FrontendRoute_Admin :: FrontendRoute ()
  FrontendRoute_Print :: FrontendRoute (Maybe Text)

fullRouteEncoder
  :: Encoder (Either Text) Identity (R (FullRoute BackendRoute FrontendRoute)) PageName
fullRouteEncoder = mkFullRouteEncoder
  (FullRoute_Backend BackendRoute_Missing :/ ())
  (\case
      BackendRoute_Missing -> PathSegment "missing" $ unitEncoder mempty
      BackendRoute_WebSocket -> PathSegment "api" $ unitEncoder mempty

  )

  (\case
      FrontendRoute_Main -> PathEnd $ unitEncoder mempty
      FrontendRoute_Deck -> PathSegment "deck" $ maybeEncoder (unitEncoder mempty) singlePathSegmentEncoder
      FrontendRoute_Adhoc -> PathSegment "adhoc" $ maybeEncoder (unitEncoder mempty) singlePathSegmentEncoder
      FrontendRoute_Demo -> PathSegment "demo" $ unitEncoder mempty
      FrontendRoute_Consequences -> PathSegment "consequences" $ unitEncoder mempty
      FrontendRoute_Admin -> PathSegment "admin" $ unitEncoder mempty
      FrontendRoute_Print -> PathSegment "print" $ maybeEncoder (unitEncoder mempty) singlePathSegmentEncoder
  )


mconcat <$> sequence
  [ deriveRouteComponent ''BackendRoute
  , deriveRouteComponent ''FrontendRoute
  , deriveJSONGADT ''Api
  , deriveArgDict ''Api
  ]
