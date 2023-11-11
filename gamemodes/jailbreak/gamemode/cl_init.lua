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
    hook_Run( "HUDDrawPickupHistory" )
    hook_Run( "DrawDeathNotice", 0.85, 0.04 )
end

hook.Add( "HUDPaint", "Jailbreak::RoundInfo", function()
    draw.DrawText( string.upper( language.GetPhrase( "jb.round." .. GAMEMODE:GetRoundState() ) ), "DermaLarge", ScrW() / 2, 32, color_white, TEXT_ALIGN_CENTER )
end )

---
--- Colors
---

local color_white = Color(255, 255, 255)
local color_red = Color(255, 0, 0)
local color_bacground = Color(0, 0, 0, 200)

---
--- Gigga Nigga Scoreboard (by PrikolMen:-b (I'm joking he's probably dead, we coudn't know exactly is he alive or not, anyway this code has not been written by PrikolMen:-b and not UknownDeveloper))
---

local PANEL_META = FindMetaTable("Panel")

do
    local PANEL = {}

    function PANEL:Init()
        local avatar = vgui.Create("AvatarImage", self)
        if IsValid(avatar) then
            self.Avatar = avatar
        end


    end

    function PANEL:SetPlayer(ply)
        if not IsValid(ply) and not ply:IsPlayer() then return end

        self.Player = ply
        self.Nick = ply:Nick()
        self.Ping = ply:Ping()
        self.Frags = ply:Frags()
        self.Deaths = ply:Deaths()

        self.Avatar:SetPlayer(ply, 32)
    end

    function PANEL:PerformLayout()
        local tall = ScreenScaleH(16)

        self:SetTall(tall)

        local marginBottom = ScreenScale(3)
        self:DockMargin(0, 0, 0, marginBottom)

        local avatar = self.Avatar
        if IsValid(avatar) then
            local wide, tall = self:GetSize()
            local avatarSize = tall - ScreenScale(2)
            local marginLeft = ScreenScale(6)

            avatar:SetPos(marginLeft, tall / 2 - avatarSize / 2)
            avatar:SetSize(avatarSize, avatarSize)
        end
    end

    function PANEL:Paint(w, h)
        local round = 20

        draw.RoundedBox(round, 0, 0, w, h, color_bacground)

        if not IsValid(self.Player) then return end
        local avatar = self.Avatar
        if not IsValid(avatar) then return end

        local marginLeft, marginTop = ScreenScale(5), ScreenScaleH(0.4)
        draw.DrawText(self.Nick, "DermaLarge", marginLeft * 2 + avatar:GetWide(), marginTop, color_white, TEXT_ALIGN_LEFT)
    end

    vgui.Register("JB.Scoreboard.Player", PANEL)
end

---
--- MAIN PANEL
---

do
    local PANEL = {}

    function PANEL:Init()
    end

    function PANEL:PerformLayout(w, h)
        local wide, tall = ScreenScale(300), ScreenScaleH(380)

        self:SetSize(wide, tall)
        self:Center()

        local paddingTop, paddingHorizontal = ScreenScaleH(20), ScreenScale(10)
        self:DockPadding(paddingHorizontal, paddingTop, paddingHorizontal, 0)
    end

    function PANEL:DeletePlayers()
        if not istable(self.Players) then
            self.Players = {}

            return
        end

        for _, ply in ipairs(self.Players) do
            if not IsValid(ply) then continue end

            ply:Remove()
        end

        self.Players = {}
    end

    function PANEL:CreatePlayers()
        self:DeletePlayers()

        local players = player.GetAll()
        for _, ply in ipairs(players) do
            if not IsValid(ply) then continue end

            local playerPanel = vgui.Create("JB.Scoreboard.Player", self)
            if not IsValid(playerPanel) then continue end
            table.insert(self.Players, playerPanel)

            playerPanel:SetPlayer(ply)
            playerPanel:Dock(TOP)
        end
    end

    function PANEL:Show()
        self:CreatePlayers()

        return PANEL_META.Show(self)
    end

    function PANEL:Hide()
        self:DeletePlayers()

        return PANEL_META.Hide(self)
    end

    function PANEL:Paint(w, h)
        surface.SetDrawColor(color_red)
        surface.DrawRect(0, 0, w, h)

        draw.DrawText("Your mom's gamemode", "DermaLarge", w / 2, 0, color_white, TEXT_ALIGN_CENTER)
    end

    vgui.Register("JB.Scoreboard", PANEL)
end

local scoreboard = GM.ScoreBoard or GAMEMODE and GAMEMODE.ScoreBoard

if IsValid(scoreboard) then
    scoreboard:Remove()
end

function GM:ScoreboardShow()
    local scoreboard = self.ScoreBoard
    if not IsValid(scoreboard) then
        scoreboard = vgui.Create("JB.Scoreboard", GetHUDPanel())
        self.ScoreBoard = scoreboard
        -- print("Created")
    end

    scoreboard:Show()

    return false
end

function GM:ScoreboardHide()
    local scoreboard = self.ScoreBoard
    if not IsValid(scoreboard) then return end

    scoreboard:Hide()
end