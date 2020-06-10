class "ClientDamageMarkerManager"


local TEXT_UP_SPEED = 0 -- 0.25
local FADE_OUT_TIME = 7
local RAYCAST_INTERVAL = 0.5 -- seconds
local MAX_RAYCAST_DISTANCE = 2000 -- meters

function ClientDamageMarkerManager:__init()
	print("Initializing ClientDamageMarkerManager")
	self:RegisterVars()
	self:RegisterEvents()
end

function ClientDamageMarkerManager:RegisterVars()
	self.hitTransformList = {}
	self.raycastTimer = 0
	self.showDistance = true
	self.showDamage = true
	self.broadcastDamage = false
end


function ClientDamageMarkerManager:RegisterEvents()
	NetEvents:Subscribe('Soldier:Damage', self, self.OnSoldierDamage)
end


function ClientDamageMarkerManager:OnSoldierDamage(giverId, enemyTransform, enemyName, damage, boneIndex, hitPosition,
												   originPosition, isBulletDamage, isExplosionDamage)
	local localPlayerId = PlayerManager:GetLocalPlayer().id
	if self.broadcastDamage == false and giverId ~= localPlayerId then
		return
	end
	-- Print on the console
	local hitDistance = originPosition:Distance(hitPosition)
	local bodyPart
	if isExplosionDamage then
		bodyPart = 'Explosion'
	elseif isBulletDamage then
		bodyPart = BodyParts[boneIndex + 1]
	else
		bodyPart = 'Other'
	end
	local damageRecord = string.format("Damage: %s at %s meters (%s) - %s",
			round(damage, 2), round(hitDistance, 1), bodyPart, enemyName)
	print(damageRecord)

	if self.showDamage == false then
		return
	end

	-- Display the damage markers
	local boneOffset = self:GetBoneOffset(enemyTransform, boneIndex)
	local hitMarkerPosition = hitPosition + boneOffset

	-- Append lastHitTransform to hitTransformList
	local index = #(self.hitTransformList) + 1
	table.insert(self.hitTransformList, {position=hitMarkerPosition, timer=0})
	local trans = string.format("DisplayHit(%s, %s, %s, %d)", index, round(damage, 2), FADE_OUT_TIME, boneIndex)
	WebUI:ExecuteJS(trans)
end


function ClientDamageMarkerManager:OnUpdateManager(p_Delta, p_Pass)
	if(p_Pass ~= UpdatePass.UpdatePass_PreFrame) then
		return
	end

	if self.showDamage then
		for index, hitObject in pairs(self.hitTransformList) do
			if hitObject ~= nil then
				-- Updating world position
				local updated_position = hitObject.position + Vec3(0, TEXT_UP_SPEED * hitObject.timer, 0)
				local screen_position = ClientUtils:WorldToScreen(updated_position)
				if screen_position ~= nil then
					local js_function = string.format("UpdatePosition(%s, %s, %s)",	index,
							screen_position.x, screen_position.y)
					WebUI:ExecuteJS(js_function)
				end

				-- Remove if fade out delay is over
				hitObject.timer = hitObject.timer + p_Delta
				if (hitObject.timer >= FADE_OUT_TIME) then
					self.hitTransformList[index] = nil
				end
			end
		end
	end

	self.raycastTimer = self.raycastTimer + p_Delta
	-- Raycast only at a predefined time interval
	if self.raycastTimer >= RAYCAST_INTERVAL and self.showDistance then
		local playerName, distance = self:GetRaycastPlayerDistance()
		-- Show distance to the other player, if any was found
		if playerName ~= nil and distance ~= nil then
			local js_function = string.format("SetDistancePlayerName(%s, \"%s\")", round(distance, 1), playerName)
			WebUI:ExecuteJS(js_function)
		-- Clear the distance UI in case no player was hit by the raycast
		else
			WebUI:ExecuteJS("ClearDistancePlayerName()")
		end
		self.raycastTimer = 0
	end
end


function ClientDamageMarkerManager:ClearDamageMarkers()
	for index, value in pairs(self.hitTransformList) do
		self.hitTransformList[index] = nil
	end
	WebUI:ExecuteJS("ClearHits()")
end


function ClientDamageMarkerManager:OnShowDistance(args)
	local option = toboolean(args[1])
	if option == nil then
		return 'You must provide a valid boolean. Usage: _testrange.showDistance <true/false>'
	end
	self.showDistance = option
	if option == false then
		WebUI:ExecuteJS("ClearDistancePlayerName()")
	end
end


function ClientDamageMarkerManager:OnShowDamage(args)
	local option = toboolean(args[1])
	if option == nil then
		return 'You must provide a valid boolean. Usage: _testrange.showDamage <true/false>'
	end
	self.showDamage = option
	if option == false then
		self:ClearDamageMarkers()
	end
end


function ClientDamageMarkerManager:OnBroadcastDamage(args)
	local option = toboolean(args[1])
	if option == nil then
		return 'You must provide a valid boolean. Usage: _testrange.showDamage <true/false>'
	end
	self.broadcastDamage = option
end


function ClientDamageMarkerManager:GetRaycastPlayerDistance()
	local s_LocalPlayer = PlayerManager:GetLocalPlayer()

	if s_LocalPlayer == nil or s_LocalPlayer.soldier == nil then
		return
	end
	local localSoldier = s_LocalPlayer.soldier

	local s_Transform = ClientUtils:GetCameraTransform()
	if s_Transform.trans == Vec3(0,0,0) then -- Camera is below the ground. Creating an entity here would be useless.
		return
	end

	-- The freecam transform is inverted. Invert it back
	local s_CameraForward = Vec3(s_Transform.forward.x * -1, s_Transform.forward.y * -1, s_Transform.forward.z * -1)

	local s_CastPosition = Vec3(s_Transform.trans.x + (s_CameraForward.x * MAX_RAYCAST_DISTANCE),
			s_Transform.trans.y + (s_CameraForward.y * MAX_RAYCAST_DISTANCE),
			s_Transform.trans.z + (s_CameraForward.z * MAX_RAYCAST_DISTANCE))

	local s_Raycast = RaycastManager:Raycast(s_Transform.trans, s_CastPosition, RayCastFlags.IsAsyncRaycast)

	if s_Raycast == nil or s_Raycast.rigidBody == nil or s_Raycast.rigidBody:Is("CharacterPhysicsEntity") == false then
		return
	end

	local s_RayHit = SpatialEntity(s_Raycast.rigidBody)
	local raycastTrans = s_RayHit.transform.trans
	local s_Entities = RaycastManager:SpatialRaycast(s_Transform.trans, s_CastPosition, SpatialQueryFlags.AllGrids)

	for _, s_Entity in pairs(s_Entities) do
		if s_Entity:Is("ClientSoldierEntity") then
			local s_Soldier = SoldierEntity(s_Entity)
			local soldierTrans = s_Soldier.transform.trans
			if localSoldier ~= s_Soldier and s_Soldier.player ~= nil
					and math.floor(soldierTrans.x) == math.floor(raycastTrans.x)
					and math.floor(soldierTrans.z) == math.floor(raycastTrans.z) then
				local distance = localSoldier.transform.trans:Distance(soldierTrans)
				return s_Soldier.player.name, distance
			end
		end
	end

end


function ClientDamageMarkerManager:GetBoneOffset(refTransform, boneIndex)
	local offset
	if boneIndex == HitReactionType.HRT_Head then -- Head
		offset = refTransform.up * 1.0 --+ refTransform.left * 0.2
	elseif boneIndex == HitReactionType.HRT_LeftArm then -- Left arm
		offset = refTransform.up * 0.4 + refTransform.left * 0.3
	elseif boneIndex == HitReactionType.HRT_RightArm then -- Right arm
		offset = refTransform.up * 0.4 + refTransform.left * (-0.65)
	elseif boneIndex == HitReactionType.HRT_LeftLeg then -- Left leg
		offset = refTransform.up * (-0.3) + refTransform.left * 0.3
	elseif boneIndex == HitReactionType.HRT_RightLeg then -- Right leg
		offset = refTransform.up * (-0.3) + refTransform.left * (-0.7)
	else -- Torso and other damage types (fall damage, explosive)
		offset = refTransform.up * 0.2 + refTransform.left * 0.3
	end
	return offset
end


-- Singleton
if g_ClientDamageMarkerManager == nil then
	g_ClientDamageMarkerManager = ClientDamageMarkerManager()
end

return g_ClientDamageMarkerManager