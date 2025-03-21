

public Action:Timer_TwentiethSecond(Handle:Timer)
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			//Liberty Launcher
			LLDealDamage(client);
			
			//Direct Hit
			SpeedCalc(client);
		}
	}
}