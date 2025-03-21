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
			//Solar
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
			
			//Strand
			
			if (WepAttribCheck(killerwep, "unraveling rounds"))
			{
				if (KillStacks[killer] < 3)
				{
					Killstacks_Duration[killer] = GetEngineTime()+3.5;
					KillStacks[killer] += 1;
				}
				
				if (KillStacks[killer] >= 3)
				{
					Unraveling_Rounds_Active[killer] = true;
					Killstacks_Duration[killer] = 0.0;
					Unraveling_Rounds_Duration[killer] = GetEngineTime()+7.5;
					
					if (Unraveling_Rounds_Stacks[killer] < 3.0)
					{	
						Unraveling_Rounds_Stacks[killer] += 1.0;
					}
				}
			}
		}
	}
}