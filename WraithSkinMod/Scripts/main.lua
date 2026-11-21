-- WraithSkinMod 0.75 for Sword of the Sea (UE4SS Lua mod)
--
-- Skins live in the "skins" folder next to this mod's Scripts folder:
--   skins\My Skin\colours.png   colour image made with the WraithSkinMod website
--   skins\My Skin\effects.txt   optional: flame, eyes, helmet lines, glow colours
--   skins\My Skin\skin.json     optional: {"name": "...", "author": "..."}
--   skins\My Skin\preview.png   optional: picture for people browsing skins
--   skins\Another Skin.png      a single PNG also works (colours only)
-- Anything a skin leaves out stays as the original Wraith.
--
-- The mod only changes the Wraith's and hoversword's own materials: colour images, pattern
-- images and the colour/number settings those materials offer. It does not touch particle
-- effects, lights or game variables.
--
-- Keys (change them in settings.txt): F6 next skin, F5 previous skin,
-- F7 reload skins from disk. The chosen skin is remembered in selected.txt.
-- Skin files are only ever read as data, never run as code.

local VERSION = "0.75"
local TAG = "[WraithSkinMod] "
local function log(m) print(TAG .. tostring(m) .. "\n") end

local ORIGINAL_NAME = "Original Wraith"
local WRAITH_CLASS = "Wraith_BP_C"
local CHECK_EVERY_MS = 1000
local VISIBLE, HIDDEN = 4, 2   -- ESlateVisibility values

---------------------------------------------------------------- helpers
local function isValid(o)
    if o == nil then return false end
    local ok, v = pcall(function() return o:IsValid() end)
    return ok and v
end

local function className(o)
    local ok, n = pcall(function() return o:GetClass():GetFName():ToString() end)
    return ok and n or "?"
end

local function addr(o)
    local ok, a = pcall(function() return o:GetAddress() end)
    return ok and tostring(a) or nil
end

local function S(f) local ok, v = pcall(f) if ok then return v end return nil end
local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return nil end
    local d = f:read("a")
    f:close()
    return d
end

local function writeFile(p, data)
    local f = io.open(p, "wb")
    if not f then return false end
    f:write(data)
    f:close()
    return true
end

local function modDir()
    local ok, info = pcall(function() return debug.getinfo(1, "S") end)
    if ok and info and info.source then
        local src = info.source:gsub("^@", "")
        return src:match("^(.*)[/\\][Ss]cripts[/\\][^/\\]*$")
    end
    return nil
end

local MOD_DIR = modDir() or "Mods\\WraithSkinMod"
local MOD_FOLDER_NAME = MOD_DIR:match("([^/\\]+)$") or "WraithSkinMod"
log("mod folder: " .. MOD_DIR)

-- Reads "key = value" lines. Lines starting with # ; or // are comments.
-- Colour values like #FF8800 are fine because only whole lines can be comments.
local function parseKeyValues(text)
    local t = {}
    if not text then return t end
    text = text:gsub("^\239\187\191", "")          -- strip UTF-8 BOM
    for line in (text .. "\n"):gmatch("([^\r\n]*)\r?\n") do
        local s = trim(line)
        if s ~= "" and not s:match("^;") and not s:match("^//") and not s:match("^#") then
            local k, v = s:match("^([%w_]+)%s*=%s*(.-)$")
            if k then t[k:lower()] = trim(v) end
        end
    end
    return t
end

-- Pulls simple "key": "string" values out of skin.json without running it.
local function jsonString(text, key)
    if not text then return nil end
    local v = text:match('"' .. key .. '"%s*:%s*"(.-)"')
    if v then v = v:gsub('\\"', '"'):gsub("\\\\", "\\") end
    return v
end

---------------------------------------------------------------- settings
local settings = {
    nextskinkey = "F6", previousskinkey = "F5", reloadkey = "F7",
    showskinname = "1", messageseconds = "3",
}
do
    local path = MOD_DIR .. "\\settings.txt"
    local text = readFile(path)
    if text then
        for k, v in pairs(parseKeyValues(text)) do settings[k] = v end
    else
        writeFile(path, table.concat({
            "; WraithSkinMod settings. Lines starting with ; are notes.",
            "; Keys use UE4SS key names, for example F5, F6, F7, F8, NUM_ONE, PAGE_UP.",
            "NextSkinKey=F6",
            "PreviousSkinKey=F5",
            "ReloadKey=F7",
            "; 1 shows the skin name on screen when it changes, 0 hides it.",
            "ShowSkinName=1",
            "MessageSeconds=3",
            "",
        }, "\r\n"))
    end
end
local SHOW_TEXT = settings.showskinname ~= "0"
local MESSAGE_MS = math.floor((tonumber(settings.messageseconds) or 3) * 1000)
if MESSAGE_MS < 500 then MESSAGE_MS = 500 end
if MESSAGE_MS > 30000 then MESSAGE_MS = 30000 end

---------------------------------------------------------------- effects table
-- Every setting a skin can change. "body" = Wraith_Rig slots 0 and 1,
-- "eyes" = slot 2, "lines" = slot 3, "flame" = HeadFlameMesh slot 0.
-- kind: "colour" (hex, sRGB) or "number" (with min/max).
local EFFECTS = {
    { key = "FlameOuter",       target = "flame", param = "ColorA",              kind = "colour" },
    { key = "FlameMiddle",      target = "flame", param = "ColorB",              kind = "colour" },
    { key = "FlameCore",        target = "flame", param = "ColorCore",           kind = "colour" },
    { key = "FlameBrightness",  target = "flame", param = "Brightness",          kind = "number", min = 0, max = 10 },
    { key = "FlameGlow",        target = "flame", param = "EmissiveMult",        kind = "number", min = 0, max = 50 },
    { key = "FlameCoreGlow",    target = "flame", param = "CoreEmissiveMult",    kind = "number", min = 0, max = 100 },
    { key = "FlameWidth",       target = "flame", param = "FlameWidthMultiplier",kind = "number", min = 0, max = 5 },
    { key = "EyeColour",        target = "eyes",  param = "ColorTint",           kind = "colour" },
    { key = "EyeGlow",          target = "eyes",  param = "EyeGlow",             kind = "number", min = 0, max = 200 },
    { key = "HelmetLines1",     target = "lines", param = "ColorA",              kind = "colour" },
    { key = "HelmetLines2",     target = "lines", param = "ColorB",              kind = "colour" },
    { key = "TrimColour",       target = "both",  param = "PatternGoldColor",    kind = "colour" },
    { key = "TrimBrightness",   target = "both",  param = "PatternLineBrightness", kind = "number", min = 0, max = 5 },
    { key = "FlameLight",       target = "both",  param = "FakeLightColor",      kind = "colour" },
    { key = "FlameLightStrength", target = "both", param = "FakeLightBrightness1", kind = "number", min = 0, max = 5 },
    { key = "GlowColour",       target = "both",  param = "GlowColor",           kind = "colour" },
    { key = "PulseFlash",       target = "both",  param = "ChirpFlashColor",     kind = "colour" },
    { key = "BoostCharge",      target = "both",  param = "TurboChargeColor",    kind = "colour" },
    -- hoversword (the Wraith's child actor, Hoversword_Mesh, every material slot)
    { key = "SwordBlade",       target = "sword", param = "BladeColor",          kind = "colour" },
    { key = "SwordHilt",        target = "sword", param = "HiltColor",           kind = "colour" },
    { key = "SwordGlyphs",      target = "sword", param = "CorrosionColor",      kind = "colour" },
    { key = "SwordGlyphDarkness", target = "sword", param = "GroovesDarken",     kind = "number", min = 0, max = 1 },
    { key = "SwordGlint",       target = "sword", param = "GlintColor",          kind = "colour" },
    { key = "SwordGlow",        target = "sword", param = "BladeGlowColor",      kind = "colour" },
    { key = "SwordBoostGlow",   target = "sword", param = "BoostColor",          kind = "colour" },
}
-- Looks that can be set separately for the body (Wraith_Rig slot 0: everything but the jacket)
-- and the jacket (slot 1). Keys are "Body<Name>" and "Jacket<Name>". Found with WraithSkinProbe.
local PART_LOOKS = {
    { "Tint",          "OverallColorTint",         "colour" },
    { "Saturation",    "ColorSat",                 "number", 0, 4 },
    { "Brightness",    "ColorBrightness",          "number", 0, 16 },
    { "Aura",          "GlowColor",                "colour" },
    { "AuraStrength",  "GlowAlpha",                "number", 0, 1 },
    { "Flash",         "ChirpFlashColor",          "colour" },
    { "Lava",          "HeatOverride",             "number", 0, 1 },
    { "LavaColour",    "LavaTint",                 "colour" },
    { "LavaGlowColour","LavaAccumulationColor",    "colour" },
    { "Damage",        "Damage",                   "number", 0, 1 },
    { "DamageColour",  "DamageColor",              "colour" },
    { "Dirt",          "DirtOverride",             "number", 0, 1 },
    { "Wet",           "WetnessOverride",          "number", 0, 1 },
    { "Silhouette",    "BacklitAlpha",             "number", 0, 1 },
    { "ShadingLines",  "HatchingTextureDarkeness", "number", 0, 2 },
    { "MetalContrast", "MetalPatternDarkness",     "number", 0, 2 },
}
for _, part in ipairs({ { "Body", "body" }, { "Jacket", "jacket" } }) do
    for _, l in ipairs(PART_LOOKS) do
        table.insert(EFFECTS, { key = part[1] .. l[1], target = part[2], param = l[2], kind = l[3], min = l[4], max = l[5] })
    end
end
for _, e in ipairs({
    -- jacket extras
    { key = "JacketAltColours",  target = "jacket", param = "AltColorCloak",       kind = "number", min = 0, max = 1 },
    { key = "JacketEmbroidery",  target = "jacket", param = "PatternGoldColor",    kind = "colour" },
    { key = "JacketPattern",     target = "jacket", param = "CloakPattern",        kind = "image", file = "jacket_pattern.png" },
    -- flame shape
    { key = "FlameFalloff",      target = "flame",  param = "VerticalFalloff",     kind = "number", min = 0, max = 3 },
    { key = "FlameSwirl",        target = "flame",  param = "SwirlAmount",         kind = "number", min = 0, max = 6 },
    { key = "FlameSparkle",      target = "flame",  param = "Scale",               kind = "number", min = 0, max = 6 },
    { key = "FlameTaper",        target = "flame",  param = "Taper",               kind = "number", min = -1, max = 3 },
    { key = "FlameSpeed",        target = "flame",  param = "Speed (S)",           kind = "number", min = 0, max = 10 },
    { key = "FlameCoreSize",     target = "flame",  param = "Core",                kind = "number", min = 0, max = 8 },
    -- sword extras (SwordTint is the strongest blade colour; SwordGlyphs is the older name for it)
    { key = "SwordTint",         target = "sword",  param = "CorrosionColor",      kind = "colour" },
    { key = "SwordSilhouette",   target = "sword",  param = "BacklitAlpha",        kind = "number", min = 0, max = 1 },
    { key = "SwordAuraStrength", target = "sword",  param = "BladeGlowAlpha",      kind = "number", min = 0, max = 1 },
    { key = "SwordPattern",      target = "sword",  param = "HoverswordPattern",   kind = "image", file = "sword_pattern.png" },
    -- booster jets at the back of the hoversword (BoosterCard)
    { key = "JetWidth",          target = "jets",   param = "Width",               kind = "number", min = 0, max = 300 },
    { key = "JetHeight",         target = "jets",   param = "Height",              kind = "number", min = 0, max = 300 },
    { key = "JetOpacity",        target = "jets",   param = "Opacity",             kind = "number", min = 0, max = 1 },
    { key = "SwordColourMask",   target = "sword",  param = "PatternColorMask",    kind = "image", file = "sword_mask.png" },
}) do table.insert(EFFECTS, e) end

local EFFECT_BY_KEY = {}
for _, e in ipairs(EFFECTS) do
    EFFECT_BY_KEY[e.key:lower()] = e
    -- accept American spelling too
    EFFECT_BY_KEY[e.key:lower():gsub("colour", "color")] = e
end

local function srgbToLinear(c)
    c = c / 255
    if c <= 0.04045 then return c / 12.92 end
    return ((c + 0.055) / 1.055) ^ 2.4
end

local function parseColour(v)
    local r, g, b = v:match("^#?(%x%x)(%x%x)(%x%x)$")
    if not r then return nil end
    return { R = srgbToLinear(tonumber(r, 16)), G = srgbToLinear(tonumber(g, 16)),
             B = srgbToLinear(tonumber(b, 16)), A = 1 }
end

-- Settings from older versions that changed game effects rather than the Wraith's own
-- materials. They were removed to keep the mod stable; skins that still have them load fine.
local RETIRED = {}
for _, k in ipairs({ "BoostLight", "GhostTrail1", "GhostTrail2", "GhostTrailRainbow", "PulseColour",
                     "BoardTrail", "WispColour", "WispTrailColour", "SwordTrail", "TrimColour2",
                     "BodyStone", "BodyStoneColour", "BodyStoneTop", "JacketStone", "JacketStoneColour",
                     "JacketStoneTop", "SwordStone", "SwordStoneColour", "SwordStoneTop" }) do
    RETIRED[k:lower()] = true
    RETIRED[(k:lower():gsub("colour", "color"))] = true
end

local function parseEffects(text, skinName)
    local out = {}
    for k, v in pairs(parseKeyValues(text)) do
        local e = EFFECT_BY_KEY[k]
        if RETIRED[k] then
            -- quietly skip
        elseif not e or e.kind == "image" then
            log(skinName .. ": unknown setting '" .. k .. "' ignored")
        elseif e.kind == "colour" then
            local c = parseColour(v)
            if c then out[e.key] = c else log(skinName .. ": " .. e.key .. " needs a colour like #FF8800") end
        else
            local n = tonumber(v)
            if n then
                if n < e.min then n = e.min end
                if n > e.max then n = e.max end
                out[e.key] = n
            else
                log(skinName .. ": " .. e.key .. " needs a number")
            end
        end
    end
    return out
end

---------------------------------------------------------------- finding skins
local function childCI(dir, name)
    if type(dir) ~= "table" and type(dir) ~= "userdata" then return nil end
    local direct = dir[name]
    if direct then return direct end
    local lname = name:lower()
    for k, v in pairs(dir) do
        if type(k) == "string" and k:lower() == lname then return v end
    end
    return nil
end

local function filesOf(dir)
    local out = {}
    local ok = pcall(function()
        for _, f in pairs(dir.__files or {}) do
            table.insert(out, { name = f.__name, path = f.__absolute_path })
        end
    end)
    if not ok then log("could not list files") end
    return out
end

local function subdirsOf(dir)
    local out = {}
    pcall(function()
        for k, v in pairs(dir) do
            if type(k) == "string" and k:sub(1, 2) ~= "__" then
                table.insert(out, { name = k, dir = v })
            end
        end
    end)
    return out
end

local function findSkinsDir()
    local ok, dirs = pcall(IterateGameDirectories)
    if not ok or not dirs then log("IterateGameDirectories failed") return nil end
    local d = dirs.Game
    for _, part in ipairs({ "Binaries", "Win64", "ue4ss", "Mods", MOD_FOLDER_NAME, "skins" }) do
        d = childCI(d, part)
        if not d then return nil end
    end
    return d
end

local function isPng(n) return n:lower():match("%.png$") ~= nil end

local skins = {}   -- [1] is always the original Wraith

local function scanSkins()
    local list = { { name = ORIGINAL_NAME, id = "", effects = {} } }
    local dir = findSkinsDir()
    if not dir then
        log("no skins folder found (expected " .. MOD_DIR .. "\\skins)")
        skins = list
        return
    end
    local found = {}
    -- single PNG files = colour-only skins
    for _, f in ipairs(filesOf(dir)) do
        if isPng(f.name) then
            table.insert(found, { name = f.name:gsub("%.[Pp][Nn][Gg]$", ""), id = f.name, colours = f.path, effects = {} })
        end
    end
    -- folders = full skins
    for _, sd in ipairs(subdirsOf(dir)) do
        local skin = { name = sd.name, id = sd.name .. "/", effects = {} }
        local pngs, effectsPath, jsonPath = {}, nil, nil
        for _, f in ipairs(filesOf(sd.dir)) do
            local ln = f.name:lower()
            if ln == "effects.txt" then effectsPath = f.path
            elseif ln == "skin.json" then jsonPath = f.path
            elseif isPng(ln) and ln ~= "preview.png" then pngs[ln] = f.path end
            for _, e in ipairs(EFFECTS) do
                if e.kind == "image" and ln == e.file then skin.effects[e.key] = { image = f.path } end
            end
        end
        skin.colours = pngs["colours.png"] or pngs["colors.png"]
        if not skin.colours then
            local special = {}
            for _, e in ipairs(EFFECTS) do if e.kind == "image" then special[e.file] = true end end
            for name, p in pairs(pngs) do if not special[name] then skin.colours = p break end end
        end
        if jsonPath then
            local j = readFile(jsonPath)
            local n = jsonString(j, "name")
            if n and n ~= "" then skin.name = n end
            skin.author = jsonString(j, "author")
        end
        if effectsPath then for k, v in pairs(parseEffects(readFile(effectsPath), skin.name)) do skin.effects[k] = v end end
        if skin.colours or next(skin.effects) then
            table.insert(found, skin)
        else
            log("folder '" .. sd.name .. "' has no colour image or effects.txt, skipped")
        end
    end
    table.sort(found, function(a, b) return a.name:lower() < b.name:lower() end)
    for _, s in ipairs(found) do table.insert(list, s) end
    skins = list
    log("found " .. (#skins - 1) .. " skin(s)")
end

---------------------------------------------------------------- choosing
local current = 1
local stateVersion = 1
local textures = {}   -- colour image path -> Texture2D

local function selectedPath() return MOD_DIR .. "\\selected.txt" end

local function loadSelection()
    local saved = readFile(selectedPath())
    saved = saved and trim(saved) or ""
    current = 1
    for i, s in ipairs(skins) do
        if s.id == saved then current = i break end
    end
end

local function saveSelection()
    writeFile(selectedPath(), skins[current].id)
end

---------------------------------------------------------------- on-screen text
local widget, textBlock, hideHandle
local widgetCount = 0

local function buildWidget()
    if isValid(widget) and isValid(textBlock) then return true end
    local gi = FindFirstOf("GameInstance")   -- same as UE4SS UEHelpers.GetGameInstance
    if not isValid(gi) then return false end
    widgetCount = widgetCount + 1
    local n = tostring(widgetCount)   -- fresh names each time, in case an old widget is still being cleaned up
    local w = StaticConstructObject(StaticFindObject("/Script/UMG.UserWidget"), gi, FName("WraithSkinModWidget" .. n))
    w.WidgetTree = StaticConstructObject(StaticFindObject("/Script/UMG.WidgetTree"), w, FName("WraithSkinModTree" .. n))
    local canvas = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), w.WidgetTree, FName("WraithSkinModCanvas" .. n))
    w.WidgetTree.RootWidget = canvas
    local bg = StaticConstructObject(StaticFindObject("/Script/UMG.Border"), canvas, FName("WraithSkinModBG" .. n))
    bg:SetBrushColor({ R = 0, G = 0, B = 0, A = 0.55 })
    bg:SetPadding({ Left = 18, Top = 8, Right = 18, Bottom = 8 })
    local slot = canvas:AddChildToCanvas(bg)
    slot:SetAutoSize(true)
    slot:SetAnchors({ Minimum = { X = 0.5, Y = 0 }, Maximum = { X = 0.5, Y = 0 } })
    slot:SetAlignment({ X = 0.5, Y = 0 })
    slot:SetPosition({ X = 0, Y = 40 })
    local t = StaticConstructObject(StaticFindObject("/Script/UMG.TextBlock"), bg, FName("WraithSkinModText" .. n))
    pcall(function() t.Font.Size = 22 end)
    t:SetColorAndOpacity({ SpecifiedColor = { R = 1, G = 1, B = 1, A = 1 }, ColorUseRule = 0 })
    t:SetText(FText(" "))
    bg:SetContent(t)
    w:SetVisibility(HIDDEN)
    w:AddToViewport(99)
    widget, textBlock = w, t
    return true
end

local function showMessage(msg)
    log(msg)
    if not SHOW_TEXT then return end
    local ok, err = pcall(function()
        if not buildWidget() then return end
        if not widget:IsInViewport() then widget:AddToViewport(99) end
        textBlock:SetText(FText(msg))
        widget:SetVisibility(VISIBLE)
    end)
    if not ok then log("could not show text: " .. tostring(err)) return end
    if hideHandle and CancelDelayedAction then pcall(CancelDelayedAction, hideHandle) end
    hideHandle = ExecuteInGameThreadWithDelay(MESSAGE_MS, function()
        pcall(function() if isValid(widget) then widget:SetVisibility(HIDDEN) end end)
    end)
end

local function skinLabel()
    local s = skins[current]
    local label = "Skin: " .. s.name
    if s.author and s.author ~= "" then label = label .. " by " .. s.author end
    return label .. "  (" .. current .. "/" .. #skins .. ")"
end

---------------------------------------------------------------- applying
local originals = {}   -- material address -> { [param] = original value }
local applied = {}     -- material address -> stateVersion last applied
local warned = {}

local function warnOnce(key, msg)
    if warned[key] then return end
    warned[key] = true
    log(msg)
end

local function getMID(comp, slot)
    local mat = comp:GetMaterial(slot)
    if not isValid(mat) then return nil end
    if className(mat) == "MaterialInstanceDynamic" then return mat end
    pcall(function() comp:CreateDynamicMaterialInstance(slot, mat, FName("None")) end)
    mat = comp:GetMaterial(slot)
    if isValid(mat) and className(mat) == "MaterialInstanceDynamic" then return mat end
    return nil
end

-- Loads the colour image. A loaded image is only reused while it is still on a Wraith material
-- in this skin (stateVersion); otherwise the game may have cleaned it up, so it is loaded again.
local function getTexture(worldContext, path)
    local cached = textures[path]
    if cached and cached.version == stateVersion and cached.inUse and isValid(cached.tex) then return cached.tex end
    local lib = StaticFindObject("/Script/Engine.Default__KismetRenderingLibrary")
    if not isValid(lib) then return nil end
    local ok, t = pcall(function() return lib:ImportFileAsTexture2D(worldContext, path) end)
    if ok and isValid(t) then
        textures[path] = { tex = t, version = stateVersion, inUse = false }
        log("loaded colour image " .. path)
        return t
    end
    warnOnce("tex" .. path, "could not load colour image " .. path)
    return nil
end

local function copyColour(v)
    local ok, c = pcall(function() return { R = v.R, G = v.G, B = v.B, A = v.A } end)
    return ok and c or nil
end

-- Remember a parameter's value the first time we touch it, so we can put it back.
local function remember(mid, key, kind, param)
    originals[key] = originals[key] or {}
    local store = originals[key]
    if store[param] ~= nil then return end
    local f = FName(param)
    local ok, v
    if kind == "colour" then ok, v = pcall(function() return copyColour(mid:K2_GetVectorParameterValue(f)) end)
    elseif kind == "number" then ok, v = pcall(function() return mid:K2_GetScalarParameterValue(f) end)
    else ok, v = pcall(function() return mid:K2_GetTextureParameterValue(f) end) end
    if ok and v ~= nil then store[param] = v else store[param] = false end
end

local function setParam(mid, kind, param, value)
    local f = FName(param)
    local ok, err
    if kind == "colour" then ok, err = pcall(function() mid:SetVectorParameterValue(f, value) end)
    elseif kind == "number" then ok, err = pcall(function() mid:SetScalarParameterValue(f, value) end)
    else ok, err = pcall(function() mid:SetTextureParameterValue(f, value) end) end
    if not ok then warnOnce("set" .. param, "could not set " .. param .. ": " .. tostring(err)) end
end

-- One parameter: use the skin's value, or put the original back.
-- Values this mod has set, per material, so they can be put back if the game resets them
-- (the game resets some Wraith settings, for example when leaving photo mode).
local enforced = {}   -- material address -> { mid = material, list = { [param] = { kind, value } } }
local function applyParam(mid, key, kind, param, value)
    if value ~= nil then
        remember(mid, key, kind, param)
        setParam(mid, kind, param, value)
        enforced[key] = enforced[key] or { mid = mid, list = {} }
        enforced[key].list[param] = { kind = kind, value = value }
    else
        if enforced[key] then enforced[key].list[param] = nil end
        local store = originals[key]
        local orig = store and store[param]
        if orig then setParam(mid, kind, param, orig) end
    end
end

-- targets: a set of effect targets this material slot takes, e.g. { both = true, body = true }
local function applyTarget(comp, slot, targets, skin, colourTex, actor)
    if type(targets) == "string" then targets = { [targets] = true } end
    local mid = getMID(comp, slot)
    if not mid then return end
    local key = addr(mid)
    if not key or applied[key] == stateVersion then return end
    enforced[key] = { mid = mid, list = {} }
    if targets.both then
        local tex = colourTex and colourTex() or nil   -- loaded only when a material actually needs it
        applyParam(mid, key, "texture", "ColorGradient", tex)
        if tex and skin.colours and textures[skin.colours] then textures[skin.colours].inUse = true end
    end
    for _, e in ipairs(EFFECTS) do
        if targets[e.target] then
            local v = skin.effects[e.key]
            if e.kind == "image" then
                local tex = nil
                if v and v.image then
                    tex = getTexture(actor, v.image)
                    if tex and textures[v.image] then textures[v.image].inUse = true end
                end
                applyParam(mid, key, "texture", e.param, tex)
            else
                applyParam(mid, key, e.kind, e.param, v)
            end
        end
    end
    applied[key] = stateVersion
end

local function hoverswordOf(actor)
    local cac = S(function() return actor.ChildActor_Hoversword end)
    local sword = cac and S(function() return cac.ChildActor end)
    if isValid(sword) then return sword end
    return nil
end

local function applyTo(actor)
    local skin = skins[current]
    local colourTex = nil
    if skin.colours then colourTex = function() return getTexture(actor, skin.colours) end end
    local rig = actor.Wraith_Rig
    if isValid(rig) then
        applyTarget(rig, 0, { both = true, body = true }, skin, colourTex, actor)
        applyTarget(rig, 1, { both = true, jacket = true }, skin, colourTex, actor)
        applyTarget(rig, 2, "eyes", skin, colourTex, actor)
        applyTarget(rig, 3, "lines", skin, colourTex, actor)
    end
    local flame = actor.HeadFlameMesh
    if isValid(flame) then applyTarget(flame, 0, "flame", skin, colourTex, actor) end
    local sword = hoverswordOf(actor)
    if sword then
        local mesh = S(function() return sword.Hoversword_Mesh end)
        if isValid(mesh) then
            local n = S(function() return mesh:GetNumMaterials() end) or 1
            for i = 0, n - 1 do applyTarget(mesh, i, "sword", skin, colourTex, actor) end
        else warnOnce("nosword", "hoversword mesh not found") end
        local jets = S(function() return sword.BoosterCard end)
        if isValid(jets) then applyTarget(jets, 0, "jets", skin, colourTex, actor) end
    end
end

-- Every 250 ms: if the game has changed a value this skin sets, set it again.
local resetLogged = {}
local function differs(mid, kind, param, want)
    local f = FName(param)
    if kind == "number" then
        local cur = S(function() return mid:K2_GetScalarParameterValue(f) end)
        return cur ~= nil and math.abs(cur - want) > 0.001
    elseif kind == "colour" then
        local cur = S(function() local v = mid:K2_GetVectorParameterValue(f) return { v.R, v.G, v.B } end)
        return cur ~= nil and (math.abs(cur[1] - want.R) + math.abs(cur[2] - want.G) + math.abs(cur[3] - want.B)) > 0.003
    else
        local cur = S(function() return mid:K2_GetTextureParameterValue(f) end)
        return isValid(want) and addr(cur) ~= addr(want)
    end
end
local function enforce()
    for key, rec in pairs(enforced) do
        if not isValid(rec.mid) then enforced[key] = nil
        else
            for param, e in pairs(rec.list) do
                if differs(rec.mid, e.kind, param, e.value) then
                    setParam(rec.mid, e.kind, param, e.value)
                    resetLogged[param] = (resetLogged[param] or 0) + 1
                    local n = resetLogged[param]
                    if n == 1 or n == 10 or n == 100 or n % 1000 == 0 then
                        log("the game changed " .. param .. ", set it again (" .. n .. " times so far)")
                    end
                end
            end
        end
    end
end
LoopInGameThreadWithDelay(250, function() pcall(enforce) return false end)

local announced = false
local function tick()
    local ok, err = pcall(function()
        local wraiths = FindAllOf(WRAITH_CLASS)
        if not wraiths then return end
        local any = false
        for _, w in ipairs(wraiths) do
            if isValid(w) and isValid(w.Wraith_Rig) then applyTo(w) any = true end
        end
        if any and not announced then
            announced = true
            showMessage(skinLabel() .. "  -  " .. settings.nextskinkey .. " to change")
        end
    end)
    if not ok then warnOnce("tick" .. tostring(err), "error: " .. tostring(err)) end
end

local function changeSkin(step, rescan)
    local id = skins[current] and skins[current].id or ""
    if rescan then
        textures = {}
        scanSkins()
        current = 1
        for i, s in ipairs(skins) do if s.id == id then current = i break end end
    end
    current = ((current - 1 + step) % #skins) + 1
    stateVersion = stateVersion + 1
    saveSelection()
    tick()
    showMessage(skinLabel())
end

---------------------------------------------------------------- start
scanSkins()
loadSelection()
log("starting with: " .. skins[current].name)

LoopInGameThreadWithDelay(CHECK_EVERY_MS, tick)

local function bindKey(name, fn)
    local k = Key[name and name:upper() or ""]
    if not k then log("unknown key '" .. tostring(name) .. "' in settings.txt") return end
    RegisterKeyBind(k, function() ExecuteInGameThread(fn) end)
end
bindKey(settings.nextskinkey, function() changeSkin(1, true) end)
bindKey(settings.previousskinkey, function() changeSkin(-1, true) end)
bindKey(settings.reloadkey, function() changeSkin(0, true) end)

log("version " .. VERSION .. " loaded. " .. settings.nextskinkey .. " next skin, " .. settings.previousskinkey ..
    " previous skin, " .. settings.reloadkey .. " reload skins")
