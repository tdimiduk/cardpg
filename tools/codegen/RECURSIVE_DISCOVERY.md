# Recursive TypeScript Type Discovery Explained

This document explains the mechanism used in `Main.hs` to automatically discover and export all dependent TypeScript types from a small set of root types. This approach leverages **Existential Quantification**, **Runtime Type Reflection (`Typeable`)**, and **Template Haskell**.

## The Problem

Previously, the codegen tool required a manually maintained list of every single type to be exported.
```haskell
-- Old way: Manual list
formatTSDeclarations (
  getTypeScriptDeclarations (Proxy :: Proxy ServerMessage) <>
  getTypeScriptDeclarations (Proxy :: Proxy ActorState) <>
  getTypeScriptDeclarations (Proxy :: Proxy Card) <>
  ... -- easy to forget one!
)
```
If `ServerMessage` contained a `Card`, but `Card` wasn't in the list, the generated TypeScript for `ServerMessage` would refer to `Card`, but `Card`'s definition would be missing, causing TypeScript errors.

## The Solution: Graph Traversal

Since types form a dependency graph (e.g., `ServerMessage` -> `GameState` -> `ActorState` -> `Stats`), we can traverse this graph starting from the roots.

### 1. The `TypeScript` Typeclass

The library `aeson-typescript` defines a typeclass that every exportable type must implement:

```haskell
class (Typeable a) => TypeScript a where
  getTypeScriptDeclarations :: Proxy a -> [TSDeclaration]
  getParentTypes :: Proxy a -> [TSType]
  ...
```

- **`getTypeScriptDeclarations`**: Returns the actual TypeScript code (e.g., `interface Foo { ... }`).
- **`getParentTypes`**: Returns a list of the *immediate dependencies* of this type.

When you use `$(deriveTypeScript ...)` (Template Haskell), it inspects your data definition at compile time and automatically generates the code for `getParentTypes`. For example, if you have:

```haskell
data User = User { name :: String, age :: Int, role :: Role }
```

The generated instance effectively says: "My dependencies are `String`, `Int`, and `Role`".

### 2. The `TSType` Wrapper (Existential Quantification)

How do we return a list of dependencies when they are all different types (`String`, `Int`, `Role`)? Haskell lists are homogenous (must contain the same type).

The library uses an **Existential Wrapper**:

```haskell
data TSType = forall a. (TypeScript a, Typeable a) => TSType (Proxy a)
```

The syntax `forall a.` here essentially says: "I hide the specific type `a` inside me. All you need to know is that `a` implements `TypeScript` and `Typeable`."

This allows us to have a list `[TSType]` containing `[TSType (Proxy :: Proxy Int), TSType (Proxy :: Proxy Role)]`.

### 3. The `visit` Function (Runtime Reflection)

We need to traverse the graph without getting stuck in infinite loops (recursive types, e.g., A -> B -> A). We use `Data.Typeable` to get a unique fingerprint (`TypeRep`) for every type we visit.

```haskell
-- simplified logic from Main.hs
visit :: [TSType] -> Set TypeRep -> [TSDeclaration]
visit [] visited = []
visit ((TSType p) : queue) visited =
  let rep = typeRep p -- Get unique ID for type 'a'
  in if Set.member rep visited
     then visit queue visited -- Already seen, skip
     else
       -- 1. Get definitions for THIS type
       let myDecls = getTypeScriptDeclarations p
       -- 2. Get children (dependencies)
       let children = getParentTypes p
       -- 3. Recurse
       in myDecls ++ visit (children ++ queue) (Set.insert rep visited)
```

By pattern matching `(TSType p)`, we "open" the existential box. Inside the match, we have access to the dictionary functions `typeRep`, `getTypeScriptDeclarations`, and `getParentTypes` for that specific unknown type.

## Summary

1.  **Template Haskell** (`deriveTypeScript`) analyses your data types at compile time and generates code that knows what other types they contain (`getParentTypes`).
2.  **Existential Types** (`TSType`) allow us to treat completely different Haskell types uniformly as "nodes in a graph."
3.  **Runtime Reflection** (`Typeable`/`TypeRep`) allows us to track which nodes we've already processed to handle cycles and diamonds in the graph.

Result: You declare the "Roots" (top-level messages), and the algorithm pulls in everything required to define them.
