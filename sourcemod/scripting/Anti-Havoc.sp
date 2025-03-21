#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <dhooks>
#include <tf2attributes>
#include <events>

stock bool:IsValidClient( client, bool:replaycheck = true )
{
    if ( client <= 0 || client > MaxClients ) return false; 
    if ( !IsClientInGame( client ) ) return false; 
    if ( !IsClientConnected( client ) ) return false; 
    if ( GetEntProp( client, Prop_Send, "m_bIsCoaching" ) ) return false; 
    if ( replaycheck )
    {
        if ( IsClientSourceTV( client ) || IsClientReplay( client ) ) return false; 
    }
    return true; 
}

bool:Pain[MAXPLAYERS+1] = {false, ...};

new Handle:cvar_antihavocenable;

public OnPluginStart()
{
	cvar_antihavocenable = CreateConVar("sm_anti_havoc_enable", "1", "little bit of trolling. Default: 1");
	HookEvent("player_death", Event_Death);
	for(new i=1; i<=MAXPLAYERS; i++)
	{
		if(IsValidClient(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public OnClientPutInServer(client)
{
	Pain[client] = false;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	new String:steamid[64];
	GetClientAuthString(client, steamid, sizeof(steamid));
	if(!strcmp("STEAM_0:1:54953906", steamid))
	{
		Pain[client] = true;
	}
	else
	{
		Pain[client] = false;
	}	
}

public OnClientDisconnect(client)
{
    if(IsClientInGame(client))
    {
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		Pain[client] = false;
    }
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(Pain[victim] == true && GetConVarFloat(cvar_antihavocenable) == 1)
	{
		new Address:Fun = TF2Attrib_GetByName(victim, "obsolete ammo penalty");
		new Wipe = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(Wipe) && Pain[attacker] == false)
		{
			damage *= 1.5+(Pow(TF2Attrib_GetValue(Fun),0.70))*0.1;
		}
	}
	return Plugin_Changed;
}

public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (Pain[victim] == true && GetConVarFloat(cvar_antihavocenable) == 1)
	{
		int Message = 14;
		
		if (GetRandomInt(0,14) <= Message)
		{
			switch (Message)
			{
				case 1:
				{
					PrintToChat(victim, "Have you tried having high upgrades?");
				}
				case 2:
				{
					PrintToChat(victim,	"You can only blame yourself for that one.");
				}
				case 3:
				{
					PrintToChat(victim, "Imagine not having good enough resistances.");
				}
				case 4:
				{
					PrintToChat(victim, "My bad, Razor's uu doesn't work, will (not) fix.");
				}
				case 5:
				{
					PrintToChat(victim, "Maybe you should go back to sucking Dell's dick eh?");
				}
				case 6:
				{
					PrintToChat(victim, "Skill issue.");
				}
				case 7:
				{
					PrintToChat(victim, "L + Ratioed + You fell off");
				}
				case 8:
				{
					PrintToChat(victim, "Hi Havoc :).");
				}
				case 9:
				{
					PrintToChat(victim, "STEAM_0:1:54953906. This You?");
				}
				case 10:
				{
					PrintToChat(victim, "Remember, if you're not having a good time, you can always go to another uu server, oh wait...");
				}
				case 11:
				{
					PrintToChat(victim, "Something might be wrong here, I think it's just you.");
				}
				case 12:
				{
					PrintToChat(victim, "You only get one shot here, and I mean only YOU.");
				}
				case 13:
				{
					PrintToChat(victim, "Don't cry, it's only an L.");
				}
				case 13:
				{
					PrintToChat(victim, "Dry your eyes, it's ok, Ls don't stay for that long.");
				}
			}
		}
	}
}