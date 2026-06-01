-- ============================================================
-- GOJO DOMAIN V32 — MERGED SINGLE FILE
-- All systems merged: utils, combat, bf, fly, extras, ui
-- Local register limit workaround: config/state/connections
-- grouped into tables (Cfg/St/Cn)
-- ============================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local UserInputService  = game:GetService("UserInputService")
local StarterGui        = game:GetService("StarterGui")
local TweenService      = game:GetService("TweenService")
local InsertService     = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris            = game:GetService("Debris")


local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local mobile      = UserInputService.TouchEnabled
local _lastDomainRebuild = 0
-- ============================================================
-- CONFIG TABLE
-- ============================================================
local Cfg = {
    INCLUDE_NPCS        = true,
    MAX_HUNT_ATTEMPTS   = 50,
    RESPAWN_WAIT        = 1.3,
    STABILITY_DURATION  = 0.85,
    SNAP_THRESHOLD      = 8,
    MIN_TARGET_DISTANCE = 55,
    offsetX = 0, offsetY = 0, offsetZ = 2,
    tpMode      = "under",
    tpMethod    = "default",
    sweepMode   = "normal",
    tpPriority  = "normal",
    -- DEFAULT -500: do not touch unless you know what you are doing
    fallenHeight = -1000,
    BF = {
        Duration             = 0.25,
        Radius               = 3,
        Range                = 25,
        CurveStrength        = 14,
        CamOffset            = 2,
        PredictionMultiplier = 0.6,
        LandingLinger = 0.2,
        BackAngleDot  = 0.5,   -- how far into back arc counts as "behind" (0=side, 1=directly behind)
        BehindDist    = 4.0,   -- extra stud tolerance beyond Radius for behind check
        FacingDot     = 0.3,   -- how much we need to face target to count as behind
        GlideCurveK   = 0.6,   -- bezier curve flatDist multiplier (controls curve tightness)
    },
    BF_AnimationTriggers = {
        ["rbxassetid://100962226150441"] = 0.19,
        ["rbxassetid://95852624447551"]  = 0.19,
        ["rbxassetid://74145636023952"]  = 0.19,
        ["rbxassetid://72475960800126"]  = 0.20,
    },
    BF_StraightAnimations = { ["rbxassetid://123171106092050"] = true },
    BF_DASH_ANIM_LEFT  = "rbxassetid://117223862448096",
    BF_DASH_ANIM_RIGHT = "rbxassetid://75203303352791",
    BF_BEHIND_DIST = 2.5,
    BF_BEHIND_DOT  = 0.72,
    BF_CAM_LINGER  = 0.10,
    BF_RECENCY     = 3.0,
    DRONE_ID          = 17865400476,
    SHRINK_ANIM_ID    = "rbxassetid://75390215999547",
    INVIS_ANIM_ID     = "rbxassetid://108081843941348",
    INVIS_FREEZE_TIME = 7,
    FlySpeed = 150,
    LockOn = {
        Method     = "Body",
        SideOffset = 0,
        Smoothness = 0.15,
        MaxDistance= 60,
    },
}

-- ============================================================
-- EMOTE LIST
-- ============================================================
local EMOTE_LIST = {
    {name="Mahito Itadori",        id=105199432380841},
    {name="Waste of Time",         id=5775509840},
    {name="Ganbare Ganbare",       id=128755610900618},
    {name="Heavenly Ramble",       id=82476745705122},
    {name="Satoru Gojo",           id=6265242673},
    {name="Huh",                   id=16363777391},
    {name="Don",                   id=12917642257},
    {name="Sorry Nanami",          id=18680487885},
    {name="Mambo",                 id=97871211303571},
    {name="What Are U Mahito",     id=71411567772779},
    {name="Idk This Guy",          id=78044670447386},
    {name="Yowai Mo",              id=7948969023},
    {name="You Did It",            id=99137255050147},
    {name="My Besto Frendo",       id=129622474979733},
    {name="Besto Frendo",          id=18257697094},
    {name="Convergence",           id=15917626934},
    {name="Where U Going",         id=96326653225562},
    {name="Next",                  id=7061369096},
    {name="Toji Fushiguro",        id=6743603446},
    {name="Apologize",             id=15753185070},
    {name="Disrespectful Rush",    id=136335654594541},
    {name="Hidoi Na",              id=106755448566954},
    {name="Nanami Sigh",           id=10173613362},
    {name="You Cryin",             id=112599702984099},
    {name="Laugh",                 id=18319797565},
    {name="Words Are Unnecessary", id=134719689134074},
    {name="Jackpot",               id=108907296117028},
    {name="Stand Proud",           id=100445971002729},
    {name="Forreal",               id=7061190867},
    {name="Veri Angri",            id=13997948756},
    {name="Slap Vibra",            id=18246120711},
    {name="Majika",                id=16159090773},
    {name="Somethin Off",          id=131371183130808},
    {name="Yujiiii",               id=89667437228243},
    {name="Yo Long Time",          id=7061193663},
    {name="Oi",                    id=18370175258},
    {name="Idiot",                 id=137318879402973},
}

local emoteSelectedIndex = 1
local emoteKeybind       = Enum.KeyCode.C
local emoteKeybindConn   = nil

local function fireEmote(id)
    pcall(function()
        ReplicatedStorage:WaitForChild("Knit"):WaitForChild("Knit")
            :WaitForChild("Services"):WaitForChild("JoinService")
            :WaitForChild("RE"):WaitForChild("Talk"):FireServer(id)
    end)
end

local function getEmoteNames()
    local n = {}
    for _, e in ipairs(EMOTE_LIST) do table.insert(n, e.name) end
    return n
end

local function setEmoteIndex(name)
    for i, e in ipairs(EMOTE_LIST) do
        if e.name == name then emoteSelectedIndex = i; return end
    end
end

local function fireSelectedEmote()
    local e = EMOTE_LIST[emoteSelectedIndex]
    if e then fireEmote(e.id) end
end

local function setEmoteKeybind(keyCode)
    emoteKeybind = keyCode
    if emoteKeybindConn then emoteKeybindConn:Disconnect() end
    emoteKeybindConn = UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == emoteKeybind then fireSelectedEmote() end
    end)
end

-- ============================================================
-- STATE TABLE
-- ============================================================
local St = {
    sweepActive        = false,
    huntRunning        = false,
    luckyCycleFound    = false,
    noDomainTP         = false,
    voidMethodSit      = false,
    overlayEnabled     = true,
    attachActive       = false,
    attachTarget       = nil,
    attachLoopId       = 0,
    safeTpActive       = false,
    bfEnabled          = false,
    bfGlideActive      = false,
    bfPingDelay        = 0.12,
    bfMode             = "blatant",
    flyActive          = false,
    flyOriginalFOV     = 70,
    noStunConn         = nil,
    shrinkHitboxActive = false,
    invisActive        = false,
    invisAnimTrack     = nil,
    invis2Active       = false,
    hitboxLoaded       = false,
    invisLoaded        = false,
    emotesLoaded       = false,
    instantBHLoaded    = false,
    yutaBFLoaded       = false,
    wallhopMetaHooked  = false,
    attachHRP          = nil,
    attachSavedPos     = nil,
    invisPrevCamSubject = nil,
    invisPrevCamType    = nil,
    invisOrigHipHeight  = nil,
    invisOrigAutoJump   = nil,
    -- fly state (stored here to avoid local register overflow)
    flyCharacter        = nil,
    flyHumanoid         = nil,
    flyRootPart         = nil,
    flyAnimator         = nil,
    flyBodyVelocity     = nil,
    flyBodyGyro         = nil,
    flyIdleAnim         = nil,
    flyMoveAnim         = nil,
    flyIdleTrack        = nil,
    flyMoveTrack        = nil,
    flyCurrentAnimState = nil,
    flyWasMoving        = false,
    flyBoostTrack  = nil,
    flyRightTrack  = nil,
    flyLeftTrack   = nil,
    flyBackTrack   = nil,
    flyToggleOn = false,
    -- bf state
    bfLastAttackTime      = {},
    bfTargetLookSmoothed  = {},
    bfPrevTargetPos       = {},
    bfPrevTargetTime      = {},
    -- shrink
    shrinkDroneRefs  = {},
    shrinkTrackRefs  = {},
    shrinkAnimConns  = {},
    -- misc
    whitelist        = {},
    StatusParagraph  = nil,
    originalFallenHeight = Workspace.FallenPartsDestroyHeight,
    -- kokusen
    kokusenSelectedTarget = "",
    kokusenIsExecuting    = false,
    kokusenCFLoop         = nil,
    dashMultiplierEnabled = false,
    dashMultiplierValue   = 1,
    yonkEnabled     = false,
    yonkSpeed       = 1,
    yonkAnimTrack   = nil,
    yonkAnim        = nil,
    hiromiEnabled   = false,
    hiromiMinMs     = 120,
    hiromiMaxMs     = 220,
    lockOnEnabled        = false,
    lockOnOrigAutoRotate = true,
    lockOnToggleOn = false,
}

-- ============================================================
-- CONNECTIONS TABLE
-- ============================================================
local Cn = {
    noclipConn           = nil,
    invisCharConn        = nil,
    invis2CharConn       = nil,
    shrinkCharConn       = nil,
    noDashCooldownConn   = nil,
    wallhopConn1         = nil,
    wallhopConn2         = nil,
    bfHeartbeatConn      = nil,
    bfCharConn           = nil,
    bfPlayerAddedConn    = nil,
    bfPlayerRemovingConn = nil,
    bfAttackConns        = {},
    flyConnection        = nil,
    mobileFlyThumbConn   = nil,
    overlayUpdateConn    = nil,
    nanamiRatioConn = nil,
    hiromiConn      = nil,
    yonkCharConn    = nil,
    dashMultCharConn = nil,
    lockOnConn = nil,
    attachLoopConn = nil,
}

local Keys = {
    sweepKey = Enum.KeyCode.E,
    huntKey  = Enum.KeyCode.Y,
    stopKey  = Enum.KeyCode.H,
    voidKey  = Enum.KeyCode.V,
    bfKey    = Enum.KeyCode.G,
    flyKey   = Enum.KeyCode.X,
    yonkKey = Enum.KeyCode.J,
    lockOnKey = Enum.KeyCode.C,
}

local flyKeys = { W=false, A=false, S=false, D=false, Up=false, Down=false, Boost=false }
local mobileFlyVector = Vector3.zero

-- ============================================================
-- HELPERS / UTILS
-- ============================================================
local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title=title, Text=text, Duration=dur or 4})
    end)
end

local function makeStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(30, 80, 180)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function setStatus(text)
    if St.StatusParagraph then pcall(function() St.StatusParagraph:SetText(text) end) end
end

local function waitForCharacter()
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hrp and hum and hum.Health > 0 then return char end
    end
    local result
    local conn = LocalPlayer.CharacterAdded:Connect(function(c) result = c end)
    local t0 = tick()
    while not result and tick()-t0 < 10 do
        task.wait(0.05)
        local c = LocalPlayer.Character
        if c and c ~= char then result = c end
    end
    conn:Disconnect()
    return result or LocalPlayer.Character
end

-- ============================================================
-- DOMAIN CACHE
-- ============================================================
local domainsFolder    = Workspace:FindFirstChild("Domains")
local domainPartsCache = {}
local cacheBuilding    = false


local function rebuildDomainCache()
    if cacheBuilding then return end
    cacheBuilding = true
    task.spawn(function()
        local nc = {}
        if domainsFolder then
            local ok, descs = pcall(function() return domainsFolder:GetDescendants() end)
            if ok and descs then
                for _, obj in ipairs(descs) do
                    if obj:IsA("BasePart") then table.insert(nc, obj) end
                end
            end
        end
        domainPartsCache = nc
        cacheBuilding = false
    end)
end
rebuildDomainCache()

if domainsFolder then
    domainsFolder.ChildAdded:Connect(function() task.wait(0.5); rebuildDomainCache() end)
    domainsFolder.ChildRemoved:Connect(function() task.wait(0.1); rebuildDomainCache() end)
end

if not domainsFolder then
    Workspace.ChildAdded:Connect(function(child)
        if child.Name == "Domains" then
            domainsFolder = child
            rebuildDomainCache()
            child.ChildAdded:Connect(function() task.wait(0.5); rebuildDomainCache() end)
            child.ChildRemoved:Connect(function() task.wait(0.1); rebuildDomainCache() end)
        end
    end)
end

local function isInsideDomainRaw(worldPos)
    for _, part in ipairs(domainPartsCache) do
        if part and part.Parent then
            local ok, result = pcall(function()
                local lp = part.CFrame:PointToObjectSpace(worldPos)
                local h  = part.Size / 2
                return math.abs(lp.X)<=h.X and math.abs(lp.Y)<=h.Y and math.abs(lp.Z)<=h.Z
            end)
            if ok and result then return true end
        end
    end
    return false
end

local function hasDomainTag(character)
    if not character then return false end
    local info = character:FindFirstChild("Info")
    return info and info:FindFirstChild("DomainTag") ~= nil
end

local function isSelfInsideDomain()
    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return false end
    if hasDomainTag(myChar) then return true end
    return isInsideDomainRaw(myHRP.Position)
end

local function isTargetInsideDomain(target)
    if not target or not target.Core or not target.Core.Parent then return false end
    if target.Char and hasDomainTag(target.Char) then return true end
    return isInsideDomainRaw(target.Core.Position)
end

-- ============================================================
-- TARGET HELPERS
-- ============================================================
local _npcCache     = {}
local _npcCacheTime = 0
local NPC_CACHE_TTL = 2 -- seconds

local function getValidTargets(myHRP)
    local targets = {}
    -- Players are always live-scanned (small list, fast)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum  = p.Character:FindFirstChildOfClass("Humanoid")
            local core = p.Character:FindFirstChild("Torso")
                      or p.Character:FindFirstChild("UpperTorso")
                      or p.Character:FindFirstChild("HumanoidRootPart")
            if hum and core and hum.Health > 0 then
                table.insert(targets, 1, {Humanoid=hum, Core=core, Char=p.Character, name=p.Name})
            end
        end
    end
    if Cfg.INCLUDE_NPCS then
        local now = tick()
        -- Rebuild NPC cache only every 2 seconds
       if now - _npcCacheTime > NPC_CACHE_TTL then
            _npcCacheTime = now
            _npcCache = {}
            local function _scanNPCs(container)
                for _, model in ipairs(container:GetChildren()) do
                    if model:IsA("Model") and not Players:GetPlayerFromCharacter(model) then
                        local hum = model:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            local core = model:FindFirstChild("Torso")
                                     or model:FindFirstChild("UpperTorso")
                                     or model:FindFirstChild("HumanoidRootPart")
                            if core then
                                table.insert(_npcCache, {Humanoid=hum, Core=core, Char=model, name=model.Name})
                            end
                        end
                    end
                end
            end
            _scanNPCs(Workspace)
            for _, fn in ipairs({"Characters","NPCs","Enemies","Mobs","Bosses"}) do
                local f = Workspace:FindFirstChild(fn)
                if f then _scanNPCs(f) end
            end
        end
        -- Only add alive NPCs from cache
        for _, t in ipairs(_npcCache) do
            if t.Humanoid and t.Humanoid.Parent and t.Humanoid.Health > 0
                and t.Core and t.Core.Parent then
                table.insert(targets, t)
            end
        end
    end
    return targets
end

local function sortByHPPercent(targets)
    local function getPct(t)
        local m = t.Humanoid.MaxHealth
        return (not m or m <= 0) and 1 or t.Humanoid.Health / m
    end
    for i = #targets, 2, -1 do
        local j = math.random(1, i)
        targets[i], targets[j] = targets[j], targets[i]
    end
    table.sort(targets, function(a, b) return getPct(a) < getPct(b) end)
    return targets
end

local function getSweepTargets(myHRP)
    local tgts    = getValidTargets(myHRP)
    local filtered = {}
    for _, t in ipairs(tgts) do
        if not St.whitelist[t.name] then
            if St.noDomainTP then
                if not isTargetInsideDomain(t) then table.insert(filtered, t) end
            else
                table.insert(filtered, t)
            end
        end
    end
    if not St.noDomainTP and isSelfInsideDomain() then
        local domainOnly = {}
        for _, t in ipairs(filtered) do
            if isTargetInsideDomain(t) then table.insert(domainOnly, t) end
        end
        if #domainOnly > 0 then filtered = domainOnly end
    end
    if Cfg.tpPriority == "hppct" then sortByHPPercent(filtered) end
    return filtered
end

-- ============================================================
-- TELEPORT HELPERS
-- ============================================================
local function getAttackCFrame(myHRP, targetCore)
    local tp = targetCore.Position
    if Cfg.tpMode == "under" then
        local bp = Vector3.new(tp.X+Cfg.offsetX, tp.Y-3-math.abs(Cfg.offsetY), tp.Z+Cfg.offsetZ)
        return CFrame.new(bp) * CFrame.Angles(math.pi/2, 0, 0), bp
    else
        local tcf = targetCore.CFrame
        local ap  = tp + tcf.LookVector*Cfg.offsetZ + tcf.RightVector*Cfg.offsetX + Vector3.new(0, Cfg.offsetY, 0)
        return CFrame.new(ap, Vector3.new(tp.X, ap.Y, tp.Z)), ap
    end
end

local function tpBypass(targetCF)
    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP or not myHRP.Parent then return end
    local i = 0; local conn
    conn = RunService.Heartbeat:Connect(function()
        i = i + 1
        pcall(function() myHRP.CFrame = targetCF end)
        if i >= 11 then conn:Disconnect(); pcall(function() myHRP.CFrame = targetCF end) end
    end)
end

local function smartTP(myHRP, targetCF, frames)
    frames = frames or 11
    if not myHRP or not myHRP.Parent then return end
    local count = 0; local conn
    conn = RunService.Heartbeat:Connect(function()
        count = count + 1
        pcall(function() myHRP.CFrame = targetCF end)
        if count >= frames then conn:Disconnect(); pcall(function() myHRP.CFrame = targetCF end) end
    end)
    return conn
end

local function aggressiveTP(targetCF, duration)
    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHRP.Parent then return end
    duration = duration or 0.45
    St.safeTpActive = true
    local origSpeed = myHum and myHum.WalkSpeed or 16
    if myHum and myHum.Parent then
        pcall(function() myHum.AutoRotate=false; myHum.WalkSpeed=0 end)
    end
    pcall(function()
        myHRP.AssemblyLinearVelocity  = Vector3.zero
        myHRP.AssemblyAngularVelocity = Vector3.zero
    end)
    local startTime = tick(); local conn
    conn = RunService.Heartbeat:Connect(function()
        if not myHRP or not myHRP.Parent then conn:Disconnect(); St.safeTpActive=false; return end
        pcall(function()
            myHRP.CFrame = targetCF
            myHRP.AssemblyLinearVelocity  = Vector3.zero
            myHRP.AssemblyAngularVelocity = Vector3.zero
        end)
        if tick()-startTime >= duration then
            conn:Disconnect()
            if myHum and myHum.Parent then
                pcall(function() myHum.WalkSpeed=origSpeed; myHum.AutoRotate=true; myHum:Move(Vector3.zero,true) end)
            end
            local dc=0; local dconn
            dconn = RunService.Heartbeat:Connect(function()
                dc=dc+1
                pcall(function()
                    myHRP.AssemblyLinearVelocity  = Vector3.zero
                    myHRP.AssemblyAngularVelocity = Vector3.zero
                end)
                if dc>=5 then dconn:Disconnect(); St.safeTpActive=false end
            end)
        end
    end)
end

-- ============================================================
-- VOID RESET  (camera block version)
-- ============================================================
local function voidResetFallback()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    local mt  = getrawmetatable(game)
    local old = mt.__namecall
    local block = true
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and tostring(self) == "Camera" and block then return end
        return old(self, ...)
    end)
    setreadonly(mt, true)

    if hum.Sit then hum.Sit = false end
    hum.PlatformStand = false
    pcall(function() char:PivotTo(hrp.CFrame * CFrame.new(0, -30, 0)) end)
    pcall(function()
        hrp.AssemblyLinearVelocity  = Vector3.new(0, -500, 0)
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)

    task.spawn(function()
        local start = tick()
        while tick()-start < 1.6 do
            local c  = LocalPlayer.Character
            local h  = c and c:FindFirstChild("HumanoidRootPart")
            local hm = c and c:FindFirstChildOfClass("Humanoid")
            if not c or not h or not hm or hm.Health<=0 then break end
            pcall(function()
                c:PivotTo(h.CFrame * CFrame.new(0, -30, 0))
                h.AssemblyLinearVelocity = Vector3.new(0, -500, 0)
            end)
            task.wait(0.1)
        end
        block = false
        task.wait(0.5)
        local mt2 = getrawmetatable(game)
        setreadonly(mt2, false)
        mt2.__namecall = old
        setreadonly(mt2, true)
    end)
end

local function waitForDeathAndRespawn()
    local t0 = tick()
    local deadTimeout = mobile and 6 or 5
    while tick()-t0 < deadTimeout do
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if not c or not h or h.Health<=0 then break end
        task.wait(0.05)
    end
    local deadChar = LocalPlayer.Character
    local newChar
    if deadChar then
        local done = false
        local conn = LocalPlayer.CharacterAdded:Connect(function(c)
            if not done then done=true; newChar=c end
        end)
        local t1 = tick()
        local spawnTimeout = mobile and 8 or 6
        while not newChar and tick()-t1 < spawnTimeout do
            task.wait(0.05)
            local c = LocalPlayer.Character
            if c and c ~= deadChar then newChar = c end
        end
        conn:Disconnect()
    end
    local char = newChar or LocalPlayer.Character or waitForCharacter()
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local tries=0; local maxTries = mobile and 120 or 80
    while (not hrp or not hum or hum.Health<=0) and tries<maxTries do
        task.wait(0.05)
        char = LocalPlayer.Character
        if not char then char = waitForCharacter() end
        hrp  = char and char:FindFirstChild("HumanoidRootPart")
        hum  = char and char:FindFirstChildOfClass("Humanoid")
        tries=tries+1
    end
    task.wait(mobile and (Cfg.RESPAWN_WAIT+0.8) or Cfg.RESPAWN_WAIT)
    return LocalPlayer.Character
end

-- ============================================================
-- CYCLE CHECK
-- ============================================================
local function checkCycle()
    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myChar or not myHRP or not myHum then return nil, "No character" end
    if myHum.Health<=0 then return nil, "Humanoid not ready" end
    local targets = getValidTargets(myHRP)
    if #targets==0 then return nil, "No targets" end
    local testTarget
    for _, t in ipairs(targets) do
        if t.Core and (myHRP.Position-t.Core.Position).Magnitude >= Cfg.MIN_TARGET_DISTANCE then
            testTarget=t; break
        end
    end
    if not testTarget then return nil, "All targets too close" end
    local startCF = myChar:GetPivot()
    local function doSnapTest(attackCF, attackPos, dur)
        pcall(function() myChar:PivotTo(attackCF) end)
        myHRP.AssemblyLinearVelocity  = Vector3.zero
        myHRP.AssemblyAngularVelocity = Vector3.zero
        RunService.Heartbeat:Wait(); RunService.Heartbeat:Wait()
        if (myHRP.Position-attackPos).Magnitude > Cfg.SNAP_THRESHOLD then
            pcall(function() myChar:PivotTo(startCF) end); return false, false
        end
        local t0=tick(); local snapped=false
        while tick()-t0 < dur do
            RunService.Heartbeat:Wait()
            myChar = LocalPlayer.Character
            myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myChar or not myHRP then return nil, true end
            if (myHRP.Position-attackPos).Magnitude > Cfg.SNAP_THRESHOLD then snapped=true; break end
        end
        pcall(function() myChar:PivotTo(startCF) end)
        return not snapped, false
    end
    local attackCF1, attackPos1 = getAttackCFrame(myHRP, testTarget.Core)
    local pass1, lost1 = doSnapTest(attackCF1, attackPos1, Cfg.STABILITY_DURATION)
    if lost1 then return nil, "Character lost" end
    if not pass1 then return false end
    myHRP.AssemblyLinearVelocity=Vector3.zero; myHRP.AssemblyAngularVelocity=Vector3.zero
    task.wait(0.05)
    local attackCF2, attackPos2 = getAttackCFrame(myHRP, testTarget.Core)
    local pass2, lost2 = doSnapTest(attackCF2, attackPos2, 0.2)
    if lost2 then return nil, "Character lost" end
    return pass2
end

-- ============================================================
-- AC CHECK
-- ============================================================
local function checkACStatus()
    setStatus("Checking AC...")
    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myChar or not myHRP then notify("AC Check","No character.",4); setStatus("Idle"); return end
    local others={}
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if (myHRP.Position-p.Character.HumanoidRootPart.Position).Magnitude >= Cfg.MIN_TARGET_DISTANCE then
                table.insert(others, p)
            end
        end
    end
    if #others==0 then notify("AC Check","No far players found.",4); setStatus("Idle"); return end
    local target    = others[math.random(1,#others)]
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then setStatus("Idle"); return end
    local savedCF = myHRP.CFrame
    local tpPos   = targetHRP.CFrame * CFrame.new(0,0,Cfg.offsetZ+1)
    pcall(function() myChar:PivotTo(tpPos) end)
    myHRP.AssemblyLinearVelocity=Vector3.zero
    RunService.Heartbeat:Wait(); RunService.Heartbeat:Wait()
    local snapped=false; local t0=tick()
    while tick()-t0 < Cfg.STABILITY_DURATION do
        RunService.Heartbeat:Wait()
        myChar = LocalPlayer.Character
        myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myChar or not myHRP then snapped=true; break end
        if (myHRP.Position-tpPos.Position).Magnitude > Cfg.SNAP_THRESHOLD then snapped=true; break end
    end
    pcall(function() myChar:PivotTo(savedCF) end)
    if snapped then
        notify("AC ACTIVE","Teleported back. AC is active.",6); setStatus("AC Active (no bypass)")
    else
        notify("AC BYPASSED","Bypass working!",6); setStatus("AC Bypassed")
    end
end

-- ============================================================
-- SWEEP
-- ============================================================
local startOverlayUpdates = function() end
local stopOverlayUpdates  = function() end
local resolveOverlay      = function() end
local buildOverlay        = function(_) end
local destroyOverlay      = function() end

local function doTP(myChar, myHRP, attackCF)
    if Cfg.tpMethod == "smart" then
        smartTP(myHRP, attackCF, 11)
    else
        pcall(function() myChar:PivotTo(attackCF) end)
        myHRP.AssemblyLinearVelocity  = Vector3.zero
        myHRP.AssemblyAngularVelocity = Vector3.zero
    end
end

local function runSweepNormal()
    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myChar or not myHRP then St.sweepActive=false; return end
    -- Rebuild domain cache fresh at sweep start if stale (older than 30s)
    if not cacheBuilding and (tick() - (_lastDomainRebuild or 0)) > 30 then
        _lastDomainRebuild = tick()
        rebuildDomainCache()
        task.wait(0.1) -- brief wait for cache to populate
    end
    local startCFrame  = myHRP.CFrame
    local skySanctuary = startCFrame * CFrame.new(0, 1000, 0)

    if Cfg.sweepMode == "faster" then
        local sweepIndex = 1
        if Cfg.tpMethod == "smart" then
            local prevHP = {}
            local sweepConn
            sweepConn = RunService.Heartbeat:Connect(function()
                if not St.sweepActive then sweepConn:Disconnect(); return end
                myChar = LocalPlayer.Character
                myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if not myChar or not myHRP or not myHRP.Parent then return end
                local sweepTgts = getSweepTargets(myHRP)
                if #sweepTgts==0 then return end
                if sweepIndex>#sweepTgts then sweepIndex=1 end
                local tgt = sweepTgts[sweepIndex]; sweepIndex=sweepIndex+1
                if not tgt or not tgt.Core or not tgt.Core.Parent then return end
                if tgt.Humanoid.Health<=0 then return end
                local hpBefore = prevHP[tgt.name] or tgt.Humanoid.Health
                local attackCF = getAttackCFrame(myHRP, tgt.Core)
                pcall(function() myHRP.CFrame = attackCF end)
                local hpNow = tgt.Humanoid.Health
                if hpNow<hpBefore or hpNow<=0 then pcall(function() myHRP.CFrame=skySanctuary end) end
                prevHP[tgt.name] = hpNow
            end)
            while St.sweepActive do RunService.Heartbeat:Wait() end
            if sweepConn then sweepConn:Disconnect() end
        else
            while St.sweepActive do
                myChar = LocalPlayer.Character
                myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if not myChar or not myHRP or not myHRP.Parent then
                    RunService.Heartbeat:Wait()
                else
                    local sweepTgts = getSweepTargets(myHRP)
                    if #sweepTgts==0 then RunService.Heartbeat:Wait()
                    else
                        if sweepIndex>#sweepTgts then sweepIndex=1 end
                        local tgt=sweepTgts[sweepIndex]; sweepIndex=sweepIndex+1
                        if tgt and tgt.Core and tgt.Core.Parent and tgt.Humanoid and tgt.Humanoid.Health>0 then
                            doTP(myChar, myHRP, getAttackCFrame(myHRP, tgt.Core))
                        end
                        RunService.Heartbeat:Wait()
                    end
                end
            end
        end
    else
        while St.sweepActive do
            myChar = LocalPlayer.Character
            myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myChar or not myHRP or not myHRP.Parent then
                RunService.Heartbeat:Wait()
            else
                local sweepTgts = getSweepTargets(myHRP)
                if #sweepTgts==0 then RunService.Heartbeat:Wait()
                else
                    local anyTeleported=false
                    for _, tgt in ipairs(sweepTgts) do
                        if St.sweepActive then
                            if tgt.Core and tgt.Core.Parent and tgt.Humanoid.Health>0 then
                                anyTeleported=true
                                local hpBefore=tgt.Humanoid.Health
                                doTP(myChar, myHRP, getAttackCFrame(myHRP, tgt.Core))
                                RunService.Heartbeat:Wait()
                                if St.sweepActive then
                                    local hpAfter=(tgt.Humanoid and tgt.Humanoid.Parent) and tgt.Humanoid.Health or 0
                                    if hpAfter<hpBefore or hpAfter<=0 then
                                        pcall(function() myChar:PivotTo(skySanctuary) end)
                                    end
                                end
                            end
                        end
                    end
                    if not anyTeleported then RunService.Heartbeat:Wait() end
                end
            end
        end
    end

    myChar = LocalPlayer.Character
    if myChar then
        local hrp = myChar:FindFirstChild("HumanoidRootPart")
        if hrp then
            if Cfg.tpMethod == "smart" then
                smartTP(hrp, startCFrame, 11); task.wait(0.25)
                pcall(function() myChar:PivotTo(startCFrame) end)
                hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
            else
                tpBypass(startCFrame)
            end
        end
    end
end

local runSweep
runSweep = function()
    setStatus("SWEEPING...")
    runSweepNormal()
    setStatus("Idle")
end

-- ============================================================
-- HUNT
-- ============================================================
local function runHunt()
    if St.huntRunning then return end
    St.huntRunning = true
    setStatus("Hunting...")
    notify("Hunting","Press H to stop.",3)
    local attempts=0
    while St.huntRunning and attempts<Cfg.MAX_HUNT_ATTEMPTS do
        attempts=attempts+1
        setStatus("Attempt "..attempts.." / "..Cfg.MAX_HUNT_ATTEMPTS)
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hum or hum.Health<=0 then
            char = waitForDeathAndRespawn()
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
            end
        end
        if not St.huntRunning then break end
        task.wait(mobile and 0.6 or 0.2)
        local result, err = checkCycle()
        if result==true then
            St.luckyCycleFound=true; St.huntRunning=false
            notify("LUCKY CYCLE!","Got it in "..attempts.." tries. Sweep now.",8)
            setStatus("Lucky — "..attempts.." tries")
            break
        elseif result==false then
            if not St.huntRunning then break end
            setStatus("Voiding...")
            voidResetFallback()
            waitForDeathAndRespawn()
            task.wait(mobile and 0.8 or 0.4)
        else
            setStatus("Waiting: "..(err or "no far targets"))
            task.wait(0.5)
        end
    end
    if attempts>=Cfg.MAX_HUNT_ATTEMPTS then notify("Hunt Stopped","Max attempts.",5) end
    St.huntRunning=false
    if not St.luckyCycleFound and not St.sweepActive then setStatus("Idle") end
end

-- ============================================================
-- STOP ALL
-- ============================================================
local function stopAll()
    St.sweepActive=false; St.huntRunning=false; St.luckyCycleFound=false
    St.attachActive=false; St.attachTarget=nil; St.attachLoopId=St.attachLoopId+1
    Workspace.FallenPartsDestroyHeight = St.originalFallenHeight
    setStatus("Stopped"); notify("Stopped","All stopped.",3)
end

-- ============================================================
-- ATTACH
-- ============================================================
local function updateAttachHRP()
    local char = LocalPlayer.Character
    St.attachHRP = char and char:FindFirstChild("HumanoidRootPart")
end
updateAttachHRP()

LocalPlayer.CharacterAdded:Connect(function(char)
    St.attachHRP = char:WaitForChild("HumanoidRootPart", 10)
    St.attachSavedPos = nil
    if St.attachActive and St.attachTarget then
        local targetName = St.attachTarget.name
        local found=false; local searchStart=tick()
        while tick()-searchStart<5 do
            task.wait(0.2)
            if not St.attachActive then found=true; break end
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name==targetName and p.Character then
                    local nh=p.Character:FindFirstChildOfClass("Humanoid")
                    local nc=p.Character:FindFirstChild("HumanoidRootPart")
                           or p.Character:FindFirstChild("UpperTorso")
                           or p.Character:FindFirstChild("Torso")
                    if nh and nc and nh.Health>0 then
                        St.attachTarget={Humanoid=nh,Core=nc,Char=p.Character,name=p.Name}
                        found=true; break
                    end
                end
            end
            if found then break end
        end
        if not found then
            St.attachActive=false; St.attachTarget=nil; St.attachLoopId=St.attachLoopId+1
            notify("Attach","Target lost after respawn. Detached.",4); setStatus("Idle")
        end
    end
end)

local function startAttach(liveTarget)
    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if myHRP and myHRP.Parent then St.attachSavedPos = myHRP.CFrame end
    Workspace.FallenPartsDestroyHeight = Cfg.fallenHeight
    St.attachActive=true; St.attachTarget=liveTarget; St.attachLoopId=St.attachLoopId+1
    -- Start loop only now
    if Cn.attachLoopConn then Cn.attachLoopConn:Disconnect() end
    local _lastRun=0
    Cn.attachLoopConn=RunService.Heartbeat:Connect(function()
        if St.safeTpActive then return end
        if not St.attachActive or not St.attachTarget then return end
        local now=tick()
        if now-_lastRun < 0.05 then return end
        _lastRun=now
        if not St.attachHRP or not St.attachHRP.Parent then updateAttachHRP(); return end
        local core=St.attachTarget.Core
        local hum=St.attachTarget.Humanoid
        if not core or not core.Parent or not hum or hum.Health<=0 then
            local targetName=St.attachTarget.name; St.attachActive=false
            task.spawn(function()
                local found=false; local searchStart=tick()
                while tick()-searchStart<5 do
                    task.wait(0.2)
                    for _,p in ipairs(Players:GetPlayers()) do
                        if p.Name==targetName and p.Character then
                            local nh=p.Character:FindFirstChildOfClass("Humanoid")
                            local nc=p.Character:FindFirstChild("HumanoidRootPart")
                                   or p.Character:FindFirstChild("UpperTorso")
                                   or p.Character:FindFirstChild("Torso")
                            if nh and nc and nh.Health>0 then
                                St.attachTarget={Humanoid=nh,Core=nc,Char=p.Character,name=p.Name}
                                found=true; break
                            end
                        end
                    end
                    if found then break end
                end
                if found then St.attachActive=true
                else
                    St.attachTarget=nil; St.attachLoopId=St.attachLoopId+1
                    if Cn.attachLoopConn then Cn.attachLoopConn:Disconnect(); Cn.attachLoopConn=nil end
                    notify("Attach","Target lost. Detached.",4); setStatus("Idle")
                end
            end)
            return
        end
        pcall(function() St.attachHRP.CFrame=core.CFrame*CFrame.new(Cfg.offsetX,Cfg.offsetY,Cfg.offsetZ) end)
    end)
end

local function stopAttach()
    St.attachActive=false
    if Cn.attachLoopConn then Cn.attachLoopConn:Disconnect(); Cn.attachLoopConn=nil end
    Workspace.FallenPartsDestroyHeight=St.originalFallenHeight
    local savedCF=St.attachSavedPos; St.attachSavedPos=nil; St.attachTarget=nil; St.attachLoopId=St.attachLoopId+1
    if savedCF then aggressiveTP(savedCF,0.45) end
end

-- ============================================================
-- EXTRAS: SHRINK HITBOX
-- ============================================================
local function cleanupShrinkForChar(char)
    if not char then return end
    local ref=St.shrinkDroneRefs[char]
    if ref and ref.Parent then pcall(function() ref:Destroy() end) end
    St.shrinkDroneRefs[char]=nil
    local track=St.shrinkTrackRefs[char]
    if track then pcall(function() track:Stop(); track:Destroy() end) end
    St.shrinkTrackRefs[char]=nil
    local conn=St.shrinkAnimConns[char]
    if conn then conn:Disconnect() end
    St.shrinkAnimConns[char]=nil
end

local function setupShrinkForChar(char)
    if not char then return end
    task.spawn(function()
        local ok, model = pcall(function() return InsertService:LoadAsset(Cfg.DRONE_ID) end)
        if ok and model then
            local accessory=model:FindFirstChildOfClass("Accessory")
            if accessory then
                local humanoid=char:FindFirstChildOfClass("Humanoid")
                accessory.Parent=char
                if humanoid then pcall(function() humanoid:AddAccessory(accessory) end) end
                St.shrinkDroneRefs[char]=accessory
            end
            model:Destroy()
        end
    end)
    local humanoid=char:WaitForChild("Humanoid",5)
    if not humanoid then return end
    local animator=humanoid:FindFirstChildOfClass("Animator")
    if not animator then animator=Instance.new("Animator"); animator.Parent=humanoid end
    local animation=Instance.new("Animation"); animation.AnimationId=Cfg.SHRINK_ANIM_ID
    local ok2, track=pcall(function() return animator:LoadAnimation(animation) end)
    if not ok2 or not track then return end
    St.shrinkTrackRefs[char]=track
    pcall(function() track:Play(); task.wait(); track.TimePosition=2.1; track:AdjustSpeed(0) end)
    local animConn=humanoid.AnimationPlayed:Connect(function(playedTrack)
        if not St.shrinkHitboxActive then return end
        local id=playedTrack.Animation and playedTrack.Animation.AnimationId or ""
        if id~=Cfg.SHRINK_ANIM_ID then pcall(function() playedTrack:Stop(); playedTrack:Destroy() end) end
    end)
    St.shrinkAnimConns[char]=animConn
end

-- ============================================================
-- EXTRAS: INVISIBILITY / NOCLIP
-- (camera is NOT touched in cleanup to preserve shiftlock)
-- ============================================================
-- ============================================================
-- EXTRAS: INVISIBILITY / NOCLIP
-- SHIFTLOCK + DASH SAFE VERSION
-- ============================================================

St.invisAnimTrack = nil

-- ============================================================
-- INVIS
-- ============================================================

-- ============================================================
-- INVISIBILITY (SHIFTLOCK SAFE / STABLE VERSION)
-- ============================================================

local function setupInvisForChar(char)
    if not char then return end
    local humanoid=char:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return end
    local animator=humanoid:FindFirstChildOfClass("Animator")
    if not animator then animator=Instance.new("Animator"); animator.Parent=humanoid end
    local anim=Instance.new("Animation"); anim.AnimationId=Cfg.INVIS_ANIM_ID
    local ok, track=pcall(function() return animator:LoadAnimation(anim) end)
    if not ok or not track then return end
    St.invisAnimTrack=track
    pcall(function()
        track:Play()
        task.wait()
        track.TimePosition=Cfg.INVIS_FREEZE_TIME
        track:AdjustSpeed(0)
    end)
    -- No Camera.CameraSubject changes: shiftlock stays intact
end

local function cleanupInvis(char)
    -- Stop animation; no camera manipulation so shiftlock is unaffected
    if St.invisAnimTrack then
        pcall(function()
            St.invisAnimTrack:AdjustSpeed(1)
            St.invisAnimTrack:Stop(0)
            St.invisAnimTrack:Destroy()
        end)
        St.invisAnimTrack=nil
    end
    if not char then return end
    -- Restart Animate to hand back normal locomotion animations
    local animateScript=char:FindFirstChild("Animate")
    if animateScript then
        animateScript.Disabled=true
        task.wait(0.05)
        animateScript.Disabled=false
    end
end

local function startNoclip()
    if Cn.noclipConn then Cn.noclipConn:Disconnect(); Cn.noclipConn=nil end
    Cn.noclipConn=RunService.Stepped:Connect(function()
        local char=LocalPlayer.Character; if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide=false end
        end
    end)
end

local function stopNoclip()
    if Cn.noclipConn then Cn.noclipConn:Disconnect(); Cn.noclipConn=nil end
    local char=LocalPlayer.Character; if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide=true end
    end
    -- do NOT touch CameraSubject here — it breaks shiftlock
end
-- ============================================================
-- EXTRAS: NO DASH COOLDOWN / WALLHOP
-- ============================================================
local function enableNoDashCooldown()
    if Cn.noDashCooldownConn then return end
    pcall(function()
        local ok, movCtrl=pcall(function()
            return require(LocalPlayer.PlayerScripts.Controllers.Character.MovementController)
        end)
        if not ok or not movCtrl then return end
        local dashFn=movCtrl.DashRequest; if not dashFn then return end
        Cn.noDashCooldownConn=RunService.RenderStepped:Connect(function()
            pcall(function() debug.setupvalue(dashFn,4,0); debug.setupvalue(dashFn,6,999) end)
        end)
    end)
end

local function disableNoDashCooldown()
    if Cn.noDashCooldownConn then Cn.noDashCooldownConn:Disconnect(); Cn.noDashCooldownConn=nil end
end

local wallhopAnimR=Instance.new("Animation"); wallhopAnimR.AnimationId="rbxassetid://94327920127463"
local wallhopAnimL=Instance.new("Animation"); wallhopAnimL.AnimationId="rbxassetid://113609963676386"
local wallhopMapParams=RaycastParams.new(); wallhopMapParams.FilterType=Enum.RaycastFilterType.Include
local function setupWallhopMapParams()
    local mapFolder=Workspace:FindFirstChild("Map")
    if mapFolder then wallhopMapParams.FilterDescendantsInstances={mapFolder} end
end
setupWallhopMapParams()
Workspace.ChildAdded:Connect(function(child)
    if child.Name=="Map" then setupWallhopMapParams() end
end)

local function enableNoWallhopCooldown()
    pcall(function()
        local mod=require(LocalPlayer.PlayerScripts.Controllers.Character.MovementController)
        local function getUV(fn, idx)
            if type(fn)~="function" then return nil end
            local ok, val=pcall(debug.getupvalue,fn,idx); return ok and val or nil
        end
        local layer1=getUV(mod.Parkour,1)
        local actualParkour=layer1 and getUV(layer1,1)
        if actualParkour then
            if Cn.wallhopConn1 then Cn.wallhopConn1:Disconnect() end
            Cn.wallhopConn1=RunService.Heartbeat:Connect(function()
                pcall(debug.setupvalue,actualParkour,2,0)
            end)
        end
    end)
    if not St.wallhopMetaHooked then
        St.wallhopMetaHooked=true
        pcall(function()
            local mt=getrawmetatable(game); local oldNc=mt.__namecall
            setreadonly(mt,false)
            mt.__namecall=newcclosure(function(self,...)
                if getnamecallmethod()=="GetAttribute" then
                    if (...)=="Parkour" and self.Name=="Info" then return nil end
                end
                return oldNc(self,...)
            end)
            setreadonly(mt,true)
        end)
    end
    local lastAssist=0
    if Cn.wallhopConn2 then Cn.wallhopConn2:Disconnect() end
  local _wallhopLastCheck = 0
    Cn.wallhopConn2=RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - _wallhopLastCheck < 0.1 then return end
        _wallhopLastCheck = now
        local char=LocalPlayer.Character; if not char then return end
        local hrp=char:FindFirstChild("HumanoidRootPart")
        local hum=char:FindFirstChild("Humanoid")
        if not hrp or not hum then return end
        if hum:GetState()~=Enum.HumanoidStateType.Freefall then return end
        if hum.Jump~=true then return end
        if char:GetAttribute("Movement") then return end
        if tick()-lastAssist<0.35 then return end
        local right=hrp.CFrame.RightVector; local wallDir=nil
        if Workspace:Raycast(hrp.Position,right*6,wallhopMapParams) then wallDir=1
        elseif Workspace:Raycast(hrp.Position,-right*6,wallhopMapParams) then wallDir=-1 end
        if not wallDir then return end
        lastAssist=tick()
        for _, s in hrp:GetChildren() do
            if s:IsA("Sound") and s.Name=="Falling" then
                local prev=s.Volume; s.Volume=0; task.delay(0.5,function() s.Volume=prev end)
            end
        end
        local animator=hum:FindFirstChildOfClass("Animator")
        if animator then
            local track=animator:LoadAnimation(wallDir==1 and wallhopAnimR or wallhopAnimL)
            track.Priority=Enum.AnimationPriority.Action; track:Play(0.05)
            task.delay(0.5,function() track:Stop(0.1) end)
        end
        local up=hrp.CFrame.UpVector
        local look=(hrp.CFrame.LookVector*Vector3.new(1,0,1)).Unit
        char:SetAttribute("Movement",true); task.delay(0.4,function() char:SetAttribute("Movement",nil) end)
        local bv=Instance.new("BodyVelocity")
        bv.MaxForce=Vector3.new(1e5,1e5,1e5)
        bv.Velocity=up*30-right*(wallDir*35)+look*25; bv.Parent=hrp
        Debris:AddItem(bv,0.25)
    end)
    notify("Wallhop","No Cooldown + Assist Active.",3)
end

local function disableNoWallhopCooldown()
    if Cn.wallhopConn1 then Cn.wallhopConn1:Disconnect(); Cn.wallhopConn1=nil end
    if Cn.wallhopConn2 then Cn.wallhopConn2:Disconnect(); Cn.wallhopConn2=nil end
    notify("Wallhop","Disabled.",2)
end

-- ============================================================
-- ITEMS
-- ============================================================
local function zeroAllPrompts()
    local folder=Workspace:FindFirstChild("Items"); if not folder then return end
    for _, item in ipairs(folder:GetChildren()) do
        local prompt=item:FindFirstChildWhichIsA("ProximityPrompt",true)
        if prompt then prompt.HoldDuration=0 end
    end
end
zeroAllPrompts()

local itemsFolder=Workspace:FindFirstChild("Items")
if itemsFolder then
    itemsFolder.ChildAdded:Connect(function(item)
        task.wait(0.05)
        local prompt=item:FindFirstChildWhichIsA("ProximityPrompt",true)
        if prompt then prompt.HoldDuration=0 end
    end)
end
Workspace.ChildAdded:Connect(function(child)
    if child.Name=="Items" then
        itemsFolder=child; zeroAllPrompts()
        child.ChildAdded:Connect(function(item)
            task.wait(0.05)
            local prompt=item:FindFirstChildWhichIsA("ProximityPrompt",true)
            if prompt then prompt.HoldDuration=0 end
        end)
    end
end)

local function grabItem(item, onDone)
    local prompt=item:FindFirstChildWhichIsA("ProximityPrompt",true)
    if not prompt then notify("Item Grab","No prompt found!",3); if onDone then onDone(false) end; return end
    local char=LocalPlayer.Character; if not char then if onDone then onDone(false) end; return end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then if onDone then onDone(false) end; return end
    local itemPos
    if item:IsA("BasePart") then itemPos=item.Position
    elseif item:IsA("Model") and item.PrimaryPart then itemPos=item.PrimaryPart.Position
    else if onDone then onDone(false) end; return end
    local returnCFrame=hrp.CFrame; prompt.HoldDuration=0
    local grabCFrame=CFrame.new(itemPos+Vector3.new(0,1.5,0))
    local done=false
    local function finish(success)
        if done then return end; done=true
        if hrp and hrp.Parent then hrp.CFrame=returnCFrame end
        if onDone then onDone(success) end
    end
    local removeConn
    local f2=Workspace:FindFirstChild("Items")
    if f2 then
        removeConn=f2.ChildRemoved:Connect(function(removed)
            if removed==item then if removeConn then removeConn:Disconnect() end; finish(true) end
        end)
    end
    local renderConn
    renderConn=RunService.RenderStepped:Connect(function()
        if done then renderConn:Disconnect(); return end
        if not hrp or not hrp.Parent then
            renderConn:Disconnect()
            if removeConn then removeConn:Disconnect() end
            finish(false); return
        end
        hrp.CFrame=grabCFrame
        pcall(function() fireproximityprompt(prompt,0) end)
    end)
    task.delay(2,function()
        if not done then
            renderConn:Disconnect()
            if removeConn then removeConn:Disconnect() end
            if hrp and hrp.Parent then hrp.CFrame=returnCFrame end
            finish(false)
        end
    end)
end

local function getItemsList()
    local items={}; local folder=Workspace:FindFirstChild("Items"); if not folder then return items end
    local myChar=LocalPlayer.Character; local myHRP=myChar and myChar:FindFirstChild("HumanoidRootPart")
    for _, child in ipairs(folder:GetChildren()) do
        local prompt=child:FindFirstChildWhichIsA("ProximityPrompt",true)
        if prompt then
            local pos; local ok, result=pcall(function()
                if child:IsA("BasePart") then return child.Position
                elseif child:IsA("Model") then return child:GetPivot().Position end
            end)
            if ok and result then pos=result end
            if pos then
                local tooHigh=pos.Y>500; local tooFar=false
                if myHRP then
                    local fd=Vector2.new(pos.X-myHRP.Position.X,pos.Z-myHRP.Position.Z).Magnitude
                    tooFar=fd>1000
                end
                if not tooHigh and not tooFar then
                    table.insert(items,{name=child.Name,part=child,prompt=prompt,position=pos})
                end
            end
        end
    end
    return items
end

-- ============================================================
-- BLACK FLASH SYSTEM
-- ============================================================
do
    local BF = Cfg.BF

    local function bfGetHRP(character)
        return character and (
            character:FindFirstChild("HumanoidRootPart")
            or character:FindFirstChild("Torso")
            or character:FindFirstChild("UpperTorso")
        )
    end

   local function bfUpdateSmoothedLook(targetPlayer, tHRP)
        if not tHRP or not tHRP.Parent then return end
        local raw = Vector3.new(tHRP.CFrame.LookVector.X, 0, tHRP.CFrame.LookVector.Z)
        if raw.Magnitude < 0.01 then return end
        raw = raw.Unit
        local prev = St.bfTargetLookSmoothed[targetPlayer]
        if not prev then St.bfTargetLookSmoothed[targetPlayer] = raw; return end
        -- Snap on large changes (shiftlock), smooth on small jitter
        local changeDot = prev:Dot(raw)
        if changeDot < 0.5 then
            St.bfTargetLookSmoothed[targetPlayer] = raw
        else
            local blended = prev:Lerp(raw, 0.5)
            St.bfTargetLookSmoothed[targetPlayer] = blended.Magnitude > 0.01 and blended.Unit or raw
        end
    end

    local function bfGetSmoothedLook(targetPlayer, tHRP)
        local cached=St.bfTargetLookSmoothed[targetPlayer]
        if cached then return cached end
        if not tHRP then return Vector3.new(0,0,1) end
        local raw=Vector3.new(tHRP.CFrame.LookVector.X,0,tHRP.CFrame.LookVector.Z)
        return raw.Magnitude>0.01 and raw.Unit or Vector3.new(0,0,1)
    end

    local function bfClearTarget(tp)
        St.bfTargetLookSmoothed[tp]=nil; St.bfPrevTargetPos[tp]=nil; St.bfPrevTargetTime[tp]=nil
    end

    local function bfGetTargetVelocity(targetPlayer, tHRP)
        local now=tick()
        local pos=Vector3.new(tHRP.Position.X,0,tHRP.Position.Z)
        local vel=Vector3.zero
        if St.bfPrevTargetPos[targetPlayer] and St.bfPrevTargetTime[targetPlayer] then
            local dt=now-St.bfPrevTargetTime[targetPlayer]
            if dt>0 and dt<0.5 then vel=(pos-St.bfPrevTargetPos[targetPlayer])/dt end
        end
        St.bfPrevTargetPos[targetPlayer]=pos; St.bfPrevTargetTime[targetPlayer]=now
        return vel
    end

    local function bfFireActivated()
        local char=LocalPlayer.Character; if not char then return end
        local moveset=char:FindFirstChild("Moveset"); if not moveset then return end
        local move=moveset:FindFirstChild("Divergent Fist"); if not move then return end
        local ok, re=pcall(function()
            return ReplicatedStorage.Knit.Knit.Services.DivergentFistService.RE.Activated
        end)
        if not ok or not re then return end
        re:FireServer(move)
    end

    local function bfGetNearestPlayer(maxRange)
        local myHRP=bfGetHRP(LocalPlayer.Character); if not myHRP then return nil end
        local bestPlayer, bestScore=nil, math.huge
        for _, pl in pairs(Players:GetPlayers()) do
            if pl~=LocalPlayer and pl.Character then
                local hum=pl.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health>0 then
                    local tHRP=bfGetHRP(pl.Character)
                    if tHRP then
                        local dist=(myHRP.Position-tHRP.Position).Magnitude
                        if dist<=maxRange then
                            local score=dist
                            local at=St.bfLastAttackTime[pl]
                            if at and (tick()-at)<Cfg.BF_RECENCY then score=score-999 end
                            if score<bestScore then bestScore=score; bestPlayer=pl end
                        end
                    end
                end
            end
        end
        return bestPlayer
    end

    local function bfGetAnimator()
        local char=LocalPlayer.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
        return hum and hum:FindFirstChildOfClass("Animator")
    end

   local _bfDashAnimCache = {}
    local function bfPlayDashAnimation(animId)
        local animator=bfGetAnimator(); if not animator then return nil end
        if not _bfDashAnimCache[animId] then
            local a=Instance.new("Animation"); a.AnimationId=animId
            _bfDashAnimCache[animId]=a
        end
        local ok, track=pcall(function() return animator:LoadAnimation(_bfDashAnimCache[animId]) end)
        if not ok or not track then return nil end
        track.Priority=Enum.AnimationPriority.Action; track:Play()
        return track
    end

    local function bfGetDashSide(myHRP, tHRP)
        local toTarget=tHRP.Position-myHRP.Position
        local flatRight=Vector3.new(myHRP.CFrame.RightVector.X,0,myHRP.CFrame.RightVector.Z)
        if flatRight.Magnitude>0.01 then flatRight=flatRight.Unit end
        return toTarget:Dot(flatRight)>=0 and "right" or "left"
    end

    local function bfGetBehindPoint(targetPlayer, tHRP, remaining)
        local fl=bfGetSmoothedLook(targetPlayer,tHRP)
        local basePos=Vector3.new(tHRP.Position.X,0,tHRP.Position.Z)-fl*BF.Radius
        if remaining and remaining>0 then
            local vel=bfGetTargetVelocity(targetPlayer,tHRP)
            local predScale=math.clamp(remaining,0,BF.Duration)
            basePos=basePos+Vector3.new(vel.X,0,vel.Z)*predScale*BF.PredictionMultiplier
        end
        return basePos
    end

local function bfIsAlreadyBehind(myHRP, targetPlayer, tHRP)
        if not myHRP or not tHRP or not tHRP.Parent then return false end
        local fl = bfGetSmoothedLook(targetPlayer, tHRP)
        local toMe = Vector3.new(
            myHRP.Position.X - tHRP.Position.X, 0,
            myHRP.Position.Z - tHRP.Position.Z)
        if toMe.Magnitude < 0.1 then return false end
        local toMeUnit = toMe.Unit
        -- Back arc check: dot < negative threshold means we are behind
        local backDot = toMeUnit:Dot(fl)
        if backDot > -BF.BackAngleDot then return false end
        -- Distance check
        local behindPt = Vector3.new(tHRP.Position.X,0,tHRP.Position.Z) - fl*BF.Radius
        local myFlat   = Vector3.new(myHRP.Position.X,0,myHRP.Position.Z)
        if (myFlat - behindPt).Magnitude > (BF.Radius + BF.BehindDist) then return false end
        -- Facing check
        local myLook = Vector3.new(myHRP.CFrame.LookVector.X,0,myHRP.CFrame.LookVector.Z)
        if myLook.Magnitude > 0.01 then
            local facingDot = myLook.Unit:Dot(-toMeUnit)
            if facingDot < BF.FacingDot then return false end
        end
        return true
    end
    -- LEGIT DASH: Face target's back direction, dash forward (W dash), land behind.
    -- This makes the dash naturally travel behind the opponent.
    -- LEGIT DASH:
    -- 1. Lock HRP to face target every frame while dashing
    -- 2. Pick the side (A or D) that curves to the back automatically
    -- 3. Slide around to behind point, fire BF when landed
    local function bfDashLegit(lockedTarget)
        if not St.bfEnabled then return end
        local myChar = LocalPlayer.Character
        local myHRP  = bfGetHRP(myChar)
        local tHRP   = lockedTarget and bfGetHRP(lockedTarget.Character)
        if not myHRP or not tHRP then return end

        local fl       = bfGetSmoothedLook(lockedTarget, tHRP)
        local behindPt = Vector3.new(tHRP.Position.X,0,tHRP.Position.Z) - fl*BF.Radius
        local finalPos = Vector3.new(behindPt.X, myHRP.Position.Y, behindPt.Z)
        local faceDir  = Vector3.new(tHRP.Position.X, finalPos.Y, tHRP.Position.Z)

        -- Determine which side to dash: pick the side where player currently is
        -- relative to target's right vector, so dash swings them behind
        local tRight    = Vector3.new(tHRP.CFrame.RightVector.X,0,tHRP.CFrame.RightVector.Z)
        local toMe      = Vector3.new(myHRP.Position.X-tHRP.Position.X,0,myHRP.Position.Z-tHRP.Position.Z)
        local onRight   = toMe:Dot(tRight) >= 0
        -- If we're on target's right side, dash left (A+Q) to go behind
        -- If we're on target's left side, dash right (D+Q) to go behind
        local sideKey   = onRight and Enum.KeyCode.A or Enum.KeyCode.D

        -- Cosmetic anim
        local animId = onRight and Cfg.BF_DASH_ANIM_LEFT or Cfg.BF_DASH_ANIM_RIGHT
        local dashTrack = bfPlayDashAnimation(animId)

        -- PHASE 1: HRP lock — face target every frame for 0.15s while dash fires
        local lockDone   = false
        local lockConn
        lockConn = RunService.Heartbeat:Connect(function()
            if lockDone then lockConn:Disconnect(); return end
            local curHRP = bfGetHRP(LocalPlayer.Character)
            if curHRP and curHRP.Parent and tHRP and tHRP.Parent then
                pcall(function()
                    curHRP.CFrame = CFrame.new(curHRP.Position,
                        Vector3.new(tHRP.Position.X, curHRP.Position.Y, tHRP.Position.Z))
                end)
            end
        end)

        -- Fire the side dash via VIM
        local function trySideDashModule(side)
            local ok, movCtrl = pcall(function()
                return require(LocalPlayer.PlayerScripts.Controllers.Character.MovementController)
            end)
            if not ok or not movCtrl then return false end
            local VIM = game:GetService("VirtualInputManager")
            pcall(function()
                VIM:SendKeyEvent(true, side, false, game)
                task.delay(0.13, function() VIM:SendKeyEvent(false, side, false, game) end)
            end)
            task.wait(0.02)
            local dashed = false
            pcall(function()
                if movCtrl.DashRequest then movCtrl:DashRequest(); dashed=true end
            end)
            return dashed
        end

        local function trySideDashVIM(side)
            local VIM = game:GetService("VirtualInputManager")
            pcall(function()
                VIM:SendKeyEvent(true,  side,             false, game); task.wait(0.02)
                VIM:SendKeyEvent(true,  Enum.KeyCode.Q,   false, game); task.wait(0.08)
                VIM:SendKeyEvent(false, Enum.KeyCode.Q,   false, game); task.wait(0.02)
                VIM:SendKeyEvent(false, side,             false, game)
            end)
        end

        local moduled = trySideDashModule(sideKey)
        if not moduled then trySideDashVIM(sideKey) end

        -- Wait ping delay then fire BF
        task.wait(St.bfPingDelay)
        bfFireActivated()

        -- PHASE 2: Slide to behind point and snap
        task.spawn(function()
            task.wait(0.08)
            lockDone = true -- stop the HRP lock loop
            local curHRP = bfGetHRP(LocalPlayer.Character)
            if not curHRP or not curHRP.Parent then
                if dashTrack then pcall(function() dashTrack:Stop(0.1) end) end
                return
            end
            if not tHRP or not tHRP.Parent then
                if dashTrack then pcall(function() dashTrack:Stop(0.1) end) end
                return
            end
            -- Smooth slide to behind point
            local startPos    = curHRP.Position
            local slideStart  = tick()
            local slideDur    = 0.15
            local slideConn
            slideConn = RunService.Heartbeat:Connect(function()
                local el    = tick()-slideStart
                local alpha = math.clamp(el/slideDur, 0, 1)
                local eased = 1-(1-alpha)^3
                local lhrp  = bfGetHRP(LocalPlayer.Character)
                if not lhrp or not lhrp.Parent then slideConn:Disconnect(); return end
                if not tHRP or not tHRP.Parent then
                    slideConn:Disconnect()
                    if dashTrack then pcall(function() dashTrack:Stop(0.1) end) end
                    return
                end
                local lerpPos  = startPos:Lerp(finalPos, eased)
                local liveFace = Vector3.new(tHRP.Position.X, lerpPos.Y, tHRP.Position.Z)
                pcall(function() lhrp.CFrame = CFrame.new(lerpPos, liveFace) end)
                if alpha >= 1 then
                    slideConn:Disconnect()
                    if dashTrack then pcall(function() dashTrack:Stop(0.1) end) end
                    -- Hold facing target's back briefly
                    local holdStart = tick(); local holdConn
                    holdConn = RunService.Heartbeat:Connect(function()
                        if tick()-holdStart > 0.3 then holdConn:Disconnect(); return end
                        local hhrp = bfGetHRP(LocalPlayer.Character)
                        if hhrp and hhrp.Parent and tHRP and tHRP.Parent then
                            pcall(function()
                                hhrp.CFrame = CFrame.new(finalPos,
                                    Vector3.new(tHRP.Position.X, finalPos.Y, tHRP.Position.Z))
                            end)
                        end
                    end)
                end
            end)
        end)
    end

    local function bfStartCurveGlide(lockedTarget)
        if not St.bfEnabled or St.bfGlideActive then return end
        local myChar=LocalPlayer.Character; local myHRP=bfGetHRP(myChar)
        local hum=myChar and myChar:FindFirstChildOfClass("Humanoid")
        if not (lockedTarget and myHRP and hum) then return end
        local tHRP=bfGetHRP(lockedTarget.Character)
        if not tHRP or not tHRP.Parent then return end

        if bfIsAlreadyBehind(myHRP,lockedTarget,tHRP) then bfFireActivated(); return end

        St.bfGlideActive=true
        local side=bfGetDashSide(myHRP,tHRP)
        local animId=side=="right" and Cfg.BF_DASH_ANIM_RIGHT or Cfg.BF_DASH_ANIM_LEFT
        local dashAnimTrack=bfPlayDashAnimation(animId)
        local startTime=tick(); local startPos=Vector3.new(myHRP.Position.X,0,myHRP.Position.Z)
        local prevCam=Camera.CameraType
        hum.AutoRotate=false; Camera.CameraType=Enum.CameraType.Custom

        local function getSideControlPoint()
            local rv=Vector3.new(tHRP.CFrame.RightVector.X,0,tHRP.CFrame.RightVector.Z)
            if rv.Magnitude>0.01 then rv=rv.Unit end
            local toPlayer=Vector3.new(myHRP.Position.X-tHRP.Position.X,0,myHRP.Position.Z-tHRP.Position.Z)
            local sideSign=toPlayer:Dot(rv)>=0 and 1 or -1
            local initEnd=bfGetBehindPoint(lockedTarget,tHRP,BF.Duration)
            local flatDist=(initEnd-startPos).Magnitude
            local scaledCurve = math.clamp(flatDist * BF.GlideCurveK, 4, BF.CurveStrength)
            return Vector3.new(tHRP.Position.X,0,tHRP.Position.Z)+rv*(scaledCurve*sideSign)
        end

        local function cleanupGlide()
            St.bfGlideActive=false
            if hum and hum.Parent then hum.AutoRotate=true end
            Camera.CameraType=prevCam
            if dashAnimTrack then pcall(function() dashAnimTrack:Stop(0.1) end); dashAnimTrack=nil end
        end

        local glideConn
        glideConn=RunService.Heartbeat:Connect(function()
            if not St.bfEnabled then glideConn:Disconnect(); cleanupGlide(); return end
            local elapsed=tick()-startTime
            local alpha=math.clamp(elapsed/BF.Duration,0,1)
            local remaining=BF.Duration-elapsed

            if alpha>=1 or not tHRP.Parent then
                glideConn:Disconnect()
                if tHRP and tHRP.Parent then
                    local fb=bfGetBehindPoint(lockedTarget,tHRP,0)
                    local fp=Vector3.new(fb.X,myHRP.Position.Y,fb.Z)
                    local la=Vector3.new(tHRP.Position.X,myHRP.Position.Y,tHRP.Position.Z)
                    pcall(function() myHRP.CFrame=CFrame.new(fp,la) end)
                end
                if dashAnimTrack then pcall(function() dashAnimTrack:Stop(0.1) end); dashAnimTrack=nil end
                bfClearTarget(lockedTarget)
                if tHRP and tHRP.Parent then
                   local lingerConn; local lingerStart=tick()
                    lingerConn=RunService.Heartbeat:Connect(function()
                        local elapsed=tick()-lingerStart
                        local done2=elapsed>=BF.LandingLinger
                            or not St.bfEnabled or not (tHRP and tHRP.Parent)
                        if done2 then lingerConn:Disconnect(); cleanupGlide(); return end
                        local curHRP=bfGetHRP(LocalPlayer.Character)
                        if curHRP and curHRP.Parent and tHRP and tHRP.Parent then
                            -- Update look every frame during linger
                            bfUpdateSmoothedLook(lockedTarget, tHRP)
                            local fl2=bfGetSmoothedLook(lockedTarget, tHRP)
                            local targetBehindPos=Vector3.new(
                                tHRP.Position.X - fl2.X*BF.Radius,
                                curHRP.Position.Y,
                                tHRP.Position.Z - fl2.Z*BF.Radius)
                            local faceDir2=Vector3.new(tHRP.Position.X,curHRP.Position.Y,tHRP.Position.Z)
                            -- Aggressive lerp to chase target's back
                            local lerpPos=curHRP.Position:Lerp(targetBehindPos, 0.4)
                            pcall(function()
                                curHRP.CFrame=CFrame.new(lerpPos, faceDir2)
                                Camera.CFrame=CFrame.new(
                                    lerpPos+Vector3.new(0,BF.CamOffset,0), tHRP.Position)
                            end)
                        end
                    end)
                else cleanupGlide() end
                return
            end

          -- Refresh look direction every frame — catches shiftlock mid-glide
            bfUpdateSmoothedLook(lockedTarget, tHRP)
            local liveEnd=bfGetBehindPoint(lockedTarget,tHRP,remaining)
            -- Recalculate control point dynamically so the curve always curves toward current back
            local liveControlPt=getSideControlPoint()
            local t=1-(1-alpha)^2; local t1=1-t
            local movePos=Vector3.new(
                (t1*t1)*startPos.X+(2*t1*t)*liveControlPt.X+(t*t)*liveEnd.X,
                myHRP.Position.Y,
                (t1*t1)*startPos.Z+(2*t1*t)*liveControlPt.Z+(t*t)*liveEnd.Z)
            pcall(function()
                myHRP.CFrame=CFrame.new(movePos,Vector3.new(tHRP.Position.X,movePos.Y,tHRP.Position.Z))
                Camera.CFrame=CFrame.new(myHRP.Position+Vector3.new(0,BF.CamOffset,0),tHRP.Position)
            end)
        end)
    end

local _bfLastTrigger = 0

    local function bfTriggerDash_inner()
        if not St.bfEnabled then return end
        -- Prevent double-fire within 0.1s but don't block legitimate rapid presses
        local now = tick()
        if now - _bfLastTrigger < 0.08 then return end
        _bfLastTrigger = now

       local target=bfGetNearestPlayer(BF.Range)
        if not target then return end
        local myHRP=bfGetHRP(LocalPlayer.Character)
        local tHRP=bfGetHRP(target.Character)
        if not myHRP or not tHRP then return end

        -- Always read fresh direction at the moment of trigger
        bfUpdateSmoothedLook(target, tHRP)

        if bfIsAlreadyBehind(myHRP, target, tHRP) then
            -- Already behind: just fire BF, no dash, no glide
            bfFireActivated()
            return
        end

        -- Not behind: dash/glide then fire
        -- Use task.spawn so rapid presses don't queue
        if St.bfGlideActive then return end -- already mid-glide

        task.spawn(function()
            if St.bfMode=="legit" then
                bfFireActivated()
                task.wait(St.bfPingDelay)
                bfDashLegit(target)
            else
                bfFireActivated()
                task.wait(St.bfPingDelay)
                bfStartCurveGlide(target)
            end
        end)
    end

 local function bfWatchPlayerAttacks(player)
        if player==LocalPlayer then return end
        local function hookChar(character)
            local hum=character:WaitForChild("Humanoid",5)
            local animator=hum and hum:WaitForChild("Animator",5)
            if not animator then return end
            local conn=animator.AnimationPlayed:Connect(function(track)
                -- Early exit before string ops if BF is off
                if not St.bfEnabled then return end
                local id=track.Animation and track.Animation.AnimationId or ""
                if Cfg.BF_AnimationTriggers[id] or Cfg.BF_StraightAnimations[id] then
                    St.bfLastAttackTime[player]=tick()
                end
            end)
            if not Cn.bfAttackConns[player] then Cn.bfAttackConns[player]={} end
            table.insert(Cn.bfAttackConns[player],conn)
        end
        if player.Character then task.spawn(function() hookChar(player.Character) end) end
        local cc=player.CharacterAdded:Connect(function(c)
            task.spawn(function() hookChar(c) end)
        end)
        if not Cn.bfAttackConns[player] then Cn.bfAttackConns[player]={} end
        table.insert(Cn.bfAttackConns[player],cc)
    end

   local function bfSetupLocalCharacter(character)
        local humanoid=character:WaitForChild("Humanoid",5)
        local animator=humanoid and humanoid:WaitForChild("Animator",5)
        if not animator then return end
        local conn=animator.AnimationPlayed:Connect(function(track)
            if not St.bfEnabled then return end
            local animId=track.Animation and track.Animation.AnimationId or ""
            local delayTime=Cfg.BF_AnimationTriggers[animId]
            if not delayTime and Cfg.BF_StraightAnimations[animId] then delayTime=0.19 end
            if delayTime then
                task.delay(delayTime,function()
                    if not St.bfEnabled then return end
                    local hum2=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum2 and hum2.Health>0 then bfFireActivated() end
                end)
            end
        end)
        Cn.bfAttackConns["local"]=Cn.bfAttackConns["local"] or {}
        table.insert(Cn.bfAttackConns["local"],conn)
    end

    local function bfStartAll()
        -- Guard: disconnect any stale connections before creating new ones
        if Cn.bfHeartbeatConn      then Cn.bfHeartbeatConn:Disconnect();      Cn.bfHeartbeatConn=nil      end
        if Cn.bfCharConn           then Cn.bfCharConn:Disconnect();            Cn.bfCharConn=nil           end
        if Cn.bfPlayerAddedConn    then Cn.bfPlayerAddedConn:Disconnect();    Cn.bfPlayerAddedConn=nil    end
        if Cn.bfPlayerRemovingConn then Cn.bfPlayerRemovingConn:Disconnect(); Cn.bfPlayerRemovingConn=nil end
        for _, pl in pairs(Players:GetPlayers()) do bfWatchPlayerAttacks(pl) end
        Cn.bfPlayerAddedConn=Players.PlayerAdded:Connect(bfWatchPlayerAttacks)
        Cn.bfPlayerRemovingConn=Players.PlayerRemoving:Connect(function(pl)
            St.bfLastAttackTime[pl]=nil; St.bfPrevTargetPos[pl]=nil
            St.bfPrevTargetTime[pl]=nil; St.bfTargetLookSmoothed[pl]=nil
            if Cn.bfAttackConns[pl] then
                for _, c in ipairs(Cn.bfAttackConns[pl]) do pcall(function() c:Disconnect() end) end
                Cn.bfAttackConns[pl]=nil
            end
        end)
        local char=LocalPlayer.Character
        if char then task.spawn(function() bfSetupLocalCharacter(char) end) end
        Cn.bfCharConn=LocalPlayer.CharacterAdded:Connect(function(character)
            St.bfGlideActive=false
            task.spawn(function() bfSetupLocalCharacter(character) end)
        end)
        local _bfLastScan  = 0
        local _bfLastTarget = nil
        Cn.bfHeartbeatConn=RunService.Heartbeat:Connect(function()
            if not St.bfEnabled then return end
            local _bfNow=tick()
            -- Only scan for nearest player 10 times/sec
            if _bfNow-_bfLastScan < 0.03 then return end
            _bfLastScan=_bfNow
            local target=bfGetNearestPlayer(BF.Range)
            if not target then _bfLastTarget=nil; return end
            _bfLastTarget=target
            local tHRP=bfGetHRP(target.Character)
            if tHRP and tHRP.Parent then
                bfUpdateSmoothedLook(target,tHRP)
                bfGetTargetVelocity(target,tHRP)
            end
        end)
        end

    local function bfStopAll()
        St.bfEnabled=false; St.bfGlideActive=false
        if Cn.bfHeartbeatConn      then Cn.bfHeartbeatConn:Disconnect();      Cn.bfHeartbeatConn=nil end
        if Cn.bfCharConn           then Cn.bfCharConn:Disconnect();            Cn.bfCharConn=nil end
        if Cn.bfPlayerAddedConn    then Cn.bfPlayerAddedConn:Disconnect();    Cn.bfPlayerAddedConn=nil end
        if Cn.bfPlayerRemovingConn then Cn.bfPlayerRemovingConn:Disconnect(); Cn.bfPlayerRemovingConn=nil end
        for key, conns in pairs(Cn.bfAttackConns) do
            for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
            Cn.bfAttackConns[key]=nil
        end
        St.bfLastAttackTime={}; St.bfTargetLookSmoothed={}
        St.bfPrevTargetPos={}; St.bfPrevTargetTime={}
    end

    _G.bfStartAll     = bfStartAll
    _G.bfStopAll      = bfStopAll
    _G.bfTriggerDash  = bfTriggerDash_inner
end

local bfStartAll    = _G.bfStartAll
local bfStopAll     = _G.bfStopAll
local bfTriggerDash = _G.bfTriggerDash

-- ============================================================
-- FLY SYSTEM
-- Uses Heartbeat only — never RenderStepped — so skills/grabs
-- cannot cancel it. Forces Physics state every frame.
-- ============================================================
do
    local FLY_IDLE  = "idle"
    local FLY_MOVE  = "move"
    local FLY_BOOST = "boost"
    local FLY_RIGHT = "right"
    local FLY_LEFT  = "left"
    local FLY_BACK  = "back"

    local flyHiddenPart  = nil
    local flyFlySound    = nil
    local flyBoostSndRef = nil

    local function flyStopTrack(track)
        if track then pcall(function() track:Stop(0.12); track:Destroy() end) end
    end

    local function flyStopAllAnims()
        flyStopTrack(St.flyIdleTrack);  St.flyIdleTrack  = nil
        flyStopTrack(St.flyMoveTrack);  St.flyMoveTrack  = nil
        flyStopTrack(St.flyBoostTrack); St.flyBoostTrack = nil
        flyStopTrack(St.flyRightTrack); St.flyRightTrack = nil
        flyStopTrack(St.flyLeftTrack);  St.flyLeftTrack  = nil
        flyStopTrack(St.flyBackTrack);  St.flyBackTrack  = nil
        St.flyCurrentAnimState = nil
    end

local _flyAnimCache = {}
    local function flyLoadTrack(animId, looped, speed, timePos)
        if not St.flyAnimator then return nil end
        if not _flyAnimCache[animId] then
            local a = Instance.new("Animation"); a.AnimationId = animId
            _flyAnimCache[animId] = a
        end
        local ok, track = pcall(function() return St.flyAnimator:LoadAnimation(_flyAnimCache[animId]) end)
        if not ok or not track then return nil end
        track.Priority = Enum.AnimationPriority.Idle
        track.Looped   = looped
        track:Play(0.15)
        track:AdjustSpeed(speed)
        if timePos and timePos > 0 then
            task.delay(0.06, function()
                if track and track.IsPlaying then
                    pcall(function() track.TimePosition = timePos end)
                end
            end)
        end
        return track
    end

    local function flySetState(newState)
        if St.flyCurrentAnimState == newState then return end
        local old = St.flyCurrentAnimState
        St.flyCurrentAnimState = newState
        -- Stop old track
        if     old == FLY_IDLE  then flyStopTrack(St.flyIdleTrack);  St.flyIdleTrack  = nil
        elseif old == FLY_MOVE  then flyStopTrack(St.flyMoveTrack);  St.flyMoveTrack  = nil
       elseif old == FLY_BOOST then
            flyStopTrack(St.flyBoostTrack); St.flyBoostTrack = nil
            -- Restore FOV from boost
            TweenService:Create(Camera,
                TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                {FieldOfView=90}):Play()
        elseif old == FLY_RIGHT then flyStopTrack(St.flyRightTrack); St.flyRightTrack = nil
        elseif old == FLY_LEFT  then flyStopTrack(St.flyLeftTrack);  St.flyLeftTrack  = nil
        elseif old == FLY_BACK  then flyStopTrack(St.flyBackTrack);  St.flyBackTrack  = nil
        end
        -- Start new track
        if     newState == FLY_IDLE  then
            St.flyIdleTrack  = flyLoadTrack("rbxassetid://91408938873266", true,  0, 1.5)
        elseif newState == FLY_MOVE  then
            St.flyMoveTrack  = flyLoadTrack("rbxassetid://9443519528",     true,  0, 1)
       elseif newState == FLY_BOOST then
            St.flyBoostTrack = flyLoadTrack("rbxassetid://15984964491",    true,  0, 0.5)
            -- FOV increase when boosting
            TweenService:Create(Camera,
                TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                {FieldOfView=120}):Play()
            if flyBoostSndRef then
                pcall(function()
                    flyBoostSndRef.TimePosition = 0
                    flyBoostSndRef:Play()
                end)
                task.delay(1.5, function()
                    if flyBoostSndRef then pcall(function() flyBoostSndRef:Pause() end) end
                end)
            end
        elseif newState == FLY_RIGHT then
            St.flyRightTrack = flyLoadTrack("rbxassetid://9443521999",  true, 0, 0.02083333395421505)
        elseif newState == FLY_LEFT  then
            St.flyLeftTrack  = flyLoadTrack("rbxassetid://9443520855",  true, 0, 0.02083333395421505)
        elseif newState == FLY_BACK  then
            St.flyBackTrack  = flyLoadTrack("rbxassetid://9443517965",  true, 0, 0.03333333507180214)
        end
    end

    local function flyGetSpeed()
        if flyKeys.Boost then return math.min(Cfg.FlySpeed + 200, 650) end
        return Cfg.FlySpeed
    end

    local function randomPartName()
        local c = "abcdefghijklmnopqrstuvwxyz"; local n = ""
        for i = 1, 8 do local idx = math.random(1,#c); n = n..c:sub(idx,idx) end
        return n
    end

    local function flyBuildHiddenPart(hrp)
        if flyHiddenPart and flyHiddenPart.Parent then
            pcall(function() flyHiddenPart:Destroy() end)
        end
        if flyFlySound  then pcall(function() flyFlySound:Stop();  flyFlySound:Destroy()  end) end
        if flyBoostSndRef then pcall(function() flyBoostSndRef:Stop(); flyBoostSndRef:Destroy() end) end
        flyHiddenPart = nil; flyFlySound = nil; flyBoostSndRef = nil

        local part = Instance.new("Part")
        part.Name = randomPartName(); part.Size = Vector3.new(0.05,0.05,0.05)
        part.Shape = Enum.PartType.Block; part.Material = Enum.Material.Plastic
        part.Transparency = 0; part.CanCollide = false
        part.Anchored = false; part.CFrame = hrp.CFrame; part.Parent = Workspace

        local weld = Instance.new("Weld")
        weld.Part0 = part; weld.Part1 = hrp
        weld.C0 = CFrame.new(); weld.C1 = CFrame.new(); weld.Parent = part

        local bv = Instance.new("BodyVelocity")
        bv.Name = "FlyBV"; bv.MaxForce = Vector3.new(8999999488,8999999488,8999999488)
        bv.P = 1250; bv.Velocity = Vector3.zero; bv.Parent = part

        local bg = Instance.new("BodyGyro")
        bg.Name = "FlyBG"; bg.MaxTorque = Vector3.new(8999999488,8999999488,8999999488)
        bg.P = 1000; bg.D = 50; bg.CFrame = hrp.CFrame; bg.Parent = part

        -- Sounds parented to Camera (non-positional, local only)
        local snd = Instance.new("Sound")
        snd.Name = "FlyAmbient"; snd.SoundId = "rbxassetid://79148321721845"
        snd.Volume = 0.8; snd.PlaybackSpeed = 0.8; snd.Looped = true
        snd.Parent = workspace.CurrentCamera

        local bsnd = Instance.new("Sound")
        bsnd.Name = "FlyBoostSnd"; bsnd.SoundId = "rbxassetid://858508159"
        bsnd.Volume = 1; bsnd.PlaybackSpeed = 1; bsnd.Looped = false
        bsnd.Parent = workspace.CurrentCamera

        flyHiddenPart = part; St.flyBodyVelocity = bv; St.flyBodyGyro = bg
        flyFlySound = snd; flyBoostSndRef = bsnd
        return part, bv, bg
    end

    local function enableFly()
        St.flyCharacter = LocalPlayer.Character; if not St.flyCharacter then return end
        St.flyHumanoid  = St.flyCharacter:FindFirstChildOfClass("Humanoid")
        St.flyRootPart  = St.flyCharacter:FindFirstChild("HumanoidRootPart")
        if not St.flyHumanoid or not St.flyRootPart then return end
        St.flyAnimator    = St.flyHumanoid:FindFirstChildOfClass("Animator")
        if not St.flyAnimator then return end
        St.flyOriginalFOV = Camera.FieldOfView; St.flyWasMoving = false
        flyKeys.Boost     = false

        flyBuildHiddenPart(St.flyRootPart)
        pcall(function() St.flyHumanoid.PlatformStand = true end)
        flySetState(FLY_IDLE)
        if flyFlySound then pcall(function() flyFlySound:Play() end) end

        TweenService:Create(Camera,
            TweenInfo.new(0.25,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),
            {FieldOfView=90}):Play()

        Cn.flyConnection = RunService.Heartbeat:Connect(function()
            if not St.flyActive then return end
            local char = LocalPlayer.Character
            if not char or not char.Parent then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then return end

            St.flyCharacter = char; St.flyRootPart = hrp; St.flyHumanoid = hum
            local animr = hum:FindFirstChildOfClass("Animator")
            if animr then St.flyAnimator = animr end

            if hum.Parent ~= char then pcall(function() hum.Parent = char end) end
            pcall(function() hum.PlatformStand = true end)
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,    false)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Seated,      false)
                hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp,   false)
            end)
            
            if not flyHiddenPart or not flyHiddenPart.Parent then
                pcall(function()
                    flyBuildHiddenPart(hrp)
                    if flyFlySound then pcall(function() flyFlySound:Play() end) end
                end)
            end

            local bv = St.flyBodyVelocity; local bg = St.flyBodyGyro
            if not bv or not bv.Parent then return end
            if not bg or not bg.Parent then return end

           local camCF = Camera.CFrame; local look = camCF.LookVector
            pcall(function()
                -- Use full look vector including Y so character tilts with camera pitch
                bg.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + look)
            end)

            local localMove
            if mobile then
                localMove = mobileFlyVector
            else
                localMove = Vector3.new(
                    (flyKeys.D  and 1 or 0)-(flyKeys.A    and 1 or 0),
                    (flyKeys.Up and 1 or 0)-(flyKeys.Down and 1 or 0),
                    (flyKeys.S  and 1 or 0)-(flyKeys.W    and 1 or 0))
            end

           if localMove.Magnitude > 0.01 then
                local spd = flyGetSpeed()
                local mv
                if mobile then
                    -- mobileFlyVector is already world-space; skip the camera transform
                    mv = localMove.Unit * spd
                else
                    mv = (camCF:VectorToWorldSpace(localMove)).Unit * spd
                end
                pcall(function() bv.Velocity = mv end)

                local newAnimState
                if not mobile then
                    if flyKeys.W then
                        newAnimState = flyKeys.Boost and FLY_BOOST or FLY_MOVE
                    elseif flyKeys.D then newAnimState = FLY_RIGHT
                    elseif flyKeys.A then newAnimState = FLY_LEFT
                    elseif flyKeys.S then newAnimState = FLY_BACK
                    else newAnimState = FLY_MOVE end
                else
                    newAnimState = FLY_MOVE
                end
                flySetState(newAnimState)
                St.flyWasMoving = true
            else
                pcall(function() bv.Velocity = Vector3.zero end)
                if St.flyWasMoving then
                    St.flyWasMoving = false; flyKeys.Boost = false
                end
                flySetState(FLY_IDLE)
            end
        end)
    end -- end enableFly

    local function disableFly()
        St.flyActive = false
        if Cn.flyConnection then Cn.flyConnection:Disconnect(); Cn.flyConnection = nil end
        flyStopAllAnims()
        if flyFlySound then
            pcall(function() flyFlySound:Stop(); flyFlySound:Destroy() end); flyFlySound = nil
        end
       if flyBoostSndRef then
            pcall(function() flyBoostSndRef:Stop(); flyBoostSndRef:Destroy() end); flyBoostSndRef = nil
        end
        -- Safety: destroy any orphaned fly sounds left in camera
        pcall(function()
            for _, s in ipairs(workspace.CurrentCamera:GetChildren()) do
                if s:IsA("Sound") and (s.Name == "FlyAmbient" or s.Name == "FlyBoostSnd") then
                    s:Stop(); s:Destroy()
                end
            end
        end)
        if flyHiddenPart and flyHiddenPart.Parent then
            pcall(function() flyHiddenPart:Destroy() end)
        end
        flyHiddenPart = nil; St.flyBodyVelocity = nil; St.flyBodyGyro = nil
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                hum.PlatformStand = false
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,    true)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.Seated,      true)
                hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp,   true)
            end)
        end
        TweenService:Create(Camera,
            TweenInfo.new(0.35,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),
            {FieldOfView=St.flyOriginalFOV}):Play()
        for k in pairs(flyKeys) do flyKeys[k] = false end
        mobileFlyVector = Vector3.zero
        St.flyHumanoid = nil; St.flyRootPart  = nil
        St.flyCharacter = nil; St.flyAnimator  = nil
        St.flyWasMoving = false
    end

    local function toggleFly()
        St.flyActive = not St.flyActive
        if St.flyActive then enableFly(); notify("Fly","Flying enabled.",2)
        else disableFly(); notify("Fly","Flying disabled.",2) end
    end

    LocalPlayer.CharacterAdded:Connect(function(char)
        if not St.flyActive then return end
        task.wait(1)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        St.flyCharacter = char; St.flyHumanoid = hum; St.flyRootPart = hrp
        St.flyAnimator  = hum:FindFirstChildOfClass("Animator")
        St.flyWasMoving = false; St.flyCurrentAnimState = nil
        flyBuildHiddenPart(hrp)
        pcall(function() hum.PlatformStand = true end)
        if flyFlySound then pcall(function() flyFlySound:Play() end) end
        flySetState(FLY_IDLE)
    end)

    _G.enableFly  = enableFly
    _G.disableFly = disableFly
    _G.toggleFly  = toggleFly
end

local enableFly  = _G.enableFly
local disableFly = _G.disableFly
local toggleFly  = _G.toggleFly

-- ============================================================
-- KOKUSEN / YUTA BF EXECUTE
-- ============================================================
local function kokusenExecute()
    if St.kokusenIsExecuting then return end
    local char=LocalPlayer.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart")
    local head=char:FindFirstChild("Head")
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not hrp or not head or not hum then return end
    local targetChar=nil
    if St.kokusenSelectedTarget~="" then
        local tp=Players:FindFirstChild(St.kokusenSelectedTarget)
        if tp then targetChar=tp.Character end
    end
    local targetHrp=targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    local originalPos=hrp.CFrame
    St.kokusenIsExecuting=true; hum.PlatformStand=true; head.Anchored=true
    local moveset=char:FindFirstChild("Moveset")
    local move=moveset and moveset:FindFirstChild("Resolute Slash")
    if move then
        pcall(function() replicatesignal(LocalPlayer.Kill) end)
        task.wait(0.1)
        local skillTarget=char
        pcall(function()
            local Knit=require(ReplicatedStorage.Knit.Knit)
            local t=Knit.GetController("ToolController"):GetTarget()
            if t and t.Parent then skillTarget=t end
        end)
        pcall(function()
            local knit=ReplicatedStorage:FindFirstChild("Knit")
            if knit then knit.Knit.Services.ResoluteSlashService.RE.Activated:FireServer(move,skillTarget) end
        end)
    end
    if St.kokusenCFLoop then pcall(function() St.kokusenCFLoop:Disconnect() end); St.kokusenCFLoop=nil end
    local cam=workspace.CurrentCamera
    St.kokusenCFLoop=RunService.Heartbeat:Connect(function(dt)
        if not St.kokusenIsExecuting or not head or not head.Parent then
            if St.kokusenCFLoop then pcall(function() St.kokusenCFLoop:Disconnect() end); St.kokusenCFLoop=nil end; return
        end
        local camLook=cam.CFrame.LookVector
        local flatLook=Vector3.new(camLook.X,0,camLook.Z).Unit
        if targetHrp and targetHrp.Parent then
            head.CFrame=CFrame.lookAt(targetHrp.Position+Vector3.new(0,1.5,1),targetHrp.Position+flatLook)
        else
            local moveDir=hum.MoveDirection
            if moveDir.Magnitude>0 then
                moveDir=Vector3.new(moveDir.X,0,moveDir.Z).Unit
                local newPos=head.Position+(moveDir*28*dt)
                head.CFrame=CFrame.lookAt(newPos,newPos+flatLook)
            else
                head.CFrame=CFrame.lookAt(head.Position,head.Position+flatLook)
            end
        end
    end)
    task.delay(4,function()
        if St.kokusenCFLoop then pcall(function() St.kokusenCFLoop:Disconnect() end); St.kokusenCFLoop=nil end
        St.kokusenIsExecuting=false
        if head then head.Anchored=false end
        if hum then hum.PlatformStand=false end
        task.wait(0.1)
        if hrp and hrp.Parent then hrp.CFrame=originalPos end
    end)
end

-- ============================================================
-- LOCK-ON SYSTEM
-- ============================================================
local function lockOnFindClosest()
    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local closest, minDist = nil, Cfg.LockOn.MaxDistance
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
            local hum = pl.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local dist = (myHRP.Position - hrp.Position).Magnitude
                if dist < minDist then minDist = dist; closest = hrp end
            end
        end
    end
    return closest
end

local function lockOnFindByMouse()
    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local mouse = LocalPlayer:GetMouse()
    local unitRay = Camera:ScreenPointToRay(mouse.X, mouse.Y)
    local closest, minAngle = nil, math.rad(25)
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
            local hum = pl.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local dist = (myHRP.Position - hrp.Position).Magnitude
                if dist <= Cfg.LockOn.MaxDistance then
                    local toTarget = (hrp.Position - unitRay.Origin).Unit
                    local angle = math.acos(math.clamp(unitRay.Direction:Dot(toTarget),-1,1))
                    if angle < minAngle then minAngle=angle; closest=hrp end
                end
            end
        end
    end
    -- Fall back to closest if no mouse target
    return closest or lockOnFindClosest()
end

local function enableLockOn()
    if Cn.lockOnConn then Cn.lockOnConn:Disconnect() end
    local myChar = LocalPlayer.Character
    local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHum then return end
    St.lockOnOrigAutoRotate = myHum.AutoRotate
    local _lockLastRun = 0
    Cn.lockOnConn = RunService.Heartbeat:Connect(function()
        if not St.lockOnEnabled then return end
        local now = tick()
        if now - _lockLastRun < 0.033 then return end -- ~60fps cap
        _lockLastRun = now
        local target = mobile and lockOnFindClosest() or lockOnFindByMouse()
        if not target then return end
        local char2 = LocalPlayer.Character
        local hrp2  = char2 and char2:FindFirstChild("HumanoidRootPart")
        local hum2  = char2 and char2:FindFirstChildOfClass("Humanoid")
        if not hrp2 or not hum2 then return end
        if Cfg.LockOn.Method == "Camera" then
            local lookAt = target.Position + target.CFrame.RightVector * Cfg.LockOn.SideOffset
            local goalCF = CFrame.lookAt(Camera.CFrame.Position, lookAt)
            Camera.CFrame = Camera.CFrame:Lerp(goalCF, Cfg.LockOn.Smoothness)
        else
            local lookAt = Vector3.new(target.Position.X, hrp2.Position.Y, target.Position.Z)
            hrp2.CFrame  = hrp2.CFrame:Lerp(CFrame.lookAt(hrp2.Position, lookAt), Cfg.LockOn.Smoothness)
        end
        hum2.AutoRotate = false
    end)
end

local function disableLockOn()
    St.lockOnEnabled = false
    if Cn.lockOnConn then Cn.lockOnConn:Disconnect(); Cn.lockOnConn = nil end
    local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if myHum then myHum.AutoRotate = St.lockOnOrigAutoRotate end
end

local function toggleLockOn()
    St.lockOnEnabled = not St.lockOnEnabled
    if St.lockOnEnabled then enableLockOn(); notify("Lock-On","Enabled.",2)
    else disableLockOn(); notify("Lock-On","Disabled.",2) end
end

-- ============================================================
-- DASH MULTIPLIER
-- ============================================================
local function applyDashMultiplier(val)
    local char = LocalPlayer.Character
    if not char then return end
    local info = char:FindFirstChild("Info")
    if not info then return end
    local existing = info:FindFirstChild("DashMultiplier")
    if existing then existing:Destroy() end
    local int = Instance.new("NumberValue")
    int.Parent = info
    int.Value  = val
    int.Name   = "DashMultiplier"
end

local function enableDashMultiplier()
    applyDashMultiplier(St.dashMultiplierValue)
    -- Reapply on respawn
    if Cn.dashMultCharConn then Cn.dashMultCharConn:Disconnect() end
    Cn.dashMultCharConn = LocalPlayer.CharacterAdded:Connect(function(char)
        if not St.dashMultiplierEnabled then return end
        task.wait(1)
        applyDashMultiplier(St.dashMultiplierValue)
    end)
end

local function disableDashMultiplier()
    local char = LocalPlayer.Character
    if char then
        local info = char:FindFirstChild("Info")
        if info then
            local dm = info:FindFirstChild("DashMultiplier")
            if dm then dm:Destroy() end
        end
    end
    if Cn.dashMultCharConn then Cn.dashMultCharConn:Disconnect(); Cn.dashMultCharConn = nil end
end

local function kokusenGetPlayerList()
    local list={}
    for _, player in pairs(Players:GetPlayers()) do
        if player~=LocalPlayer then table.insert(list,player.Name) end
    end
    return list
end

-- ============================================================
-- NANAMI AUTO RATIO
-- ============================================================
local function enableAutoRatio()
    if Cn.nanamiRatioConn then return end
    pcall(function()
        Cn.nanamiRatioConn = game.ReplicatedStorage.Knit.Knit.Services
            .NanamiService.RE.Effects.OnClientEvent:Connect(function(...)
            local args = {...}
            if args[1] == "SpawnRatio" and args[2] == LocalPlayer then
                task.wait(args[6] * 0.56767676767676769420)
                pcall(function()
                    game:GetService("ReplicatedStorage").Knit.Knit.Services
                        .NanamiService.RE.RightActivated:FireServer()
                end)
            end
        end)
    end)
end

local function disableAutoRatio()
    if Cn.nanamiRatioConn then
        Cn.nanamiRatioConn:Disconnect(); Cn.nanamiRatioConn = nil
    end
end

-- ============================================================
-- YONK SYSTEM
-- ============================================================
local function yonkStopAnim()
    if St.yonkAnimTrack then
        pcall(function() St.yonkAnimTrack:Stop(); St.yonkAnimTrack:Destroy() end)
        St.yonkAnimTrack = nil
    end
    if St.yonkAnim then
        pcall(function() St.yonkAnim:Destroy() end)
        St.yonkAnim = nil
    end
end

local function yonkPlayAnim()
    local char     = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    yonkStopAnim()
    St.yonkAnim = Instance.new("Animation")
    St.yonkAnim.AnimationId = "rbxassetid://72042024"
    St.yonkAnimTrack = humanoid:LoadAnimation(St.yonkAnim)
    St.yonkAnimTrack.Priority = Enum.AnimationPriority.Action4
    St.yonkAnimTrack.Looped   = true
    St.yonkAnimTrack:AdjustSpeed(St.yonkSpeed)
    St.yonkAnimTrack.TimePosition = 0.05416666716337204
    St.yonkAnimTrack:Play()
end

local function yonkToggle()
    St.yonkEnabled = not St.yonkEnabled
    if St.yonkEnabled then
        yonkPlayAnim()
        notify("Yonk", "Enabled.", 2)
    else
        yonkStopAnim()
        notify("Yonk", "Disabled.", 2)
    end
end

if Cn.yonkCharConn then Cn.yonkCharConn:Disconnect() end
Cn.yonkCharConn = LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if St.yonkEnabled then yonkPlayAnim() end
end)

-- ============================================================
-- AUTO HIROMI QTE SYSTEM
-- ============================================================
local _hiromiFiring = false  -- flag: true while QTE is pressing keys

local function hiromiPressKey(keyText)
    local VIM = game:GetService("VirtualInputManager")
    local ok, kc = pcall(function() return Enum.KeyCode[keyText] end)
    if ok and kc then
        _hiromiFiring = true
        VIM:SendKeyEvent(true,  kc, false, game)
        task.wait(math.random(30, 70) / 1000)
        VIM:SendKeyEvent(false, kc, false, game)
        _hiromiFiring = false
    end
end

local function hiromiTapMobile(btn)
    local VIM = game:GetService("VirtualInputManager")
    local pos = btn.AbsolutePosition + btn.AbsoluteSize * 0.5
    VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true,  game, 0)
    task.wait(math.random(30, 70) / 1000)
    VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
end

local _hiromiActiveGuis = {}  -- debounce table per gui instance

local function hiromiHandleQTE(qteGui)
    if not St.hiromiEnabled then return end
    if _hiromiActiveGuis[qteGui] then return end
    _hiromiActiveGuis[qteGui] = true

    local removeConn
    removeConn = qteGui.AncestryChanged:Connect(function()
        if not qteGui.Parent then
            _hiromiActiveGuis[qteGui] = nil
            if removeConn then removeConn:Disconnect() end
        end
    end)

    task.spawn(function()
        while _hiromiActiveGuis[qteGui] and qteGui.Parent and St.hiromiEnabled do
            local fired = false

            -- ADAPTER 1: Standard QTE schema (QTE_PC / QTE_MOBILE)
            local pcLabel   = qteGui:FindFirstChild("QTE_PC",     true)
            local mobileBtn = qteGui:FindFirstChild("QTE_MOBILE", true)

            -- ADAPTER 2: BeamQTE + adaptive scan
            -- Scan for any single uppercase letter in a TextLabel (key hint)
            local beamLabel = nil
            local beamBtn   = nil
            if not pcLabel then
                for _, desc in ipairs(qteGui:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Visible
                        and #desc.Text == 1 and desc.Text:match("^%u$") then
                        beamLabel = desc; break
                    end
                end
            end
            -- Scan for any visible TextButton as mobile fallback
            if not mobileBtn then
                for _, desc in ipairs(qteGui:GetDescendants()) do
                    if desc:IsA("TextButton") and desc.Visible
                        and desc.AbsoluteSize.X > 10 then
                        beamBtn = desc; break
                    end
                end
            end

            if mobile then
                local btn = mobileBtn or beamBtn
                if btn then hiromiTapMobile(btn); fired = true end
            else
                local lbl = pcLabel or beamLabel
                if lbl and lbl.Text ~= "" and lbl.Text:match("^%a$") then
                    hiromiPressKey(lbl.Text); fired = true
                end
            end

            if fired then
                local delayMs = math.random(St.hiromiMinMs, St.hiromiMaxMs)
                task.wait(delayMs / 1000)
            else
                task.wait(0.05)  -- retry scan
            end
        end
        _hiromiActiveGuis[qteGui] = nil
    end)
end

local function hiromiStart()
    if Cn.hiromiConn then Cn.hiromiConn:Disconnect() end
    -- Scan already-present GUIs
    for _, child in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
        if child:IsA("ScreenGui")
            and (child.Name=="QTE" or child.Name=="BeamQTE") then
            hiromiHandleQTE(child)
        end
    end
    Cn.hiromiConn = LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
        if child:IsA("ScreenGui")
            and (child.Name=="QTE" or child.Name=="BeamQTE") then
            task.spawn(function()
                task.wait(0.1) -- brief wait for GUI to fully load
                hiromiHandleQTE(child)
            end)
        end
    end)
end

local function hiromiStop()
    if Cn.hiromiConn then Cn.hiromiConn:Disconnect(); Cn.hiromiConn = nil end
    _hiromiActiveGuis = {}
end

-- ============================================================
-- MOBILE UI (Fluent)
-- ============================================================
if mobile then
   do
        local mobileFlyGui   = nil
        local mobileFlyFloat = nil
        local mobileFlyStroke= nil
        local mobileFlyLbl   = nil

        local function destroyFlyFloatButton()
            if mobileFlyGui and mobileFlyGui.Parent then
                pcall(function() mobileFlyGui:Destroy() end)
            end
            mobileFlyGui=nil; mobileFlyFloat=nil
            mobileFlyStroke=nil; mobileFlyLbl=nil
        end

        local function buildFlyFloatButton()
            destroyFlyFloatButton()
            mobileFlyGui=Instance.new("ScreenGui")
            mobileFlyGui.Name="GojoFlyFloat"; mobileFlyGui.ResetOnSpawn=false
            mobileFlyGui.DisplayOrder=9998; mobileFlyGui.IgnoreGuiInset=true
            mobileFlyGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
            mobileFlyGui.Parent=LocalPlayer:WaitForChild("PlayerGui")

            local vp=Camera and Camera.ViewportSize or Vector2.new(800,600)
            local flyFloat=Instance.new("Frame")
            flyFloat.Size=UDim2.fromOffset(70,70)
            flyFloat.Position=UDim2.fromOffset(
                math.clamp(vp.X-170,0,vp.X-74),
                math.clamp(vp.Y-160,0,vp.Y-74))
            flyFloat.BackgroundColor3=Color3.fromRGB(4,14,4)
            flyFloat.BorderSizePixel=0; flyFloat.Active=true
            flyFloat.ZIndex=2; flyFloat.Parent=mobileFlyGui
            Instance.new("UICorner",flyFloat).CornerRadius=UDim.new(0.5,0)

            local stroke=Instance.new("UIStroke")
            stroke.Color=Color3.fromRGB(30,100,30); stroke.Thickness=2.5
            stroke.Transparency=0
            stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
            stroke.Parent=flyFloat

            local lbl=Instance.new("TextLabel")
            lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
            lbl.Text="FLY"; lbl.TextColor3=Color3.fromRGB(60,200,60)
            lbl.TextSize=14; lbl.Font=Enum.Font.GothamBold
            lbl.ZIndex=3; lbl.Parent=flyFloat

            local btn=Instance.new("TextButton")
            btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1
            btn.Text=""; btn.ZIndex=4; btn.Parent=flyFloat

            mobileFlyFloat=flyFloat; mobileFlyStroke=stroke; mobileFlyLbl=lbl

            -- Drag + tap logic
            local dragging=false; local tapStart=0
            local dragOrigin=Vector2.zero; local frameOrig=Vector2.zero
            local moved=false

            btn.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.Touch then
                    dragging=true; moved=false; tapStart=tick()
                    dragOrigin=Vector2.new(inp.Position.X,inp.Position.Y)
                    frameOrig=Vector2.new(flyFloat.Position.X.Offset,flyFloat.Position.Y.Offset)
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if dragging and inp.UserInputType==Enum.UserInputType.Touch then
                    local d=Vector2.new(inp.Position.X,inp.Position.Y)-dragOrigin
                    if d.Magnitude>12 then moved=true end
                    if moved then  -- guard: only reposition on intentional drag
                        local vp2=Camera and Camera.ViewportSize or Vector2.new(800,600)
                        flyFloat.Position=UDim2.fromOffset(
                            math.clamp(frameOrig.X+d.X,0,vp2.X-74),
                            math.clamp(frameOrig.Y+d.Y,0,vp2.Y-74))
                    end
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if dragging and inp.UserInputType==Enum.UserInputType.Touch then
                    dragging=false
                    if not moved and (tick()-tapStart)<0.35 then
                        -- Tap = toggle fly
                        if St.flyToggleOn then
                            toggleFly()
                            if St.flyActive then
                                stroke.Color=Color3.fromRGB(80,255,80)
                                lbl.TextColor3=Color3.fromRGB(80,255,80)
                                flyFloat.BackgroundColor3=Color3.fromRGB(8,28,8)
                            else
                                stroke.Color=Color3.fromRGB(30,100,30)
                                lbl.TextColor3=Color3.fromRGB(60,200,60)
                                flyFloat.BackgroundColor3=Color3.fromRGB(4,14,4)
                            end
                        else
                            notify("Fly","Enable the Fly toggle first.",2)
                        end
                    end
                end
            end)

            -- Visual sync loop
            task.spawn(function()
                while mobileFlyGui and mobileFlyGui.Parent do
                    task.wait(0.25)
                    if not mobileFlyFloat then break end
                    if St.flyActive then
                        pcall(function()
                            mobileFlyStroke.Color=Color3.fromRGB(80,255,80)
                            mobileFlyLbl.TextColor3=Color3.fromRGB(80,255,80)
                            mobileFlyFloat.BackgroundColor3=Color3.fromRGB(8,28,8)
                        end)
                    else
                        pcall(function()
                            mobileFlyStroke.Color=Color3.fromRGB(30,100,30)
                            mobileFlyLbl.TextColor3=Color3.fromRGB(60,200,60)
                            mobileFlyFloat.BackgroundColor3=Color3.fromRGB(4,14,4)
                        end)
                    end
                end
            end)
        end

        -- Expose builders so the mobile fly toggle can show/hide the button
        _G.buildFlyFloatButton   = buildFlyFloatButton
        _G.destroyFlyFloatButton = destroyFlyFloatButton

        local function hookMobileThumbstick()
            if Cn.mobileFlyThumbConn then
                Cn.mobileFlyThumbConn:Disconnect(); Cn.mobileFlyThumbConn=nil
            end
            Cn.mobileFlyThumbConn=RunService.Heartbeat:Connect(function()
                if not St.flyActive then mobileFlyVector=Vector3.zero; return end
                local char=LocalPlayer.Character
                if not char then mobileFlyVector=Vector3.zero; return end
                local moveDir=St.flyHumanoid and St.flyHumanoid.MoveDirection or Vector3.zero
                if moveDir.Magnitude>0.01 then
                    local camCF=Camera.CFrame
                    local flat=Vector3.new(camCF.LookVector.X,0,camCF.LookVector.Z)
                    if flat.Magnitude>0.01 then flat=flat.Unit end
                    local right=Vector3.new(camCF.RightVector.X,0,camCF.RightVector.Z)
                    if right.Magnitude>0.01 then right=right.Unit end
                    -- Dot products correctly project world movement onto camera axes
                local fwd=moveDir:Dot(flat)
                local rt=moveDir:Dot(right)
                local crm=flat*fwd+right*rt
                mobileFlyVector=Vector3.new(crm.X,camCF.LookVector.Y,crm.Z)
                else
                    mobileFlyVector=Vector3.zero
                end
            end)
        end

       -- Thumbstick hook started/stopped by fly toggle, not at load time
        _G.hookMobileThumbstick   = hookMobileThumbstick
    end

    -- Mobile standalone sweep overlay
    do
        local MOV={W=182,TITLE=26,ROW_H=26}
        local mobOvGui=nil; local mobOvFrame=nil; local mobOvCountLbl=nil
        local mobOvConn=nil; local mobOvPos=nil

        local function mobOvDestroy()
            if mobOvConn then mobOvConn:Disconnect(); mobOvConn=nil end
            local pg=LocalPlayer:FindFirstChild("PlayerGui")
            if pg then for _,v in ipairs(pg:GetChildren()) do
                if v.Name=="GojoMobStandalone" then pcall(function() v:Destroy() end) end
            end end
            mobOvGui=nil; mobOvFrame=nil; mobOvCountLbl=nil
        end

        local function mobOvRebuild()
            if not mobOvFrame or not mobOvFrame.Parent then return end
            local scroll=mobOvFrame:FindFirstChild("MobOvScroll"); if not scroll then return end
            for _,ch in ipairs(scroll:GetChildren()) do
                if ch:IsA("Frame") then pcall(function() ch:Destroy() end) end
            end
            local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targets=myHRP and getValidTargets(myHRP) or {}
            local pc=0
            for _,t in ipairs(targets) do if Players:FindFirstChild(t.name) then pc=pc+1 end end
            if mobOvCountLbl then mobOvCountLbl.Text="#"..#targets.."  ("..pc.."P)" end
            for i,tgt in ipairs(targets) do
                local n=tgt.name
                local isP=Players:FindFirstChild(n)~=nil
                local isWL=St.whitelist[n]~=nil
                local hp=0
                if tgt.Humanoid and tgt.Humanoid.MaxHealth and tgt.Humanoid.MaxHealth>0 then
                    hp=math.floor(tgt.Humanoid.Health/tgt.Humanoid.MaxHealth*100)
                end
                local rf=Instance.new("Frame")
                rf.Size=UDim2.new(1,-4,0,MOV.ROW_H-2)
                rf.BackgroundColor3=isWL and Color3.fromRGB(24,24,4)
                    or (isP and Color3.fromRGB(12,4,4) or Color3.fromRGB(4,10,4))
                rf.BorderSizePixel=0; rf.LayoutOrder=i; rf.ZIndex=3; rf.Parent=scroll
                Instance.new("UICorner",rf).CornerRadius=UDim.new(0,5)
                makeStroke(rf, isWL and Color3.fromRGB(160,160,30)
                    or (isP and Color3.fromRGB(80,120,255) or Color3.fromRGB(60,180,60)), 1, 0.6)
                local nb=Instance.new("TextButton")
                nb.Size=UDim2.new(1,0,1,0); nb.Position=UDim2.new(0,4,0,0)
                nb.BackgroundTransparency=1
                nb.Text=(isP and "[P] " or "[N] ")..n.." "..hp.."%"..(isWL and " ✓" or "")
                nb.TextColor3=isWL and Color3.fromRGB(200,200,60) or Color3.fromRGB(230,200,200)
                nb.TextSize=8; nb.Font=Enum.Font.GothamBold
                nb.TextXAlignment=Enum.TextXAlignment.Left; nb.ZIndex=4; nb.Parent=rf
                local cn=n
                nb.InputBegan:Connect(function(inp)
                    if inp.UserInputType==Enum.UserInputType.Touch then
                        if St.whitelist[cn] then St.whitelist[cn]=nil; notify("Whitelist","Removed: "..cn,2)
                        else St.whitelist[cn]=true; notify("Whitelist","Added: "..cn,2) end
                    end
                end)
            end
        end

        local function mobOvBuild()
            mobOvDestroy()
            local vp=Camera and Camera.ViewportSize or Vector2.new(800,600)
            local cx=math.clamp(mobOvPos and mobOvPos.X or vp.X-MOV.W-8,0,vp.X-MOV.W-4)
            local cy=math.clamp(mobOvPos and mobOvPos.Y or 80,0,vp.Y-100)
            mobOvGui=Instance.new("ScreenGui")
            mobOvGui.Name="GojoMobStandalone"; mobOvGui.ResetOnSpawn=false
            mobOvGui.DisplayOrder=1001; mobOvGui.IgnoreGuiInset=true
            mobOvGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
            mobOvGui.Parent=LocalPlayer:WaitForChild("PlayerGui")
            mobOvFrame=Instance.new("Frame")
            mobOvFrame.Size=UDim2.fromOffset(MOV.W,80); mobOvFrame.Position=UDim2.fromOffset(cx,cy)
            mobOvFrame.BackgroundColor3=Color3.fromRGB(10,4,4); mobOvFrame.BorderSizePixel=0
            mobOvFrame.ClipsDescendants=true; mobOvFrame.Active=true; mobOvFrame.Parent=mobOvGui
            Instance.new("UICorner",mobOvFrame).CornerRadius=UDim.new(0,10)
            makeStroke(mobOvFrame,Color3.fromRGB(160,10,10),1.5,0.2)
            local titleBar=Instance.new("Frame")
            titleBar.Size=UDim2.new(1,0,0,MOV.TITLE); titleBar.BackgroundColor3=Color3.fromRGB(18,5,5)
            titleBar.BorderSizePixel=0; titleBar.ZIndex=2; titleBar.Active=true; titleBar.Parent=mobOvFrame
            mobOvCountLbl=Instance.new("TextLabel")
            mobOvCountLbl.Size=UDim2.new(1,-6,1,0); mobOvCountLbl.Position=UDim2.new(0,6,0,0)
            mobOvCountLbl.BackgroundTransparency=1; mobOvCountLbl.Text="#0  (0P)"
            mobOvCountLbl.TextColor3=Color3.fromRGB(200,20,20); mobOvCountLbl.TextSize=10
            mobOvCountLbl.Font=Enum.Font.GothamBold; mobOvCountLbl.TextXAlignment=Enum.TextXAlignment.Left
            mobOvCountLbl.ZIndex=3; mobOvCountLbl.Parent=titleBar
            local ovDrg=false; local ovDragOr=Vector2.zero; local ovFrOr=Vector2.zero
            titleBar.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.Touch then
                    ovDrg=true; ovDragOr=Vector2.new(inp.Position.X,inp.Position.Y)
                    ovFrOr=Vector2.new(mobOvFrame.Position.X.Offset,mobOvFrame.Position.Y.Offset)
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if ovDrg and mobOvFrame and inp.UserInputType==Enum.UserInputType.Touch then
                    local d=Vector2.new(inp.Position.X,inp.Position.Y)-ovDragOr
                    local vp2=Camera and Camera.ViewportSize or Vector2.new(800,600)
                    mobOvFrame.Position=UDim2.fromOffset(
                        math.clamp(ovFrOr.X+d.X,0,math.max(0,vp2.X-MOV.W-4)),
                        math.clamp(ovFrOr.Y+d.Y,0,math.max(0,vp2.Y-40)))
                    mobOvPos=Vector2.new(mobOvFrame.Position.X.Offset,mobOvFrame.Position.Y.Offset)
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.Touch then ovDrg=false end
            end)
            local scroll=Instance.new("ScrollingFrame")
            scroll.Name="MobOvScroll"; scroll.Size=UDim2.new(1,-4,1,-MOV.TITLE-2)
            scroll.Position=UDim2.new(0,2,0,MOV.TITLE+1); scroll.BackgroundTransparency=1
            scroll.ScrollBarThickness=2; scroll.ScrollBarImageColor3=Color3.fromRGB(160,10,10)
            scroll.BorderSizePixel=0; scroll.ScrollingDirection=Enum.ScrollingDirection.Y
            scroll.ZIndex=2; scroll.Parent=mobOvFrame
            local rl=Instance.new("UIListLayout")
            rl.Padding=UDim.new(0,2); rl.SortOrder=Enum.SortOrder.LayoutOrder; rl.Parent=scroll
            rl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                local ch=rl.AbsoluteContentSize.Y+4
                scroll.CanvasSize=UDim2.fromOffset(0,ch)
                local vp3=Camera and Camera.ViewportSize or Vector2.new(800,600)
                local maxH=vp3.Y-mobOvFrame.AbsolutePosition.Y-20
                mobOvFrame.Size=UDim2.fromOffset(MOV.W,math.max(math.min(MOV.TITLE+ch+6,maxH),MOV.TITLE+28))
            end)
            local _lr=0
            mobOvConn=RunService.Heartbeat:Connect(function()
                local now=tick(); if now-_lr<1.0 then return end; _lr=now; mobOvRebuild()
            end)
            mobOvRebuild()
        end

        _G.buildMobileStandaloneOverlay   = mobOvBuild
        _G.destroyMobileStandaloneOverlay = mobOvDestroy
    end

-- Lock-on float button
    do
        local loGui=nil; local loFloat=nil; local loStroke=nil; local loLbl=nil

        local function destroyLockOnFloatButton()
            if loGui and loGui.Parent then pcall(function() loGui:Destroy() end) end
            loGui=nil; loFloat=nil; loStroke=nil; loLbl=nil
        end

        local function buildLockOnFloatButton()
            destroyLockOnFloatButton()
            loGui=Instance.new("ScreenGui")
            loGui.Name="GojoLockOnFloat"; loGui.ResetOnSpawn=false
            loGui.DisplayOrder=9997; loGui.IgnoreGuiInset=true
            loGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
            loGui.Parent=LocalPlayer:WaitForChild("PlayerGui")
            local vp=Camera and Camera.ViewportSize or Vector2.new(800,600)
            local lf=Instance.new("Frame")
            lf.Size=UDim2.fromOffset(64,64)
            lf.Position=UDim2.fromOffset(math.clamp(vp.X-170,0,vp.X-68),math.clamp(vp.Y-250,0,vp.Y-68))
            lf.BackgroundColor3=Color3.fromRGB(4,10,22); lf.BorderSizePixel=0
            lf.Active=true; lf.ZIndex=2; lf.Parent=loGui
            Instance.new("UICorner",lf).CornerRadius=UDim.new(0.5,0)
            local stroke=Instance.new("UIStroke")
            stroke.Color=Color3.fromRGB(30,80,220); stroke.Thickness=2.5
            stroke.Transparency=0; stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
            stroke.Parent=lf
            local lbl=Instance.new("TextLabel")
            lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
            lbl.Text="LOCK"; lbl.TextColor3=Color3.fromRGB(60,140,255)
            lbl.TextSize=11; lbl.Font=Enum.Font.GothamBold; lbl.ZIndex=3; lbl.Parent=lf
            local btn=Instance.new("TextButton")
            btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1
            btn.Text=""; btn.ZIndex=4; btn.Parent=lf
            loFloat=lf; loStroke=stroke; loLbl=lbl
            local loDrg=false; local loTapS=0
            local loDragOr=Vector2.zero; local loFrOr=Vector2.zero; local loMvd=false
            btn.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.Touch then
                    loDrg=true; loMvd=false; loTapS=tick()
                    loDragOr=Vector2.new(inp.Position.X,inp.Position.Y)
                    loFrOr=Vector2.new(lf.Position.X.Offset,lf.Position.Y.Offset)
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if loDrg and inp.UserInputType==Enum.UserInputType.Touch then
                    local d=Vector2.new(inp.Position.X,inp.Position.Y)-loDragOr
                    if d.Magnitude>12 then loMvd=true end
                    if loMvd then  -- drag guard
                        local vp2=Camera and Camera.ViewportSize or Vector2.new(800,600)
                        lf.Position=UDim2.fromOffset(math.clamp(loFrOr.X+d.X,0,vp2.X-68),math.clamp(loFrOr.Y+d.Y,0,vp2.Y-68))
                    end
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if loDrg and inp.UserInputType==Enum.UserInputType.Touch then
                    loDrg=false
                    if not loMvd and (tick()-loTapS)<0.35 then
                        if St.lockOnEnabled then
                            disableLockOn()
                        else
                            St.lockOnEnabled=true; enableLockOn()
                        end
                    end
                end
            end)
            -- Visual sync loop
            task.spawn(function()
                while loGui and loGui.Parent do
                    task.wait(0.25); if not loFloat then break end
                    if St.lockOnEnabled then
                        pcall(function()
                            stroke.Color=Color3.fromRGB(80,200,255); lbl.TextColor3=Color3.fromRGB(80,200,255)
                            lf.BackgroundColor3=Color3.fromRGB(4,22,44); lbl.Text="ON"
                        end)
                    else
                        pcall(function()
                            stroke.Color=Color3.fromRGB(30,80,220); lbl.TextColor3=Color3.fromRGB(60,140,255)
                            lf.BackgroundColor3=Color3.fromRGB(4,10,22); lbl.Text="LOCK"
                        end)
                    end
                end
            end)
        end
        _G.buildLockOnFloatButton   = buildLockOnFloatButton
        _G.destroyLockOnFloatButton = destroyLockOnFloatButton
    end

    do
        local Fluent=loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
        local SaveManager=loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
        local InterfaceManager=loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

        local Window=Fluent:CreateWindow({
            Title="Gojo Domain V32",SubTitle="Mobile",TabWidth=110,
            Size=UDim2.fromOffset(370,300),Acrylic=false,Theme="Dark",
            MinimizeKey=Enum.KeyCode.LeftControl,
        })
        local Tabs={
            Combat=Window:AddTab({Title="Combat",Icon="sword"}),
            Settings=Window:AddTab({Title="Settings",Icon="settings"}),
            Extras=Window:AddTab({Title="Extras",Icon="star"}),
            Targets=Window:AddTab({Title="Targets",Icon="crosshair"}),
            Items=Window:AddTab({Title="Items",Icon="package"}),
            Chars = Window:AddTab({Title="Characters", Icon="user"})
        }

        -- Mobile overlay
        local MOL={W=200,TITLE=30,ROW_H=30}
        local mobileOverlayGui,mobileOverlayFrame,mobileOverlayCountLbl=nil,nil,nil
        local mobileOverlayRows,mobileOverlayData={},{}
        local mobileOverlayConn=nil; local mobileOverlaySavedPos=nil

        local function destroyMobileOverlay()
            if mobileOverlayConn then mobileOverlayConn:Disconnect(); mobileOverlayConn=nil end
            local pg=LocalPlayer:FindFirstChild("PlayerGui")
            if pg then for _,v in ipairs(pg:GetChildren()) do
                if v.Name=="GojoMobileOverlay" then pcall(function() v:Destroy() end) end
            end end
            mobileOverlayGui=nil; mobileOverlayFrame=nil; mobileOverlayCountLbl=nil; mobileOverlayRows={}
        end

        local function updateMobileOverlay()
            for name,data in pairs(mobileOverlayData) do
                if not data.resolved then
                    local player=Players:FindFirstChild(name)
                    local char=player and player.Character
                    local hum=char and char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local hp=hum.Health
                        if hp<=0 and not data.isDead then
                            data.kills=data.kills+1; data.isDead=true
                            local row=mobileOverlayRows[name]
                            if row then
                                row.label.Text="DEAD "..name..(data.kills>1 and " x"..data.kills or "")
                                row.label.TextColor3=Color3.fromRGB(80,220,100)
                                row.frame.BackgroundColor3=Color3.fromRGB(10,30,10)
                            end
                        elseif hp>0 and data.isDead then
                            data.isDead=false; data.lastHP=hp
                            local row=mobileOverlayRows[name]
                            if row then
                                row.label.Text="... "..name
                                row.label.TextColor3=Color3.fromRGB(220,180,180)
                                row.frame.BackgroundColor3=Color3.fromRGB(18,6,6)
                            end
                        end
                        data.lastHP=hp
                    end
                end
            end
        end

        local function resolveMobileOverlay()
            for name,data in pairs(mobileOverlayData) do
                if not data.resolved then
                    data.resolved=true
                    local player=Players:FindFirstChild(name)
                    local char=player and player.Character
                    local hum=char and char:FindFirstChildOfClass("Humanoid")
                    local survived=hum and hum.Health>0
                    local row=mobileOverlayRows[name]
                    if row then
                        if survived then
                            row.label.Text="ALIVE "..name..(data.kills>0 and " x"..data.kills or "")
                            row.label.TextColor3=Color3.fromRGB(220,60,60)
                            row.frame.BackgroundColor3=Color3.fromRGB(40,8,8)
                        else
                            row.label.Text="DEAD "..name..(data.kills>0 and " x"..data.kills or "")
                            row.label.TextColor3=Color3.fromRGB(80,220,100)
                            row.frame.BackgroundColor3=Color3.fromRGB(10,30,10)
                        end
                    end
                end
            end
        end

        local function buildMobileOverlay(allTargets)
            destroyMobileOverlay()
            if not St.overlayEnabled then return end
            if #allTargets==0 then return end
            local vp=Camera and Camera.ViewportSize or Vector2.new(800,600)
            local olH=MOL.TITLE+#allTargets*MOL.ROW_H+8
            mobileOverlayGui=Instance.new("ScreenGui")
            mobileOverlayGui.Name="GojoMobileOverlay"; mobileOverlayGui.ResetOnSpawn=false
            mobileOverlayGui.DisplayOrder=1000; mobileOverlayGui.IgnoreGuiInset=true
            mobileOverlayGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
            mobileOverlayGui.Parent=LocalPlayer:WaitForChild("PlayerGui")
            local spx=mobileOverlaySavedPos and mobileOverlaySavedPos.X or (vp.X-MOL.W-10)
            local spy=mobileOverlaySavedPos and mobileOverlaySavedPos.Y or 80
            local cx=math.clamp(spx,0,math.max(0,vp.X-MOL.W-4))
            local cy=math.clamp(spy,0,math.max(0,vp.Y-olH-4))
            mobileOverlayFrame=Instance.new("Frame")
            mobileOverlayFrame.Size=UDim2.fromOffset(MOL.W,olH)
            mobileOverlayFrame.Position=UDim2.fromOffset(cx,cy)
            mobileOverlayFrame.BackgroundColor3=Color3.fromRGB(10,4,4)
            mobileOverlayFrame.BorderSizePixel=0; mobileOverlayFrame.ClipsDescendants=true
            mobileOverlayFrame.Active=true; mobileOverlayFrame.Parent=mobileOverlayGui
            Instance.new("UICorner",mobileOverlayFrame).CornerRadius=UDim.new(0,10)
            makeStroke(mobileOverlayFrame,Color3.fromRGB(160,10,10),1.5,0.2)
            local titleBar=Instance.new("Frame")
            titleBar.Size=UDim2.new(1,0,0,MOL.TITLE); titleBar.BackgroundColor3=Color3.fromRGB(20,5,5)
            titleBar.BorderSizePixel=0; titleBar.ZIndex=2; titleBar.Active=true; titleBar.Parent=mobileOverlayFrame
            mobileOverlayCountLbl=Instance.new("TextLabel")
            mobileOverlayCountLbl.Size=UDim2.new(1,-8,1,0); mobileOverlayCountLbl.Position=UDim2.new(0,8,0,0)
            mobileOverlayCountLbl.BackgroundTransparency=1
            mobileOverlayCountLbl.Text="Sweeping "..#allTargets.." targets"
            mobileOverlayCountLbl.TextColor3=Color3.fromRGB(220,50,50); mobileOverlayCountLbl.TextSize=11
            mobileOverlayCountLbl.Font=Enum.Font.GothamBold
            mobileOverlayCountLbl.TextXAlignment=Enum.TextXAlignment.Left
            mobileOverlayCountLbl.ZIndex=3; mobileOverlayCountLbl.Parent=titleBar
            local olDragging=false; local olDragOrigin=Vector2.zero; local olFrameOrig=Vector2.zero
            titleBar.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.Touch then
                    olDragging=true
                    olDragOrigin=Vector2.new(inp.Position.X,inp.Position.Y)
                    olFrameOrig=Vector2.new(mobileOverlayFrame.Position.X.Offset,mobileOverlayFrame.Position.Y.Offset)
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if olDragging and mobileOverlayFrame and inp.UserInputType==Enum.UserInputType.Touch then
                    local d=Vector2.new(inp.Position.X,inp.Position.Y)-olDragOrigin
                    local vp2=Camera and Camera.ViewportSize or Vector2.new(800,600)
                    local nx=math.clamp(olFrameOrig.X+d.X,0,math.max(0,vp2.X-MOL.W-4))
                    local ny=math.clamp(olFrameOrig.Y+d.Y,0,math.max(0,vp2.Y-olH-4))
                    mobileOverlayFrame.Position=UDim2.fromOffset(nx,ny)
                    mobileOverlaySavedPos=Vector2.new(nx,ny)
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.Touch then olDragging=false end
            end)
            local rowsFrame=Instance.new("Frame")
            rowsFrame.Size=UDim2.new(1,0,1,-MOL.TITLE); rowsFrame.Position=UDim2.new(0,0,0,MOL.TITLE)
            rowsFrame.BackgroundTransparency=1; rowsFrame.ZIndex=2; rowsFrame.Parent=mobileOverlayFrame
            local rowLayout=Instance.new("UIListLayout")
            rowLayout.SortOrder=Enum.SortOrder.LayoutOrder; rowLayout.Padding=UDim.new(0,2); rowLayout.Parent=rowsFrame
            mobileOverlayRows={}; mobileOverlayData={}
            for i,tgt in ipairs(allTargets) do
                local name=tgt.name
                mobileOverlayData[name]={kills=0,lastHP=tgt.Humanoid.Health,isDead=false,resolved=false}
                local rowFrame=Instance.new("Frame")
                rowFrame.Name="Row_"..name; rowFrame.Size=UDim2.new(1,-6,0,MOL.ROW_H-4)
                rowFrame.BackgroundColor3=Color3.fromRGB(18,6,6); rowFrame.BorderSizePixel=0
                rowFrame.LayoutOrder=i; rowFrame.ZIndex=3; rowFrame.Parent=rowsFrame
                Instance.new("UICorner",rowFrame).CornerRadius=UDim.new(0,6)
                makeStroke(rowFrame,Color3.fromRGB(140,10,10),1,0.6)
                local nameLbl=Instance.new("TextLabel")
                nameLbl.Size=UDim2.new(1,-8,1,0); nameLbl.Position=UDim2.new(0,6,0,0)
                nameLbl.BackgroundTransparency=1; nameLbl.Text="... "..name
                nameLbl.TextColor3=Color3.fromRGB(220,180,180); nameLbl.TextSize=10
                nameLbl.Font=Enum.Font.GothamBold; nameLbl.TextXAlignment=Enum.TextXAlignment.Left
                nameLbl.ZIndex=4; nameLbl.Parent=rowFrame
                mobileOverlayRows[name]={frame=rowFrame,label=nameLbl}
                local rowBtn=Instance.new("TextButton")
                rowBtn.Size=UDim2.new(1,0,1,0); rowBtn.BackgroundTransparency=1
                rowBtn.Text=""; rowBtn.ZIndex=5; rowBtn.Parent=rowFrame
              rowBtn.InputBegan:Connect(function(inp)
                    if inp.UserInputType==Enum.UserInputType.Touch then
                        if St.whitelist[name] then
                            St.whitelist[name]=nil
                            nameLbl.TextColor3=Color3.fromRGB(220,180,180)
                            rowFrame.BackgroundColor3=Color3.fromRGB(18,6,6)
                            notify("Whitelist","Removed: "..name,2)
                        else
                            St.whitelist[name]=true
                            nameLbl.TextColor3=Color3.fromRGB(180,180,60)
                            rowFrame.BackgroundColor3=Color3.fromRGB(20,20,4)
                            notify("Whitelist","Added: "..name,2)
                        end
                    end
                end)
            end
        end

       local function startMobileOverlayUpdates()
            if mobileOverlayConn then mobileOverlayConn:Disconnect() end
            local _lastMobOvl = 0
            mobileOverlayConn = RunService.Heartbeat:Connect(function()
                local now = tick()
                if now - _lastMobOvl < 0.1 then return end
                _lastMobOvl = now
                if next(mobileOverlayData) then updateMobileOverlay() end
            end)
        end
        local function stopMobileOverlayUpdates()
            if mobileOverlayConn then mobileOverlayConn:Disconnect(); mobileOverlayConn=nil end
        end

        local _origRunSweep=runSweep
        runSweep=function()
            local myChar=LocalPlayer.Character
            local myHRP=myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myChar or not myHRP then St.sweepActive=false; return end
            local allForOverlay={}
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LocalPlayer and p.Character then
                    local hum=p.Character:FindFirstChildOfClass("Humanoid")
                    local core=p.Character:FindFirstChild("HumanoidRootPart")
                           or p.Character:FindFirstChild("UpperTorso")
                           or p.Character:FindFirstChild("Torso")
                    if hum and core then
                        table.insert(allForOverlay,{Humanoid=hum,Core=core,Char=p.Character,name=p.Name})
                    end
                end
            end
            if St.overlayEnabled then buildMobileOverlay(allForOverlay); startMobileOverlayUpdates() end
            _origRunSweep()
            if St.overlayEnabled then
                resolveMobileOverlay(); stopMobileOverlayUpdates()
                task.delay(5,function() destroyMobileOverlay() end)
            end
        end

        -- COMBAT TAB
        Tabs.Combat:AddParagraph({Title="Status",Content="Idle"})
        Tabs.Combat:AddButton({Title="Start Sweep",Description="Teleport to all targets continuously",Callback=function()
            if not St.sweepActive then
                St.sweepActive=true; Workspace.FallenPartsDestroyHeight=Cfg.fallenHeight
                task.spawn(runSweep); notify("Sweep","Sweep started.",2)
            else notify("Sweep","Already sweeping.",2) end
        end})
        Tabs.Combat:AddButton({Title="Stop Sweep",Callback=function()
            St.sweepActive=false; Workspace.FallenPartsDestroyHeight=St.originalFallenHeight
            notify("Sweep","Stopped.",2)
        end})
        Tabs.Combat:AddButton({Title="Hunt for Cycle",Description="Auto-hunt for lucky bypass cycle",Callback=function()
            if St.luckyCycleFound then notify("Lucky Cycle!","Sweep to use it.",4)
            elseif not St.huntRunning then task.spawn(runHunt) end
        end})
        Tabs.Combat:AddButton({Title="Stop All",Callback=function() St.sweepActive=false; stopAll() end})
        Tabs.Combat:AddButton({Title="Void Reset",Callback=function()
            if St.luckyCycleFound then notify("Lucky!","Stop first.",3)
            else setStatus("Voiding..."); voidResetFallback()
                task.spawn(function() waitForDeathAndRespawn(); setStatus("Idle") end) end
        end})
      Tabs.Combat:AddToggle("MobileLockOn",{Title="Lock-On",Default=false,Callback=function(v)
            St.lockOnToggleOn=v
            St.lockOnEnabled=v
            if v then
                enableLockOn()
                if _G.buildLockOnFloatButton then _G.buildLockOnFloatButton() end
                notify("Lock-On","Enabled.",2)
            else
                disableLockOn()
                if _G.destroyLockOnFloatButton then _G.destroyLockOnFloatButton() end
                notify("Lock-On","Disabled.",2)
            end
        end})
        Tabs.Combat:AddDropdown("MobileLockOnMethod",{Title="Lock-On Method",Values={"Body","Camera"},Default="Body",
            Callback=function(v) Cfg.LockOn.Method=v end})
        Tabs.Combat:AddSlider("MobileLockOnSmooth",{Title="Lock-On Smoothness",Min=0.01,Max=1.0,Default=0.15,Rounding=2,
            Callback=function(v) Cfg.LockOn.Smoothness=v end})
        Tabs.Combat:AddSlider("MobileLockOnDist",{Title="Lock-On Max Distance",Min=10,Max=150,Default=60,Rounding=0,
            Callback=function(v) Cfg.LockOn.MaxDistance=v end})
        Tabs.Combat:AddButton({Title="Check AC Status",Callback=function() task.spawn(checkACStatus) end})
        Tabs.Combat:AddButton({Title="Force Reset",Callback=function()
            pcall(function()
                ReplicatedStorage:WaitForChild("Knit",3)
                    :WaitForChild("Knit",3)
                    :WaitForChild("Services",3)
                    .JoinService.RE.Reset:FireServer()
            end)
        end})
        Tabs.Combat:AddToggle("MobileNoDomainTP",{Title="No Domain TP",Default=false,Callback=function(v) St.noDomainTP=v end})
        Tabs.Combat:AddToggle("MobileIncludeNPCs",{Title="Include NPCs",Default=true,Callback=function(v) Cfg.INCLUDE_NPCS=v end})
        Tabs.Combat:AddToggle("MobileSweepOverlay",{Title="Sweep Overlay",Default=false,Callback=function(v)
            St.overlayEnabled=v
            if v then if _G.buildMobileStandaloneOverlay then _G.buildMobileStandaloneOverlay() end
            else if _G.destroyMobileStandaloneOverlay then _G.destroyMobileStandaloneOverlay() end end
        end})
        Tabs.Combat:AddToggle("MobileFly",{Title="Fly",Default=false,Callback=function(v)
            St.flyToggleOn=v
            if v then
                if _G.buildFlyFloatButton then _G.buildFlyFloatButton() end
                if _G.hookMobileThumbstick then _G.hookMobileThumbstick() end
                St.flyActive=true; enableFly(); notify("Fly","Enabled.",2)
            else
                disableFly()
                if _G.destroyFlyFloatButton then _G.destroyFlyFloatButton() end
                if Cn.mobileFlyThumbConn then Cn.mobileFlyThumbConn:Disconnect(); Cn.mobileFlyThumbConn=nil end
                notify("Fly","Disabled.",2)
            end
        end})
        Tabs.Combat:AddSlider("MobileFlySpeed",{Title="Fly Speed",Min=10,Max=650,Default=80,Rounding=0,Callback=function(v) Cfg.FlySpeed=v end})
        Tabs.Combat:AddButton({Title="Hitbox Extender",Callback=function()
            if St.hitboxLoaded then notify("Hitbox","Already loaded.",3); return end
            St.hitboxLoaded=true
            task.spawn(function() pcall(function()
                local Knit=require(ReplicatedStorage.Knit.Knit)
                local hb=Knit.GetController("HitboxController"); local old=hb.SphereHitbox
                hb.SphereHitbox=function(self,p,offset,sz)
                    local mult=40; local Size=sz*2.5; local data=old(self,p,offset,Size); local res={}
                    if data and #data>0 then for _,v in pairs(data) do for i=1,mult do table.insert(res,v) end end end
                    return res
                end; notify("Hitbox","Active.",3)
            end) end)
        end})
        Tabs.Combat:AddButton({Title="Yonk", Callback=function() yonkToggle() end})
        Tabs.Combat:AddSlider("MobileYonkSpeed",{Title="Yonk Speed",Min=0.1,Max=2,Default=1,Rounding=2,
            Callback=function(v)
                St.yonkSpeed=v
                if St.yonkAnimTrack then
                    pcall(function() St.yonkAnimTrack:AdjustSpeed(v) end)
                end
            end})
        Tabs.Combat:AddToggle("MobileHiromiQTE",{Title="Auto Hiromi QTE",Default=false,Callback=function(s)
            St.hiromiEnabled=s
            if s then hiromiStart(); notify("Auto Hiromi QTE","Enabled.",3)
            else hiromiStop(); notify("Auto Hiromi QTE","Disabled.",2) end
        end})
        Tabs.Combat:AddSlider("MobileQTESpeed",{Title="QTE Speed (ms)",Min=1,Max=220,Default=120,Rounding=0,
            Callback=function(v)
                St.hiromiMinMs=math.max(1,v-50)
                St.hiromiMaxMs=v
            end})

        -- SETTINGS TAB
        Tabs.Settings:AddSlider("MobileOffsetX",{Title="Offset X",Min=-10,Max=10,Default=0,Rounding=1,Callback=function(v) Cfg.offsetX=v end})
        Tabs.Settings:AddSlider("MobileOffsetY",{Title="Offset Y",Min=-10,Max=10,Default=0,Rounding=1,Callback=function(v) Cfg.offsetY=v end})
        Tabs.Settings:AddSlider("MobileOffsetZ",{Title="Offset Z",Min=0,Max=15,Default=2,Rounding=1,Callback=function(v) Cfg.offsetZ=v end})
        Tabs.Settings:AddSlider("MobileRespawnWait",{Title="Respawn Wait (s)",Min=1,Max=5,Default=1,Rounding=1,Callback=function(v) Cfg.RESPAWN_WAIT=v end})
        Tabs.Settings:AddSlider("MobileStability",{Title="Stability Duration",Min=0,Max=2,Default=1,Rounding=2,Callback=function(v) Cfg.STABILITY_DURATION=v end})
        Tabs.Settings:AddParagraph({Title="WARNING Fallen Height",Content="Do not touch unless you know what you're doing! | 0 = NaN/disabled"})
        Tabs.Settings:AddSlider("MobileFallenHeight",{Title="Fallen Height",Min=-500,Max=500,Default=-500,Rounding=0,Callback=function(v)
            if v == 0 then
                Cfg.fallenHeight = 0/0
                if St.sweepActive or St.attachActive then
                    pcall(function() Workspace.FallenPartsDestroyHeight = 0/0 end)
                end
            else
                Cfg.fallenHeight = v
                if St.sweepActive or St.attachActive then
                    Workspace.FallenPartsDestroyHeight = Cfg.fallenHeight
                end
            end
        end})
        Tabs.Settings:AddToggle("MobileDashMult",{Title="Dash Multiplier",Default=false,Callback=function(s)
            St.dashMultiplierEnabled=s
            if s then enableDashMultiplier(); notify("Dash Multiplier","Enabled.",3)
            else disableDashMultiplier(); notify("Dash Multiplier","Disabled.",3) end
        end})
        Tabs.Settings:AddSlider("MobileDashMultVal",{Title="Dash Multiplier Value",Min=0,Max=5,Default=1,Rounding=1,
            Callback=function(v)
                St.dashMultiplierValue=v
                if St.dashMultiplierEnabled then applyDashMultiplier(v) end
            end})
        Tabs.Settings:AddDropdown("MobileTPMode",{Title="TP Mode",Values={"Under","Behind"},Default="Under",Callback=function(v) Cfg.tpMode=v=="Under" and "under" or "behind" end})
        Tabs.Settings:AddDropdown("MobileTPMethod",{Title="TP Method",Values={"Default","Smart"},Default="Default",Callback=function(v) Cfg.tpMethod=v=="Default" and "default" or "smart" end})
        Tabs.Settings:AddDropdown("MobileSweepMode",{Title="Sweep Mode",Values={"Normal","Faster"},Default="Normal",Callback=function(v) Cfg.sweepMode=v=="Normal" and "normal" or "faster" end})
        Tabs.Settings:AddDropdown("MobileTPPriority",{Title="TP Priority",Values={"Normal","HP %"},Default="Normal",Callback=function(v) Cfg.tpPriority=v=="Normal" and "normal" or "hppct" end})
        Tabs.Settings:AddDropdown("MobileBFMode",{Title="BF Mode",Values={"Blatant","Legit"},Default="Blatant",Callback=function(v) St.bfMode=v=="Blatant" and "blatant" or "legit" end})

        -- EXTRAS TAB
        Tabs.Extras:AddToggle("MobileNoWallhop",{Title="No Wallhop Cooldown",Default=false,Callback=function(s)
            if s then enableNoWallhopCooldown() else disableNoWallhopCooldown() end
        end})
        Tabs.Extras:AddButton({Title="Unlock Emotes",Callback=function()
            if not St.emotesLoaded then St.emotesLoaded=true
                task.spawn(function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/SairyTheKing/emoteunlocktypashit/refs/heads/main/emote.lua"))() end) end)
                notify("Emotes","Unlock script fired.",3)
            else notify("Emotes","Already loaded.",3) end
        end})
        Tabs.Extras:AddToggle("MobileNoStun",{Title="No Stun",Default=false,Callback=function(s)
            if s then
                local cm=Workspace:FindFirstChild("Characters")
                if not cm then notify("No Stun","workspace.Characters not found.",4); return end
                local stunNames={InSkill=true,NoJump=true,NoSprint=true,Block=true,Stun=true,Knockback=true,Wakeup=true,Hold=true}
                St.noStunConn=cm.DescendantAdded:Connect(function(d)
                    if not stunNames[d.Name] then return end
                    local myChar=LocalPlayer.Character; if not myChar then return end
                    local parent=d.Parent
                    while parent and parent~=cm do
                        if parent==myChar then task.wait(); pcall(function() d:Destroy() end); return end
                        parent=parent.Parent
                    end
                end)
            else if St.noStunConn then St.noStunConn:Disconnect(); St.noStunConn=nil end end
        end})
        Tabs.Extras:AddToggle("MobileShrinkHitbox",{Title="Shrink Hitbox",Default=false,Callback=function(s)
            St.shrinkHitboxActive=s
            if s then
                local char=LocalPlayer.Character
                if char then task.spawn(function() setupShrinkForChar(char) end) end
                Cn.shrinkCharConn=LocalPlayer.CharacterAdded:Connect(function(newChar)
                    if St.shrinkHitboxActive then task.spawn(function() setupShrinkForChar(newChar) end) end
                end)
            else
                if Cn.shrinkCharConn then Cn.shrinkCharConn:Disconnect(); Cn.shrinkCharConn=nil end
                cleanupShrinkForChar(LocalPlayer.Character)
                for sc in pairs(St.shrinkDroneRefs) do cleanupShrinkForChar(sc) end
                for sc in pairs(St.shrinkAnimConns) do cleanupShrinkForChar(sc) end
            end
        end})
        Tabs.Extras:AddToggle("MobileInvisNoclip",{Title="Invisibility + Noclip",Default=false,Callback=function(s)
            St.invisActive=s
            if s then
                local char=LocalPlayer.Character
                if char then setupInvisForChar(char); startNoclip() end
                Cn.invisCharConn=LocalPlayer.CharacterAdded:Connect(function(newChar)
                    if St.invisActive then task.spawn(function() setupInvisForChar(newChar); startNoclip() end) end
                end)
            else
                cleanupInvis(LocalPlayer.Character); stopNoclip()
                if Cn.invisCharConn then Cn.invisCharConn:Disconnect(); Cn.invisCharConn=nil end
            end
        end})

       Tabs.Extras:AddToggle("MobileNoDashCooldown",{Title="No Dash Cooldown",Default=false,Callback=function(s)
            if s then enableNoDashCooldown(); notify("No Dash Cooldown","Enabled.",3)
            else disableNoDashCooldown(); notify("No Dash Cooldown","Disabled.",3) end
        end})
        Tabs.Extras:AddToggle("MobileNoKnockback",{Title="No Knockback",Default=false,Callback=function(s)
            if s then
                getgenv().KnockBackForce=0
                local char=LocalPlayer.Character
                if char then
                    local hrp=char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.ChildAdded:Connect(function(child)
                            if child.Name=="KnockbackForce" and child:IsA("BodyVelocity") then
                                child.Velocity=Vector3.new(0,0,0)
                            end
                        end)
                    end
                end
                LocalPlayer.CharacterAdded:Connect(function(character)
                    if not getgenv().KnockBackForce or getgenv().KnockBackForce~=0 then return end
                    local hrp=character:WaitForChild("HumanoidRootPart")
                    hrp.ChildAdded:Connect(function(child)
                        if child.Name=="KnockbackForce" and child:IsA("BodyVelocity") then
                            child.Velocity=Vector3.new(0,0,0)
                        end
                    end)
                end)
                notify("No Knockback","Enabled.",3)
            else
                getgenv().KnockBackForce=nil
                notify("No Knockback","Disabled. Rejoin for full effect.",3)
            end
        end})
        Tabs.Extras:AddToggle("MobileInvisBlock",{Title="Invisible Block",Default=false,Callback=function(s)
            if s and not St.invisLoaded then St.invisLoaded=true
                task.spawn(function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/NotEnoughJack/LuaFluentDependancies/refs/heads/main/InvisibleBlock.lua"))() end) end)
                notify("Invis Block","Loaded.",3)
            end
        end})
        Tabs.Extras:AddParagraph({Title="Emotes",Content="Select and fire an emote"})
        Tabs.Extras:AddDropdown("MobileEmoteSelect",{
            Title="Select Emote",Values=getEmoteNames(),Default=1,
            Callback=function(v) setEmoteIndex(v) end,
        })
        Tabs.Extras:AddButton({Title="Fire Emote",Callback=function() fireSelectedEmote() end})

        -- TARGETS TAB
        local mobileSelectedTarget=nil
        local TargetDropdown=Tabs.Targets:AddDropdown("MobileTargetSelect",{
            Title="Select Target",Values={"(press Refresh)"},Default=1,
            Callback=function(v)
                if v=="(none found)" or v=="(press Refresh)" then mobileSelectedTarget=nil; return end
                local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local allTgts=myHRP and getValidTargets(myHRP) or {}
                for _,t in ipairs(allTgts) do if t.name==v then mobileSelectedTarget=t; break end end
            end
        })
        Tabs.Targets:AddButton({Title="Refresh Targets",Callback=function()
            local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local allTgts=myHRP and getValidTargets(myHRP) or {}
            local names={}
            for _,t in ipairs(allTgts) do table.insert(names,t.name) end
            if #names==0 then names={"(none found)"} end
            TargetDropdown:SetValues(names); mobileSelectedTarget=nil; notify("Targets","Refreshed.",2)
        end})
        Tabs.Targets:AddButton({Title="Attach to Selected",Callback=function()
            if not mobileSelectedTarget then notify("Attach","Select a target first.",3); return end
            local tgt=mobileSelectedTarget
            if St.attachActive and St.attachTarget and St.attachTarget.name==tgt.name then
                local n=St.attachTarget.name; stopAttach()
                notify("Detached","Detached from "..n,3); setStatus("Idle"); return
            end
            local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local allTgts=myHRP and getValidTargets(myHRP) or {}; local live
            for _,t in ipairs(allTgts) do if t.name==tgt.name then live=t; break end end
            if not live then notify("Attach","Target not found/alive.",3); return end
            startAttach(live); notify("Attached","Locked onto "..tgt.name,3); setStatus("ATTACHED: "..tgt.name)
        end})
        Tabs.Targets:AddButton({Title="Detach",Callback=function()
            if St.attachActive then
                local n=St.attachTarget and St.attachTarget.name or "target"
                stopAttach(); notify("Detached","Detached from "..n,3); setStatus("Idle")
            else notify("Detach","Not attached.",2) end
        end})

        -- ITEMS TAB
        local mobileItemsCache={}
        local ItemDropdown=Tabs.Items:AddDropdown("MobileItemSelect",{Title="Select Item",Values={"(press Refresh)"},Default=1,Callback=function(v) end})
        Tabs.Items:AddButton({Title="Refresh Items",Callback=function()
            mobileItemsCache=getItemsList(); local names={}
            for _,item in ipairs(mobileItemsCache) do table.insert(names,item.name) end
            if #names==0 then names={"(none found)"} end
            ItemDropdown:SetValues(names); notify("Items","Refreshed "..#mobileItemsCache.." items.",2)
        end})
        Tabs.Items:AddButton({Title="Grab Selected Item",Callback=function()
            local selected=Fluent.Options.MobileItemSelect and Fluent.Options.MobileItemSelect.Value
            if not selected or selected=="(none found)" or selected=="(press Refresh)" then
                notify("Items","Select an item first.",3); return
            end
            local targetItem
            for _,item in ipairs(mobileItemsCache) do if item.name==selected then targetItem=item; break end end
            if not targetItem then notify("Items","Item not found. Refresh.",3); return end
            task.spawn(function()
                grabItem(targetItem.part,function(success)
                    if success then notify("Items","Grabbed: "..targetItem.name,3)
                    else notify("Items","Failed: "..targetItem.name,3) end
                end)
            end)
        end})
        
        -- CHARACTERS TAB (mobile)
        Tabs.Chars:AddParagraph({Title="Yuki",Content="Instant Blackhole"})
        Tabs.Chars:AddButton({Title="Instant Blackhole",Callback=function()
            if not St.instantBHLoaded then St.instantBHLoaded=true
                task.spawn(function() pcall(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/Dragonfly5101/Minosr/refs/heads/main/InstantBlackHole.JJS"))()
                end) end); notify("Instant Blackhole","Script loaded.",3)
            else notify("Instant Blackhole","Already loaded.",3) end
        end})

        Tabs.Chars:AddParagraph({Title="Yuta",Content="Yuta BF tools"})
        Tabs.Chars:AddButton({Title="Yuta BF Oneshot",Callback=function()
            if not St.yutaBFLoaded then St.yutaBFLoaded=true
                task.spawn(function() pcall(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/Lazzexaa/gugugaga/refs/heads/main/yutabf.txt"))()
                end) end); notify("Yuta BF Oneshot","Script loaded.",3)
            else notify("Yuta BF Oneshot","Already loaded.",3) end
        end})
        local yutaMobList={}
        for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then table.insert(yutaMobList,p.Name) end end
        local YutaDropMob2=Tabs.Chars:AddDropdown("CharsYutaTarget",{
            Title="Yuta BF Target",
            Values=#yutaMobList>0 and yutaMobList or {"(none)"},
            Default=1,
            Callback=function(v)
                if v=="(none)" then St.kokusenSelectedTarget=""; return end
                St.kokusenSelectedTarget=v
            end,
        })
        Tabs.Chars:AddButton({Title="Refresh Yuta BF List",Callback=function()
            local list={}
            for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then table.insert(list,p.Name) end end
            if #list==0 then list={"(none)"} end
            YutaDropMob2:SetValues(list); notify("Yuta BF","List refreshed.",2)
        end})
        Tabs.Chars:AddButton({Title="Execute Yuta BF",Callback=function()
            task.spawn(kokusenExecute)
        end})

        Tabs.Chars:AddParagraph({Title="Yuji",Content="Auto Black Flash"})
       Tabs.Chars:AddToggle("CharsAutoBF",{Title="Auto Black Flash",Default=false,Callback=function(v)
            if v then
                St.bfEnabled=true; bfStartAll()
                if _G.buildBFFloatButton then _G.buildBFFloatButton() end
                notify("Auto BF","Enabled.",3)
            else
                bfStopAll()
                if _G.destroyBFFloatButton then _G.destroyBFFloatButton() end
                notify("Auto BF","Disabled.",2)
            end
        end})
        Tabs.Chars:AddSlider("CharsBFRange",      {Title="BF Detect Range",Min=10,  Max=50, Default=25,  Rounding=0,Callback=function(v) Cfg.BF.Range=v end})
        Tabs.Chars:AddSlider("CharsBFGlide",      {Title="BF Glide Speed", Min=0.05,Max=1.0,Default=0.25,Rounding=2,Callback=function(v) Cfg.BF.Duration=v end})
        Tabs.Chars:AddSlider("CharsBFLandDist",   {Title="BF Landing Dist",Min=1,   Max=10, Default=3,   Rounding=1,Callback=function(v) Cfg.BF.Radius=v end})
        Tabs.Chars:AddSlider("CharsBFCurve",      {Title="BF Curve Width", Min=0,   Max=30, Default=14,  Rounding=0,Callback=function(v) Cfg.BF.CurveStrength=v end})
        Tabs.Chars:AddSlider("CharsBFPrediction", {Title="BF Prediction",  Min=0,   Max=2.0,Default=0.6, Rounding=2,Callback=function(v) Cfg.BF.PredictionMultiplier=v end})
        Tabs.Chars:AddSlider("CharsPingDelay",    {Title="Ping Delay (s)", Min=0,   Max=0.5,Default=0.12,Rounding=2,Callback=function(v) St.bfPingDelay=v end})
        Tabs.Chars:AddSlider("CharsLandLinger",   {Title="Landing Linger", Min=0,   Max=1.0,Default=0.2, Rounding=2,Callback=function(v) Cfg.BF.LandingLinger=v end})
        Tabs.Chars:AddSlider("CharsBFBackAngle",  {Title="Back Angle",      Min=0,  Max=1.0,Default=0.5,Rounding=2,Callback=function(v) Cfg.BF.BackAngleDot=v end})
        Tabs.Chars:AddSlider("CharsBFBehindDist", {Title="Behind Dist Extra",Min=0,  Max=10, Default=4,  Rounding=1,Callback=function(v) Cfg.BF.BehindDist=v end})
        Tabs.Chars:AddSlider("CharsBFFacingDot",  {Title="Facing Threshold", Min=0,  Max=1.0,Default=0.3,Rounding=2,Callback=function(v) Cfg.BF.FacingDot=v end})
        Tabs.Chars:AddSlider("CharsBFCurveK",     {Title="Curve Tightness",  Min=0.1,Max=1.5,Default=0.6,Rounding=2,Callback=function(v) Cfg.BF.GlideCurveK=v end})

        Tabs.Chars:AddParagraph({Title="Higuruma",Content="Vote viewer"})
        Tabs.Chars:AddButton({Title="Higurama Vote Viewer",Callback=function()
            task.spawn(function() pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/Dragonfly5101/Minosr/refs/heads/main/HigarumaVoteView.JJS"))()
            end) end)
            notify("Higurama Vote Viewer","Loaded.",3)
        end})

        Tabs.Chars:AddParagraph({Title="Nanami",Content="Ratio mechanics"})
        Tabs.Chars:AddToggle("CharsAutoRatio",{Title="Auto Ratio",Default=false,Callback=function(s)
            if s then enableAutoRatio(); notify("Auto Ratio","Enabled.",3)
            else disableAutoRatio(); notify("Auto Ratio","Disabled.",2) end
        end})

        SaveManager:SetLibrary(Fluent); InterfaceManager:SetLibrary(Fluent)
        SaveManager:IgnoreThemeSettings(); SaveManager:SetIgnoreIndexes({})
        InterfaceManager:SetFolder("GojoDomainV32"); SaveManager:SetFolder("GojoDomainV32/mobile")
        InterfaceManager:BuildInterfaceSection(Tabs.Settings); SaveManager:BuildConfigSection(Tabs.Settings)
        Window:SelectTab(1)
        Fluent:Notify({Title="Gojo Domain V32",Content="Mobile UI loaded.",Duration=4})
        SaveManager:LoadAutoloadConfig()

-- BF Float Button — built/destroyed by the BF toggle
        do
            local bfFloatGui=nil
            local bfFloat=nil; local bfFloatStroke=nil; local bfFloatLbl=nil

            local function destroyBFFloatButton()
                if bfFloatGui and bfFloatGui.Parent then pcall(function() bfFloatGui:Destroy() end) end
                bfFloatGui=nil; bfFloat=nil; bfFloatStroke=nil; bfFloatLbl=nil
            end

            local function buildBFFloatButton()
                destroyBFFloatButton()
                bfFloatGui=Instance.new("ScreenGui")
                bfFloatGui.Name="GojoBFFloat"; bfFloatGui.ResetOnSpawn=false
                bfFloatGui.DisplayOrder=9999; bfFloatGui.IgnoreGuiInset=true
                bfFloatGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
                bfFloatGui.Parent=LocalPlayer:WaitForChild("PlayerGui")
                local sc=Camera and Camera.ViewportSize or Vector2.new(800,600)
                local bf=Instance.new("Frame")
                bf.Size=UDim2.fromOffset(70,70)
                bf.Position=UDim2.fromOffset(math.clamp(sc.X-90,0,sc.X-74),math.clamp(sc.Y-160,0,sc.Y-74))
                bf.BackgroundColor3=Color3.fromRGB(8,4,18); bf.BorderSizePixel=0
                bf.Active=true; bf.ZIndex=2; bf.Parent=bfFloatGui
                Instance.new("UICorner",bf).CornerRadius=UDim.new(0.5,0)
                local stroke=Instance.new("UIStroke")
                stroke.Color=Color3.fromRGB(160,80,255); stroke.Thickness=2.5
                stroke.Transparency=0; stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
                stroke.Parent=bf
                local lbl=Instance.new("TextLabel")
                lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
                lbl.Text="BF"; lbl.TextColor3=Color3.fromRGB(160,80,255)
                lbl.TextSize=16; lbl.Font=Enum.Font.GothamBold; lbl.ZIndex=3; lbl.Parent=bf
                local btn=Instance.new("TextButton")
                btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1
                btn.Text=""; btn.ZIndex=4; btn.Parent=bf
                bfFloat=bf; bfFloatStroke=stroke; bfFloatLbl=lbl
                local bfDrg=false; local bfTapS=0
                local bfDragOr=Vector2.zero; local bfFrOr=Vector2.zero; local bfMvd=false
                btn.InputBegan:Connect(function(inp)
                    if inp.UserInputType==Enum.UserInputType.Touch then
                        bfDrg=true; bfMvd=false; bfTapS=tick()
                        bfDragOr=Vector2.new(inp.Position.X,inp.Position.Y)
                        bfFrOr=Vector2.new(bf.Position.X.Offset,bf.Position.Y.Offset)
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if bfDrg and inp.UserInputType==Enum.UserInputType.Touch then
                        local d=Vector2.new(inp.Position.X,inp.Position.Y)-bfDragOr
                        if d.Magnitude>12 then bfMvd=true end
                        if bfMvd then  -- drag guard: only move on intentional drag
                            local vp=Camera and Camera.ViewportSize or Vector2.new(800,600)
                            bf.Position=UDim2.fromOffset(math.clamp(bfFrOr.X+d.X,0,vp.X-74),math.clamp(bfFrOr.Y+d.Y,0,vp.Y-74))
                        end
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if bfDrg and inp.UserInputType==Enum.UserInputType.Touch then
                        bfDrg=false
                        if not bfMvd and (tick()-bfTapS)<0.35 then
                            if St.bfEnabled then
                                task.spawn(bfTriggerDash)
                                stroke.Color=Color3.fromRGB(255,200,50); lbl.TextColor3=Color3.fromRGB(255,200,50)
                                task.delay(0.2,function()
                                    if bfFloatGui and bfFloatGui.Parent then
                                        if St.bfEnabled then stroke.Color=Color3.fromRGB(160,80,255); lbl.TextColor3=Color3.fromRGB(160,80,255)
                                        else stroke.Color=Color3.fromRGB(60,30,100); lbl.TextColor3=Color3.fromRGB(120,60,200) end
                                    end
                                end)
                            else notify("Auto BF","Enable Auto BF first.",2) end
                        end
                    end
                end)
                task.spawn(function()
                    while bfFloatGui and bfFloatGui.Parent do
                        task.wait(0.25); if not bfFloat then break end
                        if St.bfEnabled then
                            pcall(function() stroke.Color=Color3.fromRGB(160,80,255); lbl.TextColor3=Color3.fromRGB(160,80,255); bf.BackgroundColor3=Color3.fromRGB(14,6,28) end)
                        else
                            pcall(function() stroke.Color=Color3.fromRGB(60,30,100); lbl.TextColor3=Color3.fromRGB(120,60,200); bf.BackgroundColor3=Color3.fromRGB(8,4,18) end)
                        end
                    end
                end)
            end
            _G.buildBFFloatButton   = buildBFFloatButton
            _G.destroyBFFloatButton = destroyBFFloatButton
        end
    end
end -- end if mobile

-- ============================================================
-- DESKTOP UI (Compkiller)
-- ============================================================
if not mobile then
    local Compkiller=loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/CompKiller/refs/heads/main/src/source.luau"))()
    local Notifier=Compkiller.newNotify()
    Compkiller:Loader("rbxassetid://120245531583106",1.5).yield()

    local sweepToggleSuppressed=false
    local Window=Compkiller.new({Name="BLUE gojo HUB",Keybind="RightAlt",Logo="rbxassetid://120245531583106",TextSize=10})
    --watermark removed

    Window:DrawCategory({Name="Combat"})
    local CombatTab=Window:DrawTab({Name="Combat",Icon="sword",Type="Double"})
    local MainSection=CombatTab:DrawSection({Name="Main",Position="left"})
    local StatusSection=CombatTab:DrawSection({Name="Status",Position="right"})
    St.StatusParagraph=StatusSection:AddParagraph({Title="Status",Content="Idle"})

    local SweepToggle=MainSection:AddToggle({Name="Sweep All",Default=false,Callback=function(state)
        if sweepToggleSuppressed then return end
        St.sweepActive=state
        if St.sweepActive then Workspace.FallenPartsDestroyHeight=Cfg.fallenHeight; task.spawn(runSweep)
        else Workspace.FallenPartsDestroyHeight=St.originalFallenHeight; setStatus("Idle") end
    end})
    SweepToggle.Link:AddHelper({Text="Teleport to all targets continuously"})

    local function setSweepToggle(state)
        sweepToggleSuppressed=true; St.sweepActive=state
        pcall(function() SweepToggle:Set(state) end); sweepToggleSuppressed=false
    end

    MainSection:AddButton({Name="Hunt for Cycle",Callback=function()
        if St.luckyCycleFound then notify("Lucky Cycle!","Press E to sweep. H to reset.",5); setStatus("Lucky — Press E"); return end
        if not St.huntRunning then task.spawn(runHunt) end
    end})
    MainSection:AddButton({Name="Stop All",Callback=function() setSweepToggle(false); stopAll() end})
    MainSection:AddButton({Name="Void",Callback=function()
        if St.luckyCycleFound then notify("Lucky Cycle!","Press Stop to clear first.",4); return end
        setStatus("Voiding..."); voidResetFallback()
        task.spawn(function() waitForDeathAndRespawn(); setStatus("Idle") end)
    end})
    MainSection:AddButton({Name="Check AC Status",Callback=function() task.spawn(checkACStatus) end})
    MainSection:AddButton({Name="Force Reset",Callback=function()
        pcall(function()
            ReplicatedStorage:WaitForChild("Knit",3)
                :WaitForChild("Knit",3)
                :WaitForChild("Services",3)
                .JoinService.RE.Reset:FireServer()
        end)
    end})
    local LockOnToggle=MainSection:AddToggle({Name="Lock-On",Default=false,Callback=function(state)
        St.lockOnToggleOn=state
        St.lockOnEnabled=state
        if state then enableLockOn(); notify("Lock-On","Enabled. Press "..Keys.lockOnKey.Name.." to toggle.",3)
        else disableLockOn(); notify("Lock-On","Disabled.",2) end
    end})
    LockOnToggle.Link:AddHelper({Text="Body=HRP faces target. Camera=Camera faces target."})
    local LockOnOpt=LockOnToggle.Link:AddOption()
    LockOnOpt:AddDropdown({Name="Method",Values={"Body","Camera"},Default="Body",
        Callback=function(v) Cfg.LockOn.Method=v end})
    LockOnOpt:AddSlider({Name="Smoothness",Min=0.01,Max=1.0,Default=0.15,Round=2,
        Callback=function(v) Cfg.LockOn.Smoothness=v end})
    LockOnOpt:AddSlider({Name="Max Distance",Min=10,Max=150,Default=60,Round=0,
        Callback=function(v) Cfg.LockOn.MaxDistance=v end})
    LockOnOpt:AddSlider({Name="Side Offset",Min=-5,Max=5,Default=0,Round=1,
        Callback=function(v) Cfg.LockOn.SideOffset=v end})
    local FlyToggleDT=MainSection:AddToggle({Name="Fly",Default=false,Callback=function(state)
        St.flyToggleOn=state
        if state then St.flyActive=true; enableFly(); notify("Fly","Flying enabled. Shift=Boost.",3)
        else disableFly(); notify("Fly","Flying disabled.",2) end
    end})
    FlyToggleDT.Link:AddHelper({Text="Heartbeat-based. Survives grabs. Shift for +200 speed boost."})
    MainSection:AddSlider({Name="Fly Speed",Min=10,Max=650,Default=80,Round=0,
        Callback=function(v) Cfg.FlySpeed=v end})
    MainSection:AddButton({Name="Hitbox Extender",Callback=function()
        if St.hitboxLoaded then notify("Hitbox","Already loaded.",3); return end
        St.hitboxLoaded=true
        task.spawn(function() pcall(function()
            local Knit=require(ReplicatedStorage.Knit.Knit)
            local hb=Knit.GetController("HitboxController"); local old=hb.SphereHitbox
            hb.SphereHitbox=function(self,p,offset,sz)
                local mult=40; local Size=sz*2.5; local data=old(self,p,offset,Size); local res={}
                if data and #data>0 then for _,v in pairs(data) do for i=1,mult do table.insert(res,v) end end end
                return res
            end; notify("Hitbox","Active.",3)
        end) end)
    end})

   -- Desktop overlay — standalone toggle-controlled window
    do
        local OL={W=244,TITLE=32,ROW_H=32}
        local overlayGui,overlayFrame,overlayCountLbl=nil,nil,nil
        local overlayRows={}
        local overlayUpdateConn=nil
        local overlaySavedPos=nil
        local _ovSpectate=nil
        local _ovSavedCam=nil

        local function ovStopSpectate()
            if not _ovSpectate then return end
            _ovSpectate=nil
            pcall(function()
                if _ovSavedCam and _ovSavedCam.Parent then Camera.CameraSubject=_ovSavedCam
                else
                    local c=LocalPlayer.Character; local h=c and c:FindFirstChildOfClass("Humanoid")
                    if h then Camera.CameraSubject=h end
                end
            end); _ovSavedCam=nil
        end

        local function ovStartSpectate(name)
            ovStopSpectate()
            local pl=Players:FindFirstChild(name)
            if not pl or not pl.Character then return false end
            local hum=pl.Character:FindFirstChildOfClass("Humanoid"); if not hum then return false end
            _ovSavedCam=Camera.CameraSubject; _ovSpectate=name; Camera.CameraSubject=hum; return true
        end

        destroyOverlay=function()
            if overlayUpdateConn then overlayUpdateConn:Disconnect(); overlayUpdateConn=nil end
            ovStopSpectate()
            local pg=LocalPlayer:FindFirstChild("PlayerGui")
            if pg then for _,v in ipairs(pg:GetChildren()) do
                if v.Name=="GojoDomainOverlay" then pcall(function() v:Destroy() end) end
            end end
            overlayGui=nil; overlayFrame=nil; overlayCountLbl=nil; overlayRows={}
        end

        local function ovRebuild()
            if not overlayFrame or not overlayFrame.Parent then return end
            local scroll=overlayFrame:FindFirstChild("OvScroll"); if not scroll then return end
            -- Auto-stop spectate if target gone
            if _ovSpectate then
                local sp=Players:FindFirstChild(_ovSpectate)
                if not sp or not sp.Character then ovStopSpectate() end
            end
            -- Clear old rows
            for _,ch in ipairs(scroll:GetChildren()) do
                if ch:IsA("Frame") then pcall(function() ch:Destroy() end) end
            end
            overlayRows={}
            local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targets=myHRP and getValidTargets(myHRP) or {}
            local pc=0
            for _,t in ipairs(targets) do if Players:FindFirstChild(t.name) then pc=pc+1 end end
            if overlayCountLbl then overlayCountLbl.Text="TARGETS "..#targets.."  ("..pc.." players)" end
            for i,tgt in ipairs(targets) do
                local n=tgt.name
                local isP=Players:FindFirstChild(n)~=nil
                local isWL=St.whitelist[n]~=nil
                local isSpy=_ovSpectate==n
                local hp=0
                if tgt.Humanoid and tgt.Humanoid.Parent and tgt.Humanoid.MaxHealth and tgt.Humanoid.MaxHealth>0 then
                    hp=math.floor(tgt.Humanoid.Health/tgt.Humanoid.MaxHealth*100)
                end
                local rf=Instance.new("Frame")
                rf.Name="OvRow_"..n
                rf.Size=UDim2.new(1,-4,0,OL.ROW_H-2)
                rf.BackgroundColor3=isWL and Color3.fromRGB(26,26,4)
                    or (isP and Color3.fromRGB(12,4,4) or Color3.fromRGB(4,10,4))
                rf.BorderSizePixel=0; rf.LayoutOrder=i; rf.ZIndex=3; rf.Parent=scroll
                Instance.new("UICorner",rf).CornerRadius=UDim.new(0,6)
                makeStroke(rf, isWL and Color3.fromRGB(180,180,40)
                    or (isP and Color3.fromRGB(80,130,255) or Color3.fromRGB(80,200,80)), 1, 0.55)
                -- Name label/button → left-click = whitelist toggle
                local nb=Instance.new("TextButton")
                nb.Size=UDim2.new(1,-64,1,0); nb.Position=UDim2.new(0,6,0,0)
                nb.BackgroundTransparency=1
                nb.Text=(isP and "[P] " or "[N] ")..n.." "..hp.."%"..(isWL and " ✓" or "")
                nb.TextColor3=isWL and Color3.fromRGB(200,200,60) or Color3.fromRGB(230,200,200)
                nb.TextSize=9; nb.Font=Enum.Font.GothamBold
                nb.TextXAlignment=Enum.TextXAlignment.Left; nb.ZIndex=5; nb.Parent=rf
                -- View button → spectate toggle
                local vb=Instance.new("TextButton")
                vb.Size=UDim2.new(0,38,0,OL.ROW_H-10); vb.Position=UDim2.new(1,-42,0,4)
                vb.BackgroundColor3=isSpy and Color3.fromRGB(20,20,60) or Color3.fromRGB(10,10,28)
                vb.Text=isSpy and "■ Stop" or "▶ View"
                vb.TextColor3=isSpy and Color3.fromRGB(160,160,255) or Color3.fromRGB(100,100,200)
                vb.TextSize=8; vb.Font=Enum.Font.GothamBold; vb.BorderSizePixel=0; vb.ZIndex=5; vb.Parent=rf
                Instance.new("UICorner",vb).CornerRadius=UDim.new(0,5)
                local cn=n
                nb.MouseButton1Click:Connect(function()
                    if St.whitelist[cn] then St.whitelist[cn]=nil; notify("Whitelist","Removed: "..cn,2)
                    else St.whitelist[cn]=true; notify("Whitelist","Added: "..cn,2) end
                end)
                vb.MouseButton1Click:Connect(function()
                    if _ovSpectate==cn then ovStopSpectate(); notify("Spectate","Stopped.",2)
                    elseif isP then
                        if ovStartSpectate(cn) then notify("Spectate","Spectating "..cn,2)
                        else notify("Spectate","Target unavailable.",2) end
                    else notify("Spectate","Can only spectate players.",2) end
                end)
                overlayRows[n]={frame=rf}
            end
        end

        buildOverlay=function()
            destroyOverlay()
            local screen=Camera and Camera.ViewportSize or Vector2.new(800,600)
            overlayGui=Instance.new("ScreenGui")
            overlayGui.Name="GojoDomainOverlay"; overlayGui.ResetOnSpawn=false
            overlayGui.IgnoreGuiInset=true; overlayGui.DisplayOrder=1000
            overlayGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
            overlayGui.Parent=LocalPlayer:WaitForChild("PlayerGui")
            local cx=math.clamp(overlaySavedPos and overlaySavedPos.X or screen.X-OL.W-14,0,screen.X-OL.W-4)
            local cy=math.clamp(overlaySavedPos and overlaySavedPos.Y or 90,0,screen.Y-200)
            overlayFrame=Instance.new("Frame")
            overlayFrame.Size=UDim2.fromOffset(OL.W,200)
            overlayFrame.Position=UDim2.fromOffset(cx,cy)
            overlayFrame.BackgroundColor3=Color3.fromRGB(10,4,4); overlayFrame.BorderSizePixel=0
            overlayFrame.ClipsDescendants=true; overlayFrame.Active=true; overlayFrame.Parent=overlayGui
            Instance.new("UICorner",overlayFrame).CornerRadius=UDim.new(0,12)
            makeStroke(overlayFrame,Color3.fromRGB(160,10,10),1.5,0.2)
            local titleBar=Instance.new("Frame")
            titleBar.Size=UDim2.new(1,0,0,OL.TITLE); titleBar.BackgroundColor3=Color3.fromRGB(18,5,5)
            titleBar.BorderSizePixel=0; titleBar.ZIndex=2; titleBar.Parent=overlayFrame
            overlayCountLbl=Instance.new("TextLabel")
            overlayCountLbl.Size=UDim2.new(1,-8,1,0); overlayCountLbl.Position=UDim2.new(0,8,0,0)
            overlayCountLbl.BackgroundTransparency=1; overlayCountLbl.Text="TARGETS 0  (0 players)"
            overlayCountLbl.TextColor3=Color3.fromRGB(200,20,20); overlayCountLbl.TextSize=11
            overlayCountLbl.Font=Enum.Font.GothamBold; overlayCountLbl.TextXAlignment=Enum.TextXAlignment.Left
            overlayCountLbl.ZIndex=3; overlayCountLbl.Parent=titleBar
            local dragging=false; local dragOr=Vector2.zero; local frOr=Vector2.zero
            titleBar.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1 then
                    dragging=true; dragOr=Vector2.new(inp.Position.X,inp.Position.Y)
                    frOr=Vector2.new(overlayFrame.Position.X.Offset,overlayFrame.Position.Y.Offset)
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if dragging and overlayFrame and inp.UserInputType==Enum.UserInputType.MouseMovement then
                    local d=Vector2.new(inp.Position.X,inp.Position.Y)-dragOr
                    local sc2=Camera and Camera.ViewportSize or Vector2.new(800,600)
                    overlayFrame.Position=UDim2.fromOffset(
                        math.clamp(frOr.X+d.X,0,math.max(0,sc2.X-OL.W-4)),
                        math.clamp(frOr.Y+d.Y,0,math.max(0,sc2.Y-100)))
                    overlaySavedPos=Vector2.new(overlayFrame.Position.X.Offset,overlayFrame.Position.Y.Offset)
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
            end)
            local scroll=Instance.new("ScrollingFrame")
            scroll.Name="OvScroll"; scroll.Size=UDim2.new(1,-4,1,-OL.TITLE-2)
            scroll.Position=UDim2.new(0,2,0,OL.TITLE+1); scroll.BackgroundTransparency=1
            scroll.ScrollBarThickness=3; scroll.ScrollBarImageColor3=Color3.fromRGB(160,10,10)
            scroll.BorderSizePixel=0; scroll.ScrollingDirection=Enum.ScrollingDirection.Y
            scroll.ZIndex=2; scroll.Parent=overlayFrame
            local rl=Instance.new("UIListLayout")
            rl.Padding=UDim.new(0,3); rl.SortOrder=Enum.SortOrder.LayoutOrder; rl.Parent=scroll
           rl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                local contentH = rl.AbsoluteContentSize.Y + 6
                local screen2  = Camera and Camera.ViewportSize or Vector2.new(800, 600)
                -- Grow tall enough to fit all rows — cap only at screen bottom
                local maxH = screen2.Y - overlayFrame.AbsolutePosition.Y - 20
                local newH = math.max(math.min(OL.TITLE + contentH + 10, maxH), OL.TITLE + 40)
                overlayFrame.Size = UDim2.fromOffset(OL.W, newH)
                -- Canvas equals content, so scrollbar never appears when frame is large enough
                scroll.CanvasSize = UDim2.fromOffset(0, contentH)
            end)
            -- Refresh every 1 second
            local _lastRebuild=0
            overlayUpdateConn=RunService.Heartbeat:Connect(function()
                local now=tick()
                if now-_lastRebuild<1.0 then return end
                _lastRebuild=now; ovRebuild()
            end)
            ovRebuild()
        end

        startOverlayUpdates = function() end
        stopOverlayUpdates  = function() end
        resolveOverlay      = function() end
    end

    -- Settings
    Window:DrawCategory({Name="Settings"})
    local SettingsTab=Window:DrawTab({Name="Settings",Icon="settings-3",Type="Double"})
    local OffsetSection=SettingsTab:DrawSection({Name="Offsets",Position="left"})
    local ModeSection=SettingsTab:DrawSection({Name="Sweep Options",Position="right"})

    OffsetSection:AddSlider({Name="Offset X (sideways)",Min=-10,Max=10,Default=0,Round=1,Callback=function(v) Cfg.offsetX=v end})
    OffsetSection:AddSlider({Name="Offset Y (vertical)",Min=-10,Max=10,Default=0,Round=1,Callback=function(v) Cfg.offsetY=v end})
    OffsetSection:AddSlider({Name="Offset Z (depth)",Min=0,Max=15,Default=2,Round=1,Callback=function(v) Cfg.offsetZ=v end})
    OffsetSection:AddDropdown({Name="TP Mode",Values={"Under","Behind"},Default="Under",Callback=function(v) Cfg.tpMode=v=="Under" and "under" or "behind" end})
    OffsetSection:AddDropdown({Name="TP Method",Values={"Default","Smart"},Default="Default",Callback=function(v) Cfg.tpMethod=v=="Default" and "default" or "smart" end})
    OffsetSection:AddToggle({Name="Include NPCs",Default=true,Callback=function(s) Cfg.INCLUDE_NPCS=s end})

    ModeSection:AddDropdown({Name="Sweep Mode",Values={"Normal","Faster"},Default="Normal",Callback=function(v) Cfg.sweepMode=v=="Normal" and "normal" or "faster" end})
    ModeSection:AddDropdown({Name="TP Priority",Values={"Normal","HP %"},Default="Normal",Callback=function(v) Cfg.tpPriority=v=="Normal" and "normal" or "hppct" end})
    ModeSection:AddDropdown({Name="BF Mode",Values={"Blatant","Legit"},Default="Blatant",Callback=function(v) St.bfMode=v=="Blatant" and "blatant" or "legit" end})
    ModeSection:AddToggle({Name="No Domain TP",Default=false,Callback=function(s) St.noDomainTP=s end})
   ModeSection:AddToggle({Name="Sweep Overlay",Default=false,Callback=function(s)
        St.overlayEnabled=s
        if s then buildOverlay() else destroyOverlay() end
    end})
    ModeSection:AddSlider({Name="Respawn Wait (s)",Min=1,Max=5,Default=1,Round=1,Callback=function(v) Cfg.RESPAWN_WAIT=v end})
    ModeSection:AddSlider({Name="Stability Duration",Min=0,Max=2,Default=1,Round=2,Callback=function(v) Cfg.STABILITY_DURATION=v end})
   ModeSection:AddParagraph({Title="WARNING Fallen Parts Height",Content="Do not touch unless you know what you are doing! | Center (0) = NaN/disabled"})
    ModeSection:AddSlider({Name="Fallen Parts Height",Min=-500,Max=500,Default=-500,Round=0,Callback=function(v)
        if v == 0 then
            -- 0/0 = NaN behavior: set to actual NaN via math
            Cfg.fallenHeight = 0/0
            if St.sweepActive or St.attachActive then
                pcall(function() Workspace.FallenPartsDestroyHeight = 0/0 end)
            end
        else
            Cfg.fallenHeight = v
            if St.sweepActive or St.attachActive then
                Workspace.FallenPartsDestroyHeight = Cfg.fallenHeight
            end
        end
    end})
    ModeSection:AddToggle({Name="Dash Multiplier", Default=false, Callback=function(state)
        St.dashMultiplierEnabled=state
        if state then enableDashMultiplier(); notify("Dash Multiplier","Enabled.",3)
        else disableDashMultiplier(); notify("Dash Multiplier","Disabled.",3) end
    end})
    ModeSection:AddSlider({Name="Dash Multiplier Value", Min=0, Max=5, Default=1, Round=1,
        Callback=function(v)
            St.dashMultiplierValue=v
            if St.dashMultiplierEnabled then applyDashMultiplier(v) end
        end})
        

    -- Keybinds
    Window:DrawCategory({Name="Keybinds"})
    local KeybindTab=Window:DrawTab({Name="Keybinds",Icon="keyboard",Type="Single",EnableScrolling=true})
    local KeySection=KeybindTab:DrawSection({Name="Configure Keys"})
    KeySection:AddKeybind({Name="Sweep Key",Default="E",Callback=function(k) pcall(function() Keys.sweepKey=Enum.KeyCode[k] end) end})
    KeySection:AddKeybind({Name="Hunt Key",Default="Y",Callback=function(k) pcall(function() Keys.huntKey=Enum.KeyCode[k] end) end})
    KeySection:AddKeybind({Name="Auto BF Trigger Key",Default="Y",Callback=function(k) pcall(function() Keys.bfKey=Enum.KeyCode[k] end) end})
    KeySection:AddKeybind({Name="Stop Key",Default="H",Callback=function(k) pcall(function() Keys.stopKey=Enum.KeyCode[k] end) end})
    KeySection:AddKeybind({Name="Void Key",Default="V",Callback=function(k) pcall(function() Keys.voidKey=Enum.KeyCode[k] end) end})
    KeySection:AddKeybind({Name="Fly Key",Default="X",Callback=function(k) pcall(function() Keys.flyKey=Enum.KeyCode[k] end) end})
    KeySection:AddKeybind({Name="Yonk Key", Default="J", Callback=function(k) pcall(function() Keys.yonkKey=Enum.KeyCode[k] end) end})
    KeySection:AddKeybind({Name="Lock-On Key", Default="C", Callback=function(k)
        pcall(function() Keys.lockOnKey=Enum.KeyCode[k] end)
    end})
    KeySection:AddParagraph({Title="UI Toggle",Content="RightAlt = open/close GUI"})

    -- Extras
    Window:DrawCategory({Name="Extras"})
    local ExtrasTab=Window:DrawTab({Name="Extras",Icon="star",Type="Double"})
    local ExtrasLeft=ExtrasTab:DrawSection({Name="Combat Extras",Position="left"})
    local ExtrasRight=ExtrasTab:DrawSection({Name="Misc / Emotes",Position="right"})


    ExtrasLeft:AddToggle({Name="No Wallhop Cooldown",Default=false,Callback=function(state)
        if state then enableNoWallhopCooldown() else disableNoWallhopCooldown() end
    end})
    ExtrasLeft:AddToggle({Name="No Dash Cooldown",Default=false,Callback=function(state)
        if state then enableNoDashCooldown(); notify("No Dash Cooldown","Enabled.",3)
        else disableNoDashCooldown(); notify("No Dash Cooldown","Disabled.",3) end
    end})
    ExtrasLeft:AddToggle({Name="Invisible Block",Default=false,Callback=function(state)
        if state and not St.invisLoaded then St.invisLoaded=true
            task.spawn(function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/NotEnoughJack/LuaFluentDependancies/refs/heads/main/InvisibleBlock.lua"))() end) end)
            notify("Invis Block","Loaded.",3)
        end
    end})
    ExtrasLeft:AddToggle({Name="No Stun",Default=false,Callback=function(state)
        if state then
            local cm=Workspace:FindFirstChild("Characters")
            if not cm then notify("No Stun","workspace.Characters not found.",4); return end
            local stunNames={InSkill=true,NoJump=true,NoSprint=true,Block=true,Stun=true,Knockback=true,Wakeup=true,Hold=true}
            St.noStunConn=cm.DescendantAdded:Connect(function(d)
                if not stunNames[d.Name] then return end
                local myChar=LocalPlayer.Character; if not myChar then return end
                local parent=d.Parent
                while parent and parent~=cm do
                    if parent==myChar then task.wait(); pcall(function() d:Destroy() end); return end
                    parent=parent.Parent
                end
            end)
        else if St.noStunConn then St.noStunConn:Disconnect(); St.noStunConn=nil end end
    end})
    ExtrasLeft:AddToggle({Name="Shrink Hitbox",Default=false,Callback=function(state)
        St.shrinkHitboxActive=state
        if state then
            local char=LocalPlayer.Character
            if char then task.spawn(function() setupShrinkForChar(char) end) end
            Cn.shrinkCharConn=LocalPlayer.CharacterAdded:Connect(function(newChar)
                if St.shrinkHitboxActive then task.spawn(function() setupShrinkForChar(newChar) end) end
            end)
        else
            if Cn.shrinkCharConn then Cn.shrinkCharConn:Disconnect(); Cn.shrinkCharConn=nil end
            cleanupShrinkForChar(LocalPlayer.Character)
            for sc in pairs(St.shrinkDroneRefs) do cleanupShrinkForChar(sc) end
            for sc in pairs(St.shrinkAnimConns) do cleanupShrinkForChar(sc) end
        end
    end})
    ExtrasLeft:AddToggle({Name="Invisibility + Noclip",Default=false,Callback=function(state)
        St.invisActive=state
        if state then
            local char=LocalPlayer.Character
            if char then setupInvisForChar(char); startNoclip() end
            Cn.invisCharConn=LocalPlayer.CharacterAdded:Connect(function(newChar)
                if St.invisActive then task.spawn(function() setupInvisForChar(newChar); startNoclip() end) end
            end)
        else
            cleanupInvis(LocalPlayer.Character); stopNoclip()
            if Cn.invisCharConn then Cn.invisCharConn:Disconnect(); Cn.invisCharConn=nil end
        end
    end})

    ExtrasLeft:AddToggle({Name="No Knockback",Default=false,Callback=function(state)
        if state then
            getgenv().KnockBackForce=0
            local char=LocalPlayer.Character
            if char then
                local hrp=char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.ChildAdded:Connect(function(child)
                        if child.Name=="KnockbackForce" and child:IsA("BodyVelocity") then
                            child.Velocity=Vector3.new(0,0,0)
                        end
                    end)
                end
            end
            LocalPlayer.CharacterAdded:Connect(function(character)
                if not getgenv().KnockBackForce or getgenv().KnockBackForce~=0 then return end
                local hrp=character:WaitForChild("HumanoidRootPart")
                hrp.ChildAdded:Connect(function(child)
                    if child.Name=="KnockbackForce" and child:IsA("BodyVelocity") then
                        child.Velocity=Vector3.new(0,0,0)
                    end
                end)
            end)
            notify("No Knockback","Enabled.",3)
        else
            getgenv().KnockBackForce=nil
            notify("No Knockback","Disabled. Rejoin for full effect.",3)
        end
    end})
    
    ExtrasLeft:AddButton({Name="Yonk", Callback=function() yonkToggle() end})
    ExtrasLeft:AddSlider({Name="Yonk Speed", Min=0.1, Max=2, Default=1, Round=2,
        Callback=function(v)
            St.yonkSpeed=v
            if St.yonkAnimTrack then
                pcall(function() St.yonkAnimTrack:AdjustSpeed(v) end)
            end
        end})
    ExtrasLeft:AddToggle({Name="Auto Hiromi QTE", Default=false, Callback=function(state)
        St.hiromiEnabled=state
        if state then hiromiStart(); notify("Auto Hiromi QTE","Enabled.",3)
        else hiromiStop(); notify("Auto Hiromi QTE","Disabled.",2) end
    end})
    ExtrasLeft:AddSlider({Name="QTE Speed (ms)", Min=1, Max=220, Default=120, Round=0,
        Callback=function(v)
            -- Lower = faster reaction. Min=1ms (instant), Max=220ms (human speed)
            St.hiromiMinMs=math.max(1, v-50)
            St.hiromiMaxMs=v
        end})

Window:DrawCategory({Name="Characters"})
local CharactersTab=Window:DrawTab({Name="Characters",Icon="user",Type="Double"})
local CharLeft =CharactersTab:DrawSection({Name="Yuki / Yuji / Nanami",Position="left"})
local CharRight=CharactersTab:DrawSection({Name="Yuta / Higuruma",      Position="right"})

-- YUKI
CharLeft:AddParagraph({Title="Yuki",Content="Instant Blackhole"})
CharLeft:AddButton({Name="Instant Blackhole",Callback=function()
    if not St.instantBHLoaded then St.instantBHLoaded=true
        task.spawn(function() pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Dragonfly5101/Minosr/refs/heads/main/InstantBlackHole.JJS"))()
        end) end); notify("Instant Blackhole","Script loaded.",3)
    else notify("Instant Blackhole","Already loaded.",3) end
end})

-- YUJI
CharLeft:AddParagraph({Title="Yuji",Content="Divergent Fist / Black Flash"})
local BFToggleDT2=CharLeft:AddToggle({Name="Auto Black Flash",Default=false,Callback=function(state)
    if state then St.bfEnabled=true; bfStartAll(); notify("Auto BF","Enabled. Press "..Keys.bfKey.Name.." to trigger.",3)
    else bfStopAll(); notify("Auto BF","Disabled.",2) end
end})
BFToggleDT2.Link:AddHelper({Text="bf chain"})
local BFOpt2=BFToggleDT2.Link:AddOption()
BFOpt2:AddSlider({Name="Glide Speed",    Min=0.05,Max=1.0, Default=0.25,Round=3,Callback=function(v) Cfg.BF.Duration=v end})
BFOpt2:AddSlider({Name="Land Dist",      Min=1,   Max=10,  Default=3,   Round=1,Callback=function(v) Cfg.BF.Radius=v end})
BFOpt2:AddSlider({Name="Detect Range",   Min=10,  Max=50,  Default=25,  Round=0,Callback=function(v) Cfg.BF.Range=v end})
BFOpt2:AddSlider({Name="Curve Width",    Min=0,   Max=30,  Default=14,  Round=0,Callback=function(v) Cfg.BF.CurveStrength=v end})
BFOpt2:AddSlider({Name="Prediction",     Min=0,   Max=2.0, Default=0.6, Round=2,Callback=function(v) Cfg.BF.PredictionMultiplier=v end})
BFOpt2:AddSlider({Name="Ping Delay (s)", Min=0,   Max=0.5, Default=0.12,Round=3,Callback=function(v) St.bfPingDelay=v end})
BFOpt2:AddSlider({Name="Landing Linger", Min=0,   Max=1.0, Default=0.2, Round=2,Callback=function(v) Cfg.BF.LandingLinger=v end})
BFOpt2:AddSlider({Name="Back Angle (dot)",  Min=0,   Max=1.0, Default=0.5, Round=2,
        Callback=function(v) Cfg.BF.BackAngleDot=v end})
    BFOpt2:AddSlider({Name="Behind Dist Extra", Min=0,   Max=10,  Default=4,   Round=1,
        Callback=function(v) Cfg.BF.BehindDist=v end})
    BFOpt2:AddSlider({Name="Facing Threshold",  Min=0,   Max=1.0, Default=0.3, Round=2,
        Callback=function(v) Cfg.BF.FacingDot=v end})
    BFOpt2:AddSlider({Name="Curve Tightness",   Min=0.1, Max=1.5, Default=0.6, Round=2,
        Callback=function(v) Cfg.BF.GlideCurveK=v end})

-- NANAMI
CharLeft:AddParagraph({Title="Nanami",Content="take this Ratio"})
CharLeft:AddToggle({Name="Auto Ratio",Default=false,Callback=function(state)
    if state then enableAutoRatio(); notify("Auto Ratio","Enabled.",3)
    else disableAutoRatio(); notify("Auto Ratio","Disabled.",2) end
end})

-- YUTA
CharRight:AddParagraph({Title="Yuta",Content="Yuta BF / Resolute Slash"})
CharRight:AddButton({Name="Yuta BF Oneshot",Callback=function()
    if not St.yutaBFLoaded then St.yutaBFLoaded=true
        task.spawn(function() pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Lazzexaa/gugugaga/refs/heads/main/yutabf.txt"))()
        end) end); notify("Yuta BF Oneshot","Script loaded.",3)
    else notify("Yuta BF Oneshot","Already loaded.",3) end
end})
local yutaListC={}
for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then table.insert(yutaListC,p.Name) end end
local YutaDropC=CharRight:AddDropdown({
    Name="Yuta BF Target",
    Values=#yutaListC>0 and yutaListC or {"(none)"},
    Default=1,
    Callback=function(v)
        if v=="(none)" then St.kokusenSelectedTarget=""; return end
        St.kokusenSelectedTarget=v
    end,
})
CharRight:AddButton({Name="Refresh Yuta BF List",Callback=function()
    local list={}
    for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then table.insert(list,p.Name) end end
    if #list==0 then list={"(none)"} end
    YutaDropC:SetValues(list); notify("Yuta BF","List refreshed.",2)
end})
CharRight:AddButton({Name="Execute Yuta BF",Callback=function()
    task.spawn(kokusenExecute)
end})

-- HIGURUMA
CharRight:AddParagraph({Title="Higuruma",Content="Vote viewer"})
CharRight:AddButton({Name="Higurama Vote Viewer",Callback=function()
    task.spawn(function() pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Dragonfly5101/Minosr/refs/heads/main/HigarumaVoteView.JJS"))()
    end) end)
    notify("Higurama Vote Viewer","Loaded.",3)
end})

    -- ExtrasRight: Yuta BF + Emotes + Hitbox + Emotes
    ExtrasRight:AddButton({Name="Unlock Emotes",Callback=function()
        if not St.emotesLoaded then St.emotesLoaded=true
            task.spawn(function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/SairyTheKing/emoteunlocktypashit/refs/heads/main/emote.lua"))() end) end)
            notify("Emotes","Unlock script fired.",3)
        else notify("Emotes","Already loaded.",3) end
    end})

    -- Emote dropdown desktop
    ExtrasRight:AddParagraph({Title="Emotes",Content="Select emote and bind a key"})
    local desktopEmoteNames=getEmoteNames()
    ExtrasRight:AddDropdown({
        Name="Select Emote",Values=desktopEmoteNames,Default=1,
        Callback=function(v) setEmoteIndex(v) end,
    })
    ExtrasRight:AddDropdown({
        Name="Emote Keybind",Values={"C","X","Z","G","J","N","M","B"},Default="C",
        Callback=function(v)
            local km={C=Enum.KeyCode.C,X=Enum.KeyCode.X,Z=Enum.KeyCode.Z,G=Enum.KeyCode.G,
                J=Enum.KeyCode.J,N=Enum.KeyCode.N,M=Enum.KeyCode.M,B=Enum.KeyCode.B}
            local kc=km[v]; if kc then setEmoteKeybind(kc) end
            notify("Emotes","Keybind set to "..v,2)
        end,
    })
    ExtrasRight:AddButton({Name="Fire Emote Now",Callback=function() fireSelectedEmote() end})
    task.spawn(function() setEmoteKeybind(Enum.KeyCode.C) end)

    -- Tools: Targets
    Window:DrawCategory({Name="Tools"})
    local TargetTab=Window:DrawTab({Name="Targets",Icon="target",Type="Single",EnableScrolling=true})
    local TargetSection=TargetTab:DrawSection({Name="Target Select"})
    local selectedTargetName=nil

    local targetListGui=Instance.new("ScreenGui")
    targetListGui.Name="GojoTargetList"; targetListGui.ResetOnSpawn=false
    targetListGui.DisplayOrder=998; targetListGui.IgnoreGuiInset=true
    targetListGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    targetListGui.Enabled=false; targetListGui.Parent=LocalPlayer:WaitForChild("PlayerGui")

    local targetListPanel=Instance.new("Frame")
    targetListPanel.Size=UDim2.fromOffset(220,300); targetListPanel.Position=UDim2.fromOffset(14,300)
    targetListPanel.BackgroundColor3=Color3.fromRGB(10,4,4); targetListPanel.BorderSizePixel=0
    targetListPanel.ClipsDescendants=true; targetListPanel.Active=true; targetListPanel.Parent=targetListGui
    Instance.new("UICorner",targetListPanel).CornerRadius=UDim.new(0,12)
    makeStroke(targetListPanel,Color3.fromRGB(80,140,255),1.5,0.2)

    local tlHeader=Instance.new("Frame")
    tlHeader.Size=UDim2.new(1,0,0,32); tlHeader.BackgroundColor3=Color3.fromRGB(8,15,40)
    tlHeader.BorderSizePixel=0; tlHeader.ZIndex=2; tlHeader.Parent=targetListPanel
    local tlHeaderLbl=Instance.new("TextLabel")
    tlHeaderLbl.Size=UDim2.new(1,-8,1,0); tlHeaderLbl.Position=UDim2.new(0,8,0,0)
    tlHeaderLbl.BackgroundTransparency=1; tlHeaderLbl.Text="TARGET SELECT (WL BUTTON = WHITELIST)"
    tlHeaderLbl.TextColor3=Color3.fromRGB(80,140,255); tlHeaderLbl.TextSize=12
    tlHeaderLbl.Font=Enum.Font.GothamBold; tlHeaderLbl.TextXAlignment=Enum.TextXAlignment.Left
    tlHeaderLbl.ZIndex=3; tlHeaderLbl.Parent=tlHeader

    local selectedLbl=Instance.new("TextLabel")
    selectedLbl.Size=UDim2.new(1,-8,0,16); selectedLbl.Position=UDim2.new(0,8,0,34)
    selectedLbl.BackgroundTransparency=1; selectedLbl.Text="Selected: none"
    selectedLbl.TextColor3=Color3.fromRGB(140,80,80); selectedLbl.TextSize=9
    selectedLbl.Font=Enum.Font.GothamBold; selectedLbl.TextXAlignment=Enum.TextXAlignment.Left
    selectedLbl.ZIndex=2; selectedLbl.Parent=targetListPanel

    local tlScroll=Instance.new("ScrollingFrame")
    tlScroll.Size=UDim2.new(1,-8,1,-100); tlScroll.Position=UDim2.new(0,4,0,54)
    tlScroll.BackgroundTransparency=1; tlScroll.ScrollBarThickness=3
    tlScroll.ScrollBarImageColor3=Color3.fromRGB(80,140,255); tlScroll.BorderSizePixel=0
    tlScroll.ScrollingDirection=Enum.ScrollingDirection.Y; tlScroll.ZIndex=2; tlScroll.Parent=targetListPanel
    local tlLayout=Instance.new("UIListLayout")
    tlLayout.Padding=UDim.new(0,4); tlLayout.SortOrder=Enum.SortOrder.LayoutOrder; tlLayout.Parent=tlScroll
    tlLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tlScroll.CanvasSize=UDim2.fromOffset(0,tlLayout.AbsoluteContentSize.Y+8)
    end)

    local attachPanelBtn=Instance.new("TextButton")
    attachPanelBtn.Size=UDim2.new(1,-16,0,34); attachPanelBtn.Position=UDim2.new(0,8,1,-44)
    attachPanelBtn.BackgroundColor3=Color3.fromRGB(10,30,10); attachPanelBtn.BorderSizePixel=0
    attachPanelBtn.Text="Attach"; attachPanelBtn.TextColor3=Color3.fromRGB(80,220,100)
    attachPanelBtn.TextSize=12; attachPanelBtn.Font=Enum.Font.GothamBold
    attachPanelBtn.ZIndex=3; attachPanelBtn.Parent=targetListPanel
    Instance.new("UICorner",attachPanelBtn).CornerRadius=UDim.new(0,8)

    local tlDragging=false; local tlDragOrigin=Vector2.zero; local tlFrameOrigin=Vector2.zero
    tlHeader.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            tlDragging=true
            tlDragOrigin=Vector2.new(inp.Position.X,inp.Position.Y)
            tlFrameOrigin=Vector2.new(targetListPanel.Position.X.Offset,targetListPanel.Position.Y.Offset)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if tlDragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=Vector2.new(inp.Position.X,inp.Position.Y)-tlDragOrigin
            targetListPanel.Position=UDim2.fromOffset(tlFrameOrigin.X+d.X,tlFrameOrigin.Y+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then tlDragging=false end
    end)

    local function refreshTargetList()
        for _,ch in ipairs(tlScroll:GetChildren()) do if not ch:IsA("UIListLayout") then ch:Destroy() end end
        selectedTargetName=nil; selectedLbl.Text="Selected: none"
        local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local targets=myHRP and getValidTargets(myHRP) or {}
        local combined={}
        for _,tgt in ipairs(targets) do
            if Players:FindFirstChild(tgt.name) then table.insert(combined,1,tgt) else table.insert(combined,tgt) end
        end
        if #combined==0 then
            local noTgt=Instance.new("TextLabel"); noTgt.Size=UDim2.new(1,-8,0,28); noTgt.BackgroundTransparency=1
            noTgt.Text="No targets found"; noTgt.TextColor3=Color3.fromRGB(140,80,80); noTgt.TextSize=9
            noTgt.Font=Enum.Font.Gotham; noTgt.ZIndex=3; noTgt.LayoutOrder=1; noTgt.Parent=tlScroll; return
        end
        for i,tgt in ipairs(combined) do
            local capturedTgt=tgt; local isPlayer=Players:FindFirstChild(tgt.name)~=nil
            local row=Instance.new("Frame"); row.Size=UDim2.new(1,-8,0,30)
            row.BackgroundColor3=isPlayer and Color3.fromRGB(14,4,4) or Color3.fromRGB(4,10,4)
            row.BorderSizePixel=0; row.LayoutOrder=i; row.ZIndex=3; row.Parent=tlScroll
            Instance.new("UICorner",row).CornerRadius=UDim.new(0,7)
            makeStroke(row,isPlayer and Color3.fromRGB(80,140,255) or Color3.fromRGB(80,200,80),1,0.7)
            local rowLbl=Instance.new("TextLabel")
            rowLbl.Size=UDim2.new(1,-8,1,0); rowLbl.Position=UDim2.new(0,6,0,0); rowLbl.BackgroundTransparency=1
            rowLbl.Text=(isPlayer and "[P] " or "[N] ")..tgt.name; rowLbl.TextColor3=Color3.fromRGB(230,200,200)
            rowLbl.TextSize=10; rowLbl.Font=Enum.Font.GothamBold; rowLbl.TextXAlignment=Enum.TextXAlignment.Left
            rowLbl.ZIndex=4; rowLbl.Parent=row
            local hitBtn=Instance.new("TextButton"); hitBtn.Size=UDim2.new(1,0,1,0); hitBtn.BackgroundTransparency=1
            hitBtn.Text=""; hitBtn.ZIndex=5; hitBtn.Parent=row
            local rowStroke=row:FindFirstChildOfClass("UIStroke")
         -- WL button: click to toggle whitelist
            local wlBtn=Instance.new("TextButton")
            wlBtn.Size=UDim2.new(0,26,0,20); wlBtn.Position=UDim2.new(1,-30,0.5,-10)
            wlBtn.BackgroundColor3=St.whitelist[capturedTgt.name] and Color3.fromRGB(40,40,6) or Color3.fromRGB(18,18,4)
            wlBtn.BorderSizePixel=0; wlBtn.Text="WL"
            wlBtn.TextColor3=St.whitelist[capturedTgt.name] and Color3.fromRGB(200,200,60) or Color3.fromRGB(120,120,40)
            wlBtn.TextSize=8; wlBtn.Font=Enum.Font.GothamBold; wlBtn.ZIndex=6; wlBtn.Parent=row
            Instance.new("UICorner",wlBtn).CornerRadius=UDim.new(0,4)
            wlBtn.MouseButton1Click:Connect(function()
                local tname=capturedTgt.name
                if St.whitelist[tname] then
                    St.whitelist[tname]=nil
                    wlBtn.BackgroundColor3=Color3.fromRGB(18,18,4); wlBtn.TextColor3=Color3.fromRGB(120,120,40)
                    notify("Whitelist","Removed: "..tname,2)
                else
                    St.whitelist[tname]=true
                    wlBtn.BackgroundColor3=Color3.fromRGB(40,40,6); wlBtn.TextColor3=Color3.fromRGB(200,200,60)
                    notify("Whitelist","Added: "..tname,2)
                end
            end)
            -- Row click = select for attach
            hitBtn.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                    for _,ch in ipairs(tlScroll:GetChildren()) do
                        if ch:IsA("Frame") then
                            local s2=ch:FindFirstChildOfClass("UIStroke"); local l2=ch:FindFirstChildOfClass("TextLabel")
                            local isP2=l2 and (l2.Text:sub(1,3)=="[P]")
                            if s2 and l2 then
                                s2.Color=isP2 and Color3.fromRGB(80,140,255) or Color3.fromRGB(80,200,80)
                                s2.Transparency=0.7; l2.TextColor3=Color3.fromRGB(230,200,200)
                            end
                        end
                    end
                    selectedTargetName=capturedTgt.name
                    selectedLbl.Text="Selected: "..(isPlayer and "[P] " or "[N] ")..capturedTgt.name
                    if rowStroke then rowStroke.Color=Color3.fromRGB(80,220,100); rowStroke.Transparency=0.2 end
                    rowLbl.TextColor3=Color3.fromRGB(80,220,100)
                    attachPanelBtn.Text=St.attachActive and St.attachTarget and St.attachTarget.name==capturedTgt.name
                        and "Detach from "..capturedTgt.name or "Attach to "..capturedTgt.name
                end
            end)
        end
    end

    attachPanelBtn.MouseButton1Click:Connect(function()
        local name=selectedTargetName or (St.attachActive and St.attachTarget and St.attachTarget.name)
        if not name then notify("Attach","Select a target first.",3); return end
        if St.attachActive and St.attachTarget and St.attachTarget.name==name then
            local n=St.attachTarget.name; stopAttach()
            attachPanelBtn.Text="Attach"; attachPanelBtn.TextColor3=Color3.fromRGB(80,220,100)
            notify("Detached","Detached from "..n,3); setStatus("Idle"); return
        end
        local myChar=LocalPlayer.Character; local myHRP=myChar and myChar:FindFirstChild("HumanoidRootPart")
        local allTgts=myHRP and getValidTargets(myHRP) or {}; local liveTarget
        for _,t in ipairs(allTgts) do if t.name==name then liveTarget=t; break end end
        if not liveTarget then notify("Attach","Target not in range/alive.",3); return end
        startAttach(liveTarget)
        attachPanelBtn.Text="Detach from "..name; attachPanelBtn.TextColor3=Color3.fromRGB(200,50,50)
        notify("Attached","Locked onto "..name,3); setStatus("ATTACHED: "..name)
    end)

    TargetSection:AddButton({Name="Open / Refresh Target List",Callback=function() refreshTargetList(); targetListGui.Enabled=true end})
    TargetSection:AddButton({Name="Close Target List",Callback=function() targetListGui.Enabled=false end})
    TargetSection:AddButton({Name="Detach",Callback=function()
        if St.attachActive then
            local n=St.attachTarget and St.attachTarget.name or "target"
            stopAttach(); notify("Detached","Detached from "..n,3); setStatus("Idle")
        end
    end})
    TargetSection:AddButton({Name="Clear Whitelist",Callback=function()
        St.whitelist={}; notify("Whitelist","Cleared.",2)
    end})

    -- Tools: Items
    local ItemsTab=Window:DrawTab({Name="Items",Icon="package",Type="Single",EnableScrolling=true})
    local ItemsSection=ItemsTab:DrawSection({Name="Item Grabber"})
    local itemsGui=Instance.new("ScreenGui"); itemsGui.Name="GojoItemsList"; itemsGui.ResetOnSpawn=false
    itemsGui.DisplayOrder=997; itemsGui.IgnoreGuiInset=true; itemsGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    itemsGui.Enabled=false; itemsGui.Parent=LocalPlayer:WaitForChild("PlayerGui")
    local itemsPanel=Instance.new("Frame")
    itemsPanel.Size=UDim2.fromOffset(220,300); itemsPanel.Position=UDim2.fromOffset(250,300)
    itemsPanel.BackgroundColor3=Color3.fromRGB(10,6,2); itemsPanel.BorderSizePixel=0
    itemsPanel.ClipsDescendants=true; itemsPanel.Active=true; itemsPanel.Parent=itemsGui
    Instance.new("UICorner",itemsPanel).CornerRadius=UDim.new(0,12)
    makeStroke(itemsPanel,Color3.fromRGB(255,140,40),1.5,0.2)
    local ipHeader=Instance.new("Frame")
    ipHeader.Size=UDim2.new(1,0,0,32); ipHeader.BackgroundColor3=Color3.fromRGB(22,10,2)
    ipHeader.BorderSizePixel=0; ipHeader.ZIndex=2; ipHeader.Parent=itemsPanel
    local ipHeaderLbl=Instance.new("TextLabel")
    ipHeaderLbl.Size=UDim2.new(1,-8,1,0); ipHeaderLbl.Position=UDim2.new(0,8,0,0)
    ipHeaderLbl.BackgroundTransparency=1; ipHeaderLbl.Text="ITEMS"
    ipHeaderLbl.TextColor3=Color3.fromRGB(255,140,40); ipHeaderLbl.TextSize=13
    ipHeaderLbl.Font=Enum.Font.GothamBold; ipHeaderLbl.TextXAlignment=Enum.TextXAlignment.Left
    ipHeaderLbl.ZIndex=3; ipHeaderLbl.Parent=ipHeader
    local ipScroll=Instance.new("ScrollingFrame")
    ipScroll.Size=UDim2.new(1,-8,1,-40); ipScroll.Position=UDim2.new(0,4,0,36)
    ipScroll.BackgroundTransparency=1; ipScroll.ScrollBarThickness=3
    ipScroll.ScrollBarImageColor3=Color3.fromRGB(255,140,40); ipScroll.BorderSizePixel=0
    ipScroll.ScrollingDirection=Enum.ScrollingDirection.Y; ipScroll.ZIndex=2; ipScroll.Parent=itemsPanel
    local ipLayout=Instance.new("UIListLayout")
    ipLayout.Padding=UDim.new(0,5); ipLayout.SortOrder=Enum.SortOrder.LayoutOrder; ipLayout.Parent=ipScroll
    ipLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ipScroll.CanvasSize=UDim2.fromOffset(0,ipLayout.AbsoluteContentSize.Y+8)
    end)
    local ipDragging=false; local ipDragOrigin=Vector2.zero; local ipFrameOrigin=Vector2.zero
    ipHeader.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            ipDragging=true; ipDragOrigin=Vector2.new(inp.Position.X,inp.Position.Y)
            ipFrameOrigin=Vector2.new(itemsPanel.Position.X.Offset,itemsPanel.Position.Y.Offset)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if ipDragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=Vector2.new(inp.Position.X,inp.Position.Y)-ipDragOrigin
            itemsPanel.Position=UDim2.fromOffset(ipFrameOrigin.X+d.X,ipFrameOrigin.Y+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then ipDragging=false end
    end)

    local function buildItemsList()
        for _,ch in ipairs(ipScroll:GetChildren()) do if not ch:IsA("UIListLayout") then ch:Destroy() end end
        local items=getItemsList()
        if #items==0 then
            local noItem=Instance.new("TextLabel"); noItem.Size=UDim2.new(1,-8,0,30); noItem.BackgroundTransparency=1
            noItem.Text="No items found"; noItem.TextColor3=Color3.fromRGB(140,80,80)
            noItem.TextSize=9; noItem.Font=Enum.Font.Gotham; noItem.ZIndex=3; noItem.LayoutOrder=1; noItem.Parent=ipScroll; return
        end
        for i,item in ipairs(items) do
            local capturedItem=item
            local row=Instance.new("Frame"); row.Size=UDim2.new(1,-8,0,34)
            row.BackgroundColor3=Color3.fromRGB(20,10,2); row.BorderSizePixel=0
            row.LayoutOrder=i; row.ZIndex=3; row.Parent=ipScroll
            Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
            makeStroke(row,Color3.fromRGB(255,140,40),1,0.6)
            local rowLbl=Instance.new("TextLabel")
            rowLbl.Size=UDim2.new(1,-12,1,0); rowLbl.Position=UDim2.new(0,8,0,0); rowLbl.BackgroundTransparency=1
            rowLbl.Text="[Item] "..item.name; rowLbl.TextColor3=Color3.fromRGB(230,200,200)
            rowLbl.TextSize=10; rowLbl.Font=Enum.Font.GothamBold; rowLbl.TextXAlignment=Enum.TextXAlignment.Left
            rowLbl.ZIndex=4; rowLbl.Parent=row
            local rowStroke=row:FindFirstChildOfClass("UIStroke"); local grabRunning=false
            local hitBtn=Instance.new("TextButton"); hitBtn.Size=UDim2.new(1,0,1,0)
            hitBtn.BackgroundTransparency=1; hitBtn.Text=""; hitBtn.ZIndex=5; hitBtn.Parent=row
            hitBtn.InputBegan:Connect(function(inp)
                if inp.UserInputType~=Enum.UserInputType.MouseButton1 and inp.UserInputType~=Enum.UserInputType.Touch then return end
                if grabRunning then return end; grabRunning=true; rowLbl.TextColor3=Color3.fromRGB(255,140,40)
                if rowStroke then rowStroke.Transparency=0.2 end
                task.spawn(function()
                    grabItem(capturedItem.part,function(success)
                        grabRunning=false
                        if success then rowLbl.TextColor3=Color3.fromRGB(80,220,100); if rowStroke then rowStroke.Color=Color3.fromRGB(80,220,100) end
                        else rowLbl.TextColor3=Color3.fromRGB(200,50,50) end
                        task.delay(2,function()
                            if rowLbl and rowLbl.Parent then rowLbl.TextColor3=Color3.fromRGB(230,200,200)
                                if rowStroke then rowStroke.Color=Color3.fromRGB(255,140,40); rowStroke.Transparency=0.6 end end
                        end)
                    end)
                end)
            end)
        end
    end

    ItemsSection:AddButton({Name="Open / Refresh Items",Callback=function() buildItemsList(); itemsGui.Enabled=true end})
    ItemsSection:AddButton({Name="Close Items",Callback=function() itemsGui.Enabled=false end})
      task.spawn(function()
        local _lastItemCount=0
        while true do task.wait(0.5)
            if itemsGui.Enabled then
                local current=getItemsList()
                if #current~=_lastItemCount then _lastItemCount=#current; buildItemsList() end
            end
        end
    end)

    -- Keybind handler
    UserInputService.InputBegan:Connect(function(inp, processed)
        if processed then return end
        if inp.UserInputType~=Enum.UserInputType.Keyboard then return end
        if _hiromiFiring then return end
        if inp.KeyCode==Keys.sweepKey then
            local newState=not St.sweepActive; setSweepToggle(newState)
            if newState then Workspace.FallenPartsDestroyHeight=Cfg.fallenHeight; task.spawn(runSweep)
            else Workspace.FallenPartsDestroyHeight=St.originalFallenHeight; setStatus("Idle") end
        elseif inp.KeyCode==Keys.bfKey then
            if St.bfEnabled then task.spawn(bfTriggerDash) end
        elseif inp.KeyCode==Keys.huntKey then
            if not St.bfEnabled then
                if St.luckyCycleFound then notify("Lucky Cycle!","Press E to sweep. H to reset.",5); return end
                if not St.huntRunning then task.spawn(runHunt) end
            end
        elseif inp.KeyCode==Keys.stopKey then
            setSweepToggle(false); stopAll()
        elseif inp.KeyCode==Keys.voidKey then
            if St.luckyCycleFound then notify("Lucky Cycle!","Press Stop to clear first.",4)
            else setStatus("Voiding..."); voidResetFallback()
                task.spawn(function() waitForDeathAndRespawn(); setStatus("Idle") end) end
        elseif inp.KeyCode==Keys.flyKey then
            if St.flyToggleOn then
                toggleFly()
                pcall(function() FlyToggleDT:Set(St.flyActive) end)
            end
           elseif inp.KeyCode == Keys.lockOnKey then
            if not _hiromiFiring and St.lockOnToggleOn then toggleLockOn() end
            elseif inp.KeyCode==Keys.yonkKey then
            yonkToggle()
        end
    end)

   UserInputService.InputBegan:Connect(function(inp, processed)
        if processed then return end
        if inp.UserInputType~=Enum.UserInputType.Keyboard then return end
        local key=inp.KeyCode
        if     key==Enum.KeyCode.W           then flyKeys.W=true
        elseif key==Enum.KeyCode.A           then flyKeys.A=true
        elseif key==Enum.KeyCode.S           then flyKeys.S=true
        elseif key==Enum.KeyCode.D           then flyKeys.D=true
        elseif key==Enum.KeyCode.Space       then flyKeys.Up=true
        elseif key==Enum.KeyCode.LeftControl then flyKeys.Down=true
        elseif key==Enum.KeyCode.LeftShift   then flyKeys.Boost=true end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        local key=inp.KeyCode
        if     key==Enum.KeyCode.W           then flyKeys.W=false
        elseif key==Enum.KeyCode.A           then flyKeys.A=false
        elseif key==Enum.KeyCode.S           then flyKeys.S=false
        elseif key==Enum.KeyCode.D           then flyKeys.D=false
        elseif key==Enum.KeyCode.Space       then flyKeys.Up=false
        elseif key==Enum.KeyCode.LeftControl then flyKeys.Down=false
        elseif key==Enum.KeyCode.LeftShift   then flyKeys.Boost=false end
    end)

local _origRunSweepDT=runSweep
    runSweep=function()
        local myChar=LocalPlayer.Character; local myHRP=myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myChar or not myHRP then St.sweepActive=false; return end
        _origRunSweepDT()
    end
end -- end if not mobile

print("[V32] Loaded")
if mobile then print("[V32] Mobile — Fluent UI active")
else print("[V32] Desktop — E=Sweep | Y=Hunt/BF | H=Stop | V=Void | X=Fly | RightAlt=UI")
end
