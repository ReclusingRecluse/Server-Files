#include <sdkhooks>
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION		"1.00"
#define MAX_MODIFIER_Name_Length 200
#define MAX_ELEMENTAL_BURNS 3

//new Handle:c;
new String:Modifiers[64];

Handle:kv_MissionModifiersFile = INVALID_HANDLE;

char CurrentMVMMission[255];

char Mission_ModifierName[MAX_MODIFIER_Name_Length];

new bool:ObtuseSolar_active = false;

new bool:ObtuseVoid_active = false;

new bool:ObtuseArc_active = false;

public Plugin:myinfo =
{
	name		= "Uberupgrades Modifiers",
	author		= "Recluse",
	description	= "Adds Modifiers",
	version		= PLUGIN_VERSION,
};

public void OnPluginStart()
{
	HookEvent("mvm_mission_update", Event_mvm_mission_update);
	//HookEvent("mvm_wave_failed", Event_mvm_wave_failed);
	//HookEvent("mvm_reset_stats", Event_ResetStats);
	
	//Commands and stuff
	RegConsoleCmd("sm_modifiers", Modifiers);
	
	//Hooks
	for(new i=0; i<=MaxClients; i++)
	{
		if(!IsValidClient(i)){continue;}
		SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}
	
/*
// Generate Config Files to make managing modifiers easier
public void LoadModifiers()
{
	new Handle:kv = CreateKeyValues("Mission_Modifiers");
	//kv = CreateKeyValues("modifiers");
	FileToKeyValues(kv, "addons/sourcemod/configs/mission_modifiers.txt");
	PrintToServer("Getting Modifiers (kvh:%d)", kv);
	BrowseModifierKV(kv);
	CloseHandle(kv);
}
*/

public bool BrowseModifierKV()
{
	kv_MissionModifiersFile = CreateModifierCfg(kv_MissionModifiersFile);
	if (kv_MissionModifiersFile == INVALID_HANDLE) return false;
	
	kvRewind(kv_MissionModifiersFile);
	kvGotoFirstSubKey(kv_MissionModifiersFile, false); //Missions Subkey
	
	char MissionName[255];
	do
	{
		KvGetSectionName(kv_MissionModifiersFile, MissionName, sizeof(MissionName)) //Get specific mission name
		
		if (StrEqual(CurrentMVMMission, MissionName, false))
		{	
			kvGotoFirstSubKey(kv_MissionModifiersFile, false);
			
			do
			{
				KvGetSectionName(kv_MissionModifiersFile, MissionName, sizeof(MissionName));
				
				KvGetString(kv_MissionModifiersFile, "Elemental Burns", Mission_ModifierName[MAX_MODIFIER_Name_Length]);
}

public Handle CreateModifierCfg(Handle CFGFile)
{
	if (CFGFile != INVALID_HANDLE)
	{
		CFGFile = CreateKeyValues("mvm_mission_modifiers");
		
		char cfgdata[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, cData, PLATFORM_MAX_PATH, "data/mvm_mission_modifiers.txt");
		
		FileToKeyValues(CFGFile, cfgdata);
	}
	return CFGFile;
}

public OnClientPutInServer(client)
{
	if (IsValidClient(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

//Select Active Modifiers for Current Mission

public Event_mvm_mission_update(Handle:event, const String:name[], bool:dontBroadcast)
{
	char responseBuffer[4096];
	int ObjResc = FindEntityByClassname(-1, "tf_objective_resource");
	
	if (IsValidEntity(ObjResc))
	{
		GetEntPropString(ObjResc, Prop_Send, "m_iszMvMPopfileName", responseBuffer, sizeof(responseBuffer));
	
		GetEntPropString(ObjResc, Prop_Send, "m_iszMvMPopfileName", CurrentMVMMission, sizeof(CurrentMVMMission));
	}
	
	decl String:Modifier1[32];
	decl String:Modifier2[32];
	if (IsValidEntity(ObjResc))
	{
		if (StrContains(responseBuffer, "666", true) != -1)
		{
			PrintToChatAll("Active Modifiers:");
			PrintToChatAll("%s", Modifier1);
			PrintToChatAll("%s", Modifier2);
		}
	}
}
//Functions and stuff

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsValidClient(attacker) && IsPlayerAlive(attacker) && !(damagetype & DMG_NERVEGAS))
	{
		new AttackerWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(AttackerWeapon))
		{
			//Elemental Burns
			
			if (!IsFakeClient(attacker) && IsFakeClient(victim))
			{
				if (ObtuseVoid_active == true)
				{
					if (WepAttribCheck(AttackerWeapon, "strange restriction user value 3"))
					{
						damage *= 2.0;
					}
				}
				if (ObtuseSolar_active == true)
				{
					if (WepAttribCheck(AttackerWeapon, "scorch"))
					{
						damage *= 2.0;
					}
				}
				if (ObtuseArc_active == true)
				{
					if (WepAttribCheck(AttackerWeapon, "throwable particle trail only"))
					{
						damage *= 2.0;
					}
				}
			}
			
			if (IsFakeClient(attacker) && !IsFakeClient(victim))
			{
				if (ObtuseVoid_active == true)
				{
					if (WepAttribCheck(AttackerWeapon, "strange restriction user value 3"))
					{
						damage *= 2.8;
					}
				}
				if (ObtuseSolar_active == true)
				{
					if (WepAttribCheck(AttackerWeapon, "scorch"))
					{
						damage *= 2.8;
					}
				}
				if (ObtuseArc_active == true)
				{
					if (WepAttribCheck(AttackerWeapon, "throwable particle trail only"))
					{
						damage *= 2.8;
					}
				}
			}
		}
	}
	return Plugin_Changed;
}

//Stonks

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