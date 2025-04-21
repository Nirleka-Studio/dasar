--[=[
	This will demonstrate and test how require() works in the Roblox enviremount.
	Thanks to this [DevForum thread](https://devforum.roblox.com/t/module-script-memory/2999826)
]=]

-- Get and require the ModuleScript
local ms = script.ModuleScript
local r = require(ms)

-- Clone the ModuleScript for further testing
-- as the first ModuleScript will be destroyed
local ms2 = ms:Clone()
ms2.Parent = ms.Parent

r.yay = "yay"

local r1 = require(ms) -- alwyas refers to the cached 'r'

print(r1.yay) -- "yay", expected

-- makes a weak table with weak values
local gcTest = setmetatable({r; {}}, { __mode = 'v' })

r=nil			-- no further references to the ModuleScript
ms:Destroy()	-- resulting in garbage collection

-- wait until the values gone nil
-- meaning it has been garbage collected
while gcTest[2] do
	print(gcTest[1])
	print(gcTest[2])
	task.wait()
end

task.wait(1)

print(gcTest[1]) --> nil (garbage collected)
print(gcTest[2]) --> nil (garbage collected)

-- if we try to require the second ModuleScript,
-- Roblox will treat this as a seperate module and run it again
-- no further memory of ms
local r2 = require(ms2)
print(r2.yay) -- nil, ofc