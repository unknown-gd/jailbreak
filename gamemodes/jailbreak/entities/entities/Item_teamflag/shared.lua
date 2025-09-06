AddCSLuaFile()
ENT.Base = "item_healthkit_medium"
ENT.Model = "models/flag/briefcase.mdl"
ENT.Sequence = "spin"
if SERVER then
	ENT.Init = function(self)
		self:SetTrigger(false)
		return self:DrawShadow(false)
	end
	ENT.Touch = function() end
	function ENT:SelectSkin( teamID)
		return self:SetSkin(teamID - 2)
	end
	function ENT:KeyValue( key, value)
		if string.lower(key) == "teamnum" then
			return self:SelectSkin(tonumber(value) or 0)
		end
	end
	function ENT:AcceptInput( key, _, __, value)
		local _exp_0 = string.lower(key)
		if "skin" == _exp_0 then
			return self:SelectSkin(tonumber(value) or 0)
		elseif "setteam" == _exp_0 then
			return self:SelectSkin(tonumber(value) or 0)
		end
	end
end
