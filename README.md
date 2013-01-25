# [TF2] Hidden - SourceMod Plugin 

TF2 Hidden is a Hidden:Source-like SourceMod plugin for [Team Fortress 2](http://www.teamfortress.com/).

* [Allied Mods Forum Post](https://forums.alliedmods.net/showthread.php?p=1880477#post1880477)
* Get [Plugin](https://forums.alliedmods.net/attachment.php?attachmentid=115025&d=1359143203),
* Get [Source](https://github.com/atomic-penguin/sm-hidden),

## Requirements

Plugin optionally requires [SteamTools](http://forums.alliedmods.net/showthread.php?t=129763) extension to change server game description.
Requires [smlib](https://github.com/bcserv/smlib) stock includes when building the plugin from source.

Original code by [Matheus28](http://forums.alliedmods.net/showthread.php?t=143577).  Adapted and improved by [atomic-penguin](https://github.com/atomic-penguin)
([steam](http://steamcommunity.com/id/atomic-penguin/)) and [daniel-murray](https://github.com/daniel-murray) ([steam](http://steamcommunity.com/id/smileydan2/))
based on suggestions in [this](http://forums.alliedmods.net/showpost.php?p=1770153&postcount=133) post, and feedback from testing sessions with members of
[atomic's steam group](http://steamcommunity.com/groups/PenguinsPub).

### Installation/Usage

Simply drop the smx, in your Sourcemod plugins folder, and restart your server to load the plugin.
Once the plugin is loaded, switch to an arena map.

**WARNING**:  Plugins which manage AFK players, scramble, and autobalance plugins may interfere with
player queueing and spawning in this gamemode.  These type of plugins have not been thoroughly tested
with this plugin and it woulde be safest to disable these.

## Gameplay

Each round one player is the Hidden. Their goal is to kill all of players on the other team.
The Hidden plays as the spy with some supplementary abilities and attributes:

* Increased health points.
  - Additional health granted per player.
* Increased movement speed.
* Increased jump heighth and distance.
* Reduced effectiveness of certain weapon effects.
  - e.g. fire after-burn, jarate splash, and bleed effects.
* Hidden is almost always cloaked.  Except when:
  - attacking
  - pouncing
  - taking damage

### Hidden controls and gameplay

The Hidden has only a couple minutes of time to kill everyone on team Iris.
The Hidden's arsenal includes two special mechanisms, to make him
especially dangerous to players on team Iris.

* `attack2` allows the Hidden to perform a super jump/pounce and stick briefly to walls.
* `reload` allows the Hidden to stun nearby enemies.

### Iris teamplay

When playing on the Iris team, you play just as you would any other TF2 mode.  A few
things have been changed in this plugin to make it balanced and fair for anyone to play the Hidden.

* Spies have been disabled.
* Sentry guns have been blocked.
* Engineers and Pyros can optionally be disabled.

So it looks pretty hopeless for team Iris right?  Well not quite, with a hefty dose of teamwork
you can bring The Hidden down... maybe.

See a full life of Iris team gameplay [here](https://www.youtube.com/watch?v=H8WquUK2kLI).

### Other tips

* Listen! Do you hear somet...
* Health is hard to come by on Arena maps, think about items that may help you here!
* Unless you're a total badass, it's probably a good idea to stick with your team.
* Turn on payload objective glow, if you haven't already. You can see the outline effects
  [here](https://www.youtube.com/watch?v=nJN_dUMeeaQ).

## FAQ

* How is the next Hidden determined?
  - If an Iris player kills the Hidden, then they will be rewarded by getting to play the Hidden next.
  - If no Iris player kills the Hidden, then a random player will be selected to play the Hidden next.
  - A server admin, may force the next Hidden with the `sm_nexthidden` command, instead of random selection.

* What maps can we play this gamemode on?
  - The plugin will only run on Arena mode maps.  Because there is only one life per round in arena,
    this suits the nature of this paricular plugin and game mode.

* Where can I find more arena maps
  - [Here](https://gist.github.com/4605750) is a list of custom arena maps we have playtested
    with this particular plugin.  The plugin works small to medium size arena maps.  Larger
    arena maps are not particularly fun with fewer people.

* Why can I not use sentries?
  - During testing we found sentries to be too powerful.  By allowing the Engineer class,
   but restricting him to support buildings let us replicate the support class (can refill ammo/health)
   from Hidden:Source.
   

## Admin Commands

* `sm_nexthidden <client-name>`
 - Forces a player to be the next Hidden

* `sm_hidden_enable`
  - Enable the plugin

* `sm_hidden_disable`
  - Disable the plugin

## ConVars

* `sm_hidden_enabled`
  - def = 1, Enables/disables the plugin

* `sm_hidden_alltalk`
  - def = 1, Turn alltalk and voice icons off

* `sm_hidden_allowpyro`
  - def = 1, Set whether pyro is allowed on team Iris

* `sm_hidden_allowengineer`
  - def = 1, Set Whether engineer is allowed on team Iris

* `sm_hidden_visible_damage`
  - def = 0.5, Time hidden is visible for (seconds) on taking weapon damage

* `sm_hidden_visible_jarate`
  - def = 1, Time hidden is visible for (seconds) when splashed or bonked

* `sm_hidden_visible_pounce`
  - def = 0.25, Time hidden is visible for (seconds) when pouncing

## How Do I Suggest a Feature or Submit a Bug?

Either use the GitHub Issue Tracking system found
[here](https://github.com/atomic-penguin/sm-hidden/issues?state=open), or
post a comment on the [plugin thread]().
