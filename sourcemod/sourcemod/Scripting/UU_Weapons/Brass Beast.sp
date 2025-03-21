bool HitBonusActive[MAXPLAYERS+1] = {false, ...};

int HitBonusExplo_Counter[MAXPLAYERS+1] = {0, ...};

int HitCounter[MAXPLAYERS+1] = {0, ...};



new particle_a = -1;

#define SOUND_EXPLO	"weapons/explode1.wav"

/*
public Action:OnTakeDamageBrassBeast(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsValidClient(attacker) && IsValidClient(victim))
	{
		new clientweapon =  weapon;
		
		if (IsValidEntity(clientweapon))
		{	
			if (WepAttribCheck(clientweapon, "thunderlord"))
			{
				if (HitCounter[attacker] < 30)
				{
					HitCounter[attacker] += 1;
				}
				if (HitCounter[attacker] == 30)
				{
					HitBonusActive[attacker] = true;
					CreateTimer(5.0, Timer_HitBonus, attacker);
				}
				if (HitBonusActive[attacker])
				{
					if (HitBonusExplo_Counter[attacker] < 5)
					{
						HitBonusExplo_Counter[attacker] += 1;
					}
				}
				
				if (HitBonusActive[attacker])
				{
					damage *= 1.30;
					for ( new client = 1; client <= MaxClients; client++ )
					{
						if (IsValidClient(client) && client != attacker)
						{
							if (GetClientTeam(client) == GetClientTeam(victim))
							{
								new Handle:Tray = INVALID_HANDLE;
								
								if (Tray == INVALID_HANDLE && damagetype & DMG_BULLET && HitBonusExplo_Counter[attacker] == 5)
								{
									Explode(attacker, victim, client, clientweapon, 450.0, (120.0+damage*0.40), Tray);
									HitBonusExplo_Counter[attacker] = 0;
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Changed;
}
*/

public Action:Timer_HitBonus(Handle:Timer, any:attacker)
{
	if (IsValidClient(attacker))
	{
		new clientweapon =  GetPlayerWeaponSlot(attacker,0);
		
		if (IsValidEntity(clientweapon))
		{	
			if (WepAttribCheck(clientweapon, "thunderlord"))
			{
				if (HitBonusActive[attacker])
				{
					HitBonusActive[attacker] = false;
					HitCounter[attacker] = 0;
					HitBonusExplo_Counter[attacker] = 0;
				}
			}
			if (WepAttribCheck(clientweapon, "abbadon"))
			{
				if (HitBonusActive[attacker])
				{
					HitBonusActive[attacker] = false;
					HitCounter[attacker] = 0;
					HitBonusExplo_Counter[attacker] = 0;
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