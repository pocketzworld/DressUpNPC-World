--!Type(Module)

Tween = {}
Tween.__index = Tween

local tweens = {}

-- Easing functions
Easing = {
	linear = function(t)
		return t
	end,
	easeInQuad = function(t)
		return t * t
	end,
	easeOutQuad = function(t)
		return t * (2 - t)
	end,
	easeInOutSin = function(t)
		return (1 - math.cos(t * math.pi)) / 2
	end,
	easeOutBack = function(x: number): number
		local c1 = 1.70158
		local c3 = c1 + 1
		return 1 + c3 * math.pow(x - 1, 3) + c1 * math.pow(x - 1, 2)
	end,
	easeInBack = function(x: number): number
		local c1 = 1.70158
		local c3 = c1 + 1
		return c3 * x * x * x - c1 * x * x
	end,
}

-- Constructor for the Tween class
-- Parameters:
--   from: starting value
--   to: ending value
--   duration: time in seconds over which to tween
--   easing: easing function (optional, defaults to linear)
--   onUpdate: callback function(value) called every update
--   onComplete: callback function() called when tween finishes
function Tween:new(onUpdate)
	local obj = {
		from = 0,
		to = 1,
		duration = 1,
		easing = Easing.easeInOutSin,
		onUpdate = onUpdate,
		onComplete = nil,
		elapsed = 0,
		finished = false,
		loop = false,
	}
	setmetatable(obj, Tween)
	return obj
end

function Tween:FromTo(from: number, to: number): Tween
	self.from = from
	self.to = to
	return self
end

function Tween:OnUpdate(onUpdate): Tween
	self.onUpdate = onUpdate
	return self
end

function Tween:Easing(easing): Tween
	self.easing = easing
	return self
end

function Tween:Duration(duration): Tween
	self.duration = duration
	return self
end

function Tween:Loop(): Tween
	self.loop = true
	return self
end

function Tween:OnComplete(onComplete): Tween
	self.onComplete = onComplete
	return self
end

-- Update the tween
-- deltaTime: time elapsed since last update (in seconds)
function Tween:update(deltaTime)
	if self.finished then
		return
	end

	self.elapsed = self.elapsed + deltaTime
	local t = self.elapsed / self.duration
	if t >= 1 then
		t = 1
		if self.loop then
			self.elapsed = 0
		else
			self.finished = true
		end
	end

	local easedT = self.easing(t)
	local currentValue = self.from + (self.to - self.from) * easedT

	if self.onUpdate then
		self.onUpdate(currentValue)
	end

	if self.finished and self.onComplete then
		self.onComplete()
	end
end

-- Reset the tween to its initial state
function Tween:start()
	self.elapsed = 0
	self.finished = false
	tweens[self] = self
end

function Tween:stop()
	self.finished = true
	tweens[self] = nil
end

-- Check if the tween has finished
function Tween:isFinished()
	return self.finished
end

function self:ClientUpdate()
	for _, tween in pairs(tweens) do
		if not tween.finished then
			tween:update(Time.deltaTime)
			if tween:isFinished() then
				tweens[tween] = nil
			end
		end
	end
end

return {
	Tween = Tween,
	Easing = Easing,
}
