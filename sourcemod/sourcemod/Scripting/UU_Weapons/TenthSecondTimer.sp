bool:Arcstrike_bonus_active[MAXPLAYERS+1] = {false, ...};

public Action:Timer_TenthSecond(Handle:Timer)
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			
			new clientweapon = GetPlayerWeaponSlot(client,0);
			new clientweapon1 = GetPlayerWeaponSlot(client,1);
			
			if(WepAttribCheck(clientweapon1, "flare gun extreme"))
			{
				TF2Attrib_SetByName(clientweapon1, "crit vs burning players", 0.0);
				if (Chance_clear[client] == true)
				{
					Chain_Chance[client] = 0.05;
					//PrintToChat(client, "chain chance %.2f", Chain_Chance[client]);
					TF2Attrib_SetByName(clientweapon1, "throwable particle trail only", Chain_Chance[client]);
					Chance_clear[client] = false;
				}
			}
			if (WepAttribCheck(clientweapon, "buff weapon on consect hits"))
			{
				if (HitBonusActive[client])
				{
					TF2Attrib_SetByName(clientweapon, "fire rate bonus HIDDEN", 0.70);
				}
				else
				{
					TF2Attrib_RemoveByName(clientweapon,  "fire rate bonus HIDDEN");
				}
			}
			if (WepAttribCheck(clientweapon, "thunderlord"))
			{
				if (HitBonusActive[client])
				{
					TF2Attrib_SetByName(clientweapon, "throwable particle trail only", 1.0);
					TF2Attrib_SetByName(clientweapon, "arc damage chain max", 8.0);
					TF2Attrib_SetByName(clientweapon, "arc damage chain increase per chain", 1.0);
				}
				else
				{
					TF2Attrib_SetByName(clientweapon, "throwable particle trail only", 0.20);
					TF2Attrib_RemoveByName(clientweapon, "arc damage chain increase per chain");
					TF2Attrib_RemoveByName(clientweapon, "arc damage chain max");
				}
			}
			
			if (WepAttribCheck(clientweapon, "abbadon"))
			{
				if (HitBonusActive[client])
				{
					TF2Attrib_SetByName(clientweapon, "incandescent", 120.0);
				}
				else
				{
					TF2Attrib_RemoveByName(clientweapon, "incandescent");
				}
			}
			
			if(WepAttribCheck(clientweapon, "void mangler"))
			{
				FireRateToDamage(client, clientweapon);
				Totaldamage[client] = ((Pow(Siphoned_Health[client], 0.15))*(Pow(Siphoned_Health[client], 0.07))+(Fire_rate_to_damage[client]*2.0))-2.0;
				
				
				if (Siphoned_Health[client] > 0.0)
				{
					Projectile_Speed_bonus[client] = (Pow((Siphoned_Health[client]*0.70), 0.32));
					TF2Attrib_SetByName(clientweapon, "Projectile speed increased", Projectile_Speed_bonus[client]);
					
				}
				
				if (Siphoned_Health[client] > 1000.0)
				{
					Siphoned_Health[client] = 1000.0;
				}
				
			}
			
			if(WepAttribCheck(clientweapon1, "scorch shot extreme"))
			{
				TF2Attrib_SetByName(clientweapon1, "minicrit vs burning player", 0.0);
				
				FireRateToDamage(client, clientweapon1);
				Totaldamage[client] = (Fire_rate_to_damage[client]*2.0);
				
				if (AltFire_active[client] == true)
				{
					
					TF2Attrib_SetByName(clientweapon1, "Blast radius decreased", (Buff[client]*0.60));
					TF2Attrib_SetByName(clientweapon1, "weapon burn time increased", Buff[client]);
					TF2Attrib_SetByName(clientweapon1, "weapon burn dmg increased", Buff[client]);
					TF2Attrib_SetByName(clientweapon1, "damage bonus", Buff[client]);
					TF2Attrib_SetByName(clientweapon1, "killstreak idleeffect", 3.0);
					
					TF2Attrib_SetByName(clientweapon1, "scorch", 250.0);
					TF2Attrib_SetByName(clientweapon1, "fire rate bonus", 0.4);
				}
				
				if (AltFire_active[client] == false)
				{
					TF2Attrib_RemoveByName(clientweapon1, "Blast radius decreased");
					TF2Attrib_RemoveByName(clientweapon1, "weapon burn time increased");
					TF2Attrib_RemoveByName(clientweapon1, "weapon burn dmg increased");
					TF2Attrib_RemoveByName(clientweapon1, "killstreak idleeffect");
					TF2Attrib_RemoveByName(clientweapon1, "fire rate bonus");
					
					TF2Attrib_SetByName(clientweapon1, "scorch", 60.0);
				}
				
				if (Ember_stacks[client] > 100.0)
				{
					Ember_stacks[client] = 100.0;
				}
			}
			
			if(WepAttribCheck(clientweapon, "arcstrike"))
			{
				if(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1)
				{
					Arcstrike_bonus_active[client] = true;
					TF2Attrib_SetByName(clientweapon, "arc damage chain increase per chain", 1.0);
					TF2Attrib_SetByName(clientweapon, "arc damage chain max", 6.0);
					TF2Attrib_SetByName(clientweapon, "throwable particle trail only", 0.75);
					TF2Attrib_SetByName(clientweapon, "arc explode on last chain", 1.0);
					TF2Attrib_SetByName(clientweapon, "Projectile speed increased HIDDEN", 3.00);
				}
				else
				{
					Arcstrike_bonus_active[client] = false;
					TF2Attrib_SetByName(clientweapon, "arc damage chain max", 4.0);
					TF2Attrib_SetByName(clientweapon, "throwable particle trail only", 0.45);
					TF2Attrib_RemoveByName(clientweapon, "arc explode on last chain");
					TF2Attrib_RemoveByName(clientweapon, "Projectile speed increased HIDDEN");
				}
			}
		}
	}
}