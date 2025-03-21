#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <sdkhooks>

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

new bool:ArcConductor_active[MAXPLAYERS+1];

bool:Braap[MAXPLAYERS+1] = {false, ...};

//new Float:TimeAdd[MAXPLAYERS+1];

new Float:Timerm;

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	//HookEvent("player_death", Event_Death);
	ArcConductor_active[client] = false;
	Braap[client] = true;
}

public OnPluginEnd()
{
	for(new i=0; i<=MaxClients; i++)
	{
		Braap[i] = false;
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsValidClient(attacker))
	{
		new ArcGun = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		new Riskrunner = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
	
		if (IsValidEntity(ArcGun))
		{
			new Address:ArcDmgChain = TF2Attrib_GetByName(ArcGun, "throwable particle trail only");
		
			if (IsValidClient(attacker) && ArcDmgChain != Address_Null)
			{
				if (IsValidEntity(Riskrunner))
				{
					new ItemDefinition = GetEntProp(Riskrunner, Prop_Send, "m_iItemDefinitionIndex");
					{
						if (ItemDefinition == 16 || 203 || 751 || 1149)
						{
							new Address:ArcConductor = TF2Attrib_GetByName(Riskrunner, "super conductor");
						
							if(ArcConductor != Address_Null && ArcConductor_active[victim] == false)
							{
								Timerm = 5.0;
								ArcConductor_active[victim] = true;
								CreateTimer(Timerm, Timer_Conductor);
							}
						}
					}
				}
			}
		}
		if (IsValidEntity(ArcGun))
		{
			new ItemDefinition = GetEntProp(ArcGun, Prop_Send, "m_iItemDefinitionIndex");
			{
				if (ItemDefinition == 16 || 203 || 751 || 1149)
				{
					new Address:ArcConductor = TF2Attrib_GetByName(ArcGun, "super conductor");
						
					if(ArcConductor != Address_Null && ArcConductor_active[attacker] == true)
					{
						damage *= 1.30;
					}
				}
			}
		}
	}
	return Plugin_Changed;
}


public OnGameFrame()
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			new Riskrunner = GetPlayerWeaponSlot(client,0)
			
			if (IsValidEntity(Riskrunner))
			{
				new ItemDefinition = GetEntProp(Riskrunner, Prop_Send, "m_iItemDefinitionIndex");
				{
					if (ItemDefinition == 16 || 203 || 751 || 1149)
					{
						new Address:ArcConductor = TF2Attrib_GetByName(Riskrunner, "super conductor");
						
						if (ArcConductor != Address_Null)
						{
							if (ArcConductor_active[client] == true)
							{
								TF2Attrib_SetByName(Riskrunner, "throwable particle trail only", 1.00);
								TF2Attrib_SetByName(Riskrunner, "halloween reload time decreased", 0.50);
								TF2Attrib_SetByName(Riskrunner, "single wep deploy time decreased", 0.50);
								
								decl String:ArmorLeft[32]
								Format(ArmorLeft, sizeof(ArmorLeft), "Arc Conductor"); 
								SetHudTextParams(0.65, 0.2, 0.5, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
								ShowHudText(client, -1, ArmorLeft);
							}
							if (ArcConductor_active[client] == false)
							{
								TF2Attrib_SetByName(Riskrunner, "throwable particle trail only", 0.20);
								TF2Attrib_RemoveByName(Riskrunner, "halloween reload time decreased");
								TF2Attrib_RemoveByName(Riskrunner, "single wep deploy time decreased");
							}
						}
					}
				}
			}
		}
	}
}

public Action:Timer_Conductor(Handle:Timer)
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (ArcConductor_active[client] == true)
		{
			ArcConductor_active[client] = false;
		}
	}
}