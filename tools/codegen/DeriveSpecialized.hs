module DeriveSpecialized (specializeType, deriveSpecializedInstance) where

import Control.Monad (when)
import Data.Aeson (Options)
import Data.Aeson.TypeScript.TH (deriveTypeScript)
import Data.Map (Map)
import Data.Map qualified as Map
import Language.Haskell.TH

-- | specializeType creates a new concrete data type from a parameterized one by substituting
-- a list of specific types for the type variables.
--
-- Usage:

-- $(specializeType ''BaseCard [ConT ''Identity] "CardWithId")
--
-- This generates:
-- data CardWithId = CardWithId { ... fields with f substituted ... } deriving (Generic)
--
-- It substitutes the first N type parameters found, where N is the length of the provided list of types.
-- Also derives the TypeScript instance using provided Options.

specializeType :: Name -> [Type] -> String -> Q [Dec]
specializeType typeName paramTypes newTypeNameStr = do
  info <- reify typeName
  case info of
    TyConI (DataD _cxt _name binders _kind constructors _deriv) -> do
      let newName = mkName newTypeNameStr

      -- Identify the type variables to substitute.
      let binderNames = map getBinderName binders

      when (length binderNames < length paramTypes) $
        fail $
          "specializeType: Too many parameter types provided. Expected at most " ++ show (length binderNames)

      -- Create substitution map
      let subst = Map.fromList $ zip binderNames paramTypes

      -- Process constructors
      newConstructors <- mapM (substConstructor subst newName) constructors

      -- Generate the new data declaration
      -- We add Generic to deriving clauses to support Aeson/TypeScript derivation
      let derivingClauses = [DerivClause Nothing [ConT (mkName "Generic")]]
      let dataDec = DataD [] newName [] Nothing newConstructors derivingClauses

      return [dataDec]
    _ -> fail "specializeType: Expected a data type declaration"

deriveSpecializedInstance :: Options -> Name -> Name -> [Type] -> Q [Dec]
deriveSpecializedInstance options newName origName paramTypes = do
  -- Generate Primary Instance
  primaryInsts <- deriveTypeScript options newName

  -- Generate Bridge Instance
  let newTypeNameStr = nameBase newName
  let instanceHead = AppT (ConT (mkName "TypeScript")) (foldl AppT (ConT origName) paramTypes)

  let getTypeScriptTypeDec =
        FunD
          (mkName "getTypeScriptType")
          [Clause [WildP] (NormalB (LitE (StringL newTypeNameStr))) []]

  let proxyExp = SigE (ConE (mkName "Proxy")) (AppT (ConT (mkName "Proxy")) (ConT newName))
  let tsTypeExp = AppE (ConE (mkName "TSType")) proxyExp
  let listExp = ListE [tsTypeExp]
  let getParentTypesDec =
        FunD
          (mkName "getParentTypes")
          [Clause [WildP] (NormalB listExp) []]

  let bridgeInstDec = InstanceD Nothing [] instanceHead [getTypeScriptTypeDec, getParentTypesDec]

  return $ primaryInsts ++ [bridgeInstDec]

getBinderName :: TyVarBndr flag -> Name
getBinderName (PlainTV n _) = n
getBinderName (KindedTV n _ _) = n

substConstructor :: Map Name Type -> Name -> Con -> Q Con
substConstructor subst newTypeName (RecC _name fields) = do
  -- For single-constructor records, we often rename constructor to type name
  let newConName = newTypeName
  newFields <- mapM (substField subst) fields
  return $ RecC newConName newFields
substConstructor subst newTypeName (NormalC name fields) = do
  -- For sum types, we prepend the new TypeName to the old ConstructorName to avoid collision
  -- e.g. Rule -> RuleRuleAttack.
  -- We assume Aeson options will be configured to strip this prefix.
  let newConName = mkName (nameBase newTypeName ++ nameBase name)
  newFields <- mapM (substBangType subst) fields
  return $ NormalC newConName newFields
substConstructor _ _ _ = fail "specializeType: Only record and normal constructors are supported"

substField :: Map Name Type -> (Name, Bang, Type) -> Q (Name, Bang, Type)
substField subst (name, bang, type_) = do
  newType <- substType subst type_
  return (name, bang, newType)

substBangType :: Map Name Type -> (Bang, Type) -> Q (Bang, Type)
substBangType subst (bang, type_) = do
  newType <- substType subst type_
  return (bang, newType)

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
  ListT -> return ListT
  ConT n -> return (ConT n)
  _ -> return t


