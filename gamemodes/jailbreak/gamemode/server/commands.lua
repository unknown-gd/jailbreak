local Jailbreak = Jailbreak

local NOTIFY_ERROR = NOTIFY_ERROR
local CHAN_STATIC = CHAN_STATIC

local HasWarden, Emotion, GameInProgress = Jailbreak.HasWarden, Jailbreak.Emotion, Jailbreak.GameInProgress
local concommand_Add = concommand.Add
local tonumber = tonumber
local CurTime = CurTime
local Entity = Entity

local random = math.random
local hook_Run = hook.Run

-- ========================
-- Change Team Command
-- ========================
do
    local ChangeTeam = Jailbreak.ChangeTeam
    concommand_Add("changeteam", function(self, _, args)
        local teamID = tonumber( args[1] ) or 0
        return ChangeTeam(self, teamID)
    end)
end

-- ========================
-- Warden & Shock Collars
-- ========================
do
    local IsRoundRunning, SetShockCollars, IsShockCollarsActive =
        Jailbreak.IsRoundRunning, Jailbreak.SetShockCollars, Jailbreak.IsShockCollarsActive

    concommand_Add("jb_warden", function( self )
        if not (self and self:IsValid()) then return end

        if not (IsRoundRunning() and self:IsGuard() and self:Alive()) then
            self:SendNotify("#jb.error.warden-failure", NOTIFY_ERROR, 10)
            return
        end

        if (self.m_fWardenDelay or 0) > CurTime() then
            self:SendNotify("#jb.please-wait", NOTIFY_ERROR, 3)
            return
        end

        if self:IsWarden() then
            self.m_fWardenDelay = CurTime() + 5
            self:SetWarden( false )
            return
        end

        if HasWarden() then
            self:SendNotify("#jb.error.warden-exists", NOTIFY_ERROR, 10)
            return
        end

        self.m_fWardenDelay = CurTime() + 3
        return self:SetWarden( true )
    end)

    concommand_Add("jb_shock_collars", function(self, _, args)
        if not (self and self:IsValid()) then return end

        if not (IsRoundRunning() and self:Alive() and self:IsWarden()) then
            self:SendNotify("#jb.error.cant-do-that", NOTIFY_ERROR, 10)
            return
        end

        if (self.m_fShockCollarsDelay or 0) > CurTime() then
            self:SendNotify("#jb.please-wait", NOTIFY_ERROR, 3)
            return
        end

        local requested = args[1]
        if requested ~= nil and #requested ~= 0 then
            SetShockCollars(requested == "1")
        else
            SetShockCollars(not IsShockCollarsActive())
        end

        self.m_fShockCollarsDelay = CurTime() + 1.5
    end)
end

-- ========================
-- Force Round
-- ========================
do
    local SetRoundState, SetRoundTime = Jailbreak.SetRoundState, Jailbreak.SetRoundTime
    local Clamp = math.Clamp

    concommand_Add("jb_force_round", function(self, _, args)
        if self and self:IsValid() and not self:IsSuperAdmin() then return end

        local index = tonumber( args[1] )
        if index then
            return SetRoundState(Clamp(index, 0, 3))
        else
            SetRoundState( 0 )
            return SetRoundTime( 0 )
        end
    end)
end

-- ========================
-- Respawn Command
-- ========================
concommand_Add("jb_respawn", function(self, _, args)
    if self and self:IsValid() and not self:IsAdmin() then return end

    if #args == 0 then
        self:Spawn()
        return
    end

    local index = tonumber( args[1] )
    if not index then return end

    local ply = Entity( index )
    if ply:IsValid() then
        return ply:Spawn()
    end
end)

-- ========================
-- Move Player Command
-- ========================
concommand_Add("jb_move_player", function(self, _, args)
    if self and self:IsValid() and not self:IsAdmin() then return end

    local index = tonumber( args[1] )
    if not index then return end

    local ply = Entity( index )
    if ply and ply:IsValid() then
        if ply:Alive() then ply:Kill() end

        local teamID = tonumber( args[2] )
        if teamID then ply:SetTeam( teamID ) end

        if args[3] then return ply:Spawn() end
    end
end)

-- ========================
-- Kick Player Command
-- ========================
concommand_Add("jb_kick_player", function(self, _, args)
    if self and self:IsValid() and not self:IsAdmin() then return end

    local index = tonumber( args[1] )
    if not index then return end

    local ply = Entity( index )
    if ply:IsValid() then
        local reason = args[2]
        if reason ~= nil then
            return ply:Kick( reason )
        else
            return ply:Kick()
        end
    end
end)

-- ========================
-- Drop Weapon
-- ========================
do
    local IsValidModel = util.IsValidModel

    local function dropWeapon( self )
        if not self:Alive() then return end

        local droppedWeapon = self:GetActiveWeapon()
        if not (droppedWeapon and droppedWeapon:IsValid()) then return end

        local model = droppedWeapon:GetWeaponWorldModel()
        if not (model and #model ~= 0 and IsValidModel( model )) then return end

        local traceResult, isPlayer = self:GetEyeTrace(), false
        if traceResult.Hit then
            local entity = traceResult.Entity
            if entity:IsValid() and entity:IsPlayer() and entity:Alive() then
                isPlayer = true
            end
        end

        self:DropWeapon( droppedWeapon )

        if not droppedWeapon:IsInWorld() then
            self:PickupWeapon( droppedWeapon )
            self:SelectWeapon(droppedWeapon:GetClass())
            return
        end

        if isPlayer then
            self:DoAnimationEvent( ACT_GMOD_GESTURE_ITEM_GIVE )
        else
            self:DoAnimationEvent( ACT_GMOD_GESTURE_ITEM_DROP )
        end

        local maxWeight, nextWeapon = nil, nil
        for _, weapon in ipairs(self:GetWeapons()) do
            local weight = weapon:GetWeight()
            if not maxWeight or maxWeight <= weight then
                nextWeapon = weapon
                maxWeight = weight
            end
        end

        if nextWeapon and nextWeapon:IsValid() then
            self:SelectWeapon(nextWeapon:GetClass())
        end
    end

    concommand_Add("drop", dropWeapon)
    concommand_Add("headtrack_reset_home_pos", dropWeapon)
    Jailbreak.SetChatCommand("drop", dropWeapon, "#jb.chat.command.drop")
    Jailbreak.SetChatCommand("dropweapon", dropWeapon, "#jb.chat.command.drop")
end

-- ========================
-- Markers System
-- ========================
do
    util.AddNetworkString( "Jailbreak::Markers" )

    local Markers, VoiceChatMinDistance, MarkersLifetime, MarkersCount, GetWeaponName =
        Jailbreak.Markers, Jailbreak.VoiceChatMinDistance, Jailbreak.MarkersLifetime, Jailbreak.MarkersCount, Jailbreak.GetWeaponName

    local Start, WriteEntity, WriteBool, WriteVector, Send, Broadcast =
        net.Start, net.WriteEntity, net.WriteBool, net.WriteVector, net.Send, net.Broadcast

    local white = Jailbreak.ColorScheme.white
    local EmitSound = EmitSound
    local TraceLine = util.TraceLine
    local abs = math.abs
    local traceResult = {}
    local trace = { mask = MASK_SHOT, output = traceResult }

    concommand_Add("marker", function( self )
        if not (Markers:GetBool() and self and self:IsValid() and self:Alive()) then return end

        if (self.m_fNextMarker or 0) > CurTime() then
            self:SendNotify("#jb.please-wait", NOTIFY_ERROR, 3)
            return
        end

        local isWarden, isPrisoner = self:IsWarden(), self:IsPrisoner()
        if not isWarden and self:IsGuard() and not HasWarden() then
            isWarden = true
        end

        if not (isWarden or isPrisoner) then
            self:SendNotify("#jb.error.cant-do-that", NOTIFY_ERROR, 10)
            return
        end

        local distance = isWarden and 32768 or 4096

        self:LagCompensation( true )
        trace.filter = self
        trace.start = self:EyePos()
        trace.endpos = trace.start + self:GetAimVector() * distance
        TraceLine( trace )
        self:LagCompensation( false )

        if not traceResult.Hit then return end

        self.m_fNextMarker = CurTime() + (MarkersLifetime:GetInt() / MarkersCount:GetInt())
        local entity = traceResult.Entity
        local isValid = entity and entity:IsValid()

        Start( "Jailbreak::Markers" )
        WriteEntity( self )
        WriteBool( isValid )

        local origin
        if isValid then
            WriteEntity( entity )
            origin = entity:WorldToLocal( traceResult.HitPos )
        else
            origin = traceResult.HitPos
        end

        WriteVector( origin )

        -- Warden markers are must be broadcasted, prisoner markers are must be sent to specific players
        if isWarden then
            Broadcast()

            local rf = RecipientFilter()
            rf:AddPAS( origin )

            if isValid then
                entity:EmitSound( "buttons/button" .. random( 14, 19 ) .. ".wav", 75, random(80, 120), 1, CHAN_STATIC, 0, 1, rf)
            else
                EmitSound( "buttons/button" .. random( 14, 19 ) .. ".wav", origin, 0, CHAN_STATIC, 1, 75, 0, random(80, 120), 1, rf)
            end
        elseif isPrisoner then
            local players = self:GetNearPlayers( VoiceChatMinDistance:GetInt(), true )
            local rf = RecipientFilter()
            local hasSender = false

            for i = 1, #players, 1 do
                local ply = players[ i ]

                if ply == self then
                    hasSender = true
                end

                rf:AddPlayer( ply )
            end

            if not hasSender then
                rf:AddPlayer( self )
            end

            Send( rf )

            if isValid then
                entity:EmitSound("buttons/button" .. random(14, 19) .. ".wav", 75, random(80, 120), 1, CHAN_STATIC, 0, 1, rf)
            else
                EmitSound("buttons/button" .. random(14, 19) .. ".wav", origin, 0, CHAN_STATIC, 1, 75, 0, random(80, 120), 1, rf)
            end
        end

        if isValid then
            if entity:IsPlayer() then
                return Emotion( self, "#jb.chat.pointed-at \"", entity:GetModelColor(), entity:Nick(), white, "\"." )
            elseif entity:IsPlayerRagdoll() then
                return Emotion( self, "#jb.chat.pointed-at \"", entity:GetModelColor(), entity:GetRagdollOwnerNickname(), white, "\"." )
            elseif entity:IsWeapon() then
                return Emotion( self, "#jb.chat.pointed-at \"" .. GetWeaponName( entity ) .. "\"." )
            else
                return Emotion( self, "#jb.chat.pointed-at \"#jb." .. entity:GetClass() .. "\"." )
            end
        elseif traceResult.HitSky then
            return Emotion( self, "#jb.chat.pointed-at \"#jb.sky\"." )
        else
            local dir = traceResult.HitNormal
            if abs( dir[ 1 ] ) > 0.5 or abs( dir[ 2 ] ) > 0.5 then
                return Emotion( self, "#jb.chat.pointed-at \"#jb.wall\"." )
            elseif dir[ 3 ] > 0.5 then
                return Emotion( self, "#jb.chat.pointed-at \"#jb.floor\"." )
            else
                return Emotion( self, "#jb.chat.pointed-at \"#jb.ceiling\"." )
            end
        end
    end )
end

-- ========================
-- Reload Localization
-- ========================
concommand_Add( "jb_reload_localization", function( self )
    if self and self:IsValid() and not self:IsListenServerHost() then return end
    Jailbreak.ReloadLocalization()
end )

-- ========================
-- Shop / Buy Items
-- ========================
do

    local ShopItems, TakeWardenCoins, CanWardenAfford = Jailbreak.ShopItems, Jailbreak.TakeWardenCoins, Jailbreak.CanWardenAfford
    local NOTIFY_GENERIC = NOTIFY_GENERIC

    concommand_Add( "jb_buy", function( self, _, args )
        if not ( GameInProgress() and self and self:IsValid() and self:Alive() and self:IsWarden() ) then return end

        local item = ShopItems[ args[ 1 ] ]
        if not item then return end

        if not self:IsInBuyZone() then
            self:SendNotify( "#jb.shop.not-in-buy-zone", NOTIFY_ERROR, 5 )
            return
        end

        if not CanWardenAfford( item.price ) then
            self:SendNotify( "#jb.shop.not-enough-coins", NOTIFY_ERROR, 5 )
            return
        end

        if hook_Run( "PlayerCanBuyItem", self, item ) == false then
            self:SendNotify( "#jb.error.cant-do-that", NOTIFY_ERROR, 5 )
            return
        end

        local action_fn = item.action

        if not action_fn or action_fn( self, item ) == false then
            self:SendNotify( "#jb.error.cant-do-that", NOTIFY_ERROR, 5 )
            return
        end

        TakeWardenCoins( item.price )

        self:EmitSound( "ambient/levels/labs/coinslot1.wav", 75, random( 80, 120 ), 1, CHAN_STATIC, 0, 1 )
        self:SendNotify( "#jb.shop.you-bought \"" .. item.title .. "\"", NOTIFY_GENERIC, 5 )
        Emotion( self, "#jb.chat.bought \"" .. item.title .. "\"." )
        hook_Run( "PlayerBoughtItem", self, item )
    end )

end

-- ========================
-- Paint Entity
-- ========================
concommand_Add( "jb_paint_entity_apply", function( self, _, args )
    if not ( self and self:IsValid() ) then return end

    if not self:Alive() then
        self:SendNotify( "#jb.error.cant-do-that", NOTIFY_ERROR, 5 )
        return
    end

    local entity = Entity( tonumber( args[ 1 ] or "0", 10 ) or 0 )
    if not ( entity and entity:IsValid() and entity:IsPaintCan() ) then return end
    if entity:GetPos():Distance( self:GetPos() ) > 72 then return end

    local color = string.Split(args[2] or "0 0 0", " ")
    self:SetColor( Color( color[ 1 ], color[ 2 ], color[ 3 ] ) )
end )

-- ========================
-- Lose Consciousness
-- ========================
do

    local Jailbreak_AllowPlayersLoseConsciousness = Jailbreak.AllowPlayersLoseConsciousness

    concommand_Add( "jb_lose_consciousness", function( self )
        if not ( self and self:IsValid() ) then return end

        if not self:Alive() or self:IsPlayingTaunt() or not self:IsInWorld() then
            self:SendNotify( "#jb.error.cant-do-that", NOTIFY_ERROR, 5 )
            return
        end

        if ( self.m_fLoseConsciousnessDelay or 0 ) > CurTime() then
            self:SendNotify( "#jb.please-wait", NOTIFY_ERROR, 3 )
            return
        end

        self.m_fLoseConsciousnessDelay = CurTime() + 3

        if not ( GameInProgress() and Jailbreak_AllowPlayersLoseConsciousness:GetBool() ) then
            self:SendNotify("#jb.error.cant-do-that", NOTIFY_ERROR, 5)
            return
        end

        self:SetLoseConsciousness( not self:IsLoseConsciousness() )
    end )

end

-- ========================
-- Restart Server
-- ========================
concommand_Add( "jb_restart_server", function( ply )
    if ply and ply:IsValid() and not ( ply:IsSuperAdmin() or ply:IsListenServerHost() ) then return end
    if #player.GetHumans() > 1 then return end
    RunConsoleCommand( "_restart" )
end )
