# WraithSkinMod

Custom skins for the Wraith in **Sword of the Sea** (PC). Recolour the Wraith, the helmet flame, the eyes and the hoversword, add pattern images to the jacket and blade, and switch between skins in game with one key.

Make skins with the skin maker website (`docs/index.html`, also hosted on GitHub Pages), or write them by hand.

> Unofficial fan mod. Not affiliated with or endorsed by the makers of Sword of the Sea. It only changes how the Wraith looks on your own PC; gameplay is not affected.

## What it changes

Only the Wraith's and the hoversword's own materials:

- **Colours:** every colour zone of the body, jacket, helmet and legs (from a colour image).
- **Helmet flame:** colours, brightness, width, and shape (height, swirl, sparkle, taper, speed, core size).
- **Eyes and helmet lines.**
- **Effects:** for the body and the jacket separately: tint, saturation, brightness, aura, pulse flash, lava, colour wash, dirt, wet, silhouette, shading lines, metal contrast.
- **Glows:** glow, pulse flash and boost charge colours, the flame's light on the body, embroidery colour.
- **Hoversword:** blade tint, inner blade, hilt, engravings, glint, glow, boost glow, silhouette, plus engraving and colour-area images; booster jet size and visibility.
- **Jacket pattern image.**

It does **not** change particle effects (wisps, pulse wave, trails), lights, or anything in the game's files.

## Requirements

- *Sword of the Sea* on PC (Steam), **patch 1.6**
- Windows

Nothing else needs to be installed. The download includes a version of UE4SS, the script loader the mod runs on.

## Install

1. Download `WraithSkinMod-0.75.zip` from the [Releases page](../../releases).
2. Close the game.
3. Open the game's `Win64` folder. In Steam, right-click the game, choose **Manage → Browse local files**, then go to:

   ```
   Surfer\Binaries\Win64
   ```

4. Extract the zip into that folder. When you're done it should look like this:

   ```
   Win64\
   ├── SwordOfTheSea-Win64-Shipping.exe
   ├── dwmapi.dll                  <- from the zip
   └── ue4ss\                      <- from the zip
       ├── UE4SS.dll
       ├── UE4SS-settings.ini
       └── Mods\
           └── WraithSkinMod\
   ```

5. Start the game.

## Uninstall

Delete `dwmapi.dll` and the `ue4ss` folder from the `Win64` folder. The game is then back to its original state.

## If you already use UE4SS in Sword of The Sea

Don't extract the whole zip. Copy only the `ue4ss\Mods\HiVisWraith` folder from the zip into your existing `ue4ss\Mods` folder. The mod enables itself through its own `enabled.txt`.

Your UE4SS build must support Unreal Engine 5.8. The one in the zip is experimental build `v3.0.1-1218`.

## Use

| Key | Action |
|---|---|
| F6 | Next skin |
| F5 | Previous skin |
| F7 | Reload the skins folder (after adding or editing a skin) |

The chosen skin is remembered. Change the keys in `WraithSkinMod\settings.txt` (created on first run).

Included skins: **Cotton Candy**, **Jolly**, **Nebula**, **Red Wraith**, **Stress Test(may crash)**.

## Making skins

1. Open the skin maker (GitHub Pages link, or `docs/index.html` in a browser).
2. Pick colours on the model, adjust the sections on the right, and click **Download skin**.
3. Unzip the download into `ue4ss\Mods\WraithSkinMod\skins\`, so it becomes its own folder.
4. In the game press **F7**, then **F6** until your skin shows.

A skin is a folder:

```
skins\My Skin\colours.png         colour image from the skin maker
skins\My Skin\effects.txt         other settings, one per line: Name=value
skins\My Skin\jacket_pattern.png  optional
skins\My Skin\sword_pattern.png   optional
skins\My Skin\sword_mask.png      optional
skins\My Skin\skin.json           name and author
skins\My Skin\preview.png         optional picture
```

Every setting is listed in `WraithSkinMod\skins\README.txt`. Anything a skin leaves out stays as the original Wraith.

## Stress test skin

`extras/Stress Test (may crash)` sets every setting to an extreme value and loads three 8192 × 8192 pattern images.

## GitHub Pages (skin maker)

The skin maker is a single file, `docs/index.html`. To host it: repository **Settings → Pages**, publish from a branch, choose the default branch and the `/docs` folder, then save.

## Credits and licence

    UE4SS by the UE4SS-RE team, MIT licence. A copy of the licence is in ue4ss\LICENSE.
    Sword of the Sea is developed by Giant Squid. This is an unofficial fan mod and is not affiliated with or endorsed by Giant Squid.
    Original skins "Cotton Candy", "Jolly", "Nebula", and "Red Wraith" were created by myself. The stress test skin was created by Claude Opus 5.5.
    Mod code in Lua to load the textures was created by Claude Fable 5.2, the textures themselves were created by me. I do not have experience coding in Lua but I do have experience coding in Python so I wrote a snippit of code in Python for Claude to create the mod based in Lua, so it is of my own design.
