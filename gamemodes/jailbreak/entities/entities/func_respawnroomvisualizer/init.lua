ENT.Type = "brush"
function ENT:Initialize()
	self:SetCustomCollisionCheck( true )
	self:PhysicsInit( SOLID_BSP )
	return self:SetMoveType( MOVETYPE_NONE )
end
function ENT:IsDisabled()
	return self:GetNW2Bool( "disabled" )
end
function ENT:SetDisabled( bool)
	return self:SetNW2Bool("disabled", bool)
end
function ENT:KeyValue( key, value)
	if "respawnroomname" == key then
		self.RoomName = value
		return timer.Simple(0.25, function()
			if not self:IsValid() then
				return
			end
			local entities = ents.FindByName( value )
			if #entities == 0 then
				return
			end
			return self:SetTeam(entities[1]:Team())
		end)
	elseif "StartDisabled" == key then
		return self:SetDisabled(tobool( value ))
	end
end
function ENT:Disable()
	return self:SetDisabled( true )
end
function ENT:Enable()
	return self:SetDisabled( false )
end
function ENT:Toggle()
	return self:SetDisabled(not self:GetDisabled())
end
function ENT:AcceptInput( key, activator, caller, data)
	local func = self[key]
	if func then
		return func( self )
	end
end
