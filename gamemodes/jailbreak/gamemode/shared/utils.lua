---@class Jailbreak
local Jailbreak = Jailbreak

---@class Player
local PLAYER = PLAYER

---@class Entity
local ENTITY = ENTITY

local hook_Run, hook_Add = hook.Run, hook.Add

local math_min, math_max = math.min, math.max
local math_random = math.random
local math_ceil = math.ceil

local GetNW2Var, SetNW2Var
do
	local _obj_0 = ENTITY
	GetNW2Var, SetNW2Var = _obj_0.GetNW2Var, _obj_0.SetNW2Var
end

local GetGlobal2Bool = GetGlobal2Bool
local GetGlobal2Int = GetGlobal2Int


local Iterator = player.Iterator
local CurTime = CurTime
local Simple = timer.Simple

local lower = string.lower
local TEAM_SPECTATOR = TEAM_SPECTATOR
local TEAM_PRISONER = TEAM_PRISONER
local CHAN_STATIC = CHAN_STATIC
local TEAM_GUARD = TEAM_GUARD
local NULL = NULL
do

	local AllowJoinToGuards, GuardsDiff = Jailbreak.AllowJoinToGuards, Jailbreak.GuardsDiff
	local Joinable = team.Joinable

	Jailbreak.TeamIsJoinable = function( requestedTeamID )
		if not Joinable( requestedTeamID ) then
			return false
		end

		local guardCount, prisonerCount = 0, 0
		for _, ply in Iterator() do
			local team_id = ply:Team()
			if team_id == TEAM_GUARD then
				guardCount = guardCount + 1
			elseif team_id == TEAM_PRISONER then
				prisonerCount = prisonerCount + 1
			end
		end

		if TEAM_PRISONER == requestedTeamID then
			if prisonerCount == 0 then
				return true
			else
				return guardCount ~= 0
			end
		elseif TEAM_GUARD == requestedTeamID then
			if not AllowJoinToGuards:GetBool() then
				return false
			end

			if guardCount == 0 then
				return true
			end

			if prisonerCount == 0 then
				return false
			end

			return guardCount < math_ceil( prisonerCount / GuardsDiff:GetInt() )
		end

		return true
	end

end

---@param weapon Weapon
---@return string
function Jailbreak.GetWeaponName( weapon )
	if not (weapon and weapon:IsValid() and weapon:IsWeapon()) then
		return "#jb.unknown"
	end

	local name = hook_Run( "LanguageWeaponName", weapon )
	if name == nil then
		name = weapon:GetPrintName()
		if name == "Scripted Weapon" then
			name = "#" .. weapon:GetClass()
		end
	end

	return name
end

if CLIENT then

	local language_GetPhrase = CLIENT and language.GetPhrase

	function GM:LanguageWeaponName( weapon )
		local placeholder = "jb." .. weapon:GetClass()
		if language_GetPhrase( placeholder ) ~= placeholder then
			return "#" .. placeholder
		end
	end

end

do

	local gsub = string.gsub

	Jailbreak.FixModelPath = function( modelPath )
		return gsub( lower( modelPath ), "[\\/]+", "/" )
	end

end

---@param team_id integer | nil
---@param alive_only boolean | nil
---@return integer
function Jailbreak.GetPlayerCount( team_id, alive_only )
	local player_count = 0

	if team_id == nil then

		for _, ply in Iterator() do
			if not alive_only or ply:Alive() == alive_only then
				player_count = player_count + 1
			end
		end

	else

		for _, ply in Iterator() do
			if ply:Team() == team_id and ( not alive_only or ply:Alive() == alive_only ) then
				player_count = player_count + 1
			end
		end

	end

	return player_count
end

function Jailbreak.GetTeamPlayers( alive_only, ... )
	local teams = { ... }

	for i = 1, #teams, 1 do
		local team_id = teams[ i ]
		local player_count = 0
		local players = {}

		for _, ply in Iterator() do
			if ply:Team() == team_id and ( not alive_only or ply:Alive() ) then
				player_count = player_count + 1
				players[ player_count ] = ply
			end
		end

		players[ 0 ] = player_count
		teams[ i ] = players
	end

	return teams
end

function Jailbreak.GetTeamPlayersCount( alive_only, ... )
	local teams = { ... }
	local length = 0

	for index, team_id in ipairs( teams ) do
		length = 0

		for _, ply in Iterator() do
			if ply:Team() ~= team_id then
				goto _continue_0
			end

			if alive_only ~= nil and ply:Alive() ~= alive_only then
				goto _continue_0
			end

			length = length + 1
			::_continue_0::
		end

		teams[ index ] = length
	end

	return teams
end

do

	local function getWarden()
		local warden = Jailbreak.Warden
		if warden and warden:IsValid() and warden:IsWarden() and warden:Alive() then
			return warden
		end

		for _, ply in Iterator() do
			if ply:IsWarden() then
				Jailbreak.Warden = ply
				return ply
			end
		end

		return NULL

	end

	Jailbreak.GetWarden = getWarden

	function Jailbreak.HasWarden()
		local warden = getWarden()
		return warden:IsValid() and warden:Alive()
	end

end

do

	local ROUND_WAITING_PLAYERS = ROUND_WAITING_PLAYERS
	local ROUND_PREPARING = ROUND_PREPARING
	local ROUND_RUNNING = ROUND_RUNNING
	local ROUND_FINISHED = ROUND_FINISHED

	local function getRoundState()
		return GetGlobal2Int( "round-state" )
	end

	Jailbreak.GetRoundState = getRoundState

	function Jailbreak.IsWaitingPlayers()
		return getRoundState() == ROUND_WAITING_PLAYERS
	end

	function Jailbreak.IsRoundPreparing()
		return getRoundState() == ROUND_PREPARING
	end

	function Jailbreak.IsRoundRunning()
		return getRoundState() == ROUND_RUNNING
	end

	function Jailbreak.IsRoundFinished()
		return getRoundState() == ROUND_FINISHED
	end

	function Jailbreak.GameInProgress()
		local state = getRoundState()
		return state ~= ROUND_WAITING_PLAYERS and state ~= ROUND_PREPARING
	end

end

do

	local function getRoundTime()
		return GetGlobal2Int( "next-round-state" )
	end

	Jailbreak.GetRoundTime = getRoundTime

	function Jailbreak.GetRemainingTime()
		return math_max( 0, getRoundTime() - CurTime() )
	end

end

function Jailbreak.GetWinningTeam()
	return GetGlobal2Int( "winning-team" )
end

function Jailbreak.IsShockCollarsActive()
	return GetGlobal2Bool( "shock-collars" )
end

do

	local function getWardenCoins()
		return GetGlobal2Int( "warden-coins" )
	end

	Jailbreak.GetWardenCoins = getWardenCoins

	function Jailbreak.CanWardenAfford( value )
		return getWardenCoins() >= value
	end

end

function ENTITY:DelayedRemove( delay )
	if not self:IsValid() then
		return
	end

	Simple( delay or 0, function()
		if self:IsValid() then
			return self:Remove()
		end
	end )
end

function Jailbreak.TF2Team( team_id )
	if 2 == team_id then
		return TEAM_PRISONER
	elseif 3 == team_id then
		return TEAM_GUARD
	else
		return TEAM_SPECTATOR
	end
end

do

	local date = os.date
	Jailbreak.IsFemalePrison = function()
		if GetGlobal2Bool( "female-prison" ) then
			return true
		else
			local result = date( "!*t" )
			return result.month == 3 and result.day == 8
		end
	end

end

do

	local AllowCustomPlayerModels, IsFemalePrison = Jailbreak.AllowCustomPlayerModels, Jailbreak.IsFemalePrison
	local TranslateToPlayerModelName = player_manager.TranslateToPlayerModelName

	function Jailbreak.FormatPlayerModelName( modelName )
		if AllowCustomPlayerModels:GetBool() then
			return modelName
		end

		local isFemalePrison = IsFemalePrison()
		local models = Jailbreak.PlayerModels[ TEAM_GUARD ][ isFemalePrison ]
		if #models == 0 or models[ modelName ] then

			return modelName

		end

		models = Jailbreak.PlayerModels[ TEAM_PRISONER ][ isFemalePrison ]

		if #models == 0 or models[ modelName ] then
			return modelName
		end

		return TranslateToPlayerModelName( models[ math_random( 1, #models ) ] )
	end

end

function PLAYER:IsDeveloper()
	return GetNW2Var( self, "is-developer", false )
end

function PLAYER:UsingSecurityRadio()
	return GetNW2Var( self, "using-security-radio", false )
end

function ENTITY:IsPlayerRagdoll()
	return GetNW2Var( self, "is-player-ragdoll", false )
end

function ENTITY:GetRagdollOwner()
	return GetNW2Var( self, "ragdoll-owner", NULL )
end

function ENTITY:GetRagdollOwnerNickname()
	local value = GetNW2Var( self, "owner-nickname" )
	if value then
		return value
	else
		return "#jb.player.unknown"
	end
end

do

	local EffectData = EffectData
	local Effect = util.Effect

	function ENTITY:DoElectricSparks( origin, pitch, noSound )
		if origin == nil then
			local bone_id = self:LookupBone( "ValveBiped.Bip01_Head1" )
			if bone_id and bone_id >= 0 then
				origin = self:GetBonePosition( bone_id )
			end

			if origin == nil then
				origin = self:EyePos()
			end
		end

		local fx = EffectData()
		fx:SetScale( 0.5 )
		fx:SetOrigin( origin )
		fx:SetMagnitude( math_random( 3, 5 ) )
		fx:SetRadius( math_random( 1, 5 ) )
		Effect( "ElectricSpark", fx )

		if noSound ~= true then
			return self:EmitSound( "Jailbreak.ElectricSpark", math_random( 50, 90 ), pitch or math_random( 80, 120 ), 1, CHAN_STATIC, 0, 1 )
		end
	end

end

do

	local DefaultPlayerColor = Jailbreak.DefaultPlayerColor

	local function getPlayerColor( self )
		return self.m_vPlayerColor or DefaultPlayerColor
	end

	ENTITY.GetPlayerColor, PLAYER.GetPlayerColor = getPlayerColor, getPlayerColor

end

do

	local isvector = isvector

	hook_Add( "EntityNetworkedVarChanged", "Jailbreak::PlayerColor", function( self, key, _, value )
		if key == "player-color" and isvector( value ) then
			self.m_vPlayerColor = value
			hook_Run( "PlayerColorChanged", self, value )
			return
		end
	end )

end

do

	local Call = hook.Call

	do

		local ClearMovement, ClearButtons = CUSERCMD.ClearMovement, CUSERCMD.ClearButtons

		hook_Add( "StartCommand", "Jailbreak::MovementBlocking", function( self, cmd )
			if Call( "AllowPlayerMove", nil, self ) == false then
				ClearMovement( cmd )
				ClearButtons( cmd )
			end
		end )

	end

	do

		local GetVelocity, SetVelocity
		do
			local _obj_0 = CMOVEDATA
			GetVelocity, SetVelocity = _obj_0.GetVelocity, _obj_0.SetVelocity
		end

		local FrameTime = FrameTime
		local Lerp = Lerp

		function GM:Move( ply, mv )
			if Call( "AllowPlayerMove", nil, ply ) == false then
				local velocity, frameTime = GetVelocity( mv ), FrameTime()
				velocity[ 1 ] = Lerp( frameTime, velocity[ 1 ], 0 )
				velocity[ 2 ] = Lerp( frameTime, velocity[ 2 ], 0 )
				SetVelocity( mv, velocity )
			end
		end

	end

end

do

	local ToColor = VECTOR.ToColor

	local defaultColor = ToColor( Jailbreak.DefaultPlayerColor )

	hook_Add( "PlayerColorChanged", "Jailbreak::PlayerColor", function( self, vector )
		self.m_cPlayerColor = ToColor( vector )
	end )

	function ENTITY:GetModelColor()
		if self:IsValid() then
			return self.m_cPlayerColor or defaultColor
		end

		return defaultColor
	end

	function ENTITY:GetModelColorUnpacked()
		if self:IsValid() then
			local color = self.m_cPlayerColor or defaultColor
			return color.r, color.g, color.b
		end

		return defaultColor.r, defaultColor.g, defaultColor.b
	end

end

local function setPlayerColor( self, vector )
	return SetNW2Var( self, "player-color", vector )
end

ENTITY.SetPlayerColor, PLAYER.SetPlayerColor = setPlayerColor, setPlayerColor

do

	local classNames = list.GetForEdit( "prop-classnames" )
	classNames.prop_physics_multiplayer = true
	classNames.prop_physics_override = true
	classNames.prop_dynamic_override = true
	classNames.prop_dynamic = true
	classNames.prop_ragdoll = true
	classNames.prop_physics = true
	classNames.prop_detail = true
	classNames.prop_static = true

	function Jailbreak.IsProp( className )
		return classNames[ className ] ~= nil
	end

	local GetClass = ENTITY.GetClass

	function ENTITY:IsProp()
		return classNames[ GetClass( self ) ] ~= nil
	end

	function ENTITY:IsFemaleModel()
		local teamModels = Jailbreak.PlayerModels[ self:Team() ]
		if not teamModels then
			return false
		end

		local model_path = self:GetModel()
		if model_path == nil then
			return false
		end

		model_path = lower( model_path )

		local model_list = teamModels[ true ]
		for i = 1, #model_list do
			if model_list[ i ] == model_path then
				return true
			end
		end

		return false
	end

	local paintCans = {
		[ "models/props_junk/metal_paintcan001a.mdl" ] = true,
		[ "models/props_junk/metal_paintcan001b.mdl" ] = true
	}

	function ENTITY:IsPaintCan()
		return classNames[ GetClass( self ) ] ~= nil and paintCans[ self:GetModel() ] ~= nil
	end

end

function ENTITY:IsButton()
	return GetNW2Var( self, "is-button", false )
end

function ENTITY:IsFood()
	return GetNW2Var( self, "is-food", false )
end

function ENTITY:Team()
	return GetNW2Var( self, "player-team", TEAM_SPECTATOR )
end

function ENTITY:Alive()
	return GetNW2Var( self, "alive", false ) and self:Health() >= 1
end

do

	local DefaultColor = Color( 255, 255, 100, 255 )
	local TeamInfo = team.GetAllTeams()
	local function getTeamColor( team_id )
		local teamInfo = TeamInfo[ team_id ]
		if teamInfo == nil then
			return DefaultColor
		else
			return teamInfo.Color
		end
	end

	Jailbreak.GetTeamColor = getTeamColor

	local function getTeamColorUpacked( team_id )
		local color = getTeamColor( team_id )
		return color.r, color.g, color.b, color.a
	end

	Jailbreak.GetTeamColorUpacked = getTeamColorUpacked

	function PLAYER:GetTeamColor()
		return getTeamColor( self:Team() )
	end

	function PLAYER:GetTeamColorUpacked()
		return getTeamColorUpacked( self:Team() )
	end

end

function PLAYER:IsFullyConnected()
	return GetNW2Var( self, "fully-connected", false )
end

function PLAYER:IsFlightAllowed()
	return GetNW2Var( self, "flight-allowed", false )
end

function PLAYER:GetWeaponsInSlot( slot_id )
	local weapon_entities = self:GetWeapons()
	local weapons, weapon_count = {}, 0

	for i = 1, #weapon_entities, 1 do
		local weapon = weapon_entities[ i ]
		if weapon:GetSlot() == slot_id then
			weapon_count = weapon_count + 1
			weapons[ weapon_count ] = weapon
		end
	end

	return weapons, weapon_count
end

function PLAYER:HasWeaponsInSlot( slot_id )
	local weapon_entities = self:GetWeapons()
	for i = 1, #weapon_entities, 1 do
		if weapon_entities[ i ]:GetSlot() == slot_id then
			return true
		end
	end

	return false
end

function PLAYER:GetCountWeaponsInSlot( slot_id )
	local weapon_entities = self:GetWeapons()
	local weapon_count = 0

	for i = 1, #weapon_entities, 1 do
		if weapon_entities[ i ]:GetSlot() == slot_id then
			weapon_count = weapon_count + 1
		end
	end

	return weapon_count
end

function PLAYER:GetRagdollEntity()
	return GetNW2Var( self, "player-ragdoll", NULL )
end

do

	local entities_FindByClass = ents.FindByClass

	function PLAYER:FindRagdollEntity()
		local ragdoll_entity = GetNW2Var( self, "player-ragdoll" )
		if ragdoll_entity and ragdoll_entity:IsValid() then
			return ragdoll_entity
		end

		local isBot = self:IsBot()
		local sid64 = isBot and self:Nick() or self:SteamID64()

		local ragdoll_entities = entities_FindByClass( "prop_ragdoll" )
		for _index_0 = 1, #ragdoll_entities do
			local entity = ragdoll_entities[ _index_0 ]
			if entity:IsPlayerRagdoll() and GetNW2Var( entity, isBot and "owner-nickname" or "owner-steamid64" ) == sid64 then
				SetNW2Var( self, "player-ragdoll", entity )
				return entity
			end
		end

		local _list_1 = entities_FindByClass( "prop_physics" )
		for _index_0 = 1, #_list_1 do
			local entity = _list_1[ _index_0 ]
			if entity:IsPlayerRagdoll() and GetNW2Var( entity, isBot and "owner-nickname" or "owner-steamid64" ) == sid64 then
				SetNW2Var( self, "player-ragdoll", entity )
				return entity
			end
		end

		return NULL
	end

end

function ENTITY:IsGuard()
	return self:Team() == TEAM_GUARD
end

function ENTITY:IsPrisoner()
	return self:Team() == TEAM_PRISONER
end

function ENTITY:IsWarden()
	return GetNW2Var( self, "is-warden", false )
end

do

	local function hasShockCollar( self )
		return GetNW2Var( self, "shock-collar", false )
	end

	PLAYER.HasShockCollar = hasShockCollar

	function PLAYER:ShockCollarIsEnabled()
		return hasShockCollar( self ) and GetNW2Var( self, "shock-collar-enabled", false )
	end

end

function PLAYER:HasSecurityKeys()
	return GetNW2Var( self, "security-keys", false )
end

function PLAYER:HasSecurityRadio()
	return GetNW2Var( self, "security-radio", false )
end

do

	local entities_FindInSphere = ents.FindInSphere

	---@param distance number
	---@param ignore_team boolean?
	---@param ignore_self boolean?
	function PLAYER:GetNearPlayers( distance, ignore_team, ignore_self, ignore_dead )
		---@type integer | nil
		local team_id

		if not ignore_team then
			team_id = self:Team()
		end

		local entities = entities_FindInSphere( self:EyePos(), distance )
		local players, player_count = {}, 0

		for i = 1, #entities do
			local ply = entities[ i ]
			if ply:IsPlayer() and ( not ignore_team or team_id == ply:Team() ) and ( not ignore_self or ply ~= self ) and not ( ignore_dead or ply:Alive() ) then
				player_count = player_count + 1
				players[ player_count ] = ply
			end
		end

		return players, player_count

	end

end
do

	local KeyDown = PLAYER.KeyDown
	local IN_USE = IN_USE
	function PLAYER:GetUsedEntity()

		if KeyDown( self, IN_USE ) then

			return self:GetUseEntity()

		end

		return NULL

	end

	function PLAYER:IsUsingEntity()

		if KeyDown( self, IN_USE ) then

			local entity = self:GetUseEntity()
			return entity ~= NULL and entity:IsValid()

		end

		return false

	end

	function PLAYER:IsHoldingEntity()

		return GetNW2Var( self, "holding-entity", NULL ):IsValid()

	end

	function PLAYER:GetHoldingEntity()

		return GetNW2Var( self, "holding-entity", NULL )

	end

	function PLAYER:GetUseTime()

		if not KeyDown( self, IN_USE ) then

			return 0

		end

		local startUseTime = GetNW2Var( self, "start-use-time" )
		if not startUseTime then

			return 0

		end

		return CurTime() - startUseTime

	end

end
do

	local game_GetAmmoMax = game.GetAmmoMax

	local function getAmmoMax( ammoType )
		return math_min( math_max( game_GetAmmoMax( ammoType ), 0 ), 256 )
	end

	Jailbreak.GetAmmoMax = getAmmoMax

	local GetAmmoCount = PLAYER.GetAmmoCount

	function PLAYER:GetPickupAmmoCount( ammoType )
		return math_max( 0, getAmmoMax( ammoType ) - GetAmmoCount( self, ammoType ) )
	end

end

function PLAYER:IsSpawning()
	return self:Alive() and GetNW2Var( self, "is-spawning", false )
end

function PLAYER:IsEscaped()
	return GetNW2Var( self, "escaped", false )
end

function PLAYER:IsLoseConsciousness()
	return GetNW2Var( self, "lost-consciousness", false )
end

do

	local jb_buy_zones = GetConVar( "jb_buy_zones" )

	function PLAYER:IsInBuyZone()
		return not jb_buy_zones:GetBool() or GetNW2Var( self, "in-buy-zone", false )
	end

end

do

	local MOVETYPE_NOCLIP = MOVETYPE_NOCLIP

	do

		local entity_GetMoveType = ENTITY.GetMoveType

		function PLAYER:InNoclip()
			return entity_GetMoveType( self ) == MOVETYPE_NOCLIP
		end

	end

	function PLAYER:SetNoclip( desired_state, force )
		if desired_state == self:InNoclip() then
			return true
		end

		if not force and hook_Run( "PlayerNoClip", self, desired_state ) == false then
			return false
		end

		self:SetMoveType( desired_state and MOVETYPE_NOCLIP or MOVETYPE_WALK )
		return true
	end

end

do

	local sounds = {}
	for number = 1, 6 do
		sounds[ number ] = "ambient/energy/spark" .. number .. ".wav"
	end

	sound.Add( {
		name = "Jailbreak.ElectricSpark",
		channel = CHAN_WEAPON,
		level = SNDLVL_70dB,
		sound = sounds,
		pitch = 100,
		volume = 1
	} )

end

do

	local sounds = {}
	for number = 1, 6 do
		sounds[ number ] = "vo/npc/male01/pain0" .. number .. ".wav"
	end

	sound.Add( {
		name = "Jailbreak.Male.Pain",
		channel = CHAN_STATIC,
		level = SNDLVL_TALKING,
		sound = sounds,
		pitch = 100,
		volume = 1
	} )

end

do

	local sounds = {}
	for number = 1, 6 do
		sounds[ number ] = "vo/npc/female01/pain0" .. number .. ".wav"
	end

	sound.Add( {
		name = "Jailbreak.Female.Pain",
		channel = CHAN_STATIC,
		level = SNDLVL_TALKING,
		sound = sounds,
		pitch = 100,
		volume = 1
	} )

end

hook.Remove( "PostDrawEffects", "RenderWidgets" )
hook.Remove( "PlayerTick", "TickWidgets" )
