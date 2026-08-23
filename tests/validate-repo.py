#!/usr/bin/env python3
"""Structural checks for the debussy marketplace.

Everything here is a rule the repo already states in prose (README.md,
CLAUDE.md, plugins/conventions/hooks/README.md) but nothing enforced. Run it
locally the same way CI does:

    python3 tests/validate-repo.py

Exits 0 when every check passes, 1 otherwise, and prints one line per check so
a green run still shows what was actually verified.
"""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover - CI always has it
    print("FAIL: PyYAML is required (pip install pyyaml)")
    sys.exit(1)

ROOT = Path(__file__).resolve().parent.parent
SEMVER = re.compile(r"^\d+\.\d+\.\d+$")

failures: list[str] = []
checks = 0


def check(ok: bool, label: str, detail: str = "") -> bool:
    """Record one assertion; return it so callers can skip dependent work."""
    global checks
    checks += 1
    if ok:
        print(f"  ok   {label}")
    else:
        print(f"  FAIL {label}" + (f"\n         {detail}" if detail else ""))
        failures.append(label)
    return ok


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def load_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001 - report any parse problem
        check(False, f"{rel(path)} is valid JSON", str(exc))
        return None


# --------------------------------------------------------------------------
print("\n== JSON manifests ==")

marketplace_path = ROOT / ".claude-plugin" / "marketplace.json"
marketplace = load_json(marketplace_path)
if marketplace is not None:
    check(True, f"{rel(marketplace_path)} is valid JSON")
    for key in ("name", "owner", "metadata", "plugins"):
        check(key in marketplace, f"marketplace.json has '{key}'")
    version = (marketplace.get("metadata") or {}).get("version", "")
    check(
        bool(SEMVER.match(version)),
        f"marketplace version is semver ({version or 'missing'})",
    )

plugin_dirs = sorted(p for p in (ROOT / "plugins").iterdir() if p.is_dir())
plugin_names: dict[str, Path] = {}

for plugin_dir in plugin_dirs:
    manifest_path = plugin_dir / ".claude-plugin" / "plugin.json"
    if not check(manifest_path.is_file(), f"{plugin_dir.name} has plugin.json"):
        continue
    manifest = load_json(manifest_path)
    if manifest is None:
        continue
    check(True, f"{rel(manifest_path)} is valid JSON")
    name = manifest.get("name", "")
    check(
        name == plugin_dir.name,
        f"{plugin_dir.name}: plugin.json name matches its directory",
        f"name={name!r}",
    )
    plugin_version = manifest.get("version", "")
    check(
        bool(SEMVER.match(plugin_version)),
        f"{plugin_dir.name}: version is semver ({plugin_version or 'missing'})",
    )
    check(
        bool(manifest.get("description")),
        f"{plugin_dir.name}: plugin.json has a description",
    )
    if name:
        plugin_names[name] = plugin_dir

for extra in sorted((ROOT / "settings").glob("*.json")):
    if load_json(extra) is not None:
        check(True, f"{rel(extra)} is valid JSON")

# --------------------------------------------------------------------------
print("\n== marketplace <-> plugins ==")

if marketplace is not None:
    listed = {}
    for entry in marketplace.get("plugins", []):
        entry_name = entry.get("name", "")
        source = entry.get("source", "")
        listed[entry_name] = source
        check(
            bool(entry_name) and bool(source) and bool(entry.get("description")),
            f"marketplace entry {entry_name or '<unnamed>'} has name/source/description",
        )
        source_dir = (ROOT / source.lstrip("./")).resolve()
        check(
            source_dir.is_dir(),
            f"marketplace entry {entry_name}: source {source} exists",
        )
        if source_dir.is_dir():
            check(
                source_dir.name == entry_name,
                f"marketplace entry {entry_name}: source directory matches its name",
            )

    for name in sorted(plugin_names):
        check(name in listed, f"plugin {name} is listed in marketplace.json")

# --------------------------------------------------------------------------
print("\n== component frontmatter ==")

component_globs = {
    "agent": "plugins/*/agents/*.md",
    "command": "plugins/*/commands/*.md",
    "skill": "plugins/*/skills/*/SKILL.md",
}

for kind, pattern in component_globs.items():
    for path in sorted(ROOT.glob(pattern)):
        text = path.read_text(encoding="utf-8")
        if not check(
            text.startswith("---"), f"{kind} {rel(path)} starts with frontmatter"
        ):
            continue
        end = text.find("\n---", 3)
        if not check(end != -1, f"{kind} {rel(path)} frontmatter is closed"):
            continue
        try:
            meta = yaml.safe_load(text[3:end]) or {}
        except yaml.YAMLError as exc:
            check(False, f"{kind} {rel(path)} frontmatter is valid YAML", str(exc))
            continue
        check(True, f"{kind} {rel(path)} frontmatter is valid YAML")
        check(
            bool(meta.get("description")),
            f"{kind} {rel(path)} declares a description",
        )
        if kind == "command":
            continue  # commands take their name from the filename
        expected = path.parent.name if kind == "skill" else path.stem
        check(
            meta.get("name") == expected,
            f"{kind} {rel(path)} name matches its {'directory' if kind == 'skill' else 'filename'}",
            f"name={meta.get('name')!r}, expected {expected!r}",
        )

# --------------------------------------------------------------------------
print("\n== hook wiring ==")

PLUGIN_ROOT_VAR = "${CLAUDE_PLUGIN_ROOT}"

for hooks_json in sorted(ROOT.glob("plugins/*/hooks/hooks.json")):
    config = load_json(hooks_json)
    if config is None:
        continue
    check(True, f"{rel(hooks_json)} is valid JSON")
    plugin_dir = hooks_json.parent.parent
    referenced = 0
    for matchers in config.get("hooks", {}).values():
        for matcher in matchers:
            for hook in matcher.get("hooks", []):
                command = hook.get("command", "")
                for raw in re.findall(r"\$\{CLAUDE_PLUGIN_ROOT\}[^\"']*", command):
                    referenced += 1
                    target = plugin_dir / raw.replace(PLUGIN_ROOT_VAR + "/", "")
                    check(
                        target.is_file(),
                        f"{rel(hooks_json)} -> {raw.replace(PLUGIN_ROOT_VAR + '/', '')} exists",
                    )
                check(
                    PLUGIN_ROOT_VAR in command,
                    f"{rel(hooks_json)} command uses {PLUGIN_ROOT_VAR}",
                    command,
                )
    check(referenced > 0, f"{rel(hooks_json)} wires at least one script")

# Skills, commands, and agents must address in-plugin files through
# ${CLAUDE_PLUGIN_ROOT}; a hardcoded ~/.claude path breaks on install.
for pattern in component_globs.values():
    for path in sorted(ROOT.glob(pattern)):
        text = path.read_text(encoding="utf-8")
        bad = [
            line.strip()
            for line in text.splitlines()
            if re.search(r"~/\.claude/(hooks|skills|agents|commands|plugins)/", line)
        ]
        check(
            not bad,
            f"{rel(path)} has no hardcoded ~/.claude component path",
            "; ".join(bad[:3]),
        )

# --------------------------------------------------------------------------
print("\n== convention hook runners ==")

cross = ROOT / "plugins" / "conventions" / "hooks" / "cross-platform"
windows_only = ROOT / "plugins" / "conventions" / "hooks" / "windows-only"

for ps1 in sorted(cross.glob("*.ps1")):
    check(
        ps1.with_suffix(".sh").is_file(),
        f"cross-platform {ps1.name} has a .sh counterpart",
    )
for sh in sorted(cross.glob("*.sh")):
    check(
        sh.with_suffix(".ps1").is_file(),
        f"cross-platform {sh.name} has a .ps1 counterpart",
    )
check(
    not list(windows_only.glob("*.sh")),
    "windows-only hooks ship no .sh runner",
    ", ".join(p.name for p in windows_only.glob("*.sh")),
)


def ps_word_map(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    body = text.split("$wordMap = [ordered]@{", 1)[-1].split("\n}", 1)[0]
    return dict(re.findall(r"'([^']+)'\s*=\s*'([^']+)'", body))


def sh_word_map(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    body = text.split("<<'MAP'", 1)[-1].split("\nMAP", 1)[0]
    pairs = {}
    for line in body.splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            parts = line.split()
            if len(parts) == 2:
                pairs[parts[0]] = parts[1]
    return pairs


english_ps1 = cross / "check-american-english.ps1"
english_sh = cross / "check-american-english.sh"
if english_ps1.is_file() and english_sh.is_file():
    ps_map = ps_word_map(english_ps1)
    sh_map = sh_word_map(english_sh)
    check(len(ps_map) > 100, f"word map extracted from the .ps1 ({len(ps_map)} entries)")
    check(len(sh_map) > 100, f"word map extracted from the .sh ({len(sh_map)} entries)")
    only_ps = sorted(set(ps_map) - set(sh_map))
    only_sh = sorted(set(sh_map) - set(ps_map))
    mismatched = sorted(w for w in set(ps_map) & set(sh_map) if ps_map[w] != sh_map[w])
    check(
        not only_ps,
        "every .ps1 word map entry is in the .sh runner",
        ", ".join(only_ps[:10]),
    )
    check(
        not only_sh,
        "every .sh word map entry is in the .ps1 runner",
        ", ".join(only_sh[:10]),
    )
    check(
        not mismatched,
        "the two word maps agree on every replacement",
        ", ".join(mismatched[:10]),
    )

# --------------------------------------------------------------------------
print()
if failures:
    print(f"validate-repo: {checks - len(failures)} passed, {len(failures)} FAILED")
    for label in failures:
        print(f"  - {label}")
    sys.exit(1)

print(f"validate-repo: {checks} checks passed")
sys.exit(0)
