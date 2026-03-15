--[[
╔══════════════════════════════════════════╗
║        Vape External  v5.1               ║
║   ПР. SHIFT  =  скрыть / показать        ║
╚══════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════
--  БЕЗОПАСНЫЙ ЗАПУСК
-- ═══════════════════════════════════════
local function safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[VapeExt] "..tostring(err)) end
end

local function safeGet(fn)
    local ok, v = pcall(fn)
    return ok and v or nil
end

-- ═══════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════
local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local RS       = game:GetService("RunService")
local TS       = game:GetService("TweenService")
local lp       = Players.LocalPlayer
local cam      = workspace.CurrentCamera

if not lp.Character then lp.CharacterAdded:Wait() end

-- ═══════════════════════════════════════
--  FEATURE DETECTION
-- ═══════════════════════════════════════
local HAS_DRAWING = (typeof(Drawing) == "table" or type(Drawing) == "table")
local HAS_VIM     = safeGet(function() return game:GetService("VirtualInputManager") end) ~= nil
local VIM         = HAS_VIM and safeGet(function() return game:GetService("VirtualInputManager") end)

-- ═══════════════════════════════════════
--  THEMES
-- ═══════════════════════════════════════
local THEMES = {
    { name="Тёмная",  bg=Color3.fromRGB(11,11,16),  nav=Color3.fromRGB(16,16,24),
      card=Color3.fromRGB(22,22,34), hi=Color3.fromRGB(28,28,44),
      accent=Color3.fromRGB(80,152,255), text=Color3.fromRGB(224,230,246),
      sub=Color3.fromRGB(82,88,114),  br=Color3.fromRGB(30,30,52),
      anim="none", snow=false },
    { name="Сумерки", bg=Color3.fromRGB(9,7,18),    nav=Color3.fromRGB(13,10,26),
      card=Color3.fromRGB(19,15,34),  hi=Color3.fromRGB(26,20,46),
      accent=Color3.fromRGB(148,80,255), text=Color3.fromRGB(215,210,242),
      sub=Color3.fromRGB(96,78,134),  br=Color3.fromRGB(36,26,62),
      anim="pulse", snow=false },
    { name="Уголь",   bg=Color3.fromRGB(12,12,12),  nav=Color3.fromRGB(17,17,17),
      card=Color3.fromRGB(24,24,24),  hi=Color3.fromRGB(30,30,30),
      accent=Color3.fromRGB(255,58,58), text=Color3.fromRGB(236,236,236),
      sub=Color3.fromRGB(108,108,108),br=Color3.fromRGB(40,40,40),
      anim="ember", snow=false },
    { name="Рассвет", bg=Color3.fromRGB(8,14,22),   nav=Color3.fromRGB(10,20,34),
      card=Color3.fromRGB(14,27,44),  hi=Color3.fromRGB(18,34,58),
      accent=Color3.fromRGB(0,198,168), text=Color3.fromRGB(194,225,236),
      sub=Color3.fromRGB(62,114,140), br=Color3.fromRGB(18,38,64),
      anim="drift", snow=false },
    { name="❄ Снег",  bg=Color3.fromRGB(16,22,34),  nav=Color3.fromRGB(22,30,46),
      card=Color3.fromRGB(28,38,56),  hi=Color3.fromRGB(34,46,68),
      accent=Color3.fromRGB(155,200,255), text=Color3.fromRGB(228,238,255),
      sub=Color3.fromRGB(108,130,168),br=Color3.fromRGB(42,54,78),
      anim="snow", snow=true },
}
local TI = 1
local function TH() return THEMES[TI] end

-- ═══════════════════════════════════════
--  STATE
-- ═══════════════════════════════════════
local S = {
    fly=false, flySpeed=60,
    noclip=false,
    speed=false, speedVal=24,
    infJump=false,
    jumpPow=false, jumpVal=50,
    espOn=false, espBox=true, espName=true,
    espHP=true,  espLines=false, espDist=false,
    espCorner=0, espColor=Color3.fromRGB(80,152,255),
    espCI=1,     espLineFrom="bottom",
    aimOn=false, aimFOV=120, aimSmooth=0.18,
    aimPart="Head", aimMode="nearest",
    aimPred=false, aimPredVal=0.12,
    aimTeam=false, aimVisible=false,
    aimFOVCircle=true, aimKey="rmb",
    aclick=false, aclickCps=10, aclickBtn=0,
    farmOn=false, farmPtA=nil, farmPtB=nil, farmDelay=1,
    antiAfk=false, noFog=false,
    tpClick=false,
    oldFarmOn=false, oldFarmTarget="players", oldFarmDelay=0.5,
    _oldFarmStatus=nil, _oldFarmDots=nil,
}

local ESP_COLORS = {
    Color3.fromRGB(80,152,255),  Color3.fromRGB(255,60,60),
    Color3.fromRGB(45,215,95),   Color3.fromRGB(255,215,50),
    Color3.fromRGB(255,255,255), Color3.fromRGB(0,208,182),
    Color3.fromRGB(255,120,40),  Color3.fromRGB(210,75,210),
}

-- ═══════════════════════════════════════
--  METRICS
-- ═══════════════════════════════════════
local fpsVal, pingVal = 60, 0
do
    local fc, lt = 0, tick()
    RS.Heartbeat:Connect(function()
        fc += 1
        local n = tick()
        if n - lt >= 0.5 then
            fpsVal = math.floor(fc / (n - lt))
            fc, lt = 0, n
        end
    end)
    -- Ping via Stats (safe)
    task.spawn(function()
        while true do
            task.wait(2)
            safe(function()
                local st = game:GetService("Stats")
                pingVal = math.floor(st.Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
        end
    end)
end

-- ═══════════════════════════════════════
--  HELPERS
-- ═══════════════════════════════════════
local function tw(o, p, t, s, d)
    if not o or not o.Parent then return end
    pcall(function()
        TS:Create(o, TweenInfo.new(
            t or 0.2,
            s or Enum.EasingStyle.Quart,
            d or Enum.EasingDirection.Out
        ), p):Play()
    end)
end

local function getChar()  return safeGet(function() return lp.Character end) end
local function getHRP()   local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()   local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end

-- ═══════════════════════════════════════
--  CLEANUP OLD GUI
-- ═══════════════════════════════════════
safe(function()
    local old = lp.PlayerGui:FindFirstChild("VapeExt")
    if old then old:Destroy() end
end)
task.wait(0.05)

-- ═══════════════════════════════════════
--  SCREEN GUI
-- ═══════════════════════════════════════
local SGui = Instance.new("ScreenGui")
SGui.Name = "VapeExt"
SGui.ResetOnSpawn = false
SGui.DisplayOrder = 999
SGui.IgnoreGuiInset = true
SGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SGui.Parent = lp.PlayerGui

-- ═══════════════════════════════════════
--  MAIN WINDOW  490 × 490
-- ═══════════════════════════════════════
local Win = Instance.new("Frame", SGui)
Win.Name = "Win"
Win.Size = UDim2.new(0, 490, 0, 490)
Win.Position = UDim2.new(0.5, -245, 2, 0)   -- off-screen at start
Win.BackgroundColor3 = TH().bg
Win.BorderSizePixel = 0
Win.Active = true
Win.Draggable = true
Win.ClipsDescendants = false
Instance.new("UICorner", Win).CornerRadius = UDim.new(0, 12)
local WStroke = Instance.new("UIStroke", Win)
WStroke.Color = TH().br; WStroke.Thickness = 1

-- Shadow
local Shad = Instance.new("Frame", Win)
Shad.Size = UDim2.new(1, 28, 1, 28)
Shad.Position = UDim2.new(0, -14, 0, 10)
Shad.BackgroundColor3 = Color3.new(0, 0, 0)
Shad.BackgroundTransparency = 0.72
Shad.BorderSizePixel = 0
Shad.ZIndex = 0
Instance.new("UICorner", Shad).CornerRadius = UDim.new(0, 20)

-- ═══════════════════════════════════════
--  SNOW LAYER  — красивые снежинки
-- ═══════════════════════════════════════
local SnowLayer = Instance.new("Frame", Win)
SnowLayer.Size = UDim2.new(1, 0, 1, 0)
SnowLayer.BackgroundTransparency = 1
SnowLayer.BorderSizePixel = 0
SnowLayer.ZIndex = 6
SnowLayer.ClipsDescendants = true
SnowLayer.Visible = false

-- Символы снежинок разного вида
local FLAKE_CHARS = {"❄","❅","❆","✦","✧","·","•","❋","✼"}
-- Три слоя: крупные, средние, мелкие — для эффекта глубины
local SNOW_LAYERS = {
    { count=10, minSz=16, maxSz=22, minSpd=8,  maxSpd=14, alpha=0.12, blur=0  }, -- дальний (крупный символ мало виден)
    { count=14, minSz=11, maxSz=16, minSpd=14, maxSpd=22, alpha=0.55, blur=0  }, -- средний
    { count=10, minSz=7,  maxSz=10, minSpd=22, maxSpd=36, alpha=0.88, blur=0  }, -- ближний (быстрый, яркий)
}

local snowflakes = {}
for _, layer in ipairs(SNOW_LAYERS) do
    for _ = 1, layer.count do
        local sz = math.random(layer.minSz, layer.maxSz)
        local sf = Instance.new("TextLabel", SnowLayer)
        sf.Size               = UDim2.new(0, sz, 0, sz)
        sf.BackgroundTransparency = 1
        sf.TextColor3         = Color3.new(1, 1, 1)
        sf.TextTransparency   = 1 - layer.alpha
        sf.Text               = FLAKE_CHARS[math.random(1, #FLAKE_CHARS)]
        sf.TextSize           = sz
        sf.Font               = Enum.Font.Gotham
        sf.TextXAlignment     = Enum.TextXAlignment.Center
        sf.TextYAlignment     = Enum.TextYAlignment.Center
        sf.BorderSizePixel    = 0
        sf.ZIndex             = 7

        table.insert(snowflakes, {
            f       = sf,
            x       = math.random(),
            y       = math.random() * -0.15 - 0.05,
            speed   = math.random(layer.minSpd, layer.maxSpd) / 1000,
            drift   = math.random(-8, 8) / 14000,
            rot     = math.random(-3, 3) / 10,    -- вращение (визуальная смена символа)
            rotAcc  = 0,
            rotTimer= 0,
            nextChar= math.random(180, 400),       -- менять символ каждые ~N кадров
            frame   = 0,
            wobble  = math.random() * math.pi * 2, -- синусоидальный дрейф
            wobbleAmp = math.random(1, 5) / 18000,
        })
    end
end

RS.Heartbeat:Connect(function()
    if not TH().snow then return end
    for _, s in ipairs(snowflakes) do
        s.frame = s.frame + 1
        -- синусоидальный боковой дрейф (нежное покачивание)
        s.wobble = s.wobble + 0.022
        local wobX = math.sin(s.wobble) * s.wobbleAmp
        s.y = s.y + s.speed
        s.x = s.x + s.drift + wobX
        -- смена символа для эффекта вращения
        if s.frame >= s.nextChar then
            s.frame = 0
            s.nextChar = math.random(120, 320)
            if s.f and s.f.Parent then
                s.f.Text = FLAKE_CHARS[math.random(1, #FLAKE_CHARS)]
            end
        end
        -- сброс позиции
        if s.y > 1.04 then
            s.y = -0.04
            s.x = math.random()
            s.wobble = math.random() * math.pi * 2
        end
        if s.x < -0.02 then s.x = 1.02 elseif s.x > 1.02 then s.x = -0.02 end
        if s.f and s.f.Parent then
            s.f.Position = UDim2.new(s.x, 0, s.y, 0)
        end
    end
end)

-- ═══════════════════════════════════════
--  HEADER  h = 40
-- ═══════════════════════════════════════
local Hdr = Instance.new("Frame", Win)
Hdr.Size = UDim2.new(1, 0, 0, 40)
Hdr.BackgroundColor3 = TH().nav
Hdr.BorderSizePixel = 0; Hdr.ZIndex = 3
Instance.new("UICorner", Hdr).CornerRadius = UDim.new(0, 12)
local HFix = Instance.new("Frame", Hdr)
HFix.Size = UDim2.new(1, 0, 0, 12)
HFix.Position = UDim2.new(0, 0, 1, -12)
HFix.BackgroundColor3 = TH().nav; HFix.BorderSizePixel = 0; HFix.ZIndex = 3

local GDot = Instance.new("Frame", Hdr)
GDot.Size = UDim2.new(0, 7, 0, 7)
GDot.Position = UDim2.new(0, 13, 0.5, -3.5)
GDot.BackgroundColor3 = Color3.fromRGB(46, 215, 90)
GDot.BorderSizePixel = 0; GDot.ZIndex = 4
Instance.new("UICorner", GDot).CornerRadius = UDim.new(1, 0)

local TitleL = Instance.new("TextLabel", Hdr)
TitleL.Size = UDim2.new(0, 140, 1, 0)
TitleL.Position = UDim2.new(0, 25, 0, 0)
TitleL.BackgroundTransparency = 1
TitleL.Text = "Vape External"
TitleL.TextColor3 = TH().text; TitleL.TextSize = 13
TitleL.Font = Enum.Font.GothamBold
TitleL.TextXAlignment = Enum.TextXAlignment.Left; TitleL.ZIndex = 4

local FpsL = Instance.new("TextLabel", Hdr)
FpsL.Size = UDim2.new(0, 66, 1, 0); FpsL.Position = UDim2.new(0, 168, 0, 0)
FpsL.BackgroundTransparency = 1; FpsL.TextSize = 10
FpsL.Font = Enum.Font.GothamBold; FpsL.TextXAlignment = Enum.TextXAlignment.Left; FpsL.ZIndex = 4

local PingL = Instance.new("TextLabel", Hdr)
PingL.Size = UDim2.new(0, 84, 1, 0); PingL.Position = UDim2.new(0, 236, 0, 0)
PingL.BackgroundTransparency = 1; PingL.TextSize = 10
PingL.Font = Enum.Font.GothamBold; PingL.TextXAlignment = Enum.TextXAlignment.Left; PingL.ZIndex = 4

RS.Heartbeat:Connect(function()
    FpsL.Text = "FPS: " .. fpsVal
    FpsL.TextColor3 = fpsVal >= 50 and Color3.fromRGB(46, 215, 90)
        or fpsVal >= 30 and Color3.fromRGB(255, 215, 50)
        or Color3.fromRGB(255, 65, 65)
    PingL.Text = "PING: " .. pingVal .. "ms"
    PingL.TextColor3 = pingVal <= 80 and Color3.fromRGB(46, 215, 90)
        or pingVal <= 160 and Color3.fromRGB(255, 215, 50)
        or Color3.fromRGB(255, 65, 65)
end)

local CloseBtn = Instance.new("TextButton", Hdr)
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -28, 0.5, -11)
CloseBtn.BackgroundColor3 = Color3.fromRGB(58, 20, 20)
CloseBtn.Text = "✕"; CloseBtn.TextColor3 = Color3.fromRGB(200, 65, 65)
CloseBtn.TextSize = 10; CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0; CloseBtn.ZIndex = 10
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

-- ═══════════════════════════════════════
--  TAB BAR  h = 32
-- ═══════════════════════════════════════
local TabBar = Instance.new("Frame", Win)
TabBar.Size = UDim2.new(1, -16, 0, 32)
TabBar.Position = UDim2.new(0, 8, 0, 44)
TabBar.BackgroundColor3 = TH().nav
TabBar.BorderSizePixel = 0; TabBar.ZIndex = 3
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 9)
local TabLayout = Instance.new("UIListLayout", TabBar)
TabLayout.FillDirection = Enum.FillDirection.Horizontal

-- ═══════════════════════════════════════
--  CONTENT AREA
-- ═══════════════════════════════════════
local ContentArea = Instance.new("Frame", Win)
ContentArea.Size = UDim2.new(1, -16, 1, -86)
ContentArea.Position = UDim2.new(0, 8, 0, 80)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants = true

-- ═══════════════════════════════════════
--  COMPONENT HELPERS
-- ═══════════════════════════════════════
local _ord = 0
local function nO() _ord = _ord + 1; return _ord end

local function makePage()
    local sf = Instance.new("ScrollingFrame", ContentArea)
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.ScrollBarThickness = 2
    sf.ScrollBarImageColor3 = TH().br
    sf.BackgroundTransparency = 1
    sf.Visible = false; sf.BorderSizePixel = 0
    sf.ScrollingDirection = Enum.ScrollingDirection.Y
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local pad = Instance.new("UIPadding", sf)
    pad.PaddingTop = UDim.new(0, 2); pad.PaddingRight = UDim.new(0, 5); pad.PaddingBottom = UDim.new(0, 12)
    local lay = Instance.new("UIListLayout", sf)
    lay.Padding = UDim.new(0, 3); lay.SortOrder = Enum.SortOrder.LayoutOrder
    return sf
end

local function makePlainPage()
    local f = Instance.new("Frame", ContentArea)
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1; f.Visible = false; f.BorderSizePixel = 0
    return f
end

-- Section label
local function secLbl(page, txt)
    local f = Instance.new("Frame", page)
    f.Size = UDim2.new(1, 0, 0, 18); f.BackgroundTransparency = 1
    f.BorderSizePixel = 0; f.LayoutOrder = nO()
    local line = Instance.new("Frame", f)
    line.Size = UDim2.new(1, 0, 0, 1); line.Position = UDim2.new(0, 0, 1, -1)
    line.BackgroundColor3 = TH().br; line.BorderSizePixel = 0
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, -8, 1, -2); l.Position = UDim2.new(0, 4, 0, 0)
    l.BackgroundTransparency = 1; l.Text = txt
    l.TextColor3 = TH().sub; l.TextSize = 8
    l.Font = Enum.Font.GothamBold; l.TextXAlignment = Enum.TextXAlignment.Left
end

-- Base card
local function mkCard(page, h)
    local f = Instance.new("Frame", page)
    f.Size = UDim2.new(1, -2, 0, h); f.BackgroundColor3 = TH().card
    f.BorderSizePixel = 0; f.LayoutOrder = nO()
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local st = Instance.new("UIStroke", f); st.Color = TH().br; st.Thickness = 1
    return f, st
end

-- Icon background helper
local function mkIco(parent, icon)
    local bg = Instance.new("Frame", parent)
    bg.Size = UDim2.new(0, 24, 0, 24); bg.Position = UDim2.new(0, 6, 0.5, -12)
    bg.BackgroundColor3 = TH().hi; bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 7)
    local ico = Instance.new("TextLabel", bg)
    ico.Size = UDim2.new(1, 0, 1, 0); ico.BackgroundTransparency = 1
    ico.Text = icon; ico.TextSize = 12; ico.Font = Enum.Font.Gotham
    ico.TextColor3 = TH().sub
    return bg, ico
end

-- ──────────────────────────────────────
--  TOGGLE
-- ──────────────────────────────────────
local function Toggle(page, icon, label, init, cb)
    local c = mkCard(page, 34)
    local ibg, ico = mkIco(c, icon)
    local lbl = Instance.new("TextLabel", c)
    lbl.Size = UDim2.new(1, -68, 1, 0); lbl.Position = UDim2.new(0, 36, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = label
    lbl.TextColor3 = TH().text; lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local pill = Instance.new("Frame", c)
    pill.Size = UDim2.new(0, 32, 0, 17); pill.Position = UDim2.new(1, -38, 0.5, -8.5)
    pill.BorderSizePixel = 0; Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
    local dot = Instance.new("Frame", pill)
    dot.Size = UDim2.new(0, 11, 0, 11); dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local val = init or false
    local function refresh()
        if val then
            tw(pill,{BackgroundColor3=TH().accent},.16)
            tw(dot,{Position=UDim2.new(0,17,0.5,-5.5),BackgroundColor3=Color3.new(1,1,1)},.16)
            tw(ibg,{BackgroundColor3=TH().accent},.16)
            tw(ico,{TextColor3=Color3.new(1,1,1)},.16)
        else
            tw(pill,{BackgroundColor3=TH().br},.16)
            tw(dot,{Position=UDim2.new(0,3,0.5,-5.5),BackgroundColor3=TH().sub},.16)
            tw(ibg,{BackgroundColor3=TH().hi},.16)
            tw(ico,{TextColor3=TH().sub},.16)
        end
    end
    refresh()
    local btn = Instance.new("TextButton", c)
    btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1; btn.Text = ""; btn.ZIndex = 2
    btn.MouseButton1Click:Connect(function()
        val = not val; refresh()
        if cb then safe(cb, val) end
    end)
end

-- ──────────────────────────────────────
--  SLIDER
-- ──────────────────────────────────────
local _drg = nil
UIS.InputChanged:Connect(function(i)
    if not _drg or i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    local d = _drg
    if not d.tr or not d.tr.Parent then _drg = nil; return end
    local p = math.clamp((i.Position.X - d.tr.AbsolutePosition.X) / math.max(d.tr.AbsoluteSize.X, 1), 0, 1)
    local v = math.floor(d.mn + p * (d.mx - d.mn))
    d.fl.Size = UDim2.new(p, 0, 1, 0)
    d.th.Position = UDim2.new(p, -5, 0.5, -5)
    d.vl.Text = tostring(v)
    if d.cb then safe(d.cb, v) end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then _drg = nil end
end)

local function Slider(page, label, init, mn, mx, cb)
    local c = mkCard(page, 40)
    local ll = Instance.new("TextLabel", c)
    ll.Size = UDim2.new(0.62, 0, 0, 18); ll.Position = UDim2.new(0, 10, 0, 4)
    ll.BackgroundTransparency = 1; ll.Text = label; ll.TextColor3 = TH().text
    ll.TextSize = 11; ll.Font = Enum.Font.GothamSemibold; ll.TextXAlignment = Enum.TextXAlignment.Left
    local vl = Instance.new("TextLabel", c)
    vl.Size = UDim2.new(0.36, 0, 0, 18); vl.Position = UDim2.new(0.64, 0, 0, 4)
    vl.BackgroundTransparency = 1; vl.Text = tostring(init); vl.TextColor3 = TH().accent
    vl.TextSize = 11; vl.Font = Enum.Font.GothamBold; vl.TextXAlignment = Enum.TextXAlignment.Right
    local tr = Instance.new("Frame", c)
    tr.Size = UDim2.new(1, -18, 0, 4); tr.Position = UDim2.new(0, 9, 0, 30)
    tr.BackgroundColor3 = TH().hi; tr.BorderSizePixel = 0
    Instance.new("UICorner", tr).CornerRadius = UDim.new(1, 0)
    local pct = math.clamp((init - mn) / (mx - mn), 0, 1)
    local fl = Instance.new("Frame", tr)
    fl.Size = UDim2.new(pct, 0, 1, 0); fl.BackgroundColor3 = TH().accent; fl.BorderSizePixel = 0
    Instance.new("UICorner", fl).CornerRadius = UDim.new(1, 0)
    local th = Instance.new("Frame", tr)
    th.Size = UDim2.new(0, 10, 0, 10); th.Position = UDim2.new(pct, -5, 0.5, -5)
    th.BackgroundColor3 = Color3.new(1, 1, 1); th.BorderSizePixel = 0; th.ZIndex = 3
    Instance.new("UICorner", th).CornerRadius = UDim.new(1, 0)
    local hit = Instance.new("TextButton", tr)
    hit.Size = UDim2.new(1, 0, 0, 24); hit.Position = UDim2.new(0, 0, 0.5, -12)
    hit.BackgroundTransparency = 1; hit.Text = ""; hit.ZIndex = 4
    hit.MouseButton1Down:Connect(function()
        _drg = {tr=tr,fl=fl,th=th,vl=vl,mn=mn,mx=mx,cb=cb}
    end)
end

-- ──────────────────────────────────────
--  CYCLER
-- ──────────────────────────────────────
local function Cycler(page, icon, label, opts, initI, cb)
    local c = mkCard(page, 34); local idx = initI or 1
    mkIco(c, icon)
    local ll = Instance.new("TextLabel", c)
    ll.Size = UDim2.new(1, -88, 1, 0); ll.Position = UDim2.new(0, 36, 0, 0)
    ll.BackgroundTransparency = 1; ll.Text = label; ll.TextColor3 = TH().text
    ll.TextSize = 11; ll.Font = Enum.Font.GothamSemibold; ll.TextXAlignment = Enum.TextXAlignment.Left
    local vl = Instance.new("TextLabel", c)
    vl.Size = UDim2.new(0, 62, 1, 0); vl.Position = UDim2.new(1, -66, 0, 0)
    vl.BackgroundTransparency = 1; vl.Text = opts[idx]; vl.TextColor3 = TH().accent
    vl.TextSize = 10; vl.Font = Enum.Font.GothamBold; vl.TextXAlignment = Enum.TextXAlignment.Right
    -- arrows
    local arrowR = Instance.new("TextLabel", c)
    arrowR.Size = UDim2.new(0, 12, 1, 0); arrowR.Position = UDim2.new(1, -14, 0, 0)
    arrowR.BackgroundTransparency = 1; arrowR.Text = "›"; arrowR.TextColor3 = TH().sub
    arrowR.TextSize = 14; arrowR.Font = Enum.Font.GothamBold
    local btn = Instance.new("TextButton", c)
    btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1; btn.Text = ""; btn.ZIndex = 2
    btn.MouseButton1Click:Connect(function()
        idx = idx % #opts + 1; vl.Text = opts[idx]
        if cb then safe(cb, idx, opts[idx]) end
    end)
end

-- ──────────────────────────────────────
--  ACTION BUTTON
-- ──────────────────────────────────────
local function ActionBtn(page, icon, label, cb)
    local c = mkCard(page, 34)
    mkIco(c, icon)
    local ll = Instance.new("TextLabel", c)
    ll.Size = UDim2.new(1, -88, 1, 0); ll.Position = UDim2.new(0, 36, 0, 0)
    ll.BackgroundTransparency = 1; ll.Text = label; ll.TextColor3 = TH().text
    ll.TextSize = 11; ll.Font = Enum.Font.GothamSemibold; ll.TextXAlignment = Enum.TextXAlignment.Left
    local sl = Instance.new("TextLabel", c)
    sl.Size = UDim2.new(0, 66, 1, 0); sl.Position = UDim2.new(1, -70, 0, 0)
    sl.BackgroundTransparency = 1; sl.Text = "нажми →"; sl.TextColor3 = TH().sub
    sl.TextSize = 9; sl.Font = Enum.Font.Gotham; sl.TextXAlignment = Enum.TextXAlignment.Right
    local btn = Instance.new("TextButton", c)
    btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1; btn.Text = ""; btn.ZIndex = 2
    btn.MouseButton1Click:Connect(function() if cb then safe(cb, sl) end end)
    btn.MouseEnter:Connect(function() tw(c, {BackgroundColor3=TH().hi}, .1) end)
    btn.MouseLeave:Connect(function() tw(c, {BackgroundColor3=TH().card}, .1) end)
    return sl
end

-- ═══════════════════════════════════════════════════
--  PAGE 1 — MOVE
-- ═══════════════════════════════════════════════════
local MovePg = makePage()
secLbl(MovePg, "ДВИЖЕНИЕ")
Toggle(MovePg, "↑", "Полёт  (W A S D + Space / Shift)", false, function(v) S.fly = v end)
Toggle(MovePg, "◌", "Нет коллизий", false, function(v) S.noclip = v end)
Toggle(MovePg, "→", "Скорость", false, function(v)
    S.speed = v
    local h = getHum(); if h then h.WalkSpeed = v and S.speedVal or 16 end
end)
Slider(MovePg, "Значение скорости", 24, 2, 150, function(v)
    S.speedVal = v; if S.speed then local h = getHum(); if h then h.WalkSpeed = v end end
end)
Toggle(MovePg, "⇑", "Бесконечный прыжок", false, function(v) S.infJump = v end)
Toggle(MovePg, "↟", "Сила прыжка", false, function(v)
    S.jumpPow = v
    local h = getHum(); if h then h.JumpPower = v and S.jumpVal or 50 end
end)
Slider(MovePg, "Значение прыжка", 50, 10, 300, function(v)
    S.jumpVal = v; if S.jumpPow then local h = getHum(); if h then h.JumpPower = v end end
end)
secLbl(MovePg, "ТЕЛЕПОРТ")
ActionBtn(MovePg, "⊕", "TP → случайный игрок", function(sl)
    local others = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= lp then table.insert(others, p) end end
    if #others == 0 then sl.Text = "нет игроков"; return end
    local t = others[math.random(1, #others)]
    local th = t.Character and t.Character:FindFirstChild("HumanoidRootPart")
    local hrp = getHRP()
    if th and hrp then hrp.CFrame = th.CFrame + Vector3.new(3, 0, 0); sl.Text = "→ " .. t.DisplayName
    else sl.Text = "ошибка" end
end)
ActionBtn(MovePg, "★", "TP → спаун", function(sl)
    local sp = workspace:FindFirstChildOfClass("SpawnLocation"); local hrp = getHRP()
    if sp and hrp then hrp.CFrame = sp.CFrame + Vector3.new(0, 4, 0); sl.Text = "✓ готово"
    else sl.Text = "нет спауна" end
end)

-- ═══════════════════════════════════════════════════
--  PAGE 2 — VISUAL  (split layout)
-- ═══════════════════════════════════════════════════
local VisPg = makePlainPage()

-- Left scroll
local VisLeft = Instance.new("ScrollingFrame", VisPg)
VisLeft.Size = UDim2.new(0, 234, 1, 0)
VisLeft.CanvasSize = UDim2.new(0, 0, 0, 0)
VisLeft.ScrollBarThickness = 2; VisLeft.ScrollBarImageColor3 = TH().br
VisLeft.BackgroundTransparency = 1; VisLeft.BorderSizePixel = 0
VisLeft.ScrollingDirection = Enum.ScrollingDirection.Y
VisLeft.AutomaticCanvasSize = Enum.AutomaticSize.Y
local vlPad = Instance.new("UIPadding", VisLeft)
vlPad.PaddingTop = UDim.new(0, 2); vlPad.PaddingRight = UDim.new(0, 4); vlPad.PaddingBottom = UDim.new(0, 10)
local vlLay = Instance.new("UIListLayout", VisLeft)
vlLay.Padding = UDim.new(0, 3); vlLay.SortOrder = Enum.SortOrder.LayoutOrder

-- Right preview panel
local VisRight = Instance.new("Frame", VisPg)
VisRight.Size = UDim2.new(1, -240, 1, 0); VisRight.Position = UDim2.new(0, 238, 0, 0)
VisRight.BackgroundColor3 = TH().card; VisRight.BorderSizePixel = 0
Instance.new("UICorner", VisRight).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", VisRight).Color = TH().br

local PrevLbl = Instance.new("TextLabel", VisRight)
PrevLbl.Size = UDim2.new(1, -8, 0, 16); PrevLbl.Position = UDim2.new(0, 8, 0, 4)
PrevLbl.BackgroundTransparency = 1; PrevLbl.Text = "ESP ПРЕВЬЮ"
PrevLbl.TextColor3 = TH().sub; PrevLbl.TextSize = 8
PrevLbl.Font = Enum.Font.GothamBold; PrevLbl.TextXAlignment = Enum.TextXAlignment.Left

local Stage = Instance.new("Frame", VisRight)
Stage.Size = UDim2.new(1, -12, 1, -26); Stage.Position = UDim2.new(0, 6, 0, 21)
Stage.BackgroundColor3 = Color3.fromRGB(5, 7, 12); Stage.BorderSizePixel = 0
Instance.new("UICorner", Stage).CornerRadius = UDim.new(0, 6)

-- Preview characters
local function mkPChar(pct, sc, name)
    local bw, bh = 18 * sc, 30 * sc
    local bx = pct * Stage.AbsoluteSize.X - bw / 2  -- approximate

    -- head
    local head = Instance.new("Frame", Stage)
    head.Size = UDim2.new(0, 8*sc, 0, 8*sc); head.Position = UDim2.new(pct, -4*sc, 0.38, -20*sc)
    head.BackgroundColor3 = Color3.fromRGB(68, 88, 126); head.BorderSizePixel = 0
    Instance.new("UICorner", head).CornerRadius = UDim.new(1, 0)

    -- body
    local body = Instance.new("Frame", Stage)
    body.Size = UDim2.new(0, 10*sc, 0, 15*sc); body.Position = UDim2.new(pct, -5*sc, 0.38, -10*sc)
    body.BackgroundColor3 = Color3.fromRGB(48, 62, 88); body.BorderSizePixel = 0
    Instance.new("UICorner", body).CornerRadius = UDim.new(0, 2)

    -- ESP box
    local box = Instance.new("Frame", Stage)
    box.Size = UDim2.new(0, bw, 0, bh); box.Position = UDim2.new(pct, -bw/2, 0.38, -22*sc)
    box.BackgroundTransparency = 1; box.BorderSizePixel = 0
    local bSt = Instance.new("UIStroke", box); bSt.Thickness = 1.3; bSt.Color = S.espColor
    local bCo = Instance.new("UICorner", box); bCo.CornerRadius = UDim.new(0, 0)

    -- name label
    local nLbl = Instance.new("TextLabel", Stage)
    nLbl.Size = UDim2.new(0, 54, 0, 10); nLbl.Position = UDim2.new(pct, -27, 0.38, -26*sc)
    nLbl.BackgroundTransparency = 1; nLbl.Text = name
    nLbl.TextSize = 8; nLbl.Font = Enum.Font.GothamBold
    nLbl.TextColor3 = S.espColor; nLbl.TextXAlignment = Enum.TextXAlignment.Center

    -- hp label
    local hLbl = Instance.new("TextLabel", Stage)
    hLbl.Size = UDim2.new(0, 40, 0, 9); hLbl.Position = UDim2.new(pct, -20, 0.38, 9*sc)
    hLbl.BackgroundTransparency = 1; hLbl.Text = "100hp"
    hLbl.TextSize = 7; hLbl.Font = Enum.Font.GothamBold
    hLbl.TextColor3 = Color3.fromRGB(80, 220, 80); hLbl.TextXAlignment = Enum.TextXAlignment.Center

    -- tracer
    local tLine = Instance.new("Frame", Stage)
    tLine.Size = UDim2.new(0, 1, 0.42, 0); tLine.Position = UDim2.new(pct, 0, 0.98, 0)
    tLine.BackgroundColor3 = S.espColor; tLine.BorderSizePixel = 0
    tLine.AnchorPoint = Vector2.new(0.5, 1)

    return {box=box, bSt=bSt, bCo=bCo, name=nLbl, hp=hLbl, tLine=tLine}
end

local pv1 = mkPChar(0.34, 1.1, "Player1")
local pv2 = mkPChar(0.70, 0.85, "Player2")

RS.Heartbeat:Connect(function()
    for _, pv in ipairs({pv1, pv2}) do
        pv.bSt.Color   = S.espColor
        pv.bCo.CornerRadius = UDim.new(0, S.espCorner)
        pv.name.TextColor3  = S.espColor;  pv.name.Visible  = S.espName
        pv.hp.Visible        = S.espHP;    pv.box.Visible   = S.espBox
        pv.tLine.BackgroundColor3 = S.espColor; pv.tLine.Visible = S.espLines
    end
end)

-- Build left ESP controls into VisLeft
local vOrd = 0
local function vCard(h)
    vOrd = vOrd + 1
    local f = Instance.new("Frame", VisLeft)
    f.Size = UDim2.new(1, -2, 0, h); f.BackgroundColor3 = TH().card
    f.BorderSizePixel = 0; f.LayoutOrder = vOrd
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", f).Color = TH().br
    return f
end
local function vSecLbl(txt)
    vOrd = vOrd + 1
    local f = Instance.new("Frame", VisLeft)
    f.Size = UDim2.new(1, 0, 0, 18); f.BackgroundTransparency = 1; f.BorderSizePixel = 0; f.LayoutOrder = vOrd
    local line = Instance.new("Frame", f); line.Size = UDim2.new(1, 0, 0, 1); line.Position = UDim2.new(0, 0, 1, -1)
    line.BackgroundColor3 = TH().br; line.BorderSizePixel = 0
    local l = Instance.new("TextLabel", f); l.Size = UDim2.new(1, -8, 1, -2); l.Position = UDim2.new(0, 4, 0, 0)
    l.BackgroundTransparency = 1; l.Text = txt; l.TextColor3 = TH().sub; l.TextSize = 8
    l.Font = Enum.Font.GothamBold; l.TextXAlignment = Enum.TextXAlignment.Left
end
local function vToggle(icon, label, init, cb)
    local c = vCard(34)
    local ibg, ico = mkIco(c, icon)
    local lbl = Instance.new("TextLabel", c)
    lbl.Size = UDim2.new(1, -66, 1, 0); lbl.Position = UDim2.new(0, 36, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = label; lbl.TextColor3 = TH().text
    lbl.TextSize = 11; lbl.Font = Enum.Font.GothamSemibold; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local pill = Instance.new("Frame", c); pill.Size = UDim2.new(0, 32, 0, 17); pill.Position = UDim2.new(1, -36, 0.5, -8.5)
    pill.BorderSizePixel = 0; Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
    local dot = Instance.new("Frame", pill); dot.Size = UDim2.new(0, 11, 0, 11); dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local val = init or false
    local function ref()
        if val then tw(pill,{BackgroundColor3=TH().accent},.16); tw(dot,{Position=UDim2.new(0,17,0.5,-5.5),BackgroundColor3=Color3.new(1,1,1)},.16); tw(ibg,{BackgroundColor3=TH().accent},.16); tw(ico,{TextColor3=Color3.new(1,1,1)},.16)
        else tw(pill,{BackgroundColor3=TH().br},.16); tw(dot,{Position=UDim2.new(0,3,0.5,-5.5),BackgroundColor3=TH().sub},.16); tw(ibg,{BackgroundColor3=TH().hi},.16); tw(ico,{TextColor3=TH().sub},.16) end
    end; ref()
    local btn = Instance.new("TextButton", c); btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.ZIndex=2
    btn.MouseButton1Click:Connect(function() val=not val; ref(); if cb then safe(cb,val) end end)
end

vSecLbl("ВКЛЮЧИТЬ")
vToggle("▣","ESP Вкл",      false,function(v) S.espOn=v end)
vSecLbl("ЭЛЕМЕНТЫ")
vToggle("□","Бокс",          true, function(v) S.espBox=v end)
vToggle("◈","Имена",         true, function(v) S.espName=v end)
vToggle("♡","Здоровье",      true, function(v) S.espHP=v end)
vToggle("╲","Линии",         false,function(v) S.espLines=v end)
vToggle("◎","Дистанция",     false,function(v) S.espDist=v end)
vSecLbl("СТИЛЬ")
-- Corner stepper
do
    local c = vCard(34)
    local ll = Instance.new("TextLabel",c); ll.Size=UDim2.new(1,-90,1,0); ll.Position=UDim2.new(0,10,0,0)
    ll.BackgroundTransparency=1; ll.Text="Закругление"; ll.TextColor3=TH().text; ll.TextSize=11
    ll.Font=Enum.Font.GothamSemibold; ll.TextXAlignment=Enum.TextXAlignment.Left
    local vl=Instance.new("TextLabel",c); vl.Size=UDim2.new(0,20,1,0); vl.Position=UDim2.new(1,-58,0,0)
    vl.BackgroundTransparency=1; vl.Text="0"; vl.TextColor3=TH().accent; vl.TextSize=11; vl.Font=Enum.Font.GothamBold
    for _,d in ipairs({{-36,"−",-2},{-14,"+",2}}) do
        local b=Instance.new("TextButton",c); b.Size=UDim2.new(0,20,0,20); b.Position=UDim2.new(1,d[1],0.5,-10)
        b.BackgroundColor3=TH().hi; b.Text=d[2]; b.TextColor3=TH().text; b.TextSize=13; b.Font=Enum.Font.GothamBold
        b.BorderSizePixel=0; b.ZIndex=2; Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
        b.MouseButton1Click:Connect(function() S.espCorner=math.clamp(S.espCorner+d[3],0,20); vl.Text=tostring(S.espCorner) end)
    end
end
-- Color picker
do
    local c = vCard(46)
    local tl=Instance.new("TextLabel",c); tl.Size=UDim2.new(1,0,0,14); tl.Position=UDim2.new(0,8,0,2)
    tl.BackgroundTransparency=1; tl.Text="ЦВЕТ"; tl.TextColor3=TH().sub; tl.TextSize=8; tl.Font=Enum.Font.GothamBold; tl.TextXAlignment=Enum.TextXAlignment.Left
    local rings={}
    for ci,col in ipairs(ESP_COLORS) do
        local btn=Instance.new("TextButton",c); btn.Size=UDim2.new(0,17,0,17); btn.Position=UDim2.new(0,6+(ci-1)*22,0,22)
        btn.BackgroundColor3=col; btn.Text=""; btn.BorderSizePixel=0; btn.ZIndex=2
        Instance.new("UICorner",btn).CornerRadius=UDim.new(1,0)
        local ring=Instance.new("UIStroke",btn); ring.Color=Color3.new(1,1,1); ring.Thickness=(ci==1) and 1.5 or 0
        rings[ci]=ring
        btn.MouseButton1Click:Connect(function()
            S.espColor=col; S.espCI=ci; for j,r in ipairs(rings) do r.Thickness=(j==ci) and 1.5 or 0 end
        end)
    end
end
-- Line direction cycler (simplified)
do
    local c = vCard(34)
    local ll=Instance.new("TextLabel",c); ll.Size=UDim2.new(1,-80,1,0); ll.Position=UDim2.new(0,10,0,0)
    ll.BackgroundTransparency=1; ll.Text="Линия от"; ll.TextColor3=TH().text; ll.TextSize=11; ll.Font=Enum.Font.GothamSemibold; ll.TextXAlignment=Enum.TextXAlignment.Left
    local vl=Instance.new("TextLabel",c); vl.Size=UDim2.new(0,66,1,0); vl.Position=UDim2.new(1,-68,0,0)
    vl.BackgroundTransparency=1; vl.Text="Низ"; vl.TextColor3=TH().accent; vl.TextSize=10; vl.Font=Enum.Font.GothamBold; vl.TextXAlignment=Enum.TextXAlignment.Right
    local opts={"Низ","Центр"}; local idx=1
    local btn=Instance.new("TextButton",c); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.ZIndex=2
    btn.MouseButton1Click:Connect(function() idx=idx%2+1; vl.Text=opts[idx]; S.espLineFrom=(idx==1) and "bottom" or "center" end)
end

-- ═══════════════════════════════════════════════════
--  PAGE 3 — AIM
-- ═══════════════════════════════════════════════════
local AimPg = makePage()
secLbl(AimPg, "ПРИЦЕЛ")
Toggle(AimPg,"⊙","Аимбот",false,function(v) S.aimOn=v end)
Toggle(AimPg,"◉","FOV-круг",true,function(v) S.aimFOVCircle=v end)
Slider(AimPg,"Радиус FOV",120,20,400,function(v) S.aimFOV=v end)
Slider(AimPg,"Плавность (1=моментально)",18,1,100,function(v) S.aimSmooth=v/100 end)
secLbl(AimPg,"ЦЕЛЬ")
Cycler(AimPg,"◈","Часть тела",{"Голова","Торс"},1,function(i)
    S.aimPart=({"Head","UpperTorso"})[i]
end)
Cycler(AimPg,"⊕","Режим",{"Ближайший","Низкое HP","Видимый"},1,function(i)
    S.aimMode=({"nearest","lowhp","visible"})[i]
end)
Cycler(AimPg,"◐","Клавиша",{"ПКМ","ЛКМ","Всегда"},1,function(i)
    S.aimKey=({"rmb","lmb","always"})[i]
end)
secLbl(AimPg,"ДОПОЛНИТЕЛЬНО")
Toggle(AimPg,"≋","Предсказание движения",false,function(v) S.aimPred=v end)
Slider(AimPg,"Сила предсказания",12,1,50,function(v) S.aimPredVal=v/100 end)
Toggle(AimPg,"⚑","Только видимые",false,function(v) S.aimVisible=v end)
Toggle(AimPg,"♟","Игнорировать команду",false,function(v) S.aimTeam=v end)

-- ═══════════════════════════════════════════════════
--  PAGE 4 — ATK
-- ═══════════════════════════════════════════════════
local AtkPg = makePage()
secLbl(AtkPg,"АВТО КЛИКЕР")
Toggle(AtkPg,"⬤","Авто кликер",false,function(v) S.aclick=v end)
Slider(AtkPg,"CPS (кликов/сек)",10,1,50,function(v) S.aclickCps=v end)
Cycler(AtkPg,"◐","Кнопка",{"ЛКМ","ПКМ"},1,function(i) S.aclickBtn=(i==1) and 0 or 1 end)
secLbl(AtkPg,"АВТО ФАРМ")
-- Point indicators
local ptAL, ptBL
do
    vOrd=0
    local c=mkCard(AtkPg,26)
    ptAL=Instance.new("TextLabel",c); ptAL.Size=UDim2.new(0.5,-4,1,0); ptAL.Position=UDim2.new(0,4,0,0)
    ptAL.BackgroundTransparency=1; ptAL.Text="A: не задана"; ptAL.TextColor3=TH().sub; ptAL.TextSize=9; ptAL.Font=Enum.Font.GothamBold; ptAL.TextXAlignment=Enum.TextXAlignment.Left
    ptBL=Instance.new("TextLabel",c); ptBL.Size=UDim2.new(0.5,-4,1,0); ptBL.Position=UDim2.new(0.5,0,0,0)
    ptBL.BackgroundTransparency=1; ptBL.Text="B: не задана"; ptBL.TextColor3=TH().sub; ptBL.TextSize=9; ptBL.Font=Enum.Font.GothamBold; ptBL.TextXAlignment=Enum.TextXAlignment.Left
end
ActionBtn(AtkPg,"◎","Задать точку A (текущая позиция)",function(sl)
    local hrp=getHRP(); if not hrp then sl.Text="нет персонажа"; return end
    S.farmPtA=hrp.Position
    ptAL.Text="A: "..math.floor(hrp.Position.X)..","..math.floor(hrp.Position.Z)
    ptAL.TextColor3=TH().accent; sl.Text="✓ сохранено"
end)
ActionBtn(AtkPg,"◎","Задать точку B (текущая позиция)",function(sl)
    local hrp=getHRP(); if not hrp then sl.Text="нет персонажа"; return end
    S.farmPtB=hrp.Position
    ptBL.Text="B: "..math.floor(hrp.Position.X)..","..math.floor(hrp.Position.Z)
    ptBL.TextColor3=TH().accent; sl.Text="✓ сохранено"
end)
Toggle(AtkPg,"⟳","Авто фарм A→B→A",false,function(v)
    S.farmOn=v
    if v then
        task.spawn(function()
            while S.farmOn do
                if S.farmPtA then local hrp=getHRP(); if hrp then hrp.CFrame=CFrame.new(S.farmPtA+Vector3.new(0,3,0)) end end
                task.wait(S.farmDelay)
                if not S.farmOn then break end
                if S.farmPtB then local hrp=getHRP(); if hrp then hrp.CFrame=CFrame.new(S.farmPtB+Vector3.new(0,3,0)) end end
                task.wait(S.farmDelay)
            end
        end)
    end
end)
Slider(AtkPg,"Задержка фарма (×0.1 сек)",10,1,50,function(v) S.farmDelay=v*0.1 end)

-- ─── СТАРЫЙ АВТО ФАРМ (loop collect style) ──────────
secLbl(AtkPg,"СТАРЫЙ АВТО ФАРМ")
do
    local c = mkCard(AtkPg, 46)
    local info = Instance.new("TextLabel",c)
    info.Size = UDim2.new(1,-10,0,14); info.Position = UDim2.new(0,6,0,3)
    info.BackgroundTransparency=1; info.Text="Телепортирует к каждому объекту/игроку"
    info.TextColor3=TH().sub; info.TextSize=8; info.Font=Enum.Font.Gotham; info.TextXAlignment=Enum.TextXAlignment.Left
    local statusL = Instance.new("TextLabel",c)
    statusL.Size=UDim2.new(1,-10,0,12); statusL.Position=UDim2.new(0,6,0,18)
    statusL.BackgroundTransparency=1; statusL.Text="Выключен"
    statusL.TextColor3=TH().sub; statusL.TextSize=9; statusL.Font=Enum.Font.GothamBold; statusL.TextXAlignment=Enum.TextXAlignment.Left
    -- progress dots
    local dotsL = Instance.new("TextLabel",c)
    dotsL.Size=UDim2.new(1,-10,0,12); dotsL.Position=UDim2.new(0,6,0,32)
    dotsL.BackgroundTransparency=1; dotsL.Text=""
    dotsL.TextColor3=TH().accent; dotsL.TextSize=9; dotsL.Font=Enum.Font.GothamBold; dotsL.TextXAlignment=Enum.TextXAlignment.Left
    S._oldFarmStatus = statusL
    S._oldFarmDots   = dotsL
end
Cycler(AtkPg,"◈","Цель сбора",{"Игроки","Части (Parts)","Инструменты"},1,function(i)
    S.oldFarmTarget = ({"players","parts","tools"})[i]
end)
Slider(AtkPg,"Задержка старого фарма (×0.1)",5,1,30,function(v) S.oldFarmDelay=v*0.1 end)
Toggle(AtkPg,"⟳","Старый авто фарм (вкл)",false,function(v)
    S.oldFarmOn=v
    if S._oldFarmStatus then
        S._oldFarmStatus.Text  = v and "Работает..." or "Выключен"
        S._oldFarmStatus.TextColor3 = v and TH().accent or TH().sub
    end
    if v then
        task.spawn(function()
            local dotChars = {"·","··","···","····"}
            local di = 0
            while S.oldFarmOn do
                di = di % 4 + 1
                if S._oldFarmDots then S._oldFarmDots.Text = "собираю "..dotChars[di] end
                local hrp = getHRP(); if not hrp then task.wait(0.2); continue end
                -- Collect targets
                local targets = {}
                local mode = S.oldFarmTarget or "players"
                if mode == "players" then
                    for _,plr in ipairs(Players:GetPlayers()) do
                        if plr ~= lp then
                            local th = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                            if th then table.insert(targets, th) end
                        end
                    end
                elseif mode == "parts" then
                    for _,obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("BasePart") and obj.Name:lower():find("coin")
                           or obj:IsA("BasePart") and obj.Name:lower():find("item")
                           or obj:IsA("BasePart") and obj.Name:lower():find("collect")
                           or obj:IsA("BasePart") and obj.Name:lower():find("gem") then
                            table.insert(targets, obj)
                        end
                    end
                elseif mode == "tools" then
                    for _,obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("Tool") then table.insert(targets, obj) end
                    end
                end
                -- TP to each
                for _, t in ipairs(targets) do
                    if not S.oldFarmOn then break end
                    if t and t.Parent then
                        hrp = getHRP()
                        if hrp then
                            hrp.CFrame = CFrame.new(t.Position + Vector3.new(0,3,0))
                        end
                    end
                    task.wait(S.oldFarmDelay or 0.5)
                end
                if #targets == 0 then task.wait(1) end
            end
            if S._oldFarmDots then S._oldFarmDots.Text = "" end
        end)
    else
        if S._oldFarmDots then S._oldFarmDots.Text = "" end
    end
end)

-- ─── ТЕЛЕПОРТ ПО КЛИКУ ──────────────────────────────
secLbl(AtkPg,"ТЕЛЕПОРТ")
do
    local c = mkCard(AtkPg, 36)
    local ibg,ico = mkIco(c,"⊕")
    local lbl = Instance.new("TextLabel",c)
    lbl.Size=UDim2.new(1,-100,1,0); lbl.Position=UDim2.new(0,36,0,0)
    lbl.BackgroundTransparency=1; lbl.Text="Телепорт по клику ЛКМ"
    lbl.TextColor3=TH().text; lbl.TextSize=11; lbl.Font=Enum.Font.GothamSemibold; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local statusTPC = Instance.new("TextLabel",c)
    statusTPC.Size=UDim2.new(0,60,1,0); statusTPC.Position=UDim2.new(1,-64,0,0)
    statusTPC.BackgroundTransparency=1; statusTPC.Text="ВЫКЛ"
    statusTPC.TextColor3=TH().sub; statusTPC.TextSize=10; statusTPC.Font=Enum.Font.GothamBold; statusTPC.TextXAlignment=Enum.TextXAlignment.Right
    local pill=Instance.new("Frame",c); pill.Size=UDim2.new(0,32,0,17); pill.Position=UDim2.new(1,-38,0.5,-8.5)
    pill.BorderSizePixel=0; Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0); pill.BackgroundColor3=TH().br
    local dot=Instance.new("Frame",pill); dot.Size=UDim2.new(0,11,0,11); dot.BorderSizePixel=0
    dot.Position=UDim2.new(0,3,0.5,-5.5); dot.BackgroundColor3=TH().sub
    Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
    S.tpClick=false
    local btn=Instance.new("TextButton",c); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.ZIndex=2
    btn.MouseButton1Click:Connect(function()
        S.tpClick = not S.tpClick
        if S.tpClick then
            tw(pill,{BackgroundColor3=TH().accent},.16)
            tw(dot,{Position=UDim2.new(0,17,0.5,-5.5),BackgroundColor3=Color3.new(1,1,1)},.16)
            tw(ibg,{BackgroundColor3=TH().accent},.16)
            statusTPC.Text="ВКЛ"; statusTPC.TextColor3=TH().accent
        else
            tw(pill,{BackgroundColor3=TH().br},.16)
            tw(dot,{Position=UDim2.new(0,3,0.5,-5.5),BackgroundColor3=TH().sub},.16)
            tw(ibg,{BackgroundColor3=TH().hi},.16)
            statusTPC.Text="ВЫКЛ"; statusTPC.TextColor3=TH().sub
        end
    end)
end

secLbl(AtkPg,"ПРОЧЕЕ")
Toggle(AtkPg,"⏰","Анти-АФК",false,function(v) S.antiAfk=v end)

-- ═══════════════════════════════════════════════════
--  PAGE 5 — MISC
-- ═══════════════════════════════════════════════════
local MiscPg = makePage()
secLbl(MiscPg,"МИР")
Toggle(MiscPg,"⛅","Убрать туман",false,function(v)
    S.noFog=v
    local L=game:GetService("Lighting")
    if v then L.FogEnd=9e8; L.FogStart=9e8 end
end)
secLbl(MiscPg,"ТЕМА")
-- Theme grid
do
    _ord=_ord+1
    local grid=Instance.new("Frame",MiscPg)
    grid.Size=UDim2.new(1,-2,0,160); grid.BackgroundTransparency=1; grid.BorderSizePixel=0; grid.LayoutOrder=_ord
    for i,theme in ipairs(THEMES) do
        local col=(i-1)%3; local row=math.floor((i-1)/3)
        local tc=Instance.new("Frame",grid)
        tc.Size=UDim2.new(0.315,0,0,66); tc.Position=UDim2.new(col*0.344,0,0,row*72)
        tc.BackgroundColor3=theme.nav; tc.BorderSizePixel=0
        Instance.new("UICorner",tc).CornerRadius=UDim.new(0,9)
        local tcs=Instance.new("UIStroke",tc); tcs.Color=(i==TI) and theme.accent or theme.br; tcs.Thickness=(i==TI) and 1.5 or 1
        for si,sc in ipairs({theme.bg,theme.accent,theme.hi}) do
            local sw=Instance.new("Frame",tc); sw.Size=UDim2.new(0,8,0,8); sw.Position=UDim2.new(0,7+(si-1)*12,0,7)
            sw.BackgroundColor3=sc; sw.BorderSizePixel=0; Instance.new("UICorner",sw).CornerRadius=UDim.new(1,0)
        end
        if theme.snow then
            local sIco=Instance.new("TextLabel",tc); sIco.Size=UDim2.new(0,12,0,12); sIco.Position=UDim2.new(1,-16,0,5)
            sIco.BackgroundTransparency=1; sIco.Text="❄"; sIco.TextSize=9; sIco.Font=Enum.Font.Gotham; sIco.TextColor3=theme.accent
        end
        local stripe=Instance.new("Frame",tc); stripe.Size=UDim2.new(0,3,0,22); stripe.Position=UDim2.new(0,7,0,24)
        stripe.BackgroundColor3=theme.accent; stripe.BorderSizePixel=0; Instance.new("UICorner",stripe).CornerRadius=UDim.new(1,0)
        local tn=Instance.new("TextLabel",tc); tn.Size=UDim2.new(1,-14,0,13); tn.Position=UDim2.new(0,14,0,24)
        tn.BackgroundTransparency=1; tn.Text=theme.name; tn.TextColor3=theme.text; tn.TextSize=10
        tn.Font=Enum.Font.GothamBold; tn.TextXAlignment=Enum.TextXAlignment.Left
        local ts=Instance.new("TextLabel",tc); ts.Size=UDim2.new(1,-14,0,11); ts.Position=UDim2.new(0,14,0,39)
        ts.BackgroundTransparency=1; ts.Text=(i==TI) and "● активна" or "нажми"; ts.TextColor3=(i==TI) and theme.accent or theme.sub
        ts.TextSize=8; ts.Font=Enum.Font.Gotham; ts.TextXAlignment=Enum.TextXAlignment.Left
        if theme.anim~="none" then
            local al=Instance.new("TextLabel",tc); al.Size=UDim2.new(1,-14,0,10); al.Position=UDim2.new(0,14,0,52)
            al.BackgroundTransparency=1; al.Text="✦ анимация"; al.TextColor3=theme.sub; al.TextSize=7; al.Font=Enum.Font.Gotham; al.TextXAlignment=Enum.TextXAlignment.Left
        end
        local all_strokes_and_subs = {} -- store for update
        local tb=Instance.new("TextButton",tc); tb.Size=UDim2.new(1,0,1,0); tb.BackgroundTransparency=1; tb.Text=""; tb.ZIndex=2
        tb.MouseButton1Click:Connect(function()
            if TI==i then return end; TI=i
            -- update all
            for j,theme2 in ipairs(THEMES) do
                local ref=grid:GetChildren()
                -- find matching frame by index
            end
            -- simpler: just update window colors
            tw(Win,{BackgroundColor3=TH().bg},.4); tw(WStroke,{Color=TH().br},.4)
            tw(Hdr,{BackgroundColor3=TH().nav},.4); tw(HFix,{BackgroundColor3=TH().nav},.4)
            tw(TabBar,{BackgroundColor3=TH().nav},.4)
            TitleL.TextColor3=TH().text
            tcs.Color=TH().accent; tcs.Thickness=1.5; ts.Text="● активна"; ts.TextColor3=TH().accent
            SnowLayer.Visible=TH().snow
        end)
    end
end
secLbl(MiscPg,"ГОРЯЧИЕ КЛАВИШИ")
do
    local c=mkCard(MiscPg,50)
    for i,row in ipairs({{"ПР. SHIFT","скрыть / показать окно"},{"W/A/S/D + Space","лететь"},{"ПКМ / ЛКМ","аимбот (зажим)"}}) do
        local r=Instance.new("Frame",c); r.Size=UDim2.new(1,-12,0,14); r.Position=UDim2.new(0,6,0,2+(i-1)*16)
        r.BackgroundTransparency=1; r.BorderSizePixel=0
        local k=Instance.new("TextLabel",r); k.Size=UDim2.new(0,100,1,0); k.BackgroundTransparency=1
        k.Text=row[1]; k.TextColor3=TH().accent; k.TextSize=9; k.Font=Enum.Font.GothamBold; k.TextXAlignment=Enum.TextXAlignment.Left
        local v=Instance.new("TextLabel",r); v.Size=UDim2.new(1,-104,1,0); v.Position=UDim2.new(0,104,0,0)
        v.BackgroundTransparency=1; v.Text=row[2]; v.TextColor3=TH().sub; v.TextSize=9; v.Font=Enum.Font.Gotham; v.TextXAlignment=Enum.TextXAlignment.Left
    end
end

-- ═══════════════════════════════════════════════════
--  TAB BUTTONS
-- ═══════════════════════════════════════════════════
local TABS = {
    {lbl="MOVE",  ico="↑", page=MovePg},
    {lbl="VISUAL",ico="▣", page=VisPg},
    {lbl="AIM",   ico="⊙", page=AimPg},
    {lbl="ATK",   ico="⚔", page=AtkPg},
    {lbl="MISC",  ico="≡", page=MiscPg},
}
local activeTab = 1; local tabRefs = {}

for i, td in ipairs(TABS) do
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(1/#TABS, 0, 1, 0)
    btn.BackgroundTransparency = i==1 and 0 or 1
    btn.BackgroundColor3 = TH().hi
    btn.Text = ""; btn.BorderSizePixel = 0; btn.ZIndex = 4
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 9)

    local icoL = Instance.new("TextLabel", btn)
    icoL.Size = UDim2.new(0, 16, 1, 0); icoL.Position = UDim2.new(0.5, -28, 0, 0)
    icoL.BackgroundTransparency = 1; icoL.Text = td.ico; icoL.TextSize = 12
    icoL.Font = Enum.Font.GothamBold; icoL.TextColor3 = i==1 and TH().accent or TH().sub; icoL.ZIndex = 5

    local lblL = Instance.new("TextLabel", btn)
    lblL.Size = UDim2.new(0, 44, 1, 0); lblL.Position = UDim2.new(0.5, -13, 0, 0)
    lblL.BackgroundTransparency = 1; lblL.Text = td.lbl; lblL.TextSize = 10
    lblL.Font = i==1 and Enum.Font.GothamBold or Enum.Font.Gotham
    lblL.TextColor3 = i==1 and TH().text or TH().sub; lblL.ZIndex = 5
    lblL.TextXAlignment = Enum.TextXAlignment.Left

    local ul = Instance.new("Frame", btn)
    ul.Size = UDim2.new(0.6, 0, 0, 2); ul.Position = UDim2.new(0.2, 0, 1, -2)
    ul.BackgroundColor3 = TH().accent; ul.BorderSizePixel = 0
    ul.BackgroundTransparency = i==1 and 0 or 1
    Instance.new("UICorner", ul).CornerRadius = UDim.new(1, 0)

    tabRefs[i] = {btn=btn, ico=icoL, lbl=lblL, ul=ul}

    btn.MouseButton1Click:Connect(function()
        if i == activeTab then return end
        local prev = tabRefs[activeTab]
        tw(prev.btn, {BackgroundTransparency=1}, .15)
        tw(prev.ico, {TextColor3=TH().sub}, .15)
        tw(prev.lbl, {TextColor3=TH().sub}, .15); prev.lbl.Font = Enum.Font.Gotham
        tw(prev.ul,  {BackgroundTransparency=1}, .15)
        TABS[activeTab].page.Visible = false
        activeTab = i
        tw(btn, {BackgroundTransparency=0, BackgroundColor3=TH().hi}, .15)
        tw(icoL,{TextColor3=TH().accent}, .15)
        tw(lblL,{TextColor3=TH().text},   .15); lblL.Font = Enum.Font.GothamBold
        tw(ul,  {BackgroundTransparency=0, BackgroundColor3=TH().accent}, .15)
        td.page.Visible = true
    end)
end
TABS[1].page.Visible = true

-- ═══════════════════════════════════════════════════
--  OPEN / CLOSE
-- ═══════════════════════════════════════════════════
local isOpen = true

local MiniBtn = Instance.new("TextButton", SGui)
MiniBtn.Size = UDim2.new(0, 100, 0, 24); MiniBtn.Position = UDim2.new(0, 8, 0, 8)
MiniBtn.BackgroundColor3 = TH().nav; MiniBtn.Text = "▶  Vape Ext"
MiniBtn.TextColor3 = TH().accent; MiniBtn.TextSize = 10
MiniBtn.Font = Enum.Font.GothamBold; MiniBtn.BorderSizePixel = 0; MiniBtn.Visible = false; MiniBtn.ZIndex = 999
Instance.new("UICorner", MiniBtn).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MiniBtn).Color = TH().accent

local function closeWin()
    if not isOpen then return end; isOpen = false
    tw(Win, {Position=UDim2.new(0.5,-245,1.1,0)}, .28, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    task.delay(.3, function() Win.Visible=false; MiniBtn.Visible=true end)
end
local function openWin()
    if isOpen then return end; isOpen = true
    MiniBtn.Visible = false; Win.Visible = true
    Win.Position = UDim2.new(0.5, -245, 1.1, 0)
    tw(Win, {Position=UDim2.new(0.5,-245,0.5,-245)}, .4, Enum.EasingStyle.Back)
end

CloseBtn.MouseButton1Click:Connect(closeWin)
MiniBtn.MouseButton1Click:Connect(openWin)
CloseBtn.MouseEnter:Connect(function() tw(CloseBtn, {BackgroundColor3=Color3.fromRGB(88,24,24)}, .1) end)
CloseBtn.MouseLeave:Connect(function() tw(CloseBtn, {BackgroundColor3=Color3.fromRGB(58,20,20)}, .1) end)
UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.RightShift then
        if isOpen then closeWin() else openWin() end
    end
end)

-- ═══════════════════════════════════════════════════
--  THEME ANIMATIONS
-- ═══════════════════════════════════════════════════
task.spawn(function()
    while task.wait(1.5) do
        safe(function()
            local th = TH()
            if th.anim == "pulse" then
                tw(WStroke,{Color=Color3.fromRGB(178,98,255)},1.2,Enum.EasingStyle.Sine)
                task.wait(1.2)
                tw(WStroke,{Color=th.br},1.2,Enum.EasingStyle.Sine)
            elseif th.anim == "ember" then
                tw(WStroke,{Color=Color3.fromRGB(255,42,42)},0.7,Enum.EasingStyle.Sine)
                task.wait(0.7)
                tw(WStroke,{Color=th.br},0.5,Enum.EasingStyle.Sine)
            elseif th.anim == "drift" then
                tw(GDot,{BackgroundColor3=th.accent},1.0,Enum.EasingStyle.Sine)
                task.wait(1.0)
                tw(GDot,{BackgroundColor3=Color3.fromRGB(46,215,90)},1.0,Enum.EasingStyle.Sine)
            elseif th.anim == "snow" then
                tw(WStroke,{Color=Color3.fromRGB(180,215,255)},1.5,Enum.EasingStyle.Sine)
                task.wait(1.5)
                tw(WStroke,{Color=th.br},1.5,Enum.EasingStyle.Sine)
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════
--  GAMEPLAY LOGIC
-- ═══════════════════════════════════════════════════

-- Fly
RS.Heartbeat:Connect(function()
    safe(function()
        local hum=getHum(); local hrp=getHRP(); if not hum or not hrp then return end
        if S.fly then
            hum.PlatformStand=true
            local dir=Vector3.new(); local cf=cam.CFrame
            if UIS:IsKeyDown(Enum.KeyCode.W)         then dir+=cf.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.S)         then dir-=cf.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.A)         then dir-=cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D)         then dir+=cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space)     then dir+=Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir-=Vector3.new(0,1,0) end
            if dir.Magnitude>0 then dir=dir.Unit end
            hrp.Velocity=dir*S.flySpeed; hrp.RotVelocity=Vector3.zero
        else
            if hum.PlatformStand then hum.PlatformStand=false end
        end
    end)
end)

-- Noclip
RS.Stepped:Connect(function()
    if not S.noclip then return end
    safe(function()
        local c=getChar(); if not c then return end
        for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
    end)
end)

-- Infinite jump
UIS.JumpRequest:Connect(function()
    if not S.infJump then return end
    safe(function()
        local hum=getHum()
        if hum and hum.FloorMaterial==Enum.Material.Air then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end)

-- Auto clicker
task.spawn(function()
    while true do
        if S.aclick and HAS_VIM and VIM then
            local delay = 1 / math.max(S.aclickCps, 1)
            safe(function()
                local pos = UIS:GetMouseLocation()
                VIM:SendMouseButtonEvent(pos.X, pos.Y, S.aclickBtn or 0, true,  game, 0)
                task.wait(0.01)
                VIM:SendMouseButtonEvent(pos.X, pos.Y, S.aclickBtn or 0, false, game, 0)
            end)
            task.wait(math.max(delay - 0.01, 0.01))
        else
            task.wait(0.1)
        end
    end
end)

-- ─── AIMBOT ────────────────────────────────────────
local fovCircle = nil
if HAS_DRAWING then
    safe(function()
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness    = 1
        fovCircle.Color        = Color3.new(1, 1, 1)
        fovCircle.Transparency = 0.55
        fovCircle.Filled       = false
        fovCircle.Visible      = false
    end)
end

local function aimHeld()
    if S.aimKey=="always" then return true end
    if S.aimKey=="rmb" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
    if S.aimKey=="lmb" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
    return false
end

local function bestTarget()
    local vp = cam.ViewportSize; local center = Vector2.new(vp.X/2, vp.Y/2)
    local best, bestScore = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == lp then continue end
        if S.aimTeam and plr.Team == lp.Team then continue end
        local char = plr.Character; if not char then continue end
        local part = char:FindFirstChild(S.aimPart) or char:FindFirstChild("HumanoidRootPart"); if not part then continue end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health <= 0 then continue end
        local sp, vis = cam:WorldToViewportPoint(part.Position); if not vis then continue end
        local sd = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if sd > S.aimFOV then continue end
        if S.aimVisible then
            local rp = RaycastParams.new(); rp.FilterDescendantsInstances = {getChar()}
            rp.FilterType = Enum.RaycastFilterType.Exclude
            local ray = workspace:Raycast(cam.CFrame.Position, (part.Position-cam.CFrame.Position).Unit*1000, rp)
            if ray and not ray.Instance:IsDescendantOf(char) then continue end
        end
        local score = S.aimMode=="lowhp" and hum.Health or sd
        if score < bestScore then bestScore=score; best=part end
    end
    return best
end

RS.RenderStepped:Connect(function()
    safe(function()
        local vp = cam.ViewportSize
        if fovCircle then
            fovCircle.Visible   = S.aimOn and S.aimFOVCircle
            fovCircle.Position  = Vector2.new(vp.X/2, vp.Y/2)
            fovCircle.Radius    = S.aimFOV
            fovCircle.Color     = S.espColor
        end
        if S.aimOn and aimHeld() then
            local target = bestTarget()
            if target then
                local pos = target.Position
                if S.aimPred then
                    local hrp = target.Parent and target.Parent:FindFirstChild("HumanoidRootPart")
                    if hrp then pos = pos + hrp.Velocity * S.aimPredVal end
                end
                local dir = (pos - cam.CFrame.Position).Unit
                local newCF = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + dir)
                cam.CFrame = cam.CFrame:Lerp(newCF, math.clamp(S.aimSmooth, 0.01, 1))
            end
        end
    end)
end)

-- ─── ESP (Drawing API, box from screen projection) ─
local pool = {}

local function newDrawing(t, props)
    if not HAS_DRAWING then return nil end
    local ok, d = pcall(function()
        local obj = Drawing.new(t)
        for k, v in pairs(props or {}) do
            pcall(function() obj[k] = v end)
        end
        return obj
    end)
    return ok and d or nil
end

local function rmEsp(uid)
    local o = pool[uid]; if not o then return end
    for _, d in pairs(o) do pcall(function() d:Remove() end) end
    pool[uid] = nil
end
local function clearEsp()
    for uid in pairs(pool) do rmEsp(uid) end
end

RS.RenderStepped:Connect(function()
    if not S.espOn then clearEsp(); return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == lp then continue end
        local char = plr.Character
        local head = char and char:FindFirstChild("Head")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not head or not hrp or not hum or hum.Health <= 0 then rmEsp(plr.UserId); continue end

        -- Top and bottom world positions
        local topW = head.Position + Vector3.new(0, head.Size.Y/2 + 0.1, 0)
        local botW = hrp.Position  - Vector3.new(0, 3.1, 0)
        local sTop, vTop = cam:WorldToViewportPoint(topW)
        local sBot, vBot = cam:WorldToViewportPoint(botW)
        if not vTop and not vBot then rmEsp(plr.UserId); continue end

        local bH  = math.abs(sBot.Y - sTop.Y)
        local bW  = bH * 0.5
        local cx  = sTop.X
        local bL, bTy, bBy = cx - bW/2, sTop.Y, sBot.Y
        local col = S.espColor

        if not pool[plr.UserId] then
            pool[plr.UserId] = {
                box  = newDrawing("Square",{Thickness=1.3, Filled=false, Visible=false}),
                name = newDrawing("Text",  {Size=12, Outline=true, Visible=false}),
                hpBg = newDrawing("Square",{Filled=true, Color=Color3.fromRGB(15,15,15), Transparency=0.35, Visible=false}),
                hpFl = newDrawing("Square",{Filled=true, Visible=false}),
                hp   = newDrawing("Text",  {Size=10, Outline=true, Visible=false}),
                dist = newDrawing("Text",  {Size=10, Outline=true, Color=Color3.fromRGB(185,185,200), Visible=false}),
                line = newDrawing("Line",  {Thickness=1, Transparency=0.35, Visible=false}),
            }
        end

        local o = pool[plr.UserId]
        safe(function()
            if o.box then
                o.box.Visible   = S.espBox; o.box.Color = col
                o.box.Position  = Vector2.new(bL, bTy)
                o.box.Size      = Vector2.new(bW, bH)
            end
            if o.name then
                o.name.Visible   = S.espName; o.name.Color = col
                o.name.Text      = plr.DisplayName
                o.name.Position  = Vector2.new(cx, bTy - 14)
                o.name.Center    = true
            end
            local hp  = hum.Health; local mx = math.max(hum.MaxHealth, 1); local r = hp/mx
            local hpCol = Color3.fromRGB(math.floor(255*(1-r)), math.floor(55+200*r), 55)
            local hpH = bH * r
            if o.hpBg then
                o.hpBg.Visible  = S.espHP
                o.hpBg.Position = Vector2.new(bL - 5, bTy)
                o.hpBg.Size     = Vector2.new(4, bH)
            end
            if o.hpFl then
                o.hpFl.Visible  = S.espHP; o.hpFl.Color = hpCol
                o.hpFl.Position = Vector2.new(bL - 5, bBy - hpH)
                o.hpFl.Size     = Vector2.new(4, hpH)
            end
            if o.hp then
                o.hp.Visible   = S.espHP; o.hp.Color = hpCol
                o.hp.Text      = math.floor(hp) .. "hp"
                o.hp.Position  = Vector2.new(bL + bW + 3, bTy)
                o.hp.Center    = false
            end
            if o.dist then
                local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                local dist = myHRP and math.floor((hrp.Position - myHRP.Position).Magnitude) or 0
                o.dist.Visible   = S.espDist; o.dist.Text = dist .. "m"
                o.dist.Position  = Vector2.new(cx, bBy + 2); o.dist.Center = true
            end
            if o.line then
                o.line.Visible = S.espLines; o.line.Color = col
                if S.espLines then
                    local vp = cam.ViewportSize
                    o.line.From = Vector2.new(vp.X/2, S.espLineFrom=="bottom" and vp.Y or vp.Y/2)
                    o.line.To   = Vector2.new(cx, bBy)
                end
            end
        end)
    end
end)
Players.PlayerRemoving:Connect(function(p) rmEsp(p.UserId) end)

-- ─── ТЕЛЕПОРТ ПО КЛИКУ ─────────────────────────────
do
    local mouse = lp:GetMouse()
    -- Используем UIS чтобы не мешать GUI-кликам
    UIS.InputBegan:Connect(function(inp, gpe)
        if gpe then return end  -- клик был на GUI — игнорируем
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if not S.tpClick then return end
        safe(function()
            local hrp = getHRP(); if not hrp then return end
            local unitRay = cam:ViewportPointToRay(inp.Position.X, inp.Position.Y)
            local rp = RaycastParams.new()
            rp.FilterDescendantsInstances = {getChar()}
            rp.FilterType = Enum.RaycastFilterType.Exclude
            local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 2000, rp)
            if result then
                hrp.CFrame = CFrame.new(result.Position + result.Normal * 3)
            else
                -- нет пересечения — телепорт на дальность 200 studs по лучу камеры
                hrp.CFrame = CFrame.new(unitRay.Origin + unitRay.Direction * 200)
            end
        end)
    end)
end

-- ═══════════════════════════════════════════════════
--  STARTUP ANIMATION
-- ═══════════════════════════════════════════════════
Win.Visible = true
SnowLayer.Visible = TH().snow

-- Slide in from bottom
task.delay(0.05, function()
    tw(Win, {Position = UDim2.new(0.5, -245, 0.5, -245)}, 0.55, Enum.EasingStyle.Back)
end)

print("[Vape External v5.1] ✓  готово — ПР.SHIFT скрыть/показать")
