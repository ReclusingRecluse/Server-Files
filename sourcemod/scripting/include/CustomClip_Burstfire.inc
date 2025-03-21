bool:BurstFireReady[MAXPLAYERS+1] = {true, ...};
bool:Shooting[MAXPLAYERS+1] = {false, ...};
bool:Hasburstfireweapon[MAXPLAYERS+1] = {false, ...};
new Handle:g_Timer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
Float:g_TimerSetTime[MAXPLAYERS] = {0.0, ...};
int MaxShots[MAXPLAYERS+1] = {0, ...};
int CurrentShot[MAXPLAYERS+1] = {0, ...};

stock bool BurstFireAttribCheck(c_weapon)
{
	if (IsValidEntity(c_weapon))
	{
		new Address:BurstFireActive = TF2Attrib_GetByName(c_weapon, "burst fire weapon");
		
		if (BurstFireActive!=Address_Null)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	else {return false;}
}

	

stock BurstFireConfigure(client, c_weapon, int shotsper = 3, Float:burst_cooldown = 2.0, bool:FireRateAttribSupport = false)
{
	if (!IsValidClient(client) || !IsValidEntity(c_weapon) || shotsper < 2 || burst_cooldown == 0.0){return;}
	
	if (IsValidClient(client) && IsValidEntity(c_weapon) && shotsper > 1 && burst_cooldown > 0.0)
	{
		CurrentShot[client] = 0;
		BurstFireReady[client] = true;
		Hasburstfireweapon[client] = true;
		MaxShots[client] = shotsper;
		g_TimerSetTime[client] = burst_cooldown;
		PrintToServer("burst fire set");
	}
}

stock BurstReset(client)
{
	BurstFireReady[client] = true;
	Hasburstfireweapon[client] = false;
	g_Timer[client] = INVALID_HANDLE;
}

