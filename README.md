# AnimeMovement

A self-contained movement feature extracted from the purchased Studio system. It includes running, jumping, one double jump per airborne cycle, sliding, slide jumps, wall running, wall jumps, camera-directed dashes, and the movement camera.

## Structure

| File | Responsibility |
| --- | --- |
| `src/features/movement/Config.luau` | Speeds, durations, cooldowns, camera settings, and bindings |
| `MovementServer.luau` | WCS startup, character lifetime, and Networker effect broadcasts |
| `MovementClient.luau` | Input binding, local character lifetime, and frame updates |
| `modules/Skills.luau` | Four WCS skill classes, request validation, and cooldowns |
| `modules/Character.luau` | Character state and composition of the movement classes |
| `modules/Traversal.luau` | Surface queries and slide, jump, dash, and wall physics |
| `modules/Camera.luau` | Movement camera adapter: torso follow, facing, airborne tilt, boosts, and blur |
| `modules/Effects.luau` | Animation tracks and movement sounds |
| `modules/VFX.luau` | Slide, wall-run, and jump effects using the existing Studio assets |
| `src/game/modules/camera/CameraController.luau` | Reusable camera output and named FOV modifiers |
| `src/game/modules/camera/OrbitCamera.luau` | Reusable orbit input, zoom, smoothing, and collision |
| `src/game/assets/` | Animation IDs and sound definitions |

The feature uses full instance paths under `ReplicatedStorage.Source.Features.Movement` and `ServerScriptService.Features.Movement`. Startup calls `MovementServer:init()` and `MovementClient:init()`. No purchased framework folders, map folders, UI, datastore, disc, or purchased ability modules are required.

## Controls

| Action | Keyboard / mouse | Gamepad |
| --- | --- | --- |
| Jump / double jump / traversal jump | Space | A |
| Dash in the camera direction | E | R2 |
| Hold slide | Left Control or Z | R1 |
| Toggle shift lock | Left Alt | R3 |
| Orbit | Hold right mouse and move | Right stick |
| Zoom | Mouse wheel | - |

Wall running starts automatically beside a wall while airborne. Jumping during a slide boosts forward; jumping during a wall run launches away from the wall. Holding slide also starts a slide on landing. Bindings are in `Config.Inputs`; there is no custom keybind framework or touch UI.

Tune wall jumps in `Config.WallRun`: `JumpSpeed` controls horizontal launch speed (90 studs/second at the default WalkSpeed), `JumpLift` controls upward speed (45), and `JumpDuration` controls how long the launch velocity is maintained (0.1 seconds). Momentum continues after that boost ends, so lower `JumpSpeed` to reduce travel distance.

## WCS and networking

Input bindings request WCS skills through `Start()` and `End()`. The server validates surfaces and action state and applies WCS cooldowns. Physics and animations start on the owning client after WCS accepts the action. The pending-request timeout only prevents repeated requests while awaiting replication; WCS owns gameplay cooldowns.

Networker broadcasts movement sounds and VFX to other players, including the accepted action's origin. Roblox replicates the owning client's character physics and Animator tracks. Project code creates no RemoteEvents; WCS and Networker manage their own internal transport.

The feature creates and owns the WCS character wrapper. When adding other WCS features, reuse that wrapper via `WCS.Character.GetCharacterFromInstance(model)` and add skills individually. This feature does not claim the character's single moveset slot.

Other game systems can set `MovementDisabled` on the character to block traversal actions or use WCS's `DisableSkills`. Use WCS humanoid defaults/status effects for speed changes; traversal speeds scale with the applied WalkSpeed.

## Camera reuse

Shared camera modules are under `ReplicatedStorage.Source.Game.Modules.Camera` and have no dependency on the Movement feature. `OrbitCamera.new(settings, params)` creates orbit controls; `update(delta, focus, collisionOrigin)` returns a camera CFrame. `CameraController.new(camera, fieldOfView)` owns camera output; `render(frame, focus, delta)` applies the pose and FOV modifiers.

Use `setModifier(name, amount)`, `pulse(name, amount, duration)`, and `removeModifier(name)` for independent FOV effects. Pulses use the original quadratic fade and stack under separate names. Call `destroy()` on both objects to disconnect input and restore camera state.

The Movement adapter restores the original torso animation offsets, Roblox mouse-sensitivity scaling, smooth character facing, airborne pitch, and slide-jump depth of field. Its settings and boost timings are in `Config.Camera`. The initial zoom is `0`, matching the original; mouse-wheel zoom clamps to 5-35 studs. Set `Config.Camera.Zoom` to start farther out.

Another camera system can suspend movement camera output by setting the active adapter's `Controller.Enabled = false`, then resume it with `true`. Movement-specific body and boost behavior stays in the feature adapter.

## Assets and setup

The original R6 animation IDs and movement sound IDs are centralized in `src/game/assets`. Movement uses the existing player characters in Studio; the animation IDs target R6. Roblox animation/audio permissions must allow these IDs in the experience; replace the IDs if needed.

VFX templates stay in `ReplicatedStorage.Assets.VFX.Movement`, with `WallRun` and `JumpEffects` subfolders. Runtime effects clone these templates; nothing is exported into this workspace. Wall-run smoke attaches to the R6 arms without disc equipment. Jump effects use the original orientations and each emitter's `EmitCount`, including emitters directly under parts. Hand templates, attachment offset, and cleanup lifetime are in `Config.VFX`.

Active slides clone `ReplicatedStorage.Assets.VFX.Movement.Slide.Effect` onto the character's existing `RightMovementHilt`. Each character gets its own trail endpoints using `Config.VFX.SlideTrailOffsets`, matching the original offsets. The effect is reused across slides, and its sound uses `SoundIds.Movement.SlideSparkle`. They start after `Config.VFX.SlideDelay` (0.2 seconds) and stop when sliding ends. Keep the existing effect carrier in the R6 character; no disc gameplay is used.

Keep all characters, models, parts, attachments, and effects in their original Studio locations. This workspace ports code and asset ID tables only, and its project mapping preserves unmanaged instances in ReplicatedStorage. Both Studio projects were read only during this change. Disable the purchased startup scripts when enabling the refactored startup so both systems do not run together.

Run `setup.bat` for tools and dependencies, then `npm run watch:rojo` for the existing sync workflow. The dependencies are WCS 2.5.0, Networker 0.3.0, and Janitor 1.18.3. `tools/genFeatureTree.js` generates the code project mapping.

Validation for this refactor is a source review only, as requested. No Rojo builds, Studio playtests, or MCP tests were run.
