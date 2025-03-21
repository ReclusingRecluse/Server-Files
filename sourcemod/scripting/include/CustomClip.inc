// CustomClip
new Handle:g_Timer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new bool:ReloadFinished[MAXPLAYERS+1] = {false, ...};
new bool:IsReloading[MAXPLAYERS+1] = {false, ...};
int ClipSet[MAXPLAYERS+1] = {0, ...};
int Reserve1Set[MAXPLAYERS+1] = {0, ...};
int Reserve2Set[MAXPLAYERS+1] = {0, ...};


int AmmoNeeded[MAXPLAYERS+1] = {0, ...};
int g_Slot[MAXPLAYERS+1] = {-1, ...};

new Float:timer[MAXPLAYERS+1] = {0.0, ...};

stock bool:IsReloadFinished(client)
{
	if (ReloadFinished[client] == true)
	{
		return true;
	}
	else {return false;}
}

stock CustomClip_SetClipAndReserves(client, c_weapon, int slot = -1, int Clip = 0, int Reserves = 0, bool:CustomClip_MaxClipAttribSupport = false)
{
	if (!IsValidClient(client) || !IsValidEntity(c_weapon) || slot == -1) {return;}
	
	if (IsValidClient(client) && IsValidEntity(c_weapon) && slot > -1)
	{
		new Weapon = TF2_GetClientActiveSlot(client);
		g_Slot[client] = Weapon;
		if (Weapon == slot)
		{
			//for easy detection for other plugin stuff
			TF2Attrib_SetByName(client, "SET BONUS: special dsp", 1.00);
			
			int Currentclip = GetEntProp(c_weapon, Prop_Data, "m_iClip1");
			Currentclip = Clip;
			ClipSet[client] = Clip;
			
			if (CustomClip_MaxClipAttribSupport == true)
			{
				//Increase Clip
				new Address:H_Clip1 = TF2Attrib_GetByName(c_weapon, "clip size bonus");
				new Address:H_Clip2 = TF2Attrib_GetByName(c_weapon, "clip size bonus upgrade");
				new Address:H_Clip3 = TF2Attrib_GetByName(c_weapon, "clip size upgrade atomic");
				
				//Decrease Clip
				new Address:L_Clip1 = TF2Attrib_GetByName(c_weapon, "clip size penalty");
				new Address:L_Clip2 = TF2Attrib_GetByName(c_weapon, "clip size penalty HIDDEN");
				
				//Increase Clip Size
				if (H_Clip1 != Address_Null)
				{
					ClipSet[client] *= RoundToFloor(TF2Attrib_GetValue(H_Clip1)+1);
					//PrintToServer("New Clip %i", ClipSet[client]);
				}
				if (H_Clip2 != Address_Null)
				{
					ClipSet[client] *= RoundToFloor(TF2Attrib_GetValue(H_Clip2)+1);
				}
				if (H_Clip3 != Address_Null)
				{
					ClipSet[client] *= RoundToFloor(TF2Attrib_GetValue(H_Clip3)+1);
				}
				//else
				//{
					//ClipSet[client] = Currentclip;
				//}
				
				// Decrease Clip Size
				if (L_Clip1 != Address_Null)
				{
					ClipSet[client] *= RoundToFloor(TF2Attrib_GetValue(L_Clip1));
				}
				if (L_Clip2 != Address_Null)
				{
					ClipSet[client] *= RoundToFloor(TF2Attrib_GetValue(L_Clip2));
				}
				//else
				//{
					//ClipSet[client] = Currentclip;
				//}
			}
			if (CustomClip_MaxClipAttribSupport == false)
			{
				ClipSet[client] = Currentclip;
			}
			CreateTimer(0.1, Clip_Set, client);
			//SetEntProp(c_weapon, Prop_Send, "m_iClip1", Currentclip);
			
			if (slot == 0)
			{
				new PrimaryAmmoType = GetEntProp(c_weapon, Prop_Send, "m_iPrimaryAmmoType");
				
				PrimaryAmmoType = Reserves;
				Reserve1Set[client] = PrimaryAmmoType;
				
				SetEntProp(client, Prop_Send, "m_iAmmo", PrimaryAmmoType);
			}
			if (slot == 1)
			{
				new SecondaryAmmoType = GetEntProp(c_weapon, Prop_Send, "m_iSecondaryAmmoType");
				
				SecondaryAmmoType = Reserves;
				Reserve2Set[client] = SecondaryAmmoType;
				
				SetEntProp(client, Prop_Send, "m_iAmmo", SecondaryAmmoType);
			}
		}
		else
		{
			return;
		}
	}
}

public Action:Clip_Set(Handle:Timer, any:client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client)){return;}
	
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		new C_Weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(C_Weapon))
		{
			new Weapon = TF2_GetClientActiveSlot(client);
			
			if (Weapon == g_Slot[client])
			{
				int clip;
				clip = GetEntProp(C_Weapon, Prop_Data, "m_iClip1");
				
				clip = ClipSet[client];
				SetEntProp(C_Weapon, Prop_Send, "m_iClip1", clip);
				//PrintToServer("braap");
			}
			else
			{
				return;
			}
		}
		else
		{
			return;
		}
	}
}

//stock CustomClip_AddClip(client, c_weapon, int slot = -1, int Add = 0)

stock CustomClip_ReloadCalc(client, c_weapon, int slot = -1, Float:reload_timer = 2.0, int OriginalClip = 0, bool:CustomClip_ReloadAttribSupport = false)
{
	if (!IsValidClient(client) || !IsValidEntity(c_weapon) || slot == -1 || OriginalClip == 0){return;}
	
	if (IsValidClient(client) && IsValidEntity(c_weapon) && slot > -1)
	{
		new Weapon = TF2_GetClientActiveSlot(client);
		g_Slot[client] = Weapon;
		
		if (Weapon == slot)
		{
			int Currentclip = GetEntProp(c_weapon, Prop_Data, "m_iClip1");
			if (CustomClip_ReloadAttribSupport == true) //Support for Reload affecting attributes
			{
				//Increase Reload Speed
				new Address:F_Reload1 = TF2Attrib_GetByName(c_weapon, "Reload time decreased");
				new Address:F_Reload2 = TF2Attrib_GetByName(c_weapon, "reload time decreased while healed");
				new Address:F_Reload3 = TF2Attrib_GetByName(c_weapon, "faster reload rate");
				new Address:F_Reload4 = TF2Attrib_GetByName(c_weapon, "halloween reload time decreased");
				
				//Decrease Reload Speed
				new Address:S_Reload1 = TF2Attrib_GetByName(c_weapon, "Reload time increased");
				new Address:S_Reload2 = TF2Attrib_GetByName(c_weapon, "reload time increased hidden");
				
				//Faster Reload Speed
				if (F_Reload1 != Address_Null)
				{
					reload_timer *= TF2Attrib_GetValue(F_Reload1);
				}
				if (F_Reload2 != Address_Null)
				{
					reload_timer *= TF2Attrib_GetValue(F_Reload2);
				}
				if (F_Reload3 != Address_Null)
				{
					reload_timer *= TF2Attrib_GetValue(F_Reload3);
				}
				if (F_Reload4 != Address_Null)
				{
					reload_timer *= TF2Attrib_GetValue(F_Reload4);
				}
				else
				{
					timer[client] = reload_timer;
				}
				
				//Slower Reload Speed
				if (S_Reload1 != Address_Null)
				{
					reload_timer *= TF2Attrib_GetValue(S_Reload1);
				}
				if (S_Reload2 != Address_Null)
				{
					reload_timer *= TF2Attrib_GetValue(S_Reload2);
				}
				else
				{
					timer[client] = reload_timer;
				}
			}
			if (CustomClip_ReloadAttribSupport == false)
			{
				timer[client] = reload_timer;
			}
			if (Currentclip < OriginalClip)
			{
				AmmoNeeded[client] = OriginalClip - Currentclip;
				IsReloading[client] = true;
				timer[client] = reload_timer;
				g_Timer[client] = CreateTimer(0.1, CustomClip_ReloadFunc, client, TIMER_REPEAT);
			}
			if (Currentclip == OriginalClip)
			{
				IsReloading[client] = false;
				//PrintToServer("Not Reloading");
				return;
			}
		}
		else
		{
			return;
		}
	}
}

//Handle g_SyncDisplay1;
public Action:CustomClip_ReloadFunc(Handle:Timer, any:client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client)){return;}
	
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		new C_Weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (IsReloading[client] == true && IsValidEntity(C_Weapon))
		{
			new Weapon = TF2_GetClientActiveSlot(client);
			
			if (Weapon == g_Slot[client])
			{
				new PrimaryAmmoType = GetEntProp(client, Prop_Send, "m_iAmmo");
				if (timer[client] > 0.0 && IsReloading[client] == true && PrimaryAmmoType > 0)
				{
					timer[client] -= 0.1;
					/*
					decl String:ArmorLeft[32]
					Format(ArmorLeft, sizeof(ArmorLeft), "Reloading %.1f", timer[client]); 
					SetHudTextParams(0.65, -0.15, 0.5, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
					ShowSyncHudText(client, g_SyncDisplay1, "%s", ArmorLeft);
					*/
				}
				if (timer[client] < 0.0)
				{
					timer[client] = 0.0;
				}
				if (g_Slot[client] == 0 && timer[client] == 0.0)
				{
					int clip;
					clip = GetEntProp(C_Weapon, Prop_Data, "m_iClip1");
					
					if (PrimaryAmmoType < AmmoNeeded[client] && PrimaryAmmoType > 0)
					{
						AmmoNeeded[client] = PrimaryAmmoType;
					}
					clip += AmmoNeeded[client];
					
					if (PrimaryAmmoType > 0 && PrimaryAmmoType >= AmmoNeeded[client])
					{
						PrimaryAmmoType -= AmmoNeeded[client];
					}
					else
					{
						return;
					}
					
					SetEntProp(client, Prop_Send, "m_iAmmo", PrimaryAmmoType);
					SetEntProp(C_Weapon, Prop_Send, "m_iClip1", clip);
					IsReloading[client] = false;
					ReloadFinished[client] = true;
					timer[client] = 0.0;
					KillTimer(g_Timer[client]);
					g_Timer[client] = INVALID_HANDLE;
				}
				//if (g_Slot[client] == 1)
				//{
					//secondaries
				//}
				else {return;}
			}
		}
		else
		{
			KillTimer(Timer);
		}
	}
}
stock MaxammoIncrease(client, c_weapon, int ammo, int slot = -1, int orignalmaxammo, bool:Maxammo_attributesupport=false, bool:Maxammo_regensupport=false)
{
	if (!IsValidClient(client) || slot == -1 || !IsValidEntity(c_weapon)){return;}
	
	if (IsValidClient(client) && slot > -1 && IsValidEntity(c_weapon))
	{
		new Weapon = TF2_GetClientActiveSlot(client);
		
		if (Weapon == slot)
		{
			
			if (Maxammo_attributesupport == true)
			{
				ammo = 0;
				if(slot == 0)
				{
					new PrimaryAmmoType = GetEntProp(c_weapon, Prop_Send, "m_iPrimaryAmmoType");
					new Address:Maxammo1 = TF2Attrib_GetByName(client, "maxammo primary increased");
					if (Maxammo1 != Address_Null)
					{
						PrimaryAmmoType = orignalmaxammo*RoundToFloor(TF2Attrib_GetValue(Maxammo1)*8);
						SetEntProp(client, Prop_Send, "m_iAmmo", PrimaryAmmoType);
					}
					else
					{
						return;
					}
				}
				if(slot == 1)
				{
					new SecondaryAmmoType = GetEntProp(c_weapon, Prop_Send, "m_iSecondaryAmmoType");
					new Address:Maxammo2 = TF2Attrib_GetByName(client, "maxammo secondary increased");
					if (Maxammo2 != Address_Null)
					{
						SecondaryAmmoType = orignalmaxammo*RoundToFloor(TF2Attrib_GetValue(Maxammo2)*8);
						SetEntProp(client, Prop_Send, "m_iAmmo", SecondaryAmmoType);
					}
					else
					{
						return;
					}
				}
			}
			if (Maxammo_attributesupport == false && ammo > 0)
			{
				if (slot == 0)
				{
					new PrimaryAmmoType = GetEntProp(c_weapon, Prop_Send, "m_iPrimaryAmmoType");
					PrimaryAmmoType += ammo;
					SetEntProp(client, Prop_Send, "m_iAmmo", PrimaryAmmoType);
				}
				if (slot == 1)
				{
					new SecondaryAmmoType = GetEntProp(c_weapon, Prop_Send, "m_iSecondaryAmmoType");
					SecondaryAmmoType += ammo;
					SetEntProp(client, Prop_Send, "m_iAmmo", SecondaryAmmoType);
				}
				else
				{
					return;
				}
			}
			if (Maxammo_regensupport == true)
			{
				new Address:AmmoRegen = TF2Attrib_GetByName(client, "ammo regen");
				if (AmmoRegen != Address_Null)
				{
					CreateTimer(5.0, Ammo_Regen, client, TIMER_REPEAT);
				}
				else
				{
					return;
				}
			}
			else {return;}
		}
		else
		{
			return;
		}
	}
}

public Action:Ammo_Regen(Handle:Timer, any:client)
{
	if (IsValidClient(client))
	{
		new Weapon = TF2_GetClientActiveSlot(client);
		new hClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		new Address:AmmoRegen = TF2Attrib_GetByName(client, "ammo regen");
		
		if (AmmoRegen != Address_Null)
		{
			int Regen;
			if (Weapon == 0)
			{
				new PrimaryAmmoType = GetEntProp(hClientWeapon, Prop_Send, "m_iPrimaryAmmoType");
				Regen = PrimaryAmmoType*RoundToFloor(TF2Attrib_GetValue(AmmoRegen)+1);
				
				PrimaryAmmoType += Regen;
				MaxammoIncrease(client, hClientWeapon, PrimaryAmmoType, 0, PrimaryAmmoType, true, false);
			}
			if (Weapon == 1)
			{
				new SecondaryAmmoType = GetEntProp(hClientWeapon, Prop_Send, "m_iSecondaryAmmoType");
				Regen = SecondaryAmmoType*RoundToFloor(TF2Attrib_GetValue(AmmoRegen)+1);
				
				MaxammoIncrease(client, hClientWeapon, Regen, 0, SecondaryAmmoType, true, false);
			}
			else {return;}
		}
		else {return;}
	}
}

stock bool DidWepAttribChange(c_weapon, const char[] attribute)
{
	if(!IsValidEntity(c_weapon)){return false;}
	
	else
	{
		new Float:OldAttribValue = 0.0;
		new Float:NewAttribValue = 0.0;
		new Address:Attrib = TF2Attrib_GetByName(c_weapon, attribute);
		OldAttribValue = TF2Attrib_GetValue(Attrib);
		
		if (Attrib!=Address_Null)
		{
			NewAttribValue = TF2Attrib_GetValue(Attrib);
		}
		if (NewAttribValue > OldAttribValue)
		{
			OldAttribValue = NewAttribValue;
			return true;
		}
	}
}

stock int TF2_GetClientActiveSlot(int client)
{
	return GetWeaponSlot(client, GetActiveWeapon(client));
}

stock int GetWeaponSlot(int client, int weapon)
{
	if (client == 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsValidEntity(weapon))
	{
		return -1;
	}

	for (int i = 0; i < 5; i++)
	{
		if (GetPlayerWeaponSlot(client, i) == weapon)
		{
			return i;
		}
	}

	return -1;
}

stock int GetActiveWeapon(int client)
{
	if (!IsPlayerIndex(client) || !HasEntProp(client, Prop_Send, "m_hActiveWeapon"))
	{
		return 0;
	}

	return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

stock bool IsPlayerIndex(int index)
{
	return index > 0 && index <= MaxClients;
}
