--[[
  JSON Analyzer
  Author: Matheus Pratta (Wolfram) @ Wolfe Labs
  Description: This is a blazing-fast JSON analysis library that uses RegEx to extract keys and values from large chunks of JSON while not consuming a lot of CPU. This **IS NOT MEANT** to replace any standard JSON libraries, but just provide a quick and dirty way of reading large datasets without a CPU Overheat error in-game.
]]

-- Imports CPU utilities
local CPU = require('CPU')

local JSA = {}

function JSA.extractAllKeys(json, groupArrays)
  -- Prepares the JSON by appending the characters '{', '}' and ',' with new lines
  local prepared = json:gsub('{', '\n'):gsub('}', '\n'):gsub(',', '\n')
  local regex = '"(%a+)":[ ]*(.-)%s*\n+'
  local results = {}
  local currentKey = nil
  local currentBuffer = {}

  -- Gets every key: value pair in the entire string
  for key, value in prepared:gmatch(regex) do
    -- Iterator tick to prevent overheating
    CPU.tick(1000)

    -- Handles opening of arrays, so we can at least isolate them
    if '[' == value and groupArrays then
      if not currentKey then
        results = currentBuffer
      else
        results[currentKey] = currentBuffer
      end
      currentKey = key
      currentBuffer = {}
    else
      -- Extracts proper value
      if 'true' == value then value = true
      elseif 'false' == value then value = false
      elseif 'null' == value then value = nil
      elseif '"' == value:sub(1, 1) then value = value:sub(2, #value - 1)
      else value = tonumber(value)
      end
      table.insert(currentBuffer, { k = key, v = value })
    end
  end

  -- Handles last item
  if groupArrays and currentKey then
    results[currentKey] = currentBuffer
  elseif #currentBuffer and not groupArrays then
    results = currentBuffer
  end

  return results
end

function JSA.extractEntities(sourceList, key)
  local results = {}

  -- Only does anything if source has at least one item
  if sourceList and #sourceList > 0 then
    -- If no key is provided, extract first of source
    if not key then key = sourceList[1].k end

    -- This is the current object being handled
    local current = {}

    -- Processes each of the entries (k = key, v = value) and groups them as proper objects
    for _, entry in pairs(sourceList) do
      -- Iterator tick to prevent overheating
      CPU.tick(1000)

      -- Handles next entity in list
      if #current and key == entry.k then
        table.insert(results, current)
        current = {}
      end

      -- Properly adds to list
      current[entry.k] = entry.v
    end

    -- Handles last item
    if #current then
      table.insert(results, current)
    end
  end

  return results
end

return JSA