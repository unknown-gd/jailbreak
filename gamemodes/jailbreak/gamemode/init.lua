AddCSLuaFile( "weapons.lua" )
AddCSLuaFile( "shared.lua" )
include( "weapons.lua" )
include( "shared.lua" )

resource.AddWorkshop( "2950445307" )
resource.AddWorkshop( "643148462" )

local TEAM_UNASSIGNED = TEAM_UNASSIGNED
local TEAM_PRISONER = TEAM_PRISONER
local TEAM_GUARD = TEAM_GUARD
local hook_Run = hook.Run

function GM:PlayerInitialSpawn( ply, transiton )
    ply:SetTeam( TEAM_UNASSIGNED )
    ply.NextSpawnTime = 0
end

function GM:PlayerSpawn( ply, transiton )
    local teamID = ply:Team()
    if teamID == TEAM_SPECTATOR then
        self:PlayerSpawnAsSpectator( ply )
        return
    end

    ply:AllowFlashlight( false )
    ply:SetCanZoom( false )
    ply:RemoveAllAmmo()
    ply:StripWeapons()
    ply:UnSpectate()

    ply:SetMaxHealth( 100 )
    ply:SetMaxArmor( 100 )
    ply:SetHealth( 100 )

    if teamID == TEAM_GUARD then
        ply:SetArmor( 50 )
    else
        ply:SetArmor( 0 )
    end

    hook_Run( "PlayerSetSpeed", ply, teamID )

    if not self.PlayableTeams[ teamID ] then
        ply:SetNoCollideWithTeammates( true )
        ply:SetAvoidPlayers( false )
        ply:SetNoDraw( true )
        return
    end

    ply:SetNoCollideWithTeammates( false )
    ply:SetAvoidPlayers( true )
    ply:SetNoDraw( false )

    if not transiton then
        hook_Run( "PlayerLoadout", ply, teamID )
    end

    hook_Run( "PlayerSetModel", ply, teamID )

    ply:SetPlayerColor( Vector( ply:GetInfo( "cl_playercolor" ) ) )
    ply:SetSkin( ply:GetInfoNum( "cl_playerskin", 0 ) )

    local weaponColor = Vector( ply:GetInfo( "cl_weaponcolor" ) )
    if weaponColor:Length() < 0.001 then
        weaponColor = Vector( 0.001, 0.001, 0.001 )
    end

    ply:SetWeaponColor( weaponColor )

    local groups = string.Explode( " ", ply:GetInfo( "cl_playerbodygroups" ) or "" )
    for i = 0, ply:GetNumBodyGroups() - 1 do
        ply:SetBodygroup( i, tonumber( groups[ i + 1 ] ) or 0 )
    end

    ply:SetupHands()
end

function GM:PlayerSetSpeed( ply, teamID )
    if self.PlayableTeams[ teamID ] then
        ply:SetSlowWalkSpeed( 100 )
        ply:SetWalkSpeed( 185 )
        ply:SetRunSpeed( 365 )
        return
    end

    ply:SetSlowWalkSpeed( 1 )
    ply:SetWalkSpeed( 1 )
    ply:SetRunSpeed( 1 )
end

function GM:PlayerLoadout( ply, teamID )
    if not self.PlayableTeams[ teamID ] then
        return
    end

    if teamID == TEAM_PRISONER then
        ply:GiveAmmo( 30, "ar2", true )
        ply:GiveAmmo( 45, "smg1", true )
        ply:GiveAmmo( 20, "Pistol", true )
        ply:GiveAmmo( 10, "Buckshot", true )

        if math.random( 1, 3 ) == 3 then
            ply:Give( "weapon_knife" )
        end
    elseif teamID == TEAM_GUARD then
        ply:GiveAmmo( 7, "357", true )
        ply:GiveAmmo( 60, "ar2", true )
        ply:GiveAmmo( 90, "smg1", true )
        ply:GiveAmmo( 40, "Pistol", true )
        ply:GiveAmmo( 20, "Buckshot", true )
    end

    ply:Give( "jb_fists" )
end

function GM:PlayerSetModel( ply, teamID )
    local models = self.PlayerModels[ teamID ]
    if teamID == TEAM_PRISONER then
        models = models[ self.FemalePrison and 1 or 2 ]
    end

    local requested = player_manager.TranslatePlayerModel( ply:GetInfo( "cl_playermodel" ) )
    if requested and #requested > 0 then
        for _, modelPath in ipairs( models ) do
            if modelPath ~= requested then continue end
            ply:SetModel( modelPath )
            return
        end
    end

    ply:SetModel( table.Random( models ) )
end

function GM:PlayerSetHandsModel( ply, hands )
    local info = player_manager.TranslatePlayerHands( player_manager.TranslateToPlayerModelName( ply:GetModel() ) )
    if not info then return end
    hands:SetModel( info.model )
    hands:SetSkin( info.matchBodySkin and ply:GetSkin() or info.skin )
    hands:SetBodyGroups( info.body )
end

do

    local keys = bit.bor( IN_ATTACK, IN_ATTACK2, IN_JUMP )

    function GM:PlayerDeathThink( ply )
        if ply.InstantRespawn then
            ply.InstantRespawn = nil
            ply:Spawn()
            return
        end

        if ply.NextSpawnTime > CurTime() then
            return
        end

        if ply:IsBot() or ply:KeyPressed( keys ) then
            ply:Spawn()
        end
    end

end

function GM:PlayerShouldTakeDamage( ply, attacker )
    if ply:Team() == TEAM_GUARD and attacker:IsPlayer() then
        return attacker:Team() == TEAM_PRISONER
    end

    return true
end

function GM:GetFallDamage( ply, speed )
    return math.max( 0, math.ceil( 0.2418 * speed - 141.75 ) )
end

function GM:PlayerCanPickupWeapon( ply, weapon )
    return not ply:HasWeapon( weapon:GetClass() )
end

function GM:PlayerNoClip( ply, desiredState )
    if ply:IsSuperAdmin() then
        return true
    end

    return not desiredState
end

function GM:CanPlayerSuicide( ply )
    return self.PlayableTeams[ ply:Team() ]
end

function GM:PlayerSwitchFlashlight( ply )
    if ply:Team() == TEAM_GUARD then
        return true
    end

    return ply:CanUseFlashlight()
end

function GM:PlayerCanHearPlayersVoice( listener, talker )
    local talkerPosition = talker:EyePos()
    if talkerPosition:DistToSqr( listener:EyePos() ) <= self.VoiceChatDistance then
        local rf = RecipientFilter()
        rf:AddPAS( talkerPosition )

        for _, ply in ipairs( rf:GetPlayers() ) do
            if ply == listener then
                return true, true
            end
        end
    end

    return false
end

function GM:PlayerCanJoinTeam( ply, teamID )
    if ply:Team() == teamID then
        return false
    end

    if teamID == TEAM_GUARD then
        local guards = team.GetPlayers( TEAM_GUARD )
        if #guards == 0 then
            return true
        end

        return ( #guards / #team.GetPlayers( TEAM_PRISONER ) ) < 0.25
    end

    return true
end

function GM:PlayerRequestTeam( ply, teamID )
    if not team.Joinable( teamID ) then
        ply:ChatPrint( "You can't join that team" )
        return
    end

    if not self:PlayerCanJoinTeam( ply, teamID ) then
        return
    end

    self:PlayerJoinTeam( ply, teamID )
end

function GM:PlayerJoinTeam( ply, teamID )
    if ply:Alive() then
        if self.PlayableTeams[ ply:Team() ] then
            ply:Kill()
        else
            ply.InstantRespawn = true
            ply:KillSilent()
        end
    end

    ply:SetTeam( teamID )
    ply.LastTeamSwitch = CurTime()
end

function GM:PlayerDisconnected( ply )
    if ply:Team() == TEAM_PRISONER then
        local guards, prisoners = team.GetPlayers( TEAM_GUARD ), team.GetPlayers( TEAM_PRISONER )
        local diff = #guards / ( #prisoners - 1 )
        if diff > 0.25 then
            for i = 1, #guards do
                local guard, index = table.Random( guards )
                table.remove( guards, index )

                if guard and guard:IsValid() then
                    guard:SetTeam( TEAM_PRISONER )
                    break
                end
            end
        end
    end
end

concommand.Add( "drop", function( ply )
    local weapon = ply:GetActiveWeapon()
    if weapon and weapon:IsValid() then
        local model = weapon:GetWeaponWorldModel()
        if not model or not util.IsValidModel( model ) then return end
        ply:DropWeapon( weapon )
    end
end )
