AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

-- TODO: Write desc
GM.Preparing = CreateConVar( "jb_preparing", "30", bit.bor( FCVAR_ARCHIVE, FCVAR_NOTIFY ), "", 5, 120 )

resource.AddWorkshop( "2950445307" )
resource.AddWorkshop( "643148462" )

local TEAM_UNASSIGNED = TEAM_UNASSIGNED
local TEAM_PRISONER = TEAM_PRISONER
local TEAM_GUARD = TEAM_GUARD
local hook_Run = hook.Run
local ipairs = ipairs

function GM:PlayerInitialSpawn( ply, transiton )
    ply:SetTeam( TEAM_UNASSIGNED )
end

function GM:PlayerSpawn( ply, transiton )
    ply:AllowFlashlight( false )
    ply:SetCanZoom( false )
    ply:RemoveAllAmmo()
    ply:StripWeapons()
    ply:UnSpectate()

    ply:SetSlowWalkSpeed( 100 )
    ply:SetWalkSpeed( 185 )
    ply:SetRunSpeed( 365 )

    ply:SetMaxHealth( 100 )
    ply:SetMaxArmor( 100 )
    ply:SetHealth( 100 )

    local teamID = ply:Team()
    if teamID == TEAM_GUARD then
        ply:SetArmor( 50 )
    else
        ply:SetArmor( 0 )
    end

    if teamID == TEAM_PRISONER then
        ply:SetNoCollideWithTeammates( false )
        ply:SetAvoidPlayers( true )
    else
        ply:SetNoCollideWithTeammates( true )
        ply:SetAvoidPlayers( false )
    end

    if not self.PlayableTeams[ teamID ] then
        if ply:IsBot() then
            for i = 1, 2 do
                self:PlayerRequestTeam( ply, i )
            end
        end

        ply:Spectate( ( teamID == TEAM_SPECTATOR ) and OBS_MODE_ROAMING or OBS_MODE_FIXED )
        ply:SetNoDraw( true )
        return
    end

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

function GM:OnEntityCreated( weapon )
    if not weapon:IsWeapon() then return end

    timer.Simple( 0.025, function()
        if not weapon:IsValid() then return end
        weapon:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

        local phys = weapon:GetPhysicsObject()
        if not phys or not phys:IsValid() then
            return
        end

        if weapon:GetPos():Length() <= 3 then
            weapon:Remove()
            return
        end

        local counter = 0
        for _, entity in ipairs( ents.FindInSphere( weapon:GetPos(), 32 ) ) do
            if not entity:IsWeapon() then continue end
            counter = counter + 1
        end

        if counter >= 5 then
            phys:EnableMotion( false )
        end
    end )
end

function GM:PlayerDroppedWeapon( ply, weapon )
    local timerName = "JB_WeaponDrop #" .. weapon:EntIndex()
    timer.Create( timerName, 1, 1, function()
        timer.Remove( timerName )
        if not weapon:IsValid() then return end

        local phys = weapon:GetPhysicsObject()
        if not phys or not phys:IsValid() then return end

        local pos = weapon:LocalToWorld( weapon:OBBCenter() )
        local mins, maxs = weapon:GetCollisionBounds()

        local tr = util.TraceLine( {
            ["start"] = pos,
            ["endpos"] = pos + Vector( 0, 0, mins[ 3 ] - 2 ),
            ["mask"] = MASK_SOLID_BRUSHONLY,
            ["mins"] = mins,
            ["maxs"] = maxs
        } )

        if tr.Hit then
            phys:EnableMotion( false )
            return
        end

        self:PlayerDroppedWeapon( ply, weapon )
    end )
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
        if math.random( 1, 10 ) == 1 then
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

function GM:PlayerDeathThink( ply )
    if not ply:IsBot() and self.PlayableTeams[ ply:Team() ] and not ( self:IsRoundPreparing() or self:IsWaitingPlayers() ) then return end
    ply:Spawn()
end

function GM:IsSpawnpointSuitable( ply, entity, bMakeSuitable )
    if not self.PlayableTeams[ ply:Team() ] then
        return true
    end

    local pos = entity:GetPos()
    local mins, maxs = ply:GetHull()

    local tr = util.TraceHull( {
        ["start"] = pos,
        ["endpos"] = pos,
        ["mask"] = MASK_PLAYERSOLID,
        ["mins"] = mins,
        ["maxs"] = maxs
    } )

    return not tr.Hit
end

function GM:TeamPlayerDeath( ply, teamID )
    if self:IsRoundPreparing() or self:IsWaitingPlayers() then return end
    ply:SetTeam( TEAM_SPECTATOR )
end

function GM:PlayerSilentDeath( ply )
    local teamID = ply:Team()
    if self.PlayableTeams[ teamID ] then
        hook.Run( "TeamPlayerDeath", ply, teamID )
    end
end

function GM:PlayerDeath( ply, inflictor, attacker )
    local teamID = ply:Team()
    if self.PlayableTeams[ teamID ] then
        hook.Run( "TeamPlayerDeath", ply, teamID )
    end

    if IsValid( attacker ) and attacker:GetClass() == "trigger_hurt" then
        attacker = ply
    end

    if IsValid( attacker ) and attacker:IsVehicle() and IsValid( attacker:GetDriver() ) then
        attacker = attacker:GetDriver()
    end

    if not IsValid( inflictor ) and IsValid( attacker ) then
        inflictor = attacker
    end

    -- Convert the inflictor to the weapon that they're holding if we can.
    -- This can be right or wrong with NPCs since combine can be holding a
    -- pistol but kill you by hitting you with their arm.
    if IsValid( inflictor ) and inflictor == attacker and ( inflictor:IsPlayer() or inflictor:IsNPC() ) then
        inflictor = inflictor:GetActiveWeapon()
        if not IsValid( inflictor ) then
            inflictor = attacker
        end
    end

    if attacker == ply then
        self:SendDeathNotice( nil, "suicide", ply, 0 )
        MsgAll( attacker:Nick() .. " suicided!\n" )
        return
    end

    if attacker:IsPlayer() then
        self:SendDeathNotice( attacker, inflictor:GetClass(), ply, 0 )
        MsgAll( attacker:Nick() .. " killed " .. ply:Nick() .. " using " .. inflictor:GetClass() .. "\n" )
        return
    end

    local flags = 0
    if attacker:IsNPC() and attacker:Disposition( ply ) ~= D_HT then
        flags = flags + DEATH_NOTICE_FRIENDLY_ATTACKER
    end

    self:SendDeathNotice( self:GetDeathNoticeEntityName( attacker ), inflictor:GetClass(), ply, 0 )

    MsgAll( ply:Nick() .. " was killed by " .. attacker:GetClass() .. "\n" )
end

function GM:PlayerShouldTakeDamage( ply, attacker )
    if self:IsRoundPreparing() then
        return false
    end

    if ply:Team() == TEAM_GUARD and attacker:IsPlayer() then
        return attacker:Team() == TEAM_PRISONER
    end

    return true
end

function GM:GetFallDamage( ply, speed )
    return math.max( 0, math.ceil( 0.2418 * speed - 141.75 ) )
end

function GM:AllowPlayerPickup( ply, entity )
    return self.PlayableTeams[ ply:Team() ]
end

function GM:PlayerCanPickupItem( ply, entity )
    return self.PlayableTeams[ ply:Team() ]
end

function GM:PlayerCanPickupWeapon( ply, weapon )
    return self.PlayableTeams[ ply:Team() ] and not ply:HasWeapon( weapon:GetClass() )
end

function GM:PlayerNoClip( ply, desiredState )
    if ply:IsSuperAdmin() then
        return true
    end

    return not desiredState
end

function GM:CanPlayerSuicide( ply )
    if self:IsRoundPreparing() then
        return false
    end

    return self.PlayableTeams[ ply:Team() ]
end

function GM:PlayerSwitchFlashlight( ply )
    if ply:Team() == TEAM_GUARD then
        return true
    end

    return ply:CanUseFlashlight()
end

function GM:PlayerDeathSound( ply )
    return ply:Team() ~= TEAM_GUARD
end

function GM:PlayerUse( ply, entity )
    return true
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

    if self.PlayableTeams[ teamID ] then
        if self:IsRoundPreparing() or self:IsWaitingPlayers() then
            if teamID == TEAM_GUARD then
                local guards = team.GetPlayers( TEAM_GUARD )
                if #guards == 0 then
                    return true
                end

                if ( #guards / #team.GetPlayers( TEAM_PRISONER ) ) < 0.35 then
                    return true
                end

                -- TODO: here chat message
                return false
            end

            return true
        end

        -- TODO: here chat message
        return false
    end

    return true
end

function GM:PlayerJoinTeam( ply, teamID )
    if ply:Alive() then
        if self.PlayableTeams[ ply:Team() ] then
            ply:Kill()
        else
            ply:KillSilent()
        end
    end

    ply:SetTeam( teamID )
end

function GM:PlayerRequestTeam( ply, teamID )
    if not team.Joinable( teamID ) then
        -- TODO: here chat message
        return
    end

    if not self:PlayerCanJoinTeam( ply, teamID ) then
        return
    end

    self:PlayerJoinTeam( ply, teamID )
end

function GM:PlayerDisconnected( ply )
    if ply:Team() == TEAM_PRISONER then
        local guards, prisonerCount = team.GetPlayers( TEAM_GUARD ), team.NumPlayers( TEAM_PRISONER )
        local diff = #guards / ( prisonerCount - 1 )
        if diff > 0.25 then
            for i = 1, #guards do
                local guard, index = table.Random( guards )
                table.remove( guards, index )

                if guard and guard:IsValid() then
                    self:PlayerJoinTeam( guard, TEAM_PRISONER )
                    break
                end
            end
        end
    end
end

concommand.Add( "drop", function( ply )
    local dropWeapon = ply:GetActiveWeapon()
    if not dropWeapon or not dropWeapon:IsValid() then return end

    local model = dropWeapon:GetWeaponWorldModel()
    if not model or not util.IsValidModel( model ) then return end

    ply:DropWeapon( dropWeapon )

    local maxWeight, nextWeapon
    for _, weapon in ipairs( ply:GetWeapons() ) do
        local weight = weapon:GetWeight()
        if not maxWeight or maxWeight <= weight then
            nextWeapon = weapon
            maxWeight = weight
        end
    end

    if not nextWeapon or not nextWeapon:IsValid() then return end
    ply:SelectWeapon( nextWeapon:GetClass() )
end )

function GM:InitPostEntity()
    RunConsoleCommand( "sv_defaultdeployspeed", "1" )
    RunConsoleCommand( "mp_show_voice_icons", "0" )
    GetGlobal2String( "round-state", "waiting" )
end

function GM:StartRound()
    SetGlobalInt( "preparing", CurTime() + self.Preparing:GetInt() )
    GetGlobal2String( "round-state", "preparing" )
end

function GM:EndRound()
    local guardCount, prisonerCount = team.NumPlayers( TEAM_GUARD ), team.NumPlayers( TEAM_PRISONER )
    if guardCount == 0 and prisonerCount == 0 then
        GetGlobal2String( "round-state", "draw" )
    elseif guardCount > prisonerCount then
        GetGlobal2String( "round-state", "guard_victory" )
    else
        GetGlobal2String( "round-state", "prisoner_victory" )
    end
end