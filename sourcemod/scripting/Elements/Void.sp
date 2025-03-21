new Float:Voided[MAXPLAYERS+1] = {0.0, ...};

new bool:Voided_debuff[MAXPLAYERS+1];

new bool:VoidDmg_Active[MAXPLAYERS+1];

bool:CanBeVoided[MAXPLAYERS+1] = {false, ...};

bool:IsVolatile[MAXPLAYERS+1] = {false, ...};

new Float:Volatile_DmgThresh[MAXPLAYERS+1] = {0.0, ...};

new Float:Volatile_CurrentDMG[MAXPLAYERS+1] = {0.0, ...};



public Event_PlayerreSpawn2(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer=GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(victim))
	{
		if (Voided[victim] > 0)
		{
			Voided[victim] = 0.0;
		}
	}
}

public Action:OnTakeDamageVoid(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsValidClient(attacker) && IsValidClient(victim))
	{
		new AttWep = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		//new Address:VoidGun = TF2Attrib_GetByName(AttWep, "strange restriction user value 3");
		if (IsValidEntity(AttWep))
		{
			if (WepAttribCheck(AttWep, "strange restriction user value 3"))
			{
				if (Voided[victim] < 50.0 && CanBeVoided[victim] == true)
				{
					Voided[victim] += GetWepAttribValue(AttWep, "strange restriction user value 3");
				}
				if (Voided[victim] == 50.0)
				{
					Voided[victim] = 0.0;
					new Float:Dmg = TF2_GetMaxHealth(victim)*0.30+damage*1.2;
					//PrintToChat(attacker, "Voided victim");
					new Float:HealthSiphon = (TF2_GetMaxHealth(attacker)*(GetWepAttribValue(AttWep, "strange restriction user value 3")/100.0))*1.80;
					if (Voided_debuff[victim] == false)
					{
						TF2Attrib_SetByName(AttWep, "reduce armor on hit", Dmg);
						CanBeVoided[victim] = false;
						
						//SDKHooks_TakeDamage(attacker, attacker, attacker, HealthSiphon, DMG_BLAST, 0, NULL_VECTOR, NULL_VECTOR, true);
						
						Voided_debuff[victim] = true;
						
						TF2Attrib_SetByName(victim, "armor regen penalty", 15.0);
						//TF2Attrib_SetByName(victim, "armor additional regen", 0.60);
						//fl_ArmorRegenPenalty[victim] = 20.0;
						//fl_AdditionalArmorRegen[victim] -= 0.60;
						//fl_CurrentArmor[victim] -= fl_MaxArmor[victim]*0.30+HealthSiphon;
						//PrintToChat(attacker, "victim armor %.0f out of %.0f", fl_CurrentArmor[victim], fl_MaxArmor[victim]);
						
						CreateTimer(7.0, Timer_debuff);
					}
				}
				
				/*
				if (IsVolatile[victim])
				{
					Volatile_DmgThresh[victim] = (TF2_GetMaxHealth(victim)*0.30);
					Volatile_CurrentDMG[victim] += damage;
					
					if (Volatile_CurrentDMG[victim] >= Volatile_DmgThresh[victim])
					{
					}
				}
				*/
			}
		}
	}
}

public Action:Timer_debuff(Handle:Timer)
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			if (Voided_debuff[client] == true)
			{
				Voided_debuff[client] = false;
				TF2Attrib_RemoveByName(client, "armor regen penalty");
				//TF2Attrib_RemoveByName(client, "armor additional regen");
			}
			if (CanBeVoided[client] == false)
			{
				CanBeVoided[client] = true;
			}
			
			new AttWep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (IsValidEntity(AttWep))
			{
				if (WepAttribCheck(AttWep, "strange restriction user value 3"))
				{
					TF2Attrib_SetByName(AttWep, "reduce armor on hit", 7.0);
				}
			}
		}
	}
}

public Action:Timer_Thing2(Handle:Timer)
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (VoidDmg_Active[client] == false)
		{
			VoidDmg_Active[client] = true;
		}
	}
}