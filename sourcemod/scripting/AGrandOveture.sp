#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <sdkhooks>
#include <dhooks>

float Delay[MAXPLAYERS+1] = {0.0, ...};

// Stocks & other stuff

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

new bool:Heavyshotmode_active[MAXPLAYERS+1] = false;

new Float:Heavyshotmode_shotcounter[MAXPLAYERS+1] = 0.0;

new Float:OverrideProjectiletype[MAXPLAYERS+1] = 0.0;

new LastButtons[MAXPLAYERS+1] = -1;



//Basic stuff

public OnPluginStart()
{
	HookEvent("player_changeclass", Event_PlayerreSpawn);
	HookEvent("player_spawn", Event_PlayerreSpawn);
	HookEvent("player_death", Event_PlayerreSpawn);
	HookEvent("player_hurt", Event_Playerhurt);
	HookEvent("post_inventory_application", Event_PlayerreSpawn);
	
	CreateTimer(0.1, Timer_ShotCounter, _, TIMER_REPEAT);
	for(new i=0; i<=MaxClients; i++)
	{
		if(!IsValidClient(i)){continue;}
		Heavyshotmode_active[i] = false;
		Heavyshotmode_shotcounter[i] = 0.0;
	}
}

public OnPluginEnd()
{
	UnhookEvent("player_death", Event_Death);
	UnhookEvent("player_changeclass", Event_PlayerreSpawn);
	UnhookEvent("player_spawn", Event_PlayerreSpawn);
	UnhookEvent("player_death", Event_PlayerreSpawn);
	UnhookEvent("post_inventory_application", Event_PlayerreSpawn);
	UnhookEvent("player_hurt", Event_Playerhurt);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
}

public OnEntityCreated(Ent, const String:cls[])
{
	if (StrEqual(cls, "obj_sentrygun") || StrEqual(cls, "obj_dispenser") || StrEqual(cls, "obj_teleporter")/* || StrEqual(cls, "obj_attachment_sapper")*/)
	{
		SDKHook(Ent, SDKHook_OnTakeDamage, OnTakeDamage_Building);
	}
	
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			new GrandOver = GetPlayerWeaponSlot(client,0);
	
			if (IsValidEntity(GrandOver))
			{
				new Address:Heavyshot = TF2Attrib_GetByName(GrandOver, "paint decal enum");
	
				if (Heavyshot != Address_Null)
				{
					if (StrEqual(cls, "tf_projectile_rocket") && Heavyshotmode_shotcounter[client] > 0.0 && Heavyshotmode_active[client] == true && IsValidOwner(client, "tf_projectile_rocket"))
					{
						Heavyshotmode_shotcounter[client] -= 1.0;
					}
				}
			}
		}
	}
}

public Action:Timer_ShotCounter(Handle:Timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			if (Heavyshotmode_shotcounter[client] > 0.0)
			{
				decl String:Shotsleft[32];
				Format(Shotsleft, sizeof(Shotsleft), "Heavy Shots %.0f", Heavyshotmode_shotcounter[client]);
				SetHudTextParams(-0.65, 0.20, 1.2, 255, 0, 0, 255, 2, 0.0, 0.0, 0.0);
				ShowHudText(client, -1, Shotsleft);
			}
			if (Heavyshotmode_shotcounter[client] > 20.0)
			{
				Heavyshotmode_shotcounter[client] = 20.0;
			}
			if (Heavyshotmode_shotcounter[client] < 0.0)
			{
				Heavyshotmode_shotcounter[client] = 0.0;
			}
			if (Heavyshotmode_shotcounter[client] == 0.0 && Heavyshotmode_active[client] == true)
			{
				Heavyshotmode_active[client] = false;
			}
		}
	}
}

public OnClientPreThink(client) OnPreThink(client);
public OnPreThink(client)
{
	new ButtonsLast = LastButtons[client];
	new Buttons = GetClientButtons(client);
	new Buttons2 = Buttons;
	
	Buttons = GrandOverture(client, Buttons, ButtonsLast);
	
	if (Buttons != Buttons2) SetEntProp(client, Prop_Data, "m_nButtons", Buttons);	
	LastButtons[client] = Buttons;
}


GrandOverture(client, &Buttons, &ButtonsLast)
{
	new GrandOver = GetPlayerWeaponSlot(client,0);
	if (IsValidEntity(GrandOver))
	{
		new Address:Heavyshot = TF2Attrib_GetByName(GrandOver, "paint decal enum");
	
		if (Heavyshot != Address_Null)
		{
			if ((Buttons & IN_RELOAD == IN_RELOAD) && Heavyshotmode_shotcounter[client] > 0.0)
			{
				Toggle(client)
				PrintHintText(client, "Heavy Shot Mode %s.", Heavyshotmode_active[client] ? "enabled" : "disabled");
			}
		}
	}
	return Buttons;
}

public Event_PlayerreSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client))
	{
		Heavyshotmode_shotcounter[client] = 0.0;
	}
}

public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(victim))
	{
		Heavyshotmode_shotcounter[victim] = 0.0;
	}
}

public Event_Playerhurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer=GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (IsValidClient(killer))
	{
		new Grand = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(Grand))
		{
			new Address:Heavyshot = TF2Attrib_GetByName(Grand, "paint decal enum");
			
			if(Heavyshot != Address_Null)
			{
				if (Heavyshotmode_active[killer] == false && Heavyshotmode_shotcounter[killer] < 20.0)
				{
					Heavyshotmode_shotcounter[killer] += 2.0;
				}
			}
		}
	}
}

//Main Functions

public OnGameFrame()
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			new GrandOver = GetPlayerWeaponSlot(client,0)
			
			if (IsValidEntity(GrandOver))
			{
				new Address:Heavyshot = TF2Attrib_GetByName(GrandOver, "paint decal enum");
			
				if (Heavyshot != Address_Null)
				{
					if (Heavyshotmode_active[client] == false)
					{
						OverrideProjectiletype[client] = 8.0;
						TF2Attrib_SetByName(GrandOver, "override projectile type", OverrideProjectiletype[client]);
						TF2Attrib_SetByName(GrandOver, "Projectile speed increased", 7.00);
					}
					if (Heavyshotmode_active[client] == true && Heavyshotmode_shotcounter[client] > 0.0)
					{
						OverrideProjectiletype[client] = 2.0;
						TF2Attrib_SetByName(GrandOver, "override projectile type", OverrideProjectiletype[client]);
						TF2Attrib_SetByName(GrandOver, "Projectile speed increased", 2.00);
						TF2Attrib_SetByName(GrandOver, "Blast radius increased", 3.50);
					}
				}
			}
		}
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsValidClient(attacker))
	{
		new Grand = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	
		if (IsValidEntity(Grand))
		{
			new Address:Heavyshot = TF2Attrib_GetByName(Grand, "paint decal enum");
			if (Heavyshot != Address_Null && Heavyshotmode_active[attacker] == true)
			{
				damage *= 2.2;
			}
		}
	}
	return Plugin_Changed;
}

public Action:OnTakeDamage_Building(Ent, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	new Grand = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	
	if (IsValidEntity(Grand))
	{
		new Address:Heavyshot = TF2Attrib_GetByName(Grand, "paint decal enum");
		
		if (Heavyshot != Address_Null && Heavyshotmode_active[attacker] == true)
		{
			damage *= 2.2;
		}
	}
	return Plugin_Changed;
}

stock bool:IsValidOwner(client, const char[] classname)
{
	int entity = -1; 
	while( ( entity = FindEntityByClassname( entity, classname ) )!= INVALID_ENT_REFERENCE )
	{
		int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		
		if (!IsValidEntity(owner)){return false;}
		
		if (owner == client && IsValidClient(client))
		{
			return true;
		}
	}
}

Toggle(client)
{
	if (Delay[client] >= GetEngineTime()) return;
	
	Delay[client] = GetEngineTime()+0.2;
	
	Heavyshotmode_active[client] = !Heavyshotmode_active[client];
}