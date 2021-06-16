local Thread = require('@wolfe-labs/Kernel:Thread')

local screen = library.getLinksByClass('ScreenUnit')[0]

local thread = Thread(function (_)
  local numbers = {}
  _:range(1, 10000, function (i)
    _:range(1, 50, function (j)
      local k = i * j
      if 0 == k % 10000 then
        system.print(i .. ', ' .. j .. ', ' .. k)
      end
    end)
    table.insert(numbers, i)
  end)

  system.print(#numbers)
end)
thread:start()