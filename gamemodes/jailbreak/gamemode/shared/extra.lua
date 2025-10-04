local entity_GetNetworkValue, entity_SetNetworkValue = ENTITY.GetNW2Var, ENTITY.SetNW2Var
local move_GetVelocity, move_SetVelocity = CMOVEDATA.GetVelocity, CMOVEDATA.SetVelocity
local CLIENT, SERVER = CLIENT, SERVER
local hook_Add = hook.Add
local CurTime = CurTime

---@class Jailbreak
local Jailbreak = Jailbreak

do

	local bit_band = bit.band
	local IN_WALK = IN_WALK

	local attack_filter = bit.bnot( bit.bor( 1, 2048 ) )

	hook_Add( "StartCommand", "Jailbreak::Markers", function( ply, cmd )
		if ply:Alive() then
			local buttons = cmd:GetButtons()
			if bit_band( buttons, IN_WALK ) ~= 0 then
				cmd:SetButtons( bit_band( buttons, attack_filter ) )
			end
		end
	end )

end

hook_Add( "AllowPlayerMove", "Jailbreak::Death Animations", function( ply )
	if entity_GetNetworkValue( ply, "death-animation" ) ~= 0 then
		return false
	end
end )

hook_Add( "PlayerEmitSound", "Jailbreak::Death Animations", function( ply, data )
	if entity_GetNetworkValue( ply, "death-animation" ) ~= 0 then
		return false
	end
end )

hook_Add( "CanPlayerTakeDamage", "Jailbreak::Death Animations", function( ply )
	if entity_GetNetworkValue( ply, "death-animation" ) == 2 then
		return false
	end
end )

do

	local IN_JUMP = IN_JUMP
	local IN_DUCK = IN_DUCK
	local IN_SPEED = IN_SPEED
	local IN_FORWARD = IN_FORWARD
	local IN_BACK = IN_BACK
	local IN_MOVELEFT = IN_MOVELEFT
	local IN_MOVERIGHT = IN_MOVERIGHT
	local sv_gravity = GetConVar( "sv_gravity" )
	local FrameTime = FrameTime
	local IsOnGround = ENTITY.IsOnGround
	local Lerp = Lerp
	local band = bit.band
	local abs = math.abs

	hook_Add( "Move", "Jailbreak::Developer", function( ply, mv )
		if not ply:IsFlightAllowed() then
			if not CLIENT and entity_GetNetworkValue( ply, "in-flight" ) then
				entity_SetNetworkValue( ply, "in-flight", false )
			end

			return
		end

		if IsOnGround( ply ) then
			if not CLIENT and entity_GetNetworkValue( ply, "in-flight" ) then
				return entity_SetNetworkValue( ply, "in-flight", false )
			end
		elseif entity_GetNetworkValue( ply, "in-flight" ) then
			local velocity = move_GetVelocity( mv )
			local angles = mv:GetMoveAngles()
			local buttons = mv:GetButtons()
			if band( buttons, IN_FORWARD ) ~= 0 then
				velocity = velocity + (angles:Forward() * 16)
				buttons = buttons - IN_FORWARD
			end

			if band( buttons, IN_BACK ) ~= 0 then
				velocity = velocity + (angles:Forward() * -16)
				buttons = buttons - IN_BACK
			end

			if band( buttons, IN_MOVELEFT ) ~= 0 then
				velocity = velocity + (angles:Right() * -16)
				buttons = buttons - IN_MOVELEFT
			end

			if band( buttons, IN_MOVERIGHT ) ~= 0 then
				velocity = velocity + (angles:Right() * 16)
				buttons = buttons - IN_MOVERIGHT
			end

			if band( buttons, IN_JUMP ) ~= 0 then
				velocity = velocity + (angles:Up() * 16)
				buttons = buttons - IN_JUMP
			end

			if band( buttons, IN_DUCK ) ~= 0 then
				velocity = velocity + (angles:Up() * -16)
				buttons = buttons - IN_DUCK
			end

			local frameTime = FrameTime()
			if band( buttons, IN_SPEED ) ~= 0 then
				velocity[ 1 ] = Lerp( frameTime, velocity[ 1 ], 0 )
				velocity[ 2 ] = Lerp( frameTime, velocity[ 2 ], 0 )
				velocity[ 3 ] = Lerp( frameTime, velocity[ 3 ], 0 )
				buttons = buttons - IN_SPEED
			end

			if abs( velocity[ 1 ] ) < 1 then
				velocity[ 1 ] = 0
			end

			if abs( velocity[ 2 ] ) < 1 then
				velocity[ 2 ] = 0
			end

			if abs( velocity[ 3 ] ) < 1 then
				velocity[ 3 ] = 0
			end

			local _update_0 = 3
			velocity[ _update_0 ] = velocity[ _update_0 ] + ((ply:GetGravity() + 1) * sv_gravity:GetFloat() * 0.5 * frameTime)
			move_SetVelocity( mv, velocity )
			mv:SetButtons( buttons )
		elseif not CLIENT and mv:KeyPressed( IN_JUMP ) then
			entity_SetNetworkValue( ply, "in-flight", true )
		end
	end )

end

hook_Add( "Move", "Jailbreak::Shock", function( ply, mv )
	local shock_time = entity_GetNetworkValue( ply, "shock-time" )
	if shock_time == nil or CurTime() > shock_time then
		return
	end

	mv:SetMaxSpeed( ply:GetWalkSpeed() / 4 )
end )

hook_Add( "PlayerEmitSound", "Jailbreak::SilentDeath", function( ply, data )
	if not ply:Alive() then
		return false
	end
end )

do

	local player_IsSpawning = PLAYER.IsSpawning

	hook_Add( "AllowPlayerMove", "Jailbreak::PlayerSpawning", function( ply )
		if player_IsSpawning( ply ) then
			return false
		end
	end )

end

do

	local player_IsPlayingTaunt = PLAYER.IsPlayingTaunt

	hook_Add( "StartCommand", "Jailbreak::Taunts", function( ply, cmd )
		if player_IsPlayingTaunt( ply ) then
			cmd:SetImpulse( 0 )
		end
	end, PRE_HOOK )

	hook_Add( "AllowPlayerMove", "Jailbreak::Taunts", function( ply )
		if player_IsPlayingTaunt( ply ) then
			return false
		end
	end)

	-- hook_Add( "SetupMove", "Jailbreak::Taunts", function( ply, _, cmd )
		-- if player_IsPlayingTaunt( ply ) then
		-- 	cmd:ClearMovement()
		-- 	cmd:ClearButtons()
		-- end
	-- end, PRE_HOOK )
end

do

	local player_GetObserverMode = PLAYER.GetObserverMode
	local OBS_MODE_NONE = OBS_MODE_NONE

	hook_Add( "AllowPlayerMove", "Jailbreak::AliveSpectator", function( ply )
		if ply:Alive() and player_GetObserverMode( ply ) ~= OBS_MODE_NONE then
			return false
		end
	end )

end

hook_Add( "PlayerFootstep", "Jailbreak::LoseConsciousness", function( ply )
	if ply:IsLoseConsciousness() then
		return true
	end
end )

do

	local Length2D, SetUnpacked
	do
		local _obj_0 = VECTOR
		Length2D, SetUnpacked = _obj_0.Length2D, _obj_0.SetUnpacked
	end

	local speed = 0

	hook_Add( "Move", "Jailbreak::PlayerPush", function( ply, mv )
		local target = entity_GetNetworkValue( ply, "push-target" )
		if target and target:IsValid() and target:Alive() then
			local velocity = move_GetVelocity( mv )
			local direction
			speed, direction = Length2D( velocity ), nil
			if speed == 0 then
				speed, direction = ply:GetWalkSpeed(), ply:GetAimVector()
			else
				direction = velocity:GetNormalized()
				SetUnpacked( velocity, velocity[ 1 ] * 0.5, velocity[ 2 ] * 0.5, velocity[ 3 ] )
				move_SetVelocity( mv, velocity )
			end

			ply.m_vPushVelocity = direction * speed
			return
		end

		local pushing_player = entity_GetNetworkValue( ply, "pushing-player" )
		if pushing_player and pushing_player:IsValid() and pushing_player:Alive() then
			if SERVER and ply:GetPos():DistToSqr( pushing_player:GetPos() ) > 5184 then
				entity_SetNetworkValue( pushing_player, "push-target", nil )
				entity_SetNetworkValue( ply, "pushing-player", nil )
				return
			end

			local push_velocity = pushing_player.m_vPushVelocity
			if push_velocity ~= nil then
				push_velocity = push_velocity * 1.125
				push_velocity[ 3 ] = move_GetVelocity( mv )[ 3 ]
				move_SetVelocity( mv, push_velocity )
			end
		end
	end )

end
