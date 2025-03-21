#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <sdkhooks>
#include <UU_StatusEffects>
#include <tf_econ_dynamic>
#include <tf2utils>
#include <custom_status_hud_Elements>
#include <UbUp-PowerSupply>

#include "Elements/Arc.sp"
#include "Elements/Solar.sp"
#include "Elements/Void.sp"
#include "Elements/Stasis.sp"
#include "Elements/Strand.sp"
#include "Elements/OnGameFrame.sp"

//#include "Elements/Shields.sp"
//#include "Elements/Hud.sp"


public OnMapStart()
{
	PrecacheSound(ArcChainSound);
	PrecacheSound(SOUND_EXPLO);
}


//Hooks


public OnClientPutInServer(client)
{
	if (IsValidClient(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage2);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageVoid);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageStrand);
		
		
		
		ChainMax[client] = 0.0;
		Chain_Chance[client] = 0.05;
		ChainDelay[client] = false;
		CanBeChained[client] = true;
		
		
		Explosion_Delay[client] = false;
		Ignition_activator[client] = false;
		
		
		Voided[client] = 0.0;
		Voided_debuff[client] = false;
		VoidDmg_Active[client] = true;
		CanBeVoided[client] = true;
	}
}



public OnPluginStart()
{

	//Register Attributes
	TF2EconDynAttribute attrib = new TF2EconDynAttribute();
	
	//Main Element Attributes
	attrib.SetName("stasis element");
	attrib.SetClass("element_stasis");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	
	attrib.SetName("strand element");
	attrib.SetClass("element_strand");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	
	//Supporting Element Attributes
	
	attrib.SetName("strand poison duration");
	attrib.SetClass("element_strand_poison_duration");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("strand poison explosion");
	attrib.SetClass("element_strand_poison_duration");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("damage bonus vs slowed");
	attrib.SetClass("element_stasis_dmg_vs_slowed");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.Register();
	
	attrib.SetName("damage bonus vs frozen");
	attrib.SetClass("element_stasis_dmg_vs_frozen");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.Register();
	
	attrib.SetName("glacial eruption");
	attrib.SetClass("element_stasis_glacial_eruption");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("headstone");
	attrib.SetClass("element_stasis_headstone");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	
	HookEvent("player_death", Event_Death);
	HookEvent("player_spawn", Event_PlayerreSpawn);
	HookEvent("player_changeclass", Event_PlayerreSpawn);
	HookEvent("post_inventory_application", Event_PlayerreSpawn);
	
	HookEvent("player_spawn", PlayerRespawn);
	HookEvent("player_changeclass", PlayerRespawn);
	HookEvent("post_inventory_application", PlayerRespawn);
	
	
	HookEvent("player_hurt", Event_PlayerhurtStasis);
	
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage2);
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageVoid);
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageStrand);
			
		}
	}
	
	
	CreateTimer(0.1, Deon, _, TIMER_REPEAT);
	
	
	CreateTimer(0.3, Timer_Degen, _, TIMER_REPEAT);
	CreateTimer(0.1, Timer_Thing, _, TIMER_REPEAT);
	
	
	CreateTimer(0.1, Timer_Slow, _, TIMER_REPEAT);
	CreateTimer(0.1, Timer_StackClear, _, TIMER_REPEAT);
	
	
	CreateTimer(0.3, Timer_PoisonDmg, _, TIMER_REPEAT);
	
	
	
	
	
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if (IsValidClient(i))
		{
			
			Scorch[i] = 0.0;
			Scorch_max[i] = 400.0;
			Explosion_Delay[i] = false;
			Ignition_activator[i] = false;
			
			Voided[i] = 0.0;
			Voided_debuff[i] = false;
			VoidDmg_Active[i] = true;
			CanBeVoided[i] = true;
			
			CanBeChained[i] = true;
			ChainDelay[i] = false;
			
			Strand_IsPoisoned[i] = false;
			Strand_PoisonHits[i] = 1.0;
			Strand_DamagePenalty[i] = 1.0;
		}
	}
}



public OnPluginEnd()
{
	UnhookEvent("player_changeclass", Event_PlayerreSpawn);
	UnhookEvent("player_spawn", Event_PlayerreSpawn);
	UnhookEvent("player_death", Event_PlayerreSpawn);
	UnhookEvent("post_inventory_application", Event_PlayerreSpawn);
	
	UnhookEvent("player_changeclass", PlayerRespawn);
	UnhookEvent("player_spawn", PlayerRespawn);
	UnhookEvent("post_inventory_application", PlayerRespawn);

}



public Action PlayerRespawn(Handle event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(client))
	{
		Dmg_VsFrozen[client] = 0.0;
		CanBeChained[client] = true;
		ChainDelay[client] = false;
		
		Voided[client] = 0.0;
		Voided_debuff[client] = false;
		VoidDmg_Active[client] = true;
		CanBeVoided[client] = true;
		
		Strand_IsPoisoned[client] = false;
		Strand_PoisonHits[client] = 1.0;
		Strand_DamagePenalty[client] = 1.0;
		Strand_PoisonDuration[client] = 0.0;
		
	}
}





public Action:OnCustomStatusHUDUpdate2(int client, StringMap entries) 
{
	if (IsValidClient(client))
	{
		char stats[32];
		char str_Scorch[32];
		char str_Slowed[32];
		char str_Frozen[32];
		char str_Poisoned[32];
		
		Format(stats, sizeof(stats), "Status Effects");
		entries.SetString("elements_a", stats);
		if (Scorch[client] > 0.0)
		{
			Format(str_Scorch, sizeof(str_Scorch), "Scorched: %.0f", Scorch[client]);
			entries.SetString("elements_effects_scorch", str_Scorch);
		}
		if (Slowed[client] > 0.0)
		{
			Format(str_Slowed, sizeof(str_Slowed), "Slowed: %.0f", Slowed[client]);
			entries.SetString("elements_effects_stasis_slowed", str_Slowed);
		}
		if (Frozen[client])
		{
			Format(str_Frozen, sizeof(str_Frozen), "Frozen");
			entries.SetString("elements_effects_stasis_frozen", str_Frozen);
		}
		if (Strand_IsPoisoned[client])
		{
			Format(str_Poisoned, sizeof(str_Poisoned), "Poisoned");
			entries.SetString("elements_effects_strand_poisoned", str_Poisoned);
		}
		return Plugin_Changed;
	}
}






//Stocks

stock TF2_GetMaxHealth(iClient)
{
    new maxhealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, iClient);
    return ((maxhealth == -1 || maxhealth == 80896) ? GetEntProp(iClient, Prop_Data, "m_iMaxHealth") : maxhealth);
}

stock EmitSoundFromOrigin(const String:sound[],const Float:orig[3]) // Thx Advanced Weaponiser
{
    EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_FRIDGE,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask) // Thx RavensBro.
{
    return entity > GetMaxClients() || !entity;
}

public bool TraceFilterIgnoreSelf( entity, contentsMask, any:hiok )
{
    if ( entity == hiok || entity > 0 && entity <= MaxClients ) return false; 
    return true; 
}

stock DealDamage(victim, damage, attacker=0, dmg_type=DMG_GENERIC ,String:logname[]="")
{
    if(victim>0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage>0)
    {
        new String:dmg_str[16];
        IntToString(damage,dmg_str,16);
        new String:dmg_type_str[32];
        IntToString(dmg_type,dmg_type_str,32);
        new pointHurt=CreateEntityByName("point_hurt");
        if(pointHurt)
        {
            DispatchKeyValue(victim,"targetname","war3_hurtme");
            DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
            DispatchKeyValue(pointHurt,"Damage",dmg_str);
            DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
            if(!StrEqual(logname,""))
            {
                DispatchKeyValue(pointHurt,"classname",logname);
            }
            DispatchSpawn(pointHurt);
            AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:1);
            DispatchKeyValue(pointHurt,"classname","point_hurt");
            DispatchKeyValue(victim,"targetname","war3_donthurtme");
            RemoveEdict(pointHurt);
        }
    }
}


stock bool WepAttribCheck(c_weapon, const char[] attribname)
{
	if (IsValidEntity(c_weapon))
	{
		new Address:Attrib = TF2Attrib_GetByName(c_weapon, attribname);
		
		if (Attrib!=Address_Null)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	else {return false;}
}

stock float GetWepAttribValue(c_weapon, const char[] attribname)
{
	if (IsValidEntity(c_weapon))
	{
		new Float:AttribValue = 1.0;
		new Address:Attrib = TF2Attrib_GetByName(c_weapon, attribname);
		
		if (Attrib != Address_Null)
		{
			AttribValue = TF2Attrib_GetValue(Attrib);
			
			return AttribValue;
		}
		else{return AttribValue;}
	}
	else{return 0.0;}
}

stock float GetClientAttribValue(client, const char[] attribname)
{
	if (IsValidClient(client))
	{
		new Float:AttribValue = 1.0;
		new Address:Attrib = TF2Attrib_GetByName(client, attribname);
		
		if (Attrib != Address_Null)
		{
			AttribValue = TF2Attrib_GetValue(Attrib);
			
			return AttribValue;
		}
		else{return AttribValue;}
	}
	else{return 0.0;}
}


stock EntityExplosion(owner, float damage, float radius, float pos[3], soundType = 0, bool visual = true, entity = -1, float soundLevel = 0.7,damagetype = DMG_BLAST, weapon = -1, float falloff = 0.0, soundPriority = 80, bool ignition = false)
{
	if(entity == -1 || !IsValidEdict(entity))
		entity = owner;
	int i = -1;
	while ((i = FindEntityByClassname(i, "*")) != -1)
	{
		if(IsValidForDamage(i) && IsOnDifferentTeams(owner,i) && i != entity)
		{
			float targetvec[3];
			float distance;
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", targetvec);
			distance = GetVectorDistance(pos, targetvec, false)
			if(distance <= radius)
			{
				if(IsPointVisible(i, pos,targetvec))
				{
					if(falloff != 0.0)
					{
						float ratio = (1.0-(distance/radius)*falloff);
						if(ratio < 0.5)
							ratio = 0.5;
						if(ratio >= 0.95)
							ratio = 1.0;
						damage *= ratio
					}

					if(IsValidEntity(weapon) && IsValidClient(i))
					{
						SDKHooks_TakeDamage(i,owner,owner,damage, damagetype,weapon,NULL_VECTOR,NULL_VECTOR)
						if(ignition)
							TF2Util_IgnitePlayer(i, owner, 7.0, weapon);
					}
					else
					{
						SDKHooks_TakeDamage(i,owner,owner,damage, damagetype,-1,NULL_VECTOR,NULL_VECTOR, false);
					}
				}
			}
		}
	}
	if(visual)
		CreateParticle(-1, "ExplosionCore_MidAir", pos);
	
	int random = GetRandomInt(1,3)
	switch(soundType)
	{
		case 1:
		{
			if(random == 1){
				//EmitSoundToAll(ExplosionSound1, entity,_,soundPriority,_,soundLevel,_,_,pos);
				//EmitSoundToAll(ExplosionSound1, entity,_,soundPriority,_,soundLevel,_,_,pos);
				//EmitSoundToAll(ExplosionSound1, entity,_,soundPriority,_,soundLevel,_,_,pos);
			}else if(random == 2){
				//EmitSoundToAll(ExplosionSound2, entity,_,soundPriority,_,soundLevel,_,_,pos);
				//EmitSoundToAll(ExplosionSound2, entity,_,soundPriority,_,soundLevel,_,_,pos);
				//EmitSoundToAll(ExplosionSound2, entity,_,soundPriority,_,soundLevel,_,_,pos);
			}else if(random == 3){
				//EmitSoundToAll(ExplosionSound3, entity,_,soundPriority,_,soundLevel,_,_,pos);
				//EmitSoundToAll(ExplosionSound3, entity,_,soundPriority,_,soundLevel,_,_,pos);
				//EmitSoundToAll(ExplosionSound3, entity,_,soundPriority,_,soundLevel,_,_,pos);
			}
		}
		case 2:
		{
			//EmitSoundToAll(SOUND_EXPLO, entity, -1, soundPriority-20, 0, soundLevel-0.15,_,_,pos);
		}
		case 3:
		{
			//EmitSoundToAll(OrnamentExplosionSound, entity, -1, soundPriority, 0, soundLevel,_,_,pos);
		}
		default:
		{
			if(random == 1){
				//EmitSoundToAll(ExplosionSound1, entity,_,soundPriority,_,soundLevel,_,_,pos);
			}else if(random == 2){
				//EmitSoundToAll(ExplosionSound2, entity,_,soundPriority,_,soundLevel,_,_,pos);
			}else if(random == 3){
				//EmitSoundToAll(ExplosionSound3, entity,_,soundPriority,_,soundLevel,_,_,pos);
			}
		}
	}
}


stock bool IsValidForDamage(target)
{
	if (IsValidClient(target) && IsPlayerAlive(target))
	{
		return true;
	}
	if (!IsValidClient(target) && !IsPlayerAlive(target))
	{
		return false;
	}
}

stock bool IsOnDifferentTeams(client1, client2)
{

	if (!IsValidClient(client1) && !IsValidClient(client2))
		return false;
		
	if (IsValidClient(client1) && IsValidClient(client2))
	{
		if (GetClientTeam(client1) != GetClientTeam(client2))
		{
			return true;
		}
		else
		{
			return false;
		}
	}
}

stock bool IsPointVisible(target, float position1[3], float position2[3])
{
	if (!IsValidEdict(target))
	{
		return false;
	}
	
	if (IsValidEdict(target))
	{
		decl Handle:Filter;
		(Filter = INVALID_HANDLE);
	
		Filter = TR_TraceRayFilterEx(position1, position2, MASK_SOLID, RayType_EndPoint, TraceEntityFilterPlayer, target);
		if (Filter != INVALID_HANDLE)
		{
			if (!TR_DidHit(Filter))
			{
				return true;
			}
			else
			{
				return false;
			}
		}
	}
}


stock any:AttachParticle(ent, String:particleType[], Float:time = 0.0, Float:addPos[3]=NULL_VECTOR, Float:addAngle[3]=NULL_VECTOR, bool:bShow = true, String:strVariant[] = "", bool:bMaintain = false) {
    new particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle)) {
        new Float:pos[3];
        new Float:ang[3];
        decl String:tName[32];
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
        AddVectors(pos, addPos, pos);
        GetEntPropVector(ent, Prop_Send, "m_angRotation", ang);
        AddVectors(ang, addAngle, ang);

        Format(tName, sizeof(tName), "target%i", ent);
        DispatchKeyValue(ent, "targetname", tName);

        TeleportEntity(particle, pos, ang, NULL_VECTOR);
        DispatchKeyValue(particle, "targetname", "tf2particle");
        DispatchKeyValue(particle, "parentname", tName);
        DispatchKeyValue(particle, "effect_name", particleType);
        DispatchSpawn(particle);
        SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", ent);
        if (bShow) {
            SetVariantString(tName);
        } else {
            SetVariantString("!activator");
        }
        AcceptEntityInput(particle, "SetParent", ent, particle, 0);
        if (!StrEqual(strVariant, "")) {
            SetVariantString(strVariant);
            if (bMaintain) AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", ent, particle, 0);
            else AcceptEntityInput(particle, "SetParentAttachment", ent, particle, 0);
        }
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        if (time > 0.0) CreateTimer(time, RemoveParticle, particle);
    }
    else LogError("AttachParticle: could not create info_particle_system");
    return particle;
}

public Action:RemoveParticle( Handle:timer, any:particle ) 
{
    if ( particle >= 0 && IsValidEntity(particle) ) 
	{
        new String:classname[32];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false)) 
		{
            AcceptEntityInput(particle, "stop");
            AcceptEntityInput(particle, "Kill");
            particle = -1;
        }
    }
}

stock CreateParticle(iEntity, String:strParticle[], Float:fOffset[3]={0.0, 0.0, 0.0})
{
	new iParticle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(iParticle))
	{
		decl Float:fPosition[3];
		decl Float:fAngles[3];
		decl Float:fForward[3];
		decl Float:fRight[3];
		decl Float:fUp[3];
		
		// Retrieve entity's position and angles
		//GetClientAbsOrigin(iClient, fPosition);
		//GetClientAbsAngles(iClient, fAngles);
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPosition);
		
		// Determine vectors and apply offset
		GetAngleVectors(fAngles, fForward, fRight, fUp);    // I assume 'x' is Right, 'y' is Forward and 'z' is Up
		fPosition[0] += fRight[0]*fOffset[0] + fForward[0]*fOffset[1] + fUp[0]*fOffset[2];
		fPosition[1] += fRight[1]*fOffset[0] + fForward[1]*fOffset[1] + fUp[1]*fOffset[2];
		fPosition[2] += fRight[2]*fOffset[0] + fForward[2]*fOffset[1] + fUp[2]*fOffset[2];
		
		// Teleport and attach to client
		//TeleportEntity(iParticle, fPosition, fAngles, NULL_VECTOR);
		TeleportEntity(iParticle, fPosition, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(iParticle, "effect_name", strParticle);
		
		
		// Spawn and start
		DispatchSpawn(iParticle);
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "Start");
	}
	
	return iParticle;
}

stock CreateBulletTrace(const Float:origin[3], const Float:dest[3], const Float:speed = 6000.0, const Float:startwidth = 0.5, const Float:endwidth = 0.2, const Float:lifetime = 0.5, const String:color[] = "200 200 0")
{
	new entity = CreateEntityByName("env_spritetrail");
	if (entity == -1)
	{
		LogError("Couldn't create entity 'bullet_trace'");
		return -1;
	}
	DispatchKeyValue(entity, "classname", "bullet_trace");
	DispatchKeyValue(entity, "spritename", "materials/sprites/laser.vmt");
	DispatchKeyValue(entity, "renderamt", "255");
	DispatchKeyValue(entity, "rendercolor", color);
	DispatchKeyValue(entity, "rendermode", "5");
	DispatchKeyValueFloat(entity, "startwidth", startwidth);
	DispatchKeyValueFloat(entity, "endwidth", endwidth);
	DispatchKeyValueFloat(entity, "lifetime", lifetime);
	if (!DispatchSpawn(entity))
	{
		AcceptEntityInput(entity, "Kill");
		LogError("Couldn't create entity 'bullet_trace'");
		return -1;
	}
	
	SetEntPropFloat(entity, Prop_Send, "m_flTextureRes", 0.05);
	
	decl Float:vecVeloc[3], Float:angRotation[3];
	MakeVectorFromPoints(origin, dest, vecVeloc);
	GetVectorAngles(vecVeloc, angRotation);
	NormalizeVector(vecVeloc, vecVeloc);
	ScaleVector(vecVeloc, speed);
	
	TeleportEntity(entity, origin, angRotation, vecVeloc);
	
	decl String:_tmp[128];
	FormatEx(_tmp, sizeof(_tmp), "OnUser1 !self:kill::%f:-1", GetVectorDistance(origin, dest) / speed);
	SetVariantString(_tmp);
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
	
	return entity;
}


stock bool IsValidTarget_Arc(c_victim, entity)
{
	if (!IsValidClient(c_victim) || !IsPlayerAlive(c_victim))
		return false;
	
	if (IsValidClient(c_victim) && IsPlayerAlive(c_victim))
	{
		int team = GetEntProp( entity, Prop_Send, "m_iTeamNum" ); 
		if (!TF2_IsPlayerInCondition( c_victim, TFCond_Cloaked ) && !TF2_IsPlayerInCondition( c_victim, TFCond_Ubercharged )
			&& !TF2_IsPlayerInCondition( c_victim, TFCond_Bonked ) && !TF2_IsPlayerInCondition( c_victim, TFCond_Stealthed )
			&& !TF2_IsPlayerInCondition( c_victim, TFCond_BlastImmune ) && !TF2_IsPlayerInCondition( c_victim, TFCond_HalloweenGhostMode )
			&& !TF2_IsPlayerInCondition( c_victim, TFCond_Disguised ) && GetEntProp( c_victim, Prop_Send, "m_nDisguiseTeam" ) != team && CanBeChained[c_victim] == true)
		{
			return true;
		}
	}
}


stock bool IsValidTarget(c_victim, entity)
{
	if (!IsValidClient(c_victim) || !IsPlayerAlive(c_victim))
		return false;
	
	if (IsValidClient(c_victim) && IsPlayerAlive(c_victim))
	{
		int team = GetEntProp( entity, Prop_Send, "m_iTeamNum" ); 
		if (!TF2_IsPlayerInCondition( c_victim, TFCond_Cloaked ) && !TF2_IsPlayerInCondition( c_victim, TFCond_Ubercharged )
			&& !TF2_IsPlayerInCondition( c_victim, TFCond_Bonked ) && !TF2_IsPlayerInCondition( c_victim, TFCond_Stealthed )
			&& !TF2_IsPlayerInCondition( c_victim, TFCond_BlastImmune ) && !TF2_IsPlayerInCondition( c_victim, TFCond_HalloweenGhostMode )
			&& !TF2_IsPlayerInCondition( c_victim, TFCond_Disguised ) && GetEntProp( c_victim, Prop_Send, "m_nDisguiseTeam" ) != team)
		{
			return true;
		}
	}
}


stock GetClosestTarget( entity, owner, float radius)
{
    float TargetDistance = radius; 
    int ClosestTarget = 0; 
    for( new i = 1; i <= MaxClients; i++ ) 
    {
		if (!IsValidClient(i) || !IsPlayerAlive(i)){continue;}
		
        
        float EntityLocation[3], TargetLocation[3]; 
        GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", EntityLocation ); 
        GetClientAbsOrigin( i, TargetLocation ); 
        
        Handle hTrace = TR_TraceRayFilterEx( TargetLocation, EntityLocation, MASK_SOLID, RayType_EndPoint, TraceFilterIgnoreSelf, i ); 
        if( hTrace != INVALID_HANDLE )
        {
            if( TR_DidHit( hTrace ) )
            {
                CloseHandle( hTrace ); 
                continue; 
            }
            
            CloseHandle( hTrace ); 
            
            float distance = GetVectorDistance( EntityLocation, TargetLocation ); 
            if( TargetDistance ) 
			{
                if( distance < TargetDistance ) 
				{
                    ClosestTarget = i; 
                    TargetDistance = distance;          
                }
            }
        }
    }
    return ClosestTarget; 
}
