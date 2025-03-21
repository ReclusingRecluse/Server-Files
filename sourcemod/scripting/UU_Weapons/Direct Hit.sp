
Float:Amplified_Timer[MAXPLAYERS+1] = {0.0, ...};

bool:Is_Amplified[MAXPLAYERS+1] = {false, ...};

Handle:g_Timer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

stock SpeedCalc(client)
{
	if (IsValidClient(client))
	{
		new clientweapon = GetPlayerWeaponSlot(client,0);
		
		if (IsValidEntity(clientweapon))
		{
			if (WepAttribCheck(clientweapon, "fuller court"))
			{
				decl Float:fAngles[3], Float:fVelocity[3], Float:vBuffer[3];
				
				new Float:Pos3[3];
				Pos3[2] -= 30.0;
				int ent = -1;
				while((ent = FindEntityByClassname(ent, "tf_projectile_rocket")) != -1) 
				{
					int owner = GetEntPropEnt( ent, Prop_Data, "m_hOwnerEntity" );
					
					if (!IsValidEntity(owner)) continue; 
					if (owner == client)
					{
						GetEntPropVector(ent, Prop_Data, "m_vecOrigin", Pos3);
						GetEntPropVector(ent, Prop_Data, "m_angRotation", fAngles);
						
						GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
						
						new Float:Speed = 2500.0;
						
						new Float:Pos4[3];
						GetClientEyePosition(client, Pos4);
						Pos4[2] -= 30.0;
						new Float:Distance = GetVectorDistance(Pos3, Pos4);
						
						
						if (Distance > 100.0)
						{
							Speed *= (Distance*Pow(0.01,1.32));
							
							
							//PrintToChat(client, "Projectile distance %.0f\nProjectile Speed bonus %.0f", Distance, Speed);
							
							fVelocity[0] = vBuffer[0]*Speed;
							fVelocity[1] = vBuffer[1]*Speed;
							fVelocity[2] = vBuffer[2]*Speed;
							
							TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, fVelocity);
						}
					}
				}
				
				
				new Float:ChainDamageOld = 0.30;
				
				if (Is_Amplified[client])
				{
					TF2Attrib_SetByName(clientweapon, "mult_player_movespeed_active", 1.50);
					
					
					TF2Attrib_SetByName(clientweapon, "throwable particle trail only", (ChainDamageOld+0.15));
				}
				
				if (!Is_Amplified[client])
				{
					
					TF2Attrib_SetByName(clientweapon, "throwable particle trail only", (ChainDamageOld));
					
					ChainDamageOld = GetWepAttribValue(clientweapon, "throwable particle trail only");
					
					TF2Attrib_RemoveByName(clientweapon, "mult_player_movespeed_active");
				}
			}
		}
	}
}

/*
public Action:OnTakeDamageDirectHit(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsValidClient(attacker))
	{
		new clientweapon = GetPlayerWeaponSlot(attacker,0);
			
		if (IsValidEntity(clientweapon))
		{
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
				
				if (Is_Amplified[attacker])
				{
					damage *= 1.30;
				}
			}
		}
	}
	return Plugin_Changed;
}
*/

public Event_PlayerDeathDR(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer=GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(killer) && IsValidClient(victim))
	{
		new clientweapon = GetPlayerWeaponSlot(killer,0);
		
		if (IsValidEntity(clientweapon))
		{
			if (WepAttribCheck(clientweapon, "fuller court"))
			{
				Is_Amplified[killer] = true;
				Amplified_Timer[killer] = 7.0;
				
				g_Timer[killer] = CreateTimer(Amplified_Timer[killer], Timer_Amplified, killer);
			}
		}
	}
}

public Action:Timer_Amplified(Handle:Timer, any:killer)
{
	if (IsValidClient(killer))
	{
		if (Is_Amplified[killer])
		{
			Is_Amplified[killer] = false;
		}
	}
}