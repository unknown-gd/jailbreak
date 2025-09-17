ENT.Type = "brush"
function ENT:Touch( entity)
	if self.Disabled then
		return
	end
	return entity:Ignite(0.5, 0)
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
	if "StartDisabled" == key then
		self.Disabled = tobool( value )
	end
end
