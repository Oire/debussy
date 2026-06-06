# dotnet-tools (plugin)

Oire .NET tooling for Claude Code, packaged as an installable plugin so it only
loads where it's relevant (.NET projects) rather than globally.

## Contents

- `agents/dotnet-style-corrector.md` — reviews C# against Oire .NET coding
  standards and `.editorconfig`, and fixes formatting / convention violations.

## Why its own plugin

The .NET corrector is stack-specific, so it gets its own plugin — install it
only in .NET projects rather than carrying it into every repo. The other
debussy plugins (`planning`, `review`, `write-manual`, `conventions`) are
grouped by cohesion; the rationale is in
[`../../docs/marketplace-plan.md`](../../docs/marketplace-plan.md).

## Install (via the debussy marketplace)

From inside Claude Code:

```
/plugin marketplace add Oire/debussy
/plugin install dotnet-tools@debussy
```

(Or add the local checkout as a marketplace with `/plugin marketplace add
<path-to-debussy>`.) Once installed, the `dotnet-style-corrector` agent appears
in `/agents`.
