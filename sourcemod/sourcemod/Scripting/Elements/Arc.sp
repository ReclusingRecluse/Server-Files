new Float:Chain[MAXPLAYERS+1];

new Float:ChainMax[MAXPLAYERS+1];

bool ChainDelay[MAXPLAYERS+1] = {false, ...};

bool CanBeChained[MAXPLAYERS+1] = {false, ...};

new TargetClient;
new PreviousVictim;
//new ChainTarget;

#define ArcChainSound		"ambient/halloween/thunder_04.wav"
#define MAXCHAINTARGETS 1

#include "UU_Weapons/Flare gun.sp"
#define SOUND_EXPLO	"weapons/explode1.wav"
int particle_a = -1;

//Functions

//public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)


//public Event_PlayerhurtArc(Handle:event, const String:name[], bool:dontBroadcast)

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	
	if (IsValidClient(attacker))
	{
		new ArcGun = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(ArcGun))
		{
			if (IsValidClient(attacker) && WepAttribCheck(ArcGun, "throwable particle trail only"))
			{
				if (GetRandomFloat(0.0,1.0) <= GetWepAttribValue(ArcGun, "throwable particle trail only"))
				{
					//PreviousVictim = victim;
					//PrintToChat(attacker, "previous victim %d", PreviousVictim);
					
					new Float:Pos1[3];
					GetClientEyePosition(victim, Pos1);
					Pos1[2] -= 30.0;
					
					
					for ( new i = 1; i <= MaxClients; i++ )
					{
						if(IsValidClient(i) && GetClientTeam(i) != GetClientTeam(attacker) && i != victim && i != PreviousVictim)
						{
							new Float:Pos2[3];
							GetClientEyePosition(i, Pos2);
							Pos2[2] -= 30.0;
							
							new Float: distance = GetVectorDistance(Pos1, Pos2);
							if (distance < 400.0)
							{
								//int target = GetClosestTarget(i, PreviousVictim);
								
								if (IsValidTarget(i, attacker))
								{
									//PrintToChat(attacker, "Client %d is closest to victim %d", i, PreviousVictim);
									decl Handle:Filter;
									(Filter = INVALID_HANDLE);
								
									Filter = TR_TraceRayFilterEx(Pos1, Pos2, MASK_SOLID, RayType_EndPoint, TraceFilterIgnoreSelf, i);
									if (Filter != INVALID_HANDLE)
									{
										if (!TR_DidHit(Filter) && ChainDelay[attacker] == false)
										{
											int target = GetClosestTarget(i, victim, 400.0);
											
											ArcChainDamage(attacker, victim, target, ArcGun, damage, Filter);
										}
									}
									CloseHandle(Filter);
								}
							}
						}
					}
				}
			}
		}
	}
}



stock ArcChainDamage(attacker, victim, i, ArcGun, float damage, Handle TRay_hdl)
{
	if (!IsValidClient(attacker) || !IsValidClient(victim) || !IsValidEntity(ArcGun) || !IsValidClient(i))
	{
		return;
	}
	
	if (!IsOnlyTarget(attacker, victim, TRay_hdl, 400.0))
	{
		CreateTimer(0.5, Timer_chainreset);
		new Float:position1[3];
		new Float:position2[3];
		
		
		GetClientEyePosition(victim, position1);
		position1[2] -= 30.0;
		
		GetClientEyePosition(i, position2);
		position2[2] -= 30.0;
		
		PreviousVictim = i;
		//PrintToChat(attacker, "chain victim %d", PreviousVictim);
		
		
		EmitSoundFromOrigin(ArcChainSound, position1);
		CreateBulletTrace(position1, position2, 1100.0, 25.0, 18.0, 10.0, "0 155 255");
		
		if (WepAttribCheck(ArcGun, "flare gun extreme"))
		{
			SDKHooks_TakeDamage(i, ArcGun, attacker, ((5.0+damage*0.79)*(1.0+Chain_Chance[attacker]))*Chain[attacker], DMG_SHOCK, ArcGun, NULL_VECTOR, NULL_VECTOR, false);
		}
		if (WepAttribCheck(ArcGun, "arc damage chain increase per chain"))
		{
			SDKHooks_TakeDamage(i, ArcGun, attacker, ((5.0+damage*0.30)+(3*Chain[attacker])), DMG_SHOCK, ArcGun, NULL_VECTOR, NULL_VECTOR, false);
		}
		else
		{
			SDKHooks_TakeDamage(i, ArcGun, attacker, (5.0+damage*0.79), DMG_SHOCK, ArcGun, NULL_VECTOR, NULL_VECTOR, false);
		}
	}
	else
	{
		if (WepAttribCheck(ArcGun, "arc explode on last chain"))
		{
			if (IsValidClient(TargetClient) && IsPlayerAlive(TargetClient) && TargetClient != victim)
			{
				Explode(attacker, TargetClient, i, ArcGun, 700.0, (30+damage*0.30)+(3*Chain[attacker]), TRay_hdl);
				TargetClient = 0;
			}
		}
	}
}
	
	
stock bool IsOnlyTarget(attacker, int target, Handle TRay_hdl, float radius)
{

	if (!IsValidClient(target) || TRay_hdl == INVALID_HANDLE)
	{
		return false;
	}
	
	new Float:targetpos[3];
	new Float:nexttargetpos[3];
	new Float:distance;
	

	GetClientEyePosition(target, targetpos);
	targetpos[2] -= 30.0;
	
	
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if (IsValidClient(i))
		{
			int nexttarget = GetClosestTarget(i, target, 500.0);
			
			if (GetClientTeam(nexttarget) == GetClientTeam(target))
			{
	
				GetClientEyePosition(nexttarget, nexttargetpos);
				nexttargetpos[2] -= 30.0;
				
				distance = GetVectorDistance(targetpos, nexttargetpos);
				
				if (distance < radius){
				
					TRay_hdl = TR_TraceRayFilterEx(targetpos, nexttargetpos, MASK_SOLID, RayType_EndPoint, TraceFilterIgnoreSelf, nexttarget);
					if (IsValidTarget(nexttarget, attacker) && CanBeChained[nexttarget] == true && Chain[attacker] < ChainMax[attacker] )
					{
						if (!TR_DidHit(TRay_hdl))
						{
							Chain[attacker] += 1.0;
							CanBeChained[nexttarget] = false;
							
							//PrintToChat(attacker, "Chained to client %d", nexttarget);
							
							PreviousVictim = nexttarget;
							TargetClient = nexttarget;
							
							CloseHandle(TRay_hdl); 
							return false;
						}
					}
					else
					{
						TargetClient = PreviousVictim;
						//PrintToChat(attacker, "No Valid Targets around Client %d", TargetClient);
						CloseHandle(TRay_hdl); 
						return true;
					}
					//TargetClient = GetClosestTarget( nexttarget, target);
				}
			}
		}
	}
}


stock Explode(attacker, origin, target, c_weapon, float Radius = 600.0, float Damage = 50.0, Handle TRay_hdl)
{
	if (!IsValidEntity(origin) || !IsValidEntity(target) || !IsValidEntity(c_weapon))
	{
		return;
	}
	
	new Float:originpos[3];
	new Float:targetpos[3];
	new Float:distance;
	
	GetClientEyePosition(origin, originpos);
	originpos[2] -= 30.0;
	
	GetClientEyePosition(target, targetpos);
	targetpos[2] -= 30.0;
	
	distance = GetVectorDistance(originpos, targetpos);
	
	particle_a = CreateEntityByName( "info_particle_system" );
	if ( IsValidEdict( particle_a ) )
	{
		TeleportEntity( particle_a, originpos, NULL_VECTOR, NULL_VECTOR );
		DispatchKeyValue( particle_a, "effect_name", "ExplosionCore_MidAir" );
		DispatchSpawn( particle_a );
		ActivateEntity( particle_a );
		AcceptEntityInput( particle_a, "start" );
		SetVariantString( "OnUser1 !self:Kill::8:-1" );
		AcceptEntityInput( particle_a, "AddOutput" );
		AcceptEntityInput( particle_a, "FireUser1" );
	}
	
	if (distance <= Radius){
		TRay_hdl = TR_TraceRayFilterEx(originpos, targetpos, MASK_SOLID, RayType_EndPoint, TraceEntityFilterPlayer, target);
		if (!TR_DidHit(TRay_hdl) && IsValidTarget(target, attacker))
		{
			SDKHooks_TakeDamage(target, c_weapon, attacker, Damage, DMG_BLAST, c_weapon, NULL_VECTOR, NULL_VECTOR, true);
			EmitSoundToAll(SOUND_EXPLO, origin);
		}
		CloseHandle(TRay_hdl); 
	}
}
	
	

public Action:Deon(Handle:Timer)
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			if (Chain[client] > ChainMax[client])
			{
				Chain[client] = ChainMax[client];
			}
			if (Chain[client] == ChainMax[client])
			{
				CreateTimer(1.0, Timer_reset);
			}
			
			new ArcGun = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (IsValidEntity(ArcGun))
			{
				if (WepAttribCheck(ArcGun, "arc damage chain max"))
				{
					ChainMax[client] = GetWepAttribValue(ArcGun, "arc damage chain max");
				}
				else
				{
					ChainMax[client] = 4.0;
				}
			}
		}
	}
}

public Action:Timer_reset(Handle:Timer)
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (Chain[client] == ChainMax[client])
		{
			Chain[client] = 0.0;
		}
	}
}

public Action:Timer_chainreset(Handle:Timer)
{
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if (IsValidClient(i))
		{
			if (CanBeChained[i] == false)
			{
				CanBeChained[i] = true;
			}
		}
	}
}