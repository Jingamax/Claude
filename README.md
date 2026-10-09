# Claude

Roblox game synced into Studio with [Rojo](https://rojo.space).

## Connect to Roblox Studio

1. Install [Rokit](https://github.com/rojo-rbx/rokit), then run `rokit install` in this folder to get Rojo.
2. Install the Rojo plugin in Studio: `rojo plugin install`.
3. Run `rojo serve` in this folder.
4. In Studio, open a place, click **Rojo** in the Plugins tab, then **Connect**.

Edits under `src/` sync into Studio live.

## Layout

| Folder        | Shows up in Studio as                              |
|---------------|----------------------------------------------------|
| `src/shared`  | `ReplicatedStorage.Shared`                         |
| `src/server`  | `ServerScriptService.Server`                       |
| `src/client`  | `StarterPlayer.StarterPlayerScripts.Client`        |

`*.server.luau` becomes a Script, `*.client.luau` a LocalScript, and plain `*.luau` a ModuleScript.
