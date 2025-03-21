#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <UU_StatusEffects>
#include <UbUp-PowerSupply>
#include <custom_status_hud_Weapons>

#define PLUGIN_VERSION		"1.50"

public Plugin:myinfo =
{
	name		= "Destiny 2 Champions",
	author		= "Recluse",
	description	= "Lol artificial difficulty",
	version		= PLUGIN_VERSION,
};

//Important Variables and stuff

int ChampMod[MAXPLAYERS+1] = {0, ...};

bool ChampStunActive[MAXPLAYERS+1] = {false, ...};

Handle cvar_ChampModClientCheck;

//Overload 

bool Is_Overload[MAXPLAYERS+1] = {false, ...};

bool Overload_Stunned[MAXPLAYERS+1] = {false, ...};

//Unstoppable

bool Is_Unstoppable[MAXPLAYERS+1] = {false, ...};

bool Unstoppable_Stunned[MAXPLAYERS+1] = {false, ...};

//Barrier

bool Is_Barrier[MAXPLAYERS+1] = {false, ...};

bool Barrier_Stunned[MAXPLAYERS+1] = {false, ...};

bool Barrier_ShieldActive[MAXPLAYERS+1] = {false, ...};

bool Barrier_CanUseShield[MAXPLAYERS+1] = {false, ...};

new Float:Barrier_ShieldHealth[MAXPLAYERS+1] = {0.0, ...};

new Float:Barrier_ShieldMaxHealth[MAXPLAYERS+1] = {0.0, ...};

bool Barrier_HealthRegenActive[MAXPLAYERS+1] = {false, ...};



public Action:OnCustomStatusHUDUpdate3(int client, StringMap entries) 
{
	if (IsValidClient(client))
	{
		char stun[32];
		
		if (ChampStunActive[client])
		{
			int cvar = 0
			cvar = GetConVarInt(cvar_ChampModClientCheck);
			
			if (cvar == 1)
			{
				if (ClientAttribCheck(client, "special taunt"))
				{
					Format(stun, sizeof(stun), "Unstoppable Stun Ready");
					entries.SetString("champion_stun", stun);
				}
				if (ClientAttribCheck(client, "revive"))
				{
					Format(stun, sizeof(stun), "Anti-Barrier");
					entries.SetString("champion_stun", stun);
				}
				if (ClientAttribCheck(client, "taunt attack name"))
				{
					Format(stun, sizeof(stun), "Overload Stun Ready");
					entries.SetString("champion_stun", stun);
				}
			}
			else
			{
				new ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				
				if (IsValidEntity(ClientWeapon))
				{
					if (WepAttribCheck(ClientWeapon, "special taunt"))
					{
						Format(stun, sizeof(stun), "Unstoppable Stun Ready");
						entries.SetString("champion_stun", stun);
					}
					if (WepAttribCheck(ClientWeapon, "revive"))
					{
						Format(stun, sizeof(stun), "Anti-Barrier");
						entries.SetString("champion_stun", stun);
					}
					if (WepAttribCheck(ClientWeapon, "taunt attack name"))
					{
						Format(stun, sizeof(stun), "Overload Stun Ready");
						entries.SetString("champion_stun", stun);
					}
				}
			}
		}
	}
	return Plugin_Changed;
}

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	//HookEvent("player_death", Event_Death);
	//HookEvent("player_hurt", Event_Playerhurt);
	cvar_ChampModClientCheck = CreateConVar("sm_champions_ChampModClientCheck", "0", "Enables whether plugin checks for anti-champ mods on clients, auto-disables default check for anti-champ mods on weapons when enabled. Disabled = 0 | Enabled = 1. Default: 0");
	for(new client=0; client<=MaxClients; client++)
	{
		if(!IsValidClient(client)){continue;}
		SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
		ChampStunActive[client] = true;
		CreateTimer(0.1, Timer_HealthRegen, client, TIMER_REPEAT);
	}
}
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client) && IsFakeClient(client))
	{
		new String:clientname[128];
		GetClientName(client, clientname, sizeof(clientname));
		ResetAll(client);
		CreateTimer(0.6, Timer_ChampSetting, client);
		ChampStunActive[client] = true;
		
		if (StrContains(clientname, "OVERLOAD", false) != -1)
		{
			PrintToChatAll("An Overload Champion has appeared!");
			Is_Overload[client] = true;
			Overload_Stunned[client] = false;
			TF2Attrib_SetByName(client, "halloween fire rate bonus", 0.4);
		}
		else if (StrContains(clientname, "BARRIER", false) != -1)
		{
			PrintToChatAll("A Barrier Champion has appeared!");
			Is_Barrier[client] = true;
			Barrier_Stunned[client] = false;
			Barrier_CanUseShield[client] = true;
			Barrier_ShieldActive[client] = false;
			Barrier_ShieldHealth[client] = (TF2_GetMaxHealth(client)*1.5);
			Barrier_ShieldMaxHealth[client] = Barrier_ShieldHealth[client];
		}
		else if (StrContains(clientname, "UNSTOPPABLE", false) != -1)
		{
			PrintToChatAll("An Unstoppable Champion has appeared!");
			Is_Unstoppable[client] = true;
			Unstoppable_Stunned[client] = false;
			TF2Attrib_SetByName(client, "halloween fire rate bonus", 2.5);
		}
	}
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		ChampStunActive[client] = true;
	}
}

public Action:Timer_ChampSetting(Handle:timer, any:client)
{
	if (IsValidClient(client) && IsFakeClient(client))
	{
		if (Is_Unstoppable[client] == true)
		{
			ChampHealthMult(client, 5.0);
			ChampArmorMult(client, 3.0);
		}
		if (Is_Overload[client] == true)
		{
			ChampHealthMult(client, 3.0);
			ChampArmorMult(client, 2.2);
		}
		if (IsChampion(client))
		{
			//fl_CurrentArmor[client] = fl_MaxArmor[client];
		}
	}
}


stock ResetAll( client )
{
	if (IsValidClient(client))
	{
		TF2Attrib_RemoveByName(client, "SET BONUS: max health additive bonus");
		
		Is_Unstoppable[client] = false;
		Unstoppable_Stunned[client] = false;
		
		Is_Barrier[client] = false;
		Barrier_Stunned[client] = false;
		Barrier_ShieldActive[client] = false;
		
		Is_Overload[client] = false;
		Overload_Stunned[client] = false;
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsValidClient(attacker))
	{
		new ClientWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(ClientWeapon))
		{
			if (IsChampion(victim) == true)
			{
				if (damagetype & DMG_CRIT)
				{
					damage /= 3.0;
				}
				
				if (damage >= TF2_GetMaxHealth(victim))
				{
					damage = TF2_GetMaxHealth(victim)*0.70;
				}
			}
			
			if (IsFakeClient(attacker) && !IsFakeClient(victim))
			{
				if (Is_Overload[attacker] == true)
				{
					damage *= 2.5;
				}
				else if (Is_Unstoppable[attacker] == true)
				{
					damage *= 4.0;
				}
				else
				{
					damage *= 1.0;
				}
			}
			if (!IsFakeClient(attacker) && IsFakeClient(victim))
			{
				if (Is_Overload[victim] == true)
				{
					if (Overload_Stunned[victim] == false)
					{
						if (IsValidEntity(ClientWeapon))
						{
							damage *= 0.20;
						}
					}
					if (Overload_Stunned[victim] == true)
					{
						if (IsValidEntity(ClientWeapon))
						{
							damage *= 2.0;
						}
					}
					if (HasAnti_ChampMod(ClientWeapon, attacker) == true)
					{
						StunChamp(attacker, victim);
					}
				}
				else if (Is_Unstoppable[victim] == true)
				{
					if (Unstoppable_Stunned[victim] == false)
					{
						if (IsValidEntity(ClientWeapon))
						{
							damage *= 0.05;
						}
					}
					if (Unstoppable_Stunned[victim] == true)
					{
						if (IsValidEntity(ClientWeapon))
						{
							damage *= 2.5;
						}
					}
					if (HasAnti_ChampMod(ClientWeapon, attacker) == true)
					{
						StunChamp(attacker, victim);
					}
				}
				else if (Is_Barrier[victim] == true)
				{
					if (Barrier_Stunned[victim] == false)
					{
						if (IsValidEntity(ClientWeapon))
						{
							damage *= 0.6;
							
							new clientHealth = GetEntProp(victim, Prop_Data, "m_iHealth");
							
							if (clientHealth <= TF2_GetMaxHealth(victim)*0.85)
							{
								if (Barrier_CanUseShield[victim] == true)
								{
									CreateTimer(13.0, Timer_BarrierShieldReset, victim);
									Barrier_ShieldActive[victim] = true;
									Barrier_CanUseShield[victim] = false;
									SetEntityMoveType(victim, MOVETYPE_NONE);
								}
							}
						}
					}
					if (Barrier_ShieldActive[victim] == true)
					{
						if (IsValidEntity(ClientWeapon))
						{
							if (HasAnti_ChampMod(ClientWeapon, attacker) == true)
							{
								new Float:ShieldDeplete = damage/50.0;
								
								damage *= 0.0;
								
								//new Address:Disruptor = TF2Attrib_GetByName(ClientWeapon, "referenced item id low");
								if (WepAttribCheck(ClientWeapon, "referenced item id low"))
								{
									ShieldDeplete *= (Pow(GetWepAttribValue(ClientWeapon, "referenced item id low"),0.15)+SquareRoot(Barrier_ShieldHealth[victim])/10.0)*2.0;
								}
								else
								{
									ShieldDeplete *= 1.0;
								}
							
								Barrier_ShieldHealth[victim] -= ShieldDeplete;
								
								if (Barrier_ShieldHealth[victim] > 0.0)
								{
									PrintHintText(attacker, "Shield: %.0f/%.0f", Barrier_ShieldHealth[victim], Barrier_ShieldMaxHealth[victim]);
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
								}
								if (Barrier_ShieldHealth[victim] < 0.0)
								{
									StunChamp(attacker, victim);
									CreateTimer(20.0, Timer_BarrierShieldUseReset, victim);
									Barrier_ShieldActive[victim] = false;
									SetEntityMoveType(victim, MOVETYPE_WALK);
								}
							}
							else
							{
								damage *= 0.0;
							}
						}
					}
					if (Barrier_Stunned[victim] == true)
					{
						if (IsValidEntity(ClientWeapon))
						{
							damage *= 1.8;
						}
					}
				}
				else
				{
					damage *= 1.0;
				}
			}
		}
	}
	return Plugin_Changed;
}

public Action:Timer_BarrierShieldUseReset(Handle:Timer, any:victim)
{
	if (IsValidClient(victim))
	{
		if (Barrier_CanUseShield[victim] == false)
		{
			Barrier_CanUseShield[victim] = true;
		}
	}
}

public Action:Timer_BarrierShieldReset(Handle:Timer, any:victim)
{
	if (IsValidClient(victim))
	{
		if (Barrier_ShieldActive[victim] == true)
		{
			Barrier_ShieldActive[victim] = false;
		}
		if (Barrier_CanUseShield[victim] == false)
		{
			Barrier_CanUseShield[victim] = true;
		}
		SetEntityMoveType(victim, MOVETYPE_WALK);
	}
}


public Action:Timer_HealthRegen(Handle:Timer, any:client)
{
	if (IsValidClient(client))
	{
		if (Is_Overload[client] == true)
		{
			if (Overload_Stunned[client] == false)
			{
				PercHealthRegen(client, 0.50);
				ArmorRegenAdd(client, 150.0);
			}
			else
			{
				ArmorRegenAdd(client, 0.0);
			}
		}
		if (Is_Unstoppable[client] == true)
		{
			if (Unstoppable_Stunned[client] == false)
			{
				ArmorRegenAdd(client, 150.0);
			}
			else
			{
				ArmorRegenAdd(client, 0.0);
			}
		}
		if (Is_Barrier[client] == true)
		{
			if (Barrier_HealthRegenActive[client] == true)
			{
				PercHealthRegen(client, 0.30);
				ArmorRegenAdd(client, 25.0);
			}
			else
			{
				ArmorRegenAdd(client, 0.0);
			}
			
			/*
			if (Barrier_ShieldActive[client] == true)
			{
				TF2_AddCondition(client, TFCond_InHealRadius, 1.0);
			}
			*/
		}
		
		if (IsChampion(client))
		{
			if	(Is_Overload[client] == true && Overload_Stunned[client] == false)
			{
				if (Scorch[client] > 150.0)
				{
					Scorch[client] = 150.0;
				}
			}
			if	(Is_Barrier[client] == true && Barrier_Stunned[client] == false)
			{
				if (Scorch[client] > 150.0)
				{
					Scorch[client] = 150.0;
				}
			}
			if	(Is_Unstoppable[client] == true && Unstoppable_Stunned[client] == false)
			{
				if (Scorch[client] > 150.0)
				{
					Scorch[client] = 150.0;
				}
			}
			if (Barrier_ShieldHealth[client] < 0.0)
			{
				Barrier_ShieldHealth[client] = 0.0;
			}
		}
	}
}

stock PercHealthRegen(client, float percent = 0.0)
{
	if (!IsValidClient(client) || percent < 0.0){return;}
	
	if (IsValidClient(client))
	{
		new Float:RegenPerSecond = (TF2_GetMaxHealth(client)*percent);
		new Float:RegenPerTick = RegenPerSecond/10;
			
		new clientHealth = GetEntProp(client, Prop_Data, "m_iHealth");
		new clientMaxHealth = TF2_GetMaxHealth(client);
			
		if(clientHealth < clientMaxHealth)
		{
			if(float(clientHealth) + RegenPerTick < clientMaxHealth)
			{
				SetEntProp(client, Prop_Data, "m_iHealth", clientHealth+RoundToNearest(RegenPerTick));
				TF2_AddCondition(client, TFCond_InHealRadius, 1.0);
			}
			else
			{
				SetEntProp(client, Prop_Data, "m_iHealth", clientMaxHealth);
			}
		}
		
		if (IsChampion(client))
		{
			if	(Is_Overload[client] == true && Overload_Stunned[client] == false)
			{
				fl_CurrentArmor[client] += fl_MaxArmor[client]*0.1;
			}
			if	(Is_Barrier[client] == true && Barrier_Stunned[client] == false)
			{
				fl_CurrentArmor[client] += fl_MaxArmor[client]*0.1;
			}
			if	(Is_Unstoppable[client] == true && Unstoppable_Stunned[client] == false)
			{
				fl_CurrentArmor[client] += fl_MaxArmor[client]*0.1;
			}
		}
	}
}

stock ChampHealthMult(client, float mult = 1.0)
{
	if (!IsValidClient(client) || mult < 0.1){return;}
	
	if (IsValidClient(client))
	{
		new Float:HealthAdd = 0.0;
		if (ClientAttribCheck(client, "max health additive penalty"))
		{
			HealthAdd = (GetClientAttribValue(client, "max health additive penalty")*mult);
		}
		
		TF2Attrib_SetByName(client, "SET BONUS: max health additive bonus", HealthAdd);
	}
}

stock ChampArmorMult(client, float mult = 1.0)
{
	if (!IsValidClient(client) || mult < 0.1){return;}
	
	if (IsValidClient(client))
	{
		new Float:ArmorAdd = 0.0;
		if (ClientAttribCheck(client, "obsolete ammo penalty"))
		{
			ArmorAdd = (GetClientAttribValue(client, "obsolete ammo penalty")*mult);
		}
		
		TF2Attrib_SetByName(client, "noise maker", ArmorAdd);
	}
}

stock ArmorRegenAdd(client, float add = 0.0)
{
	if (!IsValidClient(client) || add < 0.0){return;}
	
	if (IsValidClient(client))
	{
		new Float:OldArmorAdd = 0.0;
		
		if (ClientAttribCheck(client, "armor additional regen"))
		{
			OldArmorAdd = GetClientAttribValue(client, "armor additional regen");
		}
		else
		{
			OldArmorAdd = 0.0;
		}
		
		if (add > 0.0)
		{
			TF2Attrib_SetByName(client, "armor additional regen", OldArmorAdd+add);
		}
		
		else
		{
			TF2Attrib_RemoveByName(client, "armor additional regen");
		}
	}
}

stock bool HasAnti_ChampMod(c_weapon, client)
{
	if (!IsValidClient(client) || !IsValidEntity(c_weapon)){return false;}
	
	ChampMod[client] = 0;
	int cvar = 0
	cvar = GetConVarInt(cvar_ChampModClientCheck);
	
	if (IsValidEntity(c_weapon) && cvar == 0)
	{
		//new Address:Anti_Unstoppable = TF2Attrib_GetByName(c_weapon, "special taunt");
		//new Address:Anti_Barrier = TF2Attrib_GetByName(c_weapon, "revive");
		//new Address:Anti_Overload = TF2Attrib_GetByName(c_weapon, "taunt attack name");
		
		if (WepAttribCheck(c_weapon, "special taunt"))
		{
			ChampMod[client] = 1;
			return true;
		}
		else if (WepAttribCheck(c_weapon, "revive"))
		{
			ChampMod[client] = 2;
			return true;
		}
		else if (WepAttribCheck(c_weapon, "taunt attack name"))
		{
			ChampMod[client] = 3;
			return true;
		}
		else
		{
			ChampMod[client] = 0;
			//PrintToServer("No antichamp mod");
			return false;
		}
	}
	else if (IsValidClient(client) && cvar == 1)
	{
		//new Address:Anti_Unstoppable = TF2Attrib_GetByName(client, "special taunt");
		//new Address:Anti_Barrier = TF2Attrib_GetByName(client, "revive");
		//new Address:Anti_Overload = TF2Attrib_GetByName(client, "taunt attack name");
		
		if (ClientAttribCheck(client, "special taunt"))
		{
			ChampMod[client] = 1;
			return true;
		}
		else if (ClientAttribCheck(client, "revive"))
		{
			ChampMod[client] = 2;
			return true;
		}
		else if (ClientAttribCheck(client, "taunt attack name"))
		{
			ChampMod[client] = 3;
			return true;
		}
		else
		{
			//PrintToServer("No antichamp mod");
			return false;
		}
	}
	else
	{
		//PrintToServer("No antichamp mod");
		return false;
	}
}

stock StunChamp(attacker, victim)
{
	if(!IsValidClient(attacker) || !IsValidClient(victim)){return;}
	
	if (IsValidClient(attacker) && IsValidClient(victim) && CanStun(attacker) == true)
	{
		new ClientWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if (HasAnti_ChampMod(ClientWeapon, attacker) == true)
		{
			if (Is_Overload[victim] == true && Overload_Stunned[victim] == false)
			{
				if (ChampMod[attacker] == 3)
				{
					Overload_Stunned[victim] = true;
					PrintToChatAll("%N Has stunned a Champion!", attacker);
					ChampStun(victim);
				}
			}
			else if (Is_Barrier[victim] == true && Barrier_Stunned[victim] == false)
			{
				if (ChampMod[attacker] == 2)
				{
					Barrier_Stunned[victim] = true;
					PrintToChatAll("%N Has stunned a Champion!", attacker);
					ChampStun(victim);
				}
			}
			else if (Is_Unstoppable[victim] == true && Unstoppable_Stunned[victim] == false)
			{
				if (ChampMod[attacker] == 1)
				{
					Unstoppable_Stunned[victim] = true;
					PrintToChatAll("%N Has stunned a Champion!", attacker);
					ChampStun(victim);
				}
			}
			else
			{
				return;
			}
		}
	}
}

stock bool CanStun( attacker )
{
	if (!IsValidClient(attacker)){return false;}
	
	if (ChampStunActive[attacker] == true)
	{
		ChampStunActive[attacker] = false;
		CreateTimer(10.0, Timer_StunActivate, attacker);
		return true;
	}
	return false;
}

stock ChampStun(client)
{
	if(!IsValidClient(client)){return;}
	
	new StunFlag = TF_STUNFLAGS_NORMALBONK;
	if (IsValidClient(client))
	{
		if (Is_Overload[client] == true)
		{
			TF2_StunPlayer(client, 5.0, 0.0, StunFlag, 0);
			CreateTimer(5.0, Timer_StunClear, client);
			//PrintToServer("stun");
		}
		else if (Is_Barrier[client] == true)
		{
			TF2_StunPlayer(client, 4.0, 0.0, StunFlag, 0);
			CreateTimer(4.0, Timer_StunClear, client);
			//PrintToServer("stun");
		}
		else if (Is_Unstoppable[client] == true)
		{
			TF2_StunPlayer(client, 3.0, 0.0, StunFlag, 0);
			CreateTimer(3.0, Timer_StunClear, client);
			//PrintToServer("stun");
		}
	}
}
	
public Action:Timer_StunClear(Handle:timer, any:client)
{
	if (Is_Overload[client] && Overload_Stunned[client] == true)
	{
		Overload_Stunned[client] = false;
	}
	else if (Is_Barrier[client] && Barrier_Stunned[client] == true)
	{
		Barrier_Stunned[client] = false;
	}
	else if (Is_Unstoppable[client] && Unstoppable_Stunned[client] == true)
	{
		Unstoppable_Stunned[client] = false;
	}
}

public Action:Timer_StunActivate(Handle:timer, any:attacker)
{
	if (IsValidClient(attacker) && ChampStunActive[attacker] == false)
	{
		ChampStunActive[attacker] = true;
		PrintHintText(attacker, "Weapon stun active");
	}
}

/*
stock bool IsValidClient( client, bool replaycheck = true )
{
    if ( client <= 0 || client > MaxClients ) return false; 
    if ( !IsClientInGame( client ) ) return false; 
    if ( !IsPlayerAlive( client ) ) return false; 
    return true; 
}
*/
stock TF2_GetMaxHealth(iClient)
{
    new maxhealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, iClient);
    return ((maxhealth == -1 || maxhealth == 80896) ? GetEntProp(iClient, Prop_Data, "m_iMaxHealth") : maxhealth);
}

stock bool IsChampion(client)
{
	if (!IsValidClient(client)) {return false;}
	
	if (Is_Overload[client] || Is_Barrier[client] || Is_Unstoppable[client] == true) {return true;}
	return false;
}

stock bool ClientAttribCheck(client, const char[] attribname)
{
	if (IsValidClient(client))
	{
		new Address:Attrib = TF2Attrib_GetByName(client, attribname);
		
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

stock float GetClientAttribValue(client, const char[] attribname)
{
	if (IsValidClient(client))
	{
		new Float:AttribValue = 1.0;
		new Address:Attrib = TF2Attrib_GetByName(client, attribname);
		
		if (Attrib != Address_Null)
		{
			AttribValue = TF2Attrib_GetValue(Attrib);
			
			return AttribValue;
		}
		else{return AttribValue;}
	}
	else{return 0.0;}
}

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

stock float GetWepAttribValue(c_weapon, const char[] attribname)
{
	if (IsValidEntity(c_weapon))
	{
		new Float:AttribValue = 1.0;
		new Address:Attrib = TF2Attrib_GetByName(c_weapon, attribname);
		
		if (Attrib != Address_Null)
		{
			AttribValue = TF2Attrib_GetValue(Attrib);
			
			return AttribValue;
		}
		else{return AttribValue;}
	}
	else{return 0.0;}
}
