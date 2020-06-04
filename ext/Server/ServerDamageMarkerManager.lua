class "ServerDamageMarkerManager"


function ServerDamageMarkerManager:__init()
	print("Initializing ServerDamageMarkerManager")
end


function ServerDamageMarkerManager:OnSoldierDamage(hook, soldier, damageInfo, giverInfo)
	if(giverInfo.giver == nil or soldier.player == giverInfo.giver) then
		return
	end
	NetEvents:SendToLocal("Soldier:Damage", giverInfo.giver, soldier.transform, damageInfo.damage, damageInfo.boneIndex,
			damageInfo.position, damageInfo.origin, damageInfo.isBulletDamage, damageInfo.isExplosionDamage)
end


-- Singleton
if g_ServerDamageMarkerManager == nil then
	g_ServerDamageMarkerManager = ServerDamageMarkerManager()
end

return g_ServerDamageMarkerManager