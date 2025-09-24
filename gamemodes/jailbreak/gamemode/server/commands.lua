---@class Jailbreak
local Jailbreak = Jailbreak

local HasWarden, Emotion, GameInProgress = Jailbreak.HasWarden, Jailbreak.Emotion, Jailbreak.GameInProgress
local concommand_Add = concommand.Add
local random = math.random
local tonumber = tonumber
local CurTime = CurTime
local Entity = Entity
local Run = hook.Run

local NOTIFY_GENERIC = NOTIFY_GENERIC
local NOTIFY_ERROR = NOTIFY_ERROR
local CHAN_STATIC = CHAN_STATIC

concommand_Add( "changeteam", function( player_sender, _, args )
    local team_id = args[ 1 ]
    if team_id then
        team_id = tonumber( team_id ) or 0
    else
        team_id = 0
    end

    Jailbreak.ChangeTeam( player_sender, team_id )
end )

do

    local IsRoundRunning, SetShockCollars, IsShockCollarsActive = Jailbreak.IsRoundRunning, Jailbreak.SetShockCollars, Jailbreak.IsShockCollarsActive

    concommand_Add( "jb_warden", function( player_sender, _, args )
        if not (player_sender and player_sender:IsValid()) then
            return
        end

        if not (IsRoundRunning() and player_sender:IsGuard() and player_sender:Alive()) then
            player_sender:SendNotify( "#jb.error.warden-failure", NOTIFY_ERROR, 10 )
            return
        end

        if (player_sender.m_fWardenDelay or 0) > CurTime() then
            player_sender:SendNotify( "#jb.please-wait", NOTIFY_ERROR, 3 )
            return
        end

        if player_sender:IsWarden() then
            player_sender.m_fWardenDelay = CurTime() + 5
            player_sender:SetWarden( false )
            return
        end

        if HasWarden() then
            player_sender:SendNotify( "#jb.error.warden-exists", NOTIFY_ERROR, 10 )
            return
        end

        player_sender.m_fWardenDelay = CurTime() + 3
        return player_sender:SetWarden( true )
    end )

    concommand_Add( "jb_shock_collars", function( player_sender, _, args )
        if not (player_sender and player_sender:IsValid()) then
            return
        end

        if not (IsRoundRunning() and player_sender:Alive() and player_sender:IsWarden()) then
            player_sender:SendNotify( "#jb.error.cant-do-that", NOTIFY_ERROR, 10 )
            return
        end

        if (player_sender.m_fShockCollarsDelay or 0) > CurTime() then
            player_sender:SendNotify( "#jb.please-wait", NOTIFY_ERROR, 3 )
            return
        end

        local requested = args[ 1 ]
        if requested ~= nil and #requested ~= 0 then
            SetShockCollars( requested == "1" )
        else
            SetShockCollars( not IsShockCollarsActive() )
        end

        player_sender.m_fShockCollarsDelay = CurTime() + 1.5
    end )

end

do

    local SetRoundState, SetRoundTime = Jailbreak.SetRoundState, Jailbreak.SetRoundTime
    local Clamp = math.Clamp

    concommand_Add( "jb_force_round", function( player_sender, _, args )
        if player_sender and player_sender:IsValid() and not player_sender:IsSuperAdmin() then
            return
        end

        local index = args[ 1 ]
        if index then
            SetRoundState( Clamp( tonumber( index, 10 ) or 0, 0, 3 ) )
            return
        end

        SetRoundState( 0 )
        SetRoundTime( 0 )
    end )

end

concommand_Add( "jb_respawn", function( player_sender, _, args )
    if player_sender and player_sender:IsValid() and not player_sender:IsAdmin() then
        return
    end

    if #args == 0 then
        player_sender:Spawn()
        return
    end

    local index = tonumber( args[ 1 ] )
    if not index then
        return
    end

    local ply = Entity( index )
    if ply:IsValid() then
        return ply:Spawn()
    end
end )
concommand_Add( "jb_move_player", function( player_sender, _, args )
    if player_sender and player_sender:IsValid() and not player_sender:IsAdmin() then
        return
    end

    local index = tonumber( args[ 1 ] )
    if not index then
        return
    end

    local ply = Entity( index )
    if ply and ply:IsValid() then
        if ply:Alive() then
            ply:Kill()
        end

        local team_id = tonumber( args[ 2 ] )
        if team_id then
            ply:SetTeam( team_id )
        end

        if args[ 3 ] then
            return ply:Spawn()
        end
    end
end )
concommand_Add( "jb_kick_player", function( player_sender, _, args )
    if player_sender and player_sender:IsValid() and not player_sender:IsAdmin() then
        return
    end

    local index = tonumber( args[ 1 ] )
    if not index then
        return
    end

    local ply = Entity( index )
    if ply:IsValid() then
        local reason = args[ 2 ]
        if reason ~= nil then
            return ply:Kick( reason )
        else
            return ply:Kick()
        end
    end
end )
do
    local IsValidModel = util.IsValidModel
    local function dropWeapon( player_sender )
        if not player_sender:Alive() then
            return
        end

        local droppedWeapon = player_sender:GetActiveWeapon()
        if not (droppedWeapon and droppedWeapon:IsValid()) then
            return
        end

        local model = droppedWeapon:GetWeaponWorldModel()
        if not (model and #model ~= 0 and IsValidModel( model )) then
            return
        end

        local traceResult, isPlayer = player_sender:GetEyeTrace(), false
        if traceResult.Hit then
            local entity = traceResult.Entity
            if entity:IsValid() and entity:IsPlayer() and entity:Alive() then
                isPlayer = true
            end
        end

        player_sender:DropWeapon( droppedWeapon )
        if not droppedWeapon:IsInWorld() then
            player_sender:PickupWeapon( droppedWeapon )
            player_sender:SelectWeapon( droppedWeapon:GetClass() )
            return
        end

        if isPlayer then
            player_sender:DoAnimationEvent( ACT_GMOD_GESTURE_ITEM_GIVE )
        else
            player_sender:DoAnimationEvent( ACT_GMOD_GESTURE_ITEM_DROP )
        end

        local maxWeight, nextWeapon = nil, nil
        local _list_0 = player_sender:GetWeapons()
        for _index_0 = 1, #_list_0 do
            local weapon = _list_0[ _index_0 ]
            local weight = weapon:GetWeight()
            if not maxWeight or maxWeight <= weight then
                nextWeapon = weapon
                maxWeight = weight
            end
        end

        if not (nextWeapon and nextWeapon:IsValid()) then
            return
        end

        return player_sender:SelectWeapon( nextWeapon:GetClass() )
    end
    concommand_Add( "drop", dropWeapon )
    concommand_Add( "headtrack_reset_home_pos", dropWeapon )
    Jailbreak.SetChatCommand( "drop", dropWeapon, "#jb.chat.command.drop" )
    Jailbreak.SetChatCommand( "dropweapon", dropWeapon, "#jb.chat.command.drop" )
end
do
    util.AddNetworkString( "Jailbreak::Markers" )
    local Markers, VoiceChatMinDistance, MarkersLifetime, MarkersCount, GetWeaponName = Jailbreak.Markers, Jailbreak.VoiceChatMinDistance, Jailbreak.MarkersLifetime, Jailbreak.MarkersCount, Jailbreak.GetWeaponName
    local Start, WriteEntity, WriteBool, WriteVector, Send, Broadcast
    do
        local _obj_0 = net
        Start, WriteEntity, WriteBool, WriteVector, Send, Broadcast = _obj_0.Start, _obj_0.WriteEntity, _obj_0.WriteBool, _obj_0.WriteVector, _obj_0.Send, _obj_0.Broadcast
    end
    local white = Jailbreak.ColorScheme.white
    local EmitSound = EmitSound
    local TraceLine = util.TraceLine
    local abs = math.abs
    local traceResult = {}
    local trace = {
        mask = MASK_SHOT,
        output = traceResult
    }
    concommand_Add( "jb_marker", function( player_sender )
        if not (Markers:GetBool() and player_sender and player_sender:IsValid() and player_sender:Alive()) then
            return
        end

        if (player_sender.m_fNextMarker or 0) > CurTime() then
            player_sender:SendNotify( "#jb.please-wait", NOTIFY_ERROR, 3 )
            return
        end

        local isWarden, isPrisoner = player_sender:IsWarden(), player_sender:IsPrisoner()
        if not isWarden and player_sender:IsGuard() and not HasWarden() then
            isWarden = true
        end

        if not (isWarden or isPrisoner) then
            player_sender:SendNotify( "#jb.error.cant-do-that", NOTIFY_ERROR, 10 )
            return
        end

        local distance = 0
        if isWarden then
            distance = 32768
        elseif isPrisoner then
            distance = 4096
        end

        player_sender:LagCompensation( true )
        trace.filter = player_sender
        trace.start = player_sender:EyePos()
        trace.endpos = trace.start + player_sender:GetAimVector() * distance
        TraceLine( trace )
        player_sender:LagCompensation( false )
        if not traceResult.Hit then
            return
        end

        player_sender.m_fNextMarker = CurTime() + (MarkersLifetime:GetInt() / MarkersCount:GetInt())
        local entity = traceResult.Entity
        local isValid = entity and entity:IsValid()
        Start( "Jailbreak::Markers" )
        WriteEntity( player_sender )
        WriteBool( isValid )
        local origin = nil
        if isValid then
            WriteEntity( entity )
            origin = entity:WorldToLocal( traceResult.HitPos )
        else
            origin = traceResult.HitPos
        end

        WriteVector( origin )
        if isWarden then
            Broadcast()
            local rf = RecipientFilter()
            rf:AddPAS( origin )
            if isValid then
                entity:EmitSound( "buttons/button" .. random( 14, 19 ) .. ".wav", 75, random( 80, 120 ), 1, CHAN_STATIC, 0, 1, rf )
            else
                EmitSound( "buttons/button" .. random( 14, 19 ) .. ".wav", origin, 0, CHAN_STATIC, 1, 75, 0, random( 80, 120 ), 1, rf )
            end
        elseif isPrisoner then
            local rf = RecipientFilter()
            local hasSender = false
            local _list_0 = player_sender:GetNearPlayers( VoiceChatMinDistance:GetInt(), false, false, false )
            for _index_0 = 1, #_list_0 do
                local ply = _list_0[ _index_0 ]
                if ply == player_sender then
                    hasSender = true
                end

                rf:AddPlayer( ply )
            end

            if not hasSender then
                rf:AddPlayer( player_sender )
            end

            Send( rf )
            if isValid then
                entity:EmitSound( "buttons/button" .. random( 14, 19 ) .. ".wav", 75, random( 80, 120 ), 1, CHAN_STATIC, 0, 1, rf )
            else
                EmitSound( "buttons/button" .. random( 14, 19 ) .. ".wav", origin, 0, CHAN_STATIC, 1, 75, 0, random( 80, 120 ), 1, rf )
            end
        end

        if isValid then
            player_sender:AnimRestartNetworkedGesture( GESTURE_SLOT_CUSTOM, ACT_SIGNAL_GROUP, true )
        else
            player_sender:AnimRestartNetworkedGesture( GESTURE_SLOT_CUSTOM, ACT_SIGNAL_FORWARD, true )
        end

        if entity:IsValid() then
            if entity:IsPlayer() then
                return Emotion( player_sender, "#jb.chat.pointed-at \"", entity:GetModelColor(), entity:Nick(), white, "\"." )
            elseif entity:IsPlayerRagdoll() then
                return Emotion( player_sender, "#jb.chat.pointed-at \"", entity:GetModelColor(), entity:GetRagdollOwnerNickname(), white, "\"." )
            elseif entity:IsWeapon() then
                return Emotion( player_sender, "#jb.chat.pointed-at \"" .. GetWeaponName( entity ) .. "\"." )
            else
                return Emotion( player_sender, "#jb.chat.pointed-at \"#jb." .. entity:GetClass() .. "\"." )
            end
        elseif traceResult.HitSky then
            return Emotion( player_sender, "#jb.chat.pointed-at \"#jb.sky\"." )
        else
            local dir = traceResult.HitNormal
            if abs( dir[ 1 ] ) > 0.5 or abs( dir[ 2 ] ) > 0.5 then
                return Emotion( player_sender, "#jb.chat.pointed-at \"#jb.wall\"." )
            elseif dir[ 3 ] > 0.5 then
                return Emotion( player_sender, "#jb.chat.pointed-at \"#jb.floor\"." )
            else
                return Emotion( player_sender, "#jb.chat.pointed-at \"#jb.ceiling\"." )
            end
        end
    end )
end
concommand_Add( "jb_reload_localization", function( player_sender )
    if player_sender and player_sender:IsValid() and not player_sender:IsListenServerHost() then
        return
    end

    return Jailbreak.ReloadLocalization()
end )
do

    local ShopItems, TakeWardenCoins, CanWardenAfford = Jailbreak.ShopItems, Jailbreak.TakeWardenCoins, Jailbreak.CanWardenAfford

    concommand_Add( "jb_buy", function( player_sender, _, args )
        if not (GameInProgress() and player_sender and player_sender:IsValid() and player_sender:Alive() and player_sender:IsWarden()) then
            return
        end

        local item = ShopItems[ args[ 1 ] ]
        if not item then
            return
        end

        if not player_sender:IsInBuyZone() then
            player_sender:SendNotify( "#jb.shop.not-in-buy-zone", NOTIFY_ERROR, 5 )
            return
        end

        if not CanWardenAfford( item.price ) then
            player_sender:SendNotify( "#jb.shop.not-enough-coins", NOTIFY_ERROR, 5 )
            return
        end

        if Run( "PlayerCanBuyItem", player_sender, item ) == false then
            player_sender:SendNotify( "#jb.error.cant-do-that", NOTIFY_ERROR, 5 )
            return
        end

        if not item.action then
            return
        end

        if item.action( player_sender, item ) == false then
            player_sender:SendNotify( "#jb.error.cant-do-that", NOTIFY_ERROR, 5 )
            return
        end

        TakeWardenCoins( item.price )
        player_sender:EmitSound( "ambient/levels/labs/coinslot1.wav", 75, random( 80, 120 ), 1, CHAN_STATIC, 0, 1 )
        player_sender:SendNotify( "#jb.shop.you-bought \"" .. item.title .. "\"", NOTIFY_GENERIC, 5 )
        Emotion( player_sender, "#jb.chat.bought \"" .. item.title .. "\"." )
        Run( "PlayerBoughtItem", player_sender, item )
    end )
end

concommand_Add( "jb_paint_entity_apply", function( player_sender, _, args )
    if not (player_sender and player_sender:IsValid()) then
        return
    end

    if not player_sender:Alive() then
        player_sender:SendNotify( "#jb.error.cant-do-that", NOTIFY_ERROR, 5 )
        return
    end

    local entity = Entity( tonumber( args[ 1 ] or "0" ) or 0 )
    if not (entity and entity:IsValid() and entity:IsPaintCan()) then
        return
    end

    if entity:GetPos():Distance( player_sender:GetPos() ) > 72 then
        return
    end

    local color = string.Split( args[ 2 ] or "0 0 0", " " )
    player_sender:SetColor( Color( color[ 1 ], color[ 2 ], color[ 3 ] ) )
end )

do

    local jb_allow_players_lose_consciousness = GetConVar( "jb_allow_players_lose_consciousness" )

    concommand_Add( "jb_lose_consciousness", function( player_sender )
        if not (player_sender and player_sender:IsValid()) then
            return
        end

        if not player_sender:Alive() or player_sender:IsPlayingTaunt() or not player_sender:IsInWorld() then
            player_sender:SendNotify( "#jb.error.cant-do-that", NOTIFY_ERROR, 5 )
            return
        end

        if (player_sender.m_fLoseConsciousnessDelay or 0) > CurTime() then
            player_sender:SendNotify( "#jb.please-wait", NOTIFY_ERROR, 3 )
            return
        end

        player_sender.m_fLoseConsciousnessDelay = CurTime() + 3

        if not (GameInProgress() and jb_allow_players_lose_consciousness:GetBool()) then
            player_sender:SendNotify( "#jb.error.cant-do-that", NOTIFY_ERROR, 5 )
            return
        end

        player_sender:SetLoseConsciousness( not player_sender:IsLoseConsciousness() )
    end )

end

concommand_Add( "jb_restart_server", function( ply )
    if ply and ply:IsValid() and not (ply:IsSuperAdmin() or ply:IsListenServerHost()) then
        return
    end

    if #player.GetHumans() > 1 then
        return
    end

    RunConsoleCommand( "_restart" )
end )
