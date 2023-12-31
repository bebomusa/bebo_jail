fx_version "cerulean"
game "gta5"

name "bebo_jail"
author "BerkieB & Bebo"
description "Server-side admin jail manager"
version "1.0.4"
repository "https://github.com/bebomusa/bebo_jail"
license "MIT"

server_scripts {
	"@oxmysql/lib/MySQL.lua",
	"config.lua",
	"server.lua"
}

dependencies {
	"/onesync",
	"/server:6129",
	"oxmysql",
	"ox_inventory"
}

lua54 "yes"
use_experimental_fxv2_oal "yes"
