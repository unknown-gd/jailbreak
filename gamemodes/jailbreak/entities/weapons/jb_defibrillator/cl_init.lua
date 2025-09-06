include("shared.lua")
function SWEP:Initialize()
	return self:SetHoldType("duel")
end
local CurTime = CurTime
local TraceLine = util.TraceLine
local traceResult = {}
local trace = {
	output = traceResult
}
function SWEP:PrimaryAttack()
	local owner = self:GetOwner()
	if not (owner:IsValid() and owner:Alive()) then
		return
	end
	trace.start = owner:GetShootPos()
	trace.endpos = trace.start + owner:GetAimVector() * 128
	trace.filter = owner
	TraceLine(trace)
	if not traceResult.Hit then
		return
	end
	local ragdoll = traceResult.Entity
	if ragdoll:IsValid() then
		ragdoll:DoElectricSparks(traceResult.HitPos)
		return self:SetNextPrimaryFire(CurTime() + self.UsageDelay:GetFloat())
	end
end
