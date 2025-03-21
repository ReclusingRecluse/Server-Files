Float:Ember_stacks[MAXPLAYERS+1] ={0.0, ...};

bool:AltFire_active[MAXPLAYERS+1] = {false, ...};

Float:Duration[MAXPLAYERS+1] = {0.0, ...};

Float:Delay[MAXPLAYERS+1] = {0.0, ...};

new Float:Buff[MAXPLAYERS+1] = {1.0, ...};

//Float:Fire_rate_to_damage[MAXPLAYERS+1] = {0.0, ...};

//Float:Totaldamage[MAXPLAYERS+1] = {0.0, ...}

new LastButtons[MAXPLAYERS+1] = {-1 , ...};


/*
public Action:Timer_Ember(Handle:Timer)
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			new clientweapon = GetPlayerWeaponSlot(client,1);
		
			if (IsValidEntity(clientweapon))
			{
				if(WepAttribCheck(clientweapon, "scorch shot extreme"))
				{
					TF2Attrib_SetByName(clientweapon, "minicrit vs burning player", 0.0);
					//SetHudTextParams(0.75, 0.6, 0.2, 255, 255, 0, 240);
					//ShowSyncHudText(client, SyncHud_Mangler, "Ember %.0f", Ember_stacks[client]);
					
					FireRateToDamage(client, clientweapon);
					Totaldamage[client] = (Fire_rate_to_damage[client]*2.0);
					
					if (AltFire_active[client] == true)
					{
						
						TF2Attrib_SetByName(clientweapon, "Blast radius decreased", (Buff[client]*0.60));
						TF2Attrib_SetByName(clientweapon, "weapon burn time increased", Buff[client]);
						TF2Attrib_SetByName(clientweapon, "weapon burn dmg increased", Buff[client]);
						TF2Attrib_SetByName(clientweapon, "damage bonus", Buff[client]);
						TF2Attrib_SetByName(clientweapon, "killstreak idleeffect", 3.0);
						
						TF2Attrib_SetByName(clientweapon, "scorch", 250.0);
						TF2Attrib_SetByName(clientweapon, "fire rate bonus", 0.4);
					}
					
					if (AltFire_active[client] == false)
					{
						TF2Attrib_RemoveByName(clientweapon, "Blast radius decreased");
						TF2Attrib_RemoveByName(clientweapon, "weapon burn time increased");
						TF2Attrib_RemoveByName(clientweapon, "weapon burn dmg increased");
						TF2Attrib_RemoveByName(clientweapon, "killstreak idleeffect");
						TF2Attrib_RemoveByName(clientweapon, "fire rate bonus");
						
						TF2Attrib_SetByName(clientweapon, "scorch", 60.0);
					}
					
					if (Ember_stacks[client] > 100.0)
					{
						Ember_stacks[client] = 100.0;
					}
				}
			}
		}
	}
}
*/

/*
public Action:OnTakeDamageScorchShot(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsValidClient(attacker) && IsValidClient(victim))
	{
		new clientweapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(clientweapon))
		{
			if(WepAttribCheck(clientweapon, "fire rate to damage"))
			{
				if (!(damagetype & DMG_SHOCK))
				{
					FireRateToDamage(attacker, clientweapon);
					damage *= ((Fire_rate_to_damage[attacker]*2.0)-1.0)*2.0;
				}
				
				if (damagetype & DMG_BURN && (AltFire_active[attacker] == false))
				{
					Ember_stacks[attacker] += 5.0;
				}
				
			}
		}
	}
	return Plugin_Changed;
}
*/

AltFire(client, &Buttons, &ButtonsLast)
{
	if (IsValidClient(client))
	{
		new clientweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(clientweapon))
		{
			if(WepAttribCheck(clientweapon, "scorch shot extreme"))
			{
				if ((Buttons & IN_RELOAD) == IN_RELOAD)
				{
					ConsumeEmber(client);
				}
			}
		}
	}
	return Buttons;
}

ConsumeEmber(client)
{
	if (Delay[client] >= GetEngineTime()) return;
	
	Delay[client] = GetEngineTime()+1.0;
	
	if (Ember_stacks[client] > 0.0 && !AltFire_active[client])
	{
		Buff[client] = (Pow(Ember_stacks[client],0.3))+Pow((Ember_stacks[client]*0.2),0.2);
		Duration[client] = (Ember_stacks[client]*0.1);
		Ember_stacks[client] = 0.0;
		AltFire_active[client] = true;
		CreateTimer(Duration[client], Timer_BuffClear, client);
		//PrintToChat(client, "stacks consumed");
		//PrintToChat(client, "duration = %.0f", Duration[client]);
	}
}

public Action:Timer_BuffClear(Handle:Timer, any:client)
{
	if (IsValidClient(client))
	{
		if (AltFire_active[client])
		{
			AltFire_active[client] = false;
			Buff[client] = 1.0;
		}
	}
}


/*
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
*/