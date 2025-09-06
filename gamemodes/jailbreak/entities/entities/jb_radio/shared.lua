ENT.Type = "anim"
ENT.Model = Model("models/props_lab/citizenradio.mdl")
ENT.PrintName = "#jb.jb_radio"
ENT.Spawnable = false
ENT.MaxVolume = 10.0
function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "URL")
	self:NetworkVar("Float", 0, "Volume")
	if SERVER then
		self:SetURL("")
		return self:SetVolume(1.0)
	end
end
