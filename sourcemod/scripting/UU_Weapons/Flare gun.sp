Float:Chain_Chance[MAXPLAYERS+1] = {0.05, ...};

bool:ExplosionReady[MAXPLAYERS+1] = {false, ...};

Handle:clientTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

Float:Chain_Reset[MAXPLAYERS+1] = {0.0, ...};

int particlefg = -1;


public Action:OnTakeDamageFlareGun(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsValidClient(attacker) && IsValidClient(victim))
	{
		if (victim != attacker)
		{
			new victimweapon = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
			new attackerweapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			
			if (IsValidEntity(victimweapon))
			{
				if(WepAttribCheck(victimweapon, "flare gun extreme"))
				{
					if (ExplosionReady[victim] == true)
					{
						if (IsValidEntity(attackerweapon))
						{
							if(WepAttribCheck(attackerweapon, "throwable particle trail only"))
							{
							
								new Float:Pos1[3];
								GetClientEyePosition(victim, Pos1);
								Pos1[2] -= 30.0;
								
								particlefg = CreateEntityByName( "info_particle_system" );
								if ( IsValidEdict( particlefg ) )
								{
									TeleportEntity( particlefg, Pos1, NULL_VECTOR, NULL_VECTOR );
									DispatchKeyValue( particlefg, "effect_name", "ExplosionCore_MidAir" );
									DispatchSpawn( particlefg );
									ActivateEntity( particlefg );
									AcceptEntityInput( particlefg, "start" );
									SetVariantString( "OnUser1 !self:Kill::8:-1" );
									AcceptEntityInput( particlefg, "AddOutput" );
									AcceptEntityInput( particlefg, "FireUser1" );
								}
								
								for ( new i = 1; i <= MaxClients; i++ )
								{
									
									if(i != victim && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != GetClientTeam(victim))
									{
										new Float:Pos2[3];
										GetClientEyePosition(i, Pos2);
										Pos2[2] -= 30.0;
										
										new Float: distance = GetVectorDistance(Pos1, Pos2);
										if (distance <= 500.0)
										{
											decl Handle:Filter;
											(Filter = INVALID_HANDLE);
											
											Filter = TR_TraceRayFilterEx(Pos1, Pos2, MASK_SOLID, RayType_EndPoint, TraceEntityFilterPlayer, i);
											if (Filter != INVALID_HANDLE)
											{
												if (!TR_DidHit(Filter))
												{
													SDKHooks_TakeDamage(i, victim, victim, (damage*0.45+(distance*0.30)), DMG_BLAST, -1, NULL_VECTOR, NULL_VECTOR, true);
													if (ExplosionReady[victim] == true)
													{
														ExplosionReady[victim] = false;
														clientTimer[victim] = CreateTimer(5.0, Timer_ExplosionReset, victim);
														
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
			
			if (IsValidEntity(attackerweapon))
			{
				if(WepAttribCheck(attackerweapon, "flare gun extreme"))
				{
					if(TF2_IsPlayerInCondition(victim, TFCond_OnFire))
					{
						TF2Attrib_SetByName(attackerweapon, "throwable particle trail only", (Chain_Chance[attacker]+0.25))
					}
				}
			}
		}
	}
	return Plugin_Changed;
}

public Action:Timer_ExplosionReset(Handle:ExploTimer, any:victim)
{
	if (IsValidClient(victim))
	{
		if (ExplosionReady[victim] == false)
		{
			ExplosionReady[victim] = true;
		}
	}
}