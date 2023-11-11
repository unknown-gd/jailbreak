GM.Name = "Jailbreak"
GM.Author = ""
GM.TeamBased = true

GM.VoiceChatDistance = 1024 ^ 2

TEAM_PRISONER = 1
TEAM_GUARD = 2

GM.PlayableTeams = {
    [ TEAM_PRISONER ] = true,
    [ TEAM_GUARD ] = true
}

function GM:CreateTeams()
    team.SetUp( TEAM_PRISONER, "#jb.prisoners", Color( 255, 89, 50 ), true )
    team.SetSpawnPoint( TEAM_PRISONER, { "info_player_terrorist", "info_player_rebel" } )

    team.SetUp( TEAM_GUARD, "#jb.guards", Color( 50, 185, 255 ), true )
    team.SetSpawnPoint( TEAM_GUARD, { "info_player_counterterrorist", "info_player_combine" } )

    team.SetUp( TEAM_SPECTATOR, "#jb.spectators", Color( 50, 50, 50 ), true )
end

local util_PrecacheModel = util.PrecacheModel

local guardModels = {
    "models/player/gasmask.mdl",
    "models/player/riot.mdl",
    "models/player/swat.mdl",
    "models/player/urban.mdl",
    "models/player/odessa.mdl"
}

for _, modelPath in ipairs( guardModels ) do
    util_PrecacheModel( modelPath )
end

local prisonerModels = { {}, {} }

-- Female Models
for i = 1, 6 do
    local modelPath = "models/player/Group01/female_0" .. i .. ".mdl"
    prisonerModels[ 1 ][ i ] = modelPath
    util_PrecacheModel( modelPath )
end

-- Male Models
for i = 1, 9 do
    local modelPath = "models/player/Group01/male_0" .. i .. ".mdl"
    prisonerModels[ 2 ][ i ] = modelPath
    util_PrecacheModel( modelPath )
end

GM.PlayerModels = {
    [ TEAM_PRISONER ] = prisonerModels,
    [ TEAM_GUARD ] = guardModels
}

local TEAM_UNASSIGNED = TEAM_UNASSIGNED

function GM:FinishMove( ply, mv )
    if drive.FinishMove( ply, mv ) then
        return true
    end

    local teamID = ply:Team()
    if teamID == TEAM_UNASSIGNED then
        return true
    end

    if self.PlayableTeams[ teamID ] then
        if not ply:Alive() then
            return true
        end

        if ply:IsPlayingTaunt() then
            mv:SetForwardSpeed( 0 )
            mv:SetSideSpeed( 0 )
        end
    end
end

function GM:IsRoundPreparing()
    return GetGlobalInt( "preparing", 0 ) > CurTime()
end

function GM:GetRoundState()
    return GetGlobal2String( "round-state", "waiting" )
end

function GM:IsRoundRunning()
    return self:GetRoundState() == "running"
end

function GM:IsRoundEnded()
    return self:GetRoundState() == "ended"
end

function GM:IsWaitingPlayers()
    return self:GetRoundState() == "waiting"
end