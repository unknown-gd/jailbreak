local SERVER = SERVER
AddCSLuaFile()

SWEP.PrintName = "#GMOD_Fists"
SWEP.Author = "Kilburn, robotboy655, MaxOfS2D & Tenrys"
SWEP.Purpose = "Well we sure as hell didn't use guns! We would just wrestle Hunters to the ground with our bare hands! I used to kill ten, twenty a day, just using my fists."

SWEP.Slot = 0
SWEP.SlotPos = 4

SWEP.Spawnable = true

SWEP.ViewModel = Model( "models/weapons/c_arms.mdl" )
SWEP.WorldModel = ""
SWEP.ViewModelFOV = 54
SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

SWEP.DrawAmmo = false

SWEP.HitDistance = 48

local swingSound = Sound( "WeaponFrag.Throw" )
local HitSound = Sound( "Flesh.ImpactHard" )

function SWEP:Initialize()
    self:SetHoldType( "normal" )
end

function SWEP:SetupDataTables()
    self:NetworkVar( "Float", 0, "NextMeleeAttack" )
    self:NetworkVar( "Float", 1, "NextIdle" )
    self:NetworkVar( "Int", 2, "Combo" )
end

function SWEP:GetViewModel()
    return self:GetOwner():GetViewModel()
end

function SWEP:PlaySequence( sequenceName, onFinish )
    self.SequenceFinished = false

    local ply = self:GetOwner()
    local vm = ply:GetViewModel()

    local seqid = vm:LookupSequence( sequenceName )
    if not seqid or seqid <= 0 then return end
    vm:SendViewModelMatchingSequence( seqid )

    local duration = vm:SequenceDuration( seqid ) / vm:GetPlaybackRate()
    local nextSequence = CurTime() + duration

    timer.Simple( duration, function()
        if not self:IsValid() then return end
        if self:GetOwner() ~= ply then return end
        self.SequenceFinished = true
        if not onFinish then return end
        onFinish( ply, vm )
    end )

    return nextSequence, duration
end

function SWEP:SetNextFire( curTime )
    self:SetNextPrimaryFire( curTime )
    self:SetNextSecondaryFire( curTime )
end

function SWEP:PrimaryAttack( right )
    if self:GetHoldType() == "normal" then return end
    if self:GetNextIdle() == 0 then return end
    if self.Pulls then return end

    local owner = self:GetOwner()
    owner:SetAnimation( PLAYER_ATTACK1 )
    owner:EmitSound( swingSound )

    local anim = "fists_left"
    if right then
        anim = "fists_right"
    end

    local combo = self:GetCombo()
    if combo >= 2 then
        anim = "fists_uppercut"
    end

    local seqFinish, delay = self:PlaySequence( anim )
    self:SetNextFire( seqFinish )
    self:SetNextIdle( seqFinish )

    self:SetNextMeleeAttack( CurTime() + ( delay / 4 ) / math.max( combo, 1 ) )
end

function SWEP:SecondaryAttack()
    self:PrimaryAttack( true )
end

local phys_pushscale = GetConVar( "phys_pushscale" )

function SWEP:DealDamage()

    local owner = self:GetOwner()

    local anim = self:GetSequenceName(owner:GetViewModel():GetSequence())

    owner:LagCompensation( true )

    local tr = util.TraceLine( {
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * self.HitDistance,
        filter = owner,
        mask = MASK_SHOT_HULL
    } )

    if not IsValid( tr.Entity ) then
        tr = util.TraceHull( {
            start = owner:GetShootPos(),
            endpos = owner:GetShootPos() + owner:GetAimVector() * self.HitDistance,
            filter = owner,
            mins = Vector( -10, -10, -8 ),
            maxs = Vector( 10, 10, 8 ),
            mask = MASK_SHOT_HULL
        } )
    end

    -- We need the second part for single player because SWEP:Think is ran shared in SP
    if tr.Hit and not ( game.SinglePlayer() and CLIENT ) then
        self:EmitSound( HitSound )
    end

    local hit = false
    local scale = phys_pushscale:GetFloat()

    if SERVER and IsValid( tr.Entity ) and ( tr.Entity:IsNPC() or tr.Entity:IsPlayer() or tr.Entity:Health() > 0 ) then
        local dmginfo = DamageInfo()

        local attacker = owner
        if not IsValid( attacker ) then
            attacker = self
        end

        dmginfo:SetAttacker( attacker )

        dmginfo:SetInflictor( self )
        dmginfo:SetDamage( math.random( 8, 12 ) )

        if anim == "fists_left" then
            dmginfo:SetDamageForce( owner:GetRight() * 4912 * scale + owner:GetForward() * 9998 * scale ) -- Yes we need those specific numbers
        elseif anim == "fists_right" then
            dmginfo:SetDamageForce( owner:GetRight() * -4912 * scale + owner:GetForward() * 9989 * scale )
        elseif anim == "fists_uppercut" then
            dmginfo:SetDamageForce( owner:GetUp() * 5158 * scale + owner:GetForward() * 10012 * scale )
            dmginfo:SetDamage( math.random( 12, 24 ) )
        end

        SuppressHostEvents( NULL ) -- Let the breakable gibs spawn in multiplayer on client
        tr.Entity:TakeDamageInfo( dmginfo )
        SuppressHostEvents( owner )

        hit = true
    end

    if IsValid( tr.Entity ) then
        local phys = tr.Entity:GetPhysicsObject()
        if IsValid( phys ) then
            phys:ApplyForceOffset( owner:GetAimVector() * 80 * phys:GetMass() * scale, tr.HitPos )
        end
    end

    if SERVER then
        if hit and anim ~= "fists_uppercut" then
            self:SetCombo( self:GetCombo() + 1 )
        else
            self:SetCombo( 0 )
        end
    end

    owner:LagCompensation( false )
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:Show()
    self:GetViewModel():SetNoDraw( false )
    self:SetHoldType( "fist" )
    self.Pulls = true

    self:SetNextIdle( self:PlaySequence( "fists_draw", function()
        self.Pulls = false
    end ) )
end

function SWEP:Hide()
    self.Pulls = true
    self:SetNextIdle( 0 )
    self:SetHoldType( "normal" )
    self:PlaySequence( "fists_holster", function( _, vm )
        vm:SetNoDraw( true )
        self.Pulls = false
    end )
end

function SWEP:Deploy()
    if self:GetHoldType() == "normal" then
        self:GetViewModel():SetNoDraw( true )
    else
        self:Show()
    end

    if SERVER then
        self:SetCombo( 0 )
    end

    return true
end

function SWEP:Holster( weapon )
    self:SetNextMeleeAttack( 0 )
    self:SetNextIdle( 0 )
    return true
end

function SWEP:Think()
    if self:GetHoldType() ~= "fist" then return end
    if self.Pulls then return end
    local curTime = CurTime()

    local idletime = self:GetNextIdle()
    if idletime > 0 and curTime > idletime then
        self:SetNextIdle( self:PlaySequence( "fists_idle_0" .. math.random( 1, 2 ) ) )
    end

    local meleetime = self:GetNextMeleeAttack()
    if meleetime > 0 and curTime > meleetime then
        self:SetNextMeleeAttack( 0 )
        self:DealDamage()
    end

    if SERVER and curTime > self:GetNextPrimaryFire() + 0.1 then
        self:SetCombo( 0 )
    end
end

function SWEP:Reload()
    local curTime, lastReload = CurTime(), self.LastReload or 0
    self.LastReload = curTime

    if curTime - lastReload <= 0.025 then return end
    if self.Pulls then return end

    if self:GetHoldType() == "normal" then
        self:Show()
    else
        self:Hide()
    end
end