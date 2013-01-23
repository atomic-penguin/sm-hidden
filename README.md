####TF2 Hidden - SourceMod Plugin for Team Fortress 2

TF2 Hidden is a 'Hidden:Source-esque' SourceMod plugin for [Team Fortress 2](http://www.teamfortress.com/).

Get Plugin [.smx](),
Get Source [.zip](https://github.com/atomic-penguin/sm-hidden/tags),
Requires SteamTools [SteamTools](http://forums.alliedmods.net/showthread.php?t=129763)

[Allied Mods Forum Post]()

Original code by [Matheus28](http://forums.alliedmods.net/showthread.php?t=143577),
adapted and improved by [atomic-penguin](https://github.com/atomic-penguin)
([steam](http://steamcommunity.com/id/atomic-penguin/))
and [daniel-murray](https://github.com/daniel-murray)
([steam](http://steamcommunity.com/id/smileydan2/))
based on suggestions in [this](http://forums.alliedmods.net/showpost.php?p=1770153&postcount=133)
post and feedback from testing sessions with members of
[atomic's steam group](http://steamcommunity.com/groups/PenguinsPub).

####Gameplay

Each round one player is The Hidden. Their goal is to kill all of players on the other team.
The Hidden plays as the spy with some supplementary abilities and attributes:

 * Extra long cloak time
 * Increased movement speed
 * Ignores some effects, such as fire after-burn, jarate-cloak-color, bleed effects and a few others
 * Can attack from cloak
 * `attack2` allows The Hidden to perform a super jump or pounce and to stick to walls
 * `reload` allows The Hidden to scare nearby enemies

So it looks pretty hopeless for team Iris right? Well not quite, with a hefty dose of teamwork (and pyros)
you can bring The Hidden down... maybe.

Words not cutting it for you? See a full life [here](https://www.youtube.com/watch?v=H8WquUK2kLI).

####Tips

 * Listen! Do you hear somet...
 * Health is hard to come by on Arena maps, think about items that may help you here!
 * Unless you're a total badass, it's probably a good idea to stick with your team.
 * Turn on payload objective glow, if you haven't already. You can see the outline effects
   [here](https://www.youtube.com/watch?v=nJN_dUMeeaQ).

####FAQ

How is the next Hidden determined?

 * In one of three ways. If the admin command `sm_nexthidden` has been successfully issued
   the target player will be the next Hidden.  If a player on team Iris kills The Hidden, they
   will be the next Hidden. Otherwise it is random.

What maps can we play this gamemode on?

 * The plugin will only run on Arena mode maps.
   The reason for this is to simplify some aspects of the plugin by making assumptions
   based on Arena mode. Arena maps work great for this gamemode.
   You can find a list of custom arena maps [here](https://gist.github.com/4605750). 

Why can't I use sentries?

 * During testing we found sentries to be too powerful.
   We also found that allowing the Engineer class, but restricting him to support buildings only,
   allowed us to replicate the support class type in Hidden:Source (which can refill team ammo
   supplies). 

####Admin Commands

`sm_nexthidden <client-name>`

 * Forces a player to be the next Hidden

`sm_hidden_enable`

 * Enable the plugin

`sm_hidden_diable`

 * Disable the plugin

####ConVars

`sm_hidden_enabled`

 * def = 1, Enables/disables the plugin

`sm_hidden_alltalk`

 * def = 1, Turn alltalk and voice icons off

`sm_hidden_allowpyro`

 * def = 1, Set whether pyro is allowed on team Iris

`sm_hidden_allowengineer`

 * def = 1, Set Whether engineer is allowed on team Iris

`sm_hidden_visible_damage`

 * def = 0.5, Time hidden is visible for (seconds) on taking weapon damage

`sm_hidden_visible_jarate`

 * def = 1, Time hidden is visible for (seconds) when splashed or bonked

`sm_hidden_visible_pounce`

 * def = 0.25, Time hidden is visible for (seconds) when pouncing

####List of Servers known to be Running This Plugin

Reddit Unnofficial Gaming Community Penguin's Pub

 * [connect](steam://connect/206.212.61.22:27017) or `connect 206.212.61.22:27017` at TF2's console

(we'd love to add your sever here, let us know!)

####How Do I Suggest a Feature or Submit a Bug?

We'd prefer that you use the GitHub Issue Tracking system found
[here](https://github.com/atomic-penguin/sm-hidden/issues?state=open). Who knows, your issue might already be there!
However a post on the Allied Mods forum, an email or steam message to either of us or that you drop by atomic's server and
let us know there are all fine too.
