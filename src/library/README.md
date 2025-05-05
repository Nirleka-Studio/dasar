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