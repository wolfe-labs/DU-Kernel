local Math = {
  epsilon = epsilon or 1e-09,
}

-- Returns if a value is NaN
function Math.isNaN (value)
  return value ~= value
end

-- Compares two float values
function Math.equals (a, b)
  if a == 0 then return math.abs(b) < Math.epsilon end
  if b == 0 then return math.abs(a) < Math.epsilon end
  return math.abs(a - b) < math.max(math.abs(a), math.abs(b)) * Math.epsilon
end

-- Implements math.atan2 function because some **really evil** or lazy person didn't do it
function Math.atan2 (x, y)
  -- If by some miracle this gets implemented, this will handle it natively
  if math.atan2 then return math.atan2(x, y) end

  -- Does the calculation by hand
  if x == 0 and y == 0 then return 0 / 0 end
  if x == 0 and y < 0 then return -(math.pi / 2) end
  if x == 0 and y > 0 then return (math.pi / 2) end
  if x < 0 and y < 0 then return math.atan(y / x) - math.pi end
  if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
  if x > 0 then return math.atan(y / x) end

  -- If the above conditions fail, return indefinite
  return 0 / 0
end

-- Helper function for Trilateration
function Math.trilaterate (p1, r1, p2, r2, p3, r3, p4, r4)
  local r1s, r2s, r3s = r1*r1, r2*r2, r3*r3
  local v2 = p2 - p1
  local ax = v2:normalize()
  local U = v2:len()
  local v3 = p3 - p1
  local ay = (v3 - v3:project_on(ax)):normalize()
  local v3x, v3y = v3:dot(ax), v3:dot(ay)
  local vs = v3x*v3x + v3y*v3y
  local az = ax:cross(ay)  
  local x = (r1s - r2s + U*U) / (2*U) 
  local y = (r1s - r3s + vs - 2*v3x*x)/(2*v3y)
  local m = r1s - (x^2) - (y^2) 
  if Math.equals(m, 0) then m = 0 end
  local z = math.sqrt(m)
  local t1 = p1 + ax*x + ay*y + az*z
  local t2 = p1 + ax*x + ay*y - az*z

  if math.abs((p4 - t1):len() - r4) < math.abs((p4 - t2):len() - r4) then
    return t1
  else
    return t2
  end
end

-- Returns the rotation axis of an Construct from its Core Unit
function Math.getConstructWorldRotation (coreUnit)
  return {
    right = vec3(coreUnit.getConstructWorldOrientationRight()),
    forward = vec3(coreUnit.getConstructWorldOrientationForward()),
    up = vec3(coreUnit.getConstructWorldOrientationUp()),
  }
end

-- Converts from a Construct's local space into world space
function Math.convertWorldToLocalPosition (coreUnit, pos, axis, posG)
  -- Gets the construct rotation axes in world-space
  axis = axis or Math.getConstructWorldRotation(coreUnit)
  posG = posG or vec3(coreUnit.getConstructWorldPos())

  -- Converts pos into a relative position
  pos = vec3(pos) - posG
 
  --[[
    
    Resolves the following matrix multiplication:

    | aRx aFx aUx |   | x |
    | aRy aFy aUy | * | y |
    | aRz aFz aUz |   | z |

    And then adds it to the Construct's position

  ]]--
  return vec3(
    library.systemResolution3(
      { axis.right:unpack() },
      { axis.forward:unpack() },
      { axis.up:unpack() },
      { pos:unpack() }
    )
  )
end

-- Converts from world space into a Construct's local space
function Math.convertLocalToWorldPosition (coreUnit, pos, axis, posG)
  -- Converts into relative position
  posG = posG or vec3(coreUnit.getConstructWorldPos())
  
  -- Makes sure pos is a vector
  pos = vec3(pos)

  -- Gets the construct rotation axis and position in world-space
  axis = axis or Math.getConstructWorldRotation(coreUnit)

  -- Extract the axes into individual variables
  local rightX, rightY, rightZ = axis.right:unpack()
  local forwardX, forwardY, forwardZ = axis.forward:unpack()
  local upX, upY, upZ = axis.up:unpack()

  -- Extracts the local position into individual coordinates
  local rfuX, rfuY, rfuZ = pos.x, pos.y, pos.z

  -- Apply the rotations to obtain the relative coordinate in world-space
  local relX = rfuX * rightX + rfuY * forwardX + rfuZ * upX
  local relY = rfuX * rightY + rfuY * forwardY + rfuZ * upY
  local relZ = rfuX * rightZ + rfuY * forwardZ + rfuZ * upZ
  
  return posG + vec3(relX, relY, relZ)
end

return Math