class "BotSpawner"

function BotSpawner:__init()
	self:RegisterVars()
	self:RegisterEvents()
end


function BotSpawner:RegisterVars()
	self._bots = {}
	self._botInputs = {}
end


function BotSpawner:RegisterEvents()
	Events:Subscribe('UpdateManager:Update', self, self._OnUpdate)
	Events:Subscribe('Extension:Unloading', self, self._OnUnloading)
end


function BotSpawner:_OnUpdate(dt, pass)
	if pass ~= UpdatePass.UpdatePass_PostFrame then
		return
	end

	for _, botInfo in pairs(self._bots) do
		Events:Dispatch('Bot:Update', botInfo.bot, dt)

		if botInfo.bot.soldier ~= nil then
			botInfo.bot.soldier:SingleStepEntry(botInfo.bot.controlledEntryId)
		end
	end
end


function BotSpawner:_OnUnloading()
	-- Extension is unloading. Get rid of all the bots.
	self:DestroyAllBots('UNLOADING')
end


-- Creates a bot with the specified name and puts it in the specified team and squad.
function BotSpawner:CreateBot(name, team, squad, ownerId)
	-- Create a player for this bot.
	local botPlayer = PlayerManager:CreatePlayer(name, team, squad)

	-- Create input for this bot.
	local botInput = EntryInput()
	botInput.deltaTime = 1.0 / SharedUtils:GetTickrate()

	botPlayer.input = botInput
	-- Add to our local storage.
	-- We need to keep the EntryInput instances around separately because if we don't
	-- they'll get garbage-collected and destroyed and that will cause our game to crash.
	local botInfo = {bot = botPlayer, ownerId = ownerId}
	table.insert(self._bots, botInfo)
	self._botInputs[botPlayer.id] = botInput

	return botPlayer
end


-- Returns `true` if the specified player is a bot, `false` otherwise.
function BotSpawner:IsBot(player)
	for _, botInfo in pairs(self._bots) do
		if botInfo.bot == player then
			return true
		end
	end

	return false
end


-- Spawns a bot at the provided `transform`, with the provided `pose`,
-- using the provided blueprint, kit, and unlocks.
function BotSpawner:SpawnBot(bot, transform, pose, soldierBp, kit, unlocks)
	if not self:IsBot(bot) then
		return
	end

	-- If this bot already has a soldier, kill it.
	if bot.soldier ~= nil then
		bot.soldier:Kill()
	end

	bot:SelectUnlockAssets(kit, unlocks)

	-- Create and spawn the soldier for this bot.
	local botSoldier = bot:CreateSoldier(soldierBp, transform)

	bot:SpawnSoldierAt(botSoldier, transform, pose)
	bot:AttachSoldier(botSoldier)

	return botSoldier
end


-- Destroys / kicks the specified `bot` player.
function BotSpawner:DestroyBot(bot, playerId)
	-- Find index of this bot.
	local idx = nil

	for i, botInfo in pairs(self._bots) do
		if bot == botInfo.bot and botInfo.ownerId == playerId then
			self._bots[i] = nil
			self._botInputs[bot.id] = nil
			bot.input = nil
			PlayerManager:DeletePlayer(bot)
			idx = i
			break
		end
	end
	return #(self._bots)
end


-- Destroys / kicks all bots that belong to the requesting player.
function BotSpawner:DestroyAllBots(playerId)
	for i, botInfo in pairs(self._bots) do
		if botInfo ~= nil then
			if playerId == botInfo.ownerId or playerId == 'UNLOADING' then
				self._bots[i] = nil
				self._botInputs[botInfo.bot.id] = nil
				botInfo.bot.input = nil
				PlayerManager:DeletePlayer(botInfo.bot)
			end
		end
	end
	return #(self._bots)
	--self._bots = {}
	--self._botInputs = {}
end


-- Singleton
if g_Bots == nil then
	g_Bots = BotSpawner()
end

return g_Bots
