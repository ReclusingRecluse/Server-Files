///braaap

bool Strand_IsPoisoned[MAXPLAYERS+1] = {false, ...};

Float:Strand_PoisonDuration[MAXPLAYERS+1] = {0.0, ...};

int Strand_Posion_Owner[MAXPLAYERS+1] = {-1, ...};

Float:Strand_PoisonHits[MAXPLAYERS+1] = {1.0, ...};

Float:Strand_DamagePenalty[MAXPLAYERS+1] = {1.0, ...};

bool:Unraveling_Rounds_Active[MAXPLAYERS+1] = {false, ...};

Float:Unraveling_Rounds_Duration[MAXPLAYERS+1] = {0.0, ...};

Float:Unraveling_Rounds_Stacks[MAXPLAYERS+1] = {0.0, ...};

int KillStacks[MAXPLAYERS+1] = {0, ...};

Float:Killstacks_Duration[MAXPLAYERS+1] = {0.0, ...};



public Action:OnTakeDamageStrand(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	/*
	new killer=GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Float:damage = GetEventFloat(event, "damageamount");
	*/
	
	if (IsValidClient(attacker) && IsValidClient(victim))
	{
		new attackerwep = weapon;
		
		if (IsValidEntity(attackerwep))
		{
			if (WepAttribCheck(attackerwep, "strand element") && !(damagetype & DMG_SLASH))
			{
				Strand_Posion_Owner[victim] = attacker;
				Strand_IsPoisoned[victim] = true;
				
				if (WepAttribCheck(attackerwep, "strand poison duration") && GetWepAttribValue(attackerwep, "strand poison duration") > 2.0)
				{
					Strand_PoisonDuration[victim] = GetEngineTime()+GetWepAttribValue(attackerwep, "strand poison duration");
				}
				else
				{
					Strand_PoisonDuration[victim] = GetEngineTime()+2.0;
				}
			}
			if (WepAttribCheck(attackerwep, "strand poison explosion") && !(damagetype & DMG_SLASH))
			{
				PoisonExplosion(attacker, victim, attackerwep, 500.0);
				TF2Attrib_RemoveByName(attackerwep, "strand poison explosion");
			}
			if (Strand_IsPoisoned[attacker])
			{
				damage *= Strand_DamagePenalty[attacker];
			}
			
			if (WepAttribCheck(attackerwep, "unraveling rounds"))
			{
				if (Strand_IsPoisoned[victim])
				{
					damage *= 1.30;
				}
				
				if (Unraveling_Rounds_Active[attacker])
				{
					UnravelingRounds(attacker, victim, attackerwep, 300.0, 2.5);
				}
			}
		}
	}
	return Plugin_Changed;
}

public Action:Timer_PoisonDmg(Handle:Timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{	
			for ( new attacker = 1; attacker <= MaxClients; attacker++ )
			{
				if (IsValidClient(attacker) && GetClientTeam(client) != GetClientTeam(attacker) && client != attacker)
				{
					if (Strand_Posion_Owner[client] == attacker)
					{
						new attackerwep = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
						if (IsValidEntity(attackerwep))
						{
							StrandDamage_Poison(client, attacker, attackerwep);
						}
					}
				}
			}
		}
	}
}

//Calculate Poison Damage to be delt to victim
stock StrandDamage_Poison(victim, attacker, attackerweapon)
{

	if (!IsValidClient(victim) || !IsValidClient(attacker) || !IsValidEntity(attackerweapon)){return;}
	
	if (WepAttribCheck(attackerweapon, "strand element") && Strand_IsPoisoned[victim])
	{
		new Float:PoisonDamage = 0.0;
	
		PoisonDamage = ((TF2_GetMaxHealth(victim)*0.02)+(Unraveling_Rounds_Stacks[attacker]*10.0));
		Strand_PoisonHits[victim] += 0.09;
		
		if (Strand_DamagePenalty[victim] > 0.35)
		{
			Strand_DamagePenalty[victim] -= 0.05;
		}
		if (PoisonDamage > 150.0)
		{
			PoisonDamage = 150.0;
		}
		
		SDKHooks_TakeDamage(victim, attackerweapon, attacker, ((PoisonDamage*Strand_PoisonHits[victim])), DMG_SLASH, attackerweapon, NULL_VECTOR, NULL_VECTOR, true);
	}
}

stock PoisonExplosion(client, victim, clientweapon, Float:radius = 300.0)
{
	if (!IsValidClient(client) || !IsValidClient(victim) || !IsValidEntity(clientweapon)){return;}
	
	if (WepAttribCheck(clientweapon, "strand poison explosion"))
	{
		new Float:Pos1[3];
		GetClientEyePosition(victim, Pos1);
		Pos1[2] -= 30.0;
		
		new particle6 = CreateEntityByName( "info_particle_system" );
		if ( IsValidEntity( particle6 ) )
		{
			TeleportEntity( particle6, Pos1, NULL_VECTOR, NULL_VECTOR );
			DispatchKeyValue( particle6, "effect_name", "gas_can_impact_red" );
			DispatchSpawn( particle6 );
			ActivateEntity( particle6 );
			AcceptEntityInput( particle6, "start" );
			SetVariantString( "OnUser1 !self:Kill::8:-1" );
			AcceptEntityInput( particle6, "AddOutput" );
			AcceptEntityInput( particle6, "FireUser1" );
		}
		
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if (IsValidClient(i) && i != victim && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == GetClientTeam(victim))
			{
				new Float:Pos2[3];
				GetClientEyePosition(i, Pos2);
				Pos2[2] -= 30.0;
					
				new Float: distance = GetVectorDistance(Pos1, Pos2);
				if (distance <= radius)
				{
					decl Handle:Filter2;
					(Filter2 = INVALID_HANDLE);
					Filter2 = TR_TraceRayFilterEx(Pos1, Pos2, MASK_SOLID, RayType_EndPoint, TraceFilterIgnoreSelf, i);
					if (Filter2 != INVALID_HANDLE)
					{
						if (!TR_DidHit(Filter2))
						{
							if (Strand_IsPoisoned[i] == false)
							{
								Strand_IsPoisoned[i] = true;
								Strand_PoisonHits[i] = 1.20;
								Strand_PoisonDuration[i] = GetEngineTime()+2.0;
							}
						}
					}
					CloseHandle(Filter2);
				}
			}
		}
	}
}


stock UnravelingRounds(attacker, victim, attackerweapon, Float:Radius = 250.0, Float:PoisonDuration = 2.0)
{
	if (!IsValidClient(attacker) || !IsValidClient(victim) || !IsValidEntity(attackerweapon)){return;}
	
	if (WepAttribCheck(attackerweapon, "unraveling rounds") && Unraveling_Rounds_Active[attacker])
	{
		new Float:Pos1[3];
		new Float:Pos2[3];
		
		GetClientEyePosition(victim, Pos1);
		Pos1[2] -= 30.0;
		
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if (IsValidClient(i) && i != victim && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == GetClientTeam(victim))
			{
				GetClientEyePosition(i, Pos2);
				Pos2[2] -= 30.0;
				
				new Float: distance = GetVectorDistance(Pos1, Pos2);
				if (distance <= Radius)
				{
					decl Handle:Filter;
					(Filter = INVALID_HANDLE);
					
					Filter = TR_TraceRayFilterEx(Pos1, Pos2, MASK_SOLID, RayType_EndPoint, TraceFilterIgnoreSelf, i);
					
					if (!TR_DidHit(Filter))
					{
						if (!Strand_IsPoisoned[i])
						{
							Strand_IsPoisoned[i] = true;
							Strand_PoisonHits[i] = 1.3;
							Strand_PoisonDuration[i] = GetEngineTime()+PoisonDuration;
						}
					}
				}
			}
		}
	}
}
