

Float:g_GameTime = 0.0;

public OnGameFrame()
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			//LLDealDamage(client);
			RadiusCalc(client);
					
			//Black Box
			ElementSwitch(client);
			//new clientweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			
			
			if (Chain_Reset[client] <= GetEngineTime()){return;}
			
			if(!Chance_clear[client])
			{
				Chance_clear[client] = true;
			}
		}
	}
}

