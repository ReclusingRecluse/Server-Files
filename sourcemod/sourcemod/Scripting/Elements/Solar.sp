

new bool:Explosion_Delay[MAXPLAYERS+1] = {false, ...};

new bool:Ignition_active[MAXPLAYERS+1] = {false, ...};
new bool:Ignition_activator[MAXPLAYERS+1] = {false, ...};

new Float:Scorch_max[MAXPLAYERS+1] = {400.0, ...};

int particle = -1;

#define SOUND_EXPLO	"weapons/explode1.wav"

#define SOUND_PERF	"weapons/dragons_fury_impact_bonus_damage.wav"

public Action:Timer_Degen(Handle:Timer)
{
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if (IsValidClient(i))
		{
			if (Scorch[i] > 0.0)
			{
				/*
				decl String:ShieldLeft[128];
				Format(ShieldLeft, sizeof(ShieldLeft), "Scorched %.0f", Scorch[i]); 
				SetHudTextParams(-0.65, -0.4, 1.2, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(i, -1, ShieldLeft);
				*/
				
				if (Scorch[i] == 0.0)
				{
					KillTimer(Timer);
				}
			}
			if (Scorch[i] < 0.0)
			{
				Scorch[i] = 0.0;
			}
		}
	}
}

public Action:Timer_Thing(Handle:Timer)
{
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if (IsValidClient(i))
		{
			if (Scorch[i] > Scorch_max[i])
			{
				Scorch[i] = Scorch_max[i];
			}
			if (Scorch[i] > 0.0)
			{
				Scorch[i] -= 9.0;
			}
		}
	}
}

public Event_PlayerreSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client))
	{
		Scorch[client] = 0.0;
		Scorch_max[client] = 400.0;
		Explosion_Delay[client] = false;
		Ignition_active[client] = false;
	}
}

public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer=GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim=GetClientOfUserId(GetEventInt(event, "userid"));
	new Float:damage = GetEventFloat(event, "damageamount");
	if (victim != killer && IsValidClient(killer))
	{
		new killerwep = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(killerwep))
		{
			new type = GetEventInt(event, "customkill");
			if (type == 1)
			{
				new Address:FireFly = TF2Attrib_GetByName(killerwep, "firefly");
				if(FireFly!=Address_Null && Explosion_Delay[killer] == false)
				{
					new Float:Radius = (TF2Attrib_GetValue(FireFly)*1.3);
					new Float:fl_damage = (TF2Attrib_GetValue(FireFly)/3.9);
					new Float:Pos1[3];
					GetClientEyePosition(victim, Pos1);
					Pos1[2] -= 30.0;
					
					particle = CreateEntityByName( "info_particle_system" );
					if ( IsValidEdict( particle ) )
					{
						TeleportEntity( particle, Pos1, NULL_VECTOR, NULL_VECTOR );
						DispatchKeyValue( particle, "effect_name", "ExplosionCore_MidAir" );
						DispatchSpawn( particle );
						ActivateEntity( particle );
						AcceptEntityInput( particle, "start" );
						SetVariantString( "OnUser1 !self:Kill::8:-1" );
						AcceptEntityInput( particle, "AddOutput" );
						AcceptEntityInput( particle, "FireUser1" );
					}
					
					for ( new i = 1; i <= MaxClients; i++ )
					{
						EmitSoundFromOrigin(SOUND_EXPLO, Pos1);
						if(i != killer && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != GetClientTeam(killer))
						{
							new Float:Pos2[3];
							GetClientEyePosition(i, Pos2);
							Pos2[2] -= 30.0;
							
							new Float: distance = GetVectorDistance(Pos1, Pos2);
							if (distance <= Radius)
							{
								decl Handle:Filter;
								(Filter = INVALID_HANDLE);
								
								Filter = TR_TraceRayFilterEx(Pos1, Pos2, MASK_SOLID, RayType_EndPoint, TraceEntityFilterPlayer, i);
								if (Filter != INVALID_HANDLE)
								{
									if (!TR_DidHit(Filter) && i != victim)
									{
										Explosion_Delay[killer] = true;
										//DealDamage(i, RoundToFloor(fl_damage), killer, DMG_BLAST ,"pumpkindeath");
										SDKHooks_TakeDamage(i, killer, killer, fl_damage+damage*0.45, DMG_BLAST, -1, NULL_VECTOR, NULL_VECTOR, true);
										TF2Util_IgnitePlayer(i, killer, 7.0, killerwep);
										CreateTimer(1.5, ExplosionDelay);
									}
								}
								CloseHandle(Filter);
							}
						}
					}
				}
			}
			new Address:Incandescent = TF2Attrib_GetByName(killerwep, "incandescent");
			if (Incandescent!=Address_Null && Explosion_Delay[killer] == false)
			{
				new Float:Radius = (TF2Attrib_GetValue(Incandescent)*2.1);
				new Float:fl_damage2 = 85.0;
				new Float:Pos1[3];
				GetClientEyePosition(victim, Pos1);
				Pos1[2] -= 30.0;
					
				particle = CreateEntityByName( "info_particle_system" );
				if ( IsValidEdict( particle ) )
				{
					TeleportEntity( particle, Pos1, NULL_VECTOR, NULL_VECTOR );
					DispatchKeyValue( particle, "effect_name", "ExplosionCore_MidAir" );
					DispatchSpawn( particle );
					ActivateEntity( particle );
					AcceptEntityInput( particle, "start" );
					SetVariantString( "OnUser1 !self:Kill::8:-1" );
					AcceptEntityInput( particle, "AddOutput" );
					AcceptEntityInput( particle, "FireUser1" );
				}
					
				for ( new i2 = 1; i2 <= MaxClients; i2++ )
				{
					EmitSoundFromOrigin(SOUND_EXPLO, Pos1);
					if(i2 != killer && i2 != victim && IsClientInGame(i2) && IsPlayerAlive(i2) && GetClientTeam(i2) != GetClientTeam(killer))
					{
						new Float:Pos2[3];
						GetClientEyePosition(i2, Pos2);
						Pos2[2] -= 30.0;
							
						new Float: distance = GetVectorDistance(Pos1, Pos2);
						if (distance <= Radius)
						{
							decl Handle:Filter2;
							(Filter2 = INVALID_HANDLE);
								
							Filter2 = TR_TraceRayFilterEx(Pos1, Pos2, MASK_SOLID, RayType_EndPoint, TraceEntityFilterPlayer, i2);
							if (Filter2 != INVALID_HANDLE)
							{
								if (!TR_DidHit(Filter2))
								{
									if (IsPlayerAlive(i2) && IsValidClient(i2) && i2 != victim)
									{
										Explosion_Delay[killer] = true;
										new Float:Dmg2 = TF2_GetMaxHealth(i2)*0.3+(Scorch[i2]);
										//DealDamage(i2, RoundToFloor(fl_damage2), killer, DMG_BLAST ,"pumpkindeath");
										SDKHooks_TakeDamage(i2, killer, killer, ((fl_damage2+Dmg2*0.5)+damage*0.20), DMG_BLAST, -1, NULL_VECTOR, NULL_VECTOR, true);
										TF2Util_IgnitePlayer(i2, killer, 7.0, killerwep);
										Scorch[i2] += 80.0;
										Scorch[victim] = 0.0;
										CreateTimer(1.5, ExplosionDelay);
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


public Action:OnTakeDamage2(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsValidClient(attacker))
	{
		new secondary=GetPlayerWeaponSlot(attacker,1);
		new attackerwep = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		//int victimclass = TF2_GetPlayerClass(victim);
		if (IsValidEntity(attackerwep))
		{
			new Address:Causality = TF2Attrib_GetByName(attackerwep, "causality arrows");
			new String:classname[128]; 
			GetEdictClassname(inflictor, classname, sizeof(classname));
			if (Causality!=Address_Null && Scorch[victim] > 55.0)
			{
				if(!strcmp("tf_projectile_arrow", classname))
				{
					damage *= 0.15;
					new Float:Radius = (TF2Attrib_GetValue(Causality)*2.1);
					new Float:fl_damage4 = (TF2Attrib_GetValue(Causality)/6.5);
					new Float:Pos1[3];
					GetClientEyePosition(victim, Pos1);
					Pos1[2] -= 30.0;
					
					particle = CreateEntityByName( "info_particle_system" );
					if ( IsValidEdict( particle ) )
					{
						TeleportEntity( particle, Pos1, NULL_VECTOR, NULL_VECTOR );
						DispatchKeyValue( particle, "effect_name", "gas_can_impact_red" );
						DispatchSpawn( particle );
						ActivateEntity( particle );
						AcceptEntityInput( particle, "start" );
						SetVariantString( "OnUser1 !self:Kill::8:-1" );
						AcceptEntityInput( particle, "AddOutput" );
						AcceptEntityInput( particle, "FireUser1" );
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
										DealDamage(i3, RoundToFloor(fl_damage4 + damage*0.30), attacker, DMG_BLAST ,"pumpkindeath");
										TF2Util_IgnitePlayer(i3, attacker, 10.0, attackerwep);
										Scorch[victim] -= 15.0;
										Scorch[i3] += 20.0;
									}
								}
								CloseHandle(Filter2);
							}
						}
					}
				}
			}
			if (TF2_IsPlayerInCondition(victim, TFCond_OnFire) && damagetype & DMG_BURN)
			{
				if (IsFakeClient(victim))
				{
					damage *= 0.40;
				}
				if (!IsFakeClient(victim))
				{
					damage *= 0.5;
				}
				new Address:Scorchonhit = TF2Attrib_GetByName(attackerwep, "scorch");
				if (Scorchonhit != Address_Null)
				{
					if (damage > 0.0)
					{
						new Float:Amount = TF2Attrib_GetValue(Scorchonhit);
						Scorch[victim] += Amount;
					}
				}
				else
				{
					if (damage > 0.0)
					{
						Scorch[victim] += 12.0;
					}
				}
			}
			
			if (TF2_GetPlayerClass(victim) == TFClass_Pyro)
			{
				new Address:Scorchonhit = TF2Attrib_GetByName(attackerwep, "scorch");
				if (Scorchonhit != Address_Null)
				{
					if (damage > 0.0)
					{
						new Float:Amount = TF2Attrib_GetValue(Scorchonhit);
						Scorch[victim] += Amount*0.40;
					}
				}
			}
			
			if (TF2_IsPlayerInCondition(victim, TFCond_Gas))
			{
				new Address:gasexplosion = TF2Attrib_GetByName(secondary, "explode_on_ignite");
				
				if (gasexplosion != Address_Null)
				{
					if (damage > 0.0)
					{
						Scorch[victim] += 200.0;
					}
				}
				else
				{
					if (damage > 0.0)
					{
						Scorch[victim] += 0.0;
					}
				}
			}
			if (damagetype & DMG_BURN && Scorch[victim] > 0.0)
			{
				damage *= Pow(Scorch[victim], 0.18)*0.7;
			}
			new Address:Scorchmultdmg = TF2Attrib_GetByName(attackerwep, "recipe component defined item 7");
			if (Scorchmultdmg!=Address_Null)
			{
				if (Scorch[victim] > 0.0)
				{
					damage *= (Pow(Scorch[victim], 0.2)*0.8)*1.75;
				}
			}
			if (Scorch[victim] >= 350.0 && Ignition_active[victim] == false && damage > 0.0)
			{
				new Float:Pos1[3];
				GetClientEyePosition(victim, Pos1);
				Pos1[2] -= 30.0;
				
				CreateTimer(0.8, Timer_Explosion, victim);
				CreateTimer(4.0, Timer_IgnitionReset1);
				EmitSoundFromOrigin(SOUND_PERF, Pos1);
				
				particle = CreateEntityByName( "info_particle_system" );
				if ( IsValidEdict( particle ) )
				{
					TeleportEntity( particle, Pos1, NULL_VECTOR, NULL_VECTOR );
					DispatchKeyValue( particle, "effect_name", "dragons_fury_effect_parent" );
					DispatchSpawn( particle );
					ActivateEntity( particle );
					AcceptEntityInput( particle, "start" );
					SetVariantString( "OnUser1 !self:Kill::8:-1" );
					AcceptEntityInput( particle, "AddOutput" );
					AcceptEntityInput( particle, "FireUser1" );
				}
				Ignition_active[victim] = true;
				Ignition_activator[attacker] = true;
			}
		}
	}
	return Plugin_Changed;
}

public Action:Timer_Explosion(Handle:timer, any:victim)
{
	if (IsValidClient(victim) && Ignition_active[victim] == true)
	{
		new Float:Pos1[3];
		GetClientEyePosition(victim, Pos1);
		Pos1[2] -= 30.0;
		new Float:Radius = 700.0;
		
		//CreateParticle(-1, "ExplosionCore_MidAir", true, "", Pos1);
		
		particle = CreateEntityByName( "info_particle_system" );
		if ( IsValidEdict( particle ) )
		{
			TeleportEntity( particle, Pos1, NULL_VECTOR, NULL_VECTOR );
			DispatchKeyValue( particle, "effect_name", "ExplosionCore_MidAir" );
			DispatchSpawn( particle );
			ActivateEntity( particle );
			AcceptEntityInput( particle, "start" );
			SetVariantString( "OnUser1 !self:Kill::8:-1" );
			AcceptEntityInput( particle, "AddOutput" );
			AcceptEntityInput( particle, "FireUser1" );
		}
		
		for ( new i2 = 1; i2 <= MaxClients; i2++ )
		{
			EmitSoundFromOrigin(SOUND_EXPLO, Pos1);
			if(IsClientInGame(i2) && IsPlayerAlive(i2) && GetClientTeam(i2) == GetClientTeam(victim))
			{
				new Float:Pos2[3];
				GetClientEyePosition(i2, Pos2);
				Pos2[2] -= 30.0;
							
				new Float: distance = GetVectorDistance(Pos1, Pos2);
				if (distance <= Radius)
				{
					decl Handle:Filter;
					(Filter = INVALID_HANDLE);
								
					Filter = TR_TraceRayFilterEx(Pos1, Pos2, MASK_SOLID, RayType_EndPoint, TraceEntityFilterPlayer, i2);
					if (Filter != INVALID_HANDLE)
					{
						if (!TR_DidHit(Filter))
						{
							for ( new i3 = 1; i3 <= MaxClients; i3++ )
							{
								if (IsValidClient(i3) && Ignition_activator[i3] == true)
								{
									new attackerwep = GetEntPropEnt(i3, Prop_Send, "m_hActiveWeapon");
									
									if (IsValidEntity(attackerwep))
									{
										new Float:fl_damage = (TF2_GetMaxHealth(victim)*0.17)*(Scorch[victim]*Pow(0.3, 4.0))*0.80;
										if (WepAttribCheck(attackerwep, "weapon burn dmg increased"))
										{
											fl_damage *= GetWepAttribValue(attackerwep, "weapon burn dmg increased")*0.70;
										}
										
										//DealDamage(i, RoundToFloor(fl_damage), killer, DMG_BLAST ,"pumpkindeath");
										SDKHooks_TakeDamage(i2, i3, i3, fl_damage*0.80, DMG_BURN, attackerwep, NULL_VECTOR, NULL_VECTOR, true);
										TF2Util_IgnitePlayer(i2, i3, 7.0, attackerwep);
										Scorch[victim]*= 0.10;
										Scorch[i2] += Scorch[victim]*0.70;
									}
								}
							}
						}
					}
					CloseHandle(Filter);
				}
			}
		}
	}
}

public Action:Timer_IgnitionReset1(Handle:timer)
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			if (Ignition_activator[client] == true)
			{
				Ignition_activator[client] = false;
			}
			if (Ignition_active[client] == true)
			{
				Ignition_active[client] = false;
			}
		}
	}
}

public Action:ExplosionDelay(Handle:timer)
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (Explosion_Delay[client] == true)
		{
			Explosion_Delay[client] = false;
		}
	}
}


