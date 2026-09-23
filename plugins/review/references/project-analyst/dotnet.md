# .NET / C# checks

Read this after detecting a .NET project (`*.csproj`, `*.sln`, `global.json`). These
are the things Nigel looks for beyond general C# knowledge.

## Code

- Naming: PascalCase public members, camelCase locals, `_camelCase` private fields.
- `var` versus explicit types as `.editorconfig` says, not as taste says.
- Async: `ConfigureAwait(false)` in library code, no `async void` outside event
  handlers, `CancellationToken` accepted and passed all the way down.
- `sealed` on classes not designed for inheritance; `IDisposable` implemented
  correctly where resources are held.
- Nullable reference types enabled and honored, not silenced with `!`.
- `catch (Exception)` that swallows, `throw ex;` that loses the stack trace.

## API and docs

- XML docs on every public member, readable in IntelliSense.
- Overloads that follow .NET conventions (optional parameters versus overloads,
  `CancellationToken` last).

## Packaging

- `.csproj` package metadata: `PackageId`, `Authors`, `Description`,
  `PackageLicenseExpression`, `RepositoryUrl`, `PackageReadmeFile`, icon.
- SourceLink and deterministic builds; `global.json` pinning the SDK.
- `Directory.Build.props` for shared settings instead of copy-pasted `.csproj` blocks.
