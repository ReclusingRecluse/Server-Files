#pragma tabsize 0
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <dhooks>
#include <clientprefs>
#include <Reclusedpen>
#include <custom_status_hud>

bool hooked[MAXPLAYERS+1] = {false, ...};
bool Degen_Active[MAXPLAYERS+1] = {false, ...};
bool Overshield_Active[MAXPLAYERS+1] = {false, ...};

bool SwashBuckler_Active[MAXPLAYERS+1] = {false, ...};
bool SwashBuckler_MeleeBonus[MAXPLAYERS+1] = {false, ...};
bool SwashBuckler_ShotgunBonus[MAXPLAYERS+1] = {false, ...};

float BaseResistance[MAXPLAYERS+1] = {0.0, ...};

public Action OnCustomStatusHUDUpdate(int client, StringMap entries) 
{
	if (IsValidClient(client))
	{
		char overshield[32];
		
		if (Overshield_Active[client] == true)
		{
			if (fl_CurrentOverShield[client] > 0.0)
			{
				Format(overshield, sizeof(overshield), "Overshield: %.0f/%.0f", fl_CurrentOverShield[client], fl_Overshield[client]);
				entries.SetString("uu_d_overshield", overshield);
			}
		}
	}
	return Plugin_Changed;
}

public OnPluginStart()
{
	HookEvent("player_hurt", Event_Playerhurt);
	HookEvent("player_death", Event_Death)
	HookEvent("player_changeclass", Event_PlayerreSpawn);
	HookEvent("player_spawn", Event_PlayerreSpawn)
	HookEvent("player_death", Event_PlayerreSpawn)
	HookEvent("post_inventory_application", Event_PlayerreSpawn)
	CreateTimer(0.1, Timer_Shield, _, TIMER_REPEAT);
	CreateTimer(0.4, Timer_Regen, _, TIMER_REPEAT);
	CreateTimer(0.2, Timer_Degen, _, TIMER_REPEAT);
	CreateTimer(0.25, Timer_PassiveGen, _, TIMER_REPEAT);
	for(new i=0; i<=MaxClients; i++)
	{
		if(!IsValidClient(i)){continue;}
		fl_Overshield[i] = 0.0;
		fl_CurrentOverShield[i] = 0.0;
		Degen_Active[i] = true;
		if (hooked[i] == false)
		{
			hooked[i] = true;
			SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
		}
	}
}
public OnPluginEnd()
{
	for(new i=0; i<=MaxClients; i++)
	{
		if(!IsValidClient(i)){continue;}
		fl_Overshield[i] = 0.0;
		fl_CurrentOverShield[i] = 0.0;
		Degen_Active[i] = false;
		if (hooked[i] == true)
		{
			hooked[i] = false;
			SDKUnhook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
		}
	}
	UnhookEvent("player_hurt", Event_Playerhurt)
	UnhookEvent("player_changeclass", Event_PlayerreSpawn);
	UnhookEvent("player_spawn", Event_PlayerreSpawn)
	UnhookEvent("player_death", Event_PlayerreSpawn)
	UnhookEvent("post_inventory_application", Event_PlayerreSpawn)
	PrintToChatAll("Overshield has been Unloaded")
}
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

public Action:Timer_Regen(Handle:Timer)
{
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if (IsClientInGame(i))
		{
			if (TF2_IsPlayerInCondition(i, TFCond_MegaHeal) && TF2_IsPlayerInCondition(i, TFCond_Overhealed) && fl_CurrentOverShield[i] < fl_Overshield[i])
			{
				fl_CurrentOverShield[i] += 120;
			}
		}
	}
}

public Action:Timer_PassiveGen(Handle:Timer)
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			new AttWep1 = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			
			if (IsValidEntity(AttWep1))
			{
				new ItemDefinition = GetEntProp(AttWep1, Prop_Send, "m_iItemDefinitionIndex");
				{
					if (ItemDefinition == 331)
					{
						new Address:ImpD = TF2Attrib_GetByName(AttWep1, "has pipboy build interface");
					
						if (ImpD != Address_Null && fl_CurrentOverShield[client] < fl_Overshield[client]*0.60)
						{
							fl_CurrentOverShield[client] += 40;
						}
					}
				}
			}
		}
	}
}

public Action:Timer_Shield(Handle:Timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			new Address:ShieldAmount = TF2Attrib_GetByName(client, "powerup max charges");
			if (ShieldAmount!=Address_Null)
			{
				new Float:Shield = TF2Attrib_GetValue(ShieldAmount);
				fl_Overshield[client] = Shield;
				Overshield_Active[client] = true;
			}
			else
			{
				fl_Overshield[client] = 0.0;
			}
			if (fl_Overshield[client] > 0.0)
			{
				Overshield_Active[client] = true;
			}
			else
			{
				Overshield_Active[client] = false;
			}
			
			/*
			if (Overshield_Active[client] == true)
			{
				decl String:ShieldLeft[32]
				Format(ShieldLeft, sizeof(ShieldLeft), "OverShield %.0f / %.0f", fl_CurrentOverShield[client], fl_Overshield[client]); 
				new Float:pctShield =  fl_CurrentOverShield[client]/fl_Overshield[client];
				if(pctShield > 0.5 && fl_CurrentOverShield[client] > 0.0)
				{
					SetHudTextParams(-0.65, 0.8, 0.5, 0, 255, 0, 255, 0, 0.0, 0.0, 0.0);
					ShowHudText(client, -1, ShieldLeft);
				}
				else if(pctShield <= 0.5 && pctShield > 0.25 && fl_CurrentOverShield[client] > 0.0)
				{
					SetHudTextParams(-0.65, 0.8, 0.5, 255, 255, 0, 255, 0, 0.0, 0.0, 0.0);
					ShowHudText(client, -1, ShieldLeft);				
				}
				else if (fl_CurrentOverShield[client] > 0.0)
				{
					SetHudTextParams(-0.65, 0.8, 0.5, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
					ShowHudText(client, -1, ShieldLeft);				
				}
			}
			*/
			
			new AttWep1 = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			
			if (IsValidEntity(AttWep1))
			{
				new ItemDefinition = GetEntProp(AttWep1, Prop_Send, "m_iItemDefinitionIndex");
				{
					if (ItemDefinition == 331)
					{
						new Address:ImpD = TF2Attrib_GetByName(AttWep1, "has pipboy build interface");
						
						if (ImpD != Address_Null)
						{
							Degen_Active[client] = false;
							
							if (fl_Overshield[client] == 0.0)
							{
								BaseResistance[client] = 2.0;
								TF2Attrib_SetByName(client, "powerup max charges", 1000.0);
							}
						}
					}
					else
					{
						Degen_Active[client] = true;
					}
				}
			}
		}
	}
}

public Action:Timer_Degen(Handle:Timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			if(fl_CurrentOverShield[client] > 0.0 && Degen_Active[client] == true)
			{
				fl_CurrentOverShield[client] -= 10.0;
			}
			if(fl_CurrentOverShield[client] < 0.0)
			{
				fl_CurrentOverShield[client] = 0.0;
			}
		}
	}
}

public Event_Playerhurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer=GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Float:damage = GetEventFloat(event, "damageamount");
	
	if (IsValidClient(killer) && IsPlayerAlive(killer))
	{
		if(fl_CurrentOverShield[client] < 0.0)
		{
			fl_CurrentOverShield[client] = 0.0;
		}
		if (fl_CurrentOverShield[client] > 0.0)
		{
			fl_CurrentOverShield[client] -= (10.0+damage*0.7);
			new AttWep1 = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
			new Address:Disruptor = TF2Attrib_GetByName(AttWep1, "referenced item id low");
			if (Disruptor != Address_Null)
			{
				fl_CurrentOverShield[client] -= (24.0+damage*2.3)+Pow(TF2Attrib_GetValue(Disruptor),0.20);
			}
		}
		if (TF2_IsPlayerInCondition(killer, TFCond_RegenBuffed) && fl_CurrentOverShield[killer] < fl_Overshield[killer])
		{
			new Float:ShieldGainOnHit = damage*0.15;
			fl_CurrentOverShield[killer] += ShieldGainOnHit;
			if (fl_CurrentOverShield[killer] > fl_Overshield[killer])
			{
				fl_CurrentOverShield[killer] = fl_Overshield[killer];
			}
		}
		if (TF2_IsPlayerInCondition(killer, TFCond_Buffed))
		{
			fl_CurrentOverShield[client] -= (7.0+damage*1.45);
		}
	}
}

public Event_PlayerreSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		fl_CurrentOverShield[client] = 0.0;
		SwashBuckler_Active[client] = false;
		SwashBuckler_MeleeBonus[client] = false;
		SwashBuckler_ShotgunBonus[client] = false;
	}
}
public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer=GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(IsValidClient(killer) && !IsFakeClient(killer) && IsPlayerAlive(killer))
	{
		new AttWep1 = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
		new Melee=GetPlayerWeaponSlot(killer,2);
		new Address:OvershieldPerkill = TF2Attrib_GetByName(killer, "kill eater user 3");
		if (OvershieldPerkill!=Address_Null && fl_CurrentOverShield[killer] < fl_Overshield[killer] && fl_CurrentOverShield[killer] != fl_Overshield[killer])
		{
			new Float:AmountOnKill = TF2Attrib_GetValue(OvershieldPerkill);
			fl_CurrentOverShield[killer] += AmountOnKill;
		}

		if (IsValidEntity(AttWep1))
		{
			decl String:logname[32];
			GetEdictClassname(AttWep1, logname, sizeof(logname));

			if (!strcmp("tf_weapon_shotgun_hwg", logname) || !strcmp("tf_weapon_shotgun", logname))
			{
				if (IsValidEntity(Melee))
				{
					new Address:ImpD = TF2Attrib_GetByName(Melee, "has pipboy build interface");
						
					if (ImpD != Address_Null)
					{
						SwashBuckler_Active[killer] = true;
						SwashBuckler_MeleeBonus[killer] = true;
						CreateTimer(5.0, Swash_Remove, killer);
					}
				}
			}
		}
		if (IsValidEntity(Melee))
		{
			new ItemDefinition = GetEntProp(AttWep1, Prop_Send, "m_iItemDefinitionIndex");
			{
				if (ItemDefinition == 331)
				{
					new Address:ImpD = TF2Attrib_GetByName(AttWep1, "has pipboy build interface");
						
					if (ImpD != Address_Null)
					{
						SwashBuckler_Active[killer] = true;
						SwashBuckler_ShotgunBonus[killer] = true;
						CreateTimer(5.0, Swash_Remove, killer);
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
		new Address:OverShieldReduction = TF2Attrib_GetByName(victim, "rage on kill");
		new AttWep = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		new Weapon = TF2_GetClientActiveSlot(attacker);
		if (OverShieldReduction!=Address_Null && fl_CurrentOverShield[victim] > 0.0)
		{
			damage *= Pow(((TF2Attrib_GetValue(OverShieldReduction)+BaseResistance[victim])*(Pow(fl_CurrentOverShield[victim],0.27))*0.32),-0.27);
			if (TF2_IsPlayerInCondition(victim, TFCond_DefenseBuffed))
			{
				damage *= Pow(((TF2Attrib_GetValue(OverShieldReduction)+BaseResistance[victim])*(Pow(fl_CurrentOverShield[victim],0.27))*0.32),-0.33);
			}
		}
		if (fl_CurrentOverShield[victim] > 0.0)
		{
			new particle = CreateEntityByName( "info_particle_system" );
			if ( IsValidEntity( particle ) )
			{
				DispatchKeyValue( particle, "effect_name", "ExplosionCore_sapperdestroyed" );
				TeleportEntity( particle, damagePosition, NULL_VECTOR, NULL_VECTOR );
				DispatchSpawn( particle );
				ActivateEntity( particle );
				AcceptEntityInput( particle, "start" );
				SetVariantString( "OnUser1 !self:Kill::8:-1" );
				AcceptEntityInput( particle, "AddOutput" );
				AcceptEntityInput( particle, "FireUser1" );
			}
			if (IsValidEntity(AttWep))
			{
				new Address:Disruptor = TF2Attrib_GetByName(AttWep, "referenced item id low");
				if (Disruptor != Address_Null)
				{
					damage *= Pow(TF2Attrib_GetValue(Disruptor),0.15)+SquareRoot(fl_CurrentOverShield[victim])/400.0;
				}
			}
		}
		if (SwashBuckler_Active[attacker] == true)
		{
			if (SwashBuckler_MeleeBonus[attacker] == true && Weapon == 2 && IsValidEntity(Weapon))
			{
				damage *= 1.8;
			}
			else if (SwashBuckler_ShotgunBonus[attacker] == true && Weapon == 1 && IsValidEntity(Weapon))
			{
				damage *= 1.5;
			}
		}
	}
	return Plugin_Changed;
}

public Action:Swash_Remove(Handle:timer, any:killer)
{
	if (SwashBuckler_Active[killer] == true)
	{
		SwashBuckler_Active[killer] = false;
	}
	if (SwashBuckler_MeleeBonus[killer] == true)
	{
		SwashBuckler_MeleeBonus[killer] = false;
	}
	if (SwashBuckler_ShotgunBonus[killer] == true)
	{
		SwashBuckler_ShotgunBonus[killer] = false;
	}
}

stock int TF2_GetClientActiveSlot(int client)
{
	return GetWeaponSlot(client, GetActiveWeapon(client));
}

stock int GetWeaponSlot(int client, int weapon)
{
	if (client == 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsValidEntity(weapon))
	{
		return -1;
	}

	for (int i = 0; i < 5; i++)
	{
		if (GetPlayerWeaponSlot(client, i) == weapon)
		{
			return i;
		}
	}

	return -1;
}

stock int GetActiveWeapon(int client)
{
	if (!IsPlayerIndex(client) || !HasEntProp(client, Prop_Send, "m_hActiveWeapon"))
	{
		return 0;
	}

	return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

stock bool IsPlayerIndex(int index)
{
	return index > 0 && index <= MaxClients;
}