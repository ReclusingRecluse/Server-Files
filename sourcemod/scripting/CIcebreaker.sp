#include <sourcemod>
#include <tf2attributes>
#include <tf2_stocks>
#include <sdkhooks>
#include <CustomClip>

new LastButtons[MAXPLAYERS+1] = {-1 , ...};

new Handle:Ice_Timer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

new bool:Overflow_Active[MAXPLAYERS+1] = {false, ...};

new bool:GunShooting[MAXPLAYERS+1] = {false, ...};

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

public OnPluginStart()
{
	HookEvent("player_changeclass", Event_PlayerreSpawn);
	HookEvent("post_inventory_application", Event_PlayerreSpawn);
	HookEvent("player_spawn", Event_PlayerreSpawn);
	//HookEvent("player_death", Event_PlayerreSpawn);
	
	//CreateTimer(0.1, Timer_Thing, _, TIMER_REPEAT);
	
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			Ice_Timer[client] = INVALID_HANDLE;
			//SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage_player);
			IsReloading[client] = false;
			Overflow_Active[client] = false;
		}
	}
}

public OnPluginEnd()
{
	UnhookEvent("player_changeclass", Event_PlayerreSpawn);
	UnhookEvent("player_spawn", Event_PlayerreSpawn);
	UnhookEvent("post_inventory_application", Event_PlayerreSpawn);
}

public OnClientPutInServer(client)
{
	if (IsValidClient(client))
	{
		Ice_Timer[client] = INVALID_HANDLE;
		//SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage_player);
		IsReloading[client] = false;
		Overflow_Active[client] = false;
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

int IceClip[MAXPLAYERS+1] = {0, ...};

public Action:Timer_Detect(Handle:Timer, any:client)
{
	if (IsValidClient(client))
	{
		new IceBreaker = GetPlayerWeaponSlot(client,0);
		
		if (IsValidEntity(IceBreaker))
		{
			new Address:IsIcebreaker = TF2Attrib_GetByName(IceBreaker, "mod no reload DISPLAY ONLY");
			
			if (IsIcebreaker != Address_Null)
			{
				new Float:AttribValue = TF2Attrib_GetValue(IsIcebreaker);
				
				if (AttribValue == 2.0)
				{
					Overflow_Active[client] = false;
					
					if (Ice_Timer[client] != INVALID_HANDLE)
					{
						KillTimer(Ice_Timer[client]);
						Ice_Timer[client] = INVALID_HANDLE;
					}
					else
					{
						Ice_Timer[client] = CreateTimer(5.0, Clip_Regen, client, TIMER_REPEAT);
					}
					IceClip[client] = ClipSet[client];
					CustomClip_SetClipAndReserves(client, IceBreaker, 0, 0, 0, false);
					
					new PrimaryAmmoType = GetEntProp(IceBreaker, Prop_Send, "m_iPrimaryAmmoType");
					PrimaryAmmoType = Reserve1Set[client];
					
					MaxammoIncrease(client, IceBreaker, 0, 0, PrimaryAmmoType, false, false);
				}
			}
		}
	}
}

public Action:Clip_Regen(Handle:Timer, any:client)
{
	if (IsValidClient(client))
	{
		new IceBreaker = GetPlayerWeaponSlot(client,0);
		if (IsValidEntity(IceBreaker))
		{
			new Address:IsIcebreaker = TF2Attrib_GetByName(IceBreaker, "mod no reload DISPLAY ONLY");
			
			if (IsIcebreaker != Address_Null)
			{
				new Float:AttribValue = TF2Attrib_GetValue(IsIcebreaker);
				
				if (AttribValue == 2.0)
				{
					int clip = GetEntProp(IceBreaker, Prop_Data, "m_iClip1");
		
					if (Overflow_Active[client] == false)
					{
						if (clip == 6)
						{
							return;
						}
						if (clip < 6 && !(clip > 6) && GunShooting[client] == false)
						{
							clip += 1;
							CustomClip_SetClipAndReserves(client, IceBreaker, 0, clip, 0, false);
						}
					}
					else
					{
						return;
					}
				}
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsValidClient(client))
	{
		new IceBreaker = GetPlayerWeaponSlot(client,0);
		if (IsValidEntity(IceBreaker))
		{
			new Address:IsIcebreaker = TF2Attrib_GetByName(IceBreaker, "mod no reload DISPLAY ONLY");
			
			if (IsIcebreaker != Address_Null)
			{
				new Float:AttribValue = TF2Attrib_GetValue(IsIcebreaker);
				
				if (AttribValue == 2.0)
				{
					int PrimaryAmmoType;
					PrimaryAmmoType = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimaryAmmoType);
		
					decl String:ArmorLeft[32]
					Format(ArmorLeft, sizeof(ArmorLeft), "Ammo %i", PrimaryAmmoType); 
					SetHudTextParams(0.65, -0.2, 0.5, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
					ShowHudText(client, -1, ArmorLeft);
					
					if ((buttons & IN_ATTACK) == IN_ATTACK)
					{
						GunShooting[client] = true;
					}
					else
					{
						GunShooting[client] = false;
						//CustomClip_ReloadCalc(client, IceBreaker, 0, 0.0, IceClip[client], false);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}