ENT.Type = "anim"
function ENT:Think()
	self:FrameAdvance()
	self:NextThink(CurTime() + 0.5)
	return true
end
