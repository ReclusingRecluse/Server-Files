new Float:fl_MaxArmor[MAXPLAYERS+1] = {300.0, ...};
new Float:fl_CurrentArmor[MAXPLAYERS+1] = {300.0, ...};
new Float:fl_AdditionalArmorRegen[MAXPLAYERS+1] = {1.0, ...};
new Float:fl_ArmorRegenPenalty[MAXPLAYERS+1] = {0.0, ...};



stock bool:IsValidClient( client, bool:replaycheck = true )
{
    if ( client <= 0 || client > MaxClients ) return false; 
    if ( !IsClientInGame( client ) ) return false; 
    if ( !IsClientConnected( client ) ) return false; 
    if ( GetEntProp( client, Prop_Send, "m_bIsCoaching" ) ) return false; 
    if ( replaycheck )
    {
        if ( IsClientSourceTV( client ) || IsClientReplay( client ) ) return false; 
    }
    return true; 
}


stock SetArmor(client)
{
	if (IsValidClient(client))
	{
		if (IsValidClient(client))
		{
			new Address:armorActive = TF2Attrib_GetByName(client, "obsolete ammo penalty");
			new Address:armorActive2 = TF2Attrib_GetByName(client, "noise maker");
			if(armorActive != Address_Null)
			{
				new Float:armorAmount = TF2Attrib_GetValue(armorActive);
				fl_MaxArmor[client] = armorAmount+300.0;
			}
			else
			{
				fl_MaxArmor[client] = 300.0;
			}
			if(armorActive2 != Address_Null)
			{
				new Float:armorAmount = TF2Attrib_GetValue(armorActive2);
				fl_MaxArmor[client] += armorAmount+300.0;
			}
			/*new Address:capActive = TF2Attrib_GetByName(client, "tool escrow until date")
			new Address:Defense = TF2Attrib_GetByName(client, "is throwable chargeable");
			fl_ArmorCap[client] = 1.0;
			if(capActive != Address_Null)
			{
				if(!TF2_IsPlayerInCondition(client, TFCond_NoTaunting_DEPRECATED))
				{
					fl_ArmorCap[client] += Pow(TF2Attrib_GetValue(capActive), 1.65) + 1.0;
				}
				else
				{
					fl_ArmorCap[client] += Pow(TF2Attrib_GetValue(capActive)-1.0, 1.65) + 1.0;
				}
			}
			if(Defense != Address_Null)
			{
				fl_ArmorCap[client] *= Pow(TF2Attrib_GetValue(Defense), 0.85)
			}*/
		}
	}
}
