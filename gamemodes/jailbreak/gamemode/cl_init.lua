include( "shared.lua" )

CreateConVar( "cl_playercolor", "0.3 0.3 0.3", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The value is a Vector - so between 0-1 - not between 0-255" )
CreateConVar( "cl_weaponcolor", "0.30 1.80 2.10", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The value is a Vector - so between 0-1 - not between 0-255" )
CreateConVar( "cl_playerskin", "0", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The skin to use, if the model has any" )
CreateConVar( "cl_playerbodygroups", "0", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The bodygroups to use, if the model has any" )
local hook_Run = hook.Run

function GM:InitPostEntity()
    self:ShowTeam()
end

function GM:OnSpawnMenuOpen()
    RunConsoleCommand( "lastinv" )
end

function GM:PostProcessPermitted( name )
    return false
end

function GM:PlayerButtonUp( ply, keyCode )
    if keyCode ~= KEY_G then return end

    local bind = input.LookupKeyBinding( keyCode )
    if bind and bind ~= "" then return end

    RunConsoleCommand( "drop" )
end

local tauntCamera = TauntCamera()

function GM:ShouldDrawLocalPlayer( ply )
    return tauntCamera:ShouldDrawLocalPlayer( ply, ply:IsPlayingTaunt() )
end

function GM:CreateMove( cmd )
    if drive.CreateMove( cmd ) then
        return true
    end

    local ply = LocalPlayer()
    if tauntCamera:CreateMove( cmd, ply, ply:IsPlayingTaunt() ) then
        return true
    end
end

function GM:CalcView( ply, origin, angles, fov, znear, zfar )
    local view = {
        ["origin"] = origin,
        ["angles"] = angles,
        ["fov"] = fov,
        ["znear"] = znear,
        ["zfar"] = zfar,
        ["drawviewer"] = false
    }

    if tauntCamera:CalcView( view, ply, ply:IsPlayingTaunt() ) then
        return view
    end

    if ply:InVehicle() then
        return hook_Run( "CalcVehicleView", ply:GetVehicle(), ply, view )
    end

    if drive.CalcView( ply, view ) then
        return view
    end

    local weapon = ply:GetActiveWeapon()
    if IsValid( weapon ) then
        local func = weapon.CalcView
        if func then
            local origin, angles, fov = func( weapon, ply, Vector( view.origin ), Angle( view.angles ), view.fov )
            view.origin, view.angles, view.fov = origin or view.origin, angles or view.angles, fov or view.fov
        end
    end

    return view
end

function GM:Think()
    local pos = EyePos()
    for _, ply in ipairs( player.GetHumans() ) do
        if not ply:IsSpeaking() then continue end
        ply:SetVoiceVolumeScale( math.Clamp( 1 - pos:DistToSqr( ply:EyePos() ) / self.VoiceChatDistance, 0, 1 ) )
    end
end

function GM:HUDPaint()
    hook_Run( "HUDDrawTargetID" )
    hook_Run( "HUDDrawPickupHistory" )
    hook_Run( "DrawDeathNotice", 0.85, 0.04 )
end

hook.Add( "HUDPaint", "Jailbreak::RoundInfo", function()
    draw.DrawText( string.upper( language.GetPhrase( "jb.round." .. GAMEMODE:GetRoundState() ) ), "DermaLarge", ScrW() / 2, 32, color_white, TEXT_ALIGN_CENTER )
end )