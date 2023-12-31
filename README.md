# bebo_jail

A super simple disciplinary measure using state bags and routing buckets to handle rule-breaking or disruptive behavior of players within the game environment.

## Usage 

### Configuration

```
add_ace group.replaceme command.ajail allow
add_ace group.replaceme command.ajailrelease allow
add ace group.replaceme command.ajailtime allow
```

### Commands

-   `/ajail [playerId] [time] [reason]`

    -   Send player(s) to another dimension as a form of disciplinary action. The player(s) are moved to a remote location where they cannot interact with others. This command requires specifying the target player(s) ID, the duration of the jail time, and a reason for the action. For example: `/ajail 123 60 Excessive profanity in chat.`

-   `/ajailrelease [playerId]`

    -   Release player(s) from admin jail. If the handling admin decides to end their punishment prematurely, this command is employed to bring the player back to the normal gameplay environment.

-   `/ajailtime [playerId]`

    -   Admin command that allows administrators to check the remaining jail time for a specific player. By using this command and providing the target player(s) ID, the admin can get information about how much time the player(s) has left before they are released from admin jail.

- `/timeleft`

    -   Global command designed for a player(s) to easily check how much time they have left in admin jail. You can use this command to see the remaining duration of your punishment before being released by executing `/timeleft`.

## Requirements

-   [FXServer](https://runtime.fivem.net/artifacts/fivem/) 6129 or higher
-   [oxmysql](https://github.com/overextended/oxmysql/releases)
-   [ox_inventory](https://github.com/overextended/ox_inventory/releases)