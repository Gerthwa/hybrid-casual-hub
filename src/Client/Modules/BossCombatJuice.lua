--!strict
--[[
	Shared hit VFX/SFX helpers for swarm impacts (client-only).
]]

local hitSoundIds = {
	"rbxassetid://9119720971",
	"rbxassetid://9119720970",
	"rbxassetid://9119720969",
}

local BossCombatJuice = {}

function BossCombatJuice.playHitSound(parent: Instance)
	local sound = Instance.new("Sound")
	sound.SoundId = hitSoundIds[math.random(1, #hitSoundIds)]
	sound.Volume = 0.55
	sound.PlaybackSpeed = 0.9 + math.random() * 0.25
	sound.RollOffMaxDistance = 120
	sound.Parent = parent
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
end

function BossCombatJuice.emitHitParticles(anchor: BasePart)
	local attachment = anchor:FindFirstChild("SwarmHitAttachment") :: Attachment?
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "SwarmHitAttachment"
		attachment.Parent = anchor
	end

	local emitter = attachment:FindFirstChild("SwarmHitBurst") :: ParticleEmitter?
	if not emitter then
		emitter = Instance.new("ParticleEmitter")
		emitter.Name = "SwarmHitBurst"
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Lifetime = NumberRange.new(0.15, 0.35)
		emitter.Speed = NumberRange.new(8, 16)
		emitter.Rate = 0
		emitter.SpreadAngle = Vector2.new(35, 35)
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.35),
			NumberSequenceKeypoint.new(1, 0),
		})
		emitter.Parent = attachment
	end

	emitter:Emit(6)
end

return BossCombatJuice
