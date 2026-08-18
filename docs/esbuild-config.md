# esbuild.config.mjs

This is the plugin's build script — not auto-discovered by esbuild, it's just
a Node script run directly (`node esbuild.config.mjs`), invoked by
`npm run dev` / `npm run build`.

## What it does

1. **Reads a mode flag**: `process.argv[2] === 'production'` — plain
   `node esbuild.config.mjs` (the `dev` script) is dev mode;
   `node esbuild.config.mjs production` (the `build` script) is prod mode.
2. **Creates an esbuild "context"** — a reusable build configuration:
   - **Entry point**: `src/main.ts` — the plugin's source root.
   - **Bundle**: `true` — inlines all of the plugin's own imports (e.g.
     `./settings`) into one file.
   - **External**: `obsidian`, `electron`, CodeMirror/Lezer packages, and Node
     builtins are *not* bundled — they stay as `require(...)` calls, because
     Obsidian provides those at runtime (see below).
   - **Format**: `cjs` — Obsidian loads plugins as CommonJS.
   - **Target**: `es2021` — matches what Obsidian's Electron/Chromium runtime
     supports.
   - **Output**: single `main.js` file, prefixed with a
     "this is generated" banner comment.
   - **Sourcemaps**: inline in dev (for debugging), stripped in prod.
   - **Minify**: only in prod.
3. **Runs the build**:
   - **Prod**: one-shot `context.rebuild()` then exits — used for release
     builds (`npm run build`, which also runs `tsc -noEmit` first to
     type-check).
   - **Dev**: `context.watch()` — stays running, rebuilding `main.js` on every
     source file change, so the plugin can just be reloaded in Obsidian while
     editing.

## How `external` packages become available at runtime

Marking a package `external` tells esbuild: don't bundle it, leave the
`require('obsidian')` / `require('electron')` / etc. call in the output
pointing at a module name, not actual code. That only works because something
else provides those modules by that exact name at runtime:

- **`obsidian`** — the npm package installed in `node_modules/obsidian` is
  *types-only* (`main: ""`, no runtime JS). At runtime, Obsidian's own app
  process (running under Electron with Node integration) implements a custom
  module loader: before loading a plugin's `main.js`, it registers an
  internal module under the id `"obsidian"` that resolves to its real
  implementation — the actual `Plugin`, `Notice`, `Modal`, `Setting` classes
  etc. living inside Obsidian itself. `require('obsidian')` is intercepted by
  that loader and handed the live object, never touching `node_modules`.

- **`electron`** — Electron itself exposes a native `electron` module to any
  code running inside its process (main or renderer); it's part of the
  Electron runtime, not something Obsidian has to inject. Since the plugin's
  bundled `main.js` executes inside Obsidian's Electron renderer process,
  `require('electron')` resolves normally.

- **`@codemirror/*`, `@lezer/*`** — Obsidian's editor is built on CodeMirror
  6, and it bundles its own copies of these packages internally, then
  registers them under those same module names (same mechanism as
  `obsidian`). This matters for more than bundle size: CodeMirror extensions
  rely on referential/instance equality (`instanceof` checks, `Facet`
  identity). If the plugin bundled a *separate* copy of `@codemirror/state`,
  objects it creates wouldn't be recognized as compatible by Obsidian's own
  CodeMirror instance — they have to be the exact same module instance, not
  just a semver-compatible one.

- **Node builtins** (`fs`, `path`, etc., via `builtinModules`) — need no
  special provisioning. Electron ships full Node.js, so builtins resolve
  through normal Node module resolution. They're marked external simply so
  esbuild doesn't try to bundle/polyfill them, which would be pointless and
  could break (some are native bindings).

The common thread: for `obsidian`/`electron`/CodeMirror, the *host app*
pre-registers those module names before the plugin's code ever runs — similar
to how VS Code does `require('vscode')` for extensions. The plugin never
ships its own copy; it trusts the name resolves at load time.
