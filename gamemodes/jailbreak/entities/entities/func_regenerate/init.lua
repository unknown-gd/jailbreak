ENT.Type = "brush"
ENT.Sound = Sound( "Regenerate.Touch" )
function ENT:Initialize()
	self:SetTrigger( true )
	self.Players = {}
end
function ENT:Regenerate( ply)
	ply:Heal()
	local _list_0 = ply:GetWeapons()
	for _index_0 = 1, #_list_0 do
		local weapon = _list_0[_index_0]
		local clip1Type = weapon:GetPrimaryAmmoType()
		if clip1Type >= 0 then
			local amount = ply:GetPickupAmmoCount( clip1Type )
			if amount ~= 0 then
				ply:GiveAmmo(amount, clip1Type, false)
			end
		end
		local clip2Type = weapon:GetSecondaryAmmoType()
		if clip2Type >= 0 then
			local amount = ply:GetPickupAmmoCount( clip2Type )
			if amount ~= 0 then
				ply:GiveAmmo(amount, clip2Type, false)
			end
		end
	end
end
function ENT:StartTouch( entity)
	if entity:IsPlayer() and entity:Alive() then
		local _obj_0 = self.Players
		_obj_0[#_obj_0 + 1] = entity
	end
end
function ENT:EndTouch( entity)
	if entity:IsPlayer() then
		return table.RemoveByValue(self.Players, entity)
	end
end
function ENT:AssociatedAction( func)
	local _list_0 = ents.FindByName( self.AssociatedName )
	for _index_0 = 1, #_list_0 do
		local entity = _list_0[_index_0]
		func( entity )
	end
end
function ENT:Open()
	if self.Opened then
		return
	end
	self.Opened = true
	return self:AssociatedAction(function( entity )
		entity:ResetSequence( "open" )
		return entity:EmitSound(self.Sound, 150)
	end)
end
function ENT:Close()
	if not self.Opened then
		return
	end
	self.Opened = false
	return self:AssociatedAction(function( entity )
		return entity:ResetSequence( "close" )
	end)
end
function ENT:ToggleOpen()
	if self.Opened then
		return self:Close()
	else
		return self:Open()
	end
end
function ENT:Think()
	if self:IsDisabled() then
		return
	end
	local players = self.Players
	if #players == 0 then
		self:Close()
		return
	end
	for _index_0 = 1, #players do
		local ply = players[_index_0]
		self:Regenerate( ply )
	end
	self:NextThink(CurTime() + 1)
	self:ToggleOpen()
	return true
end
function ENT:IsDisabled()
	return self.Disabled or false
end
function ENT:Disable()
	self.Disabled = true
end
function ENT:Enable()
	self.Disabled = false
end
function ENT:Toggle()
	self.Disabled = not self.Disabled
end
function ENT:AcceptInput( key, activator, caller, data)
	local func = self[key]
	if func then
		return func( self )
	end
end
function ENT:KeyValue( key, value)
	if "associatedmodel" == key then
		self.AssociatedName = value
	elseif "StartDisabled" == key then
		self.Disabled = tobool( value )
	end
end
