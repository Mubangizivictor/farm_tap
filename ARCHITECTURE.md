# FarmTap Architecture

## Overview
FarmTap follows a **feature-first Clean Architecture** pattern. Each feature is self-contained and divided into three layers, with dependencies pointing inward:
`presentation -> domain <- data`.

## Layers

### 1. Domain (Inner Layer)
- **Entities**: Pure Dart objects representing business models.
- **Repository Interfaces**: Abstract classes defining how data is accessed.
- **Use Cases**: Single-purpose classes that orchestrate business logic.
- **Rule**: No dependencies on Flutter, Isar, Firebase, or JSON.

### 2. Data (Outer Layer)
- **Models**: Data transfer objects (DTOs) for Isar or Firebase, with JSON serialization.
- **Data Sources**: Implementations of local (Isar) or remote (Firebase) storage.
- **Repository Implementations**: Fulfill domain repository interfaces.
- **Mappers**: Transform between Models and Entities.

### 3. Presentation (Outer Layer)
- **Blocs/Cubits**: State management using `flutter_bloc`.
- **Pages**: Top-level widgets for screens.
- **Widgets**: Reusable UI components.

## Dependency Injection
We use `get_it` for manual dependency registration in `lib/app/di/`. Avoid code generation for DI to keep the setup transparent.

## Offline-First Write Flow
1. UI triggers a Use Case.
2. Repository writes to local Isar database first.
3. Record is assigned a `syncStatus` (pending/synced/failed).
4. A background `SyncService` (to be implemented) pushes pending changes to the cloud.
5. Every entity includes audit metadata: `id` (UUID), `tenantId`, `createdAt`, `updatedAt`, `createdBy`, `updatedBy`, `deviceId`, and `isDeleted` (soft delete).

## Error Handling
- Use the sealed `Result<T>` type (`Success` or `Failure`).
- Repositories return `Future<Result<T>>` or `Stream<Result<T>>`.
- Avoid throwing exceptions across layers.

## Adding a New Feature
1. Create a folder in `lib/sectors/<sector>/<feature_name>`.
2. Define the **Domain** (Entities, Repository Interface, Use Cases).
3. Implement the **Data** layer (Models, Repository Implementation).
4. Build the **Presentation** (Bloc, Pages, Widgets).
5. Register dependencies in `lib/app/di/injection.dart`.
6. Add routes to `lib/app/router/routes.dart` and `app_router.dart`.
