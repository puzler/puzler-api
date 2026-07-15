# GraphQL Library

This document explains the structure of the GraphQL layer and how to extend it.

## Directory Overview

```
app/graphql/
  api_schema.rb          Root schema — wires root types, Dataloader, ActionCable
  types/                 GraphQL type definitions (base classes + concrete types)
  mutations/             Mutation resolver classes (one per operation)
  schemas/               Composition layer — groups fields into domain categories
```

---

## Three-Layer Architecture

```
schemas/          ← composition: what fields exist and how they're grouped
  └── mutations/  ← logic: how each field resolves
        └── types/  ← shape: what the inputs and return values look like
```

Each layer has a single responsibility and depends only on the layer below it.

---

## `types/`

Base classes and concrete GraphQL types, organized by graphql-ruby concept.

```
types/
  arguments/        BaseArgument
  connections/      BaseConnection, BaseEdge
  enums/            BaseEnum
  fields/           BaseField
  input_objects/    BaseInputObject
  interfaces/       BaseInterface, NodeType
  objects/          BaseObject + all concrete object types (PuzzleType, UserType, …)
  scalars/          BaseScalar
  unions/           BaseUnion
```

Every concrete type (e.g. `PuzzleType`) lives in `types/objects/` and inherits from
`Types::Objects::BaseObject`. Adding a new model type means adding one file there.

---

## `mutations/`

One class per mutation, organized by domain category matching the `schemas/` structure.

```
mutations/
  base_mutation.rb      Shared base class (auth helpers, base classes wired up)
  users/                update_profile.rb
  puzzles/              create_puzzle.rb  update_puzzle.rb  publish_puzzle.rb  delete_puzzle.rb
  social/               rate_puzzle.rb  toggle_favorite.rb  create_comment.rb  delete_comment.rb
  play/                 start_play.rb  save_progress.rb  submit_solution.rb
```

Each class inherits from `Mutations::BaseMutation` and implements a single `resolve` method.

**Naming:** `Mutations::[Category]::[OperationName]` — e.g. `Mutations::Puzzles::CreatePuzzle`.

**Note:** When referencing mutation classes from inside a `schemas/` file, use the `::Mutations::`
prefix (e.g. `::Mutations::Puzzles::CreatePuzzle`) to avoid shadowing by the `Schemas::*::Mutations`
module in the nesting chain.

---

## `schemas/`

The composition layer. Each file owns one domain category and contains `Queries` and/or
`Mutations` sub-modules, each of which is a GraphQL interface implemented by the root types.

```
schemas/
  mutation_type.rb      MutationType — implements all mutation schema interfaces
  query_type.rb         QueryType    — implements all query schema interfaces
  users.rb              Users::{ Queries, Mutations }
  puzzles.rb            Puzzles::{ Queries, Mutations }
  social.rb             Social::{ Mutations }
  play.rb               Play::{ Mutations }
  tags.rb               Tags::{ Queries }
```

Each sub-module includes `Types::Interfaces::BaseInterface` (making it a proper GraphQL interface),
declares a `graphql_name` to avoid SDL name collisions, and defines fields directly in the module
body. `MutationType` and `QueryType` are thin — they only `implements` the relevant interfaces.

---

## How to Add Things

### New object type

1. Create `app/graphql/types/objects/widget_type.rb` → `Types::Objects::WidgetType`

### New mutation

1. Create `app/graphql/mutations/widgets/create_widget.rb` → `Mutations::Widgets::CreateWidget`
2. Add `field :create_widget, mutation: ::Mutations::Widgets::CreateWidget` to the `Mutations`
   module in `app/graphql/schemas/widgets.rb` (creating the file if this is a new category)
3. Add `implements Widgets::Mutations` to `schemas/mutation_type.rb`

### New query

1. Add the field + resolver to the `Queries` module in `app/graphql/schemas/[category].rb`
2. If it's a new category, add `implements [Category]::Queries` to `schemas/query_type.rb`

### New domain category

1. Create `app/graphql/schemas/[category].rb` with `Schemas::[Category]::{ Queries, Mutations }`
2. Create `app/graphql/mutations/[category]/` for the resolver classes
3. Register in `mutation_type.rb` and/or `query_type.rb`

### New enum (backed by a model enum)

Any model-backed enum should surface as a GraphQL enum so values are validated and
strongly typed end-to-end (no magic strings on the client).

1. Create `app/graphql/types/enums/[name]_enum.rb` → `Types::Enums::[Name]Enum < BaseEnum`,
   and call `generate_from_rails_enum(Model.<enum_pluralized>)` (e.g. `Puzzle.visibilities`).
   This registers each Rails key as an UPPERCASE GraphQL value (`public` → `PUBLIC`) whose
   coerced Ruby value is the original string — so resolvers and `update(...)` are unchanged.
2. Use the enum class as the type for the matching object **field** AND for any **mutation /
   input-object argument** that sets it (keep any runtime `SELECTABLE`-style guards — the enum
   only blocks values outside the enum, not business rules like "tier not live yet").
3. The wire format becomes the UPPERCASE name; the frontend imports the generated const
   (e.g. `PuzzleVisibilityEnum.Public`) instead of a string literal. Request specs must pass
   and assert the UPPERCASE form.

---

## Planned Additions

- **`loaders/`** — Dataloader batch-loading classes to eliminate N+1 queries
- **`subscriptions/`** — Action Cable subscription type classes (foundation already wired in `api_schema.rb`)
