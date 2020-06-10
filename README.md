# TestRange
Test range mod with bot spawning, damage markers, distance to other players, 
shortcuts, etc.

# Commands and shortcuts
Below, you will find a list of all the commands available in this mod. Command arguments
between angle brackets (\<abc\>) are mandatory those between brackets (\[abc\]) are optional.

### Settings and utilities

- `testrange.showDistance <true/false>`: Show/hide the distance to other soldiers.
- `testrange.showDamage <true/false>`: Show/hide the damage indicators.
- `testrange.broadcastDamage <true/false>`: Show/hide the damage that other players deal.
- `testrange.pos`: Print the player's position on the console.

### Spawning bots
All the arguments related to team, squad and the bot's name are optional. The default behaviour
is to spawn the bot on the enemy team, not belonging to any squad and with the name "BotN", where N
is the current amount of bots plus 1.

- `testrange.spawnAtDistance <distance> [height] [team] [squad] [name]`: 
Spawn a bot at a given `distance` and `height` from the player. Default value for `height` is 2.

- `testrange.spawnAtPosition <*X*> <*Y*> <*Z*> [*team*] [*squad*] [*name*]`:
 Spawn a bot at given coordinates `X`, `Y` and `Z`. To get a reference point, use the command 
 `testrange.pos` to print the player's position on the console. 

- `testrange.spawnCircle <*radius*> [*distance*] [*team*]`: Spawn bots in a circle of given
`radius` and at a `distance` from the player. The default value for `distance` is 0, so the 
circle will spawn around the player. 

- `testrange.spawnRange <*minDistance*> <*maxDistance*> <*delta*> [*lateralDistance*] [*team*]`:
 Spawn bots as in a shooting range-like pattern from a minimum distance up to a maximum (inclusive), 
 spaced by `delta` meters. The optional parameter `lateralDistance` default value is 1 meter and it
 determines how far each bot will be from each other laterally. If it is equal to 0, the bots will spawn
 in a straight line in front of the player.
 
### Kicking bots
- `testrange.kick <name>`: Kick the bot with a given name, if the current player spawned it.
- `testrange.kickAll`: Kick all the bots that the current player spawned.

### Shortcuts
- `Ctrl + F1`: Spawn a bot at 10 meters in front of the player.
- `Ctrl + F2`: Spawn bots from 10 to 100 meters spaced by 10 meters and with a lateral distance of 2 meters.
- `Ctrl + F3`: Spawn bots from 50 to 1000 meters spaced by 50 meters and with a lateral distance of 2 meters.
- `Ctrl + X`: Kick all the bots that the current player spawned.



