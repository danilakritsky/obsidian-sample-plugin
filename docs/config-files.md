# Config files

"Config files" here means the various `*.config.*` files and dotfiles that
tools auto-discover in the project root. Each tool looks for its expected
filename (or walks up parent directories) before running, and if found, loads
it to configure its own behavior. Nothing in the code references them
explicitly — the tool's CLI has the lookup built in.

| File | Consumed by | When |
|---|---|---|
| `tsconfig.json` | `tsc`, `eslint` (via `parserOptions.projectService`), editors/IDEs | Any time TypeScript is compiled, type-checked, or an editor needs type info |
| `eslint.config.mts` | `eslint` CLI (`npm run lint`) | Whenever `eslint .` runs — flat config is auto-detected by filename |
| `.prettierrc.json` / `.prettierignore` | `prettier` CLI (`npm run format`) | Whenever `prettier --write`/`--check` runs; ignore file excludes paths |
| `.editorconfig` | Your editor/IDE directly (VS Code, JetBrains, etc. — native support, no plugin needed) | Live, as you type — applies indent/charset/EOL rules to new keystrokes |
| `esbuild.config.mjs` | Not auto-discovered — it's a plain script invoked explicitly (`node esbuild.config.mjs`, via `npm run dev`/`build`) | Only when that script is run. See [esbuild-config.md](./esbuild-config.md) |
| `manifest.json` | Obsidian itself | When Obsidian loads the plugin — declares id, version, min-app-version, etc. |
| `.npmrc` | `npm` CLI | Every `npm install`/`npm run` |
| `flake.nix` / `flake.lock` + `.envrc` | `nix`, and `direnv` (which shells out to `nix develop`) | When you `cd` into the directory (direnv) or run `nix develop` — builds the dev shell |

The general pattern:

- **Tool-specific configs** (eslint, prettier, tsconfig, esbuild) are only
  read when you invoke that tool's command — they're inert otherwise.
- **Editor/environment configs** (`.editorconfig`, `.envrc`) are read
  passively/automatically by your editor or shell the moment you're in the
  directory, with no explicit command needed.
