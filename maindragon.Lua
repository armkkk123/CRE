-- [[ 🛡️ RUAJAD HUB V1.0: THE DEFINITIVE INTEGRATION ]]
local Players   = game:GetService("Players")
local LP        = Players.LocalPlayer
local Lighting  = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local oldNamecall

task.spawn(function()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    settings().Rendering.QualityLevel = 1
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") then
            v.Enabled = false
        end
    end
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsParentOf(LP.Character) then
            v.Material    = Enum.Material.SmoothPlastic
            v.CastShadow  = false
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 0.5
        end
    end
end)

task.spawn(function()
    while task.wait(60) do collectgarbage("collect") end
end)

print("🚀 [Arm Hub Boost]: FPS Boost Enabled!")

-- ============================================================
-- [[ Services & Libraries ]]
-- ============================================================
local Rayfield          = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser       = game:GetService("VirtualUser")
local vim               = game:GetService("VirtualInputManager")
local LocalPlayer       = Players.LocalPlayer

local function rndWait(min, max)
    task.wait(min + math.random() * (max - min))
end

-- [[ CORE FUNCTIONS ]]
local function safeTrigger(remote, ...)
    if not remote then return end
    local success, err = pcall(function(...)
        if remote:IsA("RemoteEvent") then
            remote:FireServer(...)
        elseif remote:IsA("RemoteFunction") then
            remote:InvokeServer(...)
        end
    end, ...)
    return success
end

local function SmartBuy(itemName, amount)
    local remote = ReplicatedStorage:WaitForChild("Remotes", 5):WaitForChild("PurchaseItemRemote", 5)
    if not remote then return end
    local args = {[1] = {["Amount"] = amount or 1, ["ItemName"] = itemName}}
    local success, err = pcall(function() remote:FireServer(unpack(args)) end)
    if success then
        Rayfield:Notify({Title = "SUCCESS", Content = "Purchased: " .. itemName .. " x" .. (amount or 1), Duration = 2})
    else
        warn("Purchase Error: " .. tostring(err))
        Rayfield:Notify({Title = "ERROR", Content = "Purchase Failed!", Duration = 3})
    end
end

-- ============================================================
-- DRAGON SYSTEM
-- ============================================================
local function getActiveDragonID()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Dragons") then
        local dragon = char.Dragons:GetChildren()[1]
        if dragon then return dragon.Name end
    end
    return "5"
end

local function getActiveDragonModel()
    local char = workspace:FindFirstChild("Characters")
        and workspace.Characters:FindFirstChild(LocalPlayer.Name)
    if char and char:FindFirstChild("Dragons") then
        return char.Dragons:FindFirstChild("1") or char.Dragons:GetChildren()[1]
    end
    local c = LocalPlayer.Character
    if c and c:FindFirstChild("Dragons") then
        return c.Dragons:GetChildren()[1]
    end
    return nil
end

-- FOOD SYSTEM
local VALID_FOODS = {
    "Apple", "Corn", "Bacon", "Lemon", "Pear",
    "Pineapple", "Strawberry", "Mango", "Carrot", "Potato", "Onion", "Pumpkin"
}

local function getAvailableFood()
    local p = game.Players.LocalPlayer
    if p and p:FindFirstChild("Data") and p.Data:FindFirstChild("Resources") then
        for _, foodName in ipairs(VALID_FOODS) do
            local foodItem = p.Data.Resources:FindFirstChild(foodName)
            if foodItem and foodItem.Value > 0 then return foodName, foodItem end
        end
    end
    return nil, nil
end

-- ============================================================
-- [[ Global Variables ]]
-- ============================================================
_G.AutoFarmFood    = false
_G.AutoFarmOre     = false
_G.AutoFarmBone    = false
_G.AutoCollect     = true
_G.AutoFeed        = false
_G.MinHunger       = 35
_G.FlySpeed        = 280
_G.HitboxSize      = Vector3.new(15, 15, 15)
_G.IgnoreCooldown  = 8
_G.MasterFarm      = false
_G.SpeedPower      = 20
_G.EnableSpeedHack = false
_G.WarpDistance    = 280
_G.AutoBond        = false
_G.Noclip          = false
_G.AutoCollectEgg  = false
_G.MonsterFarmRunning = false
_G.SelectedMonsters   = {}
_G.MonsterFlySpeed     = 280
_G.MonsterWarpDist    = 100

_G.AutoFarm        = false
_G.FarmValentines  = false
_G.FarmSilver      = false
_G.FarmBronze      = false
_G.FarmGold        = false
_G.AutoFish        = false
_G.ChestFlySpeed   = 200
_G.DragonHeight    = 15

local eggThread          = nil
local eggStickConnection = nil
local bv                 = nil
local masterThread       = nil
local ignoreList         = {}
local currentTween       = nil
local LootedInstances    = {}
local farmThread         = nil
local lockConn           = nil
local monsterThread      = nil
local monsterTween       = nil
local monsterLockConnection = nil
local monsterLockCFrame     = nil

-- Fishing Variables
local FISHING_ZONES = {
    ["Zone 1 (Lobby)"] = { a = CFrame.new(451.22, 88.47, 48.45), b = CFrame.new(451.77, 88.27, 48.10) },
    ["Zone 2"] = { a = CFrame.new(2192.61, 401.85, -330.64), b = CFrame.new(2189.50, 401.87, -327.91) },
    ["Zone 3"] = { a = CFrame.new(1324.88, 136.89, 82.13, 0.972, -0.000, 0.234, 0.000, 1.000, 0.000, -0.234, -0.000, 0.972), b = CFrame.new(1330.09, 135.62, 79.46, 0.986, 0.000, -0.169, -0.000, 1.000, -0.000, 0.169, 0.000, 0.986) },
    ["Zone 4"] = { a = CFrame.new(-263.96, 39.37, -703.85, -0.999, -0.000, -0.052, -0.000, 1.000, -0.000, 0.052, -0.000, -0.999), b = CFrame.new(-257.46, 38.90, -703.25, -0.990, -0.000, -0.141, -0.000, 1.000, -0.000, 0.141, -0.000, -0.990) },
    ["Zone 5"] = { a = CFrame.new(-640.47, 64.40, 44.11), b = CFrame.new(-637.87, 63.67, 41.29) },
    ["Zone 6"] = { a = CFrame.new(-1551.71, 201.84, 1726.81), b = CFrame.new(-1547.92, 202.01, 1727.64) },
    ["Zone 7"] = { a = CFrame.new(-2469.71, 185.94, 1169.44, -0.789, 0.000, -0.614, 0.000, 1.000, -0.000, 0.614, -0.000, -0.789), b = CFrame.new(-2464.82, 186.35, 1167.45, -0.814, 0.000, -0.581, 0.000, 1.000, -0.000, 0.581, -0.000, -0.814) }
}

_G.SelectedFishingZone = "Zone 1 (Lobby)"
local currentTarget = FISHING_ZONES["Zone 1 (Lobby)"].a
local lastClickTick = 0 
local fishStatusLabel = nil

-- 🛑 Thread Cleanup: Stop old instances if re-running script
if getgenv().ArmHubFishingThread then task.cancel(getgenv().ArmHubFishingThread) end
if getgenv().ArmHubAIConnection then getgenv().ArmHubAIConnection:Disconnect() end

-- Node Lock System
local activeWelds   = {}
local lockHeartbeat = nil
local lockedNodeRef = nil

local function lockNode(node)
    if lockHeartbeat then lockHeartbeat:Disconnect() lockHeartbeat = nil end
    for _, w in pairs(activeWelds) do pcall(function() w:Destroy() end) end
    activeWelds = {}
    lockedNodeRef = node
    pcall(function()
        for _, v in pairs(node:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Anchored = true
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = v
                weld.Part1 = workspace.Terrain
                weld.Parent = v
                table.insert(activeWelds, weld)
            end
        end
    end)
    local frozenCFrames = {}
    pcall(function()
        for _, v in pairs(node:GetDescendants()) do
            if v:IsA("BasePart") then frozenCFrames[v] = v.CFrame end
        end
    end)
    lockHeartbeat = RunService.Heartbeat:Connect(function()
        if not lockedNodeRef or not lockedNodeRef.Parent then
            if lockHeartbeat then lockHeartbeat:Disconnect() lockHeartbeat = nil end
            return
        end
        pcall(function()
            for part, cf in pairs(frozenCFrames) do
                if part and part.Parent then
                    part.Anchored = true
                    part.CFrame   = cf
                end
            end
        end)
    end)
end

local function unlockNode()
    if lockHeartbeat then lockHeartbeat:Disconnect() lockHeartbeat = nil end
    for _, w in pairs(activeWelds) do pcall(function() w:Destroy() end) end
    activeWelds = {}
    if lockedNodeRef then
        pcall(function()
            for _, v in pairs(lockedNodeRef:GetDescendants()) do
                if v:IsA("BasePart") then v.Anchored = false end
            end
        end)
    end
    lockedNodeRef = nil
end

-- ============================================================
-- [[ Game Data ]]
-- ============================================================
local FARM_TYPES = {
    { key = "AutoFarmFood", folder = "Food",      node = "LargeFoodNode"     },
    { key = "AutoFarmOre",  folder = "Resources", node = "LargeResourceNode" },
    { key = "AutoFarmBone", folder = "BoneMeal",  node = "BoneMealNode"      },
}

local Remotes             = ReplicatedStorage:WaitForChild("Remotes")
local HitRemote           = Remotes:FindFirstChild("ClientDestructibleHitRemote")
local CollectRemote       = Remotes:FindFirstChild("HarvestDropsRemote")
local FeedRemote          = Remotes:FindFirstChild("FeedDragonRemote")
local BondDragonRemote    = Remotes:WaitForChild("BondDragonRemote")
local BondingExpRemote    = LocalPlayer:WaitForChild("Remotes"):WaitForChild("BondingExpRemote")
local SetCollectEggRemote = Remotes:WaitForChild("SetCollectEggRemote")
local CollectEggRemote    = Remotes:WaitForChild("CollectEggRemote")
local FocusMissionRemote  = Remotes:WaitForChild("FocusMissionRemote")
local function OpenRemote() end -- Placeholder if not found elsewhere
pcall(function() OpenRemote = LocalPlayer:WaitForChild("Remotes"):WaitForChild("OpenChestRemote") end)



LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- [[ CLEANED REDUNDANT BLOCK ]]

local function getRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    local dragonModel = getActiveDragonModel()
    return (dragonModel and dragonModel:FindFirstChild("HumanoidRootPart")) or char:FindFirstChild("HumanoidRootPart")
end

local function restoreAllCollision()
    local function doRestore()
        pcall(function()
            local char   = LocalPlayer.Character
            local dragon = getActiveDragonModel()
            if char then
                for _, v in pairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = true end
                end
            end
            if dragon then
                for _, v in pairs(dragon:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = true end
                end
            end
        end)
    end
    doRestore()
    task.defer(doRestore)
    task.delay(0.1, doRestore)
end

RunService.Stepped:Connect(function()
    if _G.Noclip then
        pcall(function()
            local char   = LocalPlayer.Character
            local dragon = getActiveDragonModel()
            local root   = getRoot()
            local isNearGround = false
            if root then
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {char, dragon}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                local ray = workspace:Raycast(root.Position, Vector3.new(0, -6, 0), rayParams)
                if ray then isNearGround = true end
            end
            if char then
                for _, v in pairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then
                        if v.Name == "HumanoidRootPart" and isNearGround then v.CanCollide = true
                        else v.CanCollide = false end
                    end
                end
            end
            if dragon then
                for _, v in pairs(dragon:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end)
    end
    if _G.EnableSpeedHack then
        pcall(function()
            local root = getRoot()
            local hum  = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if root and hum and hum.MoveDirection.Magnitude > 0 then
                root.CFrame = root.CFrame + (hum.MoveDirection * (_G.SpeedPower / 10))
            end
        end)
    end
end)

local function isDead(target)
    if not target or not target.Parent then return true end
    local deadVal = target:FindFirstChild("Dead", true)
    if deadVal and deadVal:IsA("BoolValue") and deadVal.Value == true then return true end
    local hpVal = target:FindFirstChild("Health", true)
    if hpVal and hpVal:IsA("IntValue") and hpVal.Value <= 0 then return true end
    if not target:FindFirstChild("BillboardPart", true) then return true end
    return false
end

local function isIgnored(target)
    local t = ignoreList[target]
    if not t then return false end
    if os.clock() - t > _G.IgnoreCooldown then ignoreList[target] = nil return false end
    return true
end

local function setIgnore(target) ignoreList[target] = os.clock() end

local function setPhysics(active)
    local root = getRoot()
    if not root then return end
    if active then
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent   = root
        end
    elseif bv then
        bv:Destroy()
        bv = nil
    end
end

local function flyTo(target)
    local root = getRoot()
    if not root then return false end
    local ok, pivot = pcall(function() return target:GetPivot() end)
    if not ok then return false end
    local targetPos = pivot * CFrame.new(0, 15, 0)
    local distance  = (root.Position - targetPos.Position).Magnitude
    if distance < 10 then return true end
    local easingStyles = {Enum.EasingStyle.Linear, Enum.EasingStyle.Quad, Enum.EasingStyle.Sine}
    local chosenStyle  = easingStyles[math.random(1, #easingStyles)]
    setPhysics(true)
    currentTween = TweenService:Create(root, TweenInfo.new(distance / _G.FlySpeed, chosenStyle), { CFrame = targetPos })
    currentTween:Play()
    while currentTween.PlaybackState == Enum.PlaybackState.Playing do
        if not _G.MasterFarm or isDead(target) then
            currentTween:Cancel()
            setPhysics(false)
            return false
        end
        local currentDist = (root.Position - targetPos.Position).Magnitude
        if currentDist <= _G.WarpDistance and currentDist > 10 then
            currentTween:Cancel()
            root.CFrame = targetPos
            break
        end
        task.wait()
    end
    setPhysics(false)
    return not isDead(target)
end

local function silentAttack(node)
    local hitbox = node:FindFirstChild("Hitbox", true) or node:FindFirstChild("HitBox", true)
    if hitbox and hitbox:IsA("BasePart") then
        hitbox.Size        = _G.HitboxSize
        hitbox.Transparency = 1
        hitbox.CanCollide  = false
    end
    local billboard = node:FindFirstChild("BillboardPart", true)
    pcall(function()
        local dragonModel = getActiveDragonModel()
        if dragonModel and dragonModel:FindFirstChild("Remotes") then
            dragonModel.Remotes.PlaySoundRemote:FireServer("Breath", "Destructibles", billboard)
        end
        if HitRemote then HitRemote:FireServer(node, billboard) end
    end)
    rndWait(0.08, 0.18)
end

local function getNearestTarget()
    local root = getRoot()
    if not root then return nil end
    local nearest, minDist = nil, math.huge
    for _, farmType in ipairs(FARM_TYPES) do
        if not _G[farmType.key] then continue end
        local nodes = workspace.Interactions.Nodes:FindFirstChild(farmType.folder)
        if not nodes then continue end
        for _, v in pairs(nodes:GetChildren()) do
            if v.Name == farmType.node and v:IsA("Model") and not isDead(v) and not isIgnored(v) then
                local ok, pivot = pcall(function() return v:GetPivot() end)
                if ok then
                    local dist = (root.Position - pivot.Position).Magnitude
                    if dist < minDist and dist < 2000 then minDist = dist nearest = v end
                end
            end
        end
    end
    return nearest
end

-- ============================================================
-- [[ Auto Feed / Bond ]]
-- ============================================================
local feedThread = nil
local bondThread = nil

local function executeSmartBond()
    local dragonID     = getActiveDragonID()
    local targetFolder = LocalPlayer.Data.Dragons:FindFirstChild(dragonID)
    if not targetFolder then return end
    pcall(function()
        local possibleNeeds = {
            { name = "Bored",     checkMode = "Int",  action = "Bored" },
            { name = "Dirty",     checkMode = "Int",  action = "Wash"  },
            { name = "Happiness", checkMode = "Low",  action = "Pet"   },
            { name = "Lonely",    checkMode = "Bool", action = "Pet"   }
        }
        local activeAction = nil
        for _, need in ipairs(possibleNeeds) do
            local valObj = targetFolder:FindFirstChild(need.name)
            if valObj and (
                (need.checkMode == "Int"  and valObj.Value > 0)    or
                (need.checkMode == "Bool" and valObj.Value == true) or
                (need.checkMode == "Low"  and valObj.Value < 50)
            ) then
                activeAction = need.action break
            end
        end
        if activeAction then
            BondDragonRemote:FireServer(targetFolder)
            rndWait(0.4, 0.8)
            local args = { targetFolder, activeAction }
            for i = 1, 35 do BondingExpRemote:FireServer(unpack(args)) rndWait(0.05, 0.12) end
            BondDragonRemote:FireServer(unpack(args))
        end
    end)
end

local function startFeedThread()
    if feedThread then return end
    feedThread = task.spawn(function()
        while _G.AutoFeed do
            pcall(function()
                local currentID   = getActiveDragonID()
                local p           = game.Players.LocalPlayer
                local hungerValue = p.Data.Dragons[currentID].Hunger
                local foodName, foodItem = getAvailableFood()
                if hungerValue and hungerValue.Value < _G.MinHunger and foodItem and foodItem.Value > 0 then
                    while _G.AutoFeed and hungerValue.Value < 100 and foodItem.Value > 0 do
                        FeedRemote:InvokeServer(currentID, { ItemName = foodName, Amount = 1 })
                        rndWait(0.2, 0.4)
                    end
                end
            end)
            task.wait(3)
        end
        feedThread = nil
    end)
end

local function startBondThread()
    if bondThread then return end
    bondThread = task.spawn(function()
        while _G.AutoBond do
            executeSmartBond()
            task.wait(10)
        end
        bondThread = nil
    end)
end

task.spawn(function()
    while true do if _G.AutoBond then executeSmartBond() end task.wait(10) end
end)

task.spawn(function()
    while true do
        local root = getRoot()
        if root and _G.AutoCollect then
            local drops = workspace.Interactions:FindFirstChild("Drops")
            if drops then
                for _, item in pairs(drops:GetChildren()) do
                    pcall(function()
                        if (root.Position - item:GetPivot().Position).Magnitude < 85 then
                            item:PivotTo(root.CFrame)
                            if CollectRemote then CollectRemote:FireServer(item) end
                        end
                    end)
                end
            end
        end
        task.wait(0.3)
    end
end)

-- [[ 🧲 GLOBAL MAGNET SYSTEM (Instant Drop Collection) ]]
task.spawn(function()
    local function setupAutoCollect(remoteName)
        local remote = Remotes:FindFirstChild(remoteName)
        if not (remote and remote:IsA("RemoteEvent")) then return end
        remote.OnClientEvent:Connect(function(nodePart, waveId, itemsTable)
            if not _G.AutoCollect then return end
            if type(itemsTable) ~= "table" then return end
            for itemIndex, _ in pairs(itemsTable) do
                pcall(function()
                    remote:FireServer(nodePart, waveId, itemIndex)
                end)
                task.wait(0.03)
            end
        end)
    end
    setupAutoCollect("LargeNodeDropsRemote")
    setupAutoCollect("MobDropsRemote")
    print("🧲 [RUAJAD HUB] Global Magnet System Active!")
end)

-- [[ INTEGRATED MONSTER LOGIC ]]
local function getMobRemotes()
    local dragon = getActiveDragonModel()
    if dragon and dragon:FindFirstChild("Remotes") then
        return dragon.Remotes:FindFirstChild("PlaySoundRemote"), dragon.Remotes:FindFirstChild("BreathFireRemote")
    end
    return nil, nil
end

local function isTargetAlive(targetObj)
    if not targetObj or not targetObj.Parent then return false end
    local hp = targetObj:FindFirstChild("Health") or targetObj.Parent:FindFirstChild("Health")
    local dead = targetObj:FindFirstChild("Dead") or targetObj.Parent:FindFirstChild("Dead")
    return (hp and hp.Value > 0) and (not dead or dead.Value == false)
end

local function lockPlayerToMonster(mob)
    if monsterLockConnection then monsterLockConnection:Disconnect() monsterLockConnection = nil end
    local ok, cf = pcall(function() return mob:GetPivot() end)
    if not ok then return end
    monsterLockCFrame = cf * CFrame.new(0, 15, 0)
    monsterLockConnection = RunService.Heartbeat:Connect(function()
        if not _G.MonsterFarmRunning or not isTargetAlive(mob) then
            if monsterLockConnection then monsterLockConnection:Disconnect() monsterLockConnection = nil end
            return
        end
        pcall(function()
            local root = getRoot()
            if root then root.CFrame = monsterLockCFrame end
        end)
    end)
end

local function unlockPlayerFromMonster()
    if monsterLockConnection then monsterLockConnection:Disconnect() monsterLockConnection = nil end
    monsterLockCFrame = nil
end

local function getNearestMonster()
    local root = getRoot()
    if not root then return nil end
    local mobFolder = workspace:FindFirstChild("MobFolder")
    if not mobFolder then return nil end
    local nearest, minDist = nil, math.huge
    for _, obj in pairs(mobFolder:GetDescendants()) do
        if obj:IsA("MeshPart") or obj:IsA("Part") then
            local nameToMatch = obj.Name:lower()
            local parentName = (obj.Parent and obj.Parent.Name:lower()) or ""
            local isSelected = (#_G.SelectedMonsters == 0)
            for _, selected in ipairs(_G.SelectedMonsters) do
                local s = selected:lower()
                if nameToMatch:find(s) or parentName:find(s) then isSelected = true break end
            end
            if isSelected and isTargetAlive(obj) then
                local dist = (root.Position - obj.Position).Magnitude
                if dist < minDist then minDist = dist nearest = obj end
            end
        end
    end
    return nearest
end

local function attackMonster(mob)
    local soundRemote, breathRemote = getMobRemotes()
    if not soundRemote or not breathRemote then return end
    pcall(function() breathRemote:FireServer(true) end)
    while _G.MonsterFarmRunning and isTargetAlive(mob) do
        pcall(function() soundRemote:FireServer("Breath", "Mobs", mob) end)
        task.wait(0.27)
    end
    pcall(function() breathRemote:FireServer(false) end)
end

local function startMonsterFarm()
    if monsterThread then return end
    monsterThread = task.spawn(function()
        print("⚔️ Monster Farm Started")
        while _G.MonsterFarmRunning do
            local target = getNearestMonster()
            if target then
                local root = getRoot()
                if not root then task.wait(0.5) continue end
                local targetPos = target:GetPivot() * CFrame.new(0, 15, 0)
                local distance = (root.Position - targetPos.Position).Magnitude
                if distance > 10 then
                    setPhysics(true)
                    monsterTween = TweenService:Create(root, TweenInfo.new(distance / _G.MonsterFlySpeed, Enum.EasingStyle.Linear), { CFrame = targetPos })
                    monsterTween:Play()
                    while monsterTween.PlaybackState == Enum.PlaybackState.Playing do
                        if not _G.MonsterFarmRunning or not isTargetAlive(target) then monsterTween:Cancel() break end
                        local currentDist = (root.Position - targetPos.Position).Magnitude
                        if currentDist <= _G.MonsterWarpDist and currentDist > 10 then
                            monsterTween:Cancel()
                            root.CFrame = targetPos
                            break
                        end
                        task.wait()
                    end
                    setPhysics(false)
                end
                if _G.MonsterFarmRunning and isTargetAlive(target) then
                    lockPlayerToMonster(target)
                    attackMonster(target)
                    unlockPlayerFromMonster()
                end
            else
                task.wait(0.5)
            end
        end
        unlockPlayerFromMonster()
        monsterThread = nil
    end)
end

-- ============================================================
-- [[ 🥚 Egg System ]]
-- ============================================================
-- eggStatusLabel จะถูก assign หลัง UI สร้าง เพื่อให้ startEggFarm() อัพเดตได้
local eggStatusLabel = nil

local function lockToEggNode(nodeCF)
    if eggStickConnection then eggStickConnection:Disconnect() eggStickConnection = nil end
    eggStickConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            local root = getRoot()
            if root then
                local stickPos = nodeCF * CFrame.new(0, 15, 0)
                if (root.Position - stickPos.Position).Magnitude > 10 then
                    root.CFrame = stickPos
                end
            end
        end)
    end)
end

local function unlockEggNode()
    if eggStickConnection then eggStickConnection:Disconnect() eggStickConnection = nil end
end

local function setEggStatus(text)
    pcall(function()
        if eggStatusLabel then eggStatusLabel:Set(text) end
    end)
end

local function flyToEggNode(nodeCF)
    local root = getRoot()
    if not root then return end
    local targetPos = nodeCF * CFrame.new(0, 15, 0)
    local distance  = (root.Position - targetPos.Position).Magnitude
    if distance < 10 then return end

    -- 📷 ล็อคกล้องให้ติดตามทันทีระหว่างบิน
    local cam = workspace.CurrentCamera
    local prevCamType = cam and cam.CameraType
    if cam then cam.CameraType = Enum.CameraType.Follow end

    local easingStyles = { Enum.EasingStyle.Linear, Enum.EasingStyle.Quad, Enum.EasingStyle.Sine }
    local chosenStyle  = easingStyles[math.random(1, #easingStyles)]
    setPhysics(true)
    local tween = TweenService:Create(root, TweenInfo.new(distance / (_G.FlySpeed / 2), chosenStyle), { CFrame = targetPos })
    tween:Play()
    while tween.PlaybackState == Enum.PlaybackState.Playing do
        local currentDist = (root.Position - targetPos.Position).Magnitude
        if currentDist <= _G.WarpDistance and currentDist > 10 then
            tween:Cancel()
            root.CFrame = targetPos
            break
        end
        if not _G.AutoCollectEgg then tween:Cancel() break end
        task.wait()
    end
    setPhysics(false)

    -- 📷 คืนกล้องกลับเป็นแบบเดิม
    if cam and prevCamType then cam.CameraType = prevCamType end
end

local function startEggFarm()
    if eggThread then return end
    eggThread = task.spawn(function()
        while _G.AutoCollectEgg do
            pcall(function()
                local eggNodes    = workspace.Interactions.Nodes.Eggs
                local activeNodes = eggNodes.ActiveNodes:GetChildren()
                local totalNodes  = #activeNodes

                if totalNodes == 0 then
                    setEggStatus("🟡 ไข่: รอ Node spawn... (ยังไม่มี Node)")
                    return
                end

                setEggStatus("🟢 ไข่: พบ " .. totalNodes .. " Node | กำลังเริ่มเก็บ...")

                for idx, node in pairs(activeNodes) do
                    if not _G.AutoCollectEgg then break end
                    local ok, nodeCF = pcall(function() return node:GetPivot() end)
                    if not ok then continue end

                    setEggStatus("🟢 ไข่: บินไป Node " .. idx .. "/" .. totalNodes)
                    flyToEggNode(nodeCF)
                    task.wait(0.1)
                    lockToEggNode(nodeCF)

                    setEggStatus("🔍 ไข่: สแกน Node " .. idx .. "/" .. totalNodes .. " (ID 1-16)...")

                    local collected = false
                    for i = 1, 16 do
                        if not _G.AutoCollectEgg then break end
                        FocusMissionRemote:FireServer("WorldMission", "Lobby", "EggQuest")
                        SetCollectEggRemote:InvokeServer(tostring(i))
                        local result = CollectEggRemote:InvokeServer(tostring(i))
                        if result == true then
                            print("✅ เก็บไข่ ID:", i, "สำเร็จ!")
                            collected = true
                            setEggStatus("✅ ไข่: เก็บสำเร็จ! Node " .. idx .. "/" .. totalNodes .. " (ID " .. i .. ")")
                            break
                        end
                    end

                    unlockEggNode()

                    if not collected then
                        print("⚠️ ไม่มีไข่ใน node นี้")
                        setEggStatus("⚠️ ไข่: Node " .. idx .. " ว่างเปล่า → ข้ามไป")
                    end

                    task.wait(0.2)
                end
            end)
            task.wait(0.5)
        end
        unlockEggNode()
        setEggStatus("⚪ ไข่: ปิดอยู่")
        eggThread = nil
    end)
end

-- ============================================================
-- [[ Chest System ]]
-- ============================================================
local function getBreathRemote()
    local char = LP.Character
    if char and char:FindFirstChild("Dragons") then
        local dragon = char.Dragons:GetChildren()[1]
        if dragon and dragon:FindFirstChild("Remotes") then
            return dragon.Remotes:FindFirstChild("BreathFireRemote")
        end
    end
    return nil
end

local function isAlive(chest)
    if not chest or not chest.Parent then return false end
    local hrp    = chest:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local health = hrp:FindFirstChild("Health")
    local dead   = hrp:FindFirstChild("Dead")
    if dead and dead.Value == true then return false end
    if health and health.Value <= 0 then return false end
    return true
end

local function getTargetChest()
    local TreasureFolder = workspace:WaitForChild("Interactions"):WaitForChild("Nodes"):WaitForChild("Treasure")
    local targets = {}
    if _G.FarmValentines then table.insert(targets, "ValentinesChest") end
    if _G.FarmSilver      then table.insert(targets, "SilverChest")    end
    if _G.FarmBronze      then table.insert(targets, "BronzeChest")    end
    if _G.FarmGold        then table.insert(targets, "GoldChest")      end
    for _, targetName in ipairs(targets) do
        local nearest, lastDist = nil, math.huge
        for _, nodeFolder in pairs(TreasureFolder:GetChildren()) do
            local chest = nodeFolder:FindFirstChild(targetName)
            if chest and not LootedInstances[chest] and isAlive(chest) then
                local hrp  = chest:FindFirstChild("HumanoidRootPart")
                local char = LP.Character
                if hrp and char and char:FindFirstChild("HumanoidRootPart") then
                    local dist = (char.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if dist < lastDist then nearest = chest lastDist = dist end
                end
            end
        end
        if nearest then return nearest end
    end
    return nil
end

local function chestTeleport(targetCFrame)
    local char = LP.Character
    if not char then return false end
    local root = getRoot() -- Use getRoot for better dragon/char handling
    local hum  = char:FindFirstChild("Humanoid")
    if not root then return false end
    local dist = (root.Position - targetCFrame.Position).Magnitude
    if dist < 10 then return true end
    
    if hum then hum.WalkSpeed = 0 hum.JumpPower = 0 end
    local easingStyles = {Enum.EasingStyle.Linear, Enum.EasingStyle.Quad, Enum.EasingStyle.Sine}
    local chosenStyle  = easingStyles[math.random(1, #easingStyles)]
    
    setPhysics(true)
    local tween = TweenService:Create(root, TweenInfo.new(dist / _G.ChestFlySpeed, chosenStyle), { CFrame = targetCFrame })
    tween:Play()
    
    while tween.PlaybackState == Enum.PlaybackState.Playing do
        if not _G.AutoFarm then
            tween:Cancel()
            setPhysics(false)
            if hum then hum.WalkSpeed = 16 hum.JumpPower = 50 end
            return false
        end
        
        local currentDist = (root.Position - targetCFrame.Position).Magnitude
        if currentDist <= _G.WarpDistance and currentDist > 10 then
            tween:Cancel()
            root.CFrame = targetCFrame
            break
        end
        task.wait()
    end
    
    setPhysics(false)
    if hum then hum.WalkSpeed = 16 hum.JumpPower = 50 end
    return true
end

local function lockPosition(cf)
    if lockConn then lockConn:Disconnect() lockConn = nil end
    lockConn = RunService.Heartbeat:Connect(function()
        local char = LP.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = cf
        end
    end)
end

local function unlockPosition()
    if lockConn then lockConn:Disconnect() lockConn = nil end
end

local function startChestFarm()
    farmThread = task.spawn(function()
        while _G.AutoFarm do
            local target = getTargetChest()
            if not target then task.wait(0.1) continue end
            if not isAlive(target) then LootedInstances[target] = true continue end
            if not _G.AutoFarm then break end
            local hrp = target:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            local targetCF = hrp.CFrame * CFrame.new(0, 5, -10)
            local arrived  = chestTeleport(targetCF)
            if not _G.AutoFarm then unlockPosition() break end
            if not arrived or not isAlive(target) then LootedInstances[target] = true continue end
            lockPosition(targetCF)
            task.wait(0.4)
            local timeout = tick()
            while isAlive(target) and _G.AutoFarm do
                if tick() - timeout > 30 then break end
                pcall(function()
                    mouse1press()
                    task.wait(0.1)
                    mouse1release()
                end)
                task.wait(0.1)
            end
            pcall(function() mouse1release() end)
            pcall(function()
                local br = getBreathRemote()
                if br then br:FireServer(false) end
            end)
            unlockPosition()
            if not _G.AutoFarm then break end
            local nodeID = tonumber(target.Parent.Name)
            if nodeID then
                pcall(function()
                    local TreasureDropsRemote = ReplicatedStorage.Remotes:FindFirstChild("TreasureChestDropsRemote")
                    if not TreasureDropsRemote then return end
                    local receivedItems = nil
                    local s2cConn
                    s2cConn = TreasureDropsRemote.OnClientEvent:Connect(function(dataRef, items)
                        if typeof(items) == "table" then receivedItems = items end
                    end)
                    OpenRemote:InvokeServer(nodeID, true)
                    local waitStart = tick()
                    while not receivedItems and tick() - waitStart < 2 do task.wait(0.05) end
                    s2cConn:Disconnect()
                    local dataRef = LocalPlayer.Data.EventTreasureChests.Lobby:FindFirstChild(tostring(nodeID))
                    if not dataRef then return end
                    if receivedItems then
                        for i, _ in pairs(receivedItems) do
                            pcall(function() TreasureDropsRemote:FireServer(dataRef, i) end)
                            task.wait(0.05)
                        end
                    else
                        for i = 1, 4 do
                            pcall(function() TreasureDropsRemote:FireServer(dataRef, i) end)
                            task.wait(0.05)
                        end
                    end
                end)
            end
            LootedInstances[target] = true
        end
        unlockPosition()
        farmThread = nil
        print("🛑 หยุด Chest Farm")
    end)
end

local function stopChestFarm()
    _G.AutoFarm = false
    pcall(function()
        local br = getBreathRemote()
        if br then br:FireServer(false) end
    end)
    if farmThread then task.cancel(farmThread) farmThread = nil end
    unlockPosition()
end

-- ============================================================
-- [[ FISHING SYSTEM ]]
-- ============================================================
local function stopFishing()
    _G.AutoFish = false
    if getgenv().ArmHubFishingThread then task.cancel(getgenv().ArmHubFishingThread) getgenv().ArmHubFishingThread = nil end
    if getgenv().ArmHubAIConnection then getgenv().ArmHubAIConnection:Disconnect() getgenv().ArmHubAIConnection = nil end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if root then root.Anchored = false end
    if hum then hum.WalkSpeed = 16 end
end

local function clickCenter()
    local cam = workspace.CurrentCamera
    if cam then
        -- 🧠 Randomized Click Position (±10px) to avoid fixed-point detection
        local cx = (cam.ViewportSize.X / 2) + math.random(-10, 10)
        local cy = (cam.ViewportSize.Y / 2) + math.random(-10, 10)
        vim:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
        task.wait(math.random(1, 5)/100) -- 🧠 Hold duration
        vim:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
    end
end

local function startSmartBrain()
    if getgenv().ArmHubAIConnection then getgenv().ArmHubAIConnection:Disconnect() end
    getgenv().ArmHubAIConnection = RunService.RenderStepped:Connect(function()
        if not _G.AutoFish then return end
        
        local fishingGui = LocalPlayer.PlayerGui:FindFirstChild("FishingGui")
        if fishingGui and fishingGui.Enabled then
            local container = fishingGui:FindFirstChild("ContainerFrame")
            if container then
                local reelBtn = container:FindFirstChild("ButtonsFrame") and container.ButtonsFrame:FindFirstChild("ReelButton")
                local reeling = container:FindFirstChild("ReelingFrame")
                
                if reelBtn and reelBtn.Visible and (not reeling or not reeling.Visible) then
                    if tick() - lastClickTick > (0.8 + math.random() * 0.4) then -- 🧠 Human reaction (0.8s - 1.2s)
                        lastClickTick = tick()
                        task.spawn(clickCenter)
                    end
                elseif reeling and reeling.Visible then
                    local arrow = reeling:FindFirstChild("SpinReelLabel")
                    local safeZone = reeling:FindFirstChild("SpinRingFrame")
                    
                    if arrow and safeZone then
                        -- 🟢 NATURAL MODE (Humanized Movement)
                        local diff = math.abs((arrow.Rotation - safeZone.Rotation + 180) % 360 - 180)
                        if diff < 15 and tick() - lastClickTick > (0.15 + math.random() * 0.2) then -- 🧠 Humanized Speed (6-15 CPS)
                            lastClickTick = tick()
                            task.spawn(clickCenter)
                        end
                    end
                end
            end
        end
    end)
end

local function startFishingLoop()
    startSmartBrain() 
    
    getgenv().ArmHubFishingThread = task.spawn(function()
        while _G.AutoFish do
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart", 10)
            local hum = char:WaitForChild("Humanoid", 10)
            if not hrp or not hum then task.wait(1) continue end

            -- 📍 Dynamic Zone Lookup
            local zoneData = FISHING_ZONES[_G.SelectedFishingZone] or FISHING_ZONES["Zone 1 (Lobby)"]
            local targetA = zoneData.a
            local targetB = zoneData.b

            -- Initial target if nil or switch logic
            if not currentTarget or (currentTarget ~= targetA and currentTarget ~= targetB) then
                currentTarget = targetA
            end

            -- ⚡ Geometric Jitter
            local jitter = Vector3.new(math.random(-200, 200)/100, 0, math.random(-200, 200)/100)
            -- ⚡ Geometric Jitter: Use '+' to preserve rotation matrix
            local jitter = Vector3.new(math.random(-200, 200)/100, 0, math.random(-200, 200)/100)
            local jitteredTarget = currentTarget + jitter
            
            local dist = (hrp.Position - jitteredTarget.Position).Magnitude
            hrp.Anchored = false 
            hum.WalkSpeed = 16 

            -- 🧠 Variable Fly Speed: Capped at 160 for stealth
            local currentFlySpeed = 160 * (0.8 + math.random() * 0.4)
            local timeToFly = dist / currentFlySpeed
            if timeToFly < 0.1 then timeToFly = 0.1 end

            -- 🛑 Pre-flight Safety: Stop any current motion
            pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0,0,0) end)
            
            local tw = TweenService:Create(hrp, TweenInfo.new(timeToFly, Enum.EasingStyle.Linear), {CFrame = jitteredTarget})
            tw:Play()

            -- ⚡ ชิงกด G โยนเบ็ด
            local hasCasted = false
            local flyTimer = tick()

            while tick() - flyTimer < timeToFly do
                if (hrp.Position - jitteredTarget.Position).Magnitude < 12 and not hasCasted then
                    hasCasted = true
                    task.spawn(function()
                        rndWait(0.4, 1.1) -- 🧠 Human delay before equipping
                        local rod = char:FindFirstChild("FishingRod") or LocalPlayer.Backpack:FindFirstChild("FishingRod")
                        if rod then
                            if rod.Parent == LocalPlayer.Backpack then hum:EquipTool(rod) end
                            rndWait(0.3, 0.6) -- 🧠 Wait for equip animation
                            vim:SendKeyEvent(true, Enum.KeyCode.G, false, game)
                            task.wait(math.random(5, 15)/100) -- 🧠 Key hold duration
                            vim:SendKeyEvent(false, Enum.KeyCode.G, false, game)
                        end
                    end)
                end
                task.wait(0.1)
            end

            if not hasCasted then
                local rod = char:FindFirstChild("FishingRod") or LocalPlayer.Backpack:FindFirstChild("FishingRod")
                if rod then
                    if rod.Parent == LocalPlayer.Backpack then hum:EquipTool(rod) end
                    rndWait(0.3, 0.7)
                    vim:SendKeyEvent(true, Enum.KeyCode.G, false, game)
                    task.wait(0.1)
                    vim:SendKeyEvent(false, Enum.KeyCode.G, false, game)
                end
            end

            hrp.CFrame = jitteredTarget
            pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0,0,0) end)
            -- 🛡️ [Stealth Lock]: Avoid Anchoring (Risky). Use velocity + WalkSpeed = 0
            hum.WalkSpeed = 0
            task.spawn(function()
                while _G.AutoFish and (hrp.Position - jitteredTarget.Position).Magnitude < 5 do
                    hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    task.wait(0.5)
                end
            end)

            -- 🎒 [Event Trigger]
            local roundEnded = false
            local backpackEvent = LocalPlayer.Backpack.ChildAdded:Connect(function(item)
                if item.Name == "FishingRod" then
                    roundEnded = true
                end
            end)

            local waitStart = tick()
            while _G.AutoFish and not roundEnded do
                if tick() - waitStart > 35 then break end
                task.wait(0.1)
            end

            backpackEvent:Disconnect()
            task.wait(0.5)

            -- 🔄 Toggle between Point A and Point B for next round
            local zoneData = FISHING_ZONES[_G.SelectedFishingZone] or FISHING_ZONES["Zone 1 (Lobby)"]
            if currentTarget == zoneData.a then
                currentTarget = zoneData.b
            else
                currentTarget = zoneData.a
            end
        end
    end)
end

-- ============================================================
-- [[ UI ]]
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name            = "RUAJAD HUB V1.0",
    LoadingTitle    = "Full Logic Restored",
    LoadingSubtitle = "by Arm Hub",
    ConfigurationSaving = { Enabled = true, Folder = "RUAJAD_HUB" }
})

local MainTab = Window:CreateTab("Main", 4483345998)
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")

-- ============================================================
-- 👁️ ESP ENGINE LOGIC (V3.0 Integrated)
-- ============================================================
local ESP = {
    Enabled = false,
    Settings = {
        Players = false, Monsters = false, Eggs = false, Food = false, Chests = false,
        ShowNames = true, ShowDistance = true, ShowTracers = false, ShowBoxes = false, ShowHighlights = true,
        TextSize = 14, TracerThickness = 1, BoxThickness = 1, MaxDistance = 10000
    },
    Objects = {},
    Config = {
        Players  = { Color = Color3.fromRGB(255, 100, 255) },
        Monsters = { Color = Color3.fromRGB(255, 50, 50) },
        Eggs     = { Color = Color3.fromRGB(240, 240, 50) },
        Food     = { Color = Color3.fromRGB(50, 255, 50) },
        Chests   = { Color = Color3.fromRGB(50, 150, 255) }
    }
}

local function createESP(object, type, displayName)
    if not object or not object.Parent then return end
    if ESP.Objects[object] then return end

    local conf = ESP.Config[type]
    local root = object:IsA("Model") and (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")) or object
    if not root then return end

    local hl = Instance.new("Highlight")
    hl.Name = "ArmHub_ESP_HL"
    hl.FillColor = conf.Color; hl.FillTransparency = 0.5; hl.OutlineColor = Color3.new(1,1,1); hl.Adornee = object; hl.Parent = object

    local d_tracer = Drawing.new("Line"); d_tracer.Color = conf.Color; d_tracer.Transparency = 1
    local d_box = Drawing.new("Square"); d_box.Color = conf.Color; d_box.Transparency = 1; d_box.Filled = false
    local d_name = Drawing.new("Text"); d_name.Color = conf.Color; d_name.Center = true; d_name.Outline = true; d_name.Text = displayName
    local d_dist = Drawing.new("Text"); d_dist.Color = Color3.new(1,1,1); d_dist.Center = true; d_dist.Outline = true

    local connection
    connection = RunService.RenderStepped:Connect(function()
        local function destroyAll()
            hl:Destroy(); d_tracer:Remove(); d_box:Remove(); d_name:Remove(); d_dist:Remove(); connection:Disconnect()
            ESP.Objects[object] = nil
        end
        
        if not ESP.Enabled or not ESP.Settings[type] or not object.Parent then destroyAll() return end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local dist = (hrp.Position - root.Position).Magnitude
        if dist > ESP.Settings.MaxDistance then
            hl.Enabled = false; d_tracer.Visible = false; d_box.Visible = false; d_name.Visible = false; d_dist.Visible = false
            return
        end

        local Cam = workspace.CurrentCamera
        local pos, onScreen = Cam:WorldToViewportPoint(root.Position)
        
        if onScreen and ESP.Settings.ShowHighlights then hl.FillColor = conf.Color; hl.Enabled = true else hl.Enabled = false end

        if onScreen then
            d_tracer.Color = conf.Color; d_box.Color = conf.Color; d_name.Color = conf.Color
            local targetHeight = object:IsA("Model") and (object:GetExtentsSize().Y / 2) or 2.5
            local topPos = Cam:WorldToViewportPoint(root.Position + Vector3.new(0, targetHeight, 0))
            local bottomPos = Cam:WorldToViewportPoint(root.Position - Vector3.new(0, targetHeight, 0))
            local boxHeight = math.abs(topPos.Y - bottomPos.Y)
            local boxWidth = boxHeight * 0.65

            if ESP.Settings.ShowTracers then
                d_tracer.From = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y)
                d_tracer.To = Vector2.new(pos.X, pos.Y + boxHeight / 2)
                d_tracer.Thickness = ESP.Settings.TracerThickness; d_tracer.Visible = true
            else d_tracer.Visible = false end

            if ESP.Settings.ShowBoxes then
                d_box.Size = Vector2.new(boxWidth, boxHeight); d_box.Position = Vector2.new(pos.X - boxWidth / 2, pos.Y - boxHeight / 2)
                d_box.Thickness = ESP.Settings.BoxThickness; d_box.Visible = true
            else d_box.Visible = false end

            local textOffset = (ESP.Settings.ShowBoxes and (boxHeight / 2) + 5) or 15
            if ESP.Settings.ShowNames then
                d_name.Position = Vector2.new(pos.X, pos.Y - textOffset - ESP.Settings.TextSize)
                d_name.Size = ESP.Settings.TextSize; d_name.Visible = true
            else d_name.Visible = false end

            if ESP.Settings.ShowDistance then
                d_dist.Position = Vector2.new(pos.X, pos.Y + (ESP.Settings.ShowBoxes and (boxHeight / 2) + 2 or 5))
                d_dist.Size = math.clamp(ESP.Settings.TextSize - 4, 10, 24); d_dist.Text = "[" .. math.floor(dist) .. "M]"
                d_dist.Visible = true
            else d_dist.Visible = false end
        else
            d_tracer.Visible = false; d_box.Visible = false; d_name.Visible = false; d_dist.Visible = false
        end
    end)
    ESP.Objects[object] = { HL = hl, Conn = connection }
end

local function scanESP()
    if not ESP.Enabled then return end
    if ESP.Settings.Players then
        local function checkAndCreateESP(plr)
            if plr == LocalPlayer then return end
            local charsFolder = workspace:FindFirstChild("Characters")
            local char = (charsFolder and charsFolder:FindFirstChild(plr.Name)) or plr.Character or workspace:FindFirstChild(plr.Name)
            if char and char:IsA("Model") then
                local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart")
                if root then createESP(char, "Players", plr.DisplayName) end
            end
        end
        for _, plr in ipairs(Players:GetPlayers()) do checkAndCreateESP(plr) end
    end
    local VALID_MONSTERS = {"Boar", "Falcon", "Owl", "OwlSnow", "BoarElite"}
    local mobFolder = workspace:FindFirstChild("MobFolder")
    if mobFolder then 
        for _, obj in pairs(mobFolder:GetDescendants()) do 
            if obj:IsA("MeshPart") or obj:IsA("Part") then 
                local nameToMatch, parentName = obj.Name:lower(), (obj.Parent and obj.Parent.Name:lower()) or ""
                local isMatch, matchedName = false, ""
                for _, validName in ipairs(VALID_MONSTERS) do if nameToMatch:find(validName:lower()) or parentName:find(validName:lower()) then isMatch, matchedName = true, validName; break end end
                if isMatch then local target = (obj.Parent and obj.Parent:IsA("Model")) and obj.Parent or obj; createESP(target, "Monsters", "Mob: " .. matchedName) end
            end 
        end 
    end
    local egg = workspace:FindFirstChild("Interactions") and workspace.Interactions:FindFirstChild("Nodes") and workspace.Interactions.Nodes:FindFirstChild("Eggs") and workspace.Interactions.Nodes.Eggs:FindFirstChild("ActiveNodes")
    if egg then for _, v in pairs(egg:GetChildren()) do createESP(v, "Eggs", "[Egg]") end end
    local food = workspace:FindFirstChild("Interactions") and workspace.Interactions:FindFirstChild("Nodes") and workspace.Interactions.Nodes:FindFirstChild("Food")
    if food then for _, v in pairs(food:GetChildren()) do if v.Name == "LargeFoodNode" then createESP(v, "Food", "[Food]") end end end
    local treasure = workspace:FindFirstChild("Interactions") and workspace.Interactions:FindFirstChild("Nodes") and workspace.Interactions.Nodes:FindFirstChild("Treasure")
    if treasure then for _, v in pairs(treasure:GetChildren()) do createESP(v, "Chests", "[Chest] " .. v.Name:gsub("Chest","")) end end
end

task.spawn(function() while true do scanESP(); task.wait(2) end end)

-- Hook player joining for ESP
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        task.wait(1)
        if ESP.Enabled and plr ~= LocalPlayer then createESP(char, "Players", plr.DisplayName) end
    end)
end)

-- ============================================================
-- GLOBAL CONFIGURATIONS
-- ============================================================
local FishingTab = Window:CreateTab("🎣 Auto Fishing", 4483362458)

-- ============================================================
-- AUTO FISHING
-- ============================================================
FishingTab:CreateSection("Zone Configuration & Automation")

local zoneStatusLabel = FishingTab:CreateLabel("📍 Current Zone: Zone 1 (Lobby)")

FishingTab:CreateDropdown({
    Name = "🌊 Select Fishing Zone",
    Options = {"Zone 1 (Lobby)", "Zone 2", "Zone 3", "Zone 4", "Zone 5", "Zone 6", "Zone 7"},
    CurrentOption = "Zone 1 (Lobby)",
    Callback = function(Option)
        -- Support for both string and table (some Rayfield versions)
        local selection = Option
        if type(Option) == "table" then selection = Option[1] end
        if not selection then return end

        _G.SelectedFishingZone = selection
        local data = FISHING_ZONES[selection]
        if data then
            currentTarget = data.a -- Reset to Point A of new zone
            zoneStatusLabel:Set("📍 Current Zone: " .. selection)
            Rayfield:Notify({
                Title = "Zone Switched",
                Content = "Target set to " .. selection,
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})

FishingTab:CreateToggle({
    Name = "🎣 Enable Auto Fishing (No Dragon)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            stopFishing()
            task.wait(0.1)
            _G.AutoFish = true
            startFishingLoop() 
        else
            stopFishing()
        end
    end,
})

-- ============================================================
-- AUTO FARMING
-- ============================================================
MainTab:CreateSection("⚔️ Auto Farming Systems")

MainTab:CreateDropdown({
    Name            = "Select Monsters",
    Options         = {"Boar", "Falcon", "Owl", "OwlSnow", "BoarElite"},
    CurrentOption   = {},
    MultipleOptions = true,
    Callback        = function(selected)
        _G.SelectedMonsters = selected
    end
})

MainTab:CreateToggle({
    Name         = "⚔️ Start Auto Farm Monster",
    CurrentValue = false,
    Callback     = function(V)
        _G.MonsterFarmRunning = V
        if V then 
            startMonsterFarm() 
        else
            if monsterTween then monsterTween:Cancel() end
            unlockPlayerFromMonster()
            setPhysics(false)
        end
    end
})

-- Monster Status Label
local monsterStatusLabel = MainTab:CreateLabel("⚪ Monster: Scanning...")

-- Background scanner: Monsters
local MONSTER_LIST = {"Boar", "Falcon", "Owl", "OwlSnow", "BoarElite"}
local MONSTER_ICONS = {
    Boar = "🐗", Falcon = "🦅", Owl = "🦉", OwlSnow = "❄️", BoarElite = "👑"
}

task.spawn(function()
    while true do
        task.wait(1.5)
        pcall(function()
            local mobFolder = workspace:FindFirstChild("MobFolder")
            if not mobFolder then
                monsterStatusLabel:Set("❌ No MobFolder Found")
                return
            end
            
            local counts = {}
            for _, v in ipairs(MONSTER_LIST) do counts[v] = 0 end
            
            for _, obj in pairs(mobFolder:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local name = obj.Name
                    for mName, _ in pairs(counts) do
                        if name == mName and isTargetAlive(obj) then
                            counts[mName] = counts[mName] + 1
                            break
                        end
                    end
                end
            end
            
            local parts = {}
            for _, name in ipairs(MONSTER_LIST) do
                local icon = MONSTER_ICONS[name] or "👾"
                table.insert(parts, icon .. " " .. (counts[name] > 0 and "x" .. counts[name] or "—"))
            end
            
            local header = (_G.MonsterFarmRunning and "🟢 [" or "⚪ [") .. "Monsters]"
            monsterStatusLabel:Set(header .. " " .. table.concat(parts, " | "))
        end)
    end
end)


local FARM_OPTIONS = {
    ["🌿 Food Farm"]     = "AutoFarmFood",
    ["⛏️ Ore Farm"]      = "AutoFarmOre",
    ["🦴 Bone Meal Farm"] = "AutoFarmBone",
}

local playerLockConnection = nil
local playerLockCFrame     = nil

local function lockPlayerToNode(node)
    if playerLockConnection then playerLockConnection:Disconnect() playerLockConnection = nil end
    local ok, cf = pcall(function() return node:GetPivot() end)
    if not ok then return end
    playerLockCFrame = cf * CFrame.new(0, 15, 0)
    playerLockConnection = RunService.Heartbeat:Connect(function()
        if not _G.MasterFarm or not node or not node.Parent then
            if playerLockConnection then playerLockConnection:Disconnect() playerLockConnection = nil end
            return
        end
        pcall(function()
            local root = getRoot()
            if root then root.CFrame = playerLockCFrame end
        end)
    end)
end

local function unlockPlayerFromNode()
    if playerLockConnection then playerLockConnection:Disconnect() playerLockConnection = nil end
    playerLockCFrame = nil
end

MainTab:CreateDropdown({
    Name            = "Select Farm Type",
    Options         = {"🌿 Food Farm", "⛏️ Ore Farm", "🦴 Bone Meal Farm"},
    CurrentOption   = {},
    MultipleOptions = true,
    Callback        = function(selected)
        _G.AutoFarmFood = false
        _G.AutoFarmOre  = false
        _G.AutoFarmBone = false
        for _, name in ipairs(selected) do
            local key = FARM_OPTIONS[name]
            if key then _G[key] = true end
        end
    end
})

MainTab:CreateToggle({
    Name         = "⚔️ Start/Stop Auto Farm",
    CurrentValue = false,
    Callback     = function(V)
        if V then
            local hasAny = _G.AutoFarmFood or _G.AutoFarmOre or _G.AutoFarmBone
            if not hasAny then _G.AutoFarmFood = true _G.AutoFarmOre = true _G.AutoFarmBone = true end
            _G.MasterFarm = true
            if masterThread then return end
            masterThread = task.spawn(function()
                while _G.MasterFarm do
                    local target = getNearestTarget()
                    if not target then task.wait(0.5) continue end
                    if flyTo(target) then
                        lockNode(target)
                        lockPlayerToNode(target)
                        while _G.MasterFarm and not isDead(target) do silentAttack(target) task.wait() end
                        unlockPlayerFromNode()
                        unlockNode()
                        setIgnore(target)
                    else
                        if isDead(target) then setIgnore(target) end
                    end
                end
                unlockPlayerFromNode()
                unlockNode()
                masterThread = nil
                print("🛑 Auto Farm Stopped")
            end)
        else
            _G.MasterFarm = false
            unlockPlayerFromNode()
            unlockNode()
            masterThread = nil
        end
    end
})

-- Node Status Label
local nodeStatusLabel = MainTab:CreateLabel("⚪ Node: Scanning...")

local NODE_INFO = {
    { key = "AutoFarmFood", folder = "Food",      node = "LargeFoodNode",     icon = "🌿" },
    { key = "AutoFarmOre",  folder = "Resources", node = "LargeResourceNode", icon = "⛏️" },
    { key = "AutoFarmBone", folder = "BoneMeal",  node = "BoneMealNode",      icon = "🦴" },
}

task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local nodesRoot = workspace:FindFirstChild("Interactions")
                and workspace.Interactions:FindFirstChild("Nodes")
            if not nodesRoot then
                nodeStatusLabel:Set("❌ Nodes folder not found")
                return
            end
            local parts = {}
            for _, info in ipairs(NODE_INFO) do
                local folder = nodesRoot:FindFirstChild(info.folder)
                local count  = 0
                if folder then
                    for _, node in pairs(folder:GetChildren()) do
                        if node.Name == info.node and not isDead(node) then count += 1 end
                    end
                end
                table.insert(parts, info.icon .. " " .. (count > 0 and "x"..count or "—"))
            end
            local statusText = table.concat(parts, "  |  ")
            nodeStatusLabel:Set((_G.MasterFarm and "🟢 " or "⚪ ") .. statusText)
        end)
    end
end)

-- ============================================================
-- CHEST SYSTEM
-- ============================================================
MainTab:CreateSection("💰 Auto Farm Chest")

local CHEST_OPTIONS = {
    ["Valentines Chest ❤️"] = "FarmValentines",
    ["Silver Chest 🥈"]     = "FarmSilver",
    ["Bronze Chest 🥉"]     = "FarmBronze",
    ["Gold Chest 🥇"]       = "FarmGold",
}

MainTab:CreateDropdown({
    Name            = "Select Chest Type",
    Options         = {"Valentines Chest ❤️", "Silver Chest 🥈", "Bronze Chest 🥉", "Gold Chest 🥇"},
    CurrentOption   = {},
    MultipleOptions = true,
    Callback        = function(selected)
        _G.FarmValentines = false _G.FarmSilver = false
        _G.FarmBronze     = false _G.FarmGold   = false
        for _, name in ipairs(selected) do
            local key = CHEST_OPTIONS[name]
            if key then _G[key] = true end
        end
    end
})

MainTab:CreateToggle({
    Name         = "🚀 Start/Stop Auto Chest Farm",
    CurrentValue = false,
    Callback     = function(V)
        if V then
            stopChestFarm()
            LootedInstances = {}
            local hasAny = _G.FarmValentines or _G.FarmSilver or _G.FarmBronze or _G.FarmGold
            if not hasAny then
                _G.FarmValentines = true _G.FarmSilver = true
                _G.FarmBronze = true     _G.FarmGold   = true
            end
            _G.AutoFarm = true
            startChestFarm()
        else
            stopChestFarm()
        end
    end
})

-- Chest Status Label
local chestStatusLabel = MainTab:CreateLabel("⚪ Chest: Scanning...")

-- ⚠️ Warning
MainTab:CreateLabel("⚠️ Chests do not spawn fixed! You must walk to spawn zones for them to appear.")

local CHEST_NAMES = {"ValentinesChest", "SilverChest", "BronzeChest", "GoldChest"}
local CHEST_ICONS = {
    ValentinesChest = "❤️", SilverChest = "🥈",
    BronzeChest     = "🥉", GoldChest   = "🥇",
}

task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local treasure = workspace:FindFirstChild("Interactions")
                and workspace.Interactions:FindFirstChild("Nodes")
                and workspace.Interactions.Nodes:FindFirstChild("Treasure")
            if not treasure then
                chestStatusLabel:Set("❌ Treasure folder not found")
                return
            end
            local counts = {}
            for _, name in ipairs(CHEST_NAMES) do counts[name] = 0 end
            for _, folder in pairs(treasure:GetChildren()) do
                for _, chest in pairs(folder:GetChildren()) do
                    local hrp    = chest:FindFirstChild("HumanoidRootPart")
                    local health = hrp and hrp:FindFirstChild("Health")
                    local dead   = hrp and hrp:FindFirstChild("Dead")
                    local alive  = health and health.Value > 0 and (not dead or not dead.Value)
                    if alive and counts[chest.Name] ~= nil then
                        counts[chest.Name] += 1
                    end
                end
            end
            local parts = {}
            for _, name in ipairs(CHEST_NAMES) do
                local icon = CHEST_ICONS[name] or "📦"
                table.insert(parts, icon .. " " .. (counts[name] > 0 and "x"..counts[name] or "—"))
            end
            local statusText = table.concat(parts, "  |  ")
            chestStatusLabel:Set((_G.AutoFarm and "🟢 " or "⚪ ") .. statusText)
        end)
    end
end)

-- ============================================================
-- EGG SYSTEM
-- ============================================================
MainTab:CreateSection("🥚 Collect Eggs")

MainTab:CreateToggle({ Name = "Auto Collect Egg", CurrentValue = false, Callback = function(V)
    _G.AutoCollectEgg = V
    if V then
        startEggFarm()
    else
        unlockEggNode()
        eggThread = nil
        setEggStatus("⚪ Egg: Off")
    end
end })

eggStatusLabel = MainTab:CreateLabel("⚪ Egg: Off")

-- Background scanner: แสดงจำนวน ActiveNode แม้ตอนระบบปิดอยู่
task.spawn(function()
    while true do
        task.wait(2)
        if not _G.AutoCollectEgg then
            pcall(function()
                local eggNodes    = workspace.Interactions.Nodes.Eggs
                local activeNodes = eggNodes.ActiveNodes:GetChildren()
                local total       = #activeNodes
                setEggStatus("⚪ Egg: Off  |  Nodes Found: " .. total)
            end)
        end
    end
end)

-- ============================================================
-- DRAGON CARE
-- ============================================================
MainTab:CreateSection("🐉 Dragon Care & Bond")
MainTab:CreateToggle({ Name = "Smart Auto Feed (Any Food)", CurrentValue = false, Callback = function(V)
    _G.AutoFeed = V
    if V then startFeedThread() end
end })
MainTab:CreateToggle({ Name = "Smart Auto Bond (100% Auto)", CurrentValue = false, Callback = function(V)
    _G.AutoBond = V
    if V then startBondThread() end
end })





-- ============================================================
-- MISC & PROTECTION TAB
-- ============================================================
local TabMisc = Window:CreateTab("⚙️ Misc", 4483345998)

-- Local Testing Variables (Isolated from Misc.lua _G)

local TestEnableSpeedHack = false
local TestSpeedPower = 5
_G.InfJump = false
_G.AntiAFK = true
_G.Noclip = false
_G._particleOff = false

-- Dragon Override Variables
local TestEnableDragonBoost = false
local DragonBoostSpeed = 150 -- Default dash speed
local TestEnableInfFire = false
local dragonDefaultStats = {}

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================
local function getActiveDragonModel()
    local char = workspace:FindFirstChild("Characters")
        and workspace.Characters:FindFirstChild(LocalPlayer.Name)
    if char and char:FindFirstChild("Dragons") then
        return char.Dragons:FindFirstChild("1") or char.Dragons:GetChildren()[1]
    end
    local c = LocalPlayer.Character
    if c and c:FindFirstChild("Dragons") then
        return c.Dragons:GetChildren()[1]
    end
    return nil
end

local function getRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    local dragonModel = getActiveDragonModel()
    return (dragonModel and dragonModel:FindFirstChild("HumanoidRootPart")) or char:FindFirstChild("HumanoidRootPart")
end

local function restoreAllCollision()
    pcall(function()
        local char   = LocalPlayer.Character
        local dragon = getActiveDragonModel()
        if char then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = true end
            end
        end
        if dragon then
            for _, v in pairs(dragon:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = true end
            end
        end
    end)
end

-- ============================================================
-- MOVEMENT SECTION
-- ============================================================
TabMisc:CreateSection("Movement Abilities")

TabMisc:CreateToggle({
    Name = "Enable Speed Hack (CFrame)", CurrentValue = false,
    Callback = function(Value)
        TestEnableSpeedHack = Value
    end
})

TabMisc:CreateSlider({ 
    Name = "CFrame Speed Limit", Range = {1, 20}, Increment = 1, CurrentValue = 16, 
    Callback = function(Value)
        TestSpeedPower = Value
    end
})

TabMisc:CreateToggle({
    Name = "Infinite Jump", CurrentValue = false,
    Callback = function(Value)
        _G.InfJump = Value
    end 
})

game:GetService('UserInputService').JumpRequest:Connect(function()
    if _G.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

TabMisc:CreateToggle({ 
    Name = "Universal Safe Noclip", CurrentValue = false, 
    Callback = function(Value) 
        _G.Noclip = Value
        if not Value then restoreAllCollision() end
    end 
})

TabMisc:CreateSection("Dragon Abilities")

TabMisc:CreateToggle({
    Name = "[Dragon Boost] Enable Mega Dash", CurrentValue = false,
    Callback = function(Value)
        TestEnableDragonBoost = Value
        if not Value then
            -- Restore defaults when disabled
            local dragon = getActiveDragonModel()
            if dragon and dragonDefaultStats[dragon.Name] then
                local mStats = dragon:FindFirstChild("Data") and dragon.Data:FindFirstChild("MovementStats")
                if mStats then
                    for statName, defaultVal in pairs(dragonDefaultStats[dragon.Name]) do
                        if mStats:FindFirstChild(statName) then
                            mStats[statName].Value = defaultVal
                        end
                    end
                end
            end
        end
    end
})

TabMisc:CreateSlider({ 
    Name = "Mega Dash Power/Distance", Range = {100, 1000}, Increment = 50, CurrentValue = 100, 
    Callback = function(Value)
        DragonBoostSpeed = Value
    end
})

TabMisc:CreateToggle({
    Name = "[Dragon Boost] Infinite Fire Breath", CurrentValue = false,
    Callback = function(Value)
        TestEnableInfFire = Value
    end
})

-- ============================================================
-- CORE MOVEMENT LOOP (RunService Handle)
-- ============================================================
game:GetService("RunService").Stepped:Connect(function()
    -- 1. Noclip
    if _G.Noclip then
        pcall(function()
            local char   = LocalPlayer.Character
            local dragon = getActiveDragonModel()
            local root   = getRoot()
            local isNearGround = false
            if root then
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {char, dragon}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                local ray = workspace:Raycast(root.Position, Vector3.new(0, -6, 0), rayParams)
                if ray then isNearGround = true end
            end
            if char then
                for _, v in pairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then
                        if v.Name == "HumanoidRootPart" and isNearGround then v.CanCollide = true
                        else v.CanCollide = false end
                    end
                end
            end
            if dragon then
                for _, v in pairs(dragon:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end)
    end

    -- 2. Speed Hack (CFrame) - Isolated Test
    if TestEnableSpeedHack then
        pcall(function()
            local root = getRoot()
            local hum  = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if root and hum and hum.MoveDirection.Magnitude > 0 then
                root.CFrame = root.CFrame + (hum.MoveDirection * (TestSpeedPower / 10))
            end
        end)
    end
    
    -- 3. Dragon Mega Dash Distance Adjustments
    if TestEnableDragonBoost then
        pcall(function()
            local dragon = getActiveDragonModel()
            if dragon then
                local data = dragon:FindFirstChild("Data")
                if data then
                    local movementStats = data:FindFirstChild("MovementStats")
                    if movementStats then
                        -- Save Defaults if not saved yet
                        if not dragonDefaultStats[dragon.Name] then
                            dragonDefaultStats[dragon.Name] = {}
                            for _, stat in ipairs(movementStats:GetChildren()) do
                                if stat:IsA("NumberValue") or stat:IsA("IntValue") then
                                    dragonDefaultStats[dragon.Name][stat.Name] = stat.Value
                                end
                            end
                        end
                        
                        -- Set Custom Dash Distance/Force based on Slider
                        if movementStats:FindFirstChild("DashForce") then 
                            movementStats.DashForce.Value = DragonBoostSpeed / 10 -- Example: slider 150 = force 15
                        end
                        if movementStats:FindFirstChild("BoostSpeedMultiplier") then 
                            movementStats.BoostSpeedMultiplier.Value = DragonBoostSpeed
                        end
                        if movementStats:FindFirstChild("BoostSpeedAdd") then 
                            movementStats.BoostSpeedAdd.Value = DragonBoostSpeed / 2
                        end
                    end
                end
            end
        end)
    end
    
    -- 4. Infinite Fire Breath
    if TestEnableInfFire then
        pcall(function()
            local dragon = getActiveDragonModel()
            if dragon then
                local data = dragon:FindFirstChild("Data")
                if data then
                    local combatStats = data:FindFirstChild("CombatStats")
                    if combatStats and combatStats:FindFirstChild("BreathCapacity") then
                        local fireFuel = data:FindFirstChild("Fire") and data.Fire:FindFirstChild("BreathFuel")
                        if fireFuel then
                            fireFuel.Value = combatStats.BreathCapacity.Value
                        end
                    end
                end
            end
        end)
    end
end)

TabMisc:CreateToggle({ 
    Name = "🛡️ Semi-God Mode (Hitbox Shield)", CurrentValue = false, 
    Callback = function(Value)
        _G.GodMode = Value
        if Value then
            Rayfield:Notify({Title = "God Mode Enabled", Content = "Attempting to spoof health and shield hitboxes.", Duration = 3})
            task.spawn(function()
                while _G.GodMode do
                    pcall(function()
                        local char = game.Players.LocalPlayer.Character
                        if char then
                            local hum = char:FindFirstChild("Humanoid")
                            if hum then
                                hum.Health = hum.MaxHealth
                            end
                        end
                    end)
                    task.wait(1)
                end
            end)
        end
    end 
})

-- ============================================================
-- UTILITY SECTION
-- ============================================================
TabMisc:CreateSection("General Utility")

TabMisc:CreateToggle({ 
    Name = "Anti-AFK", CurrentValue = true, 
    Callback = function(Value)
        _G.AntiAFK = Value
        if Value then
            Rayfield:Notify({Title = "Anti-AFK Enabled", Content = "You will not be disconnected for idling.", Duration = 3})
        end
    end 
})



-- Anti-AFK Logic
LocalPlayer.Idled:Connect(function()
    if _G.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)



-- ============================================================
-- PERFORMANCE SECTION
-- ============================================================
TabMisc:CreateSection("Performance Optimization")

TabMisc:CreateToggle({ 
    Name = "Potato Mode / Low GFX", CurrentValue = false, 
    Callback = function(V)
        task.spawn(function()
            pcall(function()
                Lighting.GlobalShadows = not V
                Lighting.FogEnd = V and 9e9 or 1000
                Lighting.FogStart = V and 9e9 or 0
                settings().Rendering.QualityLevel = V and 1 or 5
                
                for _, fx in pairs(Lighting:GetChildren()) do
                    if fx:IsA("BloomEffect") or fx:IsA("BlurEffect") or fx:IsA("SunRaysEffect")
                    or fx:IsA("DepthOfFieldEffect") or fx:IsA("ColorCorrectionEffect") then
                        fx.Enabled = not V
                    end
                end
                
                _G._particleOff = V
                local count = 0
                for _, v in pairs(game:GetDescendants()) do
                    if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
                        v.Enabled = not V
                        if V then v.Rate = 0 end
                    elseif v:IsA("BasePart") and not v:IsParentOf(LocalPlayer.Character) then
                        if V then 
                            v.Material = Enum.Material.SmoothPlastic 
                            v.CastShadow = false 
                        end
                    elseif v:IsA("Decal") or v:IsA("Texture") then
                        v.Transparency = V and 1 or 0
                    end
                    count += 1
                    if count % 100 == 0 then task.wait() end
                end
                
                if V then
                    game.DescendantAdded:Connect(function(d)
                        if not _G._particleOff then return end
                        pcall(function()
                            if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then
                                d.Enabled = false 
                                d.Rate = 0
                            elseif d:IsA("BasePart") and not d:IsParentOf(LocalPlayer.Character) then
                                d.Material = Enum.Material.SmoothPlastic 
                                d.CastShadow = false
                            end
                        end)
                    end)
                end
            end)
        end)
    end 
})

-- ============================================================
-- SERVER CONTROL SECTION
-- ============================================================
TabMisc:CreateSection("Server Management")

TabMisc:CreateButton({ 
    Name = "🔄 Rejoin Server", 
    Callback = function()
        Rayfield:Notify({Title = "Rejoining...", Content = "Connecting to the same server.", Duration = 3})
        if #Players:GetPlayers() <= 1 then
            LocalPlayer:Kick("Rejoining...")
            task.wait()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end 
})

TabMisc:CreateButton({ 
    Name = "🌐 Server Hop (Smaller Server)", 
    Callback = function()
        Rayfield:Notify({Title = "Server Hop", Content = "Finding a new server...", Duration = 3})
        
        local function Hop()
            -- HTTP Request for different executors
            local HttpReq = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
            if HttpReq then
                local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
                local response = HttpReq({Url = url, Method = "GET"})
                
                if response and response.Body then
                    local decoded = HttpService:JSONDecode(response.Body)
                    if decoded and decoded.data then
                        local servers = {}
                        for _, v in pairs(decoded.data) do
                            if type(v) == "table" and v.playing and v.maxPlayers and v.playing < v.maxPlayers and v.id ~= game.JobId then
                                table.insert(servers, v.id)
                            end
                        end
                        if #servers > 0 then
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
                            return
                        end
                    end
                end
            end
            Rayfield:Notify({Title = "Failed", Content = "Could not find a valid server to hop to.", Duration = 3})
        end
        
        task.spawn(Hop)
    end 
})


-- ============================================================
-- STORE & SPIN SYSTEM
-- ============================================================
local ShopTab = Window:CreateTab("🛒 Store & Spin", 4483362458)

-- 🎰 SPIN WHEEL SECTION
ShopTab:CreateSection("🎰 Spin Wheel System")
local SpinRemote = Remotes:FindFirstChild("SpinWheelRemote")
local ClaimRemote = Remotes:FindFirstChild("ClaimWheelRemote")

ShopTab:CreateButton({
    Name = "🎡 Spin Wheel (Spin + Auto Claim)",
    Callback = function()
        if SpinRemote then
            safeTrigger(SpinRemote)
            task.wait(1)
            if ClaimRemote then
                safeTrigger(ClaimRemote)
            end
            Rayfield:Notify({Title = "Spin & Claim", Content = "Spin and claim executed!", Duration = 3})
        else
            Rayfield:Notify({Title = "Error", Content = "Spin remote not found!", Duration = 3})
        end
    end,
})

-- 🛍️ GENERAL STORE SECTION (35 ITEMS)
ShopTab:CreateSection("🧪 Potions (14 Items)")
local potions = {
    {Name = "Legacy Potion", ID = "LegacyPotion", Price = "40k"},
    {Name = "Advanced Potion", ID = "AdvancedPotion", Price = "40k"},
    {Name = "Secondary Material", ID = "SecondaryMaterialPotion", Price = "7.5k"},
    {Name = "Potion Of Tracking", ID = "PotionOfTracking", Price = "10k"},
    {Name = "Arctic Material", ID = "ArcticMaterialPotion", Price = "125k"},
    {Name = "Basic Personality", ID = "BasicPersonalityPotion", Price = "7.5k"},
    {Name = "Tertiary Color", ID = "TertiaryColorPotion", Price = "7.5k"},
    {Name = "Ash Material", ID = "AshMaterialPotion", Price = "100k"},
    {Name = "Color Shuffle", ID = "ColorShufflePotion", Price = "4k"},
    {Name = "Potion Of Combat", ID = "PotionOfCombat", Price = "10k"},
    {Name = "Arid Material", ID = "AridMaterialPotion", Price = "75k"},
    {Name = "Gender Potion", ID = "GenderPotion", Price = "15k"},
    {Name = "Personality Potion", ID = "PersonalityPotion", Price = "15k"},
    {Name = "Mutation Potion", ID = "MutationPotion", Price = "150k"}
}
for _, p in ipairs(potions) do
    ShopTab:CreateButton({
        Name = "🛒 " .. p.Name .. " (" .. p.Price .. ")",
        Callback = function() SmartBuy(p.ID, 1) end,
    })
end

ShopTab:CreateSection("🍎 Food (6 Items)")
local foods = {
    {Name = "Apple", ID = "Apple", Price = "10"},
    {Name = "Corn", ID = "Corn", Price = "36"},
    {Name = "Lemon", ID = "Lemon", Price = "48"},
    {Name = "Carrot", ID = "Carrot", Price = "15"},
    {Name = "Pear", ID = "Pear", Price = "36"},
    {Name = "Strawberry", ID = "Strawberry", Price = "48"}
}
for _, f in ipairs(foods) do
    ShopTab:CreateButton({
        Name = "🛒 " .. f.Name .. " (" .. f.Price .. ")",
        Callback = function() SmartBuy(f.ID, 1) end,
    })
end

ShopTab:CreateSection("🏥 Healing (6 Items)")
local healing = {
    {Name = "Bandages", ID = "Bandages", Price = "35"},
    {Name = "Basic Healing", ID = "BasicHealingPotion", Price = "500"},
    {Name = "Revival Heart", ID = "RevivalHeart", Price = "30"},
    {Name = "Magical Bandages", ID = "MagicalBandages", Price = "85"},
    {Name = "Dragonscale Bandages", ID = "DragonscaleBandages", Price = "200"},
    {Name = "Golden Revival Heart", ID = "GoldenRevivalHeart", Price = "70"}
}
for _, h in ipairs(healing) do
    ShopTab:CreateButton({
        Name = "🛒 " .. h.Name .. " (" .. h.Price .. ")",
        Callback = function() SmartBuy(h.ID, 1) end,
    })
end

ShopTab:CreateSection("🪵 Resources (6 Items)")
local resources = {
    {Name = "Wood", ID = "Wood", Price = "10"},
    {Name = "Leaf", ID = "Leaf", Price = "2"},
    {Name = "Copper", ID = "Copper", Price = "100"},
    {Name = "Stone", ID = "Stone", Price = "4"},
    {Name = "Honeycomb", ID = "Honeycomb", Price = "200"},
    {Name = "Petal", ID = "Petal", Price = "20"}
}
for _, r in ipairs(resources) do
    ShopTab:CreateButton({
        Name = "🛒 " .. r.Name .. " (" .. r.Price .. ")",
        Callback = function() SmartBuy(r.ID, 1) end,
    })
end

ShopTab:CreateSection("🛠️ Tools (3 Items)")
local tools = {
    {Name = "Bath Set (Soap)", ID = "ItemSetDirty", Price = "1000"},
    {Name = "Brush", ID = "Brush", Price = "500"},
    {Name = "Teddy Bear", ID = "TeddyBear", Price = "500"}
}
for _, t in ipairs(tools) do
    ShopTab:CreateButton({
        Name = "🛒 " .. t.Name .. " (" .. t.Price .. ")",
        Callback = function() SmartBuy(t.ID, 1) end,
    })
end

-- ============================================================
-- VISUALS (ESP) TAB
-- ============================================================
local success_esp, err_esp = pcall(function()
    local TabVisuals = Window:CreateTab("👁️ Visuals", 4483345998)
    TabVisuals:CreateSection("Master Control")
    TabVisuals:CreateToggle({ Name = "Enable Master ESP", CurrentValue = false, Callback = function(v) ESP.Enabled = v end })

    TabVisuals:CreateSection("Entity Selection")
    TabVisuals:CreateDropdown({
        Name = "Select Targets",
        Options = {"Players 👤", "Monsters 👹", "Eggs 🥚", "Food Nodes 🌿", "Treasure Chests 💰"},
        CurrentOption = {},
        MultipleOptions = true,
        Callback = function(selected)
            ESP.Settings.Players = table.find(selected, "Players 👤") ~= nil
            ESP.Settings.Monsters = table.find(selected, "Monsters 👹") ~= nil
            ESP.Settings.Eggs = table.find(selected, "Eggs 🥚") ~= nil
            ESP.Settings.Food = table.find(selected, "Food Nodes 🌿") ~= nil
            ESP.Settings.Chests = table.find(selected, "Treasure Chests 💰") ~= nil
        end,
    })

    TabVisuals:CreateSection("ESP Modes")
    TabVisuals:CreateToggle({ Name = "Draw Tracers (Lines)", CurrentValue = false, Callback = function(v) ESP.Settings.ShowTracers = v end })
    TabVisuals:CreateToggle({ Name = "Draw 2D Boxes", CurrentValue = false, Callback = function(v) ESP.Settings.ShowBoxes = v end })
    TabVisuals:CreateToggle({ Name = "Show 3D Highlights", CurrentValue = true, Callback = function(v) ESP.Settings.ShowHighlights = v end })
    TabVisuals:CreateToggle({ Name = "Show Names", CurrentValue = true, Callback = function(v) ESP.Settings.ShowNames = v end })
    TabVisuals:CreateToggle({ Name = "Show Distance", CurrentValue = true, Callback = function(v) ESP.Settings.ShowDistance = v end })

    TabVisuals:CreateSection("Customization")
    TabVisuals:CreateSlider({ Name = "Text Size", Range = {10, 32}, Increment = 1, Suffix = "px", CurrentValue = 14, Callback = function(v) ESP.Settings.TextSize = v end })
    TabVisuals:CreateSlider({ Name = "Tracer/Box Thickness", Range = {1, 5}, Increment = 1, Suffix = "px", CurrentValue = 1, Callback = function(v) ESP.Settings.TracerThickness = v; ESP.Settings.BoxThickness = v end })
    TabVisuals:CreateSlider({ Name = "Max Render Distance", Range = {500, 10000}, Increment = 100, Suffix = " Studs", CurrentValue = 10000, Callback = function(v) ESP.Settings.MaxDistance = v end })

    TabVisuals:CreateSection("Color Settings")
    TabVisuals:CreateColorPicker({ Name = "Player Color", Color = ESP.Config.Players.Color, Flag = "ColorPlayers", Callback = function(v) ESP.Config.Players.Color = v end })
    TabVisuals:CreateColorPicker({ Name = "Monster Color", Color = ESP.Config.Monsters.Color, Flag = "ColorMonsters", Callback = function(v) ESP.Config.Monsters.Color = v end })
    TabVisuals:CreateColorPicker({ Name = "Egg Color", Color = ESP.Config.Eggs.Color, Flag = "ColorEggs", Callback = function(v) ESP.Config.Eggs.Color = v end })
    TabVisuals:CreateColorPicker({ Name = "Food Color", Color = ESP.Config.Food.Color, Flag = "ColorFood", Callback = function(v) ESP.Config.Food.Color = v end })
    TabVisuals:CreateColorPicker({ Name = "Chest Color", Color = ESP.Config.Chests.Color, Flag = "ColorChests", Callback = function(v) ESP.Config.Chests.Color = v end })
end)
if not success_esp then
    Rayfield:Notify({
        Title = "ESP UI Error",
        Content = tostring(err_esp),
        Duration = 30,
        Image = nil,
    })
end

-- ============================================================
-- SETTINGS TAB
-- ============================================================
local SettingTab = Window:CreateTab("Settings", 4483345998)
SettingTab:CreateSection("General Settings")
SettingTab:CreateToggle({ Name = "Auto Collect Drops", CurrentValue = true, Callback = function(V) _G.AutoCollect = V end })
SettingTab:CreateSlider({ Name = "Flight Speed (Farm)",  Range = {50, 650}, CurrentValue = 280, Callback = function(V) _G.FlySpeed      = V end })
SettingTab:CreateSlider({ Name = "Flight Speed (Chest)", Range = {50, 650}, CurrentValue = 200, Callback = function(V) _G.ChestFlySpeed = V end })
SettingTab:CreateSlider({ Name = "Safe Warp Distance",   Range = {10, 650}, CurrentValue = 100, Callback = function(V) _G.WarpDistance  = V end })
SettingTab:CreateSlider({ Name = "Monster Fly Speed",    Range = {50, 1000}, CurrentValue = 280, Callback = function(V) _G.MonsterFlySpeed = V end })

-- End

print("✅ Arm Hub V50 + Chest Hunter — พร้อมใช้งานครับ!")