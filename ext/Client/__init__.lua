class "TestRangeClient"

local m_ClientBotManager = require "ClientBotManager"
local m_ClientDamageMarkerManager = require "ClientDamageMarkerManager"

function TestRangeClient:__init()
	self:RegisterEvents()
	self:RegisterConsoleCommands()
end

function TestRangeClient:RegisterEvents()
	Events:Subscribe('Extension:Loaded', self, self.OnLoaded)
	Events:Subscribe('Client:UpdateInput', self, self.OnUpdateInput)
	Events:Subscribe('UpdateManager:Update', self, self.OnUpdateManager)
end

function TestRangeClient:OnLoaded()
	-- Initialize and show the WebUI
	WebUI:Init()
	WebUI:Show()
end

function TestRangeClient:OnUpdateInput(p_Cache, p_DeltaTime)
	m_ClientBotManager:OnUpdateInput(p_Cache, p_DeltaTime)
end

function TestRangeClient:OnUpdateManager(p_Delta, p_Pass)
	m_ClientDamageMarkerManager:OnUpdateManager(p_Delta, p_Pass)
end

function TestRangeClient:RegisterConsoleCommands()
	-- BotManager console commands
	Console:Register('spawnAtPosition',
			'<*X*> <*Y*> <*Z*> [*team*] [*squad*] [*name*] Spawn a bot at given coordinates',
			m_ClientBotManager, m_ClientBotManager.OnSpawnAtPosition)

	Console:Register('spawnAtDistance',
			'<*distance*> [*height*] [*team*] [*squad*] [*name*] Spawn a bot at a given distance/height from the player',
			m_ClientBotManager, m_ClientBotManager.OnSpawnAtDistance)

	Console:Register('spawnRange',
			'<*minDistance*> <*maxDistance*> <*delta*> [*lateralDistance*] [*team*] Spawn bots as in a shooting range',
			m_ClientBotManager, m_ClientBotManager.OnSpawnRange)

	Console:Register('spawnCircle', '<*radius*> [*distance*] [*team*] Spawn bots in a circle',
			m_ClientBotManager, m_ClientBotManager.OnSpawnCircle)

	Console:Register('kick', ' <*name*> Kick a bot with a given name.', m_ClientBotManager, m_ClientBotManager.OnKick)
	Console:Register('kickAll', ' Kick all the bots.', m_ClientBotManager, m_ClientBotManager.OnKickAll)
	Console:Register('pos', "Get player's position", m_ClientBotManager, m_ClientBotManager.OnGetPlayerPos)

	-- DamageMarkerManager console commands
	Console:Register('showDistance', ' <true/false> Show/hide the distance to other soldiers.',
			m_ClientDamageMarkerManager, m_ClientDamageMarkerManager.OnShowDistance)
	Console:Register('showDamage', ' <true/false> Show/hide the damage indicators.',
			m_ClientDamageMarkerManager, m_ClientDamageMarkerManager.OnShowDamage)
	Console:Register('broadcastDamage', ' <true/false> Show/hide damage that other players deal.',
			m_ClientDamageMarkerManager, m_ClientDamageMarkerManager.OnBroadcastDamage)
end

-- Singleton
if g_TestRangeClient == nil then
	g_TestRangeClient = TestRangeClient()
end

return g_TestRangeClient