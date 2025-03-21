Float:BowChargeLevel[MAXPLAYERS+1] = {0.0, ...};
Float:HoldTime[MAXPLAYERS+1] = {0.0, ...};
Float:ChargeBegin[MAXPLAYERS+1] = {0.0, ...};
Float:MaxPoisonDuration[MAXPLAYERS+1] = {7.0, ...};
new Float:FireRate[MAXPLAYERS+1] = {1.0, ...};
new Float:ReloadRate[MAXPLAYERS+1] = {0.0, ...};

new g_iOffsetBow;
//Poison Explosion Stuff

//Float:Poison_Cloud_Radius[MAXPLAYERS+1] = {250.0, ...};
Float:Poison_Duration[MAXPLAYERS+1] = {2.0, ...};

stock CaclulatePoisonDuration(client, clientweapon)
{
	if (!IsValidClient(client) || !IsValidEntity(clientweapon)){return;}
	
	new String:classname[128]; 
	if (WepAttribCheck(clientweapon, "le monarque"))
	{
		GetEdictClassname(clientweapon, classname, sizeof(classname));
		
		if (!strcmp(classname, "tf_weapon_compound_bow"))
		{
			ChargeBegin[client] = (GetEntDataFloat(clientweapon, g_iOffsetBow));
			BowChargeLevel[client] = ((GetGameTime()) - ChargeBegin[client]) + HoldTime[client];
			
			//PrintToChat(client, "BowChargeLevel %.0f", BowChargeLevel[client]);
			
			CaculateMaxPosionDuration(client, clientweapon);
			//PrintToChat(client, "Posion Max Duration %.2f", MaxPoisonDuration[client]);
			Poison_Duration[client] = (BowChargeLevel[client]);
			
			if (Poison_Duration[client] > MaxPoisonDuration[client])
			{
				Poison_Duration[client] = MaxPoisonDuration[client];
			}
			if (Poison_Duration[client] == MaxPoisonDuration[client])
			{
				TF2Attrib_SetByName(clientweapon, "strand poison explosion", 1.0);
				TF2Attrib_SetByName(clientweapon, "ragdolls become ash", 1.0);
				TF2Attrib_SetByName(clientweapon, "taunt attack name", 1.0);
			}
			else
			{
				TF2Attrib_RemoveByName(clientweapon, "strand poison explosion");
				TF2Attrib_RemoveByName(clientweapon, "ragdolls become ash");
				TF2Attrib_RemoveByName(clientweapon, "taunt attack name");
			}
			
			TF2Attrib_SetByName(clientweapon, "strand poison duration", Poison_Duration[client]);
			
			//PrintToChat(client, "Posion Duration %.0f", Poison_Duration[client]);
		}
	}
}

BowCalcCharge(client, Buttons, ButtonsLast)
{
	if (IsValidClient(client))
	{
		new clientweapon = GetPlayerWeaponSlot(client,0);
		if (IsValidEntity(clientweapon) && WepAttribCheck(clientweapon, "le monarque"))
		{
			new String:classname[128];
			GetEdictClassname(clientweapon, classname, sizeof(classname));
		
			if (!strcmp(classname, "tf_weapon_compound_bow"))
			{
				if (Buttons & IN_ATTACK)
				{
					if (Poison_Duration[client] < MaxPoisonDuration[client])
					{
						HoldTime[client] += 0.1;
					}
					//PrintToChat(client, "Hold Time %.2f", HoldTime[client])
					CaclulatePoisonDuration(client, clientweapon);
				}
			}
		}
	}
	return Buttons;
}

stock CaculateMaxPosionDuration(client, clientweapon)
{
	if (!IsValidClient(client) || !IsValidEntity(clientweapon))
	
	
	if (WepAttribCheck(clientweapon, "fire rate bonus"))
	{
		FireRate[client] *= GetWepAttribValue(clientweapon, "fire rate bonus");
	}
	else if (WepAttribCheck(clientweapon, "fire rate bonus HIDDEN"))
	{
		FireRate[client] *= GetWepAttribValue(clientweapon, "fire rate bonus HIDDEN");
	}
	else
	{
		FireRate[client] = 1.0;
	}
	
	if (WepAttribCheck(clientweapon, "faster reload rate"))
	{
		if (GetWepAttribValue(clientweapon, "faster reload rate") < 1.0)
		{
			ReloadRate[client] = GetWepAttribValue(clientweapon, "faster reload rate");
		}
		else
		{
			ReloadRate[client] = 0.0;
		}
	}
	else
	{
		ReloadRate[client] = 0.0;
	}
	
	//PrintToChat(client, "Fire rate bonus: %.2f", FireRate[client]);
	MaxPoisonDuration[client] = 6.0*((10.0*ReloadRate[client])*1.2);
	
	if (MaxPoisonDuration[client] == 0.0)
	{
		MaxPoisonDuration[client] = 6.0;
	}
}

