local GetStored, Register
do
	local _obj_0 = weapons
	GetStored, Register = _obj_0.GetStored, _obj_0.Register
end
local isstring = isstring
local IsValid = IsValid
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
		Register = function(self, metatable)
			if self.Registered then
				return
			end
			if not istable(metatable) then
				error("Weapon '" .. tostring(self.ClassName) .. "' handling failed, reason: requested analogs missing.")
				return
			end
			local className = self.ClassName
			Register(metatable, className)
			Set("Weapon", className, nil)
			self.Registered = true
		end,
		GetWeaponInfo = function(self, className)
			return self.Weapons[className]
		end,
		Exists = function(self, className)
			return istable(self:GetWeaponInfo(className))
		end,
		AddAlternative = function(self, className)
			if self.Registered then
				return
			end
			assert(isstring(className), "Second argument must be a 'string'!")
			local info = self:GetWeaponInfo(className)
			if not istable(info) then
				return
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
						local owner = self:GetOwner()
						if IsValid(owner) then
							owner:Give(className)
							return
						end
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
									newPhys:Sleep()
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
			return self:Register(metatable)
		end,
		AddAlternatives = function(self, alternatives)
			assert(istable(alternatives), "Second argument must be a 'table'!")
			for _, className in ipairs(alternatives) do
				self:AddAlternative(className)
			end
		end
	}
	if _base_0.__index == nil then
		_base_0.__index = _base_0
	end
	_class_0 = setmetatable({
		__init = function(self, className, alternative)
			assert(isstring(className), "Second argument must be a 'string'!")
			self.Registered = self:Exists(className)
			self.ClassName = className
			if self.Registered then
				return
			end
			if isstring(alternative) then
				return self:AddAlternative(alternative)
			elseif istable(alternative) then
				return self:AddAlternatives(alternative)
			end
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
