AddCSLuaFile("cl_init.lua")
local Run = hook.Run
ENT.Type = "anim"
ENT.Sequence = "idle"
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.RespawnTime = 20
function ENT:Initialize()
	self:SetModel(Model(self.Model))
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_BBOX)
	self:AddEFlags(EFL_NO_ROTORWASH_PUSH)
	self:SetNotSolid(true)
	self:SetNoDraw(true)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:UseTriggerBounds(true, 24)
	self:ResetSequence(self.Sequence)
	self:Show()
	local init = self.Init
	if init ~= nil then
		return init(self)
	end
end
function ENT:Hide()
	self:SetNoDraw(true)
	self:SetTrigger(false)
	self:SetPos(self.Origin)
	self:SetAngles(self.Angles)
	self:DropToFloor()
	self:RemoveAllDecals()
	return timer.Simple(self.RespawnTime, function()
		if self:IsValid() then
			return self:Show()
		end
	end)
end
ENT.ShowSound = Sound("Item.Show")
function ENT:Show()
	if self:GetNoDraw() then
		self:EmitSound(self.ShowSound)
		self:SetNoDraw(false)
		self:MuzzleFlash()
	end
	return self:SetTrigger(true)
end
function ENT:Touch( entity)
	if self:IsDisabled() or self:GetNoDraw() then
		return
	end
	if entity:IsVehicle() then
		entity = entity:GetPassenger(1)
		if not entity:IsValid() then
			return
		end
	end
	if not entity:IsPlayer() then
		return
	end
	if Run("PlayerCanPickupItem", entity, self) == false then
		return
	end
	if not (self.PlayerGotItem and self:PlayerGotItem(entity)) then
		return
	end
	local soundName = self.Sound
	if soundName then
		entity:EmitSound(soundName)
	end
	self:Hide()
	return
end
function ENT:IsDisabled()
	return self.Disabled or false
end
function ENT:Disable()
	self.Disabled = true
	return self:SetNoDraw(self.Disabled)
end
function ENT:Enable()
	self.Disabled = false
	return self:SetNoDraw(self.Disabled)
end
function ENT:Toggle()
	self.Disabled = not self.Disabled
	return self:SetNoDraw(self.Disabled)
end
function ENT:AcceptInput( key, activator, caller, data)
	if "Disable" == key then
		self.Disabled = true
	elseif "Enable" == key then
		self.Disabled = false
	elseif "Toggle" == key then
		self.Disabled = not self.Disabled
	end
end
function ENT:KeyValue( key, value)
	if "origin" == key then
		self.Origin = Vector(value)
	elseif "angles" == key then
		self.Angles = Angle(value)
	elseif "StartDisabled" == key then
		self.Disabled = tobool(value)
	end
end
