local rtween = require("../ReplicatedStorage/rtween")

local new_rtween = rtween.create()
local part = workspace.Part

task.wait(3)

new_rtween.default_parallel = true
new_rtween.parallel_enabled = true

rtween.tween_instance(new_rtween, part, {
	Position = Vector3.new(30, 30, 30)
}, 5)

rtween.tween_instance(new_rtween, part, {
	Color = Color3.new(1, 0, 0)
}, 5)

rtween.tween_instance(new_rtween, workspace.Part1, {
	Position = Vector3.new(30, 30, 30)
}, 5)

rtween.play(new_rtween)
task.wait(3)
warn("PAUSING TWEEN")
rtween.pause(new_rtween)
warn(new_rtween)
task.wait(1)
warn("RESUMING TWEEN")
rtween.play(new_rtween)

task.wait(3)
warn(new_rtween)