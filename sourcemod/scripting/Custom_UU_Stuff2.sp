#include <sourcemod>
#include <tf2attributes>
#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>


ConVar g_botlevel;

new Handle:cvar_houlongdmgmult;

new Handle:cvar_MVMbotDamage;

new Handle:cvar_singleresistmode;

new bool:hooked[MAXPLAYERS+1] = false;


stock bool IsValidClient( client, bool replaycheck = true )
{
    if ( client <= 0 || client > MaxClients ) return false; 
    if ( !IsClientInGame( client ) ) return false; 
    if ( !IsPlayerAlive( client ) ) return false; 
    return true; 
}

stock bool:IsMvM(bool:forceRecalc = false)
{
	static bool:found = false;
	static bool:ismvm = false;
	if (forceRecalc)
	{
		found = false;
		ismvm = false;
	}
	if (!found)
	{	
		new i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
		if (i > MaxClients && IsValidEntity(i)) ismvm = true;
		found = true;
	}
	return ismvm;
}

public void OnPluginStart()
{
	cvar_MVMbotDamage = CreateConVar("sm_mvm_bot_damagemult", "1", "Sets Player damage mult against MVM bots. Default: 1");
	cvar_houlongdmgmult = CreateConVar("sm_huolong_flare_dmgmult", "1", "Sets Huo Long Heater flare damage against non-bot players. Default: 1");
	cvar_singleresistmode = CreateConVar("sm_uu_single_resist_mode", "0", "Single Resist mode. Default: 0");
	CreateTimer(0.1, Timer_single, _, TIMER_REPEAT);
	
	for(new client = 0; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			if (hooked[client] == false)
			{
				hooked[client] = true;
				SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage_Player);
			}
		}
	}
}

public OnPluginEnd()
{
	for(new client = 0; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			if (hooked[client] == true)
			{
				hooked[client] = false;
				SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage_Player);
			}
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage_Player);
}
public Action:Timer_single(Handle:Timer)
{
	new Float:resistmode = GetConVarFloat(cvar_singleresistmode);
	if (resistmode == 1)
	{
		for(new client = 0; client < MaxClients; client++)
		{
			if (IsValidClient(client) && !IsFakeClient(client))
			{
				TF2Attrib_SetByName(client, "referenced item id low", 0.10);
				TF2Attrib_SetByName(client, "referenced item def UPDATED", 0.30);
				TF2Attrib_SetByName(client, "always tradable", 0.30);
				TF2Attrib_SetByName(client, "noise maker", 0.30);
				TF2Attrib_SetByName(client, "collection bits DEPRECATED", 0.30)
			}
		}
	}
}

public OnEntityCreated(Ent, const String:cls[])
{
	if (StrEqual(cls, "obj_sentrygun") || StrEqual(cls, "obj_dispenser") || StrEqual(cls, "tank_boss") || StrEqual(cls, "obj_teleporter")/* || StrEqual(cls, "obj_attachment_sapper")*/)
	{
		SDKHook(Ent, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	/*
	if (StrEqual(cls, "prop_physics_override"))
	{
		CreateTimer(0.3, Timer_Delete, Ent);
	}
	*/
	//PrintToServer("Spawned %s",cls);
}

public Action:Timer_Delete(Handle:timer, any:Ent)
{
	if (IsValidEntity(Ent))
	{
		AcceptEntityInput(Ent, "Kill");
	}
}

public Action:OnTakeDamage_Player(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (attacker == 305 || 0 && !IsValidClient(attacker))
	{
		new Float:worlddmg =  TF2_GetMaxHealth(victim)*0.70;
		damage = worlddmg;
	}
}

public Action:OnTakeDamage(Ent, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (IsValidClient(attacker))
	{
		new Gunbs = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			
		new Gunbs1 = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");

		new Gunbs2 = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");

		new Gunbs3 = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			
		new Gunbs4 = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			
		new Gunbs5 = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			
		new Address:MeleeDmg = TF2Attrib_GetByName(Gunbs, "custom texture hi");
		new Address:MeleeDmgMult = TF2Attrib_GetByName(Gunbs, "cannot_transmute");
			
		new Address:BulletDmg = TF2Attrib_GetByName(Gunbs1, "cannot giftwrap");
		new Address:BulletDmgMult = TF2Attrib_GetByName(Gunbs1, "tool needs giftwrap");

		new Address:BlastDmg = TF2Attrib_GetByName(Gunbs2, "custom_paintkit_seed_lo");
		new Address:BlastDmgMult = TF2Attrib_GetByName(Gunbs2, "custom_paintkit_seed_hi");
			
		new Address:DFDmg = TF2Attrib_GetByName(Gunbs3, "tool target item");
		new Address:DFDmgMult = TF2Attrib_GetByName(Gunbs3, "end drop date");

		new Address:FlameDmg = TF2Attrib_GetByName(Gunbs4, "random drop line item 0");
		new Address:FlameDmgMult = TF2Attrib_GetByName(Gunbs4, "random drop line item 1");

		new Address:FlareDmg = TF2Attrib_GetByName(Gunbs5, "random drop line item 2");
		new Address:FlareDmgMult = TF2Attrib_GetByName(Gunbs5, "random drop line item 3");

		if (MeleeDmg && MeleeDmgMult!=Address_Null)
		{
			new Float:Noow = TF2Attrib_GetValue(MeleeDmg)+TF2Attrib_GetValue(MeleeDmgMult);
			damage *= Noow;
		}
		if (BulletDmg && BulletDmgMult!=Address_Null)
		{
			new Float:Noot = TF2Attrib_GetValue(BulletDmg)+TF2Attrib_GetValue(BulletDmgMult);
			damage *= Noot;
		}
		if (BlastDmg && BlastDmgMult!=Address_Null)
		{
			new Float:Noob = TF2Attrib_GetValue(BlastDmg)+TF2Attrib_GetValue(BlastDmgMult);
			damage *= Noob;
		}
		if (DFDmg && DFDmgMult!=Address_Null)
		{
			new Float:Noom = TF2Attrib_GetValue(DFDmg)+TF2Attrib_GetValue(DFDmgMult);
			damage *= Noom;
		}
		if (FlameDmg && FlameDmgMult!=Address_Null)
		{
			new Float:Noon = TF2Attrib_GetValue(FlameDmg)+TF2Attrib_GetValue(FlameDmgMult);
			damage *= Noon;
		}
		if (FlareDmg && FlareDmgMult!=Address_Null)
		{
			new Float:Noov = TF2Attrib_GetValue(FlareDmg)+TF2Attrib_GetValue(FlareDmgMult);
			damage *= Noov;
		}
	}
	return Plugin_Changed;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		new Gunbs = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(Gunbs))
		{
			new ItemDefinition = GetEntProp(Gunbs, Prop_Send, "m_iItemDefinitionIndex");
			{
				if (ItemDefinition == 237 || 265)
				{
					new Address:Braap = TF2Attrib_GetByName(Gunbs, "damage penalty");
					if (Braap != Address_Null)
					{
						TF2Attrib_RemoveByName(Gunbs, "damage penalty");
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
stock TF2_GetMaxHealth(iClient)
{
    new maxhealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, iClient);
    return ((maxhealth == -1 || maxhealth == 80896) ? GetEntProp(iClient, Prop_Data, "m_iMaxHealth") : maxhealth);
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

stock TraceClientViewEntity(client)
{
	new Float:m_vecOrigin[3];
	new Float:m_angRotation[3];
	GetClientEyePosition(client, m_vecOrigin);
	GetClientEyeAngles(client, m_angRotation);
	new Handle:tr = TR_TraceRayFilterEx(m_vecOrigin, m_angRotation, MASK_VISIBLE, RayType_Infinite, TRDontHitSelf, client);
	new pEntity = -1;
	if (TR_DidHit(tr))
	{
		pEntity = TR_GetEntityIndex(tr);
		CloseHandle(tr);
		return pEntity;
	}
	CloseHandle(tr);
	return -1;
}
public bool:TRDontHitSelf(entity, mask, any:data)
{
	if (entity == data) return false;
	return true;
}

stock bool:IsCritBoosted(client) // Nergal :D
{
    if (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) || TF2_IsPlayerInCondition(client, TFCond_CritCanteen) || TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin) || TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) || TF2_IsPlayerInCondition(client, TFCond_CritOnKill) || TF2_IsPlayerInCondition(client, TFCond_CritMmmph) || TF2_IsPlayerInCondition(client, TFCond_CritOnDamage))
    {
        return true;
    }
    return false;
}

stock AddPlayerHealth(iClient, iAdd, Float:flOverheal = 1.5, bAdditive = false, bool:bEvent = false)
{
    new iHealth = GetClientHealth(iClient);
    new iNewHealth = iHealth + iAdd;
    new iMax = bAdditive ? (TF2_GetMaxHealth(iClient) + RoundFloat(flOverheal)) : TF2_GetMaxOverHeal(iClient, flOverheal);
    if (iHealth < iMax)
    {
        iNewHealth = min(iNewHealth, iMax);
        if (bEvent)
        {
            ShowHealthGain(iClient, iNewHealth-iHealth);
        }
        SetEntityHealth(iClient, iNewHealth);
    }
}

stock ShowHealthGain(iPatient, iHealth, iHealer = -1)
{
    new iUserId = GetClientUserId(iPatient);
    new Handle:hEvent = CreateEvent("player_healed", true);
    SetEventBool(hEvent, "sourcemod", true);
    SetEventInt(hEvent, "patient", iUserId);
    SetEventInt(hEvent, "healer", IsValidClient(iHealer) ? GetClientUserId(iHealer) : iUserId);
    SetEventInt(hEvent, "amount", iHealth);
    FireEvent(hEvent);

    hEvent = CreateEvent("player_healonhit", true);
    SetEventBool(hEvent, "sourcemod", true);
    SetEventInt(hEvent, "amount", iHealth);
    SetEventInt(hEvent, "entindex", iPatient);
    FireEvent(hEvent);
}

stock TF2_GetMaxOverHeal(iClient, Float:flOverHeal = 1.5) // Quick-Fix would be 1.25
{
    return RoundFloat(float(TF2_GetMaxHealth(iClient)) * flOverHeal);
}

stock int min(int a, int b) 
{
    return a < b ? a : b;
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