public OnGameFrame()
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			new ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			
			
			
			if (VoidDmg_Active[client] == false)
			{
				CreateTimer(1.0, Timer_Thing2);
			}
			if (Voided[client] > 50.0)
			{
				Voided[client] = 50.0;
			}
			
			if (Strand_IsPoisoned[client])
			{
				TF2Attrib_SetByName(client, "health from healers reduced", 0.60);
				if (Strand_PoisonDuration[client] >= GetEngineTime()){return;}
				
				TF2Attrib_RemoveByName(client, "health from healers reduced");
				Strand_IsPoisoned[client] = false;
				Strand_PoisonHits[client] = 1.0;
				Strand_DamagePenalty[client] = 1.0;
			}
			
			
			if (Slowed[client] > 0.0)
			{
				if (SlowedClear_Delay[client] >= GetEngineTime()){return;}
				
				if (SlowClearing[client] == false)
				{
					SlowClearing[client] = true;
				}
			}
			
			if (Weakened[client])
			{
				TF2Attrib_SetByName(client, "is weakened", 1.0);
				if (Weakened_Timer[client] >= GetEngineTime()){return;}
				
				Weakened[client] = false;
				TF2Attrib_RemoveByName(client, "is weakened");
				
			}
			
			
			if (Frozen_Delay[client] > 0.0 && CanBeFrozen[client] == false)
			{
				if (Frozen_Delay[client] >= GetEngineTime()){return;}
				
				CanBeFrozen[client] = true;
			}
			
			if (KillStacks[client] > 0)
			{
				if (Killstacks_Duration[client] >= GetEngineTime()){return;}
				
				KillStacks[client] = 0;
			}
			
			if (Unraveling_Rounds_Active[client] && IsValidEntity(ClientWeapon))
			{
				if (KillStacks[client] > 3){KillStacks[client] = 3;}
				if (Unraveling_Rounds_Stacks[client] > 3.0){Unraveling_Rounds_Stacks[client] = 3.0;}
				
				TF2Attrib_SetByName(ClientWeapon, "revive", 1.0);
				
				if (Unraveling_Rounds_Duration[client] >= GetEngineTime()){return;}
				KillStacks[client] = 0;
				Unraveling_Rounds_Duration[client] = 0.0;
				Unraveling_Rounds_Stacks[client] = 0.0;
				
				Unraveling_Rounds_Active[client] = false;
				TF2Attrib_RemoveByName(ClientWeapon, "revive");
				
				
			}
		}
	}
}