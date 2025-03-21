#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <dhooks>
#include <events>

#define SOUND_EXPLO	"weapons/explode1.wav"
#define SOUND_PERF	"weapons/dragons_fury_impact_bonus_damage.wav"
#pragma semicolon 1

ConVar g_botlevel;

new Float:CranialSpike[MAXPLAYERS+1] = 0.0;
new Float:CranialSpike_max[MAXPLAYERS+1] = 0.0;

new Float:PerfectFifth[MAXPLAYERS+1] = 0.0;
new Float:PerfectFifth_max[MAXPLAYERS+1] = 0.0;
new bool:PerfectFifth_active[MAXPLAYERS+1];


public OnMapStart()
{
	PrecacheSound(SOUND_EXPLO);
	PrecacheSound(SOUND_PERF);
}

public OnPluginStart()
{
	HookEvent("player_death", Event_Death);
	HookEvent("player_hurt", Event_Playerhurt);
	HookEvent("player_spawn", Event_PlayerreSpawn);
	CreateTimer(0.1, Timer_Thing, _, TIMER_REPEAT);
	for(new i=0; i<=MaxClients; i++)
	{
		CranialSpike[i] = 0.0;
		CranialSpike_max[i] = 5.0;
		PerfectFifth[i] = 0.0;
		PerfectFifth_max[i] = 4.0;
		PerfectFifth_active[i] = false;
		if (IsValidClient(i))
		{
			SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
		}
	}
}

public OnPluginEnd()
{
	UnhookEvent("player_death", Event_Death);
	UnhookEvent("player_hurt", Event_Playerhurt);
	UnhookEvent("player_spawn", Event_PlayerreSpawn);
	for(new i=0; i<=MaxClients; i++)
	{
		CranialSpike[i] = 0.0;
		CranialSpike_max[i] = 5.0;
		PerfectFifth[i] = 0.0;
		PerfectFifth_max[i] = 4.0;
		PerfectFifth_active[i] = false;
		if (IsValidClient(i))
		{
			SDKUnhook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
	for(new i=0; i<=MaxClients; i++)
	{
		PerfectFifth[i] = 0.0;
		PerfectFifth_max[i] = 4.0;
		PerfectFifth_active[i] = false;
	}
}

public OnClientDisconnect(client)
{
    if(IsClientInGame(client))
    {
		SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
	}
}

public Action:Timer_Thing(Handle:Timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			if (CranialSpike[client] > CranialSpike_max[client])
			{
				CranialSpike[client] = CranialSpike_max[client];
			}
			if (PerfectFifth[client] > PerfectFifth_max[client])
			{
				PerfectFifth[client] = PerfectFifth_max[client];
			}
		}
	}
}
public bool:TraceEntityFilterPlayer(entity, contentsMask) // Thx RavensBro.
{
    return entity > GetMaxClients() || !entity;
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

public Event_Playerhurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new killer=GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (IsValidClient(killer))
	{
		new Wile = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(Wile))
		{
			//if (PerfectFiftho!=Address_Null)
			//{
				//PerfectFifth[client] += 1.0;
				//if (PerfectFifth[client] == 4.0)
				//{
					//PerfectFifth_active[client] = true;
				//}
			//}
		}
	}
}

public Event_PlayerreSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		CranialSpike[client] = 0.0;
		CranialSpike_max[client] = 5.0;
		PerfectFifth[client] = 0.0;
		PerfectFifth_max[client] = 4.0;
		PerfectFifth_active[client] = false;
	}
}

public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer=GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim=GetClientOfUserId(GetEventInt(event, "userid"));
	if (victim != killer && IsValidClient(killer))
	{
		if (CranialSpike[killer] > 0.0)
		{
			CranialSpike[killer] = 0.0;
		}
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsValidClient(attacker))
	{
		new Tile = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(Tile))
		{
			new ItemDefinition = GetEntProp(Tile, Prop_Send, "m_iItemDefinitionIndex");
			if (ItemDefinition == 19 || 206 || 308 || 996 || 1007 || 1151)
			{
				new Address:FullCourt = TF2Attrib_GetByName(Tile, "increase buff duration");
				if (FullCourt!=Address_Null)
				{
					new Float:MinimunRange = TF2Attrib_GetValue(FullCourt);
					new Float:Pos3[3];
					Pos3[2] -= 30.0;
					int ent = -1;
					while((ent = FindEntityByClassname(ent, "tf_projectile_pipe")) != -1) 
					{
						GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", Pos3);
					}
					if(victim != attacker && IsClientInGame(attacker) && IsPlayerAlive(attacker) && GetClientTeam(attacker))
					{
						new Float:Pos4[3];
						GetClientEyePosition(attacker, Pos4);
						Pos4[2] -= 30.0;
						new Float:Distance = GetVectorDistance(Pos3, Pos4);
					
						if (Distance > MinimunRange && Distance < 1500.0)
						{
							new Float:Mult = SquareRoot(Distance*0.80)*0.10;
							damage *= Mult;
							PrintToConsole(attacker, "%0.f Full Court distance. Damage multiplied by: %.2f", Distance, Mult);
						}
						if (Distance <= MinimunRange)
						{
							damage *= 1.0;
						}
					}
				}
			}
			new Address:cranialspike = TF2Attrib_GetByName(Tile, "recipe component defined item 8");
			if (cranialspike != Address_Null)
			{
				damagetype |= DMG_RADIUS_MAX;
				if (damagetype & DMG_USE_HITLOCATIONS)
				{
					CranialSpike[attacker] += 1.0;
					if (CranialSpike[attacker] > 0.0 && damagetype & DMG_USE_HITLOCATIONS)
					{
						damage *= CranialSpike[attacker]*Pow(1.1,2.0);
					}	
					else
					{
						damage *= 1.0;
					}
				}
			}
			new Address:PerfectFiftho = TF2Attrib_GetByName(Tile, "recipe component defined item 2");
			if (PerfectFiftho!=Address_Null && PerfectFifth_active[victim] == true)
			{
				CreateTimer(0.3, Timer_Explosion);
				EmitSoundFromOrigin(SOUND_PERF, damagePosition);
				new particle6 = CreateEntityByName( "info_particle_system" );
				if ( IsValidEntity( particle6 ) )
				{
					TeleportEntity( particle6, damagePosition, NULL_VECTOR, NULL_VECTOR );
					DispatchKeyValue( particle6, "effect_name", "dragons_fury_effect_parent" );
					DispatchSpawn( particle6 );
					ActivateEntity( particle6 );
					AcceptEntityInput( particle6, "start" );
					SetVariantString( "OnUser1 !self:Kill::8:-1" );
					AcceptEntityInput( particle6, "AddOutput" );
					AcceptEntityInput( particle6, "FireUser1" );
				}
			}
		}
		
	}
	return Plugin_Changed;
}

public Action:Timer_Explosion(Handle:timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			for ( new i3 = 1; i3 <= MaxClients; i3++ )
			{
				if(IsValidClient(i3) && client != i3)
				{
					new Float:Pos2[3];
					GetClientEyePosition(i3, Pos2);
					Pos2[2] -= 30.0;
				
					EmitSoundFromOrigin(SOUND_EXPLO, Pos2);
					new particle6 = CreateEntityByName( "info_particle_system" );
					if ( IsValidEntity( particle6 ) )
					{
						TeleportEntity( particle6, Pos2, NULL_VECTOR, NULL_VECTOR );
						DispatchKeyValue( particle6, "effect_name", "ExplosionCore_MidAir" );
						DispatchSpawn( particle6 );
						ActivateEntity( particle6 );
						AcceptEntityInput( particle6, "start" );
						SetVariantString( "OnUser1 !self:Kill::8:-1" );
						AcceptEntityInput( particle6, "AddOutput" );
						AcceptEntityInput( particle6, "FireUser1" );
					}
				
					if (PerfectFifth_active[i3] == true && client != i3 && IsClientInGame(i3) && IsPlayerAlive(i3))
					{
						DealDamage(i3, RoundToFloor(50.0), client, DMG_BLAST ,"pumpkindeath");
						PerfectFifth[i3] = 0.0;
						PerfectFifth_active[i3] = false;
						KillTimer(timer);
					}
				}
			}
		}
	}
}

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

stock EmitSoundFromOrigin(const String:sound[],const Float:orig[3]) // Thx Advanced Weaponiser
{
    EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_FRIDGE,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}

stock TF2_GetMaxHealth(iClient)
{
    new maxhealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, iClient);
    return ((maxhealth == -1 || maxhealth == 80896) ? GetEntProp(iClient, Prop_Data, "m_iMaxHealth") : maxhealth);
}