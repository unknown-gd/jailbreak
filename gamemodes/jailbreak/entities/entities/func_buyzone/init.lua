ENT.Type = "brush"
function ENT:Initialize()
	return self:SetTrigger(true)
end
function ENT:StartTouch( entity)
	if entity:IsPlayer() and entity:Alive() then
		return entity:SetNW2Bool("in-buy-zone", true)
	end
end
function ENT:EndTouch( entity)
	if entity:IsPlayer() then
		return entity:SetNW2Bool("in-buy-zone", false)
	end
end
