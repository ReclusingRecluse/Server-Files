#include <sourcemod>
#include <sdktools>
#include <tf2attributes>
#include <sdkhooks>

#define PLUGIN_VERSION		"1.00"
public Plugin:myinfo =
{
	name		= "Uberupgrades Weapon Augments",
	author		= "Recluse",
	description	= "Adds weapon augments",
	version		= PLUGIN_VERSION,
};





public OnPluginStart()
{
	//HookEvent("player_death", Event_Death);
	//HookEvent("player_spawn", Event_PlayerreSpawn);
	for(new i=0; i<=MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public OnPluginEnd()
{
	//UnhookEvent("player_death", Event_Death);
	//UnhookEvent("player_spawn", Event_PlayerreSpawn);
	for(new i=0; i<=MaxClients; i++)
	{
		if (IsValidClient(i))
		{
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}