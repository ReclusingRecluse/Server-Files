Handle:TimerHandle[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

bool:Chance_clear[MAXPLAYERS+1] = {false, ...};


public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (IsValidClient(client))
	{
		new clientweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new Float:Timer[MAXPLAYERS+1] = {1.0, ...};
		
		if (IsValidEntity(clientweapon))
		{
			if(WepAttribCheck(clientweapon, "flare gun extreme"))
			{
				Chance_clear[client] = false;
				if (Chain_Chance[client] < 0.45)
				{
					Chain_Chance[client] += 0.05;
				
					TF2Attrib_SetByName(clientweapon, "throwable particle trail only", (Chain_Chance[client]));
				}
				//PrintToChat(client, "chain chance %.2f", Chain_Chance[client]);
				//Timer[client] = 5.0;
				Chain_Reset[client] = GetEngineTime()+5.0;
			}
			if (WepAttribCheck(clientweapon, "le monarque"))
			{
				HoldTime[client] = 0.0;
			}
		}
	}
}

/*
public Action:Timer_ChainChanceClear(Handle:Timer, any:client)
{
	if (IsValidClient(client))
	{
		if (Chance_clear[client] == false)
		{
			Chance_clear[client] = true;
		}
	}
}
*/

/*
public Action:Timer_CalcAttack(Handle:Timer)
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			new clientweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			
			if(WepAttribCheck(clientweapon, "flare gun extreme"))
			{
				if (Chance_clear[client] == true)
				{
					Chain_Chance[client] = 0.05;
					//PrintToChat(client, "chain chance %.2f", Chain_Chance[client]);
					TF2Attrib_SetByName(clientweapon, "throwable particle trail only", Chain_Chance[client]);
					Chance_clear[client] = false;
				}
			}
		}
	}
}
*/