--[[
╔══════════════════════════════════════════╗
║        Vape External  v5.0               ║
║   ПР. SHIFT  =  скрыть / показать        ║
╚══════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local RS      = game:GetService("RunService")
local TS      = game:GetService("TweenService")
local Stats   = game:GetService("Stats")

local lp  = Players.LocalPlayer
local cam = workspace.CurrentCamera
if not lp.Character then lp.CharacterAdded:Wait() end

-- ══════════════════════════════════════════════════
--  THEMES
-- ══════════════════════════════════════════════════
local THEMES = {
    { id="dark",  name="Тёмная",
      bg=Color3.fromRGB(11,11,16),  nav=Color3.fromRGB(16,16,24),
      card=Color3.fromRGB(22,22,34),hi=Color3.fromRGB(28,28,44),
      accent=Color3.fromRGB(78,152,255),text=Color3.fromRGB(224,230,246),
      sub=Color3.fromRGB(82,88,114),br=Color3.fromRGB(30,30,52),
      anim="none",   snow=false },
    { id="dusk",  name="Сумерки",
      bg=Color3.fromRGB(9,7,18),    nav=Color3.fromRGB(13,10,26),
      card=Color3.fromRGB(19,15,34),hi=Color3.fromRGB(26,20,46),
      accent=Color3.fromRGB(148,80,255),text=Color3.fromRGB(215,210,242),
      sub=Color3.fromRGB(96,78,134),br=Color3.fromRGB(36,26,62),
      anim="pulse",  snow=false },
    { id="coal",  name="Уголь",
      bg=Color3.fromRGB(12,12,12),  nav=Color3.fromRGB(17,17,17),
      card=Color3.fromRGB(24,24,24),hi=Color3.fromRGB(30,30,30),
      accent=Color3.fromRGB(255,58,58),text=Color3.fromRGB(236,236,236),
      sub=Color3.fromRGB(108,108,108),br=Color3.fromRGB(40,40,40),
      anim="ember",  snow=false },
    { id="dawn",  name="Рассвет",
      bg=Color3.fromRGB(8,14,22),   nav=Color3.fromRGB(10,20,34),
      card=Color3.fromRGB(14,27,44),hi=Color3.fromRGB(18,34,58),
      accent=Color3.fromRGB(0,198,168),text=Color3.fromRGB(194,225,236),
      sub=Color3.fromRGB(62,114,140),br=Color3.fromRGB(18,38,64),
      anim="drift",  snow=false },
    { id="snow",  name="Снег",
      bg=Color3.fromRGB(16,22,34),  nav=Color3.fromRGB(22,30,46),
      card=Color3.fromRGB(28,38,56),hi=Color3.fromRGB(34,46,68),
      accent=Color3.fromRGB(155,200,255),text=Color3.fromRGB(228,238,255),
      sub=Color3.fromRGB(108,130,168),br=Color3.fromRGB(42,54,78),
      anim="snow",   snow=true },
}
local TI = 1
local function TH() return THEMES[TI] end

-- ══════════════════════════════════════════════════
--  STATE
-- ══════════════════════════════════════════════════
local S = {
    -- Move
    fly=false, flySpeed=60, noclip=false,
    speed=false, speedVal=24,
    infJump=false, jumpPow=false, jumpVal=50,
    -- ESP
    espOn=false, espBox=true, espName=true, espHP=true,
    espSkel=false, espLines=false, espDist=false,
    espCorner=0, espColor=Color3.fromRGB(78,152,255), espCI=1,
    espLineFrom="bottom",
    -- Aim
    aimOn=false, aimKey="rmb", aimFOV=120, aimSmooth=0.18,
    aimPart="Head", aimMode="nearest", aimPred=false, aimPredVal=0.12,
    aimTeam=false, aimVisible=false, aimFOVCircle=true,
    -- ATK
    aclick=false, aclickCps=10,
    farmOn=false, farmPtA=nil, farmPtB=nil, farmDelay=1.0,
    -- Misc
    antiAfk=false, noFog=false, nChat=false,
}

local ESP_COLORS = {
    Color3.fromRGB(78,152,255), Color3.fromRGB(255,60,60),
    Color3.fromRGB(45,215,95),  Color3.fromRGB(255,215,50),
    Color3.fromRGB(255,255,255),Color3.fromRGB(0,208,182),
    Color3.fromRGB(255,120,40), Color3.fromRGB(210,75,210),
}

-- ══════════════════════════════════════════════════
--  METRICS
-- ══════════════════════════════════════════════════
local fpsVal, pingVal = 60, 0
do
    local fc, lt = 0, tick()
    RS.Heartbeat:Connect(function()
        fc += 1
        local n = tick()
        if n - lt >= 0.5 then fpsVal = math.floor(fc/(n-lt)); fc,lt = 0,n end
        pcall(function() pingVal = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
    end)
end

-- ══════════════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════════════
local function tw(o,p,t,s,d)
    if not o or not o.Parent then return end
    TS:Create(o,TweenInfo.new(t or .2,s or Enum.EasingStyle.Quart,d or Enum.EasingDirection.Out),p):Play()
end
local function getChar() local ok,c=pcall(function() return lp.Character end); return ok and c end
local function getHRP()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()  local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end

-- ══════════════════════════════════════════════════
--  CLEANUP + SCREENGUI
-- ══════════════════════════════════════════════════
pcall(function() local g=lp.PlayerGui:FindFirstChild("VapeExt"); if g then g:Destroy() end end)
task.wait(.05)

local SGui = Instance.new("ScreenGui")
SGui.Name="VapeExt"; SGui.ResetOnSpawn=false; SGui.DisplayOrder=999
SGui.IgnoreGuiInset=true; SGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SGui.Parent=lp.PlayerGui

-- ══════════════════════════════════════════════════
--  MAIN WINDOW  490 × 490  (square)
-- ══════════════════════════════════════════════════
local Win = Instance.new("Frame",SGui)
Win.Name="Win"; Win.Size=UDim2.new(0,490,0,490)
Win.Position=UDim2.new(0.5,-245,0.5,-245)
Win.BackgroundColor3=TH().bg; Win.BorderSizePixel=0
Win.Active=true; Win.Draggable=true; Win.ClipsDescendants=false
Instance.new("UICorner",Win).CornerRadius=UDim.new(0,12)
local WStroke=Instance.new("UIStroke",Win); WStroke.Color=TH().br; WStroke.Thickness=1

-- Shadow
local Shad=Instance.new("Frame",Win)
Shad.Size=UDim2.new(1,28,1,28); Shad.Position=UDim2.new(0,-14,0,10)
Shad.BackgroundColor3=Color3.new(0,0,0); Shad.BackgroundTransparency=.72
Shad.BorderSizePixel=0; Shad.ZIndex=0
Instance.new("UICorner",Shad).CornerRadius=UDim.new(0,20)

-- ── Snow layer (above content, below buttons) ───────
local SnowLayer = Instance.new("Frame",Win)
SnowLayer.Size=UDim2.new(1,0,1,0); SnowLayer.BackgroundTransparency=1
SnowLayer.BorderSizePixel=0; SnowLayer.ZIndex=6; SnowLayer.ClipsDescendants=true
SnowLayer.Visible=false

-- ══════════════════════════════════════════════════
--  HEADER  h=40
-- ══════════════════════════════════════════════════
local Hdr = Instance.new("Frame",Win)
Hdr.Size=UDim2.new(1,0,0,40); Hdr.BackgroundColor3=TH().nav
Hdr.BorderSizePixel=0; Hdr.ZIndex=3
Instance.new("UICorner",Hdr).CornerRadius=UDim.new(0,12)
local HFix=Instance.new("Frame",Hdr); HFix.Size=UDim2.new(1,0,0,12)
HFix.Position=UDim2.new(0,0,1,-12); HFix.BackgroundColor3=TH().nav; HFix.BorderSizePixel=0; HFix.ZIndex=3

local GreenDot=Instance.new("Frame",Hdr)
GreenDot.Size=UDim2.new(0,7,0,7); GreenDot.Position=UDim2.new(0,13,0.5,-3.5)
GreenDot.BackgroundColor3=Color3.fromRGB(46,215,90); GreenDot.BorderSizePixel=0; GreenDot.ZIndex=4
Instance.new("UICorner",GreenDot).CornerRadius=UDim.new(1,0)

local TitleL=Instance.new("TextLabel",Hdr)
TitleL.Size=UDim2.new(0,140,1,0); TitleL.Position=UDim2.new(0,25,0,0)
TitleL.BackgroundTransparency=1; TitleL.Text="Vape External"
TitleL.TextColor3=TH().text; TitleL.TextSize=13; TitleL.Font=Enum.Font.GothamBold
TitleL.TextXAlignment=Enum.TextXAlignment.Left; TitleL.ZIndex=4

local FpsL=Instance.new("TextLabel",Hdr)
FpsL.Size=UDim2.new(0,68,1,0); FpsL.Position=UDim2.new(0,168,0,0)
FpsL.BackgroundTransparency=1; FpsL.Text="FPS: 60"; FpsL.TextSize=10
FpsL.Font=Enum.Font.GothamBold; FpsL.TextXAlignment=Enum.TextXAlignment.Left; FpsL.ZIndex=4

local PingL=Instance.new("TextLabel",Hdr)
PingL.Size=UDim2.new(0,80,1,0); PingL.Position=UDim2.new(0,236,0,0)
PingL.BackgroundTransparency=1; PingL.Text="PING: 0ms"; PingL.TextSize=10
PingL.Font=Enum.Font.GothamBold; PingL.TextXAlignment=Enum.TextXAlignment.Left; PingL.ZIndex=4

local CloseBtn=Instance.new("TextButton",Hdr)
CloseBtn.Size=UDim2.new(0,22,0,22); CloseBtn.Position=UDim2.new(1,-28,0.5,-11)
CloseBtn.BackgroundColor3=Color3.fromRGB(58,20,20); CloseBtn.Text="✕"
CloseBtn.TextColor3=Color3.fromRGB(200,65,65); CloseBtn.TextSize=10
CloseBtn.Font=Enum.Font.GothamBold; CloseBtn.BorderSizePixel=0; CloseBtn.ZIndex=10
Instance.new("UICorner",CloseBtn).CornerRadius=UDim.new(0,6)

RS.Heartbeat:Connect(function()
    FpsL.Text="FPS: "..fpsVal
    FpsL.TextColor3=fpsVal>=50 and Color3.fromRGB(46,215,90) or fpsVal>=30 and Color3.fromRGB(255,215,50) or Color3.fromRGB(255,65,65)
    PingL.Text="PING: "..pingVal.."ms"
    PingL.TextColor3=pingVal<=80 and Color3.fromRGB(46,215,90) or pingVal<=160 and Color3.fromRGB(255,215,50) or Color3.fromRGB(255,65,65)
end)

-- ══════════════════════════════════════════════════
--  TOP TAB BAR  h=32
-- ══════════════════════════════════════════════════
local TabBar=Instance.new("Frame",Win)
TabBar.Size=UDim2.new(1,-16,0,32); TabBar.Position=UDim2.new(0,8,0,44)
TabBar.BackgroundColor3=TH().nav; TabBar.BorderSizePixel=0; TabBar.ZIndex=3
Instance.new("UICorner",TabBar).CornerRadius=UDim.new(0,9)
Instance.new("UIListLayout",TabBar).FillDirection=Enum.FillDirection.Horizontal

-- ══════════════════════════════════════════════════
--  CONTENT  h=406
-- ══════════════════════════════════════════════════
local Content=Instance.new("Frame",Win)
Content.Size=UDim2.new(1,-16,1,-86); Content.Position=UDim2.new(0,8,0,80)
Content.BackgroundTransparency=1; Content.ClipsDescendants=true

-- ══════════════════════════════════════════════════
--  COMPONENT BUILDERS
-- ══════════════════════════════════════════════════
local _ord=0; local function nO() _ord+=1; return _ord end

local function makePage(scroll)
    if scroll==false then
        local f=Instance.new("Frame",Content)
        f.Size=UDim2.new(1,0,1,0); f.BackgroundTransparency=1
        f.Visible=false; f.BorderSizePixel=0
        return f
    end
    local sf=Instance.new("ScrollingFrame",Content)
    sf.Size=UDim2.new(1,0,1,0); sf.CanvasSize=UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize=Enum.AutomaticSize.Y
    sf.ScrollBarThickness=2; sf.ScrollBarImageColor3=TH().br
    sf.BackgroundTransparency=1; sf.Visible=false; sf.BorderSizePixel=0
    local pad=Instance.new("UIPadding",sf)
    pad.PaddingTop=UDim.new(0,2); pad.PaddingRight=UDim.new(0,4); pad.PaddingBottom=UDim.new(0,10)
    local lay=Instance.new("UIListLayout",sf); lay.Padding=UDim.new(0,3)
    return sf
end

local function secLbl(page,txt)
    local f=Instance.new("Frame",page)
    f.Size=UDim2.new(1,0,0,18); f.BackgroundTransparency=1; f.BorderSizePixel=0; f.LayoutOrder=nO()
    local line=Instance.new("Frame",f); line.Size=UDim2.new(1,0,0,1); line.Position=UDim2.new(0,0,1,-1)
    line.BackgroundColor3=TH().br; line.BorderSizePixel=0
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,-8,1,-2); l.Position=UDim2.new(0,4,0,0)
    l.BackgroundTransparency=1; l.Text=txt; l.TextColor3=TH().sub
    l.TextSize=8; l.Font=Enum.Font.GothamBold; l.TextXAlignment=Enum.TextXAlignment.Left
end

local function card(page,h,lo)
    local f=Instance.new("Frame",page)
    f.Size=UDim2.new(1,-2,0,h); f.BackgroundColor3=TH().card; f.BorderSizePixel=0
    f.LayoutOrder=lo or nO()
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,8)
    local st=Instance.new("UIStroke",f); st.Color=TH().br; st.Thickness=1
    return f,st
end

-- Toggle
local function Toggle(page,icon,label,init,cb)
    local c=card(page,34)
    local ibg=Instance.new("Frame",c)
    ibg.Size=UDim2.new(0,24,0,24); ibg.Position=UDim2.new(0,6,0.5,-12)
    ibg.BackgroundColor3=TH().hi; ibg.BorderSizePixel=0
    Instance.new("UICorner",ibg).CornerRadius=UDim.new(0,7)
    local ico=Instance.new("TextLabel",ibg)
    ico.Size=UDim2.new(1,0,1,0); ico.BackgroundTransparency=1
    ico.Text=icon; ico.TextSize=12; ico.Font=Enum.Font.Gotham; ico.TextColor3=TH().sub
    local lbl=Instance.new("TextLabel",c)
    lbl.Size=UDim2.new(1,-70,1,0); lbl.Position=UDim2.new(0,35,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=TH().text
    lbl.TextSize=11; lbl.Font=Enum.Font.GothamSemibold; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local pill=Instance.new("Frame",c)
    pill.Size=UDim2.new(0,32,0,17); pill.Position=UDim2.new(1,-38,0.5,-8.5)
    pill.BorderSizePixel=0; Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
    local dot=Instance.new("Frame",pill); dot.Size=UDim2.new(0,11,0,11); dot.BorderSizePixel=0
    Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
    local val=init or false
    local function refresh()
        if val then
            tw(pill,{BackgroundColor3=TH().accent},.16); tw(dot,{Position=UDim2.new(0,17,0.5,-5.5),BackgroundColor3=Color3.new(1,1,1)},.16)
            tw(ibg,{BackgroundColor3=TH().accent},.16); tw(ico,{TextColor3=Color3.new(1,1,1)},.16)
        else
            tw(pill,{BackgroundColor3=TH().br},.16); tw(dot,{Position=UDim2.new(0,3,0.5,-5.5),BackgroundColor3=TH().sub},.16)
            tw(ibg,{BackgroundColor3=TH().hi},.16); tw(ico,{TextColor3=TH().sub},.16)
        end
    end; refresh()
    local btn=Instance.new("TextButton",c); btn.Size=UDim2.new(1,0,1,0)
    btn.BackgroundTransparency=1; btn.Text=""; btn.ZIndex=2
    btn.MouseButton1Click:Connect(function() val=not val; refresh(); if cb then cb(val) end end)
    return {pill=pill,dot=dot,ibg=ibg,ico=ico,refresh=refresh}
end

-- Slider
local _drg=nil
UIS.InputChanged:Connect(function(i)
    if not _drg or i.UserInputType~=Enum.UserInputType.MouseMovement then return end
    local d=_drg; if not d.tr or not d.tr.Parent then _drg=nil; return end
    local p=math.clamp((i.Position.X-d.tr.AbsolutePosition.X)/math.max(d.tr.AbsoluteSize.X,1),0,1)
    local v=math.floor(d.min+p*(d.max-d.min))
    d.fill.Size=UDim2.new(p,0,1,0); d.th.Position=UDim2.new(p,-5,0.5,-5)
    d.vl.Text=tostring(v); if d.cb then d.cb(v) end
end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _drg=nil end end)

local function Slider(page,label,init,minV,maxV,fmt,cb)
    local c=card(page,40)
    local ll=Instance.new("TextLabel",c); ll.Size=UDim2.new(0.62,0,0,18); ll.Position=UDim2.new(0,10,0,4)
    ll.BackgroundTransparency=1; ll.Text=label; ll.TextColor3=TH().text; ll.TextSize=11
    ll.Font=Enum.Font.GothamSemibold; ll.TextXAlignment=Enum.TextXAlignment.Left
    local vl=Instance.new("TextLabel",c); vl.Size=UDim2.new(0.36,0,0,18); vl.Position=UDim2.new(0.64,0,0,4)
    vl.BackgroundTransparency=1; vl.Text=(fmt or "%d"):format(init); vl.TextColor3=TH().accent
    vl.TextSize=11; vl.Font=Enum.Font.GothamBold; vl.TextXAlignment=Enum.TextXAlignment.Right
    local tr=Instance.new("Frame",c); tr.Size=UDim2.new(1,-18,0,4); tr.Position=UDim2.new(0,9,0,30)
    tr.BackgroundColor3=TH().hi; tr.BorderSizePixel=0
    Instance.new("UICorner",tr).CornerRadius=UDim.new(1,0)
    local pct=math.clamp((init-minV)/(maxV-minV),0,1)
    local fill=Instance.new("Frame",tr); fill.Size=UDim2.new(pct,0,1,0)
    fill.BackgroundColor3=TH().accent; fill.BorderSizePixel=0
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local th=Instance.new("Frame",tr); th.Size=UDim2.new(0,10,0,10); th.Position=UDim2.new(pct,-5,0.5,-5)
    th.BackgroundColor3=Color3.new(1,1,1); th.BorderSizePixel=0; th.ZIndex=3
    Instance.new("UICorner",th).CornerRadius=UDim.new(1,0)
    local hit=Instance.new("TextButton",tr); hit.Size=UDim2.new(1,0,0,24); hit.Position=UDim2.new(0,0,0.5,-12)
    hit.BackgroundTransparency=1; hit.Text=""; hit.ZIndex=4
    hit.MouseButton1Down:Connect(function() _drg={tr=tr,fill=fill,th=th,vl=vl,min=minV,max=maxV,cb=function(v) vl.Text=(fmt or "%d"):format(v); if cb then cb(v) end end} end)
end

-- Cycler
local function Cycler(page,icon,label,opts,initI,cb)
    local c=card(page,34); local idx=initI or 1
    local ibg=Instance.new("Frame",c); ibg.Size=UDim2.new(0,24,0,24); ibg.Position=UDim2.new(0,6,0.5,-12)
    ibg.BackgroundColor3=TH().hi; ibg.BorderSizePixel=0; Instance.new("UICorner",ibg).CornerRadius=UDim.new(0,7)
    local ico=Instance.new("TextLabel",ibg); ico.Size=UDim2.new(1,0,1,0); ico.BackgroundTransparency=1
    ico.Text=icon; ico.TextSize=12; ico.Font=Enum.Font.Gotham; ico.TextColor3=TH().sub
    local ll=Instance.new("TextLabel",c); ll.Size=UDim2.new(1,-88,1,0); ll.Position=UDim2.new(0,35,0,0)
    ll.BackgroundTransparency=1; ll.Text=label; ll.TextColor3=TH().text; ll.TextSize=11
    ll.Font=Enum.Font.GothamSemibold; ll.TextXAlignment=Enum.TextXAlignment.Left
    local vl=Instance.new("TextLabel",c); vl.Size=UDim2.new(0,60,1,0); vl.Position=UDim2.new(1,-64,0,0)
    vl.BackgroundTransparency=1; vl.Text=opts[idx]; vl.TextColor3=TH().accent; vl.TextSize=10
    vl.Font=Enum.Font.GothamBold; vl.TextXAlignment=Enum.TextXAlignment.Right
    local btn=Instance.new("TextButton",c); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.ZIndex=2
    btn.MouseButton1Click:Connect(function() idx=idx%#opts+1; vl.Text=opts[idx]; if cb then cb(idx,opts[idx]) end end)
end

-- Action button
local function ActionBtn(page,icon,label,cb)
    local c=card(page,34)
    local ibg=Instance.new("Frame",c); ibg.Size=UDim2.new(0,24,0,24); ibg.Position=UDim2.new(0,6,0.5,-12)
    ibg.BackgroundColor3=TH().hi; ibg.BorderSizePixel=0; Instance.new("UICorner",ibg).CornerRadius=UDim.new(0,7)
    local ico=Instance.new("TextLabel",ibg); ico.Size=UDim2.new(1,0,1,0); ico.BackgroundTransparency=1
    ico.Text=icon; ico.TextSize=12; ico.Font=Enum.Font.Gotham; ico.TextColor3=TH().sub
    local ll=Instance.new("TextLabel",c); ll.Size=UDim2.new(1,-88,1,0); ll.Position=UDim2.new(0,35,0,0)
    ll.BackgroundTransparency=1; ll.Text=label; ll.TextColor3=TH().text; ll.TextSize=11
    ll.Font=Enum.Font.GothamSemibold; ll.TextXAlignment=Enum.TextXAlignment.Left
    local sl=Instance.new("TextLabel",c); sl.Size=UDim2.new(0,66,1,0); sl.Position=UDim2.new(1,-70,0,0)
    sl.BackgroundTransparency=1; sl.Text="нажми →"; sl.TextColor3=TH().sub; sl.TextSize=9; sl.Font=Enum.Font.Gotham; sl.TextXAlignment=Enum.TextXAlignment.Right
    local btn=Instance.new("TextButton",c); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.ZIndex=2
    btn.MouseButton1Click:Connect(function() if cb then cb(sl) end end)
    btn.MouseEnter:Connect(function() tw(c,{BackgroundColor3=TH().hi},.1) end)
    btn.MouseLeave:Connect(function() tw(c,{BackgroundColor3=TH().card},.1) end)
    return sl
end

-- ══════════════════════════════════════════════════
--  PAGE 1 — MOVEMENT
-- ══════════════════════════════════════════════════
local MovePg=makePage()
secLbl(MovePg,"ДВИЖЕНИЕ")
Toggle(MovePg,"↑","Полёт  (W A S D + Space / Shift)",false,function(v) S.fly=v end)
Toggle(MovePg,"◌","Нет коллизий",false,function(v) S.noclip=v end)
Toggle(MovePg,"→","Скорость",false,function(v)
    S.speed=v; local h=getHum(); if h then h.WalkSpeed=v and S.speedVal or 16 end
end)
Slider(MovePg,"Значение скорости",24,2,150,nil,function(v) S.speedVal=v; if S.speed then local h=getHum(); if h then h.WalkSpeed=v end end end)
Toggle(MovePg,"⇑","Бесконечный прыжок",false,function(v) S.infJump=v end)
Toggle(MovePg,"↟","Сила прыжка",false,function(v)
    S.jumpPow=v; local h=getHum(); if h then h.JumpPower=v and S.jumpVal or 50 end
end)
Slider(MovePg,"Сила прыжка",50,10,300,nil,function(v)
    S.jumpVal=v; if S.jumpPow then local h=getHum(); if h then h.JumpPower=v end end
end)
secLbl(MovePg,"ТЕЛЕПОРТ")
ActionBtn(MovePg,"⊕","TP → Случайный игрок",function(sl)
    local others={}; for _,p in ipairs(Players:GetPlayers()) do if p~=lp then table.insert(others,p) end end
    if #others==0 then sl.Text="нет игроков"; return end
    local t=others[math.random(1,#others)]
    local h=t.Character and t.Character:FindFirstChild("HumanoidRootPart"); local hrp=getHRP()
    if h and hrp then hrp.CFrame=h.CFrame+Vector3.new(3,0,0); sl.Text="→ "..t.DisplayName else sl.Text="ошибка" end
end)
ActionBtn(MovePg,"★","TP → Спауна",function(sl)
    local sp=workspace:FindFirstChildOfClass("SpawnLocation"); local hrp=getHRP()
    if sp and hrp then hrp.CFrame=sp.CFrame+Vector3.new(0,4,0); sl.Text="✓ готово" else sl.Text="нет спауна" end
end)

-- ══════════════════════════════════════════════════
--  PAGE 2 — VISUAL  (split: left settings | right preview)
-- ══════════════════════════════════════════════════
local VisPg = makePage(false)   -- plain Frame, not scroll

-- Left scroll column
local VisLeft=Instance.new("ScrollingFrame",VisPg)
VisLeft.Size=UDim2.new(0,238,1,0); VisLeft.CanvasSize=UDim2.new(0,0,0,0)
VisLeft.AutomaticCanvasSize=Enum.AutomaticSize.Y
VisLeft.ScrollBarThickness=2; VisLeft.ScrollBarImageColor3=TH().br
VisLeft.BackgroundTransparency=1; VisLeft.BorderSizePixel=0
local vlPad=Instance.new("UIPadding",VisLeft)
vlPad.PaddingTop=UDim.new(0,2); vlPad.PaddingRight=UDim.new(0,4); vlPad.PaddingBottom=UDim.new(0,10)
Instance.new("UIListLayout",VisLeft).Padding=UDim.new(0,3)

-- Right preview column
local VisRight=Instance.new("Frame",VisPg)
VisRight.Size=UDim2.new(1,-244,1,0); VisRight.Position=UDim2.new(0,242,0,0)
VisRight.BackgroundTransparency=1; VisRight.BorderSizePixel=0

local PrevCard=Instance.new("Frame",VisRight)
PrevCard.Size=UDim2.new(1,0,1,0); PrevCard.BackgroundColor3=TH().card
PrevCard.BorderSizePixel=0
Instance.new("UICorner",PrevCard).CornerRadius=UDim.new(0,10)
Instance.new("UIStroke",PrevCard).Color=TH().br

local PrevLabel=Instance.new("TextLabel",PrevCard)
PrevLabel.Size=UDim2.new(1,0,0,16); PrevLabel.BackgroundTransparency=1
PrevLabel.Text="  ESP ПРЕВЬЮ"; PrevLabel.TextColor3=TH().sub; PrevLabel.TextSize=8
PrevLabel.Font=Enum.Font.GothamBold; PrevLabel.TextXAlignment=Enum.TextXAlignment.Left

local Stage=Instance.new("Frame",PrevCard)
Stage.Size=UDim2.new(1,-12,1,-22); Stage.Position=UDim2.new(0,6,0,17)
Stage.BackgroundColor3=Color3.fromRGB(4,6,10); Stage.BorderSizePixel=0
Instance.new("UICorner",Stage).CornerRadius=UDim.new(0,7)

-- Characters in preview
local function makePreviewChar(parent, xPct, scale, name)
    local body=Instance.new("Frame",parent); body.BorderSizePixel=0
    body.Size=UDim2.new(0,10*scale,0,15*scale); body.Position=UDim2.new(xPct,-5*scale,0.5,-7*scale+4)
    body.BackgroundColor3=Color3.fromRGB(48,62,88)
    Instance.new("UICorner",body).CornerRadius=UDim.new(0,2)
    local head=Instance.new("Frame",parent); head.BorderSizePixel=0
    head.Size=UDim2.new(0,8*scale,0,8*scale); head.Position=UDim2.new(xPct,-4*scale,0.5,-19*scale+4)
    head.BackgroundColor3=Color3.fromRGB(68,88,126)
    Instance.new("UICorner",head).CornerRadius=UDim.new(1,0)
    -- ESP box
    local box=Instance.new("Frame",parent); box.BorderSizePixel=0
    box.Size=UDim2.new(0,18*scale,0,30*scale); box.Position=UDim2.new(xPct,-9*scale,0.5,-20*scale+4)
    box.BackgroundTransparency=1
    local bStr=Instance.new("UIStroke",box); bStr.Thickness=1.2
    local bCor=Instance.new("UICorner",box)
    local nLbl=Instance.new("TextLabel",parent)
    nLbl.Size=UDim2.new(0,50,0,9); nLbl.Position=UDim2.new(xPct,-25,0.5,-31*scale+4)
    nLbl.BackgroundTransparency=1; nLbl.Text=name; nLbl.TextSize=8*scale
    nLbl.Font=Enum.Font.GothamBold; nLbl.TextXAlignment=Enum.TextXAlignment.Center
    local hLbl=Instance.new("TextLabel",parent)
    hLbl.Size=UDim2.new(0,40,0,9); hLbl.Position=UDim2.new(xPct,-20,0.5,11*scale+4)
    hLbl.BackgroundTransparency=1; hLbl.Text="100 HP"; hLbl.TextSize=7*scale
    hLbl.Font=Enum.Font.GothamBold; hLbl.TextColor3=Color3.fromRGB(80,220,80)
    hLbl.TextXAlignment=Enum.TextXAlignment.Center
    local tLine=Instance.new("Frame",parent); tLine.Size=UDim2.new(0,1,0.42,0)
    tLine.Position=UDim2.new(xPct,0,0.98,0); tLine.BackgroundColor3=Color3.new(1,1,1)
    tLine.BorderSizePixel=0; tLine.AnchorPoint=Vector2.new(0.5,1)
    return {box=box,bStr=bStr,bCor=bCor,name=nLbl,hp=hLbl,tLine=tLine}
end

local prev1=makePreviewChar(Stage,0.35,1.1,"Player1")
local prev2=makePreviewChar(Stage,0.68,0.85,"Player2")

RS.Heartbeat:Connect(function()
    for _,pv in ipairs({prev1,prev2}) do
        pv.bStr.Color=S.espColor; pv.bCor.CornerRadius=UDim.new(0,S.espCorner)
        pv.name.TextColor3=S.espColor; pv.name.Visible=S.espName
        pv.hp.Visible=S.espHP; pv.box.Visible=S.espBox
        pv.tLine.BackgroundColor3=S.espColor; pv.tLine.Visible=S.espLines
    end
end)

-- Left column ESP toggles
_ord=0  -- reset for VisLeft
local function vT(ico,lbl,init,cb) return Toggle(VisLeft,ico,lbl,init,cb) end
local function vS(lbl,iv,mn,mx,fm,cb) return Slider(VisLeft,lbl,iv,mn,mx,fm,cb) end
local function vSL(txt) return secLbl(VisLeft,txt) end
local function vC(ico,lbl,opts,ii,cb) return Cycler(VisLeft,ico,lbl,opts,ii,cb) end

vSL("ВКЛЮЧИТЬ")
vT("▣","ESP Вкл",       false,function(v) S.espOn=v end)
vSL("ЭЛЕМЕНТЫ")
vT("□","Бокс",          true, function(v) S.espBox=v end)
vT("◈","Имена",         true, function(v) S.espName=v end)
vT("♡","Здоровье",      true, function(v) S.espHP=v end)
vT("╲","Линии",         false,function(v) S.espLines=v end)
vT("◎","Дистанция",     false,function(v) S.espDist=v end)
vSL("СТИЛЬ")
do
    local cc=card(VisLeft,46)
    local tl=Instance.new("TextLabel",cc); tl.Size=UDim2.new(1,0,0,14); tl.Position=UDim2.new(0,10,0,3)
    tl.BackgroundTransparency=1; tl.Text="ЦВЕТ"; tl.TextColor3=TH().sub
    tl.TextSize=8; tl.Font=Enum.Font.GothamBold; tl.TextXAlignment=Enum.TextXAlignment.Left
    local rings={}
    for ci,col in ipairs(ESP_COLORS) do
        local cb=Instance.new("TextButton",cc)
        cb.Size=UDim2.new(0,17,0,17); cb.Position=UDim2.new(0,8+(ci-1)*21,0,21)
        cb.BackgroundColor3=col; cb.Text=""; cb.BorderSizePixel=0; cb.ZIndex=2
        Instance.new("UICorner",cb).CornerRadius=UDim.new(1,0)
        local ring=Instance.new("UIStroke",cb); ring.Color=Color3.new(1,1,1); ring.Thickness=(ci==1) and 1.5 or 0
        rings[ci]=ring
        cb.MouseButton1Click:Connect(function()
            S.espColor=col; S.espCI=ci
            for j,r in ipairs(rings) do r.Thickness=(j==ci) and 1.5 or 0 end
        end)
    end
end
do
    local cc=card(VisLeft,34)
    local tl=Instance.new("TextLabel",cc); tl.Size=UDim2.new(0.5,0,1,0); tl.Position=UDim2.new(0,10,0,0)
    tl.BackgroundTransparency=1; tl.Text="Закругление"; tl.TextColor3=TH().text
    tl.TextSize=11; tl.Font=Enum.Font.GothamSemibold; tl.TextXAlignment=Enum.TextXAlignment.Left
    local vl=Instance.new("TextLabel",cc); vl.Size=UDim2.new(0,24,1,0); vl.Position=UDim2.new(1,-60,0,0)
    vl.BackgroundTransparency=1; vl.Text="0"; vl.TextColor3=TH().accent; vl.TextSize=11; vl.Font=Enum.Font.GothamBold
    for _,d in ipairs({{-36,"−",-2},{-14,"+",2}}) do
        local b=Instance.new("TextButton",cc); b.Size=UDim2.new(0,20,0,20); b.Position=UDim2.new(1,d[1],0.5,-10)
        b.BackgroundColor3=TH().hi; b.Text=d[2]; b.TextColor3=TH().text; b.TextSize=13
        b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; b.ZIndex=2
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
        b.MouseButton1Click:Connect(function()
            S.espCorner=math.clamp(S.espCorner+d[3],0,20); vl.Text=tostring(S.espCorner)
        end)
    end
end
vC("↕","Линия от",{"Низ","Центр"},1,function(i) S.espLineFrom=(i==1) and "bottom" or "center" end)

-- ══════════════════════════════════════════════════
--  PAGE 3 — AIM
-- ══════════════════════════════════════════════════
local AimPg=makePage()
secLbl(AimPg,"ПРИЦЕЛ")
Toggle(AimPg,"⊙","Аимбот",false,function(v) S.aimOn=v end)
Toggle(AimPg,"◉","Показ FOV-круга",true,function(v) S.aimFOVCircle=v end)
Slider(AimPg,"FOV-радиус",120,20,400,nil,function(v) S.aimFOV=v end)
Slider(AimPg,"Плавность (меньше = быстрее)",18,1,100,"%d%%",function(v) S.aimSmooth=v/100 end)
secLbl(AimPg,"ЦЕЛЬ")
Cycler(AimPg,"◈","Часть тела",{"Голова","Торс","Шея"},1,function(i)
    S.aimPart=({"Head","UpperTorso","Neck"})[i]
end)
Cycler(AimPg,"⊕","Режим",{"Ближайший","Низкое HP","Видимый"},1,function(i)
    S.aimMode=({"nearest","lowhp","visible"})[i]
end)
Cycler(AimPg,"🖱","Клавиша",{"ПКМ (зажим)","ЛКМ (зажим)","Всегда"},1,function(i)
    S.aimKey=({"rmb","lmb","always"})[i]
end)
secLbl(AimPg,"ДОПОЛНИТЕЛЬНО")
Toggle(AimPg,"≋","Предсказание (prediction)",false,function(v) S.aimPred=v end)
Slider(AimPg,"Сила предсказания",12,1,50,"%d%%",function(v) S.aimPredVal=v/100 end)
Toggle(AimPg,"⚑","Проверка видимости",false,function(v) S.aimVisible=v end)
Toggle(AimPg,"♟","Проверка команды",false,function(v) S.aimTeam=v end)
secLbl(AimPg,"СГЛАЖИВАНИЕ МЫШИ")
Slider(AimPg,"Точность прицела",50,0,100,"%d%%",function(v) end)

-- ══════════════════════════════════════════════════
--  PAGE 4 — ATK
-- ══════════════════════════════════════════════════
local AtkPg=makePage()
secLbl(AtkPg,"АВТО КЛИКЕР")
Toggle(AtkPg,"⬤","Авто кликер",false,function(v) S.aclick=v end)
Slider(AtkPg,"CPS (кликов в секунду)",10,1,50,nil,function(v) S.aclickCps=v end)
Cycler(AtkPg,"🖱","Кнопка",{"ЛКМ","ПКМ"},1,function(i) S.aclickBtn=(i==1) and 0 or 1 end)
secLbl(AtkPg,"АВТО ФАРМ")
do
    local cc=card(AtkPg,52)
    local ptAL=Instance.new("TextLabel",cc); ptAL.Size=UDim2.new(0.5,-4,0,20); ptAL.Position=UDim2.new(0,4,0,4)
    ptAL.BackgroundColor3=TH().hi; ptAL.BorderSizePixel=0
    Instance.new("UICorner",ptAL).CornerRadius=UDim.new(0,6)
    ptAL.Text="  A: не задана"; ptAL.TextColor3=TH().sub; ptAL.TextSize=9; ptAL.Font=Enum.Font.GothamBold; ptAL.TextXAlignment=Enum.TextXAlignment.Left
    local ptBL=Instance.new("TextLabel",cc); ptBL.Size=UDim2.new(0.5,-4,0,20); ptBL.Position=UDim2.new(0.5,0,0,4)
    ptBL.BackgroundColor3=TH().hi; ptBL.BorderSizePixel=0
    Instance.new("UICorner",ptBL).CornerRadius=UDim.new(0,6)
    ptBL.Text="  B: не задана"; ptBL.TextColor3=TH().sub; ptBL.TextSize=9; ptBL.Font=Enum.Font.GothamBold; ptBL.TextXAlignment=Enum.TextXAlignment.Left
    -- progress bar
    local pBar=Instance.new("Frame",cc); pBar.Size=UDim2.new(1,-8,0,8); pBar.Position=UDim2.new(0,4,0,30)
    pBar.BackgroundColor3=TH().hi; pBar.BorderSizePixel=0; Instance.new("UICorner",pBar).CornerRadius=UDim.new(0,4)
    local pFill=Instance.new("Frame",pBar); pFill.Size=UDim2.new(0,0,1,0); pFill.BackgroundColor3=TH().accent; pFill.BorderSizePixel=0
    Instance.new("UICorner",pFill).CornerRadius=UDim.new(0,4)
    local infoL=Instance.new("TextLabel",cc); infoL.Size=UDim2.new(1,0,0,12); infoL.Position=UDim2.new(0,4,0,40)
    infoL.BackgroundTransparency=1; infoL.Text="Стой на месте → задай точку → включи"
    infoL.TextColor3=TH().sub; infoL.TextSize=8; infoL.Font=Enum.Font.Gotham; infoL.TextXAlignment=Enum.TextXAlignment.Left
    -- animate progress bar when farming
    RS.Heartbeat:Connect(function()
        if S.farmOn then
            tw(pFill,{Size=UDim2.new(1,0,1,0)},S.farmDelay*0.5)
            task.delay(S.farmDelay*0.5,function() if pFill and pFill.Parent then pFill.Size=UDim2.new(0,0,1,0) end end)
        end
    end)
    S._ptAL=ptAL; S._ptBL=ptBL
end
ActionBtn(AtkPg,"◎","Задать точку A",function(sl)
    local hrp=getHRP(); if not hrp then sl.Text="нет персонажа"; return end
    S.farmPtA=hrp.Position
    if S._ptAL then S._ptAL.Text="  A: ("..math.floor(hrp.Position.X)..","..math.floor(hrp.Position.Z)..")"; S._ptAL.TextColor3=TH().accent end
    sl.Text="✓ сохранено"
end)
ActionBtn(AtkPg,"◎","Задать точку B",function(sl)
    local hrp=getHRP(); if not hrp then sl.Text="нет персонажа"; return end
    S.farmPtB=hrp.Position
    if S._ptBL then S._ptBL.Text="  B: ("..math.floor(hrp.Position.X)..","..math.floor(hrp.Position.Z)..")"; S._ptBL.TextColor3=TH().accent end
    sl.Text="✓ сохранено"
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
Slider(AtkPg,"Задержка фарма (сек × 10)",10,1,50,nil,function(v) S.farmDelay=v/10 end)
secLbl(AtkPg,"ПРОЧЕЕ")
Toggle(AtkPg,"⏰","Анти-АФК",false,function(v) S.antiAfk=v end)

-- ══════════════════════════════════════════════════
--  PAGE 5 — MISC
-- ══════════════════════════════════════════════════
local MiscPg=makePage()
secLbl(MiscPg,"МИР")
Toggle(MiscPg,"⛅","Убрать туман",false,function(v)
    S.noFog=v
    local L=game:GetService("Lighting")
    if v then L.FogEnd=9e8; L.FogStart=9e8 end
end)
secLbl(MiscPg,"ТЕМА ИНТЕРФЕЙСА")
local themeRefs={}
do
    _ord+=1
    local grid=Instance.new("Frame",MiscPg); grid.Size=UDim2.new(1,-2,0,160); grid.BackgroundTransparency=1
    grid.BorderSizePixel=0; grid.LayoutOrder=_ord
    for i,theme in ipairs(THEMES) do
        local col=(i-1)%3; local row=math.floor((i-1)/3)
        local tc=Instance.new("Frame",grid)
        tc.Size=UDim2.new(0.315,0,0,68); tc.Position=UDim2.new(col*0.344,0,0,row*76)
        tc.BackgroundColor3=theme.nav; tc.BorderSizePixel=0
        Instance.new("UICorner",tc).CornerRadius=UDim.new(0,10)
        local tcs=Instance.new("UIStroke",tc); tcs.Color=(i==TI) and theme.accent or theme.br; tcs.Thickness=(i==TI) and 1.5 or 1
        -- swatches
        for si,sc in ipairs({theme.bg,theme.accent,theme.hi}) do
            local sw=Instance.new("Frame",tc); sw.Size=UDim2.new(0,8,0,8); sw.Position=UDim2.new(0,7+(si-1)*12,0,7)
            sw.BackgroundColor3=sc; sw.BorderSizePixel=0; Instance.new("UICorner",sw).CornerRadius=UDim.new(1,0)
        end
        if theme.snow then
            local snowIco=Instance.new("TextLabel",tc); snowIco.Size=UDim2.new(0,14,0,14); snowIco.Position=UDim2.new(1,-18,0,5)
            snowIco.BackgroundTransparency=1; snowIco.Text="❄"; snowIco.TextSize=10; snowIco.Font=Enum.Font.Gotham; snowIco.TextColor3=theme.accent
        end
        local stripe=Instance.new("Frame",tc); stripe.Size=UDim2.new(0,3,0,24); stripe.Position=UDim2.new(0,7,0,24)
        stripe.BackgroundColor3=theme.accent; stripe.BorderSizePixel=0; Instance.new("UICorner",stripe).CornerRadius=UDim.new(1,0)
        local tn=Instance.new("TextLabel",tc); tn.Size=UDim2.new(1,-16,0,14); tn.Position=UDim2.new(0,14,0,24)
        tn.BackgroundTransparency=1; tn.Text=theme.name; tn.TextColor3=theme.text; tn.TextSize=10; tn.Font=Enum.Font.GothamBold; tn.TextXAlignment=Enum.TextXAlignment.Left
        local ts=Instance.new("TextLabel",tc); ts.Size=UDim2.new(1,-14,0,12); ts.Position=UDim2.new(0,14,0,40)
        ts.BackgroundTransparency=1; ts.Text=(i==TI) and "● активна" or "нажми"; ts.TextColor3=(i==TI) and theme.accent or theme.sub
        ts.TextSize=8; ts.Font=Enum.Font.Gotham; ts.TextXAlignment=Enum.TextXAlignment.Left
        if theme.anim~="none" then
            local animL=Instance.new("TextLabel",tc); animL.Size=UDim2.new(1,-14,0,10); animL.Position=UDim2.new(0,14,0,54)
            animL.BackgroundTransparency=1; animL.Text="✦ анимация"; animL.TextColor3=theme.sub; animL.TextSize=7; animL.Font=Enum.Font.Gotham; animL.TextXAlignment=Enum.TextXAlignment.Left
        end
        themeRefs[i]={tc=tc,stroke=tcs,sub=ts}
        local tb=Instance.new("TextButton",tc); tb.Size=UDim2.new(1,0,1,0); tb.BackgroundTransparency=1; tb.Text=""; tb.ZIndex=2
        tb.MouseButton1Click:Connect(function()
            if TI==i then return end; TI=i
            for j,ref in ipairs(themeRefs) do
                local th=THEMES[j]; tw(ref.stroke,{Color=(j==TI) and th.accent or th.br},.25)
                ref.stroke.Thickness=(j==TI) and 1.5 or 1
                ref.sub.Text=(j==TI) and "● активна" or "нажми"; ref.sub.TextColor3=(j==TI) and th.accent or th.sub
            end
            tw(Win,{BackgroundColor3=TH().bg},.4); tw(WStroke,{Color=TH().br},.4)
            tw(Hdr,{BackgroundColor3=TH().nav},.4); tw(HFix,{BackgroundColor3=TH().nav},.4)
            tw(TabBar,{BackgroundColor3=TH().nav},.4)
            TitleL.TextColor3=TH().text
            SnowLayer.Visible=TH().snow
        end)
    end
end
secLbl(MiscPg,"ГОРЯЧИЕ КЛАВИШИ")
do
    local cc=card(MiscPg,56)
    for i,row in ipairs({{"ПР. SHIFT","скрыть / показать"},{"W/A/S/D","лететь"},{"SPACE/SHIFT","вверх/вниз в полёте"},{"ПКМ/ЛКМ","аимбот (зажим)"}}) do
        local r=Instance.new("Frame",cc); r.Size=UDim2.new(1,-10,0,12); r.Position=UDim2.new(0,5,0,(i-1)*13)
        r.BackgroundTransparency=1; r.BorderSizePixel=0
        local k=Instance.new("TextLabel",r); k.Size=UDim2.new(0,90,1,0); k.BackgroundTransparency=1
        k.Text=row[1]; k.TextColor3=TH().accent; k.TextSize=8; k.Font=Enum.Font.GothamBold; k.TextXAlignment=Enum.TextXAlignment.Left
        local v=Instance.new("TextLabel",r); v.Size=UDim2.new(1,-94,1,0); v.Position=UDim2.new(0,94,0,0)
        v.BackgroundTransparency=1; v.Text=row[2]; v.TextColor3=TH().sub; v.TextSize=8; v.Font=Enum.Font.Gotham; v.TextXAlignment=Enum.TextXAlignment.Left
    end
end

-- ══════════════════════════════════════════════════
--  TOP TAB BUTTONS
-- ══════════════════════════════════════════════════
local TABS={
    {lbl="MOVE",  ico="↑", page=MovePg},
    {lbl="VISUAL",ico="▣", page=VisPg},
    {lbl="AIM",   ico="⊙", page=AimPg},
    {lbl="ATK",   ico="⚔", page=AtkPg},
    {lbl="MISC",  ico="≡", page=MiscPg},
}
local activeTab=1; local tabRefs={}

for i,td in ipairs(TABS) do
    local btn=Instance.new("TextButton",TabBar)
    btn.Size=UDim2.new(1/#TABS,0,1,0); btn.BackgroundTransparency=1
    btn.Text=""; btn.BorderSizePixel=0; btn.ZIndex=4
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,9)
    local isActive=(i==1)
    tw(btn,{BackgroundTransparency=isActive and 0 or 1},0)
    btn.BackgroundColor3=TH().hi

    local icoL=Instance.new("TextLabel",btn); icoL.Size=UDim2.new(0,18,1,0); icoL.Position=UDim2.new(0.5,-28,0,0)
    icoL.BackgroundTransparency=1; icoL.Text=td.ico; icoL.TextSize=12; icoL.Font=Enum.Font.GothamBold
    icoL.TextColor3=isActive and TH().accent or TH().sub; icoL.ZIndex=5

    local lblL=Instance.new("TextLabel",btn); lblL.Size=UDim2.new(0,46,1,0); lblL.Position=UDim2.new(0.5,-14,0,0)
    lblL.BackgroundTransparency=1; lblL.Text=td.lbl; lblL.TextSize=10
    lblL.Font=isActive and Enum.Font.GothamBold or Enum.Font.Gotham
    lblL.TextColor3=isActive and TH().text or TH().sub; lblL.ZIndex=5; lblL.TextXAlignment=Enum.TextXAlignment.Left

    local underline=Instance.new("Frame",btn)
    underline.Size=UDim2.new(0.65,0,0,2); underline.Position=UDim2.new(0.175,0,1,-2)
    underline.BackgroundColor3=TH().accent; underline.BorderSizePixel=0
    underline.BackgroundTransparency=isActive and 0 or 1
    Instance.new("UICorner",underline).CornerRadius=UDim.new(1,0)

    tabRefs[i]={btn=btn,ico=icoL,lbl=lblL,ul=underline}

    btn.MouseButton1Click:Connect(function()
        if i==activeTab then return end
        local prev=tabRefs[activeTab]
        tw(prev.btn,{BackgroundTransparency=1},.15); tw(prev.ico,{TextColor3=TH().sub},.15)
        tw(prev.lbl,{TextColor3=TH().sub},.15); prev.lbl.Font=Enum.Font.Gotham
        tw(prev.ul,{BackgroundTransparency=1},.15); TABS[activeTab].page.Visible=false
        activeTab=i
        tw(btn,{BackgroundTransparency=0,BackgroundColor3=TH().hi},.15)
        tw(icoL,{TextColor3=TH().accent},.15); lblL.Font=Enum.Font.GothamBold
        tw(lblL,{TextColor3=TH().text},.15)
        tw(underline,{BackgroundTransparency=0,BackgroundColor3=TH().accent},.15)
        td.page.Visible=true
    end)
end
TABS[1].page.Visible=true

-- ══════════════════════════════════════════════════
--  OPEN / CLOSE
-- ══════════════════════════════════════════════════
local isOpen=true

local MiniBtn=Instance.new("TextButton",SGui)
MiniBtn.Size=UDim2.new(0,100,0,24); MiniBtn.Position=UDim2.new(0,8,0,8)
MiniBtn.BackgroundColor3=TH().nav; MiniBtn.Text="▶  Vape Ext"; MiniBtn.TextColor3=TH().accent
MiniBtn.TextSize=10; MiniBtn.Font=Enum.Font.GothamBold; MiniBtn.BorderSizePixel=0
MiniBtn.Visible=false; MiniBtn.ZIndex=999
Instance.new("UICorner",MiniBtn).CornerRadius=UDim.new(0,8)
local MBS=Instance.new("UIStroke",MiniBtn); MBS.Color=TH().accent; MBS.Thickness=1

local function closeWin()
    if not isOpen then return end; isOpen=false
    tw(Win,{Position=UDim2.new(0.5,-245,1.1,0)},.28,Enum.EasingStyle.Back,Enum.EasingDirection.In)
    task.delay(.3,function() if Win and Win.Parent then Win.Visible=false end; MiniBtn.Visible=true end)
end
local function openWin()
    if isOpen then return end; isOpen=true; MiniBtn.Visible=false; Win.Visible=true
    Win.Position=UDim2.new(0.5,-245,1.1,0)
    tw(Win,{Position=UDim2.new(0.5,-245,0.5,-245)},.4,Enum.EasingStyle.Back)
end
CloseBtn.MouseButton1Click:Connect(closeWin)
MiniBtn.MouseButton1Click:Connect(openWin)
CloseBtn.MouseEnter:Connect(function() tw(CloseBtn,{BackgroundColor3=Color3.fromRGB(88,24,24)},.1) end)
CloseBtn.MouseLeave:Connect(function() tw(CloseBtn,{BackgroundColor3=Color3.fromRGB(58,20,20)},.1) end)
UIS.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.RightShift then if isOpen then closeWin() else openWin() end end
end)

-- ══════════════════════════════════════════════════
--  SNOW ANIMATION
-- ══════════════════════════════════════════════════
local snowflakes={}
for _=1,28 do
    local sf=Instance.new("Frame",SnowLayer)
    local sz=math.random(2,5)
    sf.Size=UDim2.new(0,sz,0,sz); sf.BackgroundColor3=Color3.new(1,1,1)
    sf.BackgroundTransparency=math.random(1,5)/10; sf.BorderSizePixel=0; sf.ZIndex=7
    Instance.new("UICorner",sf).CornerRadius=UDim.new(1,0)
    local data={f=sf, x=math.random(), y=-math.random(), speed=math.random(15,45)/1000, drift=math.random(-8,8)/10000}
    table.insert(snowflakes,data)
end

RS.Heartbeat:Connect(function(dt)
    if not TH().snow then return end
    for _,s in ipairs(snowflakes) do
        s.y=s.y+s.speed; s.x=s.x+s.drift
        if s.y>1.05 then s.y=-0.03; s.x=math.random() end
        if s.x<0 then s.x=1 elseif s.x>1 then s.x=0 end
        if s.f and s.f.Parent then s.f.Position=UDim2.new(s.x,0,s.y,0) end
    end
end)

-- ══════════════════════════════════════════════════
--  THEME ANIMATIONS
-- ══════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(1.4)
        local th=TH()
        if th.anim=="pulse" then
            -- Сумерки: border glow breathes
            tw(WStroke,{Color=Color3.fromRGB(175,95,255)},1.2,Enum.EasingStyle.Sine)
            task.wait(1.2)
            tw(WStroke,{Color=th.br},1.2,Enum.EasingStyle.Sine)
        elseif th.anim=="ember" then
            -- Уголь: red flicker
            tw(WStroke,{Color=Color3.fromRGB(255,40,40)},0.8,Enum.EasingStyle.Sine)
            task.wait(0.8)
            tw(WStroke,{Color=th.br},0.6,Enum.EasingStyle.Sine)
        elseif th.anim=="drift" then
            -- Рассвет: accent color drifts
            tw(GreenDot,{BackgroundColor3=th.accent},1.0,Enum.EasingStyle.Sine)
            task.wait(1.0)
            tw(GreenDot,{BackgroundColor3=Color3.fromRGB(46,215,90)},1.0,Enum.EasingStyle.Sine)
        end
    end
end)

-- ══════════════════════════════════════════════════
--  FLY
-- ══════════════════════════════════════════════════
RS.Heartbeat:Connect(function()
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

-- ══════════════════════════════════════════════════
--  NOCLIP
-- ══════════════════════════════════════════════════
RS.Stepped:Connect(function()
    if not S.noclip then return end
    local c=getChar(); if not c then return end
    for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
end)

-- ══════════════════════════════════════════════════
--  INFINITE JUMP
-- ══════════════════════════════════════════════════
UIS.JumpRequest:Connect(function()
    if not S.infJump then return end
    local hum=getHum()
    if hum and hum.FloorMaterial==Enum.Material.Air then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- ══════════════════════════════════════════════════
--  AUTO CLICKER
-- ══════════════════════════════════════════════════
task.spawn(function()
    while true do
        if S.aclick then
            local delay=1/math.max(S.aclickCps,1)
            local pos=UIS:GetMouseLocation()
            pcall(function()
                game:GetService("VirtualInputManager"):SendMouseButtonEvent(pos.X,pos.Y,S.aclickBtn or 0,true,game,0)
                task.wait(0.01)
                game:GetService("VirtualInputManager"):SendMouseButtonEvent(pos.X,pos.Y,S.aclickBtn or 0,false,game,0)
            end)
            task.wait(math.max(delay-0.01,0.01))
        else
            task.wait(0.1)
        end
    end
end)

-- ══════════════════════════════════════════════════
--  AIMBOT
-- ══════════════════════════════════════════════════
local aimFOVDraw=nil
pcall(function()
    aimFOVDraw=Drawing.new("Circle")
    aimFOVDraw.Thickness=1; aimFOVDraw.Color=Color3.new(1,1,1)
    aimFOVDraw.Transparency=0.55; aimFOVDraw.Filled=false; aimFOVDraw.Visible=false
end)

local function aimKeyHeld()
    if S.aimKey=="always" then return true end
    if S.aimKey=="rmb" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
    if S.aimKey=="lmb" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
    return false
end

local function findAimTarget()
    local vp=cam.ViewportSize; local center=Vector2.new(vp.X/2,vp.Y/2)
    local best,bestScore,bestHRP=nil,math.huge,nil

    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==lp then continue end
        if S.aimTeam and plr.Team==lp.Team then continue end
        local char=plr.Character; if not char then continue end
        local part=char:FindFirstChild(S.aimPart) or char:FindFirstChild("HumanoidRootPart"); if not part then continue end
        local hum=char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then continue end
        local sp,vis=cam:WorldToViewportPoint(part.Position); if not vis then continue end
        local screenDist=(Vector2.new(sp.X,sp.Y)-center).Magnitude
        if screenDist>S.aimFOV then continue end
        if S.aimVisible then
            local ray=workspace:Raycast(cam.CFrame.Position,(part.Position-cam.CFrame.Position).Unit*1000,
                RaycastParams.new())
            if ray and ray.Instance and not ray.Instance:IsDescendantOf(char) then continue end
        end
        local score
        if S.aimMode=="nearest" then score=screenDist
        elseif S.aimMode=="lowhp" then score=hum.Health
        else score=screenDist end
        if score<bestScore then bestScore=score; best=part; bestHRP=char:FindFirstChild("HumanoidRootPart") end
    end
    return best, bestHRP
end

RS.RenderStepped:Connect(function()
    local vp=cam.ViewportSize
    if aimFOVDraw then
        aimFOVDraw.Visible=S.aimOn and S.aimFOVCircle
        aimFOVDraw.Position=Vector2.new(vp.X/2,vp.Y/2)
        aimFOVDraw.Radius=S.aimFOV
        aimFOVDraw.Color=S.espColor
    end
    if not S.aimOn or not aimKeyHeld() then return end
    local target,targetHRP=findAimTarget(); if not target then return end
    local targetPos=target.Position
    if S.aimPred and targetHRP then
        targetPos=targetPos+targetHRP.Velocity*S.aimPredVal
    end
    local dir=(targetPos-cam.CFrame.Position).Unit
    local newCF=CFrame.new(cam.CFrame.Position,cam.CFrame.Position+dir)
    cam.CFrame=cam.CFrame:Lerp(newCF,math.clamp(S.aimSmooth,0.01,1))
end)

-- ══════════════════════════════════════════════════
--  ESP — Drawing API  (correct box from screen coords)
-- ══════════════════════════════════════════════════
local pool={}

local function newD(type,...) local ok,d=pcall(function() local x=Drawing.new(type)
    local args={...}; for k,v in pairs(args[1] or {}) do x[k]=v end; return x end); return ok and d or nil end

local function rmEsp(uid)
    local o=pool[uid]; if not o then return end
    for _,d in pairs(o) do pcall(function() d:Remove() end) end; pool[uid]=nil
end
local function clearEsp() for uid in pairs(pool) do rmEsp(uid) end end

RS.RenderStepped:Connect(function()
    if not S.espOn then clearEsp(); return end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==lp then continue end
        local char=plr.Character
        local head=char and char:FindFirstChild("Head")
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not head or not hrp or not hum or hum.Health<=0 then rmEsp(plr.UserId); continue end

        -- Get accurate top (above head) and bottom (below feet)
        local topPos   = head.Position + Vector3.new(0, head.Size.Y/2 + 0.15, 0)
        local botPos   = hrp.Position  - Vector3.new(0, 3.2, 0)
        local sTop,vT  = cam:WorldToViewportPoint(topPos)
        local sBot,vB  = cam:WorldToViewportPoint(botPos)
        if not vT and not vB then rmEsp(plr.UserId); continue end

        local bH = math.abs(sBot.Y - sTop.Y)
        local bW = bH * 0.5
        local cx = sTop.X
        local bL,bR,bTy,bBy = cx-bW/2, cx+bW/2, sTop.Y, sBot.Y
        local col = S.espColor

        if not pool[plr.UserId] then
            pool[plr.UserId]={
                box  = newD("Square",{Thickness=1.3,Filled=false,Visible=false}),
                name = newD("Text",  {Size=12,Font=Drawing.Fonts.Plex,Outline=true,Visible=false}),
                hp   = newD("Text",  {Size=11,Font=Drawing.Fonts.Plex,Outline=true,Visible=false}),
                dist = newD("Text",  {Size=10,Font=Drawing.Fonts.Plex,Outline=true,Color=Color3.fromRGB(180,180,200),Visible=false}),
                line = newD("Line",  {Thickness=1,Transparency=0.35,Visible=false}),
                hpBg = newD("Square",{Filled=true,Color=Color3.fromRGB(20,20,20),Transparency=0.4,Visible=false}),
                hpFl = newD("Square",{Filled=true,Visible=false}),
            }
        end

        local o=pool[plr.UserId]
        pcall(function()
            -- Box
            if o.box then o.box.Visible=S.espBox; o.box.Color=col
                o.box.Position=Vector2.new(bL,bTy); o.box.Size=Vector2.new(bW,bH) end
            -- Name
            if o.name then o.name.Visible=S.espName; o.name.Color=col
                o.name.Text=plr.DisplayName; o.name.Position=Vector2.new(cx,bTy-14); o.name.Center=true end
            -- HP bar (left side of box)
            local hp=hum.Health; local mx=math.max(hum.MaxHealth,1); local ratio=hp/mx
            local hpH=bH*ratio; local barX=bL-5
            if o.hpBg then o.hpBg.Visible=S.espHP; o.hpBg.Position=Vector2.new(barX-2,bTy); o.hpBg.Size=Vector2.new(4,bH) end
            if o.hpFl then o.hpFl.Visible=S.espHP
                o.hpFl.Color=Color3.fromRGB(math.floor(255*(1-ratio)),math.floor(55+200*ratio),55)
                o.hpFl.Position=Vector2.new(barX-2,bBy-hpH); o.hpFl.Size=Vector2.new(4,hpH) end
            -- HP text
            if o.hp then o.hp.Visible=S.espHP; o.hp.Color=Color3.fromRGB(math.floor(255*(1-ratio)),math.floor(55+200*ratio),55)
                o.hp.Text=math.floor(hp).."hp"; o.hp.Position=Vector2.new(bR+3,bTy); o.hp.Center=false end
            -- Distance
            if o.dist then
                local myHRP=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                local dist=myHRP and math.floor((hrp.Position-myHRP.Position).Magnitude) or 0
                o.dist.Visible=S.espDist; o.dist.Text=dist.."m"; o.dist.Position=Vector2.new(cx,bBy+2); o.dist.Center=true end
            -- Tracer
            if o.line then o.line.Visible=S.espLines; o.line.Color=col
                if S.espLines then local vp=cam.ViewportSize
                    o.line.From=Vector2.new(vp.X/2,(S.espLineFrom=="bottom") and vp.Y or vp.Y/2)
                    o.line.To=Vector2.new(cx,bBy) end end
        end)
    end
end)
Players.PlayerRemoving:Connect(function(p) rmEsp(p.UserId) end)

-- ══════════════════════════════════════════════════
--  STARTUP
-- ══════════════════════════════════════════════════
Win.Visible=true
Win.Position=UDim2.new(0.5,-245,1.5,0)
SnowLayer.Visible=TH().snow
tw(Win,{Position=UDim2.new(0.5,-245,0.5,-245)},.55,Enum.EasingStyle.Back)

print("[Vape External v5.0] ✓  ПР.SHIFT = скрыть/показать")
