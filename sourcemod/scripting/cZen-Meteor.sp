#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <CustomClip>

#define DynamiteShoot	"mvm/giant_soldier/giant_soldier_rocket_shoot.wav"

#define DynamiteExplosion	"mvm/giant_soldier/giant_soldier_rocket_explode.wav"
#define DynamiteExplosion2	"weapons/explode3.wav"

Handle g_SyncDisplay;

public OnMapStart()
{
	PrecacheSound(DynamiteShoot);
	PrecacheSound(DynamiteExplosion);
	PrecacheSound(DynamiteExplosion2);
}

stock EmitSoundFromOrigin(const String:sound[],const Float:orig[3]) // Thx Advanced Weaponiser
{
    EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
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

new bool:DynamiteActive[MAXPLAYERS+1];

new Float:HitCounter[MAXPLAYERS+1];


new bool:Detection[MAXPLAYERS+1];

public OnPluginStart()
{
	HookEvent("player_changeclass", Event_PlayerreSpawn);
	HookEvent("post_inventory_application", Event_PlayerreSpawn);
	HookEvent("player_spawn", Event_PlayerreSpawn);
	HookEvent("player_death", Event_PlayerreSpawn);
	
	g_SyncDisplay = CreateHudSynchronizer();
	
	CreateTimer(0.1, AmmoShow, _, TIMER_REPEAT);
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			DynamiteActive[client] = false;
			IsReloading[client] = false;
			Detection[client] = false;
			HitCounter[client] = 0.0;
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage_player);
		}
	}
}

public OnPluginEnd()
{
	UnhookEvent("player_changeclass", Event_PlayerreSpawn);
	UnhookEvent("player_spawn", Event_PlayerreSpawn);
	UnhookEvent("post_inventory_application", Event_PlayerreSpawn);
}

public OnClientPutInServer(client)
{
	if (IsValidClient(client))
	{
		DynamiteActive[client] = false;
		HitCounter[client] = 0.0;
		IsReloading[client] = false;
		Detection[client] = false;
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage_player);
	}
}

public OnEntityCreated(Ent, const String:cls[])
{
	if (StrEqual(cls, "obj_sentrygun") || StrEqual(cls, "obj_dispenser") || StrEqual(cls, "tank_boss") || StrEqual(cls, "obj_teleporter")/* || StrEqual(cls, "obj_attachment_sapper")*/)
	{
		SDKHook(Ent, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Event_PlayerreSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		Detection[client] = false;
		if (Detection[client] == false)
		{
			CreateTimer(0.2, Timer_Detect);
		}
	}
}

public Action:Timer_Detect(Handle:Timer)
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client) && IsPlayerAlive(client) && Detection[client] == false)
		{
			Detection[client] = true;
			CreateTimer(0.2, Change_Detect, client);
			ZenMeteorApply(client);
		}
	}
}

public Action:Change_Detect(Handle:Timer, any:client)
{
	if (IsValidClient(client))
	{
		ZenMeteorApply(client);
	}
}

public Action:AmmoShow(Handle:Timer)
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			new Meteor = GetPlayerWeaponSlot(client,0);
		
			if (IsValidEntity(Meteor))
			{
				new ItemDefinition = GetEntProp(Meteor, Prop_Send, "m_iItemDefinitionIndex");
				{
					if (ItemDefinition == 14 || 201 || 230 || 402 || 526 || 664 || 752 || 792 || 851)
					{
						new Address:Dynamite = TF2Attrib_GetByName(Meteor, "mod demo buff type");
					
						if (Dynamite != Address_Null)
						{
							int PrimaryAmmoType;
							PrimaryAmmoType = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimaryAmmoType);
						
							decl String:ArmorLeft[32]
							Format(ArmorLeft, sizeof(ArmorLeft), "Ammo %i", PrimaryAmmoType); 
							SetHudTextParams(0.65, -0.2, 0.5, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, g_SyncDisplay, "%s", ArmorLeft);
							
							if (HitCounter[client] > 3.0)
							{
								HitCounter[client] = 3.0;
							}
							if (HitCounter[client] == 3.0 && DynamiteActive[client] == false)
							{
								DynamiteWithALaserBeam(client);
							}
							if (HitCounter[client] == 0.0)
							{
								DynamiteActive[client] = false;
								DynamiteRemove(client);
							}
						}
					}
				}
			}
		}
	}
}

ZenMeteorApply(client)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && Detection[client] == true)
	{
		DynamiteActive[client] = false;
		HitCounter[client] = 0.0;
		IsReloading[client] = false;
		
		new Meteor = GetPlayerWeaponSlot(client,0);
		
		if (IsValidEntity(Meteor))
		{
			new ItemDefinition = GetEntProp(Meteor, Prop_Send, "m_iItemDefinitionIndex");
			{
				if (ItemDefinition == 14 || 201 || 230 || 402 || 526 || 664 || 752 || 792 || 851)
				{
					new Address:Dynamite = TF2Attrib_GetByName(Meteor, "mod demo buff type");
					
					if (Dynamite != Address_Null)
					{
						CreateTimer(0.2, Zen_Apply);
						
						if (g_Timer[client] != INVALID_HANDLE)
						{
							KillTimer(g_Timer[client]);
							g_Timer[client] = INVALID_HANDLE;
						}
					}
				}
			}
		}
	}
}

int ZenClip[MAXPLAYERS+1] = {0, ...};
public Action:Zen_Apply(Handle:Timer)
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			new Meteor = GetPlayerWeaponSlot(client,0);
		
			if (IsValidEntity(Meteor))
			{
				new ItemDefinition = GetEntProp(Meteor, Prop_Send, "m_iItemDefinitionIndex");
				{
					if (ItemDefinition == 14 || 201 || 230 || 402 || 526 || 664 || 752 || 792 || 851)
					{
						new Address:Dynamite = TF2Attrib_GetByName(Meteor, "mod demo buff type");
					
						if (Dynamite != Address_Null)
						{
							ZenClip[client] = ClipSet[client];
							
							CustomClip_SetClipAndReserves(client, Meteor, 0, 3, 12, true);
						
							new PrimaryAmmoType = GetEntProp(Meteor, Prop_Send, "m_iPrimaryAmmoType");
							PrimaryAmmoType = Reserve1Set[client];
							
							//PrintToServer("PrimaryAmmoType = %i", PrimaryAmmoType);
							//PrintToServer("Clip = %i", ClipSet[client]);
							
							DynamiteActive[client] = false;
							HitCounter[client] = 0.0;
							MaxammoIncrease(client, Meteor, 0, 0, PrimaryAmmoType, true, true);
						}
					}
				}
			}
		}
	}
}

public Action:OnTakeDamage(Ent, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (IsValidClient(attacker))
	{
		new Meteor = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(Meteor))
		{
			new ItemDefinition = GetEntProp(Meteor, Prop_Send, "m_iItemDefinitionIndex");
			{
				if (ItemDefinition == 14 || 201 || 230 || 402 || 526 || 664 || 752 || 792 || 851)
				{
					new Address:Dynamite = TF2Attrib_GetByName(Meteor, "mod demo buff type");
					
					if (Dynamite != Address_Null && !(damagetype & DMG_BLAST) && !(damagetype & DMG_BURN))
					{
						if (HitCounter[attacker] < 3.0 && DynamiteActive[attacker] == false)
						{
							HitCounter[attacker] += 1.0;
							//PrintToChat(attacker, "HitCounter = %.0f", HitCounter[attacker]);
						}
					}
				}
			}
		}
	}
}

public Action:OnTakeDamage_player(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsValidClient(attacker) && IsValidClient(victim) && attacker != victim)
	{
		new Meteor = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(Meteor))
		{
			new ItemDefinition = GetEntProp(Meteor, Prop_Send, "m_iItemDefinitionIndex");
			{
				if (ItemDefinition == 14 || 201 || 230 || 402 || 526 || 664 || 752 || 792 || 851)
				{
					new Address:Dynamite = TF2Attrib_GetByName(Meteor, "mod demo buff type");
					
					if (Dynamite != Address_Null && !(damagetype & DMG_BLAST) && !(damagetype & DMG_BURN))
					{
						if (HitCounter[attacker] < 3.0 && DynamiteActive[attacker] == false)
						{
							HitCounter[attacker] += 1.0;
							//PrintToChat(attacker, "HitCounter = %.0f", HitCounter[attacker]);
						}
					}
				}
			}
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) 
{
	if (IsValidClient(client))
	{
		new Meteor = GetPlayerWeaponSlot(client,0);
		
		if (IsValidEntity(Meteor))
		{
			new ItemDefinition = GetEntProp(Meteor, Prop_Send, "m_iItemDefinitionIndex");
			{
				if (ItemDefinition == 14 || 201 || 230 || 402 || 526 || 664 || 752 || 792 || 851)
				{
					new Address:Dynamite = TF2Attrib_GetByName(Meteor, "mod demo buff type");
					
					if (Dynamite != Address_Null)
					{
						if ((buttons & IN_ATTACK) != IN_ATTACK && IsReloading[client] == false)
						{
							CustomClip_ReloadCalc(client, Meteor, 0, 4.0, ZenClip[client], true);
						}
						if ((buttons & IN_ATTACK) == IN_ATTACK && IsReloading[client] == true)
						{
							IsReloading[client] = false;
							KillTimer(g_Timer[client]);
						}
						if (IsReloadFinished(client) == true)
						{
							HitCounter[client] = 0.0;
							ReloadFinished[client] = false;
						}
					}
				}
			}
		}
	}
	return Plugin_Changed;
}

DynamiteWithALaserBeam(client)
{
	DynamiteActive[client] = true;
	
	if (DynamiteActive[client] == true)
	{
		new Meteor = GetPlayerWeaponSlot(client,0);
		
		if (IsValidEntity(Meteor))
		{
			new ItemDefinition = GetEntProp(Meteor, Prop_Send, "m_iItemDefinitionIndex");
			{
				if (ItemDefinition == 14 || 201 || 230 || 402 || 526 || 664 || 752 || 792 || 851)
				{
					new Address:Dynamite = TF2Attrib_GetByName(Meteor, "mod demo buff type");
					
					if (Dynamite != Address_Null)
					{
						int clip = GetEntProp(Meteor, Prop_Data, "m_iClip1");
						clip = 1;
						
						SetEntProp(Meteor, Prop_Send, "m_iClip1", clip)
						TF2Attrib_RemoveByName(Meteor, "clip size bonus");
			
						TF2Attrib_SetByName(Meteor, "dmg falloff decreased", 0.01);
						TF2Attrib_SetByName(Meteor, "Blast radius increased", 5.00);
						TF2Attrib_SetByName(Meteor, "damage bonus HIDDEN", 15.00);
						TF2Attrib_SetByName(Meteor, "flat damage increase", 500.0);
						TF2Attrib_SetByName(Meteor, "Projectile speed increased", 70.00);
						
						TF2Attrib_SetByName(Meteor, "dmg bonus vs buildings", 9.00);
						TF2Attrib_SetByName(Meteor, "scorch", 130.00);
						TF2Attrib_SetByName(Meteor, "reduce armor on hit", 300.00);
						TF2Attrib_SetByName(Meteor, "referenced item id low", 40.00);
						TF2Attrib_SetByName(Meteor, "use large smoke explosion", 1.00);
						
						TF2Attrib_SetByName(Meteor, "override projectile type", 2.00);
						TF2Attrib_SetByName(Meteor, "Set DamageType Ignite", 1.00);
						TF2Attrib_SetByName(Meteor, "weapon burn dmg increased", 9.00);
						TF2Attrib_SetByName(Meteor, "weapon burn time increased", 2.00);
						
						TF2Attrib_SetByName(Meteor, "special taunt", 1.00);
					}
				}
			}
		}
	}
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (IsValidClient(client))
	{
		new Meteor = GetPlayerWeaponSlot(client,0);
		
		if (IsValidEntity(Meteor))
		{
			new ItemDefinition = GetEntProp(Meteor, Prop_Send, "m_iItemDefinitionIndex");
			{
				if (ItemDefinition == 14 || 201 || 230 || 402 || 526 || 664 || 752 || 792 || 851)
				{
					new Address:Dynamite = TF2Attrib_GetByName(Meteor, "mod demo buff type");
					
					if (Dynamite != Address_Null && DynamiteActive[client] == true)
					{
						new Float:Pos[3];
						GetClientEyePosition(client, Pos);
						EmitSoundFromOrigin(DynamiteShoot, Pos);
						
						CreateTimer(0.3, Timer_Remove,client);
					}
				}
			}
		}
	}
}

public Action:Timer_Remove(Handle:Timer,any:client)
{
	if (DynamiteActive[client] == true)
	{
		DynamiteRemove(client);
		DynamiteActive[client] = false;
	}
}

public OnEntityDestroyed(Entity)
{
	new String:classname[128];
	if (StrEqual(classname, "tf_projectile_rocket"))
	{
		for ( new client = 1; client <= MaxClients; client++ )
		{
			if (IsValidClient(client) && IsPlayerAlive(client))
			{
				if (IsValidOwner(client, "tf_projectile_rocket") == true)
				{
					new Meteor = GetPlayerWeaponSlot(client,0);
		
					if (IsValidEntity(Meteor))
					{
						new ItemDefinition = GetEntProp(Meteor, Prop_Send, "m_iItemDefinitionIndex");
						{
							if (ItemDefinition == 14 || 201 || 230 || 402 || 526 || 664 || 752 || 792 || 851)
							{
								new Address:Dynamite = TF2Attrib_GetByName(Meteor, "mod demo buff type");
					
								if (Dynamite != Address_Null)
								{
									new Float:EntityPos[3];
									GetEntPropVector(Entity, Prop_Data, "m_vecAbsOrigin", EntityPos);
								
									EmitSoundFromOrigin(DynamiteExplosion, EntityPos);
									EmitSoundFromOrigin(DynamiteExplosion2, EntityPos);
								}
							}
						}
					}
				}
			}
		}
	}
}

DynamiteRemove(client)
{
	HitCounter[client] = 0.0
	new Meteor = GetPlayerWeaponSlot(client,0);
		
	if (IsValidEntity(Meteor))
	{
		new ItemDefinition = GetEntProp(Meteor, Prop_Send, "m_iItemDefinitionIndex");
		{
			if (ItemDefinition == 14 || 201 || 230 || 402 || 526 || 664 || 752 || 792 || 851)
			{
				new Address:Dynamite = TF2Attrib_GetByName(Meteor, "mod demo buff type");
					
				if (Dynamite != Address_Null)
				{
					DynamiteActive[client] = false;
					TF2Attrib_RemoveByName(Meteor, "dmg falloff decreased");
					TF2Attrib_RemoveByName(Meteor, "Blast radius increased");
					TF2Attrib_RemoveByName(Meteor, "damage bonus HIDDEN");
					TF2Attrib_RemoveByName(Meteor, "flat damage increase");
					TF2Attrib_RemoveByName(Meteor, "Projectile speed increased");
					
					TF2Attrib_RemoveByName(Meteor, "dmg bonus vs buildings");
					TF2Attrib_RemoveByName(Meteor, "scorch");
					TF2Attrib_RemoveByName(Meteor, "reduce armor on hit");
					TF2Attrib_RemoveByName(Meteor, "referenced item id low");
					TF2Attrib_RemoveByName(Meteor, "use large smoke explosion");
					
					TF2Attrib_RemoveByName(Meteor, "override projectile type");
					TF2Attrib_RemoveByName(Meteor, "Set DamageType Ignite");
					TF2Attrib_SetByName(Meteor, "weapon burn dmg increased", 1.00);
					TF2Attrib_RemoveByName(Meteor, "weapon burn time increased");
					
					TF2Attrib_RemoveByName(Meteor, "special taunt");
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