local Class = require('Class')
local unpack = table.unpack
local trace = traceback or (debug and debug.traceback) or function (a, b) return a or b end

--------------------------------
-- Thread Scheduler
--------------------------------

local Scheduler = {
  _ = 0,
  threads = {},
  margin = 0.75,
  maxTick = 35000,
  maxSlice = 0.10,
}

function Scheduler.tick ()
  -- Keeps looping each of the threads in round-robin fashion
  Scheduler._ = Scheduler._ + 1
  if Scheduler._ > #Scheduler.threads then
    Scheduler._ = 1
  end

  -- Ticks Thread
  local thread = Scheduler.threads[Scheduler._]
  if thread.running then
    -- Current tick start
    Scheduler.t0 = system.getTime()
    Scheduler.tMax = system.getActionUpdateDeltaTime() * Scheduler.maxSlice

    -- Resumes Thread
    thread:resume()
  else if thread.finished then
    -- Triggers exit event and leaves
    thread.finished = false
    thread:triggerEvent('exit')
  end
end

system:onEvent('update', Scheduler.tick)

--------------------------------
-- Thread Class
--------------------------------

local Thread = {}

-- Creates a new Thread
function Thread:new (fn)
  local _ = self

  -- Setup underlying coroutine
  _.coroutine = coroutine.create((function (...)
    fn(unpack({...}))
    _.finish()
  end))

  -- Running status is always off
  _.running = false

  -- Finished becomes true only when the finished event is pending
  _.finished = false

  -- Tick data
  _._ = 0
  _._depth = 0

  -- Event support
  library.addEventHandlers(_)

  -- Adds to scheduler
  table.insert(Scheduler.threads, _)
end

-- Starts Thread
function Thread:start (...)
  if not self.running then
    self.args = {...}
    self.running = true
  end
end

-- Iteration counter
function Thread:tick ()
  if self.running then
    -- Gets current CPU slice
    local now = system.getTime()
    
    -- Gets last tick size
    local tSize = 0 -- This can be zero by default
    local tMax = 1 -- By default this is 1 so we have 1 tick to mensure its length
    if self._last then
      -- Calculates size and max amount of iterations at this rate, multiply it by 90% so we have a small safety margin
      tSize = now - self._last
      tMax = math.floor(Scheduler.margin * Scheduler.tMax / tSize)
    end
    self._last = now

    -- Increases iteration count
    self._ = self._ + 1

    -- Check if we already hit the threshold
    if self._ > math.min(tMax, Scheduler.maxTick) then
      self._ = 0
      self._last = nil
      self:yield()
    end
  end
end

-- Pauses Thread
function Thread:yield ()
  if self.running then
    coroutine.yield()
  end
end

-- Resumes Thread
function Thread:resume (...)
  if self.running then
    if ... then self.args = {...} end
    local status, message = coroutine.resume(self.coroutine, self, unpack(self.args))
    
    if false == status then
      error(string.format('Thread error at #%d: %s\n:%s ', Scheduler._, message, trace(self.coroutine)))
    end
  end
end

-- Ends Thread
function Thread:finish ()
  Scheduler.threads[Scheduler._].running = false
  Scheduler.threads[Scheduler._].finished = true
  coroutine.yield()
end

-- Same as the `for` keyword, but with extras to handle CPU time and return tables
function Thread:map (val, fn)
  -- Tick stuff
  if 0 == self._depth then
    self._ = 0
  end
  self._depth = self._depth + 1

  -- Actual loop
  local temp = {}
  for k, v in pairs(val) do
    self:tick()
    temp[k] = fn(k, v)
  end

  -- Cleanup
  self._depth = self._depth - 1

  -- Done
  return temp
end

-- Same as the `for` keyword with ranges, but with extras to handle CPU time and return tables
function Thread:range (rStart, rEnd, fn)
  -- Tick stuff
  if 0 == self._depth then
    self._ = 0
  end
  self._depth = self._depth + 1

  -- Actual loop
  local temp = {}
  for idx = rStart, rEnd do
    self:tick()
    temp[idx] = fn(idx)
  end

  -- Cleanup
  self._depth = self._depth - 1

  -- Done
  return temp
end

-- Returns the Thread class constructor
return Class('Thread', { prototype = Thread }).new