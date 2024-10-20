local process = require("@lune/process")   
local home_dir = if process.os == "windows" then process.env.userprofile else process.env.HOME

require(home_dir .. "/.pesde/scripts/lune/rojo/roblox_sync_config_generator.luau")