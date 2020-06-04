class "TestRangeServer"

local m_ServerBotManager = require "ServerBotManager"
local m_ServerDamageMarkerManager = require "ServerDamageMarkerManager"

function TestRangeServer:__init()
	self:RegisterEvents()
	self:RegisterHooks()
end

function TestRangeServer:RegisterEvents()
	Events:Subscribe('Engine:Update', self, self.OnEngineUpdate)
	Events:Subscribe('Bot:Update', self, self.OnBotUpdate)
end

function TestRangeServer:RegisterHooks()
	Hooks:Install("Soldier:Damage", 999, self, self.OnSoldierDamage)
end

-- Routing events
function TestRangeServer:OnEngineUpdate(p_Delta)
	m_ServerBotManager:OnEngineUpdate(p_Delta)
end

function TestRangeServer:OnBotUpdate(p_Bot, p_Delta)
	m_ServerBotManager:OnBotUpdate(p_Bot, p_Delta)
end

-- Routing hooks
function TestRangeServer:OnSoldierDamage(p_Hook, p_Soldier, p_DamageInfo, p_DamageGiverInfo)
	m_ServerDamageMarkerManager:OnSoldierDamage(p_Hook, p_Soldier, p_DamageInfo, p_DamageGiverInfo)
	m_ServerBotManager:OnSoldierDamage(p_Hook, p_Soldier, p_DamageInfo, p_DamageGiverInfo)
end

-- Singleton
if g_TestRangeServer == nil then
	g_TestRangeServer = TestRangeServer()
end

return g_TestRangeServer