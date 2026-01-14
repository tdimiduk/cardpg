module Frontend.Util where

import Data.Text (Text)
import Reflex.Dom.Core

import Api.Request

type ApiRequester t m = (ApiRequester' t m, ApiRequester' t (Client m))
type ApiRequester' t m = (Requester t m, Request m ~ ApiRequest, Response m ~ Either Text)
