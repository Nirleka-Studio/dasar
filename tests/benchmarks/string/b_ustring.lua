
local text = "why, oh, why, why would you do this??????"


local function at(str: string, i: number)
	return str:sub(i, i)
end

local function explode(str: string)
	local t = {}
	for i = 1, utf8.len(str) do
		t[#t + 1] = str:sub(i, i)
	end
	return t
end

local sub_startTime = os.clock()

print(at(text, 12))

local sub_deltaTime = os.clock() - sub_startTime

warn("Sub method time:", sub_deltaTime)

local iter_startTime = os.clock()

local str_arr = explode(text)
print(str_arr[12])

local iter_deltaTime = os.clock() - iter_startTime

warn("Array method time:", iter_deltaTime)

--//RESULTS
--[[
	// ARRAY CONSTRUCTED OUTSIDE

	13:44:29.864  y
	13:44:29.864  Sub method time:   0.00011069999891333282
	13:44:29.864  y
	13:44:29.865  Array method time: 0.0000523999915458262

	// ARRAY CONSTRUCTED INSIDE

	13:46:07.153  y
	13:46:07.153  Sub method time:   0.0001277999981539324
	13:46:07.153  y
	13:46:07.154  Array method time: 0.0000965999934123829

	CONCLUSION

	yes. I shoudlve use a shorter string.

	1. Character Access

		ACCESS INDEX: 12
		"why, oh, why, why would you do this??????" -> has 41 bytes.
													-> has 41 characters

		{
					[1] = "w",
					[2] = "h",
					[3] = "y",
					[4] = ",",
					[5] = " ",
					[6] = "o",
					[7] = "h",
					[8] = ",",
					[9] = " ",
					[10] = "w",
					[11] = "h",
					[12] = "y",	-- BOTH CORRECTLY ACCESS HERE
					[13] = ",",
					[14] = " ",
					[15] = "w",
					[16] = "h",
					[17] = "y",
					[18] = " ",
					[19] = "w",
					[20] = "o",
					[21] = "u",
					[22] = "l",
					[23] = "d",
					[24] = " ",
					[25] = "y",
					[26] = "o",
					[27] = "u",
					[28] = " ",
					[29] = "d",
					[30] = "o",
					[31] = " ",
					[32] = "t",
					[33] = "h",
					[34] = "i",
					[35] = "s",
					[36] = "?",
					[37] = "?",
					[38] = "?",
					[39] = "?",
					[40] = "?",
					[41] = "?"
		}

	2. Performance
		Using the array is much more faster (somehow) than directly using sub() in both
		while the constuction is outside and inside the measuring time.

		Which.. doesnt make sense?? Using the array, you first use explode() which uses 41
		calls on sub?

		Oh well...


	/// SECOND TEST

	Now lets see what happens if we use foreign characters. Let's use the language of my ancestors..
	Mandarin. We'll be using "你好" Common greeting, translates to "Hello" in English.

	// RESULTS

	14:23:07.303  �
	14:23:07.303  Sub method time:   0.00010380000458098948
	14:23:07.304  �
	14:23:07.304  Array method time: 0.000047900000936351717

	// CONCLUSION

	1. Shits Fucked.
		Uh.. Oh well. I call "skill issue" on the terminal.

		ACCESS INDEX: 2

		"你好" -> 6 bytes
			   -> 2 characters

		Now if youre a dumbass and uses the `#` operator on a string during a manipulation,
		that actually returns the size in bytes of the string. Not the number of characters.
		So.. be careful for that.
]]
