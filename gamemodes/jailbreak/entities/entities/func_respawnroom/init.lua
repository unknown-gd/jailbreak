ENT.Type = "brush"
local TF2Team = Jailbreak.TF2Team
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
		return func(self)
	end
end
function ENT:KeyValue( key, value)
	if "targetname" == key then
		self.Targets = value
	elseif "TeamNum" == key then
		return self:SetTeam(TF2Team(tonumber(value) or 0))
	elseif "StartDisabled" == key then
		self.Disabled = tobool(value)
	end
end
