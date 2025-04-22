-- Get and require the ModuleScript
local ms = script.ModuleScript
local r = require(ms)

-- Clone the ModuleScript for further testing
local ms2 = ms:Clone()
ms2.Parent = ms.Parent

r.yay = "yay"

local r1 = require(ms)
print(r1.yay) -- "yay", expected

-- STEP 1: Create a clean standalone copy of the function
-- This prevents the closure from referencing 'r'
local cleanFunction = r.while_loop
r.while_loop = nil -- Break backward reference from 'r' to the function

-- STEP 2: Run the clean function in a spawned task
local thread = task.spawn(function()
	cleanFunction()
end)

-- STEP 3: Prepare for garbage collection
local gcTest = setmetatable({r; {}}, { __mode = 'v' })

task.cancel(thread)
thread = nil
cleanFunction = nil -- Remove last known reference to the function
r = nil
ms:Destroy()

-- STEP 4: Wait for GC
while gcTest[2] do
	print("Still alive:", gcTest[1], gcTest[2])
	task.wait()
end

task.wait(1)

print("After GC:")
print(gcTest[1]) --> nil
print(gcTest[2]) --> nil

-- STEP 5: Requiring cloned module again
local r2 = require(ms2)
print(r2.yay) -- nil, fresh module
