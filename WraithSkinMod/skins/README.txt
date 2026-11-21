WraithSkinMod skins
===================

Each skin is a folder in here. The folder can contain:

  colours.png         the colour image from the WraithSkinMod website
  effects.txt         every other setting (optional, see below)
  jacket_pattern.png  a pattern image drawn on the jacket (optional)
  sword_pattern.png   replaces the engravings on the hoversword (optional)
  sword_mask.png      decides which sword areas take which colour (optional, advanced)
  skin.json           the skin's name and author (optional)
  preview.png         a picture of the skin (optional, not used in-game yet)

A single PNG placed directly in this folder also works as a colours-only skin.
Anything a skin leaves out stays as the original Wraith. These settings only
change how things look; gameplay is never affected.

In-game: F6 next skin, F5 previous skin, F7 reload this folder after editing.
Change the keys in ..\settings.txt

effects.txt: one setting per line, Name=value. Colours are #RRGGBB.
Numbers: 0 is off / none, 1 is full, unless a range is given.

HELMET FLAME
  FlameOuter, FlameMiddle, FlameCore      flame colours
  FlameBrightness (1), FlameGlow (2), FlameCoreGlow (15), FlameWidth (1)
  FlameFalloff (0-3)       lower = taller, fuller flame
  FlameSwirl (0-6)         wispy, swirling flame
  FlameSparkle (0-6)       breaks the flame into sparkles
  FlameTaper (-1 to 3), FlameSpeed (0-10), FlameCoreSize (0-8)

EYES AND HELMET
  EyeColour, EyeGlow (25)
  HelmetLines1, HelmetLines2

WHOLE FIGURE (body and jacket together)
  GlowColour, PulseFlash, BoostCharge, FlameLight, FlameLightStrength (0.6)
  TrimColour, TrimBrightness (0.35)       embroidery

BODY ONLY (everything except the jacket) - start each name with Body
JACKET ONLY - start each name with Jacket
  ...Tint            colour that multiplies all the colours
  ...Saturation      0-4 (more or less colourful)
  ...Brightness      0-16
  ...Aura            colour of a glow around it
  ...AuraStrength    0-1 (turns the aura on)
  ...Flash           pulse flash colour
  ...Lava            0-1 glowing lava look
  ...LavaColour      colour of the lava (FFAB21 orange)
  ...LavaGlowColour  colour of the lava glow in the lines and patterns (FFD600 yellow)
  ...Damage          0-1 colour wash, with ...DamageColour
  ...Dirt, ...Wet    0-1
  ...Silhouette      0-1 black silhouette
  ...ShadingLines    0-2 (0 gives a dark sketched look)
  ...MetalContrast   0-2
  Examples: BodyLava=1  JacketTint=#FF8800  JacketAuraStrength=1

JACKET EXTRAS
  JacketAltColours (0-1)   the game's alternate jacket colours
  JacketEmbroidery         embroidery colour on the jacket only

HOVERSWORD
  SwordTint                main blade colour
  SwordBlade, SwordHilt, SwordGlint
  SwordGlyphDarkness (0.55)  engravings: 0 none, 1 black
  SwordGlow, SwordAuraStrength (0-1)   glow around the sword
  SwordBoostGlow                       while boosting
  SwordSilhouette (0-1)

BOOSTER JETS (the glow at the back of the hoversword)
  JetWidth (60), JetHeight (60)   size, 0-300
  JetOpacity (1)                   0 hides them

Not changeable: particle effects such as wisps, pulses, trails and the boost light.
Older skins that still list those settings load fine; the settings are skipped.
