

public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsValidClient(attacker) && IsValidClient(victim) && victim != attacker)
	{
		new clientweapon =  weapon;
		
		if (IsValidEntity(clientweapon))
		{	
		
			//Thunderlord, Abbadon, Nova Mortis
			if (WepAttribCheck(clientweapon, "buff weapon on consect hits"))
			{
				if (HitCounter[attacker] < 30)
				{
					HitCounter[attacker] += 1;
				}
				if (HitCounter[attacker] == 30)
				{
					HitBonusActive[attacker] = true;
					CreateTimer(5.0, Timer_HitBonus, attacker);
				}
				if (HitBonusActive[attacker])
				{
					if (HitBonusExplo_Counter[attacker] < 5)
					{
						HitBonusExplo_Counter[attacker] += 1;
					}
				}
				
				if (HitBonusActive[attacker])
				{
					damage *= 1.30;
					
					if (WepAttribCheck(clientweapon, "thunderlord"))
					{
						for ( new client = 1; client <= MaxClients; client++ )
						{
							if (IsValidClient(client) && client != attacker)
							{
								if (GetClientTeam(client) == GetClientTeam(victim))
								{
									new Handle:Tray = INVALID_HANDLE;
									
									if (Tray == INVALID_HANDLE && damagetype & DMG_BULLET && HitBonusExplo_Counter[attacker] == 5)
									{
										Explode(attacker, victim, client, clientweapon, 450.0, (120.0+damage*0.40), Tray);
										HitBonusExplo_Counter[attacker] = 0;
									}
								}
							}
						}
					}
					
					if (WepAttribCheck(clientweapon, "abbadon"))
					{
						new Float:Pos1[3];
						GetClientEyePosition(victim, Pos1);
						Pos1[2] -= 30.0;
						
						for ( new client = 1; client <= MaxClients; client++ )
						{
							if (IsValidClient(client) && client != attacker)
							{
								if (GetClientTeam(client) == GetClientTeam(victim))
								{
									new Float:Pos2[3];
									GetClientEyePosition(client, Pos2);
									Pos2[2] -= 30.0;
									
									new Float: distance = GetVectorDistance(Pos1, Pos2);
									if (distance <= 400.0)
									{
										new Handle:Tray = INVALID_HANDLE;
									
										if (Tray == INVALID_HANDLE && damagetype & DMG_BULLET && HitBonusExplo_Counter[attacker] == 5)
										{
											Tray = TR_TraceRayFilterEx(Pos1, Pos2, MASK_SOLID, RayType_EndPoint, TraceEntityFilterPlayer, client);
											if (!TR_DidHit(Tray) && IsValidTarget(client, attacker))
											{
												CreateBulletTrace(Pos1, Pos2, 2000.0, 15.0, 5.0, "255 180 0");
												Scorch[client] += 80.0;
												TF2Util_IgnitePlayer(client, attacker, 7.0, clientweapon);
											}
											CloseHandle(Tray);
										}
									}
								}
							}
						}
					}
				}
				
				//Cow Mangler
				if(WepAttribCheck(clientweapon, "void mangler"))
				{
					damage *= (Fire_rate_to_damage[attacker]*2.0)-1.0;
					if (Siphoned_Health[attacker] > 1.0)
					{
						damage *= ((Pow(Siphoned_Health[attacker], 0.15))*(Pow(Siphoned_Health[attacker], 0.07)))*0.30;
					}
				}
				
				//Direct Hit
				
				if (WepAttribCheck(clientweapon, "fuller court"))
				{
					//decl Float:fAngles[3], Float:fVelocity[3], Float:fOrigin[3], Float:vBuffer[3];
					
					new Float:Pos3[3];
					Pos3[2] -= 30.0;
					int ent = -1;
					while((ent = FindEntityByClassname(ent, "tf_projectile_rocket")) != -1) 
					{
						int owner = GetEntPropEnt( ent, Prop_Data, "m_hOwnerEntity" );
						
						if (!IsValidEntity(owner)) continue; 
						if (owner == attacker)
						{
							GetEntPropVector(ent, Prop_Data, "m_vecOrigin", Pos3);
							
							new Float:Pos4[3];
							GetClientEyePosition(attacker, Pos4);
							Pos4[2] -= 30.0;
							new Float:Distance = GetVectorDistance(Pos3, Pos4);
							
							new Float:DamageMult =  1.0;
							
							DamageMult = (Distance*Pow(0.01,1.32))*0.5;
							
							if (DamageMult > 1.0)
							{
								damage *= DamageMult;
								//PrintToChat(attacker, "Projectile distance %.0f\nProjectile Damage Bonus %.2f", Distance, DamageMult);
							}
						}
					}
				}
				
				
				if (Is_Amplified[attacker])
				{
					damage *= 1.30;
				}
				
				//Fire Rate To Damage Conversion
				if(WepAttribCheck(clientweapon, "fire rate to damage"))
				{
					if (!(damagetype & DMG_SHOCK))
					{
						FireRateToDamage(attacker, clientweapon);
						damage *= ((Fire_rate_to_damage[attacker]*2.0)-1.0)*2.0;
					}
				}
				
				//Flare Gun
				
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
	}
	return Plugin_Changed;
}
