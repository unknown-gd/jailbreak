include( "shared.lua" )
function ENT:Initialize()
	return self:DrawShadow( false )
end
ENT.Draw = function() end
