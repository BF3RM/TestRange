class "ServerBotManager"

local m_botSpawner = require "BotSpawner"


function ServerBotManager:__init()
	print("Initializing ServerBotManager")
	self:RegisterVars()
	self:RegisterEvents()
end


function ServerBotManager:RegisterVars()
	self.botCount = 0
	self.elapsedPitchTime = 0
	self.elapsedYawTime = 0
end


function ServerBotManager:RegisterEvents()
	NetEvents:Subscribe('Bots:Spawn', self, self.OnBotSpawn)
	NetEvents:Subscribe('Bots:SpawnAtDistance', self, self.OnBotSpawnAtDistance)
	NetEvents:Subscribe('Bots:Kick', self, self.OnKick)
	NetEvents:Subscribe('Bots:KickAll', self, self.OnKickAll)
end


-- These NetEvents are triggered by client-side console commands.
-- Refer to the client __init__.lua script for more information.
function ServerBotManager:OnBotSpawn(player, transform, team, squad, name)
	local squadId = SquadId[squad] or SquadId['SquadNone']  -- Use 'SquadNone' as default
	name = name or ('Bot'..(self.botCount + 1))             -- Use 'BotN' as default, where N is a number

	-- Use the enemy team as default
	local teamId = TeamId[team]
	if teamId == nil then
		if player.teamId == TeamId['Team1'] then
			teamId = TeamId['Team2']
		else
			teamId = TeamId['Team1']
		end
	end

	local existingPlayer = PlayerManager:GetPlayerByName(name)
	local bot = nil

	if existingPlayer ~= nil then
		-- If a player with this name exists and it's not a bot then error out.
		if not m_botSpawner:IsBot(existingPlayer) then
			return
		end

		-- If it is a bot, then store it and we'll call the spawn function for it after.
		-- This will respawn the bot (killing it if it's already alive).
		bot = existingPlayer

		-- We should also update its team and squad, just in case.
		bot.teamId = teamId
		bot.squadId = squadId
	else
		-- Otherwise, create a new bot. This returns a new Player object.
		bot = m_botSpawner:CreateBot(name, teamId, squadId, player.id)
	end

	-- Get the default MpSoldier blueprint and the US assault kit.
	local soldierBlueprint = ResourceManager:SearchForInstanceByGuid(Guid('261E43BF-259B-41D2-BF3B-9AE4DDA96AD2'))
	local soldierKit = ResourceManager:SearchForInstanceByGuid(Guid('A15EE431-88B8-4B35-B69A-985CEA934855'))

	-- And then spawn the bot. This will create and return a new SoldierEntity object.
	m_botSpawner:SpawnBot(bot, transform, CharacterPoseType.CharacterPoseType_Stand, soldierBlueprint, soldierKit, {})
	self.botCount = self.botCount + 1
end


function ServerBotManager:OnKick(player, name)
	-- Try to get a player by the specified name.
	local targetPlayer = PlayerManager:GetPlayerByName(name)

	-- Check if they exists.
	if targetPlayer == nil then
		return
	end

	-- And if they do check if they're a bot.
	if not m_botSpawner:IsBot(targetPlayer) then
		return
	end

	-- If they are, destroy them.
	self.botCount = m_botSpawner:DestroyBot(targetPlayer, player.id)
end


function ServerBotManager:OnKickAll(player)
	self.botCount = m_botSpawner:DestroyAllBots(player.id)
end


function ServerBotManager:OnPlayerLeft(player)
	self.botCount = m_botSpawner:DestroyAllBots(player.id)
end


function ServerBotManager:OnEngineUpdate(dt)
	-- We keep track of pitch and yaw time separately here because we want
	-- the bots to turn and look at different rates.
	self.elapsedPitchTime = self.elapsedPitchTime + dt

	while self.elapsedPitchTime >= 0.7 do
		self.elapsedPitchTime = self.elapsedPitchTime - 0.7
	end

	self.elapsedYawTime = self.elapsedYawTime + dt

	while self.elapsedYawTime >= 1.5 do
		self.elapsedYawTime = self.elapsedYawTime - 1.5
	end
end


function ServerBotManager:OnSoldierDamage(hook, soldier, info, giverInfo)
	if(giverInfo.giver == nil) then
		print('Giver is nil')
		return
	end

	-- Check if it is a bot
	if m_botSpawner:IsBot(soldier.player) then
		info.damage = 0
		hook:Pass(soldier, info, giverInfo)
	end
end


-- Listen for bot update events and update their input to make them move.
-- You can make them do anything else you want here, from shooting to
-- aiming, and proning, etc.
function ServerBotManager:OnBotUpdate(bot, dt)
	-- Make the bots move forward.
   --[[ bot.input:SetLevel(EntryInputActionEnum.EIAThrottle, 0.5)

	-- Have bots jump with a 1.5% chance per frame.
	local shouldJump = MathUtils:GetRandomInt(0, 1000)

	if shouldJump <= 15 then
		bot.input:SetLevel(EntryInputActionEnum.EIAJump, 1.0)
	else
		bot.input:SetLevel(EntryInputActionEnum.EIAJump, 0.0)
	end

	-- We also take control over their aiming and make them look up and down
	-- and go around in circles.
	bot.input.flags = EntryInputFlag.AuthoritativeAiming

	local pitch = (((self.elapsedPitchTime / 0.7) - 1.0) * math.pi) + 0.5
	local yaw = ((self.elapsedYawTime / 1.5) * math.pi * 2.0)

	bot.input.authoritativeAimingPitch = pitch
	bot.input.authoritativeAimingYaw = yaw
	]]
end



-- Singleton
if g_ServerBotManager == nil then
	g_ServerBotManager = ServerBotManager()
end

return g_ServerBotManager
