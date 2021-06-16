-- List of Core Unit sizes
local CoreSize = {
  XS = { id = 'XS', hp = 50, side = 16 },
   S = { id = 'S', hp = 183, side = 32 },
   M = { id = 'M', hp = 1288, side = 64 },
   L = { id = 'L', hp = 11541, side = 128 },
  XL = { id = 'XL', hp = 100000, side = 256 }, -- Estimate only!
}

-- Calculates other properties for above values
for size, info in pairs(CoreSize) do
  if 'table' == type(info) then
    CoreSize[size].size = size
    CoreSize[size].diagonal = math.sqrt(3 * info.side ^ 2)
    CoreSize[size].radius = CoreSize[size].diagonal / 2
    CoreSize[size].center = vec3({ info.side / 2, info.side / 2, info.side / 2 })
  end
end

-- Gets a Core Size from a Core Unit
function CoreSize.fromCoreUnit (coreUnit)
  -- Max HP
  local mHP = coreUnit.getElementMaxHitPointsById(coreUnit.getId())

  -- Tries to find proper size for the unit
  local matchedSize = nil
  for size, info in pairs(CoreSize) do
    if 'table' == type(info) and mHP >= info.hp then
      matchedSize = size
    end
  end

  return CoreSize[matchedSize]
end

return CoreSize