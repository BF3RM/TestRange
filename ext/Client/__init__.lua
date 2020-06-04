class "TestRangeClient"

local m_ClientBotManager = require "ClientBotManager"
local m_ClientDamageMarkerManager = require "ClientDamageMarkerManager"

function TestRangeClient:__init()
	self:RegisterEvents()
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

-- Singleton
if g_TestRangeClient == nil then
	g_TestRangeClient = TestRangeClient()
end

return g_TestRangeClient