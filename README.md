# bebo_jail

A super simple disciplinary measure using state bags and routing buckets to handle rule-breaking or disruptive behavior of players within the game environment.

# Usage 

## Ace

- - Only used if `UseAces` is set `true`.
- - Be sure to replace `replaceme` with your desired group.
### `add_ace group.replaceme command.ajail allow`

### `add_ace group.replaceme command.ajailrelease allow`

### `add_ace group.replaceme command.ajailtime allow`

## Commands

### `/ajail [playerId] [time] [reason]`
- - Send a player to another dimension as a form of disciplinary action. The player is moved to a remote location where they cannot interact with others. The command requires specifying the target player(s) ID, the duration of the jail time, and a reason for the action. The reason is helpful for communication and documentation purposes. For example: `/ajail 123 60 Excessive profanity in chat`

### `/ajailrelease [playerId]`
- - Release a player(s) from admin jail. If the handling admin decides to end their punishment prematurely, this command is employed to bring the player back to the normal gameplay environment.

### `/ajailtime [playerId]`
- - Admin command that allows administrators to check the remaining jail time for a specific player. By using this command and providing the target player(s) ID, the admin can get information about how much time the player has left before they are released from admin jail.

### `/timeleft`
- - Global command designed for a player(s) to easily check how much time they have left in admin jail. You can use this command to see the remaining duration of your punishment before being released. By simply entering `/timeleft`, the player will receive a message displaying the amount of time they have left in admin jail.