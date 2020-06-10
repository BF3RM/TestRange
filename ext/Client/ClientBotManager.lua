class "ClientBotManager"

function ClientBotManager:__init()
    print("Initializing ClientBotManager")
end


-- Print current position and yaw/pitch
function ClientBotManager:OnGetPlayerPos()
    local myPlayer = PlayerManager:GetLocalPlayer()
    local myTrans = myPlayer.soldier.transform.trans
    local myYaw = myPlayer.input.authoritativeAimingYaw
    local myPitch = myPlayer.input.authoritativeAimingPitch
    return '(X, Y, Z)= '..myTrans.x..', '..myTrans.y..', '..myTrans.z..' Yaw='..myYaw..' Pitch='..myPitch
end


-- Spawn a bot at given coordinates
function ClientBotManager:OnSpawnAtPosition(args)
    -- Print usage instructions if we got an invalid number of arguments
    if #args < 3 then
        return 'Usage: _testrange.spawnAtPosition_ <*X*> <*Y*> <*Z*> [*team*] [*squad*] [*name*]'
    end

    -- Parse and validate the arguments
    local x = tonumber(args[1])
    local y = tonumber(args[2])
    local z = tonumber(args[3])
    if x == nil or y == nil or z == nil then
        return 'Error: **Spawn coordinates must be numeric.**'
    end

    -- Get the optional arguments
    local team = args[4]
    local squad = args[5]
    local name = args[6]
    -- If the name is empty, treat it as nil
    if name ~= nil and #name == 0 then
        name = nil
    end

    -- Setup bot LinearTransform
    local botTransform = LinearTransform()
    botTransform.trans = Vec3(x, y, z)

    -- Notify server so it can spawn a bot.
    NetEvents:SendLocal('Bots:Spawn', botTransform, team, squad, name)
end


-- Spawn a bot at a given distance/height from the player
function ClientBotManager:OnSpawnAtDistance(args)
    -- Print usage instructions if we got an invalid number of arguments
    if  #args < 1 then
        return 'Usage: _testrange.spawnAtDistance_ <*distance*> [*height*] [*team*] [*squad*] [*name*]'
    end

    -- Parse and validate the arguments.
    if tonumber(args[1]) == nil then
        return 'Error: **Distance must be numeric.**'
    end
    if args[2] ~= nil and tonumber(args[2]) == nil then
        return 'Error: **Height must be numeric.**'
    end

    local distance = tonumber(args[1])
    local height = tonumber(args[2]) or 2  -- Use height=2 as default
    local team = args[3]
    local squad = args[4]
    local name = args[5]
    -- If the name is empty, treat it as nil
    if name ~= nil and #name == 0 then
        name = nil
    end

    -- Get local player
    local player = PlayerManager:GetLocalPlayer()
    -- Player has not spawned
    if player.soldier == nil then
        return
    end

    -- Notify the server it needs to spawn a bot
    local playerTransform = player.soldier.transform
    local botTransform = self:CalculateBotTransform(playerTransform, distance, height)
    NetEvents:SendLocal('Bots:Spawn', botTransform, team, squad, name)
end


-- Spawn bots in a shooting range-like pattern, spacing them sideways.
function ClientBotManager:OnSpawnRange(args)
    -- Print usage instructions if we got an invalid number of arguments.
    if #args < 3 then
        return 'Usage: _testrange.spawnRange <*minDistance*> <*maxDistance*> <*delta*> [*lateralDistance*] [*team*]'
    end

    -- Validate and parse arguments
    local minDistance = tonumber(args[1])
    local maxDistance = tonumber(args[2])
    local delta = tonumber(args[3])
    local lateralDistance = tonumber(args[4]) or 1 -- Default lateralDistance to 1 meter
    local team = args[5]
    if minDistance == nil or maxDistance == nil or delta == nil then
        return 'Error: **Distances must be numeric.**'
    end

    -- Get local player
    local player = PlayerManager:GetLocalPlayer()
    -- Player has not spawned
    if player.soldier == nil then
        return
    end

    local playerTransform = player.soldier.transform
    local currentDistance = minDistance
    local currentLateralDistance = 0
    local height = 2
    while currentDistance <= maxDistance do
        local botTransform = self:CalculateBotTransform(playerTransform, currentDistance, height)
        local sidewaysRelativeTrans = playerTransform.left * currentLateralDistance * (-1)  -- Shifts to the right
        botTransform.trans = botTransform.trans + sidewaysRelativeTrans
        NetEvents:SendLocal('Bots:Spawn', botTransform, team)
        currentDistance = currentDistance + delta
        currentLateralDistance = currentLateralDistance + lateralDistance
    end
end


-- Spawns bots in circle of given radius and at a set distance from the player.
function ClientBotManager:OnSpawnCircle(args)
    -- Print usage instructions if we got an invalid number of arguments.
    if #args < 1 then
        return 'Usage: _testrange.spawnCircle <*radius*> [*distance*] [*team*]'
    end

    -- Validate and parse arguments
    local radius = tonumber(args[1])
    local distance = tonumber(args[2]) or 0
    local team = args[3]
    if radius == nil then
        return 'Error: **Radius must be numeric.**'
    end
    if distance == nil then
        return 'Error: **Distance must be numeric.**'
    end

    -- Get local player
    local player = PlayerManager:GetLocalPlayer()
    -- Player has not spawned
    if player.soldier == nil then
        return
    end

    local playerTransform = player.soldier.transform
    local circleCenterTrans = self:CalculateBotTransform(playerTransform, distance)
    local currentAngle = 0
    local height = 2
    while currentAngle < (2 * math.pi) do
        local botTransform = self:CalculateBotTransform(circleCenterTrans, radius, height, currentAngle)
        NetEvents:SendLocal('Bots:Spawn', botTransform, team)
        currentAngle = currentAngle + math.pi / 4
    end
end


-- Kick a bot using its name
function ClientBotManager:OnKick(args)
    -- Print usage instructions if we got an invalid number of arguments.
    if #args ~= 1 then
        return 'Usage: _testrange.kick_ <*name*>'
    end

    -- Parse and validate arguments.
    local name = args[1]

    if #name == 0 then
        return 'Error: **Name must be at least 1 character long.**'
    end

    -- Notify server so it can kick the bot.
    NetEvents:SendLocal('Bots:Kick', name)
end


-- Kick all the bots
function ClientBotManager:OnKickAll()
    -- Notify server so it can kick all bots.
    NetEvents:SendLocal('Bots:KickAll')
end


-- Calculate the bot's transform based on the distance, height and angle relative to a given transform.
function ClientBotManager:CalculateBotTransform(relativeTransform, distance, height, angle)
    height = height or 0
    local lookRelativeTrans
    if angle == nil then
        local localPlayer = PlayerManager:GetLocalPlayer()
        -- Player has not spawned
        if localPlayer.soldier == nil then
            return
        end
        angle = localPlayer.input.authoritativeAimingYaw
        lookRelativeTrans = relativeTransform.forward * distance + relativeTransform.up * height
    else
        lookRelativeTrans = Vec3(-math.sin(angle) * distance, height, math.cos(angle) * distance)
    end
    local botTransform = relativeTransform:Clone()
    botTransform.forward = botTransform.forward * (-1)
    botTransform.trans = botTransform.trans + lookRelativeTrans
    return botTransform
end


-- Get player shortcuts
function ClientBotManager:OnUpdateInput(p_Cache, p_DeltaTime)
    if InputManager:IsKeyDown(InputDeviceKeys.IDK_LeftCtrl) and InputManager:WentKeyDown(InputDeviceKeys.IDK_X) then
        self:OnKickAll()
    end

    if InputManager:IsKeyDown(InputDeviceKeys.IDK_LeftCtrl) and InputManager:WentKeyDown(InputDeviceKeys.IDK_F1) then
        local args = {}
        args[1] = "10"
        self:OnSpawnAtDistance(args)
    end

    if InputManager:IsKeyDown(InputDeviceKeys.IDK_LeftCtrl) and InputManager:WentKeyDown(InputDeviceKeys.IDK_F2) then
        local args = {}
        args[1] = "10"
        args[2] = "100"
        args[3] = "10"
        args[4] = "2"
        self:OnSpawnRange(args)
    end

    if InputManager:IsKeyDown(InputDeviceKeys.IDK_LeftCtrl) and InputManager:WentKeyDown(InputDeviceKeys.IDK_F3) then
        local args = {}
        args[1] = "50"
        args[2] = "1000"
        args[3] = "50"
        args[4] = "2"
        self:OnSpawnRange(args)
    end
end


-- Singleton
if g_ClientBotManager == nil then
    g_ClientBotManager = ClientBotManager()
end

return g_ClientBotManager