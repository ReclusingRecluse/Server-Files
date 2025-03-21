//Change Element type based on current clip


int Element[MAXPLAYERS+1] = {1, ...};

int Element_Remove[MAXPLAYERS+1] = {0, ...};

public Event_PlayerhurtBlackBox(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer=GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(client) && IsValidClient(killer))
	{
		new clientweapon = GetPlayerWeaponSlot(client,0);
		
		if (IsValidEntity(clientweapon))
		{
			new Address:ThreeTailedFox = TF2Attrib_GetByName(clientweapon, "three tailed fox");
			if (ThreeTailedFox!=Address_Null)
			{
				if (Element_Remove[killer] > 3)
				{
					Element_Remove[killer] += 1;
				}
			}
		}
	}
}

stock ElementSwitch(client)
{
	new clientweapon = GetPlayerWeaponSlot(client,0);
	
	if (IsValidEntity(clientweapon))
	{
		new Address:ThreeTailedFox = TF2Attrib_GetByName(clientweapon, "three tailed fox");
		if (ThreeTailedFox!=Address_Null)
		{
			TF2Attrib_RemoveByName(clientweapon, "clip size penalty");
			TF2Attrib_SetByName(clientweapon, "clip size penalty HIDDEN", 0.85);
			int clip = GetEntProp(clientweapon, Prop_Data, "m_iClip1");
			
			Element[client] = clip;
			
			switch(Element[client])
			{
				case 3:
				{
					CreateTimer(0.1, Timer_Solar, client);
				}
				case 2:
				{
					CreateTimer(0.1, Timer_Stasis, client);
				}
				case 1:
				{
					CreateTimer(0.1, Timer_Arc, client);
				}
			}
			
			switch (Element_Remove[client])
			{
				case 1:
				{
					TF2Attrib_RemoveByName(clientweapon, "throwable particle trail only");
					TF2Attrib_RemoveByName(clientweapon, "item in slot 4");
					TF2Attrib_RemoveByName(clientweapon, "item in slot 7");
					TF2Attrib_RemoveByName(clientweapon, "weapon burn dmg increased");
				}
				
				case 2:
				{
				
				}
				
				case 3:
				{
				
				}
			}
		}
	}
}

public Action:Timer_Stasis(Handle:Timer, any:client)
{
	if (IsValidClient(client))
	{
		new clientweapon = GetPlayerWeaponSlot(client,0);
		
		if (IsValidEntity(clientweapon))
		{
			new Address:ThreeTailedFox = TF2Attrib_GetByName(clientweapon, "three tailed fox");
	
			if (ThreeTailedFox!=Address_Null && Element[client] == 2)
			{
				/*
				TF2Attrib_RemoveByName(clientweapon, "throwable particle trail only");
				TF2Attrib_RemoveByName(clientweapon, "item in slot 4");
				TF2Attrib_RemoveByName(clientweapon, "item in slot 7");
				TF2Attrib_RemoveByName(clientweapon, "weapon burn dmg increased");
				*/
				//TF2Attrib_RemoveByName(clientweapon, "recipe component defined item 6");
						
				TF2Attrib_SetByName(clientweapon, "damage bonus", 3.00);
				TF2Attrib_SetByName(clientweapon, "stasis element", 80.0);
				TF2Attrib_SetByName(clientweapon, "killstreak idleeffect", 6.0);
			}	
		}
	}
}

public Action:Timer_Solar(Handle:Timer, any:client)
{
	if (IsValidClient(client))
	{
		new clientweapon = GetPlayerWeaponSlot(client,0);
		
		if (IsValidEntity(clientweapon))
		{
			new Address:ThreeTailedFox = TF2Attrib_GetByName(clientweapon, "three tailed fox");
	
			if (ThreeTailedFox!=Address_Null && Element[client] == 3)
			{
				/*
				TF2Attrib_RemoveByName(clientweapon, "throwable particle trail only");
				TF2Attrib_RemoveByName(clientweapon, "strange restriction user value 3");
				TF2Attrib_RemoveByName(clientweapon, "stasis element");
				*/
				
				TF2Attrib_SetByName(clientweapon, "damage bonus", 2.00);
				TF2Attrib_SetByName(clientweapon, "scorch", 50.0);
				TF2Attrib_SetByName(clientweapon, "Set DamageType Ignite", 1.0);
				TF2Attrib_SetByName(clientweapon, "weapon burn dmg increased", 3.0);
				TF2Attrib_SetByName(clientweapon, "killstreak idleeffect", 3.0);
				//TF2Attrib_SetByName(clientweapon, "recipe component defined item 6", 1200.0);
			}
		}
	}
}

public Action:Timer_Arc(Handle:Timer, any:client)
{
	if (IsValidClient(client))
	{
		new clientweapon = GetPlayerWeaponSlot(client,0);
		
		if (IsValidEntity(clientweapon))
		{
			new Address:ThreeTailedFox = TF2Attrib_GetByName(clientweapon, "three tailed fox");
	
			if (ThreeTailedFox!=Address_Null && Element[client] == 1)
			{
				/*
				TF2Attrib_RemoveByName(clientweapon, "item in slot 4");
				TF2Attrib_RemoveByName(clientweapon, "Set DamageType Ignite");
				TF2Attrib_RemoveByName(clientweapon, "item in slot 7");
				TF2Attrib_RemoveByName(clientweapon, "weapon burn dmg increased");
				*/
				//TF2Attrib_RemoveByName(clientweapon, "recipe component defined item 6");
						
				TF2Attrib_SetByName(clientweapon, "damage bonus", 4.00);
				TF2Attrib_SetByName(clientweapon, "throwable particle trail only", 0.50);
				TF2Attrib_SetByName(clientweapon, "killstreak idleeffect", 4.0);
			}
		}
	}
}