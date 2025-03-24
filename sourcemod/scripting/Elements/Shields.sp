bool Shieldactive_Void[MAXPLAYERS+1] = {false, ...};

bool Shieldactive_Arc[MAXPLAYERS+1] = {false, ...};

bool Shieldactive_Solar[MAXPLAYERS+1] = {false, ...};

bool Shieldactive_Stasis[MAXPLAYERS+1] = {false, ...};

Float:Shield_Health[MAXPLAYERS+1] = {0.0, ...};

public Action:OnTakeDamageShield(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsValidClient(attacker) && IsValidClient(victim))
	{
		new attackerwep = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if (Shieldactive_Arc[victim] == true)
		{
			if (IsValidEntity(attackerwep))
			{
				if (!WepAttribCheck(attackerwep, "throwable particle trail only"))
				{
					damage *= 0.50;
				}
			}
		}
		if (Shieldactive_Solar[victim] == true)
		{
			if (IsValidEntity(attackerwep))
			{
				if (!WepAttribCheck(attackerwep, "scorch"))
				{
					damage *= 0.50;
				}
			}
		}
		if (Shieldactive_Void[victim] == true)
		{
			if (IsValidEntity(attackerwep))
			{
				if (!WepAttribCheck(attackerwep, "strange restriction user value 3"))
				{
					damage *= 0.50;
				}
			}
		}
	}
	return Plugin_Changed;
}


void SetShieldHealth(client)
{
	if (!IsValidClient(client)){ continue;}
	
	Shield_Health[client] = RoundToFloor(TF2_GetMaxHealth(client)*0.5);
}

void SetElementalShield(client, int ShieldType)
{
	if (!IsValidClient(client) || ShieldType < 1 || ShieldType > 4) {continue;}
	
	SetShieldHealth(client);
	switch (ShieldType)
	{
		//Void
		case 1:
		{
			Shieldactive_Void[client] = true;
			SetEntityRenderColor(client, 255, 200, 255);
		}
		
		//Solar
		case 2:
		{
			Shieldactive_Solar[client] = true;
			SetEntityRenderColor(client, 255, 200, 200);
		}
		
		//Arc
		case 3:
		{
			Shieldactive_Arc[client] = true;
			SetEntityRenderColor(client, 200, 200, 255);
		}
		//Stasis
		case 4:
		{
			Shieldactive_Stasis[client] = true;
		}
	}
}