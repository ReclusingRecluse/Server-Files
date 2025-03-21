Float:Siphoned_Health[MAXPLAYERS+1] = {0.0, ...};

Float:Projectile_Speed_bonus[MAXPLAYERS+1] = {0.0, ...};

Float:Fire_rate_to_damage[MAXPLAYERS+1] = {0.0, ...};

Float:Totaldamage[MAXPLAYERS+1] = {0.0, ...};

public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer=GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim=GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(killer) && IsValidClient(victim))
	{
		new clientweapon = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(clientweapon))
		{
			if(WepAttribCheck(clientweapon, "void mangler"))
			{
				if (Siphoned_Health[killer] < 1000.0)
				{
					Siphoned_Health[killer] += (TF2_GetMaxHealth(victim)*0.03);
					//PrintToChat(killer, "Siphoned Health, %.0f", Siphoned_Health[killer]);
				}
			}
		}
	}
}
/*
public Action:OnTakeDamageMangler(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsValidClient(attacker) && IsValidClient(victim))
	{
		new clientweapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(clientweapon))
		{
			if(WepAttribCheck(clientweapon, "void mangler"))
			{
				damage *= (Fire_rate_to_damage[attacker]*2.0)-1.0;
				if (Siphoned_Health[attacker] > 1.0)
				{
					damage *= ((Pow(Siphoned_Health[attacker], 0.15))*(Pow(Siphoned_Health[attacker], 0.07)))*0.30;
				}
			}
		}
	}
	return Plugin_Changed;
}
*/
/*
public Action:Timer_Count(Handle:Timer)
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			new clientweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
			if (IsValidEntity(clientweapon))
			{
				if(WepAttribCheck(clientweapon, "void mangler"))
				{
					FireRateToDamage(client, clientweapon);
					Totaldamage[client] = ((Pow(Siphoned_Health[client], 0.15))*(Pow(Siphoned_Health[client], 0.07))+(Fire_rate_to_damage[client]*2.0))-2.0;
					//SetHudTextParams(0.75, 0.6, 0.2, 255, 255, 0, 240);
					//ShowSyncHudText(client, SyncHud_Mangler, "Current Damage Mult %.2f", Totaldamage[client]);
					
					
					if (Siphoned_Health[client] > 0.0)
					{
						Projectile_Speed_bonus[client] = (Pow((Siphoned_Health[client]*0.70), 0.32));
						TF2Attrib_SetByName(clientweapon, "Projectile speed increased", Projectile_Speed_bonus[client]);
						
					}
					
					if (Siphoned_Health[client] > 1000.0)
					{
						Siphoned_Health[client] = 1000.0;
					}
					
				}
			}
		}
	}
}
*/


stock FireRateToDamage(client, c_weapon)
{
	if (IsValidEntity(c_weapon) && IsValidClient(client))
	{
		Fire_rate_to_damage[client] = 1.0;
		if (WepAttribCheck(c_weapon, "fire rate bonus custom"))
		{
			Fire_rate_to_damage[client] *= (Pow(GetWepAttribValue(c_weapon, "fire rate bonus custom"),-0.27));
		}
		if (WepAttribCheck(c_weapon, "fire rate penalty custom"))
		{
			Fire_rate_to_damage[client] *= (Pow(GetWepAttribValue(c_weapon, "fire rate penalty custom"),-0.27));
		}
		else {return;}
	}
	else {return;}
}