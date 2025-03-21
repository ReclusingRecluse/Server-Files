#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <sdkhooks>
#include <dhooks>
#include <Reclusedpen>
#include <UbUp-PowerSupply>

// Stocks & other stuff

new LastButtons[MAXPLAYERS+1] = -1;

new bool:NobelRound_active[MAXPLAYERS+1];

new Float:NobelRound_count[MAXPLAYERS+1];

new bool:NobleRound_buff[MAXPLAYERS+1];

float Delay[MAXPLAYERS+1] = {0.0, ...};

public OnPluginStart()
{
	HookEvent("player_death", Event_Death)
	HookEvent("player_changeclass", Event_PlayerreSpawn);
	HookEvent("player_spawn", Event_PlayerreSpawn)
	HookEvent("player_death", Event_PlayerreSpawn)
	HookEvent("post_inventory_application", Event_PlayerreSpawn)
	CreateTimer(0.1, Timer_ShotCounter, _, TIMER_REPEAT);
}
public OnPluginEnd()
{
	UnhookEvent("player_changeclass", Event_PlayerreSpawn);
	UnhookEvent("player_spawn", Event_PlayerreSpawn)
	UnhookEvent("player_death", Event_PlayerreSpawn)
	UnhookEvent("post_inventory_application", Event_PlayerreSpawn)
}
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
	NobelRound_active[client] = false;
	NobelRound_count[client] = 0.0;
	NobleRound_buff[client] = false;
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
			new Luminan = GetPlayerWeaponSlot(client,0);
	
			if (IsValidEntity(Luminan))
			{
				new Address:NobelRound = TF2Attrib_GetByName(Luminan, "energy weapon no deflect");
	
				if (NobelRound != Address_Null)
				{
					if (StrEqual(cls, "tf_projectile_flare") && NobelRound_count[client] > 0.0 && NobelRound_active[client] == true && IsValidOwner(client, "tf_projectile_flare"))
					{
						NobelRound_count[client] -= 1.0;
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
			if (NobelRound_count[client] > 0.0)
			{
				decl String:Shotsleft[32];
				Format(Shotsleft, sizeof(Shotsleft), "Noble Rounds %.0f", NobelRound_count[client]);
				SetHudTextParams(-0.65, 0.40, 1.2, 255, 0, 0, 255, 2, 0.0, 0.0, 0.0);
				ShowHudText(client, -1, Shotsleft);
			}
			if (NobelRound_count[client] > 6.0)
			{
				NobelRound_count[client] = 6.0;
			}
			if (NobelRound_count[client] < 0.0)
			{
				NobelRound_count[client] = 0.0;
			}
			if (NobelRound_count[client] == 0.0 && NobelRound_active[client] == true)
			{
				NobelRound_active[client] = false;
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
	
	Buttons = Lumina(client, Buttons, ButtonsLast);
	
	if (Buttons != Buttons2) SetEntProp(client, Prop_Data, "m_nButtons", Buttons);	
	LastButtons[client] = Buttons;
}

Lumina(client, &Buttons, &ButtonsLast)
{
	new Lumina1 = GetPlayerWeaponSlot(client,0);
	if (IsValidEntity(Lumina1))
	{
		new ItemDefinition = GetEntProp(Lumina1, Prop_Send, "m_iItemDefinitionIndex");
		{
			if (ItemDefinition == 24 || 210 || 61 || 161 || 224 || 460 || 525 || 1006 || 1142)
			{
				new Address:NobelRound = TF2Attrib_GetByName(Lumina1, "energy weapon no deflect");
	
				if (NobelRound != Address_Null)
				{
					if ((Buttons & IN_RELOAD == IN_RELOAD) && NobelRound_count[client] > 0.0)
					{
						Toggle(client)
					}
				}
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
		NobelRound_count[client] = 0.0;
	}
}

public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer=GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(killer))
	{
		new Lumina1 = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(Lumina1))
		{
			new ItemDefinition = GetEntProp(Lumina1, Prop_Send, "m_iItemDefinitionIndex");
			{
				if (ItemDefinition == 24 || 210 || 61 || 161 || 224 || 460 || 525 || 1006 || 1142)
				{
					new Address:NobelRound = TF2Attrib_GetByName(Lumina1, "energy weapon no deflect");
			
					if (NobelRound != Address_Null)
					{
						if (NobelRound_active[killer] == false && NobelRound_count[killer] < 6.0)
						{
							NobelRound_count[killer] += 1.0;
						}
					}
				}
			}
		}
	}
	if(IsValidClient(victim))
	{
		NobelRound_count[victim] = 0.0;
	}
}

public OnGameFrame()
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			new Luminan = GetPlayerWeaponSlot(client,0)
			
			if (IsValidEntity(Luminan))
			{
				new ItemDefinition = GetEntProp(Luminan, Prop_Send, "m_iItemDefinitionIndex");
				{
					if (ItemDefinition == 24 || 210 || 61 || 161 || 224 || 460 || 525 || 1006 || 1142)
					{
						new Address:NobelRound = TF2Attrib_GetByName(Luminan, "energy weapon no deflect");
				
						if (NobelRound != Address_Null)
						{
							if (NobelRound_active[client] == false)
							{
								TF2Attrib_SetByName(Luminan, "override projectile type", 1.0);
								TF2Attrib_RemoveByName(Luminan, "Projectile speed increased");
							}
							if (NobelRound_active[client] == true)
							{
								TF2Attrib_SetByName(Luminan, "override projectile type", 6.0);
								TF2Attrib_SetByName(Luminan, "Projectile speed increased", 2.00);
							}
							int ent = -1;
							while((ent = FindEntityByClassname(ent, "tf_projectile_flare")) != INVALID_ENT_REFERENCE)
							{
								new Float:Radius;
								new Float:Pos3[3];
								Pos3[2] -= 30.0;
								int owner = GetEntPropEnt( ent, Prop_Data, "m_hOwnerEntity" );
								if (!IsValidEntity(owner)) continue; 
								if (owner == client)
								{
									GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", Pos3);
									Radius = 400.0;
								
									for(new i = 1; i < MaxClients; i++)
									{
										if(i != client && IsValidClient(i) && IsPlayerAlive(client) && GetClientTeam(client) == GetClientTeam(i) && NobleRound_buff[i] == false)
										{
											new Float:Pos4[3];
											GetClientEyePosition(i, Pos4);
											Pos4[2] -= 30.0;
											new Float:Distance = GetVectorDistance(Pos3, Pos4);
												
											if (Distance < Radius)
											{
												decl Handle:Filter2;
												(Filter2 = INVALID_HANDLE);
								
												Filter2 = TR_TraceRayFilterEx(Pos3, Pos4, MASK_SOLID, RayType_EndPoint, TraceEntityFilterPlayer, i);
												if (Filter2 != INVALID_HANDLE)
												{
													if (!TR_DidHit(Filter2))
													{
														new Float:Regen = TF2_GetMaxHealth(i)*0.35;
														AcceptEntityInput(ent, "Kill");
														TeleportEntity(ent, Pos4, NULL_VECTOR, NULL_VECTOR);
															
														AddPlayerHealth(i, RoundToFloor(Regen), 1.0);
														ShowHealthGain(i, RoundToFloor(Regen), client);
														CreateTimer(1.5, Timer_Heal, _, TIMER_REPEAT);
														CreateTimer(4.0, Timer_Buff);
															
														NobleRound_buff[i] = true;
														NobleRound_buff[client] = true;
														fl_AdditionalArmorRegen[client] = 2.0;
														fl_AdditionalArmorRegen[i] = 2.0;
														
														if (fl_Overshield[i] > 0.0)
														{
															fl_CurrentOverShield[i] += fl_Overshield[i]*0.15;
														}
														if (fl_CurrentArmor[i] < fl_MaxArmor[i])
														{
															fl_CurrentArmor[i] += Regen*3.0;
														}
													}
												}
												CloseHandle(Filter2);
											}
										}
									}
								}
							}								
						}
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
		new CWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	
		if (IsValidEntity(CWeapon))
		{
			if (NobleRound_buff[attacker] == true)
			{
				damage *= 2.0;
			}
			if (NobelRound_active[attacker] == true)
			{
				damage *= 0.0;
			}
		}
	}
	return Plugin_Changed;
}

public Action:OnTakeDamage_Building(Ent, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	new CWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	
	if (IsValidEntity(CWeapon))
	{
		if (NobleRound_buff[attacker] == true)
		{
			damage *= 2.0;
		}
		if (NobelRound_active[attacker] == true)
		{
			damage *= 0.0;
		}
	}
	return Plugin_Changed;
}

public Action:Timer_Heal(Handle:Timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			if (NobleRound_buff[client] == true)
			{
				new Float:Regen2 = TF2_GetMaxHealth(client)*0.05;
				AddPlayerHealth(client, RoundToFloor(Regen2), 2.0);
				if (fl_CurrentArmor[client] < fl_MaxArmor[client])
				{
					fl_CurrentArmor[client] += Regen2*3.0;
				}
			}
		}
	}
}

public Action:Timer_Buff(Handle:Timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			if (NobleRound_buff[client] == true)
			{
				NobleRound_buff[client] = false;
				fl_AdditionalArmorRegen[client] = 0.0;
			}
		}
	}
}


stock int min(int a, int b) 
{
    return a < b ? a : b;
} 
stock TF2_GetMaxHealth(iClient)
{
    new maxhealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, iClient);
    return ((maxhealth == -1 || maxhealth == 80896) ? GetEntProp(iClient, Prop_Data, "m_iMaxHealth") : maxhealth);
}

stock AddPlayerHealth(iClient, iAdd, Float:flOverheal = 1.5, bAdditive = false, bool:bEvent = false)
{
    new iHealth = GetClientHealth(iClient);
    new iNewHealth = iHealth + iAdd;
    new iMax = bAdditive ? (TF2_GetMaxHealth(iClient) + RoundFloat(flOverheal)) : TF2_GetMaxOverHeal(iClient, flOverheal);
    if (iHealth < iMax)
    {
        iNewHealth = min(iNewHealth, iMax);
        if (bEvent)
        {
            ShowHealthGain(iClient, iNewHealth-iHealth);
        }
        SetEntityHealth(iClient, iNewHealth);
    }
}

stock ShowHealthGain(iPatient, iHealth, iHealer = -1)
{
    new iUserId = GetClientUserId(iPatient);
    new Handle:hEvent = CreateEvent("player_healed", true);
    SetEventBool(hEvent, "sourcemod", true);
    SetEventInt(hEvent, "patient", iUserId);
    SetEventInt(hEvent, "healer", IsValidClient(iHealer) ? GetClientUserId(iHealer) : iUserId);
    SetEventInt(hEvent, "amount", iHealth);
    FireEvent(hEvent);

    hEvent = CreateEvent("player_healonhit", true);
    SetEventBool(hEvent, "sourcemod", true);
    SetEventInt(hEvent, "amount", iHealth);
    SetEventInt(hEvent, "entindex", iPatient);
    FireEvent(hEvent);
}

stock TF2_GetMaxOverHeal(iClient, Float:flOverHeal = 1.5) // Quick-Fix would be 1.25
{
    return RoundFloat(float(TF2_GetMaxHealth(iClient)) * flOverHeal);
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
	
	NobelRound_active[client] = !NobelRound_active[client];
	PrintHintText(client, "Nobel Rounds %s.", NobelRound_active[client] ? "enabled" : "disabled");
}