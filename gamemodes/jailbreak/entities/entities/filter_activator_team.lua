ENT.Base = "base_filter"

function ENT:PassesFilter( entity, ply )
    return IsValid( ply ) and ply:IsPlayer() and ply:Alive() and ply:Team() == ( entity:GetInternalVariable( "TeamNum" ) + 1 )
end