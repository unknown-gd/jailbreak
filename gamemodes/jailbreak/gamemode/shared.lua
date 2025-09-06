local GM = GM

GM.Name = "Jailbreak"
GM.Author = "Unknown Developer"
GM.TeamBased = true

local Jailbreak = Jailbreak or {}
_G.Jailbreak = Jailbreak

local TEAM_GUARD = 1
local TEAM_PRISONER = 2
local TEAM_SPECTATOR = 1002

_G.TEAM_GUARD = TEAM_GUARD
_G.TEAM_PRISONER = TEAM_PRISONER
_G.TEAM_SPECTATOR = TEAM_SPECTATOR

ROUND_WAITING_PLAYERS = 0
ROUND_PREPARING = 1
ROUND_RUNNING = 2
ROUND_FINISHED = 3
CHAT_TEXT = 0
CHAT_CONNECT = 1
CHAT_DISCONNECT = 2
CHAT_CONNECTED = 3
CHAT_NAMECHANGE = 4
CHAT_SERVERMESSAGE = 5
CHAT_CUSTOM = 6
CHAT_LOOC = 7
CHAT_OOC = 8
CHAT_EMOTION = 9
CHAT_WHISPER = 10
CHAT_ACHIEVEMENT = 11
PICKUP_OTHER = 0
PICKUP_WEAPON = 1
PICKUP_AMMO = 2
PICKUP_HEALTH = 3
PICKUP_ARMOR = 4

do

	CTAKE_DAMAGE_INFO = FindMetaTable( "CTakeDamageInfo" )
	IMATERIAL = FindMetaTable( "IMaterial" )
	CMOVEDATA = FindMetaTable( "CMoveData" )
	CUSERCMD = FindMetaTable( "CUserCmd" )
	PANEL_META = FindMetaTable( "Panel" )
	ENTITY = FindMetaTable( "Entity" )
	PLAYER = FindMetaTable( "Player" )
	WEAPON = FindMetaTable( "Weapon" )
	VECTOR = FindMetaTable( "Vector" )
	ANGLE = FindMetaTable( "Angle" )

end

local Colors
do

	local Color = Color

	Colors = {
		butterfly_bush = Color( 112, 86, 154 ),
		vivid_orange = Color( 255, 200, 50 ),
		spectators = Color( 220, 220, 220 ),
		dark_white = Color( 200, 200, 200 ),
		light_grey = Color( 180, 180, 180 ),
		turquoise = Color( 64, 224, 208 ),
		asparagus = Color( 128, 154, 86 ),
		prisoners = Color( 255, 89, 50 ),
		au_chico = Color( 154, 98, 86 ),
		dark_grey = Color( 33, 33, 33 ),
		horizon = Color( 86, 142, 154 ),
		guards = Color( 50, 185, 255 ),
		pink = Color( 225, 50, 100 ),
		blue = Color( 0, 190, 255 ),
		grey = Color( 50, 50, 50 ),
		red = Color( 255, 50, 50 ),
		black = Color( 0, 0, 0 ),
		white = color_white
	}

	Jailbreak.Colors = Colors

end

Jailbreak.DefaultPlayerColor = Vector( 0.25, 0.35, 0.4 )

Jailbreak.Teams = {
	[ TEAM_PRISONER ] = true,
	[ TEAM_GUARD ] = true
}

do

	local FCVAR_SHARED = bit.bor( FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_DONTRECORD )

	---@type fun( name: string, default: string, flags: number, help: string, min: number, max: number ): ConVar
	local CreateConVar = CreateConVar

	Jailbreak.PlayerSlowWalkSpeed = CreateConVar("jb_player_slow_walk_speed", "110", FCVAR_SHARED, "The speed of the player while slow walking.", 0, 3000)
	Jailbreak.PlayerSpawnTime = CreateConVar("jb_player_spawn_time", "1.5", FCVAR_SHARED, "Time to spawn a player in seconds.", 0, 300)
	Jailbreak.AllowCustomPlayerModels = CreateConVar("jb_allow_custom_player_models", "0", FCVAR_SHARED, "Allow custom player models.", 0, 1)
	Jailbreak.GuardsDiff = CreateConVar("jb_guards_diff", "4", FCVAR_SHARED, "Number of prisoners per guard.", 0, 1000)
	Jailbreak.GuardsFriendlyFire = CreateConVar("jb_guards_friendly_fire", "0", FCVAR_SHARED, "If enabled, guards can hurt themselves.", 0, 1)
	Jailbreak.AllowJoinToGuards = CreateConVar("jb_allow_join_to_guards", "1", FCVAR_SHARED, "If enabled, players can join as guards.", 0, 1)
	Jailbreak.MinWhisperDistance = CreateConVar("jb_chat_whisper_distance_min", "40", FCVAR_SERVER, "Minimal distance for damaging whisper messages.", 16, 65536)
	Jailbreak.MaxWhisperDistance = CreateConVar("jb_chat_whisper_distance_max", "128", FCVAR_SERVER, "Maximal distance for damaging whisper messages.", 128, 65536)
	Jailbreak.VoiceChatMinDistance = CreateConVar("jb_voice_distance_min", "256", FCVAR_SHARED, "The minimum value at which the player can be heard.", 32, 16384)
	Jailbreak.VoiceChatMaxDistance = CreateConVar("jb_voice_distance_max", "2048", FCVAR_SHARED, "The maximum value at which a player can be heard.", 128, 65536)
	Jailbreak.VoiceChatNotifications = CreateConVar("jb_voice_chat_notifications", "1", FCVAR_SHARED, "Show voice chat notifications.", 0, 1)
	Jailbreak.VoiceChatProximity = CreateConVar("jb_voice_chat_proximity", "0", FCVAR_SHARED, "Enable proximity voice chat.", 0, 1)
	Jailbreak.VoiceFlexLess = CreateConVar("jb_voice_flex_less", "1", FCVAR_SHARED, "Flex less animations mode.", 0, 10)
	Jailbreak.VoiceForceFlexLess = CreateConVar("jb_voice_force_flex_less", "0", FCVAR_SHARED, "Forces flex less animations for all playermodels.", 0, 1)
	Jailbreak.StatusIcons = CreateConVar("jb_status_icons", "1", FCVAR_SHARED, "Show voice/chat icons on players.", 0, 1)
	Jailbreak.DeathNotice = CreateConVar("jb_death_notice", "0", FCVAR_SHARED, "Draw death notice.", 0, 1)
	Jailbreak.TargetID = CreateConVar("jb_targetid", "1", FCVAR_SHARED, "Draw target id.", 0, 1)
	Jailbreak.Markers = CreateConVar("jb_markers", "1", FCVAR_SHARED, "Allow players use markers.", 0, 1)
	Jailbreak.MarkersCount = CreateConVar("jb_markers_count", "5", FCVAR_SHARED, "Marker counts from marker lifetime.", 0, 100)
	Jailbreak.MarkersLifetime = CreateConVar("jb_markers_lifetime", "10", FCVAR_SHARED, "Marker lifetime in seconds.", 0, 300)
	Jailbreak.AllowPlayersLoseConsciousness = CreateConVar("jb_allow_players_lose_consciousness", "1", FCVAR_SHARED, "Allow players to lose consciousness.", 0, 1)
	Jailbreak.RagdollLootingTime = CreateConVar("jb_ragdoll_looting_time", "4", FCVAR_SHARED, "Time to looting a ragdoll in seconds.", 0, 300)
	Jailbreak.BuyZones = CreateConVar("jb_buy_zones", "0", FCVAR_SHARED, "Makes the purchase of items possible only in the buy zone.", 0, 1)
	Jailbreak.FoodEatingTime = CreateConVar("jb_food_eating_time", "2.5", FCVAR_SHARED, "Time to eat food in seconds.", 0, 300)
end

Jailbreak.Developer = cvars.Number( "developer", 0 ) > 2

cvars.AddChangeCallback( "developer", function( _, __, value )
	Jailbreak.Developer = ( tonumber( value, 10 ) or 0 ) > 2
end, "Jailbreak::Developer" )

local GuardMaleModels = {
	"models/player/gasmask.mdl",
	"models/player/riot.mdl",
	"models/player/swat.mdl",
	"models/player/urban.mdl"
}

local GuardFemaleModels = {
	"models/player/police_fem.mdl"
}

do

	local team_SetUp, team_SetSpawnPoint = team.SetUp, team.SetSpawnPoint

	function GM:CreateTeams()
		team_SetUp( TEAM_PRISONER, "#jb.team." .. TEAM_PRISONER, Colors.prisoners, true )

		team_SetSpawnPoint( TEAM_PRISONER, {
			"info_player_zombiemaster",
			"info_survivor_position",
			"info_player_terrorist",
			"info_player_teamspawn",
			"diprip_start_team_red",
			"info_survivor_rescue",
			"info_player_pirate",
			"info_player_viking",
			"info_player_zombie",
			"info_player_rebel",
			"info_player_start",
			"gmod_player_start",
			"info_player_axis",
			"info_player_coop",
			"info_player_red",
			"dys_spawn_point",
			"ins_spawnpoint",
			"aoc_spawnpoint"
		} )

		team_SetUp( TEAM_GUARD, "#jb.team." .. TEAM_GUARD, Colors.guards, true )

		team_SetSpawnPoint( TEAM_GUARD, {
			"info_player_counterterrorist",
			"info_player_zombiemaster",
			"diprip_start_team_blue",
			"info_survivor_position",
			"info_player_deathmatch",
			"info_player_teamspawn",
			"info_survivor_rescue",
			"info_player_combine",
			"info_player_knight",
			"info_player_allies",
			"info_player_start",
			"gmod_player_start",
			"info_player_human",
			"info_player_coop",
			"info_player_blue",
			"dys_spawn_point",
			"ins_spawnpoint",
			"aoc_spawnpoint"
		} )

		team_SetUp(TEAM_SPECTATOR, "#jb.team." .. TEAM_SPECTATOR, Colors.spectators, true)

	end

end

include("shared/utils.lua")

do

	local TranslateToPlayerModelName = player_manager.TranslateToPlayerModelName
	local FixModelPath = Jailbreak.FixModelPath
	local PrecacheModel = util.PrecacheModel

	local female_guards = {}

	for i = 1, #GuardFemaleModels, 1 do
		local model_path = FixModelPath( GuardFemaleModels[ i ] )
		PrecacheModel( model_path )

		female_guards[ #female_guards + 1 ] = model_path
		female_guards[ TranslateToPlayerModelName( model_path ) ] = model_path
	end

	local male_guards = {}

	for i = 1, #GuardMaleModels, 1 do
		local model_path = FixModelPath( GuardMaleModels[ i ] )
		PrecacheModel( model_path )

		male_guards[ #male_guards + 1 ] = model_path
		male_guards[ TranslateToPlayerModelName( model_path ) ] = model_path
	end

	local female_prisoners = {}

	for i = 1, 6, 1 do
		local model_path = FixModelPath( "models/player/group01/female_0" .. i .. ".mdl" )
		PrecacheModel( model_path )

		female_prisoners[ #female_prisoners + 1 ] = model_path
		female_prisoners[ TranslateToPlayerModelName( model_path ) ] = model_path
	end

	local male_prisoners = {}

	for i = 1, 9, 1 do
		local model_path = FixModelPath( "models/player/group01/male_0" .. i .. ".mdl" )
		PrecacheModel( model_path )

		male_prisoners[ #male_prisoners + 1 ] = model_path
		male_prisoners[ TranslateToPlayerModelName( model_path ) ] = model_path
	end

	for i = 2, 8, 2 do
		local model_path = FixModelPath( "models/player/group02/male_0" .. i .. ".mdl" )
		PrecacheModel( model_path )

		male_prisoners[ #male_prisoners + 1 ] = model_path
		male_prisoners[ TranslateToPlayerModelName( model_path ) ] = model_path
	end

	Jailbreak.PlayerModels = {
		[ TEAM_GUARD ] = {
			[ true ] = female_guards,
			[ false ] = male_guards
		},
		[ TEAM_PRISONER ] = {
			[ true ] = female_prisoners,
			[ false ] = male_prisoners
		}
	}

end

Jailbreak.Credits = {
	Colors.guards,
	"\nJail",
	Colors.prisoners,
	"break\n",
	Colors.light_grey,
	"\nCode Base & API\n",
	Colors.white,
	"Unknown Developer\n",
	Colors.light_grey,
	"\nSource Games Compability\n",
	Colors.white,
	"DefaultOS\n",
	"Unknown Developer\n",
	Colors.light_grey,
	"\nBackgrounds, Maps & Workshop Icon\n",
	Colors.white,
	"Erick Maksimets\n",
	Colors.light_grey,
	"\nTranslators\n",
	Colors.white,
	"Tora (TR)\n",
	"Erick Maksimets (EN, UK)\n",
	"Unknown Developer (EN, RU)\n",
	Colors.light_grey,
	"\nIcons & Logo\n",
	Colors.white,
	"Gunter\n",
	"Komi-sar\n",
	"Unknown Developer\n",
	Colors.light_grey,
	"\nDevelopment Assistance\n",
	Colors.white,
	"Jaff\n",
	"BrunH\n",
	"Gunter\n",
	"Erick Maksimets\n",
	Colors.light_grey,
	"\nTesters\n",
	Colors.white,
	"Gunter\n",
	"SoR_Ge\n",
	"pojn87\n",
	"troit5ky\n",
	"licen777\n",
	"Shztirlec\n",
	"Yeah, well\n",
	"Erick_Maksimets\n"
}

include("shared/game.lua")
include("shared/weapons.lua")
include("shared/extra.lua")
include("shared/properties.lua")
