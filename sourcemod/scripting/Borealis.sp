#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <sdkhooks>
#include <Reclusedpen>


new LastButtons[MAXPLAYERS+1] = -1;

new bool:ExplosionReady[MAXPLAYERS+1];

new Float:SwitchDelay[MAXPLAYERS+1] = 0.0;

new Float:Element[MAXPLAYERS+1] = 0.0;

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerreSpawn)
	for(new i=1; i<=MAXPLAYERS; i++)
	{
		if(IsValidClient(i))
		{
			ExplosionReady[i] = false;
			Element[i] = 1.0;
			SDKHook(i, SDKHook_PreThink, OnClientPreThink);
		}
	}
}

public OnPluginEnd()
{
	UnhookEvent("player_death", Event_PlayerreSpawn)
	for(new i=1; i<=MAXPLAYERS; i++)
	{
		if(IsValidClient(i))
		{
			ExplosionReady[i] = false;
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKUnhook(i, SDKHook_PreThink, OnClientPreThink);
		}
	}
}

public OnClientPutInServer(client)
{
	Element[client] = 1.0;
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
public OnClientPreThink(client) OnPreThink(client);
public OnPreThink(client)
{
	new ButtonsLast = LastButtons[client];
	new Buttons = GetClientButtons(client);
	new Buttons2 = Buttons;
	
	Buttons = BorealisButtons(client, Buttons, ButtonsLast);
	
	if (Buttons != Buttons2) SetEntProp(client, Prop_Data, "m_nButtons", Buttons);	
	LastButtons[client] = Buttons;
}

BorealisButtons(client, &Buttons, &ButtonsLast)
{
	new Borealis = GetPlayerWeaponSlot(client,0);
	if (IsValidEntity(Borealis))
	{
		new ItemDefinition = GetEntProp(Borealis, Prop_Send, "m_iItemDefinitionIndex");
		{
			if (ItemDefinition == 14 || 201 || 230 || 402 || 526 || 664 || 752 || 792 || 851)
			{
				new Address:TheElements = TF2Attrib_GetByName(Borealis, "strange restriction user type 2");
				
				if (TheElements!=Address_Null)
				{
					if ((Buttons & IN_RELOAD == IN_RELOAD))
					{
						Borealis_ElementSwitch(client);
					}
				}
			}
		}
	}
	return Buttons;
}

Borealis_ElementSwitch(client)
{
	if (SwitchDelay[client] >= GetEngineTime()) return;
	
	SwitchDelay[client] = GetEngineTime()+1.0;
	//int ElementSwitch = 0;
	//ElementSwitch = RoundToFloor(Element[client]);
	Element[client] += 1.0;
	
	switch (RoundToFloor(Element[client]))
	{
		case 1:
		{
			char[] str = "Void";
			PrintHintText(client, "Current Element: %s", str);
			CreateTimer(0.1, Timer_Void, _, TIMER_REPEAT);
		}
		case 2:
		{
			char[] str = "Solar";
			PrintHintText(client, "Current Element: %s", str);
			CreateTimer(0.1, Timer_Solar, _, TIMER_REPEAT);
		}
		case 3:
		{
			char[] str = "Arc";
			PrintHintText(client, "Current Element: %s", str);
			CreateTimer(0.1, Timer_Arc, _, TIMER_REPEAT);
		}
	}
	if (Element[client] > 3.0)
	{
		Element[client] = 0.0;
	}
}

public Action:Timer_Void(Handle:Timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			new Borealis = GetPlayerWeaponSlot(client,0);
			
			if (IsValidEntity(Borealis))
			{
				new ItemDefinition = GetEntProp(Borealis, Prop_Send, "m_iItemDefinitionIndex");
				{
					if (ItemDefinition == 14 || 201 || 230 || 402 || 526 || 664 || 752 || 792 || 851)
					{
						new Address:TheElements = TF2Attrib_GetByName(Borealis, "strange restriction user type 2");
				
						if (TheElements!=Address_Null && Element[client] == 1)
						{
							TF2Attrib_RemoveByName(Borealis, "throwable particle trail only");
							TF2Attrib_RemoveByName(Borealis, "item in slot 4");
							TF2Attrib_RemoveByName(Borealis, "Set DamageType Ignite");
							TF2Attrib_RemoveByName(Borealis, "item in slot 7");
							TF2Attrib_RemoveByName(Borealis, "weapon burn dmg increased");
							TF2Attrib_RemoveByName(Borealis, "recipe component defined item 6");
							TF2Attrib_SetByName(Borealis, "scorch", 0.0);
									
							TF2Attrib_SetByName(Borealis, "damage bonus", 1.25);
							TF2Attrib_SetByName(Borealis, "strange restriction user value 3", 15.0);
							TF2Attrib_SetByName(Borealis, "killstreak idleeffect", 6.0);
						}
					}	
				}
			}
		}
	}
}

public Action:Timer_Solar(Handle:Timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			new Borealis = GetPlayerWeaponSlot(client,0);
			
			if (IsValidEntity(Borealis))
			{
				new ItemDefinition = GetEntProp(Borealis, Prop_Send, "m_iItemDefinitionIndex");
				{
					if (ItemDefinition == 14 || 201 || 230 || 402 || 526 || 664 || 752 || 792 || 851)
					{
						new Address:TheElements = TF2Attrib_GetByName(Borealis, "strange restriction user type 2");
				
						if (TheElements!=Address_Null && Element[client] == 2)
						{
							TF2Attrib_RemoveByName(Borealis, "throwable particle trail only");
							TF2Attrib_RemoveByName(Borealis, "strange restriction user value 3");
							TF2Attrib_RemoveByName(Borealis, "slow enemy on hit");
							TF2Attrib_RemoveByName(Borealis, "damage bonus");
									
							TF2Attrib_SetByName(Borealis, "scorch", 50.0);
							TF2Attrib_SetByName(Borealis, "Set DamageType Ignite", 1.0);
							TF2Attrib_SetByName(Borealis, "weapon burn dmg increased", 7.0);
							TF2Attrib_SetByName(Borealis, "firefly", 450.0);
							TF2Attrib_SetByName(Borealis, "killstreak idleeffect", 3.0);
							TF2Attrib_SetByName(Borealis, "recipe component defined item 6", 1200.0);
						}
					}
				}
			}
		}
	}
}

public Action:Timer_Arc(Handle:Timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			new Borealis = GetPlayerWeaponSlot(client,0);
			
			if (IsValidEntity(Borealis))
			{
				new ItemDefinition = GetEntProp(Borealis, Prop_Send, "m_iItemDefinitionIndex");
				{
					if (ItemDefinition == 14 || 201 || 230 || 402 || 526 || 664 || 752 || 792 || 851)
					{
						new Address:TheElements = TF2Attrib_GetByName(Borealis, "strange restriction user type 2");
				
						if (TheElements!=Address_Null && Element[client] == 3)
						{
							TF2Attrib_RemoveByName(Borealis, "item in slot 4");
							TF2Attrib_RemoveByName(Borealis, "Set DamageType Ignite");
							TF2Attrib_RemoveByName(Borealis, "item in slot 7");
							TF2Attrib_RemoveByName(Borealis, "weapon burn dmg increased");
							TF2Attrib_RemoveByName(Borealis, "recipe component defined item 6");
							TF2Attrib_SetByName(Borealis, "scorch", 0.0);
									
							TF2Attrib_SetByName(Borealis, "damage bonus", 1.20);
							TF2Attrib_SetByName(Borealis, "throwable particle trail only", 0.70);
							TF2Attrib_SetByName(Borealis, "killstreak idleeffect", 4.0);
						}
					}
				}
			}
		}
	}
}

public OnGameFrame()
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			if (fl_CurrentOverShield[client] > 0.0)
			{
				ExplosionReady[client] = true;
			}
			if (fl_CurrentOverShield[client] == 0.0)
			{
				ExplosionReady[client] = false;
			}
		}
	}
}

public Event_PlayerreSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer=GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(killer))
	{
		new Borealis = GetPlayerWeaponSlot(killer,0);
		new Enemygun = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(Borealis))
		{
			new ItemDefinition = GetEntProp(Borealis, Prop_Send, "m_iItemDefinitionIndex");
			{
				if (ItemDefinition == 14 || 201 || 230 || 402 || 526 || 664 || 752 || 792 || 851)
				{
					new Address:TheElements = TF2Attrib_GetByName(Borealis, "strange restriction user type 2");
				
					if (TheElements!=Address_Null)
					{
						new Address:Arc = TF2Attrib_GetByName(Enemygun, "throwable particle trail only");
						new Address:Solar = TF2Attrib_GetByName(Enemygun, "Set DamageType Ignite");
						new Address:Solar2 = TF2Attrib_GetByName(Enemygun, "item in slot 4");
						new Address:Void = TF2Attrib_GetByName(Enemygun, "strange restriction user value 3");
						
						if (Arc || Solar || Solar2 || Void != Address_Null)
						{
							TF2Attrib_SetByName(Borealis, "damage bonus HIDDEN", 1.50);
							CreateTimer(5.0, Timer_Bonus);
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
		new Borealis = GetPlayerWeaponSlot(attacker,0);
			
		if (IsValidEntity(Borealis))
		{
			new ItemDefinition = GetEntProp(Borealis, Prop_Send, "m_iItemDefinitionIndex");
			{
				if (ItemDefinition == 14 || 201 || 230 || 402 || 526 || 664 || 752 || 792 || 851)
				{
					new Address:TheElements = TF2Attrib_GetByName(Borealis, "strange restriction user type 2");
				
					if (TheElements!=Address_Null)
					{
						if (ExplosionReady[victim] == true && fl_CurrentOverShield[victim] > 0.0)
						{
							new Float:Radius = 500.0
							new Float:fl_damage = 100.0;
							new Float:Pos1[3];
							GetClientEyePosition(victim, Pos1);
							Pos1[2] -= 30.0;
					
							new particle6 = CreateEntityByName( "info_particle_system" );
							if ( IsValidEntity( particle6 ) )
							{
								TeleportEntity( particle6, Pos1, NULL_VECTOR, NULL_VECTOR );
								DispatchKeyValue( particle6, "effect_name", "gas_can_impact_red" );
								DispatchSpawn( particle6 );
								ActivateEntity( particle6 );
								AcceptEntityInput( particle6, "start" );
								SetVariantString( "OnUser1 !self:Kill::8:-1" );
								AcceptEntityInput( particle6, "AddOutput" );
								AcceptEntityInput( particle6, "FireUser1" );
							}
					
							for ( new i3 = 1; i3 <= MaxClients; i3++ )
							{
								EmitSoundFromOrigin(SOUND_EXPLO, Pos1);
								if(i3 != attacker && IsClientInGame(i3) && IsPlayerAlive(i3) && GetClientTeam(i3) != GetClientTeam(attacker))
								{
									new Float:Pos2[3];
									GetClientEyePosition(i3, Pos2);
									Pos2[2] -= 30.0;
							
									new Float: distance = GetVectorDistance(Pos1, Pos2);
									if (distance <= Radius)
									{
										decl Handle:Filter2;
										(Filter2 = INVALID_HANDLE);
								
										Filter2 = TR_TraceRayFilterEx(Pos1, Pos2, MASK_SOLID, RayType_EndPoint, TraceEntityFilterPlayer, i3);
										if (Filter2 != INVALID_HANDLE)
										{
											if (!TR_DidHit(Filter2))
											{
												DealDamage(i3, RoundToFloor(fl_damage + damage*0.30), attacker, DMG_BLAST ,"pumpkindeath");
												TF2_IgnitePlayer(i3, attacker, 20.0);
												ExplosionReady[victim] = false;
												TF2Attrib_SetByName(Borealis, "dmg penalty vs nonburning", 1.70);
												CreateTimer(5.0, Timer_Bonus2);
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
	return Plugin_Changed;
}

public Action:Timer_Bonus(Handle:Timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			new Borealis = GetPlayerWeaponSlot(client,0);
			
			if (IsValidEntity(Borealis))
			{
				new ItemDefinition = GetEntProp(Borealis, Prop_Send, "m_iItemDefinitionIndex");
				{
					if (ItemDefinition == 14 || 201 || 230 || 402 || 526 || 664 || 752 || 792 || 851)
					{
						new Address:TheElements = TF2Attrib_GetByName(Borealis, "strange restriction user type 2");
				
						if (TheElements!=Address_Null)
						{
							TF2Attrib_RemoveByName(Borealis, "damage bonus HIDDEN");
						}
					}
				}
			}
		}
	}
}

public Action:Timer_Bonus2(Handle:Timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			new Borealis = GetPlayerWeaponSlot(client,0);
			
			if (IsValidEntity(Borealis))
			{
				new ItemDefinition = GetEntProp(Borealis, Prop_Send, "m_iItemDefinitionIndex");
				{
					if (ItemDefinition == 14 || 201 || 230 || 402 || 526 || 664 || 752 || 792 || 851)
					{
						new Address:TheElements = TF2Attrib_GetByName(Borealis, "strange restriction user type 2");
				
						if (TheElements!=Address_Null)
						{
							TF2Attrib_RemoveByName(Borealis, "dmg penalty vs nonburning");
						}
					}
				}
			}
		}
	}
}