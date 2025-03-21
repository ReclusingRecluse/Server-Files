// Handle All Natives

/*GetElementalDamageType(int client, int slot)*/
native int Native_ElmtlDmgType(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int slot = GetNativeCell(2);
	
	if (!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not valid", client);
	}
	
	for (int i = 0; i <= 2; i++)
	{
		if (GetPlayerWeaponSlot(client, i) == slot)
		{
			return g_ElementalWeapon[client][slot];
		}
	}
}