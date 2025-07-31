# cycle_trail.nvim

A simple plugin for Neovim that allows you to cycle through marks you've set.
Marks are kept in a queue that you can cycle through.

None of the mark plugins satisfied my needs, so I decided to make my own.
Insipered by [TrailBlazer](https://github.com/LeonHeidelbach/trailblazer.nvim), I wanted to make a plugin that would allow me to cycle through marks I've set.
So I came up with this. A **Cycle Trail**󱄟 

## Installation

Install using your favorite plugin manager.

For Lazy.nvim:
```lua
return {
    "swit33/cycle_trail.nvim",
    opts = {},
}
```

## Configuration

By default, the plugin does not set any keymaps.
Example configuration (default values):
```lua
return {
    "swit33/cycle_trail.nvim",
    opts = {
        text = "󱚐",  -- The sign shown for the mark
        texthl = "Special",  -- The highlight group for the sign
        linehl = "WildMenu",  -- The highlight group for the line where the mark is set
        numhl = "WildMenu",  -- The highlight group for the number of the line where the mark is set
        setup_clear_command = true,  -- Whether to set a command to clear all marks (":RemoveMarks")
    },
    	keys = {
		{
			"m",
			function()
				require("cycle_trail").add_mark()
			end,
			{ desc = "Add current position to mark queue" },
		},
		{
			"M",
			function()
				require("cycle_trail").pop_and_jump(false)
			end,
			{ desc = "Pop and jump to last mark" },
		},
		{
			"L",
			function()
				require("cycle_trail").smart_rewind()
			end,
			{ desc = "Smart rewind jump" },
		},
		{
			"]m",
			function()
				require("cycle_trail").cycle_marks("down")
			end,
			{ desc = "Cycle marks down" },
		},
		{
			"[m",
			function()
				require("cycle_trail").cycle_marks("up")
			end,
			{ desc = "Cycle marks up" },
		},
		{
			"<leader>M",
			function()
				require("cycle_trail").clear_marks()
			end,
			{ desc = "Clear all marks" },
		}
	},
})
```


## Usage

Set a mark with `m` and jump to it with `M`. This will remove the mark from the queue.
Use `L` to jump to the last mark and mark the current position.
If it is set to smart rewind:
	- If you recently jumped to a mark ('M'), jump back to the position you were at and leave a mark where you came from.
	- If you recently placed a mark ('m'), cycle back to it and leave a mark where you came from.
Use `]m` and `[m` to cycle through the marks.
Use `<leader>M` or `:RemoveMarks` to clear all marks.

## API

```lua
CycleTrail.add_mark()
```

Adds the current position to the mark queue.

```lua
CycleTrail.cycle_marks(direction)
```

Cycles through the marks in the queue.
`direction` can be either `"up"` or `"down"`.

```lua
CycleTrail.pop_and_jump(leave_mark)
```

Removes the last mark from the queue and jumps to it.
If `leave_mark` is `true`, the current position is also marked.

```lua
CycleTrail.rewind()

```

Jumps to the las position before jumping to the mark.

```lua
CycleTrail.smart_rewind()
```

Smart rewind jump.

```lua
CycleTrail.clear_marks()
```

Clears all marks from the queue.

```lua
CycleTrail.get_number_of_marks()
```

Returns the number of marks in the queue.

```lua
CycleTrail.setup(opts)
```

Sets up the plugin.
`opts` is a table with the following fields:
- `text`: The sign shown for the mark. Default: `"󱚐"`
- `texthl`: The highlight group for the sign. Default: `"Special"`
- `linehl`: The highlight group for the line where the mark is set. Default: `"WildMenu"`
- `numhl`: The highlight group for the number of the line where the mark is set. Default: `"WildMenu"`
- `setup_clear_command`: Whether to set a command to clear all marks. Default: `true`

## Recepies

### Show the number of marks in the statusline ([lualine](https://github.com/nvim-lualine/lualine.nvim) for example)
```lua
lualine_y = {
    {
        function()
            local number = require("cycle_trail").get_number_of_marks()
            if number ~= nil then
                return "󱄟 " .. number
            end
        end,
    },
},

```

## Acknowledgements
The idea for this plugin was inspired by [TrailBlazer](https://github.com/LeonHeidelbach/trailblazer.nvim).
