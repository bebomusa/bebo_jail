UseOx = true -- Set 'true' if using ox_core, false if using ESX.
UseAces = true -- Set 'true' if using ACE Permissions, false otherwise.
JailedState = "adminjail" -- The default jail state to use when a player is jailed.

---@param AllowedGroup table | string: List of allowed groups that have permission to use the provided commands.
AllowedGroup = {
    "group.admin",
}

---@type table <string, table>
---@param insideCoords vector3: Coordinates inside the jail where the player will be teleported to.
---@param outsideCoords vector3: Coordinates outside the jail where the player will be teleported after release.
---@param items table | string | number: Items to give the jailed player on entry.
---@param blacklistedItems table | string | boolean: Blacklisted items that will be not removed from the jailed player's inventory.
Jails = {
    adminjail = {
        insideCoords = vec3(1651.621948, 2569.859375, 45.556763),
        outsideCoords = vec3(1846.628540, 2585.854980, 45.657837),
        items = {
            water = 5,
            burger = 5,
        },
        blacklistedItems = {
            phone = true,
        },
    },
}