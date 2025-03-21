#include <sourcemod>
#include <sdktools>
#include <tf2attributes>
#include <sdkhooks>


#define PLUGIN_VERSION		"1.00"
public Plugin:myinfo =
{
	name		= "Recluse's Custom Attributes",
	author		= "Recluse",
	description	= "Adds a nice ammount of custom attributes",
	version		= PLUGIN_VERSION,
};

// Hooks

public OnPluginStart()
{
	//HookEvent("player_death", Event_Death);
	//HookEvent("player_spawn", Event_PlayerreSpawn);
	HookEvent("post_inventory_application", Event_PostInvApp);
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

// Ints, Bools, and Floats

// Luck in The Chamber

int LuckInChamberRound[MAXPLAYERS+1] = {0, ...};




// Actual Functions

public Action:Event_PostInvApp(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client))
	{
		//hook weapon Reload for Luck In Chamber
		
		new Ent_ClientWep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(Ent_ClientWep))
		{
			SDKHook(Ent_ClientWep, SDKHook_Reload, Hook_WeaponReload);
		}
	}
}

//Luck In Chamber Calc

public Action:Hook_WeaponReload(Ent_ClientWep)
{
	if (IsValidEntity(Ent_ClientWep))
	{
		if (WepAttribCheck(Ent_ClientWep, "luck in the chamber"))
		{
			int maxclip = GetEntProp(Ent_ClientWep, Prop_Data, "m_iClip1");
			
			LuckInChamberRound[
				



// Stocks

stock bool WepAttribCheck(c_weapon, const char[] attribname)
{
	if (IsValidEntity(c_weapon))
	{
		new Address:Attrib = TF2Attrib_GetByName(c_weapon, attribname);
		
		if (Attrib!=Address_Null)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	else {return false;}
}