
//Floats, bools, and all

Float:Slowed[MAXPLAYERS+1] = {0.0, ...};
Float:SlowedClear_Delay[MAXPLAYERS+1] = {0.0, ...};
bool:SlowClearing[MAXPLAYERS+1] = {false, ...};

Float:Dmg_TilShatter[MAXPLAYERS+1] = {0.0, ...};

bool:Frozen[MAXPLAYERS+1] = {false, ...};

Float:Dmg_VsFrozen[MAXPLAYERS+1] = {0.0, ...};
Float:Dmg_VsFrozenTimer[MAXPLAYERS+1] = {0.0, ...};

Float:Shatter_Radius[MAXPLAYERS+1] = {0.0, ...};
Float:Shatter_Dmg[MAXPLAYERS+1] = {0.0, ...};


new Handle:g_Timer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new Handle:g_Timer1[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
//Handle:Sync_Hud_Stasis[MAXPLAYERS+1];



public Event_PlayerhurtStasis(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer=GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Float:damage = GetEventFloat(event, "damageamount");
	
	if (IsValidClient(killer) && IsValidClient(client))
	{
		new ClientWep = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
		//Address StasisWep = TF2Attrib_GetByName(ArcGun, "stasis element");
		
		if (IsValidEntity(ClientWep))
		{
			//Check that the attacker's weapon is Stasis to apply slow effect
			if (WepAttribCheck(ClientWep, "stasis element"))
			{
				if (GetRandomFloat(0.0,1.0) <= (GetWepAttribValue(ClientWep, "stasis element")*0.01))
				{
					if (Slowed[client] < 100.0 && Frozen[client] == false)
					{
						SlowClearing[client] = false;
						
						if (!TF2_IsPlayerInCondition(client, TFCond_OnFire))
						{
							Slowed[client] += GetWepAttribValue(ClientWep, "stasis element");
						}
						
						if (TF2_IsPlayerInCondition(client, TFCond_OnFire))
						{
							Slowed[client] += (GetWepAttribValue(ClientWep, "stasis element")*0.60);
						}
						
						SlowedClear_Delay[client] = GetEngineTime()+1.5;
					}
				}
			}
			
			//Freeze victim is slowed stacks is 100
			if (Slowed[client] == 100.0 && Frozen[client] == false)
			{
				CreateTimer(0.2, Timer_Freeze, client)
			}
			
			//Shatter if Frozen victim takes enough damage
			
			if (Frozen[client] == true && client != killer)
			{
				
				//new String:ClientName[64];
				
				Dmg_VsFrozen[client] += damage;
				
				if (Dmg_VsFrozen[client] == Dmg_TilShatter[client])
				{
					Shatter_Dmg[client] = (Dmg_VsFrozen[client]+(TF2_GetMaxHealth(client)*0.15));
					
					Shatter_Radius[client] = TF2_GetMaxHealth(client)*0.25;
					
					new Float:Position[3];
					GetClientEyePosition(client, Position);
					Position[2] -= 30.0
					
					CreateParticle(-1, "ExplosionCore_MidAir", Position);
					
					
					
					for ( new i = 1; i <= MaxClients; i++ )
					{
						if(i != killer && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != GetClientTeam(killer))
						{
							new Float:Position2[3];
							GetClientEyePosition(i, Position2);
							Position2[2] -= 30.0;
							
							new Float: distance = GetVectorDistance(Position, Position2);
							if (distance <= Shatter_Radius[client])
							{
								decl Handle:Filter;
								(Filter = INVALID_HANDLE);
								
								Filter = TR_TraceRayFilterEx(Position, Position2, MASK_SOLID, RayType_EndPoint, TraceEntityFilterPlayer, i);
								if (Filter != INVALID_HANDLE)
								{
									if (!TR_DidHit(Filter))
									{
										SDKHooks_TakeDamage(i, killer, killer, Shatter_Dmg[client], DMG_BLAST, -1, NULL_VECTOR, NULL_VECTOR, true);
										Frozen[client] = false;
										Dmg_VsFrozen[client] = 0.0;
										
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

public Action:Timer_DMGvsFrozenClear(Handle:Timer, any:client)
{
	if (IsValidClient(client))
	{
		if (Dmg_VsFrozen[client] > 0.0)
		{
			Dmg_VsFrozen[client] = 0.0;
		}
	}
}

public Action:Timer_Freeze(Handle:Timer, any:client)
{
	if (IsValidClient(client))
	{
		Frozen[client] = true;
		
		Dmg_VsFrozenTimer[client] = 2.0;
		g_Timer1[client] = CreateTimer(Dmg_VsFrozenTimer[client], Timer_DMGvsFrozenClear, client);
		Dmg_TilShatter[client] = (TF2_GetMaxHealth(client)*0.15);
		
		Slowed[client] = 0.0;
		
		SetEntityMoveType(client, MOVETYPE_NONE);
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
		
		//Set Player Color to Blue to indicate being frozen
		SetEntityRenderColor(client, 0, 0, 255);
		
		//EmitSoundFromOrigin(const String:sound[],const Float:orig[3])
		
		CreateTimer(4.0, Timer_FreezeClear, client);
	}
}

public Action:Timer_FreezeClear(Handle:Timer, any:client)
{
	if (IsValidClient(client))
	{
		if (Frozen[client] == true)
		{
			Frozen[client] = false;
			
			SetEntityMoveType(client, MOVETYPE_WALK);
			SetVariantInt(0);
			AcceptEntityInput(client, "SetForcedTauntCam");
			
			
			//Set player color to default when frozen duration is done
			SetEntityRenderColor(client, 255, 255, 255, 0);
			
		}
	}
}

/*
public Action:Timer_SlowedClear(Handle:Timer, any:client)
{
	if (IsValidClient(client))
	{
		if (SlowClearing[client] == false)
		{
			SlowClearing[client] = true;
		}
	}
}
*/

public Action:Timer_StackClear(Handle:Timer)
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			if (SlowClearing[client] == true)
			{
				if (Slowed[client] > 0.0)
				{
					Slowed[client] -= 3.0
				}
				
				if (Slowed[client] == 0.0)
				{
					SlowClearing[client] = false;
				}
			}
		}
	}
}

//Apply slow effect based on current slowed stacks
public Action:Timer_Slow(Handle:Timer)
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			if (Slowed[client] > 0.0)
			{
				//Apply move speed penalty based on the amount of slow they have
				TF2Attrib_SetByName(client, "major move speed bonus", Pow(Slowed[client], -0.17));
				AttachParticle(client, "xms_icicle_melt", 0.5);
				
				
				//replace slow on hit with stasis
				new clientweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				
				if (IsValidEntity(clientweapon))
				{
					if(WepAttribCheck(clientweapon, "slow enemy on hit"))
					{
						TF2Attrib_RemoveByName(clientweapon, "slow enemy on hit");
						TF2Attrib_SetByName(clientweapon, "stasis element", 15.0);
					}
					if (WepAttribCheck(clientweapon, "slow enemy on hit major"))
					{
						TF2Attrib_RemoveByName(clientweapon, "slow enemy on hit major");
						TF2Attrib_SetByName(clientweapon, "stasis element", 15.0);
					}
				}
			}
			if (Slowed[client] == 0.0)
			{
				TF2Attrib_RemoveByName(client, "major move speed bonus");
			}
			
			if (Frozen[client] == true)
			{
				//SetHudTextParams(0.48, 0.55, 1.2, 0, 255, 0, 255, 0, 0.0, 0.0, 0.0);
				//ShowSyncHudText(client, Sync_Hud_Stasis[client], "Frozen");
			}
			
			if (Slowed[client] < 0.0)
			{
				Slowed[client] = 0.0;
			}
			if (Slowed[client] > 100.0)
			{
				Slowed[client] = 100.0
			}
		}
	}
}
