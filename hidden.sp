#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <steamtools>
#include <smlib>

/*
 * Original code by Matheus28,
 * http://forums.alliedmods.net/showthread.php?t=143577
 */

#define PLUGIN_AUTHOR "atomic-penguin"
#define PLUGIN_VERSION "2.5.3"
#define PLUGIN_NAME "TF2 Hidden"
#define PLUGIN_DESCRIPTION "Hidden:Source-like mod for TF2"
#define PLUGIN_URL "https://github.com/atomic-penguin/sm-hidden"

#define TICK_INTERVAL 0.1

#define HIDDEN_HP 500
#define HIDDEN_HP_PER_PLAYER 50
#define HIDDEN_HP_PER_KILL 75
#define HIDDEN_INVISIBILITY_TIME 100.0
#define HIDDEN_STAMINA_TIME 7.5
#define HIDDEN_JUMP_TIME 0.5
#define HIDDEN_AWAY_TIME 15.0
#define HIDDEN_BOO
#define HIDDEN_BOO_TIME 20.0
#define HIDDEN_BOO_DURATION 3.5
#define HIDDEN_BOO_VISIBLE 1.5
#define HIDDEN_BOO_FILE "vo/taunts/spy_taunts06.wav"
#define HIDDEN_OVERLAY "effects/combine_binocoverlay"
#define HIDDEN_COLOR {0, 0, 0, 3}

public Plugin:myinfo = {
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
}

enum HTeam {
    HTeam_Unassigned = TFTeam_Unassigned,
    HTeam_Spectator = TFTeam_Spectator,
    HTeam_Hidden = TFTeam_Blue,
    HTeam_Iris = TFTeam_Red
}

new lastHiddenUserid;
new hidden;
new hiddenHp;
new hiddenHpMax;
new bool:hiddenStick;
new Float:hiddenStamina;
new Float:hiddenInvisibility;
new Float:hiddenVisible;
new Float:hiddenJump;
new bool:hiddenAway;
new Float:hiddenAwayTime;
#if defined HIDDEN_BOO
    new Float:hiddenBoo;
#endif
new bool:newHidden;
new bool:playing;
new bool:activated; // whether plugin is activated
new forceNextHidden;
new Handle:t_disableCps;
new Handle:t_tick;
new Handle:cv_enabled; // Internal for tf2_hidden_enabled
new Handle:cv_allowpyro;
new bool:cvar_allowpyro;
new Handle:cv_allowengineer;
new bool:cvar_allowengineer;

public OnPluginStart() {
    LoadTranslations("common.phrases");
    
    cv_enabled = CreateConVar("tf2_hidden_enabled", "0", "Enables/disables the plugin.", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cv_allowpyro = CreateConVar("tf2_hidden_allowpyro", "0", "Set whether pyro is allowed on team IRIS", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cv_allowengineer = CreateConVar("tf2_hidden_allowengineer", "0", "Set whether engineer is allowed on team IRIS", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 0.0, true, 1.0);

    HookConVarChange(cv_enabled, cvhook_enabled);
    HookConVarChange(cv_allowpyro, cvhook_allowpyro);
    HookConVarChange(cv_allowengineer, cvhook_allowengineer);
   
    RegAdminCmd("sm_nexthidden", Cmd_NextHidden, ADMFLAG_CHEATS, "Forces the next hidden to be certain player");
    RegAdminCmd("tf2_hidden_enable", Command_EnableHidden, ADMFLAG_CONVARS, "Changes the tf2_hidden_enabled cvar to 1");
    RegAdminCmd("tf2_hidden_disable", Command_DisableHidden, ADMFLAG_CONVARS, "Changes the tf2_hidden_enabled cvar to 0"); 
}

public OnPluginEnd() {
    if (activated) {
        for (new i=1;i<=MaxClients;++i) {
            if (!IsClientInGame(i)) continue;
            RemoveHiddenVision(i);
        }
    }
}

stock ActivatePlugin() {
    if (activated) return;
    activated=true;
    
    t_tick = CreateTimer(TICK_INTERVAL, Timer_Tick, _, TIMER_REPEAT);
    t_disableCps = CreateTimer(5.0, Timer_DisableCps, _, TIMER_REPEAT);
    
    HookEvent("teamplay_round_start", teamplay_round_start);
    HookEvent("teamplay_round_win", teamplay_round_win);
    HookEvent("teamplay_round_active", teamplay_round_active);
    HookEvent("arena_round_start", teamplay_round_active);
    
    HookEvent("player_team", player_team);
    HookEvent("player_spawn", player_spawn);
    HookEvent("player_hurt", player_hurt);
    HookEvent("player_death", player_death);

    AddCommandListener(Cmd_build, "build");

    PrintToChatAll("[%s] Enabled!", PLUGIN_NAME);
    decl String:gameDesc[64];
    Format(gameDesc, sizeof(gameDesc), "%s v%s", PLUGIN_NAME, PLUGIN_VERSION);
    Steam_SetGameDescription(gameDesc);
}

stock DeactivatePlugin() {
    if (!activated) return;
    activated=false;
    
    KillTimer(t_tick);
    KillTimer(t_disableCps);
    
    UnhookEvent("teamplay_round_start", teamplay_round_start);
    UnhookEvent("teamplay_round_win", teamplay_round_win);
    UnhookEvent("teamplay_round_active", teamplay_round_active);
    UnhookEvent("arena_round_start", teamplay_round_active);
    
    UnhookEvent("player_team", player_team);
    UnhookEvent("player_spawn", player_spawn);
    UnhookEvent("player_hurt", player_hurt);
    UnhookEvent("player_death", player_death);

    RemoveCommandListener(Cmd_build, "build");
}

public cvhook_enabled(Handle:cvar, const String:oldVal[], const String:newVal[]) {
    if (IsArenaMap() && GetConVarBool(cvar)) {
        ActivatePlugin();
    } else {
        DeactivatePlugin();
    }
}

public cvhook_allowpyro(Handle:cvar, const String:oldVal[], const String:newVal[]) {
    if (activated) {
        cvar_allowpyro = GetConVarBool(cvar);
        if (cvar_allowpyro) {
            PrintToChatAll("\x04[%s]\x01 Class: \x03Pyro\x01 is now allowed on team IRIS", PLUGIN_NAME);
        } else {
            PrintToChatAll("\x04[%s]\x01 Class: \x03Pyro\x01 is no longer allowed on team IRIS", PLUGIN_NAME);
        }
    }
}

public cvhook_allowengineer(Handle:cvar, const String:oldVal[], const String:newVal[]) {
    if (activated) {
        cvar_allowengineer = GetConVarBool(cvar);
        if (cvar_allowengineer) {
            PrintToChatAll("\x04[%s]\x01 Class: \x03Engineer\x01 is now allowed on team IRIS", PLUGIN_NAME);
        } else {
            PrintToChatAll("\x04[%s]\x01 Class: \x03Engineer\x01 is no longer allowed on team IRIS", PLUGIN_NAME);
        }
    }
}

public OnGameFrame() {
    if (!activated) return;
    if (!CanPlay()) return;
    
    new Float:tickInterval = GetTickInterval();
    
    for (new i=1;i<=MaxClients;++i) {
        if (!IsClientInGame(i)) continue;
        
        if (i==hidden && IsPlayerAlive(i)) {
            if (GetClientHealth(i)>0) {
                if (hiddenHp>500) {
                    SetEntityHealth(i, 500);
                } else {
                    SetEntityHealth(i, hiddenHp);
                }
            }
            
            SetEntDataFloat(i, FindSendPropInfo("CTFPlayer", "m_flMaxspeed"), 400.0, true);
            
            if (newHidden) {
                newHidden=false;
                CreateTimer(0.5, Timer_GiveHiddenPowers, GetClientUserId(hidden));
            }
            
            if (hiddenAway) {
                hiddenAwayTime+=tickInterval;
                if (hiddenAwayTime>HIDDEN_AWAY_TIME) {
                    ForcePlayerSuicide(i);
                    PrintToChatAll("\x04[%s]\x01 \x03The Hidden\x01 was killed because he was away", PLUGIN_NAME);
                    continue;
                }
            }
            
            new eflags=GetEntityFlags(i);
            
            // Save checking for these conditions, always do them.
            TF2_RemovePlayerDisguise(i);
            TF2_RemoveCondition(i, TFCond_DeadRingered);
            TF2_RemoveCondition(i, TFCond_Kritzkrieged);
            TF2_RemoveCondition(i, TFCond_MarkedForDeath);

            
            if (hiddenInvisibility>0.0) {
                hiddenInvisibility-=tickInterval;
                if (hiddenInvisibility<0.0) {
                    hiddenInvisibility=0.0;
                    ForcePlayerSuicide(i);
                    PrintToChatAll("\x04[%s]\x01 \x03The Hidden\x01 lost his powers!", PLUGIN_NAME);
                    continue;
                }
            }
            
            #if defined HIDDEN_BOO
                if (hiddenBoo>0.0) {
                    hiddenBoo-=tickInterval;
                    if (hiddenBoo<0.0) {
                        hiddenBoo=0.0;
                    }
                }
            #endif
            
            if (!hiddenStick) {
                HiddenUnstick();
                if (hiddenStamina<HIDDEN_STAMINA_TIME) {
                    hiddenStamina += tickInterval/2;
                    if (hiddenStamina>HIDDEN_STAMINA_TIME) {
                        hiddenStamina=HIDDEN_STAMINA_TIME;
                    }
                }
            } else {
                hiddenStamina-=tickInterval;
                if (hiddenStamina<=0.0) {
                    hiddenStamina=0.0;
                    hiddenStick=false;
                    HiddenUnstick();
                } else if (GetEntityMoveType(hidden)==MOVETYPE_WALK) {
                    SetEntityMoveType(hidden, MOVETYPE_NONE);
                }
            }
            
            if (eflags & FL_ONGROUND || hiddenStick) {
                if (hiddenJump>0.0) {
                    hiddenJump-=tickInterval;
                    if (hiddenJump<0.0) {
                        hiddenJump=0.0;
                    }
                }
            }
            
            if (hiddenVisible>0.0) {
                hiddenVisible-=tickInterval;
                if (hiddenVisible<0.0) {
                    hiddenVisible=0.0;
                }
            }
            
            if (hiddenInvisibility>0.0) {
                if (hiddenVisible<=0.0) {
                    if (!TF2_IsPlayerInCondition(i, TFCond_Cloaked)) {
                        TF2_AddCondition(i, TFCond_Cloaked, -1.0);
                    }
                } else {
                    TF2_RemoveCondition(i, TFCond_Cloaked);
                }
            } else {
                TF2_RemoveCondition(i, TFCond_Cloaked);
            }
                        
            if (TF2_IsPlayerInCondition(i, TFCond_OnFire)) {
                AddHiddenVisible(0.5);
                TF2_RemoveCondition(i, TFCond_OnFire);
                GiveHiddenVision(i);
            }
            
            if (TF2_IsPlayerInCondition(i, TFCond_Ubercharged)) {
                TF2_RemoveCondition(i, TFCond_Ubercharged);
                GiveHiddenVision(i);
            }
            
            if (TF2_IsPlayerInCondition(i, TFCond_Jarated)) {
                AddHiddenVisible(1.0);
                TF2_RemoveCondition(i, TFCond_Jarated);
                GiveHiddenVision(i);
            }
            
            if (TF2_IsPlayerInCondition(i, TFCond_Milked)) {
                AddHiddenVisible(0.75);
                TF2_RemoveCondition(i, TFCond_Milked);
            }
            
            if (TF2_IsPlayerInCondition(i, TFCond_Bonked)) {
                AddHiddenVisible(1.0);
                TF2_RemoveCondition(i, TFCond_Bonked);
            }
            
            if (TF2_IsPlayerInCondition(i, TFCond_Bleeding)) {
                AddHiddenVisible(0.5);
                TF2_RemoveCondition(i, TFCond_Bleeding);
                GiveHiddenVision(i);
            }
            
            SetEntPropFloat(i, Prop_Send, "m_flCloakMeter", hiddenInvisibility/HIDDEN_INVISIBILITY_TIME*100.0);
            
            if (GetEntProp(i, Prop_Send, "m_bGlowEnabled")) {
                SetEntProp(i, Prop_Send, "m_bGlowEnabled", 0);
            }
            
        } else if (IsClientPlaying(i)) {
            if (HTeam:GetClientTeam(i) == HTeam_Hidden) {
                ChangeClientTeam(i, _:HTeam_Iris);
            }
            
            if (IsPlayerAlive(i) && !GetEntProp(i, Prop_Send, "m_bGlowEnabled")) {
                SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1);
            }
        }
    }
}

public Action:teamplay_round_win(Handle:event, const String:name[], bool:dontBroadcast) {
    playing=true;
    CreateTimer(0.5, Timer_ResetHidden);
}

public Action:teamplay_round_active(Handle:event, const String:name[], bool:dontBroadcast) {
    playing=true;
}

public Action:teamplay_round_start(Handle:event, const String:name[], bool:dontBroadcast) {
    playing=false;
    CreateTimer(0.1, Timer_NewGame);
}

public Action:Timer_DisableCps(Handle:timer) {
    DisableCps();
}

public Action:Timer_NewGame(Handle:timer) {
    NewGame();
}

public Action:player_team(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!client || !IsClientInGame(client) || IsFakeClient(client)) return;
    if (IsClientSourceTV(client) || IsClientReplay(client)) return;

    new HTeam:team = HTeam:GetEventInt(event, "team");

    if (client != hidden && team==HTeam_Hidden) {
        ChangeClientTeam(client, _:HTeam_Iris);
    }
}

public Action:player_spawn(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new TFClassType:class = TF2_GetPlayerClass(client);
    
    if (client==hidden) {
        if (class!=TFClass_Spy) {
            TF2_SetPlayerClass(client, TFClass_Spy, true, true);
            CreateTimer(0.1, Timer_Respawn, client);
        }
        newHidden=true;
    } else {
        if (class==TFClass_Spy || ((class==TFClass_Engineer) && (!cvar_allowengineer))  || ((class==TFClass_Pyro) && (!cvar_allowpyro))) {
            TF2_SetPlayerClass(client, TFClass_Soldier, true, true);
            CreateTimer(0.1, Timer_Respawn, client);
            if (playing) {
                PrintToChat(client, "\x04[%s]\x01 You cannot use this class on team IRIS", PLUGIN_NAME);
            }
        }
    }
}

public Action:player_hurt(Handle:event, const String:name[], bool:dontBroadcast) {
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    if (victim!=hidden) return;
    
    new damage = GetEventInt(event, "damageamount");
    hiddenHp-=damage;

    if (hiddenHp<0) hiddenHp=0;
    
    if (hiddenHp>500) {
        SetEntityHealth(hidden, 500);
    } else if (hiddenHp>0) {
        SetEntityHealth(hidden, hiddenHp);
    }
}

public Action:player_death(Handle:event, const String:name[], bool:dontBroadcast) {
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    
    if (!playing) {
        if (victim==hidden) {
            RemoveHiddenPowers(victim);
        }
        return;
    }
    
    if (victim==hidden) {
        hiddenHp=0;
        RemoveHiddenPowers(victim);
        PrintToChatAll("\x04[%s]\x01 \x03The Hidden\x01 was killed!", PLUGIN_NAME);
    } else {
        if (hidden!=0 && attacker==hidden) {
            hiddenInvisibility+=HIDDEN_INVISIBILITY_TIME*0.35
            if (hiddenInvisibility>HIDDEN_INVISIBILITY_TIME) {
                hiddenInvisibility=HIDDEN_INVISIBILITY_TIME;
            }
            hiddenHp+=HIDDEN_HP_PER_KILL;
            if (hiddenHp>hiddenHpMax) {
                hiddenHp=hiddenHpMax;
            }
            PrintToChatAll("\x04[%s]\x01 \x03The Hidden\x01 killed \x03%N\x01 and ate his body", PLUGIN_NAME, victim);
            CreateTimer(0.1, Timer_Dissolve, victim);
        }
    }
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) {
    if (!CanPlay()) return Plugin_Continue;
    if (client==hidden) {
        new bool:changed=false;
        
        if (hiddenStick && hiddenStamina<HIDDEN_STAMINA_TIME-0.5) {
            if (buttons & IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT|IN_JUMP > 0)
            {
                HiddenUnstick();
            }
        }
        
        if (hiddenAway && (buttons & IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT|IN_JUMP) > 0)
        {
            hiddenAway=false;
        }
        
        if (buttons&IN_ATTACK) {
            changed=true;
            TF2_RemoveCondition(client, TFCond_Cloaked);
            AddHiddenVisible(0.75);
        }
        
        if (buttons&IN_ATTACK2) {
            buttons&=~IN_ATTACK2;
            changed=true;
            HiddenSpecial();
        }
        
        if (buttons&IN_RELOAD) {
            #if defined HIDDEN_BOO
                HiddenBoo();
            #endif
        }
        
        if (changed) {
            return Plugin_Changed
        }
    }
    return Plugin_Continue;
}

public Action:Cmd_build(client, String:cmd[], args)
{
    if (args < 1) return Plugin_Continue;
    if (TF2_GetPlayerClass(client) != TFClass_Engineer) return Plugin_Continue;
    decl String:arg1[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    new building = StringToInt(arg1);
    if (building == _:TFObject_Sentry)
    {
        new primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary); //find out player's primary weapon
        EquipPlayerWeapon(client, primary); //switch them to that instead of build menu
        PrintToChat(client, "\x04[%s]\x01 You cannot build sentries in this game mode.", PLUGIN_NAME);
    }
    return Plugin_Continue;
}

public Action:Timer_ResetHidden(Handle:timer) {
    ResetHidden();
}

public Action:Timer_Respawn(Handle:timer, any:data) {
    TF2_RespawnPlayer(data);
}

public Action:Timer_Dissolve(Handle:timer, any:data) {
    Dissolve(data, 3);
}

public Action:Timer_GiveHiddenPowers(Handle:timer, any:data) {
    GiveHiddenPowers(GetClientOfUserId(data));
}

public Action:Timer_Tick(Handle:timer) {
    ShowHiddenHP(TICK_INTERVAL);
}

public AddHiddenVisible(Float:value) {
    if (hiddenVisible<value) hiddenVisible=value;
}

public Action:Cmd_NextHidden(client, args) {
    if (!activated) return Plugin_Continue;
    if (IsClientSourceTV(client) || IsClientReplay(client)) return Plugin_Continue;
    if (args<1) {
        if (GetCmdReplySource()==SM_REPLY_TO_CHAT) {
            ReplyToCommand(client, "\x04[%s]\x01 Usage: /nexthidden <player>", PLUGIN_NAME);
        } else {
            ReplyToCommand(client, "\x04[%s]\x01 Usage: sm_nexthidden <player>", PLUGIN_NAME);
        }
        return Plugin_Handled;
    }
    
    decl String:tmp[128];
    GetCmdArg(1, tmp, sizeof(tmp));
    
    new target = FindTarget(client, tmp, false, false);
    if (target==-1) return Plugin_Handled;
    
    forceNextHidden = GetClientUserId(target);
    
    PrintToChat(client, "\x04[%s]\x01 The next hidden will be \x03%N\x01", PLUGIN_NAME, target);
    
    return Plugin_Handled;
}

public Action:Command_EnableHidden(client, args) {
    new bool:cvar_enabled = GetConVarBool(cv_enabled);
    if (cvar_enabled) return Plugin_Handled;
    ServerCommand("tf2_hidden_enabled 1");
    ReplyToCommand(client, "[%s] Enabled.", PLUGIN_NAME);
    return Plugin_Handled;
}

public Action:Command_DisableHidden(client, args) {
    new bool:cvar_enabled = GetConVarBool(cv_enabled);
    if (!cvar_enabled) return Plugin_Handled;
    ServerCommand("tf2_hidden_enabled 0");
    ReplyToCommand(client, "[%s] Disabled.", PLUGIN_NAME);
    return Plugin_Handled;
}

stock NewGame() {
    if (!CanPlay()) return;
    if (hidden!=0) {
        return;
    }
    playing=false;
    SelectHidden();
    if (hidden==0) return;
    for (new i=1;i<=MaxClients;++i) {
        if (!IsClientInGame(i)) continue;
        if (!IsClientPlaying(i)) continue;
        if (IsClientSourceTV(i) || IsClientReplay(i)) return;
        if (i==hidden) {
            new bool:respawn=false;
            if (HTeam:GetClientTeam(i) != HTeam_Hidden) {
                ChangeClientTeam(i, _:HTeam_Hidden);
                respawn=true;
            }
            if (TF2_GetPlayerClass(i)!=TFClass_Spy) {
                TF2_SetPlayerClass(i, TFClass_Spy, true, true);
                respawn=true;
            }
            if (respawn) {
                CreateTimer(0.1, Timer_Respawn, i);
            }
        } else {
            new bool:respawn=false;
            if (HTeam:GetClientTeam(i) != HTeam_Iris) {
                ChangeClientTeam(i, _:HTeam_Iris);
                respawn=true;
            }
            new TFClassType:class=TF2_GetPlayerClass(i);

            if (class==TFClass_Unknown || class==TFClass_Spy || ((class==TFClass_Engineer) && (!cvar_allowengineer)) || ((class==TFClass_Pyro) && (!cvar_allowpyro))) {
                TF2_SetPlayerClass(i, TFClass_Soldier, true, true);
                respawn=true;
            }
            if (respawn) {
                CreateTimer(0.1, Timer_Respawn, i);
            }
            PrintToChat(i, "\x04[%s]\x01 \x03%N\x01 is \x03The Hidden\x01! Kill him before he kills you!", PLUGIN_NAME, hidden);
        }
    }
    newHidden=true;
}

public OnMapStart() {
    playing=true;
    PrecacheSound(HIDDEN_BOO_FILE, true);
}

stock DisableCps() {
    new i = -1;
    new CP = 0;

    for (new n = 0; n <= 16; n++) {
        CP = FindEntityByClassname(i, "trigger_capture_area");
        if (IsValidEntity(CP)) {
            AcceptEntityInput(CP, "Disable");
            i = CP;
        } else {
            break;
        }
    } 
}

stock bool:IsArenaMap() {
    decl String:curMap[32];
    GetCurrentMap(curMap, sizeof(curMap));
    return strncmp("arena_", curMap, 6, false)==0;
}

public OnClientDisconnect(client) {
    if (client==hidden)
        ResetHidden();
}

stock Dissolve(client, type) {
    if (!IsClientInGame(client)) return;

    new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
    if (ragdoll<0) return;

    decl String:dname[32], String:dtype[32];
    Format(dname, sizeof(dname), "dis_%d", client);
    Format(dtype, sizeof(dtype), "%d", type);
    
    new ent = CreateEntityByName("env_entity_dissolver");
    if (ent>0) {
        DispatchKeyValue(ragdoll, "targetname", dname);
        DispatchKeyValue(ent, "dissolvetype", dtype);
        DispatchKeyValue(ent, "target", dname);
        DispatchKeyValue(ent, "magnitude", "10");
        AcceptEntityInput(ent, "Dissolve", ragdoll, ragdoll);
        AcceptEntityInput(ent, "Kill");
    }
}

stock bool:CanPlay() {
    // Requires 2 or more players, excluding bots in the server.
    if (Client_GetCount(true, false) >= 2) {
        return true;
    } else {
        return false;
    }
}

stock IsClientPlaying(i) {
    return GetClientTeam(i)>0 && !GetEntProp(i, Prop_Send, "m_bArenaSpectator");
}

stock MakeTeamWin(team) {
    new ent = FindEntityByClassname(-1, "team_control_point_master");
    if (ent == -1) {
        ent = CreateEntityByName("team_control_point_master");
        DispatchSpawn(ent);
        AcceptEntityInput(ent, "Enable");
    }
    
    SetVariantInt(team);
    AcceptEntityInput(ent, "SetWinner");
}

stock SelectHidden() {
    hidden=0;
    hiddenHpMax=HIDDEN_HP+((GetClientCount(true)-1)*HIDDEN_HP_PER_PLAYER)
    hiddenHp=hiddenHpMax;
    hiddenVisible=0.0;
    hiddenStamina=HIDDEN_STAMINA_TIME;
    hiddenStick=false;
    hiddenAway=true;
    hiddenAwayTime=0.0;
    hiddenJump=0.0;
    hiddenInvisibility=HIDDEN_INVISIBILITY_TIME;
    
    #if defined HIDDEN_BOO
        hiddenBoo=0.0;
    #endif
    
    new tmp=GetClientOfUserId(forceNextHidden);
    
    if (tmp) {
        hidden=tmp;
        forceNextHidden=0;
    } else {
        new clientsCount;
        new clients[MAXPLAYERS+1];
        for (new i=1;i<=MaxClients;++i) {
            if (!IsClientInGame(i)) continue;
            if (!IsClientPlaying(i)) continue;
            if (IsFakeClient(i)) continue;
            if (IsClientInKickQueue(i)) continue;
            if (IsClientTimingOut(i)) continue;
            if (IsClientSourceTV(i)) continue;
            if (IsClientReplay(i)) continue;
            if (GetClientUserId(i)==lastHiddenUserid) continue;
            clients[clientsCount++]=i;
        }
        
        //If there isn't any players, try to add the last hidden
        if (clientsCount==0) {
            tmp=GetClientOfUserId(lastHiddenUserid);
            if (tmp!=0)
                clients[clientsCount++]=tmp;
        }
        
        //If there isn't any players, try to add bots
        if (clientsCount==0) {
            for (new i=1;i<=MaxClients;++i) {
                if (!IsClientInGame(i)) continue;
                if (!IsClientPlaying(i)) continue;
                if (IsFakeClient(i)) continue;
                clients[clientsCount++]=i;
            }
        }
        
        if (clientsCount==0) {
            return hidden;
        }
        
        hidden = clients[GetRandomInt(0, clientsCount-1)];
    }
    
    ChangeClientTeam(hidden, _:HTeam_Hidden);
    TF2_SetPlayerClass(hidden, TFClass_Spy, true, true);
    
    if (!IsPlayerAlive(hidden)) {
        TF2_RespawnPlayer(hidden);
    }
    
    PrintToChat(hidden, "\x04[%s]\x01 You are \x03The Hidden\x01! Kill the IRIS Team!", PLUGIN_NAME);
    PrintToChat(hidden, "\x04[%s]\x01 \x03%attack2% to use the super jump or stick to walls, Press %reload% to use your stun attack.\x01", PLUGIN_NAME);

    return hidden;
}

public bool:TraceRay_HitWorld(entityhit, mask) {
    return entityhit==0;
}

stock bool:HiddenSuperJump() {
    if (hidden==0) return false;
    if (hiddenJump>0.0) return false;
    hiddenJump = HIDDEN_JUMP_TIME;
    
    HiddenUnstick();
    
    decl Float:ang[3];
    decl Float:vel[3];
    GetClientEyeAngles(hidden, ang);
    GetEntPropVector(hidden, Prop_Data, "m_vecAbsVelocity", vel);
    
    decl Float:tmp[3];
    
    GetAngleVectors(ang, tmp, NULL_VECTOR, NULL_VECTOR);
    
    vel[0] += tmp[0]*900.0;
    vel[1] += tmp[1]*900.0;
    vel[2] += tmp[2]*900.0;
    
    new flags=GetEntityFlags(hidden);
    if (flags & FL_ONGROUND)
        flags &= ~FL_ONGROUND;

    SetEntityFlags(hidden, flags);
    TeleportEntity(hidden, NULL_VECTOR, NULL_VECTOR, vel);
    AddHiddenVisible(1.0);
    
    return true;
}

stock bool:HiddenSpecial() {
    if (hidden==0) return;
    if (HiddenStick()==-1) {
        HiddenSuperJump();
    }
}

stock HiddenStick() {
    if (hidden==0) return 0;
    
    decl Float:pos[3];
    decl Float:ang[3];
    
    GetClientEyeAngles(hidden, ang);
    GetClientEyePosition(hidden, pos);
    
    new Handle:ray = TR_TraceRayFilterEx(pos, ang, MASK_ALL, RayType_Infinite, TraceRay_HitWorld);
    if (TR_DidHit(ray)) {
        decl Float:pos2[3];
        TR_GetEndPosition(pos2, ray);
        if (GetVectorDistance(pos, pos2)<64.0) {
            if (hiddenStick || hiddenStamina<HIDDEN_STAMINA_TIME*0.7) {
                CloseHandle(ray);
                return 0;
            }
            
            hiddenStick=true;
            if (GetEntityMoveType(hidden)!=MOVETYPE_NONE) {
                SetEntityMoveType(hidden, MOVETYPE_NONE);
            }
            CloseHandle(ray);
            return 1;
        } else {
            CloseHandle(ray);
            return -1;
        }
    } else {
        CloseHandle(ray);
        return -1;
    }
}

public HiddenUnstick() {
    hiddenStick=false;
    if (GetEntityMoveType(hidden)==MOVETYPE_NONE) {
        SetEntityMoveType(hidden, MOVETYPE_WALK);
        new Float:vel[3];
        TeleportEntity(hidden, NULL_VECTOR, NULL_VECTOR, vel);
    }
}

stock GiveHiddenVision(i) {
    OverlayCommand(i, HIDDEN_OVERLAY);
}

stock RemoveHiddenVision(i) {
    OverlayCommand(i, "\"\"");
}

stock ShowHiddenHP(Float:duration) {
    if (hidden==0) return;
    duration+=0.1;
    
    new Float:perc=float(hiddenHp)/float(hiddenHpMax)*100.0;
    SetHudTextParams(-1.0, 0.3, duration, 255, 255, 255, 255)
    
    for (new i=1;i<=MaxClients;++i) {
        if (!IsClientInGame(i)) continue;
        if (IsFakeClient(i)) continue;
        if (IsClientSourceTV(i) || IsClientReplay(i)) continue;
        if (i==hidden) continue;
        ShowHudText(i, 0, "Hidden Health: %.1f%%", perc);
    }
    
    if (perc>60.0) {
        SetHudTextParams(-1.0, 0.3, duration, 0, 255, 0, 255);
    } else if (perc>30.0) {
        SetHudTextParams(-1.0, 0.3, duration, 128, 128, 0, 255);
    } else {
        SetHudTextParams(-1.0, 0.3, duration, 255, 0, 0, 255);
    }
    
    ShowHudText(hidden, 0, "Hidden Health: %.1f%%", perc);
    
    SetHudTextParams(-1.0, 0.325, duration, 255, 255, 255, 255);
    ShowHudText(hidden, 1, "Stamina: %.0f%%", hiddenStamina/HIDDEN_STAMINA_TIME*100.0);
    
    #if defined HIDDEN_BOO
        SetHudTextParams(-1.0, 0.35, duration, 255, 255, 255, 255);
        ShowHudText(hidden, 2, "Boo: %.0f%%", 100.0-hiddenBoo/HIDDEN_BOO_TIME*100.0);
    #endif
}

stock GiveHiddenPowers(i) {
    if (!i) return;

    TF2_RemoveWeaponSlot(i, 0); // Revolver
    //TF2_RemoveWeaponSlot(i, 1); // Sapper
    TF2_RemoveWeaponSlot(i, 2); // Knife
    TF2_RemoveWeaponSlot(i, 3); // Disguise Kit
    TF2_RemoveWeaponSlot(i, 4); // Invisibility Watch
    TF2_RemoveWeaponSlot(i, 5); // Golden Machine Gun
                                        
    // This will add the knife to the spy, even if he has another unlock
    new knife=GivePlayerItem(i, "tf_weapon_knife");
    SetEntProp(knife, Prop_Send, "m_iItemDefinitionIndex", 4);
    SetEntProp(knife, Prop_Send, "m_iEntityLevel", 100);
    SetEntProp(knife, Prop_Send, "m_iEntityQuality", 10);
    SetEntProp(knife, Prop_Send, "m_bInitialized", 1);
    // Also, I hate extensions :p
    EquipPlayerWeapon(i, knife);
    GiveHiddenVision(i);
    Client_SetHideHud(i, HIDEHUD_HEALTH)
}

stock RemoveHiddenPowers(i) {
    RemoveHiddenVision(i);
    Client_SetHideHud(i, 0);
}

stock ResetHidden() {
    if (hidden!=0 && IsClientInGame(hidden)) {
        RemoveHiddenPowers(hidden);
        lastHiddenUserid=GetClientUserId(hidden);
    } else {
        lastHiddenUserid=0;
    }
    hidden=0;
}

stock OverlayCommand(client, String:overlay[]) {    
    if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
        SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT));
        ClientCommand(client, "r_screenoverlay %s", overlay);
    }
}

#if defined HIDDEN_BOO
stock bool:HiddenBoo() {
    if (hidden==0) return false;
    if (hiddenBoo>0.0) return false;
    hiddenBoo = HIDDEN_BOO_TIME;
    
    decl Float:pos[3];
    decl Float:eye[3];
    decl Float:pos2[3];
    GetClientAbsOrigin(hidden, pos);
    GetClientEyePosition(hidden, eye);
    
    AddHiddenVisible(HIDDEN_BOO_VISIBLE);
    
    new targets[MaxClients];
    new targetsCount;
    for (new i=1;i<=MaxClients;++i) {
        if (!IsClientInGame(i)) continue;
        if (!IsPlayerAlive(i)) continue;
        if (i==hidden) continue;
        GetClientAbsOrigin(i, pos2);
        if (GetVectorDistance(pos, pos2, true)>196.0*196.0) {
            continue
        }
        
        TF2_StunPlayer(i, HIDDEN_BOO_DURATION, _, TF_STUNFLAG_GHOSTEFFECT|TF_STUNFLAG_THIRDPERSON, hidden);
        targets[targetsCount++] = i;
    }
    targets[targetsCount++] = hidden;
    
    EmitSound(targets, targetsCount, HIDDEN_BOO_FILE, SOUND_FROM_PLAYER, _, _, _, _, _, hidden, eye);
    
    return true;
}
#endif
