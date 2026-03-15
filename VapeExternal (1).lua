local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RS         = game:GetService("RunService")
local TS         = game:GetService("TweenService")
local Stats      = game:GetService("Stats")
local VIM        = game:GetService("VirtualInputManager")

local lp  = Players.LocalPlayer
local cam = workspace.CurrentCamera
if not lp.Character then lp.CharacterAdded:Wait() end

-- ══════════════════════════════════════════
--  THEMES
-- ══════════════════════════════════════════
local THEMES = {
    {name="Тёмная",  bg=Color3.fromRGB(10,10,15),  nav=Color3.fromRGB(14,14,21),  card=Color3.fromRGB(20,20,30),  hi=Color3.fromRGB(25,25,40),  accent=Color3.fromRGB(80,155,255), text=Color3.fromRGB(225,230,245), sub=Color3.fromRGB(85,90,115),  br=Color3.fromRGB(32,32,52)},
    {name="Сумерки", bg=Color3.fromRGB(9,7,17),    nav=Color3.fromRGB(13,10,24),  card=Color3.fromRGB(18,15,32),  hi=Color3.fromRGB(24,19,44),  accent=Color3.fromRGB(150,85,255), text=Color3.fromRGB(215,210,240), sub=Color3.fromRGB(95,80,135),  br=Color3.fromRGB(36,28,60)},
    {name="Уголь",   bg=Color3.fromRGB(12,12,12),  nav=Color3.fromRGB(17,17,17),  card=Color3.fromRGB(24,24,24),  hi=Color3.fromRGB(30,30,30),  accent=Color3.fromRGB(255,65,65),  text=Color3.fromRGB(235,235,235), sub=Color3.fromRGB(110,110,110),br=Color3.fromRGB(42,42,42)},
    {name="Рассвет", bg=Color3.fromRGB(7,14,22),   nav=Color3.fromRGB(10,20,32),  card=Color3.fromRGB(14,27,42),  hi=Color3.fromRGB(18,34,54),  accent=Color3.fromRGB(0,200,170),  text=Color3.fromRGB(195,225,235), sub=Color3.fromRGB(65,115,138), br=Color3.fromRGB(18,40,62)},
}
local TI=1; local function TH() return THEMES[TI] end

-- ══════════════════════════════════════════
--  STATE
-- ══════════════════════════════════════════
local S = {
    -- Movement
    fly=false, flySpeed=60, noclip=false,
    speed=false, speedVal=24, infiniteJump=false,
    jumpPow=false, jumpVal=50,
    -- Combat
    aclick=false, aclickDelay=0.05,
    -- ESP
    espOn=false, espBox=true, espName=true,
    espHP=true, espLines=false, espDist=false,
    espCorner=0, espColor=Color3.fromRGB(80,155,255),
    espColorIdx=1, espLineFrom="bottom",
    -- Farm
    farmOn=false, farmPtA=nil, farmPtB=nil,
    farmDelay=1.0,
    -- Misc
    antiAfk=false, noFog=false,
}

local ESP_COLORS = {
    Color3.fromRGB(80,155,255),  Color3.fromRGB(255,65,65),
    Color3.fromRGB(45,215,95),   Color3.fromRGB(255,215,50),
    Color3.fromRGB(255,255,255), Color3.fromRGB(0,210,185),
    Color3.fromRGB(255,120,40),  Color3.fromRGB(210,75,210),
}

-- ══════════════════════════════════════════
--  METRICS
-- ══════════════════════════════════════════
local fpsVal, pingVal = 0, 0
do
    local frames, last = 0, tick()
    RS.Heartbeat:Connect(function()
        frames += 1
        local now = tick()
        if now - last >= 0.5 then
            fpsVal = math.floor(frames / (now - last))
            frames, last = 0, now
        end
        pingVal = math.floor((Stats.Network.ServerStatsItem["Data Ping"]:GetValue()))
    end)
end

-- ══════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════
local function tw(o,p,t,s,d)
    if not o or not o.Parent then return end
    TS:Create(o,TweenInfo.new(t or .2,s or Enum.EasingStyle.Quart,d or Enum.EasingDirection.Out),p):Play()
end

local function getChar()
    local ok,c=pcall(function() return lp.Character end)
    return ok and c or nil
end
local function getHRP()
    local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") or nil
end
local function getHum()
    local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") or nil
end

-- ══════════════════════════════════════════
--  CLEANUP
-- ══════════════════════════════════════════
pcall(function()
    if lp.PlayerGui:FindFirstChild("VapeExt") then lp.PlayerGui.VapeExt:Destroy() end
end)
task.wait(0.05)

-- ══════════════════════════════════════════
--  SCREEN GUI
-- ══════════════════════════════════════════
local SGui = Instance.new("ScreenGui")
SGui.Name="VapeExt"; SGui.ResetOnSpawn=false
SGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SGui.DisplayOrder=999; SGui.IgnoreGuiInset=true
SGui.Parent=lp.PlayerGui

-- ══════════════════════════════════════════
--  MAIN WINDOW  360 × 430
-- ══════════════════════════════════════════
local Win = Instance.new("Frame",SGui)
Win.Name="Win"; Win.Size=UDim2.new(0,360,0,430)
Win.Position=UDim2.new(0.5,-180,0.5,-215)
Win.BackgroundColor3=TH().bg; Win.BorderSizePixel=0
Win.Active=true; Win.Draggable=true; Win.ClipsDescendants=false
Instance.new("UICorner",Win).CornerRadius=UDim.new(0,14)
local WinStroke=Instance.new("UIStroke",Win)
WinStroke.Color=TH().br; WinStroke.Thickness=1

-- Shadow
local Shad=Instance.new("Frame",Win)
Shad.Size=UDim2.new(1,30,1,30); Shad.Position=UDim2.new(0,-15,0,10)
Shad.BackgroundColor3=Color3.new(0,0,0); Shad.BackgroundTransparency=.65
Shad.BorderSizePixel=0; Shad.ZIndex=0
Instance.new("UICorner",Shad).CornerRadius=UDim.new(0,22)

-- ══════════════════════════════════════════
--  HEADER  h=42
-- ══════════════════════════════════════════
local Hdr = Instance.new("Frame",Win)
Hdr.Size=UDim2.new(1,0,0,42); Hdr.BackgroundColor3=TH().nav
Hdr.BorderSizePixel=0; Hdr.ZIndex=3
Instance.new("UICorner",Hdr).CornerRadius=UDim.new(0,14)
local HFix=Instance.new("Frame",Hdr); HFix.Size=UDim2.new(1,0,0,14)
HFix.Position=UDim2.new(0,0,1,-14); HFix.BackgroundColor3=TH().nav; HFix.BorderSizePixel=0; HFix.ZIndex=3

-- Logo dot
local LogoDot=Instance.new("Frame",Hdr)
LogoDot.Size=UDim2.new(0,8,0,8); LogoDot.Position=UDim2.new(0,14,0.5,-4)
LogoDot.BackgroundColor3=Color3.fromRGB(46,214,90); LogoDot.BorderSizePixel=0; LogoDot.ZIndex=4
Instance.new("UICorner",LogoDot).CornerRadius=UDim.new(1,0)

local TitleL=Instance.new("TextLabel",Hdr)
TitleL.Size=UDim2.new(0,130,1,0); TitleL.Position=UDim2.new(0,28,0,0)
TitleL.BackgroundTransparency=1; TitleL.Text="Vape External"
TitleL.TextColor3=TH().text; TitleL.TextSize=13; TitleL.Font=Enum.Font.GothamBold
TitleL.TextXAlignment=Enum.TextXAlignment.Left; TitleL.ZIndex=4

-- FPS label
local FpsLbl=Instance.new("TextLabel",Hdr)
FpsLbl.Size=UDim2.new(0,70,1,0); FpsLbl.Position=UDim2.new(0,162,0,0)
FpsLbl.BackgroundTransparency=1; FpsLbl.Text="FPS: --"
FpsLbl.TextColor3=Color3.fromRGB(46,214,90); FpsLbl.TextSize=10; FpsLbl.Font=Enum.Font.GothamBold
FpsLbl.TextXAlignment=Enum.TextXAlignment.Left; FpsLbl.ZIndex=4

-- Ping label
local PingLbl=Instance.new("TextLabel",Hdr)
PingLbl.Size=UDim2.new(0,70,1,0); PingLbl.Position=UDim2.new(0,228,0,0)
PingLbl.BackgroundTransparency=1; PingLbl.Text="PING: --"
PingLbl.TextColor3=Color3.fromRGB(255,215,50); PingLbl.TextSize=10; PingLbl.Font=Enum.Font.GothamBold
PingLbl.TextXAlignment=Enum.TextXAlignment.Left; PingLbl.ZIndex=4

-- Update metrics display
RS.Heartbeat:Connect(function()
    FpsLbl.Text = "FPS: "..fpsVal
    FpsLbl.TextColor3 = fpsVal>=50 and Color3.fromRGB(46,214,90) or fpsVal>=30 and Color3.fromRGB(255,215,50) or Color3.fromRGB(255,65,65)
    PingLbl.Text = "PING: "..pingVal
    PingLbl.TextColor3 = pingVal<=60 and Color3.fromRGB(46,214,90) or pingVal<=120 and Color3.fromRGB(255,215,50) or Color3.fromRGB(255,65,65)
end)

-- Close btn
local CloseBtn=Instance.new("TextButton",Hdr)
CloseBtn.Size=UDim2.new(0,22,0,22); CloseBtn.Position=UDim2.new(1,-30,0.5,-11)
CloseBtn.BackgroundColor3=Color3.fromRGB(60,22,22); CloseBtn.Text="✕"
CloseBtn.TextColor3=Color3.fromRGB(200,65,65); CloseBtn.TextSize=10
CloseBtn.Font=Enum.Font.GothamBold; CloseBtn.BorderSizePixel=0; CloseBtn.ZIndex=10
Instance.new("UICorner",CloseBtn).CornerRadius=UDim.new(0,6)
CloseBtn.MouseEnter:Connect(function() tw(CloseBtn,{BackgroundColor3=Color3.fromRGB(90,26,26)},.1) end)
CloseBtn.MouseLeave:Connect(function() tw(CloseBtn,{BackgroundColor3=Color3.fromRGB(60,22,22)},.1) end)

-- ══════════════════════════════════════════
--  LEFT NAV  w=125
-- ══════════════════════════════════════════
local Nav=Instance.new("Frame",Win)
Nav.Size=UDim2.new(0,125,1,-42); Nav.Position=UDim2.new(0,0,0,42)
Nav.BackgroundColor3=TH().nav; Nav.BorderSizePixel=0; Nav.ZIndex=2
Instance.new("UICorner",Nav).CornerRadius=UDim.new(0,14)
local NFix=Instance.new("Frame",Nav); NFix.Size=UDim2.new(0,14,1,0)
NFix.Position=UDim2.new(1,-14,0,0); NFix.BackgroundColor3=TH().nav; NFix.BorderSizePixel=0; NFix.ZIndex=2
local NFix2=Instance.new("Frame",Nav); NFix2.Size=UDim2.new(1,0,0,14)
NFix2.Position=UDim2.new(0,0,0,0); NFix2.BackgroundColor3=TH().nav; NFix2.BorderSizePixel=0; NFix2.ZIndex=2

-- Divider
local NavDiv=Instance.new("Frame",Win)
NavDiv.Size=UDim2.new(0,1,1,-42); NavDiv.Position=UDim2.new(0,125,0,42)
NavDiv.BackgroundColor3=TH().br; NavDiv.BorderSizePixel=0

-- Version at bottom of nav
local NavVer=Instance.new("TextLabel",Nav)
NavVer.Size=UDim2.new(1,0,0,20); NavVer.Position=UDim2.new(0,0,1,-24)
NavVer.BackgroundTransparency=1; NavVer.Text="v4.0"
NavVer.TextColor3=TH().sub; NavVer.TextSize=9; NavVer.Font=Enum.Font.Gotham; NavVer.ZIndex=3

-- ══════════════════════════════════════════
--  CONTENT AREA
-- ══════════════════════════════════════════
local ContentWrap=Instance.new("Frame",Win)
ContentWrap.Size=UDim2.new(1,-130,1,-48); ContentWrap.Position=UDim2.new(0,129,0,46)
ContentWrap.BackgroundTransparency=1; ContentWrap.ClipsDescendants=true

-- ══════════════════════════════════════════
--  COMPONENT HELPERS
-- ══════════════════════════════════════════
local _ord=0
local function nO() _ord+=1; return _ord end

local function makePage()
    local sf=Instance.new("ScrollingFrame",ContentWrap)
    sf.Size=UDim2.new(1,0,1,0); sf.CanvasSize=UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize=Enum.AutomaticSize.Y
    sf.ScrollBarThickness=2; sf.ScrollBarImageColor3=TH().br
    sf.BackgroundTransparency=1; sf.Visible=false; sf.BorderSizePixel=0
    local pad=Instance.new("UIPadding",sf)
    pad.PaddingTop=UDim.new(0,3); pad.PaddingRight=UDim.new(0,4); pad.PaddingBottom=UDim.new(0,10)
    Instance.new("UIListLayout",sf).Padding=UDim.new(0,3)
    return sf
end

local function secLbl(page,txt)
    local f=Instance.new("Frame",page)
    f.Size=UDim2.new(1,0,0,16); f.BackgroundTransparency=1; f.BorderSizePixel=0; f.LayoutOrder=nO()
    local sep=Instance.new("Frame",f)
    sep.Size=UDim2.new(1,-8,0,1); sep.Position=UDim2.new(0,4,0.5,3)
    sep.BackgroundColor3=TH().br; sep.BorderSizePixel=0
    local l=Instance.new("TextLabel",f)
    l.Size=UDim2.new(0,120,1,0); l.Position=UDim2.new(0,4,0,0)
    l.BackgroundColor3=TH().bg; l.BorderSizePixel=0
    Instance.new("UIPadding",l).PaddingRight=UDim.new(0,4)
    l.Text=" "..txt.." "; l.TextColor3=TH().sub; l.TextSize=8
    l.Font=Enum.Font.GothamBold; l.TextXAlignment=Enum.TextXAlignment.Left
end

local function card(page,h)
    local f=Instance.new("Frame",page)
    f.Size=UDim2.new(1,-4,0,h); f.BackgroundColor3=TH().card
    f.BorderSizePixel=0; f.LayoutOrder=nO()
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,8)
    local st=Instance.new("UIStroke",f); st.Color=TH().br; st.Thickness=1
    return f,st
end

-- Toggle
local function Toggle(page,icon,label,init,cb)
    local c=card(page,34)
    local bg=Instance.new("Frame",c)
    bg.Size=UDim2.new(0,26,0,26); bg.Position=UDim2.new(0,5,0.5,-13)
    bg.BackgroundColor3=TH().hi; bg.BorderSizePixel=0
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,7)
    local ico=Instance.new("TextLabel",bg)
    ico.Size=UDim2.new(1,0,1,0); ico.BackgroundTransparency=1; ico.Text=icon
    ico.TextSize=13; ico.Font=Enum.Font.Gotham; ico.TextColor3=TH().sub

    local lbl=Instance.new("TextLabel",c)
    lbl.Size=UDim2.new(1,-90,1,0); lbl.Position=UDim2.new(0,36,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=TH().text
    lbl.TextSize=11; lbl.Font=Enum.Font.GothamSemibold; lbl.TextXAlignment=Enum.TextXAlignment.Left

    local pill=Instance.new("Frame",c)
    pill.Size=UDim2.new(0,32,0,17); pill.Position=UDim2.new(1,-38,0.5,-8.5)
    pill.BorderSizePixel=0; Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
    local dot=Instance.new("Frame",pill)
    dot.Size=UDim2.new(0,11,0,11); dot.BorderSizePixel=0
    Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)

    local val=init or false
    local function refresh()
        if val then
            tw(pill,{BackgroundColor3=TH().accent},.18)
            tw(dot,{Position=UDim2.new(0,17,0.5,-5.5),BackgroundColor3=Color3.new(1,1,1)},.18)
            tw(bg,{BackgroundColor3=TH().accent},.18); tw(ico,{TextColor3=Color3.new(1,1,1)},.18)
        else
            tw(pill,{BackgroundColor3=TH().br},.18)
            tw(dot,{Position=UDim2.new(0,3,0.5,-5.5),BackgroundColor3=TH().sub},.18)
            tw(bg,{BackgroundColor3=TH().hi},.18); tw(ico,{TextColor3=TH().sub},.18)
        end
    end
    refresh()
    local btn=Instance.new("TextButton",c)
    btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.ZIndex=2
    btn.MouseButton1Click:Connect(function() val=not val; refresh(); if cb then cb(val) end end)
end

-- Slider
local _drag=nil
UIS.InputChanged:Connect(function(i)
    if not _drag or i.UserInputType~=Enum.UserInputType.MouseMovement then return end
    local d=_drag
    if not d.tr or not d.tr.Parent then _drag=nil; return end
    local p=math.clamp((i.Position.X-d.tr.AbsolutePosition.X)/math.max(d.tr.AbsoluteSize.X,1),0,1)
    local v=math.floor(d.min+p*(d.max-d.min))
    d.fill.Size=UDim2.new(p,0,1,0); d.thumb.Position=UDim2.new(p,-5,0.5,-5)
    d.vl.Text=tostring(v); if d.cb then d.cb(v) end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then _drag=nil end
end)

local function Slider(page,label,init,minV,maxV,cb)
    local c=card(page,40)
    local lbl=Instance.new("TextLabel",c)
    lbl.Size=UDim2.new(0.62,0,0,18); lbl.Position=UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=TH().text
    lbl.TextSize=11; lbl.Font=Enum.Font.GothamSemibold; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local vl=Instance.new("TextLabel",c)
    vl.Size=UDim2.new(0.36,0,0,18); vl.Position=UDim2.new(0.64,0,0,4)
    vl.BackgroundTransparency=1; vl.Text=tostring(init); vl.TextColor3=TH().accent
    vl.TextSize=11; vl.Font=Enum.Font.GothamBold; vl.TextXAlignment=Enum.TextXAlignment.Right
    local tr=Instance.new("Frame",c)
    tr.Size=UDim2.new(1,-18,0,4); tr.Position=UDim2.new(0,9,0,29)
    tr.BackgroundColor3=TH().hi; tr.BorderSizePixel=0
    Instance.new("UICorner",tr).CornerRadius=UDim.new(1,0)
    local pct=math.clamp((init-minV)/(maxV-minV),0,1)
    local fill=Instance.new("Frame",tr)
    fill.Size=UDim2.new(pct,0,1,0); fill.BackgroundColor3=TH().accent; fill.BorderSizePixel=0
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local thumb=Instance.new("Frame",tr)
    thumb.Size=UDim2.new(0,10,0,10); thumb.Position=UDim2.new(pct,-5,0.5,-5)
    thumb.BackgroundColor3=Color3.new(1,1,1); thumb.BorderSizePixel=0; thumb.ZIndex=3
    Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0)
    local hit=Instance.new("TextButton",tr)
    hit.Size=UDim2.new(1,0,0,24); hit.Position=UDim2.new(0,0,0.5,-12)
    hit.BackgroundTransparency=1; hit.Text=""; hit.ZIndex=4
    hit.MouseButton1Down:Connect(function() _drag={tr=tr,fill=fill,thumb=thumb,vl=vl,min=minV,max=maxV,cb=cb} end)
end

-- Stepper
local function Stepper(page,icon,label,init,minV,maxV,step,cb)
    local c=card(page,34)
    local bg=Instance.new("Frame",c)
    bg.Size=UDim2.new(0,26,0,26); bg.Position=UDim2.new(0,5,0.5,-13)
    bg.BackgroundColor3=TH().hi; bg.BorderSizePixel=0
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,7)
    local ico=Instance.new("TextLabel",bg)
    ico.Size=UDim2.new(1,0,1,0); ico.BackgroundTransparency=1; ico.Text=icon
    ico.TextSize=12; ico.Font=Enum.Font.Gotham; ico.TextColor3=TH().sub
    local lbl=Instance.new("TextLabel",c)
    lbl.Size=UDim2.new(1,-95,1,0); lbl.Position=UDim2.new(0,36,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=TH().text
    lbl.TextSize=11; lbl.Font=Enum.Font.GothamSemibold; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local val=init
    local vl=Instance.new("TextLabel",c)
    vl.Size=UDim2.new(0,24,1,0); vl.Position=UDim2.new(1,-62,0,0)
    vl.BackgroundTransparency=1; vl.Text=tostring(val); vl.TextColor3=TH().accent
    vl.TextSize=11; vl.Font=Enum.Font.GothamBold
    for _,d in ipairs({{-36,"−",-step},{-14,"+",step}}) do
        local b=Instance.new("TextButton",c)
        b.Size=UDim2.new(0,20,0,20); b.Position=UDim2.new(1,d[1],0.5,-10)
        b.BackgroundColor3=TH().hi; b.Text=d[2]; b.TextColor3=TH().text
        b.TextSize=13; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; b.ZIndex=2
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
        b.MouseButton1Click:Connect(function()
            val=math.clamp(val+d[3],minV,maxV); vl.Text=tostring(val); if cb then cb(val) end
        end)
    end
end

-- Info row (read-only label)
local function InfoRow(page,icon,label,valStr)
    local c=card(page,30)
    local bg=Instance.new("Frame",c)
    bg.Size=UDim2.new(0,22,0,22); bg.Position=UDim2.new(0,5,0.5,-11)
    bg.BackgroundColor3=TH().hi; bg.BorderSizePixel=0
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,6)
    local ico=Instance.new("TextLabel",bg)
    ico.Size=UDim2.new(1,0,1,0); ico.BackgroundTransparency=1; ico.Text=icon
    ico.TextSize=11; ico.Font=Enum.Font.Gotham; ico.TextColor3=TH().sub
    local lbl=Instance.new("TextLabel",c)
    lbl.Size=UDim2.new(1,-90,1,0); lbl.Position=UDim2.new(0,31,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=TH().text
    lbl.TextSize=10; lbl.Font=Enum.Font.GothamSemibold; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local vLbl=Instance.new("TextLabel",c)
    vLbl.Size=UDim2.new(0,80,1,0); vLbl.Position=UDim2.new(1,-84,0,0)
    vLbl.BackgroundTransparency=1; vLbl.Text=valStr; vLbl.TextColor3=TH().accent
    vLbl.TextSize=10; vLbl.Font=Enum.Font.GothamBold; vLbl.TextXAlignment=Enum.TextXAlignment.Right
    return vLbl
end

-- Button
local function Btn(page,icon,label,cb)
    local c=card(page,34)
    local bg=Instance.new("Frame",c)
    bg.Size=UDim2.new(0,26,0,26); bg.Position=UDim2.new(0,5,0.5,-13)
    bg.BackgroundColor3=TH().hi; bg.BorderSizePixel=0
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,7)
    local ico=Instance.new("TextLabel",bg)
    ico.Size=UDim2.new(1,0,1,0); ico.BackgroundTransparency=1; ico.Text=icon
    ico.TextSize=13; ico.Font=Enum.Font.Gotham; ico.TextColor3=TH().sub
    local lbl=Instance.new("TextLabel",c)
    lbl.Size=UDim2.new(1,-90,1,0); lbl.Position=UDim2.new(0,36,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=TH().text
    lbl.TextSize=11; lbl.Font=Enum.Font.GothamSemibold; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local statusL=Instance.new("TextLabel",c)
    statusL.Size=UDim2.new(0,70,1,0); statusL.Position=UDim2.new(1,-74,0,0)
    statusL.BackgroundTransparency=1; statusL.Text="нажми →"
    statusL.TextColor3=TH().sub; statusL.TextSize=9; statusL.Font=Enum.Font.Gotham
    statusL.TextXAlignment=Enum.TextXAlignment.Right
    local btn=Instance.new("TextButton",c)
    btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.ZIndex=2
    btn.MouseButton1Click:Connect(function()
        if cb then cb(statusL) end
    end)
    return statusL
end

-- Cycler
local function Cycler(page,icon,label,opts,initI,cb)
    local c=card(page,34); local idx=initI or 1
    local bg=Instance.new("Frame",c)
    bg.Size=UDim2.new(0,26,0,26); bg.Position=UDim2.new(0,5,0.5,-13)
    bg.BackgroundColor3=TH().hi; bg.BorderSizePixel=0
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,7)
    local ico=Instance.new("TextLabel",bg)
    ico.Size=UDim2.new(1,0,1,0); ico.BackgroundTransparency=1; ico.Text=icon
    ico.TextSize=13; ico.Font=Enum.Font.Gotham; ico.TextColor3=TH().sub
    local lbl=Instance.new("TextLabel",c)
    lbl.Size=UDim2.new(1,-90,1,0); lbl.Position=UDim2.new(0,36,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=TH().text
    lbl.TextSize=11; lbl.Font=Enum.Font.GothamSemibold; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local vl=Instance.new("TextLabel",c)
    vl.Size=UDim2.new(0,66,1,0); vl.Position=UDim2.new(1,-70,0,0)
    vl.BackgroundTransparency=1; vl.Text=opts[idx]; vl.TextColor3=TH().accent
    vl.TextSize=10; vl.Font=Enum.Font.GothamBold; vl.TextXAlignment=Enum.TextXAlignment.Right
    local btn=Instance.new("TextButton",c)
    btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.ZIndex=2
    btn.MouseButton1Click:Connect(function() idx=idx%#opts+1; vl.Text=opts[idx]; if cb then cb(idx,opts[idx]) end end)
end

-- ══════════════════════════════════════════
--  PAGE: ДВИЖЕНИЕ
-- ══════════════════════════════════════════
local MPage=makePage()
secLbl(MPage,"ДВИЖЕНИЕ")
Toggle(MPage,"↑","Полёт (W/A/S/D + Space/Shift)",false,function(v) S.fly=v end)
Toggle(MPage,"◌","Нет коллизий",false,function(v) S.noclip=v end)
Toggle(MPage,"→","Скорость",false,function(v)
    S.speed=v
    local hum=getHum()
    if hum then hum.WalkSpeed=v and S.speedVal or 16 end
end)
Slider(MPage,"Значение скорости",24,2,150,function(v)
    S.speedVal=v
    if S.speed then local hum=getHum(); if hum then hum.WalkSpeed=v end end
end)
Toggle(MPage,"↟","Бесконечный прыжок",false,function(v) S.infiniteJump=v end)
Toggle(MPage,"⇑","Сила прыжка",false,function(v)
    S.jumpPow=v
    local hum=getHum()
    if hum then hum.JumpPower=v and S.jumpVal or 50 end
end)
Slider(MPage,"Сила прыжка",50,10,250,function(v)
    S.jumpVal=v
    if S.jumpPow then local hum=getHum(); if hum then hum.JumpPower=v end end
end)
secLbl(MPage,"ТЕЛЕПОРТ")
Btn(MPage,"★","Телепорт к точке спауна",function(sl)
    local c=getChar(); if not c then return end
    local spawn=workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn then
        local hrp=getHRP()
        if hrp then hrp.CFrame=spawn.CFrame+Vector3.new(0,3,0); sl.Text="✓ Готово" end
    else sl.Text="✗ Нет спауна" end
end)
Btn(MPage,"⊕","Телепорт к случайному игроку",function(sl)
    local others={}
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=lp then table.insert(others,p) end
    end
    if #others==0 then sl.Text="Нет игроков"; return end
    local t=others[math.random(1,#others)]
    local th=t.Character and t.Character:FindFirstChild("HumanoidRootPart")
    local hrp=getHRP()
    if th and hrp then
        hrp.CFrame=th.CFrame+Vector3.new(4,0,0); sl.Text="→ "..t.DisplayName
    end
end)

-- ══════════════════════════════════════════
--  PAGE: БОЙ
-- ══════════════════════════════════════════
local CPage=makePage()
secLbl(CPage,"АВТО КЛИКЕР")
Toggle(CPage,"⬤","Авто кликер",false,function(v) S.aclick=v end)
Slider(CPage,"Задержка (сек × 100)",5,1,100,function(v) S.aclickDelay=v/100 end)
secLbl(CPage,"АТАКА")
Toggle(CPage,"☠","Анти-АФК",false,function(v)
    S.antiAfk=v
    if v then
        local conn; conn=RS.Heartbeat:Connect(function()
            if not S.antiAfk then conn:Disconnect(); return end
            lp.Idled:Connect(function()
                pcall(function() VIM:SendKeyEvent(true,Enum.KeyCode.W,false,game) end)
                task.wait(0.1)
                pcall(function() VIM:SendKeyEvent(false,Enum.KeyCode.W,false,game) end)
            end)
        end)
    end
end)
secLbl(CPage,"ИНФО")
local killLbl=InfoRow(CPage,"☆","KDA (заглушка)","—")

-- ══════════════════════════════════════════
--  PAGE: ВИЗУАЛ / ESP
-- ══════════════════════════════════════════
local VPage=makePage()
secLbl(VPage,"ESP")
Toggle(VPage,"▣","ESP Вкл",false,function(v) S.espOn=v end)
Toggle(VPage,"□","Бокс",true,function(v) S.espBox=v end)
Toggle(VPage,"◈","Имена",true,function(v) S.espName=v end)
Toggle(VPage,"♡","Здоровье",true,function(v) S.espHP=v end)
Toggle(VPage,"╲","Линии (трасеры)",false,function(v) S.espLines=v end)
Toggle(VPage,"◎","Дистанция",false,function(v) S.espDist=v end)
secLbl(VPage,"ПАРАМЕТРЫ")
Stepper(VPage,"⌐","Закругление бокса",0,0,20,2,function(v) S.espCorner=v end)
Cycler(VPage,"↕","Линия от",{"Низ экрана","Центр"},1,function(i)
    S.espLineFrom=(i==1) and "bottom" or "center"
end)
-- Color picker
do
    local c=card(VPage,46)
    local tl=Instance.new("TextLabel",c)
    tl.Size=UDim2.new(1,0,0,14); tl.Position=UDim2.new(0,10,0,3)
    tl.BackgroundTransparency=1; tl.Text="ЦВЕТ ESP"; tl.TextColor3=TH().sub
    tl.TextSize=8; tl.Font=Enum.Font.GothamBold; tl.TextXAlignment=Enum.TextXAlignment.Left
    local rings={}
    for ci,col in ipairs(ESP_COLORS) do
        local cb=Instance.new("TextButton",c)
        cb.Size=UDim2.new(0,18,0,18); cb.Position=UDim2.new(0,8+(ci-1)*22,0,21)
        cb.BackgroundColor3=col; cb.Text=""; cb.BorderSizePixel=0; cb.ZIndex=2
        Instance.new("UICorner",cb).CornerRadius=UDim.new(1,0)
        local ring=Instance.new("UIStroke",cb); ring.Color=Color3.new(1,1,1); ring.Thickness=(ci==1) and 1.5 or 0
        rings[ci]=ring
        cb.MouseButton1Click:Connect(function()
            S.espColor=col; S.espColorIdx=ci
            for j,r in ipairs(rings) do r.Thickness=(j==ci) and 1.5 or 0 end
        end)
    end
end
secLbl(VPage,"ВИЗУАЛ МИРА")
Toggle(VPage,"⛅","Убрать туман",false,function(v)
    S.noFog=v
    local lighting=game:GetService("Lighting")
    if v then lighting.FogEnd=9e9; lighting.FogStart=9e9 end
end)

-- ══════════════════════════════════════════
--  PAGE: АВТО ФАРМ
-- ══════════════════════════════════════════
local FPage=makePage()
secLbl(FPage,"ТЕЛЕПОРТ ФАРМ")

local ptALabel, ptBLabel
do
    local c,_=card(FPage,60)
    local infoL=Instance.new("TextLabel",c)
    infoL.Size=UDim2.new(1,-10,0,18); infoL.Position=UDim2.new(0,5,0,3)
    infoL.BackgroundTransparency=1; infoL.TextColor3=TH().sub; infoL.TextSize=9
    infoL.Font=Enum.Font.Gotham; infoL.TextXAlignment=Enum.TextXAlignment.Left
    infoL.Text="Установи точку A и B, затем включи фарм"

    ptALabel=Instance.new("TextLabel",c)
    ptALabel.Size=UDim2.new(0.5,-4,0,18); ptALabel.Position=UDim2.new(0,4,0,22)
    ptALabel.BackgroundColor3=TH().hi; ptALabel.BorderSizePixel=0
    Instance.new("UICorner",ptALabel).CornerRadius=UDim.new(0,6)
    ptALabel.Text="A: не задана"; ptALabel.TextColor3=TH().sub; ptALabel.TextSize=9; ptALabel.Font=Enum.Font.GothamBold

    ptBLabel=Instance.new("TextLabel",c)
    ptBLabel.Size=UDim2.new(0.5,-4,0,18); ptBLabel.Position=UDim2.new(0.5,0,0,22)
    ptBLabel.BackgroundColor3=TH().hi; ptBLabel.BorderSizePixel=0
    Instance.new("UICorner",ptBLabel).CornerRadius=UDim.new(0,6)
    ptBLabel.Text="B: не задана"; ptBLabel.TextColor3=TH().sub; ptBLabel.TextSize=9; ptBLabel.Font=Enum.Font.GothamBold

    -- status bar
    local statusBar=Instance.new("Frame",c)
    statusBar.Size=UDim2.new(1,-8,0,12); statusBar.Position=UDim2.new(0,4,0,42)
    statusBar.BackgroundColor3=TH().hi; statusBar.BorderSizePixel=0
    Instance.new("UICorner",statusBar).CornerRadius=UDim.new(0,4)
    local statFill=Instance.new("Frame",statusBar)
    statFill.Size=UDim2.new(0,0,1,0); statFill.BackgroundColor3=TH().accent; statFill.BorderSizePixel=0
    Instance.new("UICorner",statFill).CornerRadius=UDim.new(0,4)

    RS.Heartbeat:Connect(function()
        if S.farmOn and S.farmPtA and S.farmPtB then
            tw(statFill,{Size=UDim2.new(1,0,1,0)},S.farmDelay/2)
            task.delay(S.farmDelay/2,function() statFill.Size=UDim2.new(0,0,1,0) end)
        end
    end)
end

Btn(FPage,"◎","Задать точку A (текущая позиция)",function(sl)
    local hrp=getHRP(); if not hrp then sl.Text="нет персонажа"; return end
    S.farmPtA=hrp.Position
    ptALabel.Text="A: ("..math.floor(hrp.Position.X)..","..math.floor(hrp.Position.Y)..")"
    ptALabel.TextColor3=TH().accent; sl.Text="✓ Сохранено"
end)
Btn(FPage,"◎","Задать точку B (текущая позиция)",function(sl)
    local hrp=getHRP(); if not hrp then sl.Text="нет персонажа"; return end
    S.farmPtB=hrp.Position
    ptBLabel.Text="B: ("..math.floor(hrp.Position.X)..","..math.floor(hrp.Position.Y)..")"
    ptBLabel.TextColor3=TH().accent; sl.Text="✓ Сохранено"
end)
Toggle(FPage,"⟳","Авто фарм (A→B→A...)",false,function(v)
    S.farmOn=v
    if v then
        task.spawn(function()
            while S.farmOn do
                if S.farmPtA then
                    local hrp=getHRP()
                    if hrp then hrp.CFrame=CFrame.new(S.farmPtA+Vector3.new(0,3,0)) end
                    task.wait(S.farmDelay)
                end
                if not S.farmOn then break end
                if S.farmPtB then
                    local hrp=getHRP()
                    if hrp then hrp.CFrame=CFrame.new(S.farmPtB+Vector3.new(0,3,0)) end
                    task.wait(S.farmDelay)
                end
            end
        end)
    end
end)
Slider(FPage,"Задержка (сек)",10,1,50,function(v) S.farmDelay=v/10 end)

-- ══════════════════════════════════════════
--  PAGE: НАСТРОЙКИ
-- ══════════════════════════════════════════
local SPage=makePage()
secLbl(SPage,"ТЕМА")
local themeRefs={}
do
    _ord+=1
    local grid=Instance.new("Frame",SPage)
    grid.Size=UDim2.new(1,-4,0,155); grid.BackgroundTransparency=1
    grid.BorderSizePixel=0; grid.LayoutOrder=_ord
    for i,theme in ipairs(THEMES) do
        local col=(i-1)%2; local row=math.floor((i-1)/2)
        local tc=Instance.new("Frame",grid)
        tc.Size=UDim2.new(0.49,-2,0,68); tc.Position=UDim2.new(col*0.51,0,0,row*76)
        tc.BackgroundColor3=theme.nav; tc.BorderSizePixel=0
        Instance.new("UICorner",tc).CornerRadius=UDim.new(0,10)
        local tcs=Instance.new("UIStroke",tc)
        tcs.Color=(i==TI) and theme.accent or theme.br; tcs.Thickness=(i==TI) and 1.5 or 1
        for si,sc in ipairs({theme.bg,theme.accent,theme.card,theme.hi}) do
            local sw=Instance.new("Frame",tc)
            sw.Size=UDim2.new(0,9,0,9); sw.Position=UDim2.new(0,8+(si-1)*13,0,8)
            sw.BackgroundColor3=sc; sw.BorderSizePixel=0
            Instance.new("UICorner",sw).CornerRadius=UDim.new(1,0)
        end
        local stripe=Instance.new("Frame",tc)
        stripe.Size=UDim2.new(0,3,0,28); stripe.Position=UDim2.new(0,8,0,26)
        stripe.BackgroundColor3=theme.accent; stripe.BorderSizePixel=0
        Instance.new("UICorner",stripe).CornerRadius=UDim.new(1,0)
        local tn=Instance.new("TextLabel",tc)
        tn.Size=UDim2.new(1,-18,0,16); tn.Position=UDim2.new(0,16,0,25)
        tn.BackgroundTransparency=1; tn.Text=theme.name; tn.TextColor3=theme.text
        tn.TextSize=11; tn.Font=Enum.Font.GothamBold; tn.TextXAlignment=Enum.TextXAlignment.Left
        local ts=Instance.new("TextLabel",tc)
        ts.Size=UDim2.new(1,-14,0,12); ts.Position=UDim2.new(0,16,0,43)
        ts.BackgroundTransparency=1; ts.Text=(i==TI) and "● активна" or "нажми"
        ts.TextColor3=(i==TI) and theme.accent or theme.sub
        ts.TextSize=8; ts.Font=Enum.Font.Gotham; ts.TextXAlignment=Enum.TextXAlignment.Left
        themeRefs[i]={card=tc,stroke=tcs,sub=ts}
        local tb=Instance.new("TextButton",tc)
        tb.Size=UDim2.new(1,0,1,0); tb.BackgroundTransparency=1; tb.Text=""; tb.ZIndex=2
        tb.MouseButton1Click:Connect(function()
            if TI==i then return end; TI=i
            for j,ref in ipairs(themeRefs) do
                local th=THEMES[j]
                tw(ref.stroke,{Color=(j==TI) and th.accent or th.br},.25)
                ref.stroke.Thickness=(j==TI) and 1.5 or 1
                ref.sub.Text=(j==TI) and "● активна" or "нажми"
                ref.sub.TextColor3=(j==TI) and th.accent or th.sub
            end
            tw(Win,{BackgroundColor3=TH().bg},.35)
            tw(WinStroke,{Color=TH().br},.35)
            tw(Hdr,{BackgroundColor3=TH().nav},.35)
            tw(HFix,{BackgroundColor3=TH().nav},.35)
            tw(Nav,{BackgroundColor3=TH().nav},.35)
            tw(NFix,{BackgroundColor3=TH().nav},.35)
            tw(NFix2,{BackgroundColor3=TH().nav},.35)
            tw(NavDiv,{BackgroundColor3=TH().br},.35)
            TitleL.TextColor3=TH().text; NavVer.TextColor3=TH().sub
        end)
    end
end
secLbl(SPage,"ГОРЯЧИЕ КЛАВИШИ")
do
    local c=card(SPage,44)
    for i,row in ipairs({{"ПР. SHIFT","скрыть / показать"},{"W/A/S/D","лететь (когда Fly вкл)"},{"SPACE / SHIFT","вверх / вниз при полёте"}}) do
        local r=Instance.new("Frame",c)
        r.Size=UDim2.new(1,-10,0,12); r.Position=UDim2.new(0,5,0,2+(i-1)*13)
        r.BackgroundTransparency=1; r.BorderSizePixel=0
        local k=Instance.new("TextLabel",r); k.Size=UDim2.new(0,90,1,0); k.BackgroundTransparency=1
        k.Text=row[1]; k.TextColor3=TH().accent; k.TextSize=8; k.Font=Enum.Font.GothamBold; k.TextXAlignment=Enum.TextXAlignment.Left
        local v=Instance.new("TextLabel",r); v.Size=UDim2.new(1,-94,1,0); v.Position=UDim2.new(0,94,0,0)
        v.BackgroundTransparency=1; v.Text=row[2]; v.TextColor3=TH().sub; v.TextSize=8
        v.Font=Enum.Font.Gotham; v.TextXAlignment=Enum.TextXAlignment.Left
    end
end

-- ══════════════════════════════════════════
--  NAV BUTTONS
-- ══════════════════════════════════════════
local TABS={
    {ico="↑", lbl="Движение", page=MPage},
    {ico="⚔", lbl="Бой",      page=CPage},
    {ico="▣", lbl="Визуал",   page=VPage},
    {ico="◎", lbl="Авто Фарм",page=FPage},
    {ico="⚙", lbl="Настройки",page=SPage},
}
local activeTab=1; local tabRefs={}

for i,td in ipairs(TABS) do
    local btn=Instance.new("TextButton",Nav)
    btn.Size=UDim2.new(1,-8,0,34); btn.Position=UDim2.new(0,4,0,16+(i-1)*38)
    btn.BackgroundColor3=(i==1) and TH().hi or Color3.new(0,0,0)
    btn.BackgroundTransparency=(i==1) and 0 or 1
    btn.Text=""; btn.BorderSizePixel=0; btn.ZIndex=3
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)

    local icoL=Instance.new("TextLabel",btn)
    icoL.Size=UDim2.new(0,24,1,0); icoL.Position=UDim2.new(0,6,0,0)
    icoL.BackgroundTransparency=1; icoL.Text=td.ico
    icoL.TextColor3=(i==1) and TH().accent or TH().sub
    icoL.TextSize=14; icoL.Font=Enum.Font.GothamBold; icoL.ZIndex=4

    local lblL=Instance.new("TextLabel",btn)
    lblL.Size=UDim2.new(1,-34,1,0); lblL.Position=UDim2.new(0,32,0,0)
    lblL.BackgroundTransparency=1; lblL.Text=td.lbl
    lblL.TextColor3=(i==1) and TH().text or TH().sub
    lblL.TextSize=11; lblL.Font=(i==1) and Enum.Font.GothamBold or Enum.Font.Gotham
    lblL.TextXAlignment=Enum.TextXAlignment.Left; lblL.ZIndex=4

    local ind=Instance.new("Frame",btn)
    ind.Size=UDim2.new(0,3,0,18); ind.Position=UDim2.new(1,-3,0.5,-9)
    ind.BackgroundColor3=TH().accent
    ind.BackgroundTransparency=(i==1) and 0 or 1
    ind.BorderSizePixel=0
    Instance.new("UICorner",ind).CornerRadius=UDim.new(1,0)

    tabRefs[i]={btn=btn,ico=icoL,lbl=lblL,ind=ind}

    btn.MouseButton1Click:Connect(function()
        if i==activeTab then return end
        local prev=tabRefs[activeTab]
        tw(prev.btn,{BackgroundTransparency=1},.15)
        tw(prev.ico,{TextColor3=TH().sub},.15); prev.lbl.Font=Enum.Font.Gotham
        tw(prev.lbl,{TextColor3=TH().sub},.15)
        tw(prev.ind,{BackgroundTransparency=1},.15)
        TABS[activeTab].page.Visible=false
        activeTab=i
        tw(btn,{BackgroundTransparency=0,BackgroundColor3=TH().hi},.15)
        tw(icoL,{TextColor3=TH().accent},.15); lblL.Font=Enum.Font.GothamBold
        tw(lblL,{TextColor3=TH().text},.15)
        tw(ind,{BackgroundTransparency=0,BackgroundColor3=TH().accent},.15)
        td.page.Visible=true
    end)
end
TABS[1].page.Visible=true

-- ══════════════════════════════════════════
--  OPEN / CLOSE
-- ══════════════════════════════════════════
local isOpen=true

local OpenBtn=Instance.new("TextButton",SGui)
OpenBtn.Size=UDim2.new(0,96,0,24); OpenBtn.Position=UDim2.new(0,8,0,8)
OpenBtn.BackgroundColor3=TH().nav; OpenBtn.Text="▶  Vape Ext"
OpenBtn.TextColor3=TH().accent; OpenBtn.TextSize=10
OpenBtn.Font=Enum.Font.GothamBold; OpenBtn.BorderSizePixel=0; OpenBtn.Visible=false; OpenBtn.ZIndex=999
Instance.new("UICorner",OpenBtn).CornerRadius=UDim.new(0,8)
local OPS=Instance.new("UIStroke",OpenBtn); OPS.Color=TH().accent; OPS.Thickness=1

local function closeWin()
    if not isOpen then return end; isOpen=false
    tw(Win,{Position=UDim2.new(0.5,-180,1.1,0)},.3,Enum.EasingStyle.Back,Enum.EasingDirection.In)
    task.delay(.32,function()
        if Win and Win.Parent then Win.Visible=false end
        if OpenBtn and OpenBtn.Parent then OpenBtn.Visible=true end
    end)
end
local function openWin()
    if isOpen then return end; isOpen=true
    OpenBtn.Visible=false; Win.Visible=true
    Win.Position=UDim2.new(0.5,-180,1.1,0)
    tw(Win,{Position=UDim2.new(0.5,-180,0.5,-215)},.4,Enum.EasingStyle.Back)
end

CloseBtn.MouseButton1Click:Connect(closeWin)
OpenBtn.MouseButton1Click:Connect(openWin)
UIS.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.RightShift then
        if isOpen then closeWin() else openWin() end
    end
end)

-- ══════════════════════════════════════════
--  FLY
-- ══════════════════════════════════════════
RS.Heartbeat:Connect(function()
    local hum=getHum(); local hrp=getHRP()
    if not hum or not hrp then return end
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

-- ══════════════════════════════════════════
--  NOCLIP
-- ══════════════════════════════════════════
RS.Stepped:Connect(function()
    if not S.noclip then return end
    local c=getChar(); if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide=false end
    end
end)

-- ══════════════════════════════════════════
--  INFINITE JUMP
-- ══════════════════════════════════════════
UIS.JumpRequest:Connect(function()
    if not S.infiniteJump then return end
    local hum=getHum()
    if hum and hum.FloorMaterial==Enum.Material.Air then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ══════════════════════════════════════════
--  AUTO CLICKER
-- ══════════════════════════════════════════
task.spawn(function()
    while true do
        if S.aclick then
            local pos=UIS:GetMouseLocation()
            pcall(function()
                VIM:SendMouseButtonEvent(pos.X,pos.Y,0,true,game,0)
                task.wait(0.01)
                VIM:SendMouseButtonEvent(pos.X,pos.Y,0,false,game,0)
            end)
            task.wait(S.aclickDelay)
        else
            task.wait(0.1)
        end
    end
end)

-- ══════════════════════════════════════════
--  ESP — Drawing API (точный, не на голове)
-- ══════════════════════════════════════════
local pool={}

local function newLine(col)
    local ok,l=pcall(function()
        local d=Drawing.new("Line"); d.Thickness=1.2; d.Color=col
        d.Transparency=1; d.Visible=false; return d
    end)
    return ok and l or nil
end
local function newSquare(col,corner)
    local ok,s=pcall(function()
        local d=Drawing.new("Square"); d.Thickness=1.2; d.Color=col
        d.Filled=false; d.Transparency=1; d.Visible=false; return d
    end)
    return ok and s or nil
end
local function newText(col,sz)
    local ok,t=pcall(function()
        local d=Drawing.new("Text"); d.Color=col; d.Size=sz or 12
        d.Font=Drawing.Fonts.Plex; d.Outline=true; d.Visible=false; return d
    end)
    return ok and t or nil
end

local function removeEsp(uid)
    local o=pool[uid]; if not o then return end
    for _,d in pairs(o) do pcall(function() d:Remove() end) end
    pool[uid]=nil
end
local function clearEsp() for uid in pairs(pool) do removeEsp(uid) end end

RS.RenderStepped:Connect(function()
    if not S.espOn then clearEsp(); return end

    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==lp then continue end
        local char=plr.Character
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        local head=char and char:FindFirstChild("Head")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not head or not hum or hum.Health<=0 then
            removeEsp(plr.UserId); continue
        end

        -- Project head top and feet to screen
        local headTop=head.Position+Vector3.new(0,head.Size.Y/2+0.1,0)
        local feetPos=hrp.Position-Vector3.new(0,3,0)

        local sHead,visHead=cam:WorldToViewportPoint(headTop)
        local sFeet,visFeet=cam:WorldToViewportPoint(feetPos)

        if not visHead and not visFeet then removeEsp(plr.UserId); continue end

        -- Calculate box dimensions from projected points
        local boxTop    = sHead.Y
        local boxBottom = sFeet.Y
        local boxHeight = math.abs(boxBottom - boxTop)
        local boxWidth  = boxHeight * 0.55
        local boxCenterX= sHead.X
        local boxLeft   = boxCenterX - boxWidth/2
        local boxRight  = boxCenterX + boxWidth/2
        local col       = S.espColor

        -- Build drawing objects if missing
        if not pool[plr.UserId] then
            pool[plr.UserId]={
                box  = newSquare(col, S.espCorner),
                name = newText(col, 11),
                hp   = newText(Color3.fromRGB(80,220,80), 10),
                dist = newText(Color3.fromRGB(180,180,200), 9),
                line = newLine(col),
            }
        end

        local o=pool[plr.UserId]

        -- Box
        if o.box then
            o.box.Visible     = S.espBox
            o.box.Color       = col
            o.box.Position    = Vector2.new(boxLeft, boxTop)
            o.box.Size        = Vector2.new(boxWidth, boxHeight)
        end

        -- Name (above box)
        if o.name then
            o.name.Visible  = S.espName
            o.name.Color    = col
            o.name.Text     = plr.DisplayName
            o.name.Position = Vector2.new(boxCenterX, boxTop - 14)
            o.name.Center   = true
        end

        -- HP (below box)
        if o.hp then
            local hp=hum.Health; local mx=math.max(hum.MaxHealth,1); local r=hp/mx
            o.hp.Visible  = S.espHP
            o.hp.Color    = Color3.fromRGB(math.floor(255*(1-r)),math.floor(55+200*r),55)
            o.hp.Text     = math.floor(hp).."/"..math.floor(mx)
            o.hp.Position = Vector2.new(boxCenterX, boxBottom+2)
            o.hp.Center   = true
        end

        -- Distance
        if o.dist then
            local myHRP=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            local dist=myHRP and math.floor((hrp.Position-myHRP.Position).Magnitude) or 0
            o.dist.Visible  = S.espDist
            o.dist.Text     = dist.."m"
            o.dist.Position = Vector2.new(boxRight+3, boxTop)
            o.dist.Center   = false
        end

        -- Tracer line
        if o.line then
            o.line.Visible = S.espLines
            o.line.Color   = col
            if S.espLines then
                local vp=cam.ViewportSize
                o.line.From = Vector2.new(vp.X/2,(S.espLineFrom=="bottom") and vp.Y or vp.Y/2)
                o.line.To   = Vector2.new(boxCenterX, boxBottom)
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(p) removeEsp(p.UserId) end)

-- ══════════════════════════════════════════
--  STARTUP ANIMATION
-- ══════════════════════════════════════════
Win.Visible=true
Win.Position=UDim2.new(0.5,-180,1.5,0)
tw(Win,{Position=UDim2.new(0.5,-180,0.5,-215)},.5,Enum.EasingStyle.Back)

print("[Vape External v4.0] ✓  ПР.SHIFT = скрыть/показать")
