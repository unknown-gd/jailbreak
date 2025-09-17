ENT.Type = "point"
function ENT:Initialize()
	self.Disabled = false
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
do
	local TF2Team = Jailbreak.TF2Team
	local tonumber = tonumber
	local tobool = tobool
	function ENT:KeyValue( key, value)
		if "TeamNum" == key then
			return self:SetTeam(TF2Team(tonumber( value ) or 0))
		elseif "StartDisabled" == key then
			self.Disabled = tobool( value )
		end
	end
end
