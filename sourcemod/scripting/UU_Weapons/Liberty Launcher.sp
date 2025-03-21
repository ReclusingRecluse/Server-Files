new Float:Radius[MAXPLAYERS+1] = {0.0, ...};

new Float:Hits[MAXPLAYERS+1] = {0.0, ...};

stock LLDealDamage(client)
{
	if (IsValidClient(client))
	{
		new clientweapon = GetPlayerWeaponSlot(client,0);
		
		if (IsValidEntity(clientweapon))
		{
			if (WepAttribCheck(clientweapon, "solar flare"))
			{
				//Handle Proj damage Radius
				//new Float:Damage;
				int ent = -1;
				while((ent = FindEntityByClassname(ent, "tf_projectile_rocket")) != INVALID_ENT_REFERENCE)
				{
					//PrintToChat(client, "Rocket %i", ent);
					new Float:Pos3[3];
					int owner = GetEntPropEnt( ent, Prop_Data, "m_hOwnerEntity" );
					GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", Pos3);
					if (!IsValidEntity(owner)) continue; 
					if (owner == client)
					{
					
						for(new i = 1; i < MaxClients; i++)
						{
							if(IsValidClient(i) && IsPlayerAlive(client) && GetClientTeam(client) != GetClientTeam(i))
							{
								new Float:Pos4[3];
								GetClientEyePosition(i, Pos4);
								Pos4[2] -= 30.0;
								new Float:Distance = GetVectorDistance(Pos3, Pos4);
									
								if (Distance <= Radius[client])
								{
									decl Handle:Filter2;
									(Filter2 = INVALID_HANDLE);
					
									Filter2 = TR_TraceRayFilterEx(Pos3, Pos4, MASK_SOLID, RayType_EndPoint, TraceFilterIgnoreSelf, ent);
									if (Filter2 != INVALID_HANDLE)
									{
										if (!TR_DidHit(Filter2))
										{
											if (IsValidTarget(i, client))
											{
												//PrintToChat(client, "Ray Hit");
												
												CreateBulletTrace(Pos3, Pos4, 2000.0, 15.0, 5.0, "255 180 0");
												AttachParticle(ent, "flamethrower", 0.1);
												Hits[i] += 2.0;
												new Float:Damage = 1.0*(Hits[i]*1.30);
												SDKHooks_TakeDamage(i, clientweapon, client, Damage, DMG_BLAST, clientweapon, NULL_VECTOR, NULL_VECTOR, false);
												TF2Util_IgnitePlayer(i, client, 5.0, clientweapon);
											}
										}
										if (TR_DidHit(Filter2))
										{
											Hits[i] = 0.0;
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

stock RadiusCalc(client)
{
	if (IsValidClient(client))
	{
		new clientweapon = GetPlayerWeaponSlot(client,0);
		
		if (IsValidEntity(clientweapon))
		{
			if (WepAttribCheck(clientweapon, "solar flare"))
			{
				if (WepAttribCheck(clientweapon, "Blast radius increased custom"))
				{
					Radius[client] = 270.0*(GetWepAttribValue(clientweapon, "Blast radius increased custom")*0.80);
				}
				else
				{
					return;
				}
			}
		}
	}
}