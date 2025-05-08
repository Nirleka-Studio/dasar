## The Dasar Standard Library (DSL)

The Dasar Standard Library includes reworks of the modules from `src/core/variant`, `src/modules/animation` and `src/modules/dialogue`.

The DSL only includes components that are strictly necessary for the project.

Reworked modules of the DSL takes a different approach in how they are implemented. The original modules uses Object Oriented Programming (OOP) while the DSL uses Functional Programming (FL) for low-level and basic data structures.


### Implementation Differences

#### Arrays

##### OOP

Using the OOP Arrays, which can be declared by:

```lua
local new_array = Array()
```

or with a predefined table:

```lua
local new_array = Array({1, 2, 3, 4})
```

like any OOP instances, functions can be called from the array directly:

```lua
local new_array = Array({1, 2, 3, 4})

new_array:PushBack(5)
```

and by the magic of metatables, operators like `#`, and `[]` works on the array, just like operating with normal Lua tables.

```lua
local new_array = Array({"a", "b", "c", "d"})

new_array:PushBack("e")
print(new_array[5]) -- "e"
print(#new_array) -- 5
```

however, DSL's array is declared differently.

##### DSL

```lua
local new_array = array.create()
```

```lua
local new_array = array.create({"a", "b", "c", "d"})

array.push_back(new_array)
print(array.get(new_array, 5)) -- "e"
print(array.size(new_array)) -- 5
```


Some honorable dev notes:

From urich.lua:
```
	-- this is more complicated than it needs to be.

	-- all i can explain the steps is that
	-- 1. Look for the first tag. (<...>) 2. if it does, check if its an attributed tag <...=...>
	-- 3. if its not, check if its an enclosed that (<...>...</...>)

	-- you'll probably wondering what this is for. well, guess what? its not for markup.
	-- its the backbone of the dialogue system.
	-- the previous system uses symbols and internal delays for specific characters (|, _) which is
	-- a bit too hardcoded and barely extendable.
	-- so the more logical approach is to just parses the string to a set of specific instrunctions.
	-- this is an example: in the original system, its like this "Plain text. _INSTANT APPEAR_| wow.|"
	-- now, this acts as the parser instead of the hard coded engine. So that turns to:
	-- "Plain text.<wait=1> <skip>INSTANT APPEAR</skip><wait=1> wow.<wait=1>"

	-- what about the ustrings? well, those are wrappers around the normal strings except its unicode array.
	-- does it overcomplicate it? No. Heck, all of these ustring functions are basically the string library
	-- functions. And if you did replace them, it'll still work just fine. (if the input is ASCII)`
```