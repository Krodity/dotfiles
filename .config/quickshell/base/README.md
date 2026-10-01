# base — the live Quickshell shell

Started from the Quickshell v0.3.1 guide (https://quickshell.org/docs/v0.3.1/guide) and grown into the
desktop shell. **Since 2026-09-27 this is the running shell** — end4-pC was stopped. ⚠️ Login autostart
(`~/.config/hypr/hyprland/execs.lua` → `qs -c $qsConfig`, `$qsConfig = end4-pC`) has **not** been switched
yet, so after a re-login end4-pC comes back and `base` does not start until launched by hand.

| | |
|---|---|
| Run (foreground, hot-reloads on save) | `qs -c base` |
| Run detached (how it's launched now) | `hyprctl dispatch 'hl.dsp.exec_cmd("uwsm-app -- qs -c base -d")'` |
| Log of the running instance | `qs log -c base` (add `-f` to follow) |
| Quickshell version | 0.3.0 (AUR `quickshell-git`), Hyprland 0.56.2 with the **Lua** config |

## What it draws

An island-style top bar on every monitor, plus popups:

```
   ( [icon] 3 )  ( 10:48 AM )  (wifi)
     │                │          └─ click → quick settings        (scroll = volume)
     │                └─ click → dashboard (media, wallpaper, theme)
     └─ click → window overview   (also SUPER+Tab)

   tap SUPER alone → app launcher (centred)
```

Every popup opens on the focused monitor, only one is open at a time (`services/Panels.qml`), and each
closes on Esc or on **a click anywhere outside it, on any monitor**. That's `modules/dismiss/OutsideClick.qml`:
while a bar popup is open, a transparent full-screen layer sits on `WlrLayer.Top` (above windows, below the
Overlay popups, clear of the bar's reserved strip) and closes the popup on any press, swallowing the click.
BarPopup **no longer uses `HyprlandFocusGrab`**: on this Hyprland 0.56.2 setup an active grab swallowed every
outside click, so neither the app nor the catcher got it, and it also cleared on its own ~2 s after an IPC
open. Popups must also **not** take the keyboard exclusively, because Hyprland then confines the pointer to that
layer and the catcher never sees the click. The launcher has its own full-screen backdrop, so it's excluded.

### IPC

```
qs -c base ipc call <target> toggle|close
    targets: launcher  windows  quicksettings  dashboard  wallpapers  theme
qs -c base ipc call settings toggle|close   ·   qs -c base ipc call settings open network|bluetooth|tailscale|display|sound|hyprland|appearance
qs -c base ipc call osd popup volume|brightness       # show the OSD without changing anything
qs -c base ipc call brightness increment|decrement    # ±5% on every DDC monitor, shows the OSD
```

(IPC functions can't be named `show`: `qs ipc call osd show …` is parsed as the `qs ipc show` subcommand.)

(Opening a popup this way from a terminal used to self-close after ~2 s; that was the focus grab, now removed.)

---

## App launcher — `modules/launcher/Launcher.qml`, `services/AppSearch.qml`

- **Open:** tap **Super** on its own. It's a Hyprland *release* bind, so Super+<key> combos don't trigger it
  (see [Hyprland wiring](#hyprland-wiring)). Also `ipc call launcher toggle`.
- **Look:** centred on the screen and **20% of the screen width**. It's **5% of the screen height** while it
  only holds the search bar and grows with the results up to **22.5%**, updating as you type.
  Colours come from the live theme. The fill opacity is `Appearance.launcher.opacity` (**0.65**), and the
  backdrop is a 25% tint of the theme background.
- **Keys:** type to filter · ↑/↓ or Tab/Shift+Tab to select · Enter launches/opens · Shift+Enter (file) opens its folder · Esc or a click outside closes.
- **Ranking:** match quality first (exact name > prefix > word-prefix > substring > generic
  name/comment/keywords > fuzzy subsequence), then how often you've launched the app. Launch counts are in
  `~/.local/state/quickshell-base/launcher.json`.
- **Files:** from 2 characters on, files and folders under `~` whose **name** contains the query appear
  below the apps under a "Files" header (up to 20, with the parent folder shown dimmed). `services/FileSearch.qml`
  runs `fd -i -F` live (no index, 120 ms debounce, a new keystroke kills the running search). Like fd's
  defaults it **skips hidden files and anything .gitignore'd**, plus `node_modules`. Ranking: exact name >
  prefix > word-prefix > substring, then shallower paths. **Enter** opens with `xdg-open`, **Shift+Enter**
  opens the containing folder. Icons are Papirus mimetype icons guessed from the extension.
- **Launching:** `uwsm-app -- <desktop-id>.desktop`. That gives each app its own systemd scope, so it
  survives shell restarts, and Terminal=true entries get a terminal.
- It holds the keyboard exclusively while open (`WlrKeyboardFocus.Exclusive`), so typing starts immediately.

## Window overview — `modules/windows/`

Opened by **SUPER+Tab**, a click on the left island, or `ipc call windows toggle`. It has one column per
workspace that has windows (sorted by id), and each window is a card with a snapshot, app icon and title.

### Tray

The header row has the **system tray** centred in its own pill (`TrayStrip.qml`); base's `SystemTray` is the
StatusNotifierWatcher while it runs. Passive items are hidden. **Left-click** activates the app and closes the
overview (menu-only items open their menu instead), **right-click** opens the app's menu, **middle-click** is
secondary activate, the **wheel** scrolls the item, and hovering shows its name under the pill.

### Mouse

| Action | Result |
|---|---|
| Left-click a card | Focus that window (switches workspace/monitor as needed), close the overview |
| Left-click a column **header** (number + monitor) | Switch to that workspace (`hl.dsp.focus({ workspace = "N" })`) |
| Right-click a card | Menu: **Switch to** / **Fullscreen** (or Exit fullscreen) / **Close** |
| **Drag** a card onto another column | Move the window there |
| Drag a card onto the **Empty workspaces** box | Move the window to that empty workspace |
| Mouse wheel | Scroll the grid (sideways unless it overflows vertically; Shift = sideways) |
| ↻ button | Re-capture every visible window's snapshot now |
| **+** button | Picker of the empty workspaces among **1–10** (with screen labels); click one, or ↑/↓ + Enter, to switch to it, which creates it. Esc or an outside click closes the picker |

Mouse drags move windows, so the grid does **not** drag-scroll; use the wheel. While you hold a dragged
card within 48 px of the grid's left or right edge, the grid auto-scrolls.

### Keyboard

| Key | In the grid | With the menu open |
|---|---|---|
| ← / → | previous / next workspace column | — |
| ↑ / ↓ | previous / next window in the column | move through the menu |
| Enter | open (focus) the selected window | run the highlighted menu item |
| Shift | open the menu for the selected window | close the menu |
| Esc | close the overview | close the menu (overview stays) |

The selection starts on the currently focused window and shows as an accent tint plus a thick ring. The
focused window itself only gets a thin ring. The grid scrolls to keep the selection in view. Keys arrive via
**on-demand** keyboard focus, taken when the overview opens. It's not exclusive, because an exclusive layer
would stop outside clicks from closing it (see above).

### Context menu

It acts on that exact window through its Wayland toplevel: `activate()`, `fullscreen = !fullscreen`,
`close()`. No Hyprland dispatch is needed. **Close** keeps the overview open so you can close several
windows in a row; the others close it. The menu lives in `BarPopup.overlayData`, a layer above the
content, so the grid's clipping can't cut it off.

### Drag and drop

- Each card carries a `DragHandler` and a `TapHandler` on a transparent top layer. A press becomes a tap
  (focus) or, once the pointer moves past the drag threshold, a drag. HoverRect's own MouseArea only drives
  the hover tint now, because the handler layer takes the presses.
- While dragging, a ghost chip (icon + title) follows the pointer, the source card dims to 35%, and the column
  under the pointer lights up.
- **Empty workspaces box** (`EmptyWorkspaceBox.qml`): appears beside the overview during a drag — to the right
  if it fits, else to the left, else over the overview's right end. It lists workspaces **1–10 that have no
  windows**, labelled by screen (1–5 Alienware, 6–9 Samsung, 10 HDP, matching the pinning in
  `~/.config/hypr/custom/rules.lua`). If all ten are taken it offers the next free id. Dropping on a slot
  moves the window there; dropping in the box but not on a slot sends it to the lowest empty workspace.
  - It's a separate layer window with an **empty input mask**. During the drag the Wayland implicit grab
    keeps sending pointer motion to the overview (even outside it), so the overview hit-tests the box itself
    (`slotAt()`). Both windows share the same top edge, so only x has to be translated.
  - ⚠️ The screen labels are written into `WindowOverview.qml` → `emptyWorkspaces`. Update them if the
    pinning changes.
- The move is `hl.dsp.window.move({ workspace = "N", window = "address:0x…", follow = false })`, so focus and
  what's on screen don't change. (`window =` targeting works on 0.56.2; this was re-verified.)
- Dropping on the window's own column, or outside every target, does nothing.

### Snapshots — `services/Previews.qml`, `scripts/snap-windows.sh`

- These are **grim region captures** of each window on a *visible* workspace:
  `grim -s 0.5 -q 75 -g "<x,y> <w>x<h>"` → `<address>.jpg`.
  ⚠️ This deliberately avoids per-window capture (ScreencopyView / toplevel export): that path segfaults
  Hyprland 0.56.2.
- A hidden workspace shows the **last picture taken while it was on screen**. A window never seen on screen
  shows its app icon.
- Stored in **`$XDG_RUNTIME_DIR/quickshell-base/previews/`** (tmpfs). They're **temporary**: they survive
  shell reloads, and they're gone at logout/reboot. On startup the service re-reads that folder, so a hot
  reload doesn't lose them. Pictures of windows that no longer exist are pruned on every run.
- **Throttled** (`snap-windows.sh <dir> [max-age]` skips pictures younger than max-age):

  | Trigger | Re-capture pictures older than |
  |---|---|
  | workspace / window events (`workspacev2`, `focusedmonv2`, `openwindow`, `movewindowv2`, `closewindow`), 1.5 s debounce | 60 s |
  | opening the overview (all popups are closed first so none appear in the shots) | 10 s |
  | ↻ button | 0 (always) |

## Bar show/hide

`SUPER+J` or `SUPER+ALT+B` → `qs -c base ipc call bar toggle` (also `show` / `hide`), bound in
`~/.config/hypr/custom/keybinds.lua`. It hides the bar on every monitor (`Panels.barVisible`) and frees its
reserved space; popups, the launcher and SUPER+Tab still work. Not persisted: a shell reload shows it again.
The old end4 `quickshell:barToggle` global has no listener in `base`.

## Dashboard, theme, wallpapers — `modules/dashboard/`, `modules/theme/`, `modules/wallpapers/`

- **Clock pill** (time only, always centred) → **dashboard**. It shows the date, a now-playing card (MPRIS
  art, seekable progress, prev/play/next; a **source button** top-right opens a list of every MPRIS player — pick one to pin it (📌 icon), or **Auto** to follow whatever's playing; `Media.choose()`)
- **Browser tabs:** a browser has one MPRIS player for all its tabs, so in that list Chrome/Chromium get a
  **“N tabs ⌄”** dropdown of every tab with started media (from the **Beam extension** via
  `scripts/browser-tabs.py` → broker 127.0.0.1:8780; `services/BrowserTabs.qml`, polled every 3 s only while
  the list is open). Click a tab = pause that browser's other tabs and play this one (so its player follows);
  click the playing tab = pause; ↗ = bring the tab to the front. Matched by name: MPRIS identity
  `Chrome` ↔ Beam host brand `Google Chrome`. No dropdown if Beam isn't connected in that browser., and two cards: **Wallpaper** and **Theme**.
- **Local videos (mpv, needs `mpv-mpris`)** only give a file name like `S02E07.mp4`, so `Media.describe()`
  parses the path: show = text before the episode code, else the nearest non-generic folder (skips `Encoded`,
  `Season 2`, `Anime`, …); subtitle = `Season 2 · Episode 7 — <episode title>`. Real tags always win. With
  no art, `ffmpegthumbnailer` grabs a frame at 25% → `~/.cache/quickshell-base/media-thumbs/<md5 path>.jpg`.
- **Theme picker:** presets (Catppuccin Mocha/Latte, Nord, Gruvbox, Rosé Pine, Tokyo Night, Dracula,
  Everforest), plus **From wallpaper** (end4-pC's matugen colours, which keeps following wallpaper changes),
  plus an exact editor per colour role (SV square, hue, opacity, hex). Changes are live, and **every module
  reads colours only through `Appearance.colors.*`**, so the launcher, overview, menus and side box re-theme
  instantly. Saved in `~/.local/state/quickshell-base/theme.json`.
- **Kitty follows the theme**: background, text, cursor, selection, URL, borders, tabs and the 16 ANSI colours.
  Each preset has its own published terminal palette (`ansiPalettes` in `Theme.qml`); **From wallpaper** uses
  color0–15 from end4's generated `kitty-theme.conf`; **Custom** keeps the palette of the preset it was edited
  from (`ansi` in theme.json). Every theme change writes two files in `~/.local/state/quickshell-base/`:
  `kitty.conf` (included by `~/.config/kitty/kitty.conf` *after* end4's palette, reloaded via `pkill -USR1 -x kitty`)
  and `sequences.txt` (OSC 4/10/11/12/17/19 escape codes), which is also pushed to every `/dev/pts/N`.
  ⚠️ The escape codes are the part that matters: `~/.config/fish/config.fish` cats end4's `sequences.txt` on
  every shell start, and colours set by escape codes beat kitty.conf and survive a reload, so fish cats ours
  right after end4's. Without it the kitty.conf override never shows.
- **Wallpaper picker:** a 4-column grid of `~/Pictures/Wallpapers` **and `~/Pictures/wallhaven-toplist`** (added
  2026-09-30; sources are `Wallpapers.dirs`, top level only, so `.originals/` is hidden; sorted by path, so each
  folder's wallpapers stay together). The carousel uses the same list. A click applies the wallpaper via end4-pC's `switchwall.sh`, which also re-themes. It also has
  shuffle, rescan, and ← back to the dashboard. A **Scaling** row (Fill / Fit / Stretch / Center / Tile) is
  saved in `~/.local/state/quickshell-base/wallpaper.json`. Thumbnails come from `scripts/make-thumbs.sh`
  → `~/.cache/quickshell-base/thumbs/<md5(path)>.jpg`.
- **Background** (`modules/background/`) draws the wallpaper itself and cross-fades on change.

## Notifications — `services/Notifs.qml`, `modules/notifications/`

`base` is the **notification daemon** (Quickshell `NotificationServer` owns `org.freedesktop.Notifications`
while it runs; `keepOnReload`, so hot reloads don't drop it).

- **Toasts** hang under the **quick-settings (Wi-Fi) island** on the focused monitor, newest on top, at
  most 4 (the oldest expires to make room), and the same width as the quick-settings card. While quick settings
  is open on that screen they drop below the card instead of covering it.
- **Minimal by design:** a single row of icon · **summary** · body (up to 2 lines), with a small picture on the
  right only for real images (album art, screenshots). There's **no close button and no countdown bar**.
  Action buttons appear only when the app sends actions (e.g. `notify-send -A`).
- **Every toast times out on its own:** the app's expire_timeout (capped at 30 s), else **6 s**; critical ones
  get an accent ring and **10 s**. Hovering pauses the timer invisibly. A click runs the app's "default"
  action if there is one, otherwise it just closes the toast early. Toasts slide in from the right and out
  the same way.
- **Icons:** `notify-send -i` (and many apps) send the icon as the *image* hint, which Quickshell exposes as
  `image://icon/<name-or-path>`. That's treated as the icon, not a picture. Order: app_icon → icon-type
  image → the sender's desktop entry → generic.
- Closing tells the sending app (timed out = "expired", click/action = "dismissed"). After a hot reload the
  shown toasts are rebuilt from the server's tracked notifications.
- ⚠️ Only one daemon can own the bus. **mako is stopped and masked** (`systemctl --user mask mako.service`,
  2026-09-27) so D-Bus can't auto-start it when `base` restarts. Undo with `systemctl --user unmask mako`.
  If another daemon holds the name, the log says "Could not register notification server", and Quickshell
  takes over by itself once that daemon exits.
- Test: `notify-send -a Test -i dialog-information "Title" "Body"`, add `-u critical`, or
  `-A yes=Yes -A no=No` (blocks until answered).

## Settings window — `modules/settings/`, `services/Monitors.qml`, `services/HyprOptions.qml`

A real **floating window** (Quickshell `FloatingWindow`, title `base-settings`; `~/.config/hypr/custom/rules.lua`
floats, centres and sizes it 1100×760). Open it with the **gear** in the quick-settings header or
`qs -c base ipc call settings toggle | open <page> | close`. Esc or ✕ closes it. Pages load on demand, so
Wi-Fi/Bluetooth scans and the Tailscale/`ip addr` polls only run while their page is showing.

| Page | What it does |
|---|---|
| Network | Wi-Fi on/off; networks with Connect / Disconnect / Forget + password prompt; every interface's addresses (`ip -j addr`, 5 s) |
| Display | Drag-to-arrange map (edges snap), per monitor: on/off, resolution, refresh, scale, orientation, mirror, X/Y. **Line up** packs them left→right; **Identify** shows name tags on every screen |
| Bluetooth | power, discoverable, paired devices (Connect / Trust / Forget, battery), Scan + Pair |
| Tailscale | up/down, tailnet IP, the exit-node picker from quick settings (taller) |
| Sound | output volume + device, microphone volume + device |
| Hyprland | layout (dwindle/master/scrolling/monocle + per-layout options), gaps, border, rounding, blur, shadows, opacity, dim, animations, focus-follows-mouse, sensitivity, key repeat, VRR (Off / Fullscreen only) |
| Appearance | opens the theme / wallpaper pickers |

**Display is apply-then-confirm.** Nothing reaches Hyprland until **Apply** (`hyprctl eval 'hl.monitor({…})'` per
output). Then **Keep** within 15 s, or it reverts on its own. Keep writes **`~/.config/hypr/monitors.lua`**
(old copy → `.bak.<ts>`), which `hyprland.lua` loads *after* `custom/general.lua`, so it wins. Delete it to fall back.
Rules match `desc:<make> <model>` (the Dell's full description with its `#…` serial doesn't match). A monitor
left on its fastest mode is saved as **`highrr`**, not a fixed mode: a fixed mode the link doesn't offer fails the
atomic commit and takes every monitor down (the Samsung once came up 60 Hz-only).

**Hyprland options apply live** (`hl.config({…})`, 250 ms debounce) and are saved one line each to
**`~/.config/hypr/hyprland/shellOverrides/main.lua`**, the file loaded last, in the same line format end4-pC
writes. That's why it wins over `hyprland/general.lua` and `custom/general.lua`. VRR "always" (1) is left out on
purpose: it wedged the Dell.

## Quick settings — `modules/quicksettings/`

Wi-Fi and Bluetooth tiles (a click toggles; the chevron lists networks or paired devices), a volume slider
(its icon mutes) with an output-device picker, and a brightness slider. Brightness uses DDC/CI through
ddcutil on every external monitor at once, each scaled to its own maximum: 🔴 the Dell reports **0–450**,
not 0–100. The HDP dongle has no DDC.

**Night light / Dark mode** tiles sit under Wi-Fi/Bluetooth (Dark mode has no chevron — `ToggleTile { expandable: false }`):
- Night light (`services/NightLight.qml`) drives **hyprsunset** over `hyprctl hyprsunset`: on = the saved
  temperature, off = `identity`. Starts hyprsunset if it isn't running. State is read back on open (temperature
  < 6000 = on). Its chevron drops down `NightLightPanel.qml` — a plain Rectangle in BarPopup's `overlayData` layer, positioned
  under the tile with `mapToItem` (⚠️ as a child of the tile it drew fine but got no clicks outside the tile's bounds;
  ⚠️ a Controls `Popup` ate the chevron click so it wouldn't collapse), the tile's width,
  floating over the rows below — with two icon-only buttons, warmer (`wb_twilight`) and cooler (`wb_sunny`),
  outlined in the dropdown's own colours. No temperature readout in the dropdown; the tile's sublabel shows it. Each press steps 250 K (`NightLight.step`) within 2500–5500 K; holding repeats
  (400 ms, then every 150 ms); either turns the filter on. Applied throttled 80 ms. Temperature saved in
  `~/.local/state/quickshell-base/nightlight.json`.
- Dark mode (`services/DarkMode.qml`) flips the **system** preference for apps — gsettings `color-scheme`
  (`prefer-dark`/`prefer-light`) + `gtk-theme` (`adw-gtk3-dark`/`adw-gtk3`), the same keys end4's switchwall.sh
  uses. It **also flips the shell's own colours**: `DarkMode.dark` → `Theme.dark`. When the theme's background
  brightness disagrees with it, `Theme.colors` swaps bg ↔ text (bg keeps its opacity). Surface/hover/muted are
  re-mixed between those two, the border is inverted, and the accent is kept. `Appearance.colors` reads
  `Theme.colors`, and kitty follows it (ANSI 0↔7, 8↔15 swapped). The saved palette (`Theme.current`,
  theme.json) is never modified, so the picker still edits the original. `shell.qml` calls `DarkMode.refresh()`
  at startup.

## Next / previous wallpaper

**SUPER+ALT+Right** / **SUPER+ALT+Left** (`qs -c base ipc call wallpaper next|prev`, bound in
`~/.config/hypr/custom/keybinds.lua`) step through `Wallpapers.files` (both source folders, wraps around).
Holding the key moves `current` on each press, and `switchwall.sh` runs once, 300 ms after the last press.
The IPC target is `wallpaper` (singular) because `wallpapers` is the picker popup's target.

## Wallpaper carousel — `modules/carousel/WallpaperCarousel.qml`

**SUPER+ALT+W** (`qs -c base ipc call carousel toggle`) opens a full-screen overlay (one per monitor, like the launcher)
with a looping horizontal `PathView` of `Wallpapers.files`, opened on the current wallpaper.
- ←/→, h/l, mouse wheel (either axis, one card per notch), or drag/flick to scroll. Home/End = first/last.
- Click a side card to centre it; **Enter** or click the centre card sets it (`Wallpapers.set` → switchwall.sh) and closes.
  Esc / click the backdrop closes.
- Cards are tall **2:5** (base height 57% of the monitor), with a **25 px gap** (`gap`), max **4 per side** (`side`;
  a 5th fades in only while scrolling). The centre card is **1.44×** (82% of the screen height); size grows
  continuously with distance from the centre, and neighbours are shifted by half the extra width so the gap holds.
- **Arch:** the row is bent over a circle (`archRadius`, ~35° at the screen edge). Each card slides along it and
  tilts with it, so cards drop and rotate toward the lower corners as they move out. Spacing is measured along the
  cards' bottom edges (centres ride a circle half a card larger), so the tightest gap is still 25 px. Cards fade
  over the last card-width before the screen edge; 380 ms move animation.
- Each card shows the cached thumbnail at once and fades in a sharper decode of the real file (`sourceSize` capped).
  The current wallpaper has an accent ring. Under the row: an `n / total` counter (accent when it's the
  current wallpaper) and a thin progress bar driven by the continuous `PathView.offset`, so it slides with the
  scroll animation and tracks drags live. No file name or help text (removed at the user's request).

## Dock — ARCHIVED 2026-09-30

The floating dock was removed at the user's request (they don't want it). Code + pinned list + restore steps:
`~/.config/quickshell/_archive/base-dock-2026-09-30/`. `Appearance.dock` sizes are left in place, unused.

## Volume / brightness OSD — `modules/osd/OsdPopup.qml`, `services/Osd.qml`

A pill near the bottom centre of the **focused** monitor — `[icon] ───●─── 42%` — that pops up whenever the
volume or mute state changes (media keys run `wpctl`, which PipeWire reports back; bar scroll; anything) or
brightness is set through the shell. It fades out after **1.5 s**; hovering keeps it up. The slider is live
(drag to set), and the icon mutes when it's showing volume.

- Volume changes are ignored for 1.5 s at startup and after the default output switches, so PipeWire's
  initial report and a new device's volume don't flash it.
- Brightness isn't polled over DDC, so only changes made through the shell (quick-settings slider, OSD,
  `brightness` IPC) show it. `Brightness.userChanged` is the signal it listens to.
- It stays quiet while quick settings is open (same sliders there).

---

## Hyprland wiring

In `~/.config/hypr/custom/keybinds.lua`; the end4-pC binds on the same keys are `hl.unbind`-ed first:

```lua
-- lone Super tap → launcher (fuzzel if base isn't running). Release bind = combos don't fire it.
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("qs -c base ipc call launcher toggle || pkill fuzzel || fuzzel"), { release = true })
hl.bind("SUPER + SUPER_R", …same…, { release = true })
-- SUPER+Tab → window overview
hl.bind("SUPER + Tab", hl.dsp.exec_cmd("qs -c base ipc call windows toggle"))
```

Apply with `hyprctl reload && hyprctl configerrors`. Before these binds existed, tapping Super opened
**fuzzel**, end4-pC's fallback when `qs -c end4-pC` isn't running.

Under the Lua config every dispatch is Lua: `Hyprland.dispatch('hl.dsp.…(…)')`. Quickshell's
`HyprlandWorkspace.activate()` sends the old string syntax, which is rejected, so use
`hl.dsp.focus({ workspace = "N" })` instead.

## State and cache files

| Path | What | Lifetime |
|---|---|---|
| `~/.local/state/quickshell-base/theme.json` | palette + preset name | persistent |
| `~/.local/state/quickshell-base/kitty.conf` | kitty colour overrides (generated from theme.json) | regenerated |
| `~/.local/state/quickshell-base/sequences.txt` | terminal OSC colour codes (fish cats it on start) | regenerated |
| `~/.local/state/quickshell-base/wallpaper.json` | scaling mode | persistent |
| `~/.local/state/quickshell-base/launcher.json` | launch counts per desktop id | persistent |
| `~/.cache/quickshell-base/thumbs/` | wallpaper thumbnails | cache |
| `$XDG_RUNTIME_DIR/quickshell-base/previews/` | window snapshots | **tmpfs — gone at logout** |

State lives outside the config folder on purpose: writing inside it would trigger a hot reload.

## Layout

```
base/
├── shell.qml                  entry point + //@ pragmas (QApplication, Basic controls, Papirus-Dark icons);
│                              Background, Bar, one Launcher per screen
├── config/Appearance.qml      fonts, sizes, animation speeds, launcher opacity; colours come from Theme
├── config/Theme.qml           live palette (JsonAdapter ↔ theme.json), presets, wallpaper palette
├── services/                  singletons that hold state      → import qs.services
│   ├── Time.qml               date/time (SystemClock)
│   ├── Media.qml              MPRIS players, active-player choice, video title parse + thumbs
│   ├── Wallpapers.qml         folder listing, thumbnails, current, apply
│   ├── Audio.qml              default PipeWire sink
│   ├── Net.qml                Wi-Fi via Quickshell.Networking
│   ├── Bt.qml                 BlueZ adapter + paired devices
│   ├── Brightness.qml         ddcutil detect/get/set, debounced, per-display max
│   ├── Apps.qml               icon lookup for a window
│   ├── AppSearch.qml          launcher: app list, ranking, launch counts, uwsm-app launch
│   ├── FileSearch.qml         launcher: fd over ~, ranking, mime icons, xdg-open
│   ├── Osd.qml                volume/brightness OSD state, change detection, osd + brightness IPC
│   ├── Notifs.qml             notification daemon (NotificationServer) + the toast list, timeouts, icons
│   ├── Previews.qml           window snapshots (tmpfs, throttled, re-seeded at startup)
│   └── Panels.qml             which popup is open (one at a time) + IPC handlers
├── widgets/                   reusable building blocks        → import qs.widgets
│   ├── StyledText  MaterialIcon  Island  HoverRect  ToggleTile  IconSlider  ListRow
│   ├── BarPopup.qml           drop-down card window: placement, fade, Esc,
│   │                          overlayData (layer above content), keyHandler (exclusiveKeyboard: keep false)
│   ├── SegmentedControl.qml   row of mutually exclusive buttons
│   └── ColorEditor.qml        HSV square + hue/opacity bars + hex field
└── modules/                   actual UI, one folder each       → import qs.modules.<name>
    ├── background/     Background.qml
    ├── bar/            Bar.qml  WorkspaceButton.qml  ClockPill.qml  QuickSettingsButton.qml
    ├── launcher/       Launcher.qml
    ├── dismiss/        OutsideClick.qml (per-screen click-catcher that closes the open popup)
    ├── notifications/  Toasts.qml (per-screen stack under the Wi-Fi island)  Toast.qml (one minimal toast)
    ├── windows/        WindowOverview.qml (grid, keys, menu, drag logic)  WindowCard.qml  TrayStrip.qml (tray pill)
    │                   EmptyWorkspaceBox.qml (drop box shown beside the overview mid-drag)
    ├── dashboard/      Dashboard.qml  MediaCard.qml  WallpaperButton.qml  ThemeButton.qml
    ├── theme/          ThemePicker.qml  PresetChip.qml
    ├── wallpapers/     WallpaperPicker.qml  WallpaperGrid.qml
    ├── quicksettings/  QuickSettings.qml  WifiList.qml  BluetoothList.qml  AudioOutput.qml
    └── settings/       SettingsWindow.qml (FloatingWindow + sidebar)  *Page.qml  MonitorCanvas.qml  IdentifyOverlay.qml
scripts/make-thumbs.sh         vipsthumbnail, 4 parallel, prints each finished hash
scripts/snap-windows.sh        grim each window on a visible workspace (skip fresh ones), prune dead ones
```

(`modules/bar/Menu.qml` is a scratch file of your own. It's unused, so leave it alone.)

## Rules

- File (type) names start with an **Uppercase** letter; folders are lowercase.
- Files in the same folder see each other with no import.
- Cross-folder: `import qs.<path>` (path relative to shell.qml). No qmldir needed.
- Singletons: `pragma Singleton` on line 1 + `Singleton {}` as the root type.
- Don't name a service after a Quickshell type (`Network`, `Bluetooth`) — hence `Net`, `Bt`.
- Never start a property name with `on` + capital (`onAccent`) — QML treats it as a signal handler.
- `//@ pragma` lines only apply on a fresh launch, not a hot reload.
- Colours: always `Appearance.colors.*` (never literals) so the theme picker reaches everything.
- Dispatch Hyprland with Lua (`hl.dsp.*`), never the old string syntax.

## Gotchas learned the hard way

- **Qt `Keys` order:** specific handlers (`onEscapePressed`) run *before* `onPressed`, so a generic hook
  never sees Esc. BarPopup therefore handles Esc inside `onPressed`, after `keyHandler`.
- **Pointer handlers vs MouseArea:** a MouseArea that accepts the press stops delivery to the handlers of
  items *below* it. Put the Drag/TapHandler on an Item *above* it; passive grabs don't block.
- **Flickable steals drags** (`interactive: true`), so `interactive: false` plus a `WheelHandler` is used. ⚠️ That trick **does not work in the Settings `FloatingWindow`**: the WheelHandler never fired there. Settings uses a normal interactive Flickable instead (wheel + scrollbar), and the monitor-map MouseArea sets `preventStealing: true` so dragging a monitor still works.
- **Width changes mid-drag re-centre a BarPopup** and move every drop target under the pointer. Keep the
  card width stable during a drag; that's why the empty-workspace list is a separate box.
- **Outside-click close:** `HyprlandFocusGrab` (removed) swallowed outside clicks and cleared ~2 s after
  a terminal IPC open. `modules/dismiss/OutsideClick.qml` does the job instead.
- **`WlrKeyboardFocus.Exclusive` confines the pointer** to that layer in Hyprland: outside clicks go
  nowhere. Only full-screen layers (the launcher, with its own backdrop) can use it. Everything else uses
  OnDemand.
- Popups need `ExclusionMode.Normal` + `exclusiveZone: 0` to land below other bars.
- `//@ pragma IconTheme Papirus-Dark` is needed or some app icons fail.
- `DesktopEntries.heuristicLookup` isn't reactive: touch `applications.values` in the binding.
- **Repeater + JS array model rebuilds every delegate** when the array changes (timers and animations
  restart). Use Quickshell's `ScriptModel { values: … }`, which diffs and keeps existing delegates (toasts).
- A `qs -p` test config sees an **empty** `ToplevelManager` unless it references
  `ToplevelManager.toplevels` at startup.
- DDC: the Dell's VCP 10 max is **450** — writing raw percentages once dimmed it to 22%.

## Testing without touching the mouse

- Real input: `ydotool` (the `ydotool.service` socket). `wtype -M logo` / `-P Super_L` **don't** trigger
  Hyprland binds. Keys: `ydotool key 125:1 15:1 15:0 125:0` = Super+Tab; 125 = Super, 42 = Shift,
  28 = Enter, 1 = Esc, 103/108/105/106 = ↑/↓/←/→.
- Cursor: `hyprctl dispatch 'hl.dsp.cursor.move({ x = X, y = Y })'` (logical coords; DP-2 is scale 1.25).
  A warp **does not start a Qt drag**; use relative `ydotool mousemove -x/-y` while `ydotool click 0x40`
  holds the button (`0x80` releases). Relative moves are accelerated and drift, so check `hyprctl cursorpos`.
- Screenshot a monitor: `grim -o DP-2 out.png`. Whether a popup is mapped:
  `hyprctl layers -j | jq '[..|objects|select(.namespace?=="base-windows")]|length'`.
- ⚠️ Check the popup is open before sending keys. If it isn't, the keys go to the focused app. The first
  injected key after a pause has twice gone missing.

## Adding a module

1. `mkdir modules/<name>` and create `<Name>.qml` there.
2. In `shell.qml`: `import qs.modules.<name>` and add `<Name> {}` inside ShellRoot.
3. Shared data → a new singleton in `services/`; shared styling → `config/Appearance.qml`.
4. A new drop-down: wrap its content in `BarPopup { name: "x" }`, add a `PopupIpc { target: "x" }` to
   `Panels`, instantiate it in `Bar.qml`. Keyboard-driven? Give it a `keyHandler` (not `exclusiveKeyboard`).
