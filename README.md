# Loader

A minimal, single-call module bootstrapper for Roblox. Pass it folders or `ModuleScript`s and it will recursively find, require, initialize, and start everything — in that order.

---

## How it works

`Loader.Init(...)` runs four steps in sequence:

1. **Require** — recursively finds every `ModuleScript` in the provided paths and calls `require()` on it
2. **Init** — calls `:Init()` on every loaded module that exposes one
3. **Start** — calls `:Start()` on every loaded module that exposes one, each in its own `task.spawn`
4. **Components** — if `Loader.AddComponents(...)` was called beforehand, requires all component modules after startup

---

## Installation

Place `Loader.luau` in `ReplicatedStorage` or `ServerScriptService` alongside your other shared modules and require it from your bootstrapper script.

```lua
local Loader = require(game.ServerScriptService.Loader)
```

---

## Usage

### Basic setup

```lua
local Loader = require(game.ServerScriptService.Loader)

Loader.Init(
    game.ServerScriptService.Services,
    game.ReplicatedStorage.Shared
)
```

Loader will walk every descendant of those folders, require all `ModuleScript`s it finds, then call `:Init()` and `:Start()` on each.

### With components

```lua
local Loader = require(game.ServerScriptService.Loader)

-- Must be called before Init
Loader.AddComponents(
    game.ReplicatedStorage.Components
)

Loader.Init(
    game.ServerScriptService.Services
)
```

`AddComponents` must be called **before** `Init`. The component modules are required after `:Start()` has run on all services.

### Module shape

Loader expects modules to return a table. `:Init()` and `:Start()` are both optional — Loader checks for them at runtime and skips any module that doesn't have them.

```lua
-- Services/MyService.lua
local MyService = {}

function MyService:Init()
    -- runs synchronously before any :Start()
    -- safe to set up state, bind events, etc.
end

function MyService:Start()
    -- runs in its own task.spawn after all :Init() calls
    -- safe to reference other services here
end

return MyService
```

---

## API Reference

### `Loader.Init(...: Folder | ModuleScript)`

Bootstraps the loader. Accepts any number of `Folder` or `ModuleScript` instances. Recursively requires all `ModuleScript` descendants, then runs `:Init()` and `:Start()` across all of them.

> Can only be called **once**. Errors if called again.

---

### `Loader.AddComponents(...: Folder | ModuleScript)`

Registers folders or modules to be required as components after `Init` completes. Must be called **before** `Loader.Init`.

> Can only be called once, and only before `Init`. Errors otherwise.

---

## Notes

- `:Init()` calls are **synchronous** and blocking — all modules finish `:Init()` before any `:Start()` runs. This makes it safe to reference other services inside `:Start()`.
- `:Start()` calls are wrapped in `task.spawn`, so a yielding or erroring `:Start()` will not block the rest.
- Module names must be **unique** across all provided paths. Loader stores modules by `module.Name` — duplicate names will silently overwrite each other.
- Components are required with a bare `require()` and are not tracked in the loaded module table, so they will not have `:Init()` or `:Start()` called on them automatically. Use components for self-registering patterns.
- Loader is **not** a service locator. It does not expose a way to retrieve loaded modules by name. If your modules need to communicate, have them require each other directly.

---

## License

MIT — see `LICENSE` for details.
