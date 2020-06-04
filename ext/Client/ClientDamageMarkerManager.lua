class "ClientDamageMarkerManager"


local TEXT_UP_SPEED = 0 -- 0.25
local FADE_OUT_TIME = 5 -- 7

function ClientDamageMarkerManager:__init()
	print("Initializing ClientDamageMarkerManager")
	self:RegisterVars()
	self:RegisterEvents()
end

function ClientDamageMarkerManager:RegisterVars()
	self.hitTransformList = {}
end


function ClientDamageMarkerManager:RegisterEvents()
	NetEvents:Subscribe('Soldier:Damage', self, self.OnSoldierDamage)
end


function ClientDamageMarkerManager:OnSoldierDamage(enemyTransform, damage, boneIndex, hitPosition, originPosition,
												   isBulletDamage, isExplosionDamage)
	local boneOffset = self:GetBoneOffset(enemyTransform, boneIndex)
	local hitMarkerPosition = hitPosition + boneOffset

	-- Append lastHitTransform to hitTransformList
	local index = #(self.hitTransformList) + 1
	table.insert(self.hitTransformList, {position=hitMarkerPosition, timer=0})
	local trans = string.format("DisplayHit(%s, %s, %s, %d)", index, round(damage, 2), FADE_OUT_TIME, boneIndex)
	WebUI:ExecuteJS(trans)

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
	print(string.format("Damage: %s at %s meters (%s)", round(damage, 2), round(hitDistance, 1), bodyPart))
end


function ClientDamageMarkerManager:OnUpdateManager(p_Delta, p_Pass)
	if(p_Pass ~= UpdatePass.UpdatePass_PreFrame) then
		return
	end

	for index, hitObject in pairs(self.hitTransformList) do
		if hitObject ~= nil then
			-- Updating world position
			--local updated_position = hitObject.position + Vec3(0, TEXT_UP_SPEED * hitObject.timer, 0)
			local screen_position = ClientUtils:WorldToScreen(hitObject.position)
			if screen_position ~= nil then
				local js_function = string.format("UpdatePosition(%s, %s, %s)",	index,
						                          screen_position.x, screen_position.y)
				WebUI:ExecuteJS(js_function)
			end

			-- Increment hit's timer
			hitObject.timer = hitObject.timer + p_Delta

			-- Remove if fade out delay is over
			if (hitObject.timer >= FADE_OUT_TIME) then
				self.hitTransformList[index] = nil
			end
		end
	end
end


-- 316.68359375, 206.12870788574, -976.3115234375 Yaw=4.0709943771362 Pitch=-0.0059383539482951



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