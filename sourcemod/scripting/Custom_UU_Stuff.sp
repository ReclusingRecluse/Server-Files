#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <dhooks>
#include <events>
#include <customweaponstf>
#include <clientprefs>
#include <stocksoup/tf/entity_prop_stocks>

#define spirite "spirites/zerogxplode.spr"

#pragma semicolon 1

new Float:ml_AttackerHealth[MAXPLAYERS+1] = 0.0;
new Float:ml_VictimHealth[MAXPLAYERS+1] = 0.0;

new bool:hooked[MAXPLAYERS+1];
new bool:CannotHome[MAXPLAYERS+1] = {false, ...};

public OnClientPutInServer(client)
{
	//SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
	ml_VictimHealth[client] = 0.0;
	ml_AttackerHealth[client] = 0.0;
}

public OnPluginEnd()
{
	for(new client = 0; client < MaxClients; client++)
	{
		if(!IsValidClient(client)){continue;}
		if (hooked[client] == true)
		{
			hooked[client] = false;
			//SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
		}
	}
}

public OnPluginStart()
{
	for(new i=0; i<=MaxClients; i++)
	{
		if(!IsValidClient(i)){continue;}
		if (hooked[i] == false)
		{
			hooked[i] = true;
			//SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
		}
	}
}

public OnGameFrame()
{
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if (IsClientInGame(i))
		{
			int vweapon = GetPlayerWeaponSlot(i,2);
			int nweapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
			if (IsValidEntity(vweapon))
			{
				new Address:SentryHomingRocket = TF2Attrib_GetByName(vweapon, "hide crate series number");
				if (SentryHomingRocket!=Address_Null)
				{
					if (IsValidOwner(i, "tf_projectile_sentryrocket"))
					{
						int type = 1;
						float radius = TF2Attrib_GetValue(SentryHomingRocket);
						SetHomingProjectile( i, "tf_projectile_sentryrocket", radius, type);
					}
					else
					{
						return;
					}
				}
			}
			if (IsValidEntity(nweapon))
			{
				new Address:DirectHitHoming = TF2Attrib_GetByName(nweapon, "add onhit addammo");
				if (DirectHitHoming!=Address_Null)
				{
					int type = 1;
					float radius = TF2Attrib_GetValue(DirectHitHoming);
					
					if (IsValidOwner(i, "tf_projectile_rocket"))
					{
						SetHomingProjectile( i, "tf_projectile_rocket", radius, type);
					}
					else if (IsValidOwner(i, "tf_projectile_arrow"))
					{
						SetHomingProjectile( i, "tf_projectile_arrow", radius, type);
					}
					else if (IsValidOwner(i, "tf_projectile_pipe"))
					{
						SetHomingProjectile( i, "tf_projectile_pipe", radius, type);
					}
					else if (IsValidOwner(i, "tf_projectile_healing_bolt"))
					{
						SetHomingProjectile( i, "tf_projectile_healing_bolt", radius, type);
					}
					else
					{
						return;
					}
				}
			}
		}
	}
}

stock bool:IsValidOwner(client, const char[] classname)
{
	int entity = -1; 
	while( ( entity = FindEntityByClassname( entity, classname ) )!= INVALID_ENT_REFERENCE )
	{
		int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		
		if (!IsValidEntity(owner)){return false;}
		
		if (owner == client && IsValidClient(client))
		{
			return true;
		}
	}
}

stock SetHomingProjectile( client, const char[] classname, float radius, int type_a )
{
	int entity = -1; 
	while( ( entity = FindEntityByClassname( entity, classname ) )!= INVALID_ENT_REFERENCE )
	{
        int owner = GetEntPropEnt( entity, Prop_Data, "m_hOwnerEntity" ); 
	if(StrEqual(classname, "tf_projectile_sentryrocket")) owner = GetEntPropEnt(owner, Prop_Send, "m_hBuilder");
        if ( !IsValidEntity( owner ) ) continue; 
        if ( owner == client )
        {
            int Target = GetClosestTarget( entity, owner ); 
            if ( !Target ) continue; 

            float EntityPos[3], TargetPos[3]; 
            GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", EntityPos ); 
            GetClientAbsOrigin( Target, TargetPos ); 
            float distance = GetVectorDistance( EntityPos, TargetPos ); 
            
            if( distance <= radius )
            {
                float ProjLocation[3], ProjVector[3], BaseSpeed, NewSpeed, ProjAngle[3], AimVector[3], InitialSpeed[3]; 
                
                GetEntPropVector( entity, Prop_Send, "m_vInitialVelocity", InitialSpeed ); 
                if ( GetVectorLength( InitialSpeed ) < 10.0 ) GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", InitialSpeed ); 
                BaseSpeed = GetVectorLength( InitialSpeed ) * 0.5; 
                
                GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", ProjLocation ); 
                GetClientAbsOrigin( Target, TargetPos ); 
                TargetPos[2] += ( 40.0 + Pow( distance, 2.0 ) / 10000.0 ); 
                
                MakeVectorFromPoints( ProjLocation, TargetPos, AimVector ); 
                
                if ( type_a == 0 ) GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", ProjVector ); 
                else SubtractVectors( TargetPos, ProjLocation, ProjVector ); 
                AddVectors( ProjVector, AimVector, ProjVector ); 
                NormalizeVector( ProjVector, ProjVector ); 
                
                GetEntPropVector( entity, Prop_Data, "m_angRotation", ProjAngle ); 
                GetVectorAngles( ProjVector, ProjAngle ); 
                
                NewSpeed = ( BaseSpeed * 2.0 ) + GetEntProp( entity, Prop_Send, "m_iDeflected" ) * BaseSpeed * 1.1; 
                ScaleVector( ProjVector, NewSpeed ); 
                
                TeleportEntity( entity, NULL_VECTOR, ProjAngle, ProjVector ); 
            }
        }
    }   
}
stock GetClosestTarget( entity, owner)
{
    float TargetDistance = 0.0; 
    int ClosestTarget = 0; 
    for( new i = 1; i <= MaxClients; i++ ) 
    {
        if ( !IsValidForHoming( i, owner, entity) ) continue; 
        
        float EntityLocation[3], TargetLocation[3]; 
        GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", EntityLocation ); 
        GetClientAbsOrigin( i, TargetLocation ); 
        
        Handle hTrace = TR_TraceRayFilterEx( TargetLocation, EntityLocation, MASK_SOLID, RayType_EndPoint, TraceFilterIgnoreSelf, entity ); 
        if( hTrace != INVALID_HANDLE )
        {
            if( TR_DidHit( hTrace ) )
            {
                CloseHandle( hTrace ); 
                continue; 
            }
            
            CloseHandle( hTrace ); 
            
            float distance = GetVectorDistance( EntityLocation, TargetLocation ); 
            if( TargetDistance ) {
                if( distance < TargetDistance ) {
                    ClosestTarget = i; 
                    TargetDistance = distance;          
                }
            } else {
                ClosestTarget = i; 
                TargetDistance = distance; 
            }
        }
    }
    return ClosestTarget; 
}
stock bool IsValidForHoming( client, owner, entity)
{
    if ( IsValidClient( owner ) && IsValidClient( client ) && IsValidEntity( entity ) )
    {
        float OwnerPos[3], TargetPos[3]; 
        GetClientAbsOrigin( owner, OwnerPos ); 
        GetClientAbsOrigin( client, TargetPos ); 
        float distance_d = GetVectorDistance( OwnerPos, TargetPos ); 
        if ( distance_d <= 146.0 ) return false; 
    
        int team = GetEntProp( entity, Prop_Send, "m_iTeamNum" ); 
        if ( IsPlayerAlive( client ) && client != owner && GetClientTeam( owner ) != GetClientTeam( client ) && CannotHome[client] == false )
        {
            if ( !TF2_IsPlayerInCondition( client, TFCond_Cloaked ) && !TF2_IsPlayerInCondition( client, TFCond_Ubercharged )
                && !TF2_IsPlayerInCondition( client, TFCond_Bonked ) && !TF2_IsPlayerInCondition( client, TFCond_Stealthed )
                && !TF2_IsPlayerInCondition( client, TFCond_BlastImmune ) && !TF2_IsPlayerInCondition( client, TFCond_HalloweenGhostMode )
                && !TF2_IsPlayerInCondition( client, TFCond_Disguised ) && GetEntProp( client, Prop_Send, "m_nDisguiseTeam" ) != team )
            {
               return true;
            }
        }
    }
    
    return false; 
}

public bool TraceFilterIgnoreSelf( entity, contentsMask, any:hiok )
{
    if ( entity == hiok || entity > 0 && entity <= MaxClients ) return false; 
    return true; 
}

stock bool IsValidClient( client, bool replaycheck = true )
{
    if ( client <= 0 || client > MaxClients ) return false; 
    if ( !IsClientInGame( client ) ) return false; 
    if ( !IsPlayerAlive( client ) ) return false; 
    return true; 
}

fireProjectile(Float:vPosition[3], Float:vAngles[3] = NULL_VECTOR, Float:flSpeed = 1100.0, Float:flDamage = 90.0, iTeam, client)
{
	new String:strClassname[32] = "";
	new String:strEntname[32] = "";

	strClassname = "CTFProjectile_Rocket";
	strEntname = "tf_projectile_rocket";

	new iRocket = CreateEntityByName(strEntname);
	
	if(!IsValidEntity(iRocket))
		return -1;
	
	decl Float:vVelocity[3];
	decl Float:vBuffer[3];
	
	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
	
	vVelocity[0] = vBuffer[0]*flSpeed;
	vVelocity[1] = vBuffer[1]*flSpeed;
	vVelocity[2] = vBuffer[2]*flSpeed;
	
	SetEntPropEnt(iRocket, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(iRocket,    Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= 5)? 1 : 0, 1);
	SetEntProp(iRocket,    Prop_Send, "m_iTeamNum",     iTeam, 1);
	SetEntData(iRocket, FindSendPropOffs(strClassname, "m_nSkin"), (iTeam-2), 1, true);

	SetEntDataFloat(iRocket, FindSendPropOffs(strClassname, "m_iDeflected") + 4, flDamage, true); // set damage
	TeleportEntity(iRocket, vPosition, vAngles, vVelocity);

	SetVariantInt(iTeam);
	AcceptEntityInput(iRocket, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(iRocket, "SetTeam", -1, -1, 0); 
	
	DispatchSpawn(iRocket);
	
	return iRocket;
}

stock TF2_GetMaxHealth(iClient)
{
    new maxhealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, iClient);
    return ((maxhealth == -1 || maxhealth == 80896) ? GetEntProp(iClient, Prop_Data, "m_iMaxHealth") : maxhealth);
}


	