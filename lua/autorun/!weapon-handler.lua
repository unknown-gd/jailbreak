local GetStored, Register
do
	local _obj_0 = weapons
	GetStored, Register = _obj_0.GetStored, _obj_0.Register
end
local isstring = isstring
local istable = istable
local ipairs = ipairs
local SERVER = SERVER
local assert = assert
local Create = ents.Create
local Set = list.Set
do
	local _class_0
	local _base_0 = {
		Weapons = list.GetForEdit("Weapon"),
		Perform = function(self)
			local className = self.ClassName
			if self:Exists(className) then
				return
			end
			local alternative = self.Alternatives[1]
			if not istable(alternative) then
				error("Weapon '" .. tostring(className) .. "' handling failed, reason: requested analogs missing.")
				return
			end
			Register(alternative, className)
			return Set("Weapon", className, nil)
		end,
		GetWeaponInfo = function(self, className)
			return self.Weapons[className]
		end,
		Exists = function(self, className)
			return istable(self:GetWeaponInfo(className))
		end,
		AddAlternatives = function(self, alternatives)
			local success = false
			for _, className in ipairs(alternatives) do
				if self:AddAlternative(className) then
					success = true
				end
			end
			return success
		end,
		AddAlternative = function(self, className)
			if not isstring(className) then
				return false
			end
			local info = self:GetWeaponInfo(className)
			if not istable(info) then
				return false
			end
			local metatable = GetStored(className)
			if not istable(metatable) then
				metatable = {
					PrintName = info.PrintName,
					BaseClassName = className,
					Author = info.Author,
					Spawnable = false
				}
				if SERVER then
					metatable.Initialize = function(self)
						local entity = Create(className)
						if entity and entity:IsValid() then
							entity:SetPos(self:GetPos())
							entity:SetAngles(self:GetAngles())
							entity:Spawn()
							entity:Activate()
							entity:SetCollisionGroup(self:GetCollisionGroup())
							entity:SetMoveType(self:GetMoveType())
							entity:SetNoDraw(self:GetNoDraw())
							entity:SetColor(self:GetColor())
							local newPhys = entity:GetPhysicsObject()
							if newPhys and newPhys:IsValid() then
								local oldPhys = self:GetPhysicsObject()
								if oldPhys and oldPhys:IsValid() then
									newPhys:EnableCollisions(oldPhys:IsCollisionEnabled())
									newPhys:EnableMotion(oldPhys:IsMotionEnabled())
									newPhys:EnableDrag(oldPhys:IsDragEnabled())
									newPhys:SetMass(oldPhys:GetMass())
									if oldPhys:IsAsleep() then
										newPhys:Sleep()
									else
										newPhys:Wake()
									end
									newPhys:SetVelocity(oldPhys:GetVelocity())
								else
									newPhys:Wake()
								end
							end
						end
						return self:Remove()
					end
					metatable.Deploy = function(self)
						local owner = self:GetOwner()
						if not (owner and owner:IsValid()) then
							return
						end
						if owner:IsPlayer() and not owner:Alive() then
							return
						end
						owner:Give(className)
						owner:SelectWeapon(className)
						owner:StripWeapon(self:GetClass())
						return true
					end
					metatable.Holster = function(self)
						self:Remove()
						return true
					end
				end
			end
			do
				local _obj_0 = self.Alternatives
				_obj_0[#_obj_0 + 1] = metatable
			end
			return true
		end
	}
	if _base_0.__index == nil then
		_base_0.__index = _base_0
	end
	_class_0 = setmetatable({
		__init = function(self, className)
			assert(isstring(className), "Second argument must be a 'string'!")
			self.ClassName = className
			self.Alternatives = { }
			self.Base = nil
		end,
		__base = _base_0,
		__name = "WeaponHandler"
	}, {
		__index = _base_0,
		__call = function(cls, ...)
			local _self_0 = setmetatable({ }, _base_0)
			cls.__init(_self_0, ...)
			return _self_0
		end
	})
	_base_0.__class = _class_0
	WeaponHandler = _class_0
end
