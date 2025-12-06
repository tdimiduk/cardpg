{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE LambdaCase #-}

module DeriveSpecialized (specializeType) where

import Language.Haskell.TH
import Data.Map (Map)
import qualified Data.Map as Map

-- | specializeType creates a new concrete data type from a parameterized one by substituting
-- a specific type for a type variable.
--
-- Usage:
-- $(specializeType ''BaseCard (ConT ''Identity) "CardWithId")
--
-- This generates:
-- data CardWithId = CardWithId { ... fields with f substituted ... } deriving (Generic)
--
-- Note: This currently assumes the type has a single constructor and uses record syntax.
-- It substitutes the first type parameter found.
specializeType :: Name -> Type -> String -> Q [Dec]
specializeType typeName paramType newTypeNameStr = do
  info <- reify typeName
  case info of
    TyConI (DataD _cxt _name binders _kind constructors _deriv) -> do
      let newName = mkName newTypeNameStr
      
      -- Identify the type variable to substitute.
      -- Assuming the first binder is the one to substitute.
      let (targetVar, _otherBinders) = case binders of
            (b:_) -> (getBinderName b, [])
            [] -> error "specializeType: Type has no parameters to specialize"
            
      -- Create substitution map
      let subst = Map.singleton targetVar paramType
      
      -- Process constructors
      newConstructors <- mapM (substConstructor subst newName) constructors
      
      -- Generate the new data declaration
      -- We add Generic to deriving clauses to support Aeson/TypeScript derivation
      let derivingClauses = [DerivClause Nothing [ConT (mkName "Generic")]]
      
      return [DataD [] newName [] Nothing newConstructors derivingClauses]
      
    _ -> fail "specializeType: Expected a data type declaration"

getBinderName :: TyVarBndr flag -> Name
getBinderName (PlainTV n _) = n
getBinderName (KindedTV n _ _) = n

substConstructor :: Map Name Type -> Name -> Con -> Q Con
substConstructor subst newTypeName (RecC _name fields) = do
  -- We rename the constructor to match the new type name.
  -- This is a common pattern for single-constructor types.
  let newConName = newTypeName
  newFields <- mapM (substField subst) fields
  return $ RecC newConName newFields
substConstructor _ _ _ = fail "specializeType: Only record constructors are supported"

substField :: Map Name Type -> (Name, Bang, Type) -> Q (Name, Bang, Type)
substField subst (name, bang, type_) = do
  newType <- substType subst type_
  return (name, bang, newType)

substType :: Map Name Type -> Type -> Q Type
substType subst t = case t of
  VarT n -> case Map.lookup n subst of
    Just replacement -> return replacement
    Nothing -> return t
  AppT t1 t2 -> AppT <$> substType subst t1 <*> substType subst t2
  ForallT b c t' -> do
    -- Note: Shadowing check omitted for simplicity. 
    -- If the type variable being substituted is shadowed here, this might be incorrect.
    -- For simple data types, this is usually not an issue.
    substType subst t' >>= \t'' -> return (ForallT b c t'')
  SigT t' k -> SigT <$> substType subst t' <*> pure k
  _ -> return t
