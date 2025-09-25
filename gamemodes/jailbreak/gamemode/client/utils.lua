---@class Jailbreak
local Jailbreak = Jailbreak

---@class Entity
local ENTITY = ENTITY

---@class Player
local PLAYER = PLAYER

local entity_GetNetworkVariable = ENTITY.GetNW2Var
local timer_Simple = timer.Simple
local hook_Run = hook.Run

cvars.AddChangeCallback( "gmod_language", function( _, __, value )
	timer.Create( "Jailbreak::LanguageChanged", 0.025, 1, function()
		hook_Run( "LanguageChanged", cvars.String( "gmod_language", "en" ), value )
	end )
end, "Jailbreak::LanguageChanged" )

function Jailbreak.ChangeTeam( teamID )
	return RunConsoleCommand( "changeteam", teamID )
end

do

	local string_byte, string_sub, string_gsub = string.byte, string.sub, string.gsub
	local language_GetPhrase = language.GetPhrase

	local function filter( placeholder )
		local uint8_1, uint8_2, uint8_3 = string_byte( placeholder, 1, 3 )
		local full_text = language_GetPhrase( placeholder )

		if full_text == placeholder and uint8_1 == 0x6A and uint8_2 == 0x62 and uint8_3 == 0x2E then
			return language_GetPhrase( string_sub( placeholder, 4 ) )
		else
			return full_text
		end
	end

	Jailbreak.GetPhrase = filter

	function Jailbreak.Translate( str )
		return string_gsub( str, "#([%w%.-_]+)", filter )
	end

end

do

	local math_min, math_max, math_ceil = math.min, math.max, math.ceil
	local ScrW, ScrH = ScrW, ScrH

	local width, height = ScrW(), ScrH()
	local vmin, vmax

	local function screen_resolution_changed()
		vmin, vmax = math_min( width, height ) * 0.01, math_max( width, height ) * 0.01

		Jailbreak.ScreenWidth, Jailbreak.ScreenHeight = width, height
		Jailbreak.ScreenCenterX, Jailbreak.ScreenCenterY = width * 0.5, height * 0.5

		hook_Run( "ScreenResolutionChanged", width, height )
	end

	hook.Add( "OnScreenSizeChanged", "Jailbreak::OnScreenSizeChanged", function( _, __, new_width, new_height )
		width, height = new_width, new_height
		screen_resolution_changed()
	end )

	screen_resolution_changed()

	function Jailbreak.VMin( number )
		if number == nil then
			return vmin
		else
			return math_ceil( vmin * number )
		end
	end

	function Jailbreak.VMax( number )
		if number == nil then
			return vmax
		else
			return math_ceil( vmax * number )
		end
	end

end

do

	local fonts = Jailbreak.Fonts
	if not istable( fonts ) then
		fonts = {}; Jailbreak.Fonts = fonts
	end

	local CreateFont = surface.CreateFont
	local VMin = Jailbreak.VMin
	local remove = table.remove

	local fontData = {
		extended = true,
		weight = 500,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false
	}

	function Jailbreak.Font( fontName, font, size )
		fontData.font, fontData.size = font, VMin( size )

		for index = 1, #fonts do
			if fonts[ index ].fontName == fontName then
				remove( fonts, index )
				break
			end
		end

		fonts[ #fonts + 1 ] = {
			fontName = fontName,
			font = font,
			size = size
		}

		CreateFont( fontName, fontData )
	end

	hook.Add( "ScreenResolutionChanged", "Jailbreak::Fonts", function()
		for i = 1, #fonts, 1 do
			local data = fonts[ i ]
			fontData.font, fontData.size = data.font, VMin( data.size )
			CreateFont( data.fontName, fontData )
		end
	end )

end

function GM:PerformPlayerVoice( ply )
	local voice_volume
	if ply:IsSpeaking() then
		voice_volume = ply:VoiceVolume()
	else
		voice_volume = 0
	end

	local last_voice_volume = ply.m_fLastVoiceVolume
	if last_voice_volume == nil then
		last_voice_volume = voice_volume
	end

	if last_voice_volume > 0 then
		voice_volume = last_voice_volume + (voice_volume - last_voice_volume) * 0.25

		if voice_volume < 0.01 then
			voice_volume = 0
		end
	end

	ply.m_fLastVoiceVolume = voice_volume

	local max_voice_volume = ply.m_fMaxVoiceVolume
	if max_voice_volume == nil or max_voice_volume < voice_volume then
		max_voice_volume = voice_volume
		ply.m_fMaxVoiceVolume = max_voice_volume
	end

	if max_voice_volume > 0 and voice_volume > 0 then
		ply.m_fVoiceFraction = voice_volume / max_voice_volume
	else
		ply.m_fVoiceFraction = 0
	end
end

do

	gameevent.Listen( "player_spawn" )

	local Player = Player

	hook.Add( "player_spawn", "Jailbreak::SpawnEffect", function( data )
		local ply = Player( data.userid )
		if not (ply and ply:IsValid()) then
			return
		end

		local pl = Jailbreak.Player
		if pl:IsValid() then
			ply.m_fSpawnTime = CurTime() + pl:Ping() / 1000
		else
			ply.m_fSpawnTime = CurTime() + 0.25
		end

		hook_Run( "PlayerSpawn", ply )
	end )

end

function PLAYER:GetSpawnTime()
	return self.m_fSpawnTime or entity_GetNetworkVariable( self, "spawn-time", 0 )
end

function PLAYER:GetAliveTime()
	return CurTime() - (self.m_fSpawnTime or entity_GetNetworkVariable( self, "spawn-time", 0 ))
end

function PLAYER:VoiceFraction()
	return self.m_fVoiceFraction or 0
end

function PLAYER:AnimRestartNetworkedGesture( slot, activity, autokill, finished )
	local sequence_id = self:SelectWeightedSequence( activity )
	if sequence_id < 0 then
		return
	end

	if finished ~= nil then
		timer_Simple( self:SequenceDuration( sequence_id ), function()
			if self:IsValid() then
				finished( self )
			end
		end )
	end

	self:AnimRestartGesture( slot, activity, autokill )
end

do

	local entity_GetIndex = ENTITY.EntIndex

	function ENTITY:IsDoorLocked()
		return entity_GetNetworkVariable( self, "m_bLocked", false )
	end

	function ENTITY:GetDoorState()
		return entity_GetNetworkVariable( self, "m_eDoorState", 0 )
	end

	function ENTITY:IsLocalPlayer()
		local index = Jailbreak.PlayerIndex
		if index == nil then
			return true
		else
			return entity_GetIndex( self ) == index
		end
	end

end

do

	local shopItems = Jailbreak.ShopItems
	if not shopItems then
		shopItems = {}
		Jailbreak.ShopItems = shopItems
	end

	local net_ReadString, net_ReadUInt = net.ReadString, net.ReadUInt

	local table_Empty = table.Empty

	net.Receive( "Jailbreak::Shop", function()
		table_Empty( shopItems )

		for index = 1, net_ReadUInt( 16 ), 1 do
			local name = net_ReadString()

			shopItems[ index ] = {
				name = name,
				title = "#jb." .. name,
				model = net_ReadString(),
				price = net_ReadUInt( 16 ),
				skin = net_ReadUInt( 8 ),
				bodygroups = net_ReadString()
			}
		end

		hook_Run( "ShopItems", shopItems )
	end )

end

do

	local GetPlayerColor = ENTITY.GetPlayerColor
	local SetVector = IMATERIAL.SetVector

	matproxy.Add( {
		name = "PlayerColor",
		init = function( self, _, values )
			self.ResultTo = values.resultvar
		end,
		bind = function( self, material, entity )
			return SetVector( material, self.ResultTo, GetPlayerColor( entity ) )
		end
	} )

end

do

	local Material = Material

	local materials = {}

	function Jailbreak.Material( material_path, parameters )
		if materials[ material_path ] == nil then
			materials[ material_path ] = Material( material_path, parameters )
		end

		return materials[ material_path ]
	end

end
