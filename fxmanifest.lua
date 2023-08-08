fx_version "cerulean"
game "gta5"

name "bebo_jail"
author "BerkieB & Bebo"
description "Server-side admin jail system"
version "1.0.2"
repository "https://github.com/bebomusa/bebo_jail"

shared_script "@ox_lib/init.lua"

server_scripts {
	"@oxmysql/lib/MySQL.lua",
	"config.lua",
	"server.lua",
}

dependencies {
	"/onesync",
	"/server:6129",
	"oxmysql",
}

lua54 "yes"
use_experimental_fxv2_oal "yes"