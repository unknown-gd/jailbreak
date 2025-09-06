ENT.Base = "base_filter"
function ENT:PassesFilter( entity, ply)
	if not (IsValid(ply) and ply:IsPlayer() and ply:Alive()) then
		return false
	end
	local requestedTeam = entity:GetInternalVariable("TeamNum") + 1
	if requestedTeam == ply:Team() then
		return true
	end
	return ply:HasSecurityKeys() and requestedTeam == TEAM_GUARD
end
