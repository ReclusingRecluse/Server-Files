// Includes
#pragma tabsize 0
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf2_isPlayerInSpawn>
#include <dhooks>
#include <clientprefs>
#include <UbUp-PowerSupply>
#include <custom_status_hud>
#include <tf2attributes_ubup_inc>
#include <tf_econ_dynamic>
//#include <UU_Global>

#include "UUextra/CUU_DamageCalcs.sp"
#include "UUextra/CUU_Wallbang.sp"

// Plugin Info
public Plugin:myinfo =
{
	name = "Uberupgrades Damage System",
	author = "Recluse (Modified from Razor's 0.98 Armor System",
	description = "Plugin for handling 0.98 sytle armor and damage calculations.",
	version = "2.0",
	url = "go fuck yourself",
}
/* Variables */
//Handle:SyncHud_PowerSupply;
//Floats
new Float:g_flLastAttackTime[MAXPLAYERS + 1];
new Float:g_GameFrameDelay[MAXPLAYERS+1] = {0.0, ...};
new Float:fl_CombatRegenPenalty[MAXPLAYERS+1] = {1.0, ...};

char Suffix[MAXPLAYERS+1][32];
char SuffixDMG[MAXPLAYERS+1][32];
new Float:ResistShrt[MAXPLAYERS+1] = {0.0, ...};
new Float:DMGShrt[MAXPLAYERS+1][6];
bool:Suffixactive[MAXPLAYERS+1] = {false, ...};

//Bools
new bool:b_Hooked[MAXPLAYERS+1] = false;
new bool:b_IsInCombat[MAXPLAYERS+1] = {false, ...};
//Integers
int g_iOffset;
//Stocks
stock int GetHealingTarget(const int client)
{
    int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
    if (!IsValidEdict(medigun) || !IsValidEntity(medigun))
        return -1;

    char s[32]; GetEdictClassname(medigun, s, sizeof(s));
    if ( !strcmp(s, "tf_weapon_medigun", false) ) {
        if ( GetEntProp(medigun, Prop_Send, "m_bHealing") )
            return GetEntPropEnt( medigun, Prop_Send, "m_hHealingTarget" );
    }
    return -1;
}
stock bool IsNearSpencer(const int client)
{
    int medics = 0;
    for ( int i=MaxClients ; i ; --i ) {
        if (!IsClientInGame(i))
            continue;
        if ( GetHealingTarget(i) == client )
            medics++;
    }
    return (GetEntProp(client, Prop_Send, "m_nNumHealers") > medics);
}  
stock TF2_GetMaxHealth(iClient)
{
    new maxhealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, iClient);
    return ((maxhealth == -1 || maxhealth == 80896) ? GetEntProp(iClient, Prop_Data, "m_iMaxHealth") : maxhealth);
}
stock TF2_IsPlayerCritBuffed(client)
{
   if ( TF2_IsPlayerInCondition( client, TFCond_Kritzkrieged ) || TF2_IsPlayerInCondition( client, TFCond_HalloweenCritCandy )
        || TF2_IsPlayerInCondition( client, TFCond_CritCanteen ) || TF2_IsPlayerInCondition( client, TFCond_CritDemoCharge )
        || TF2_IsPlayerInCondition( client, TFCond_CritOnFirstBlood ) || TF2_IsPlayerInCondition( client, TFCond_CritOnWin )
        || TF2_IsPlayerInCondition( client, TFCond_CritOnFlagCapture ) || TF2_IsPlayerInCondition( client, TFCond_CritOnKill )
        || TF2_IsPlayerInCondition( client, TFCond_CritMmmph ) || TF2_IsPlayerInCondition( client, TFCond_CritOnDamage )
        || TF2_IsPlayerInCondition( client, TFCond_CritRuneTemp ) )
    {
        return true; 
    }
    return false; 
}
stock TF2_IsPlayerMinicritBuffed(client)
{
   if ( TF2_IsPlayerInCondition( client, TFCond_Buffed ) || TF2_IsPlayerInCondition( client, TFCond_CritCola )
		|| TF2_IsPlayerInCondition( client, TFCond_NoHealingDamageBuff ) || TF2_IsPlayerInCondition( client, TFCond_MiniCritOnKill ))
    {
        return true; 
    }
    return false; 
}
stock TF2_IsPlayerMinicritDebuffed(client)
{
   if ( TF2_IsPlayerInCondition( client, TFCond_MarkedForDeath ) || TF2_IsPlayerInCondition( client, TFCond_MarkedForDeathSilent )
		|| TF2_IsPlayerInCondition( client, TFCond_PasstimePenaltyDebuff ) || TF2_IsPlayerInCondition( client, TFCond_Jarated ))
    {
        return true; 
    }
    return false; 
}
stock TF2_IsPlayerCritImmune(client)
{
   if ( TF2_IsPlayerInCondition( client, TFCond_UberBulletResist ) || TF2_IsPlayerInCondition( client, TFCond_UberBlastResist )
		|| TF2_IsPlayerInCondition( client, TFCond_UberFireResist ) || TF2_IsPlayerInCondition( client, TFCond_DefenseBuffed ))
    {
        return true; 
    }
    return false; 
}
stock int TF2_GetPlayerMaxHealth(int client) {
	return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
}

//======== [  CLIENT STOCKS ] =========

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////Actual Hooks & Functions////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public void TF2_OnConditionAdded(client, TFCond:cond)
{
	if (IsValidClient(client))
	{
		switch(cond)
		{
			case TFCond_OnFire:
			{
				new Address:attribute1 = TF2Attrib_GetByName(client, "absorb damage while cloaked");//Chance to remove fire on hit.
				if(TF2_GetPlayerClass(client) == TFClass_Pyro)
				{
					TF2_RemoveCondition(client, TFCond_OnFire);
					TF2_RemoveCondition(client, TFCond_HealingDebuff);
				}
				else if(attribute1 != Address_Null && GetRandomFloat(0.0,1.0) <= TF2Attrib_GetValue(attribute1))
				{
					TF2_RemoveCondition(client, TFCond_OnFire)
					TF2_RemoveCondition(client, TFCond_HealingDebuff)
				}
			}
			case TFCond_Bleeding:
			{
				new Address:attribute2 = TF2Attrib_GetByName(client, "always_transmit_so");//Chance to remove bleed on hit.
				if(attribute2 != Address_Null && GetRandomFloat(0.0,1.0) <= TF2Attrib_GetValue(attribute2))
				{
					TF2_RemoveCondition(client, TFCond_Bleeding)
				}
			}
			case TFCond_Slowed:
			{
				new Address:attribute3 = TF2Attrib_GetByName(client, "jarate description");
				if(attribute3 != Address_Null && GetRandomFloat(0.0,1.0) <= TF2Attrib_GetValue(attribute3))
				{
					TF2_RemoveCondition(client, TFCond_Slowed);
				}
			}
			case TFCond_Dazed:
			{
				new Address:attribute3 = TF2Attrib_GetByName(client, "jarate description");
				if(attribute3 != Address_Null && GetRandomFloat(0.0,1.0) <= TF2Attrib_GetValue(attribute3))
				{
					TF2_RemoveCondition(client, TFCond_Dazed);
				}
			}
			case TFCond_Bonked:
			{
				TF2_AddCondition(client, TFCond_HalloweenQuickHeal, 1.0);
			}
			case TFCond_Taunting:
			{
				new Address:TauntSpeedActive = TF2Attrib_GetByName(client, "gesture speed increase");
				if(TauntSpeedActive != Address_Null)
				{
					SetTauntAttackSpeed(client, TF2Attrib_GetValue(TauntSpeedActive));
				}
				/*new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					new String:classname[64];
					GetEdictClassname(CWeapon, classname, sizeof(classname)); 
					if(StrContains(classname, "tf_weapon_lunchbox",false) == 0)
					{
						
					}
				}*///Potentially add something for lunchboxes?
			}
		}
	}
}

Float:ArmorRechargeMult[MAXPLAYERS+1] = {0.0, ...};

// On Plugin Start
public OnPluginStart()
{
	for(new i=0; i<=MaxClients; i++)
	{
		if(!IsValidClient(i)){continue;}
		fl_MaxArmor[i] = 300.0;
		fl_CurrentArmor[i] = 300.0;
		fl_ArmorRegenPenalty[i] = 0.0;
		ResistShrt[i] = 0.0;
		Suffixactive[i] = false;
		if(b_Hooked[i] == false)
		{
			b_Hooked[i] = true;
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(i, SDKHook_TraceAttack, TraceAttack);
		}
	}
	
	//SyncHud_PowerSupply = CreateHudSynchronizer();
	//ClearSyncHud(client, SyncHud_PowerSupply);
	HookEvent("player_hurt", Event_Playerhurt)
	HookEvent("player_changeclass", Event_PlayerreSpawn);
	HookEvent("player_spawn", Event_PlayerreSpawn)
	HookEvent("player_death", Event_PlayerreSpawn)
	HookEvent("post_inventory_application", Event_PlayerreSpawn)
	
	HookEvent("player_death", Event_Death);
	CreateTimer(0.1, Timer_GiveHealth, _, TIMER_REPEAT);
	CreateTimer(1.0, Timer_Second, _, TIMER_REPEAT);
	
	//Offsets
	Handle hConf = LoadGameConfigFile("tf2.uberupgrades");
	if (LookupOffset(g_iOffset, "CTFPlayer", "m_iSpawnCounter"))
	g_iOffset -= GameConfGetOffset(hConf, "m_flTauntAttackTime");
	
	//Register Attributes
	TF2EconDynAttribute attrib = new TF2EconDynAttribute();
	
	attrib.SetName("refund attribute");
	attrib.SetClass("uu_refund_attribute");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("damage reduction");
	attrib.SetClass("uu_dr");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.Register();
	
	attrib.SetName("damage reduction multiplier");
	attrib.SetClass("uu_dr_mult");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.Register();
	
	attrib.SetName("flat damage reduction");
	attrib.SetClass("weapons_flat_dmg_reduc");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("flat damage increase");
	attrib.SetClass("weapons_flat_dmg_incr");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("accuracy scales custom");
	attrib.SetClass("weapons_accuracy_scales_custom");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.Register();
	
	attrib.SetName("dlss");
	attrib.SetClass("uu_dlss");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	
	//Wallbang stuff
	
	Handle hGameData = LoadGameConfigFile("tf2.wallbanging");
	if(hGameData == INVALID_HANDLE)
	{
		SetFailState("Gamedata not found");
	}
	
	//
	// DHooks
	//
	
	int offset = GameConfGetOffset(hGameData, "CTFWeaponBaseGun::FireBullet");
	gHook_CTFWeaponBaseGun_FireBullet = DHookCreate(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, CTFWeaponBaseGun_FireBullet);
	DHookAddParam(gHook_CTFWeaponBaseGun_FireBullet, HookParamType_CBaseEntity);
	
	offset = GameConfGetOffset(hGameData, "CBaseEntity::FireBullets");
	gHook_CBaseEntity_FireBullets = DHookCreate(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, CBaseEntity_FireBullets);
	DHookAddParam(gHook_CBaseEntity_FireBullets, HookParamType_ObjectPtr);
	
	//
	// SDK Calls
	//
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTFWeaponBaseGun::GetProjectileDamage");
	PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
	gCall_CTFWeaponBaseGun_GetProjectileWeapon = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTFWeaponBaseGun::GetWeaponSpread");
	PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
	gCall_CTFWeaponBaseGun_GetWeaponSpread = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTFWeaponBase::GetCustomDamageType");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	gCall_CTFWeaponBase_GetCustomDamageType = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTFWeaponBase::GetWeaponID");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	gCall_CTFWeaponBase_GetWeaponID = EndPrepSDKCall();
	
	HookAllPlayers();
	
	sm_penetration_falloff = CreateConVar("sm_penetration_falloff", "16", "Units per one damage unit falloff");
	sm_penetration_projectiles = CreateConVar("sm_penetration_projectiles", "0");
	sm_penetration_max_distance = CreateConVar("sm_penetration_max_distance", "90");
	sm_penetration_step = CreateConVar("sm_penetration_step", "4");
}
public Action:Timer_Second(Handle:timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			SetArmor(client);
		}
	}
}
bool LookupOffset(int &iOffset, const char[] strClass, const char[] strProp)
{
	iOffset = FindSendPropInfo(strClass, strProp);
	if (iOffset <= 0)
	{
		SetFailState("Could not locate offset for %s::%s", strClass, strProp);
	}
	return true;
}
public OnPluginEnd()
{
	for(new i=0; i<=MaxClients; i++)
	{
		if(!IsValidClient(i)){continue;}
		fl_MaxArmor[i] = 300.0;
		fl_CurrentArmor[i] = 300.0;
		fl_ArmorRegenPenalty[i] = 0.0;
		ResistShrt[i] = 0.0;
		Suffixactive[i] = false;
		if(b_Hooked[i] == true)
		{
			b_Hooked[i] = false;
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKUnhook(i, SDKHook_TraceAttack, TraceAttack);
		}
	}
	//ClearSyncHud(client, SyncHud_PowerSupply);
	UnhookEvent("player_hurt", Event_Playerhurt)
	UnhookEvent("player_changeclass", Event_PlayerreSpawn);
	UnhookEvent("player_spawn", Event_PlayerreSpawn)
	UnhookEvent("player_death", Event_PlayerreSpawn)
	UnhookEvent("post_inventory_application", Event_PlayerreSpawn)
	UnhookEvent("player_death", Event_Death);
}

// On Map Start

public OnMapStart()
{
	for(new i=0; i<=MaxClients; i++)
	{
		if(!IsValidClient(i)){continue;}
		fl_ArmorRegenPenalty[i] = 0.0;
		ResistShrt[i] = 0.0;
		VictimResistance[i] = 0.0;
		Suffixactive[i] = false;
		if(b_Hooked[i] == false)
		{
			b_Hooked[i] = true;
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(i, SDKHook_TraceAttack, TraceAttack);
		}
	}
}

public Action:Timer_GiveHealth(Handle:timer)//give health every 0.1 seconds
{
	for(new client = 0; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			new Address:RegenActive = TF2Attrib_GetByName(client, "disguise on backstab");
			if(RegenActive != Address_Null)
			{
				
				new Float:RegenPerSecond = TF2Attrib_GetValue(RegenActive);
				new Float:RegenPerTick = RegenPerSecond/10;
				new Address:HealingReductionActive = TF2Attrib_GetByName(client, "health from healers reduced");
				if(HealingReductionActive != Address_Null)
				{
					RegenPerTick *= TF2Attrib_GetValue(HealingReductionActive);
				}
				new clientHealth = GetEntProp(client, Prop_Data, "m_iHealth");
				new clientMaxHealth = TF2_GetPlayerMaxHealth(client);
				if(!IsValidClient(client))
				{
					RegenPerTick = RegenPerTick/10;
				}
				if(clientHealth < clientMaxHealth)
				{
					if (ClientAttribCheck(client, "is weakened"))
					{
						RegenPerTick *= 0.50;
					}
					if (fl_CombatRegenPenalty[client] < 1.0)
					{
						RegenPerTick *= fl_CombatRegenPenalty[client];
					}
					if(float(clientHealth) + RegenPerTick < clientMaxHealth)
					{
						SetEntProp(client, Prop_Data, "m_iHealth", clientHealth+RoundToNearest(RegenPerTick));
					}
					else
					{
						SetEntProp(client, Prop_Data, "m_iHealth", clientMaxHealth);
					}
				}
			}
		}
	}
}


//idk man
stock ResistValueSuffix(Float:Value, client)
{
	if (!IsValidClient(client)){return;}
	
	//Value *= 1.0-GetClientAttribValue(client, "dmg taken increased");
	
	if (Value >= 1000.0 && Value < 1000000.0)
	{
		Value /= 1000.0;
		Format(Suffix[client], sizeof(Suffix), "K");
	}
	else if (Value >= 1000000.0 && Value < 1000000000.0)
	{
		Value /= 1000000.0
		Format(Suffix[client], sizeof(Suffix), "M");
	}
	else if (Value >= 1000000000.0 && Value < 1000000000000.0)
	{
		Value /= 1000000000.0;
		Format(Suffix[client], sizeof(Suffix), "B");
	}
	else if (Value >= 1000000000000.0 && Value < 10000000000000000.0)
	{
		Value /= 1000000000000.0;
		Format(Suffix[client], sizeof(Suffix), "T");
	}
	else if (Value >= 10000000000000000.0)
	{
		Format(Suffix[client], sizeof(Suffix), "A shit ton");
	}
	else
	{
		Format(Suffix[client], sizeof(Suffix), "");
	}
	ResistShrt[client] = Value;
}

stock DMGValueSuffix(Float:Value, client)
{
	if (!IsValidClient(client)){return;}
	
	//Value *= 1.0-GetClientAttribValue(client, "dmg taken increased");
	
	if (Value >= 1000.0 && Value < 1000000.0)
	{
		Value /= 1000.0;
		Format(SuffixDMG[client], sizeof(SuffixDMG), "K");
	}
	else if (Value >= 1000000.0 && Value < 1000000000.0)
	{
		Value /= 1000000.0
		Format(SuffixDMG[client], sizeof(SuffixDMG), "M");
	}
	else if (Value >= 1000000000.0 && Value < 1000000000000.0)
	{
		Value /= 1000000000.0;
		Format(SuffixDMG[client], sizeof(SuffixDMG), "B");
	}
	else if (Value >= 1000000000000.0 && Value < 10000000000000000.0)
	{
		Value /= 1000000000000.0;
		Format(SuffixDMG[client], sizeof(SuffixDMG), "T");
	}
	else if (Value >= 10000000000000000.0)
	{
		Format(SuffixDMG[client], sizeof(SuffixDMG), "A shit ton");
	}
	else
	{
		Format(SuffixDMG[client], sizeof(SuffixDMG), "");
	}
	
	for (int i = 0; i < 5; i++)
	{
		if (ClientAttribCheck(client, "dlss"))
		{
			DMGShrt[client][i] = Value+FakeDmg[client][i];
		}
		else
		{
			DMGShrt[client][i] = Value;
		}
	}
}

public Action OnCustomStatusHUDUpdate(int client, StringMap entries) 
{
	if (IsValidClient(client))
	{
		//char armorsupply[32];
		char armorsupplyregenpenalty[32];
		char totalresist[32];
		char totaldmg[32];
		
		//Format(armorsupply, sizeof(armorsupply), "Armor: %.0f/%.0f", fl_CurrentArmor[client], fl_MaxArmor[client]);
		//entries.SetString("b_uu_b_armor", armorsupply);
		
		Format(totalresist, sizeof(totalresist), "Resistance: %.1f%s", ResistShrt[client], Suffix[client]);
		entries.SetString("b_uu_c_maxresist", totalresist);
		
		
		for (int i = 0; i < 5; i++)
		{
			new ActiveSlot = TF2_GetClientActiveSlot(client);
			if (ActiveSlot == i)
			{
				if (ClientAttribCheck(client, "dlss"))
				{
					Format(totaldmg, sizeof(totaldmg), "Current Wep DMG: %.2f%s", DMGShrt[client][i], SuffixDMG[client]);
					entries.SetString("b_uu_d_maxdmg", totaldmg);
				}
				else
				{
					Format(totaldmg, sizeof(totaldmg), "Current Wep DMG: %.2f%s", DMGShrt[client][i], SuffixDMG[client]);
					entries.SetString("b_uu_d_maxdmg", totaldmg);
				}
			}
		}
		
		if(b_IsInCombat[client])
		{
			Format(armorsupplyregenpenalty, sizeof(armorsupplyregenpenalty), "Regen Penalty: %.2fx", fl_CombatRegenPenalty[client]);
			entries.SetString("uu_armor_regen_penalty", armorsupplyregenpenalty);
		}
	}
	return Plugin_Changed;
}

//Calculate Le Resist for Player (Will do same for DMG to take some lag away)

//Called whenever an upgrade is added to a player
public Action:Ubup_OnAttribAddedClient(int client, String:attrib[])
{
	if (!IsValidClient(client)){return Plugin_Continue;}
	
	if (!strcmp(attrib, "max health additive bonus") || !strcmp(attrib, "damage reduction") || !strcmp(attrib, "damage reduction multiplier"))
	{
		CalculateResist(client);
		//PrintToChat(client, "Resist Bought");
	}
	return Plugin_Continue;
}

//Called whenever an upgrade is added to a player's weapon
public Action:Ubup_OnAttribAddedWeapon(int client, iEnt, slot, String:attrib[])
{
	if (!IsValidClient(client)|| !IsValidEdict(iEnt) || IsFakeClient(client)){return Plugin_Continue;}
	
	if (!strcmp(attrib, "cannot giftwrap") || !strcmp(attrib, "tool needs giftwrap"))
	{
		UU_CalculateDmg(client, iEnt, slot);
		//PrintToChat(client, "Damage bought for weapon %d", slot);
	}
	if (!strcmp(attrib, "fire rate bonus custom"))
	{
		//FireRateToDMG(client, iEnt, slot);
	}
	if (ClientAttribCheck(client, "dlss"))
	{
		CalculateFakeDMG(client, slot);
	}
	return Plugin_Continue;
}

public Event_PlayerreSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new clientweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidClient(client))
	{
		if (!IsFakeClient(client))
		{
			CalculateResist(client);
		}
		fl_CombatRegenPenalty[client] = 1.0;
		AdditonalDMGReduction[client] = 0.0;
		ArmorAddtionalResistance[client] = 0.0;
		ResistShrt[client] = 0.0;
		VictimResistance[client] = 0.0;
		Suffixactive[client] = false;
		
		for (int i = 0; i < 2; i++)
		{
			DMGShrt[client][i] = 0.0;
			FinalDMG[client][i] = 0.0;
			if (IsValidEntity(clientweapon) && IsValidEntity(i))
			{
				if (WepAttribCheck(i, "accuracy scales custom"))
				{
					ResetAccuracyScales(client, i, i);
				}
			}
		}
		CreateTimer(0.9, ResistCalc, client);
		
	}
}

ResistCalc(Handle:TimerCalc, any:client)
{
	if (IsValidClient(client))
	{
		//TF2Attrib_SetByName(client, "dmg taken increased", 0.35);
		TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.35);
		
		ResistShrt[client] = 0.0;
		VictimResistance[client] = 0.0;
		
		if (IsFakeClient(client))
		{
			CalculateResist(client);
			
			if (TotalResist[client] == 0.0)
			{
				TotalResist[client] = 1.0;
			}
			
			for (int i = 0; i < 5; i++)
			{
				new clientweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(clientweapon))
				{
					UU_CalculateDmg(client, clientweapon, i);
				}
			}
		}
	}
}

public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client))
	{
		b_IsInCombat[client] = false;
	}
}


// On Client Put In Server
public OnClientPutInServer(client)
{
	HookPlayer(client);
	fl_MaxArmor[client] = 300.0;
	fl_CurrentArmor[client] = 300.0;
	fl_ArmorRegenPenalty[client] = 0.0;
	VictimResistance[client] = 0.0;
	ResistShrt[client] = 0.0;
	if(b_Hooked[client] == false)
	{
		b_Hooked[client] = true;
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_TraceAttack, TraceAttack);
	}
}

// On Client Disconnect
public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		fl_MaxArmor[client] = 300.0;
		fl_CurrentArmor[client] = 300.0;
		if(b_Hooked[client] == true)
		{
			b_Hooked[client] = false;
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKUnhook(client, SDKHook_TraceAttack, TraceAttack);
		}
	}
}
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(IsValidClient(client))
	{
		g_iPredictionSeed[client] = seed;
		new HealingTarget = GetHealingTarget(client);
		new activeslot = TF2_GetClientActiveSlot(client);
		
		//Caculate client total resistance
		//CalculateResist(client);
		ResistValueSuffix(TotalResist[client], client);
		
		if (activeslot > -1)
		{
			DMGValueSuffix(FinalDMG[client][activeslot], client);
		}
		
		if(IsValidClient(HealingTarget))
		{
			new Address:Healrate1 = TF2Attrib_GetByName(client, "heal rate bonus");
			if(Healrate1 != Address_Null)
			{
				new Float:Healratepct = TF2Attrib_GetValue(Healrate1);
				ArmorRechargeMult[client] *= Healratepct
			}
			new Address:Healrate2 = TF2Attrib_GetByName(client, "heal rate penalty");
			if(Healrate2 != Address_Null)
			{
				new Float:Healratepct2 = TF2Attrib_GetValue(Healrate2);
				ArmorRechargeMult[client] *= Healratepct2
			}
			new Address:Healrate3 = TF2Attrib_GetByName(client, "overheal fill rate reduced");
			if(Healrate3 != Address_Null)
			{
				new Float:Healratepct3 = TF2Attrib_GetValue(Healrate3);
				ArmorRechargeMult[client] *= Healratepct3
			}
		}
		if (fl_CombatRegenPenalty[client] < 0.1)
		{
			fl_CombatRegenPenalty[client] = 0.1;
		}
	}
	return Plugin_Continue;
}
public Event_Playerhurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Float:damage = GetEventFloat(event, "damageamount");
	
	if (IsValidClient(attacker) && IsValidClient(client))
	{
		new clientweapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if (damage > 0.0)
		{
			if (IsValidEntity(clientweapon) && client != attacker)
			{
				//Accuracy Scales
					
				if (WepAttribCheck(clientweapon, "accuracy scales custom"))
				{
					new activeslot = TF2_GetClientActiveSlot(attacker);
					
					AccuracyScalesActive[attacker][activeslot] = true;
					AccuracyScalesTimer[attacker][activeslot] = GetEngineTime()+4.0;
					
					if (Hits[attacker][activeslot] < 10)
					{
						//PrintToChat(attacker, "hit %d", Hits[attacker][activeslot]);
						Hits[attacker][activeslot] += 1;
					}
					
					if (Hits[attacker][activeslot] == 9)
					{
						CalculateAccuracyScales(attacker, clientweapon, activeslot);
						Hits[attacker][activeslot] = 0;
					}
				}
				
				if (!WepAttribCheck(clientweapon, "strange restriction user value 3"))
				{
					//attacker and victim is in combat
					
					//Attacker
					b_IsInCombat[attacker] = true;
					g_GameFrameDelay[attacker] = GetEngineTime()+3.0;
					if (fl_CombatRegenPenalty[attacker] > 0.1 && b_IsInCombat[attacker])
					{
						fl_CombatRegenPenalty[attacker] -= (damage/150.0);
						//PrintToChat(attacker, "regen penalty %.2f", fl_CombatRegenPenalty[attacker]);
						
					}
					
					
					//victim (If they are not already in combat)
					if (!b_IsInCombat[client])
					{
						b_IsInCombat[client] = true;
						g_GameFrameDelay[client] = GetEngineTime()+5.0;
						if (fl_CombatRegenPenalty[client] > 0.1 && b_IsInCombat[client])
						{
							fl_CombatRegenPenalty[client] = 0.40;
							
						}
					}
				}
				
				
				if (WepAttribCheck(clientweapon, "flat armor reduction on hit"))
				{
					fl_CurrentArmor[client] -= GetWepAttribValue(clientweapon, "flat armor reduction on hit");
				}
				else
				{
					if (WepAttribCheck(clientweapon, "reduce armor on hit"))
					{
						fl_CurrentArmor[client] -= ((2.5+damage*0.07)+GetWepAttribValue(clientweapon, "reduce armor on hit"));
					}
					else
					{
						fl_CurrentArmor[client] -= (2.5+damage*0.07);
					}
				}
				
				if (WepAttribCheck(clientweapon, "is_operation_pass"))
				{
					new Float:ReturnHealth = ((damage*0.50)*(GetWepAttribValue(clientweapon, "is_operation_pass")*1.15));
				
					if (ReturnHealth > 200.0)
					{
						ReturnHealth = 200.0;
					}
				
					AddPlayerHealth(attacker, RoundToFloor(ReturnHealth), 1.0);
					ShowHealthGain(attacker, RoundToFloor(ReturnHealth), client);
					
					if (b_IsInCombat[attacker])
					{
						fl_CurrentArmor[attacker] += (ReturnHealth*0.70)*(Pow(fl_CombatRegenPenalty[attacker], -0.17));
					}
					else
					{
						fl_CurrentArmor[attacker] += ReturnHealth*0.70;
					}
				}
				
				//Bot lifesteal
				if (WepAttribCheck(clientweapon, "unique craft index"))
				{
					new Float:ReturnHealth = ((damage*0.65)*(GetWepAttribValue(clientweapon, "unique craft index")*1.17));
				
					if (ReturnHealth > 200.0)
					{
						ReturnHealth = 200.0;
					}
				
					AddPlayerHealth(attacker, RoundToFloor(ReturnHealth), 1.0);
					ShowHealthGain(attacker, RoundToFloor(ReturnHealth), client);
					
					if (b_IsInCombat[attacker])
					{
						fl_CurrentArmor[attacker] += (ReturnHealth*0.70)*(Pow(fl_CombatRegenPenalty[attacker], -0.17));
					}
					else
					{
						fl_CurrentArmor[attacker] += ReturnHealth*0.70;
					}
				}
			}
		}
	}
	if(IsValidClient(attacker) && !IsFakeClient(attacker))
	{
		if(client != attacker && attacker != 0 && damage >= 1.0)
		{
			PrintToConsole(attacker, "%.1f post damage dealt.", damage);
		}
	}
}

public OnGameFrame()
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			new clientweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			new activeslot = TF2_GetClientActiveSlot(client);
			
			if (b_IsInCombat[client])
			{
				if (g_GameFrameDelay[client] >= GetEngineTime()){return;}
			
				b_IsInCombat[client] = false;
				//PrintToChat(client, "No longer in combat");
			}
			
			if (activeslot > -1)
			{
				if (AccuracyScalesActive[client][activeslot])
				{
					if (Hits[client][activeslot] > 10)
					{
						Hits[client][activeslot] = 10;
					}
					
					if (AccuracyScalesTimer[client][activeslot] >= GetEngineTime()){return;}
					
					if (IsValidEntity(clientweapon))
					{
						ResetAccuracyScales(client, clientweapon, activeslot);
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
		g_bCurrentAttackIsCrit[client] = result;
		return Plugin_Continue;
	}
}

public Action TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
    return Plugin_Continue;
}
	
	
	
// On Take Damage
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsValidClient(attacker))
	{
		if (IsValidClient(attacker) && IsPlayerAlive(attacker) && !(damagetype & DMG_NERVEGAS))
		{
			new AttackerWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			new activeslot = TF2_GetClientActiveSlot(attacker);
			
			new String:infli_classname[128]; 
			if (IsValidEdict(inflictor))
			{
				GetEdictClassname(inflictor, infli_classname, sizeof(infli_classname));
			}
			
			
			if(!strcmp("obj_sentrygun", infli_classname))
			{
				damage = 0.4*(FinalDMG[attacker][activeslot]/FinalResist[victim]);
				
			}
			
			if (victim != attacker)
			{
				
				damage = FinalDMG[attacker][activeslot]/FinalResist[victim];
				
				
				if (IsFakeClient(attacker) && IsFakeClient(victim))
				{
					damage *= 3.0;
				}
				
				
				if (damagetype & DMG_BURN)
				{
					if (FinalDMG[attacker][activeslot] > 1.0)
					{
						damage = (FinalDMG[attacker][activeslot]/FinalResist[victim])*GetWepAttribValue(AttackerWeapon, "weapon burn dmg increased");
					}
				}
				
				if (damagetype & DMG_SLASH)
				{
					if (FinalDMG[attacker][activeslot] > 1.0)
					{
						damage = FinalDMG[attacker][activeslot]/FinalResist[victim];
					}
				}
				
				if (WepAttribCheck(AttackerWeapon, "dynamic fire rate increase"))
				{
					damage *= 0.20;
				}
				
				
			}
		}
		if(damage < 0.0)
		{
			damage = 1.0;
		}
		
		if (damage > TF2_GetMaxHealth(victim))
		{
			damage = TF2_GetMaxHealth(victim)*0.99;
		}
	}
	return Plugin_Changed;
}
public OnEntityCreated(entity, const char[] classname)
{
	if(StrEqual(classname, "obj_sentrygun"))
    {
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Sentry); 
		CreateTimer(0.35, BuildingRegeneration, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(StrEqual(classname, "obj_dispenser"))
    {
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Sentry); 
		CreateTimer(0.35, BuildingRegeneration, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(StrEqual(classname, "obj_teleporter"))
    {
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Sentry); 
		CreateTimer(0.35, BuildingRegeneration, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (StrContains(classname, "tf_weapon_") != -1)
	{
		RequestFrame(RF_WeaponCreated, entity);
	}
	
	if (StrContains(classname, "obj_sentrygun") != -1)
	{
		RequestFrame(RF_SentryGunCreated, entity);
	}
}
GetEntLevel(entity)
{
    return GetEntProp(entity, Prop_Send, "m_iUpgradeLevel", 1);
}
AddEntHealth(entity, amount)
{
    SetVariantInt(amount);
    AcceptEntityInput(entity, "AddHealth");
}
public Action:BuildingRegeneration(Handle:timer, any:entity) 
{
	if(!IsValidEntity(entity) || !IsValidEdict(entity))
	{
		return;
	}
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hBuilder"); 
	if(!IsValidEntity(owner) || !IsValidEdict(owner))
	{
		return;
	}
	if(!IsClientInGame(owner))
	{
		return;
	}
	if(GetEntProp(entity, Prop_Send, "m_bDisabled") == 1)
	{
		return;
	}
	new BuildingMaxHealth = GetEntProp(entity, Prop_Send, "m_iMaxHealth");
	new BuildingHealth = GetEntProp(entity, Prop_Send, "m_iHealth");
	if(BuildingMaxHealth != BuildingHealth)
	{
		new mode = 1;
		if(mode == 1)
		{
			new melee = (GetPlayerWeaponSlot(owner,2));
			new Address:BuildingRegen = TF2Attrib_GetByName(melee, "Projectile speed decreased");
			if(BuildingRegen != Address_Null)
			{
				new Float:buildingHPRegen = TF2Attrib_GetValue(BuildingRegen);
				new Regeneration = RoundToNearest(((buildingHPRegen*BuildingMaxHealth)/100.0)/7.5);
				if(BuildingHealth < BuildingMaxHealth)
				{
					if((Regeneration + BuildingHealth) > BuildingMaxHealth)
					{
						AddEntHealth(entity, BuildingMaxHealth - BuildingHealth)
					}
					else
					{
						AddEntHealth(entity, Regeneration)
					}
				}
			}
		}
		if(mode == 2)
		{
			new Address:BuildingRegen = TF2Attrib_GetByName(owner, "disguise on backstab");
			if(BuildingRegen != Address_Null)
			{
				new Regeneration = RoundToNearest(TF2Attrib_GetValue(BuildingRegen)/3);
				if(BuildingHealth < BuildingMaxHealth)
				{
					if((Regeneration + BuildingHealth) > BuildingMaxHealth)
					{
						AddEntHealth(entity, BuildingMaxHealth - BuildingHealth)
					}
					else
					{
						AddEntHealth(entity, Regeneration)
					}
				}
			}
		}
	}
	new sentrynumber = EntRefToEntIndex(entity)
	new String:SentryObject[128];
	GetEdictClassname(sentrynumber, SentryObject, sizeof(SentryObject));
	if (StrEqual(SentryObject, "obj_sentrygun"))
	{
		new melee = (GetPlayerWeaponSlot(owner,2));
		new sentryLevel = GetEntLevel(entity);
		new shells = GetEntProp(entity, Prop_Send, "m_iAmmoShells");
		new rockets = GetEntProp(entity, Prop_Send, "m_iAmmoRockets");
		new Address:AmmoRegen = TF2Attrib_GetByName(melee, "disguise on backstab");
		if(AmmoRegen != Address_Null)
		{
			new AmmoRegeneration = RoundToNearest(TF2Attrib_GetValue(AmmoRegen)/5.0);
			
			if(sentryLevel != 1)
			{
				if((shells + AmmoRegeneration) < 200)
				{
					SetEntProp(entity, Prop_Send, "m_iAmmoShells", shells + AmmoRegeneration);
				}
				else
				{
					SetEntProp(entity, Prop_Send, "m_iAmmoShells", 200);
				}
			}
			else
			{
				if((shells + AmmoRegeneration) < 150)
				{
					SetEntProp(entity, Prop_Send, "m_iAmmoShells", shells + AmmoRegeneration);
				}
				else
				{
					SetEntProp(entity, Prop_Send, "m_iAmmoShells", 150);
				}
			}
			if(sentryLevel == 3)
			{
				if((rockets + (AmmoRegeneration/10)) < 20)
				{
					SetEntProp(entity, Prop_Send, "m_iAmmoRockets", rockets + (AmmoRegeneration/10));
				}
				else
				{
					SetEntProp(entity, Prop_Send, "m_iAmmoRockets", 20);
				}				
			}
		}
	}
} 
public Action:OnTakeDamagePre_Sentry(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom) 
{
	new hClientWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	//Bullet to Projectile Fix
	if(IsValidEntity(hClientWeapon))
	{
		new Address:overrideproj = TF2Attrib_GetByName(hClientWeapon, "override projectile type");
		new Address:bulletspershot = TF2Attrib_GetByName(hClientWeapon, "bullets per shot bonus");
		new Address:accscales = TF2Attrib_GetByName(hClientWeapon, "accuracy scales damage");
		if(overrideproj != Address_Null && bulletspershot != Address_Null)
		{
			new Float:override = TF2Attrib_GetValue(overrideproj);
			new Float:bps = TF2Attrib_GetValue(bulletspershot);
			if(accscales != Address_Null)
			{
				new Float:accuracyScales = TF2Attrib_GetValue(accscales);
				if(override == 2.0 || override == 6.0)
				{
					damage *= Pow(accuracyScales,0.95);
				}
			}
			if(override == 2.0 || override == 6.0)
			{
				damage *= bps;
			}
		}
	}
	return Plugin_Changed;
}
//pasted from https://github.com/xcalvinsz/tauntspeed/blob/master/addons/sourcemod/scripting/tauntspeed.sp
public void SetTauntAttackSpeed(int client, float speed)
{
	float flTauntAttackTime = GetEntDataFloat(client, g_iOffset);
	float flCurrentTime = GetGameTime();
	float flNextTauntAttackTime = flCurrentTime + ((flTauntAttackTime - flCurrentTime) / speed);
	if (flTauntAttackTime > 0.0)
	{
		SetEntDataFloat(client, g_iOffset, flNextTauntAttackTime, true);
		g_flLastAttackTime[client] = flNextTauntAttackTime;
		//This is to set the next attack time for taunts like spies knife where it attack 3 times
		//or sniper huntsman taunt where it daze the opponent then attacks
		DataPack hPack;
		CreateDataTimer(0.1, Timer_SetNextAttackTime, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		hPack.WriteCell(GetClientUserId(client));
		hPack.WriteFloat(speed);
	}
}

public Action Timer_SetNextAttackTime(Handle timer, DataPack hPack)
{
	hPack.Reset();
	int client = GetClientOfUserId(hPack.ReadCell());
	float flTauntAttackTime = GetEntDataFloat(client, g_iOffset);
	
	if (g_flLastAttackTime[client] == flTauntAttackTime)
	{
		return Plugin_Continue;
	}
	else if (g_flLastAttackTime[client] > 0.0 && flTauntAttackTime == 0.0)
	{
		g_flLastAttackTime[client] = 0.0;
		return Plugin_Stop;
	}
	else
	{
		float speed = hPack.ReadFloat();
		float flCurrentTime = GetGameTime();
		float flNextTauntAttackTime = flCurrentTime + ((flTauntAttackTime - flCurrentTime) / speed);
		SetEntDataFloat(client, g_iOffset, flNextTauntAttackTime, true);
		g_flLastAttackTime[client] = flNextTauntAttackTime;
	}
	return Plugin_Continue;
}
