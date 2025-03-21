#include <sourcemod>
#include <tf2>
#include <tf2attributes>
#include <sdkhooks>
#include <CustomClip_Burstfire>
#include <tf_econ_dynamic>


new LastButtons[MAXPLAYERS+1] = -1;

public OnPluginStart()
{
	HookEvent("player_changeclass", Event_PlayerreSpawn);
	HookEvent("post_inventory_application", Event_PlayerreSpawn);
	HookEvent("player_spawn", Event_PlayerreSpawn);
	
	for(new i=1; i<=MAXPLAYERS; i++)
	{
		if(IsValidClient(i))
		{
			BurstReset(i);
			SDKHook(i, SDKHook_PreThink, OnClientPreThink);
		}
	}
	TF2EconDynAttribute attrib = new TF2EconDynAttribute();
	
	attrib.SetName("burst fire weapon");
	attrib.SetClass("burst_gun");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
}

public OnPluginEnd()
{
	for(new i=1; i<=MAXPLAYERS; i++)
	{
		if(IsValidClient(i))
		{
			BurstReset(i);
		}
	}
}

public Event_PlayerreSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		CreateTimer(0.3, Timer_Detect, client);
	}
}

public Action:Timer_Detect(Handle:timer, any:client)
{
	if (IsValidClient(client))
	{
		new ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(ClientWeapon))
		{
			new Address:BurstFireActive = TF2Attrib_GetByName(ClientWeapon, "burst fire weapon");
			
			if (BurstFireActive != Address_Null)
			{
				Hasburstfireweapon[client] = true;
				BurstFireConfigure(client, ClientWeapon, 3, 1.0, false);
			}
			else
			{
				return;
			}
		}
	}
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (IsValidClient(client) && Hasburstfireweapon[client] == true)
	{
		new ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new Address:BurstFireActive = TF2Attrib_GetByName(ClientWeapon, "burst fire weapon");
		
		if (IsValidEntity(ClientWeapon) && BurstFireActive!=Address_Null)
		{
			if (MaxShots[client] > CurrentShot[client])
			{
				CurrentShot[client] += 1;
				PrintToServer("shot");
			}
			if (MaxShots[client] == CurrentShot[client])
			{
				if (g_Timer[client] == INVALID_HANDLE)
				{
					BurstFireReady[client] = false;
					g_Timer[client] = CreateTimer(g_TimerSetTime[client], BurstRefresh, client);
				}
			}
		}
	}
	return Plugin_Handled;
}

public OnClientPreThink(client) OnPreThink(client);
public OnPreThink(client)
{
	new ButtonsLast = LastButtons[client];
	new Buttons = GetClientButtons(client);
	new Buttons2 = Buttons;
	
	Buttons = BurstButtons(client, Buttons, ButtonsLast);
	
	if (Buttons != Buttons2) SetEntProp(client, Prop_Data, "m_nButtons", Buttons);	
	LastButtons[client] = Buttons;
}

BurstButtons(client, &Buttons, &ButtonsLast)
{
	if (IsValidClient(client))
	{
		if (BurstFireReady[client] == false && Hasburstfireweapon[client] == true)
		{
			if (Buttons & IN_ATTACK)
			{
				Buttons &= ~IN_ATTACK;
			}
		}
	}
	return Buttons;
}

/*
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) 
{
	if (IsValidClient(client))
	{
		if (BurstFireReady[client] == false && Hasburstfireweapon[client] == true)
		{
			if (buttons & IN_ATTACK)
			{
				buttons &= ~IN_ATTACK;
				return Plugin_Handled;
			}
		}
	}
}
*/

public Action:BurstRefresh(Handle:Timer, any:client)
{
	if (IsValidClient(client) && BurstFireReady[client] == false)
	{
		CurrentShot[client] = 0;
		BurstFireReady[client] = true;
		KillTimer(g_Timer[client]);
		g_Timer[client] = INVALID_HANDLE;
	}
}

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