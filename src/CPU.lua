local CPU = {}

-- Gets the Core Unit (if linked)
local coreUnit = library.getLinksByClass('CoreUnit')[1]

-- Returns current thread (if any)
function CPU.thread ()
  if system.currentThread and system.currentThread.tick then
    return system.currentThread
  end
  return nil
end

-- Only used in coroutines, internal counter and limits
local internalCounter = 0
local internalCounterDefaultLimit = 1000

-- Ticks (if possible) the script so we don't overheat
function CPU.tick (limit)
  -- If threading is enable, then use it
  if CPU.thread() then
    CPU.thread().tick()
  -- Also checks if we're in a coroutine, then use the internal counter (not so accurate, though)
  elseif coroutine.running() then
    internalCounter = internalCounter + 1

    -- Limits to a certain number of list iterations
    if internalCounter > (limit or internalCounterLimit) then
      internalCounter = 0
      coroutine.yield()
    end
  end
end

function CPU.core ()
  return coreUnit
end

return CPU