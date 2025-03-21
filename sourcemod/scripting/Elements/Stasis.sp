
//Floats, bools, and all

Float:Slowed[MAXPLAYERS+1] = {0.0, ...};
Float:SlowedClear_Delay[MAXPLAYERS+1] = {0.0, ...};
bool:SlowClearing[MAXPLAYERS+1] = {false, ...};

Float:Dmg_TilShatter[MAXPLAYERS+1] = {0.0, ...};

bool:Frozen[MAXPLAYERS+1] = {false, ...};
Float:Frozen_Delay[MAXPLAYERS+1] = {0.0, ...};
bool:CanBeFrozen[MAXPLAYERS+1] = {false, ...};

Float:Dmg_VsFrozen[MAXPLAYERS+1] = {0.0, ...};
Float:Dmg_VsFrozenTimer[MAXPLAYERS+1] = {0.0, ...};

Float:Shatter_Radius[MAXPLAYERS+1] = {0.0, ...};
Float:Shatter_Dmg[MAXPLAYERS+1] = {0.0, ...};

//int particle = -1;


new Handle:g_Timer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new Handle:g_Timer1[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
//Handle:Sync_Hud_Stasis[MAXPLAYERS+1];



public Action:OnTakeDamageStasis(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	
	//new killer=GetClientOfUserId(GetEventInt(event, "attacker"));
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new Float:damage = GetEventFloat(event, "damageamount");
	
	if (IsValidClient(attacker) && IsValidClient(victim) && GetClientTeam(victim) != GetClientTeam(attacker))
	{
		new ClientWep = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		//Address StasisWep = TF2Attrib_GetByName(ArcGun, "stasis element");
		
		if (IsValidEntity(ClientWep))
		{
			//Check that the attacker's weapon is Stasis to apply slow effect
			if (WepAttribCheck(ClientWep, "stasis element"))
			{
				if (GetRandomFloat(0.0,1.0) <= (GetWepAttribValue(ClientWep, "stasis element")*0.01))
				{
					if (Slowed[victim] < 100.0 && Frozen[victim] == false)
					{
						SlowClearing[victim] = false;
						
						if (!TF2_IsPlayerInCondition(victim, TFCond_OnFire))
						{
							Slowed[victim] += GetWepAttribValue(ClientWep, "stasis element");
						}
						
						if (TF2_IsPlayerInCondition(victim, TFCond_OnFire))
						{
							Slowed[victim] += (GetWepAttribValue(ClientWep, "stasis element")*0.60);
						}
						
						SlowedClear_Delay[victim] = GetEngineTime()+1.5;
					}
				}
			}
			
			//Freeze victim is slowed stacks is 100
			if (Slowed[victim] == 100.0 && Frozen[victim] == false && CanBeFrozen[victim])
			{
				CreateTimer(0.2, Timer_Freeze, victim)
			}
			
			//Shatter if Frozen victim takes enough damage
			
			if (Frozen[victim] == true && victim != attacker)
			{
				
				//new String:ClientName[64];
				
				Dmg_VsFrozen[victim] += damage;
				
				if (Dmg_VsFrozen[victim] > Dmg_TilShatter[victim])
				{
					Shatter_Dmg[victim] = (Dmg_VsFrozen[victim]*0.40+(TF2_GetMaxHealth(victim)*0.15));
					
					Shatter_Radius[victim] = TF2_GetMaxHealth(victim)*0.25;
					
					new Float:Position[3];
					GetClientEyePosition(victim, Position);
					Position[2] -= 30.0
					
					//CreateParticle(particle, "ExplosionCore_MidAir", Position);
					
					
					
					for ( new i = 1; i <= MaxClients; i++ )
					{
						if(i != attacker && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != GetClientTeam(attacker))
						{
							new Float:Position2[3];
							GetClientEyePosition(i, Position2);
							Position2[2] -= 30.0;
							
							new Float: distance = GetVectorDistance(Position, Position2);
							if (distance <= Shatter_Radius[victim])
							{
								decl Handle:Filter;
								(Filter = INVALID_HANDLE);
								
								Frozen[victim] = false;
								Dmg_VsFrozen[victim] = 0.0;
								SetEntityRenderColor(victim, 255, 255, 255, 0);
								Explode(attacker, victim, i, ClientWep, Shatter_Radius[victim], (Shatter_Dmg[victim]), Filter);
								Frozen_Delay[victim] = GetEngineTime()+3.0;
								CanBeFrozen[victim] = false;
								PrintToConsole(attacker, "Shatter Damage: %.0f", Shatter_Dmg[victim]);
							}
						}
					}
				}
			}
		}
	}
}


public Action:Timer_DMGvsFrozenClear(Handle:Timer, any:victim)
{
	if (IsValidClient(victim))
	{
		if (Dmg_VsFrozen[victim] > 0.0)
		{
			Dmg_VsFrozen[victim] = 0.0;
		}
	}
}


public Action:Timer_Freeze(Handle:Timer, any:victim)
{
	if (IsValidClient(victim))
	{
		Frozen[victim] = true;
		Dmg_TilShatter[victim] = (TF2_GetMaxHealth(victim)*0.70);
		Dmg_VsFrozenTimer[victim] = 2.0;
		g_Timer1[victim] = CreateTimer(Dmg_VsFrozenTimer[victim], Timer_DMGvsFrozenClear, victim);
		
		Slowed[victim] = 0.0;
		
		SetEntityMoveType(victim, MOVETYPE_NONE);
		SetVariantInt(1);
		AcceptEntityInput(victim, "SetForcedTauntCam");
		
		//Set Player Color to Blue to indicate being frozen
		SetEntityRenderColor(victim, 0, 0, 255);
		
		//EmitSoundFromOrigin(const String:sound[],const Float:orig[3])
		
		CreateTimer(4.0, Timer_FreezeClear);
	}
}


public Action:Timer_FreezeClear(Handle:Timer)
{
	for ( new victim = 1; victim <= MaxClients; victim++ )
	{
		if (IsValidClient(victim))
		{
			if (Frozen[victim] == true)
			{
				Frozen[victim] = false;
				
				Dmg_VsFrozen[victim] = 0.0;
				SetEntityMoveType(victim, MOVETYPE_WALK);
				SetVariantInt(0);
				AcceptEntityInput(victim, "SetForcedTauntCam");
				
				
				//Set player color to default when frozen duration is done
				SetEntityRenderColor(victim, 255, 255, 255, 0);
				
			}
		}
	}
}

/*
public Action:Timer_SlowedClear(Handle:Timer, any:client)
{
	if (IsValidClient(client))
	{
		if (SlowClearing[client] == false)
		{
			SlowClearing[client] = true;
		}
	}
}
*/

public Action:Timer_StackClear(Handle:Timer)
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			if (SlowClearing[client] == true)
			{
				if (Slowed[client] > 0.0)
				{
					Slowed[client] -= 3.0
				}
				
				if (Slowed[client] == 0.0)
				{
					SlowClearing[client] = false;
				}
			}
		}
	}
}

//Apply slow effect based on current slowed stacks
public Action:Timer_Slow(Handle:Timer)
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			//replace slow on hit with stasis
			new clientweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (IsValidEntity(clientweapon))
			{
				if(WepAttribCheck(clientweapon, "slow enemy on hit"))
				{
					TF2Attrib_RemoveByName(clientweapon, "slow enemy on hit");
					TF2Attrib_SetByName(clientweapon, "stasis element", 15.0);
				}
				if (WepAttribCheck(clientweapon, "slow enemy on hit major"))
				{
					TF2Attrib_RemoveByName(clientweapon, "slow enemy on hit major");
					TF2Attrib_SetByName(clientweapon, "stasis element", 15.0);
				}
			}
			
			if (Slowed[client] > 0.0)
			{
				//Apply move speed penalty based on the amount of slow they have
				TF2Attrib_SetByName(client, "major move speed bonus", Pow(Slowed[client], -0.17));
				AttachParticle(client, "xms_icicle_melt", 0.5);
				
				
				
			}
			if (Slowed[client] == 0.0)
			{
				TF2Attrib_RemoveByName(client, "major move speed bonus");
			}
			
			if (Frozen[client] == true)
			{
				//SetHudTextParams(0.48, 0.55, 1.2, 0, 255, 0, 255, 0, 0.0, 0.0, 0.0);
				//ShowSyncHudText(client, Sync_Hud_Stasis[client], "Frozen");
			}
			
			if (Slowed[client] < 0.0)
			{
				Slowed[client] = 0.0;
			}
			if (Slowed[client] > 100.0)
			{
				Slowed[client] = 100.0
			}
		}
	}
}
