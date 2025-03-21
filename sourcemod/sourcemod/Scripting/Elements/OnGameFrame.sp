public OnGameFrame()
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
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
		}
	}
}