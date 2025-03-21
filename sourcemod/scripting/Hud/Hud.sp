Handle:g_SyncHud[MAXPLAYERS+1];

new String: Text1[32];


stock CreateHud(client, const char[] string, float x = -1.0, float y = -1.0, int red = 255, int green = 255, int blue = 255, int alpha = 255)
{
	if (!IsValidClient(client))
	{
		return;
	}
	
	if (IsValidClient(client))
	{
		//new Handle:g_SyncHud[MAXPLAYERS+1];
		
		g_SyncHud[client] = CreateHudSynchronizer();

		SetHudTextParams(x, y, 1.0, red, green, blue, alpha);
		
		CreateTimer(0.1, Timer_HudShow, client, TIMER_REPEAT);
	}
}

public Action:Timer_HudShow(Handle:Timer, any:client)
{
	if (IsValidClient(client))
	{
		ShowSyncHudText(client, SyncHud_Mangler[client], "Current Damage Mult %.2f", Totaldamage[client]);