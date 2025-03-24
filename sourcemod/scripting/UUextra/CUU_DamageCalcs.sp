/*
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <sdkhooks>
#include <dhooks>
*/

#pragma semicolon 1

#define PLUGIN_VERSION		"3.00"

#define MAX_SLOTS 5

//Bullet Weapons

#define BulletWeapons		"tf_weapon_pistol | tf_weapon_minigun | tf_weapon_raygun | tf_weapon_drg_pomson | tf_weapon_syringegun_medic | tf_weapon_revolver | tf_weapon_smg | tf_weapon_charged_smg | tf_weapon_sniperrifle | tf_weapon_sniperrifle_classic | tf_weapon_sniperrifle_decap | tf_weapon_shotgun | tf_weapon_sentry_revenge | tf_weapon_shotgun_primary | tf_weapon_shotgun_building_rescue | tf_weapon_shotgun_hwg | tf_weapon_shotgun_pyro | tf_weapon_shotgun_soldier | tf_weapon_handgun_scout_secondary | tf_weapon_scattergun | tf_weapon_handgun_scout_primary | tf_weapon_soda_popper | tf_weapon_pep_brawler_blaster"

#define ExplosiveWeapons	"tf_weapon_pipebomblauncher | tf_weapon_grenadelauncher | tf_weapon_cannon | tf_weapon_rocketlauncher_airstrike | tf_weapon_rocketlauncher | tf_weapon_particle_cannon | tf_weapon_rocketlauncher_directhit"

#define Flareguns			"tf_weapon_flaregun | tf_weapon_flaregun_revenge"

#define MeleeWeapons		"tf_weapon_slap | saxxy | tf_weapon_bonesaw | tf_weapon_knife | tf_weapon_club | tf_weapon_breakable_sign | tf_weapon_wrench | tf_weapon_robot_arm | tf_weapon_fists | tf_weapon_bottle | tf_weapon_sword | tf_weapon_stickbomb | tf_weapon_fireaxe | tf_weapon_shovel | tf_weapon_katana | tf_weapon_bat_fish | tf_weapon_bat | tf_weapon_bat_giftwrap | tf_weapon_bat_wood | tf_weapon_bottle"

#define SpecialWeapons		"tf_weapon_rocketlauncher_fireball"

#define FlameThrowers		"tf_weapon_flamethrower"

#define LightBulletWeapons "tf_weapon_pistol | tf_weapon_revolver | tf_weapon_smg | tf_weapon_charged_smg | tf_weapon_handgun_scout_secondary"

#define Bows "tf_weapon_compound_bow | tf_weapon_crossbow"

#define Cleaver "tf_weapon_cleaver"

new Handle:cvar_UseNewCalcs;


new Float:AdditionalDMG[MAXPLAYERS+1] = {1.0, ...};
new Float:AdditonalDMGReduction[MAXPLAYERS+1] = {1.0, ...};

//int Slots[5] = {0, 1, 2, 3, 4};


enum UpgradeSlot
{
	Slot_Primary = 0,
	Slot_Secondary = 1,
	Slot_Melee = 2,
	Slot_PDA = 3,
	Slot_Misc	= 4,
	Slot_MiscExt = 5,
	Slot_Max = 6
};


//new Float:DMGMult[MAXPLAYERS+1] = {0.0, ...};
new Float:Bulletspershot[MAXPLAYERS+1][7];


new Float:TotalDamage[MAXPLAYERS+1][7];

new Float:AccuracyScalesBonus[MAXPLAYERS+1][7];

new Float:AccuracyScalesTimer[MAXPLAYERS+1][7];

int AccuracyScalesStacks[MAXPLAYERS+1][7];

bool AccuracyScalesActive[MAXPLAYERS+1][7];

int Hits[MAXPLAYERS+1][7];

new Float:AuxDMGMult[MAXPLAYERS+1][7];

new Float:FakeDmg[MAXPLAYERS+1][7];

new Float:TotalResist[MAXPLAYERS+1] = {0.0, ...};

new Float:FinalResist[MAXPLAYERS+1] = {0.0, ...};


new Float:FinalDMG[MAXPLAYERS+1][6];
new Float:FinalDmgPre[MAXPLAYERS+1] = {1.0, ...};



//Resist Stuff
new Float:ArmorAddtionalResistance[MAXPLAYERS+1] = {1.0, ...};
new Float:ArmorReduction[MAXPLAYERS+1] = {0.0, ...};
new Float:VictimResistance[MAXPLAYERS+1];

new Float:ArmorAddtionalResistanceSentry[MAXPLAYERS+1] = {1.0, ...};
new Float:ArmorReductionSentry[MAXPLAYERS+1] = {0.0, ...};


//Spaghetti of Calculating weapon damage
stock UU_CalculateDmg(clientattacker, int clientweapon, int weaponslot)
{
	//slot = GetWeaponSlot(int client, int weapon)
	if (IsValidClient(clientattacker))
	{
		TotalDamage[clientattacker][weaponslot] = 0.0;
		Bulletspershot[clientattacker][weaponslot] = 1.0;
		
		
		//DMG Mults
		
		
		if (WepAttribCheck(clientweapon, "cannot giftwrap"))
		{
			TotalDamage[clientattacker][weaponslot] += (GetWepAttribValue(clientweapon, "cannot giftwrap")*(1.0+(GetWepAttribValue(clientweapon, "tool needs giftwrap")*0.055)));
		}
		if (WepAttribCheck(clientweapon, "tool needs giftwrap"))
		{
			TotalDamage[clientattacker][weaponslot] += (Pow(GetWepAttribValue(clientweapon, "tool needs giftwrap"),GetWepAttribValue(clientweapon, "cannot giftwrap")*0.0039))*Pow(GetWepAttribValue(clientweapon, "tool needs giftwrap"), 0.55);
		}
		
		//Dmg Bonuses
		if (WepAttribCheck(clientweapon, "damage bonus"))
		{
			TotalDamage[clientattacker][weaponslot] *= GetWepAttribValue(clientweapon, "damage bonus");
		}
		if (WepAttribCheck(clientweapon, "damage bonus HIDDEN"))
		{
			TotalDamage[clientattacker][weaponslot] *= GetWepAttribValue(clientweapon, "damage bonus HIDDEN");
		}
		if (WepAttribCheck(clientweapon, "damage penalty on bodyshot"))
		{
			if (GetWepAttribValue(clientweapon, "damage penalty on bodyshot") >= 1.0)
			{
				TotalDamage[clientattacker][weaponslot] *= GetWepAttribValue(clientweapon, "damage penalty on bodyshot");
			}
		}
		if (WepAttribCheck(clientweapon, "damage penalty vs player"))
		{
			if (GetWepAttribValue(clientweapon, "damage penalty vs player") >= 1.0)
			{
				TotalDamage[clientattacker][weaponslot] *= GetWepAttribValue(clientweapon, "damage penalty vs player");
			}
		}
		
		//Bullets per shot bonus
		if (WepAttribCheck(clientweapon, "bullets per shot bonus"))
		{
			TotalDamage[clientattacker][weaponslot] += GetWepAttribValue(clientweapon, "bullets per shot bonus")*(1.0+(GetWepAttribValue(clientweapon, "cannot giftwrap")*1.2));
		}
		
		//DMG Penalty
		if (WepAttribCheck(clientweapon, "damage penalty"))
		{
			TotalDamage[clientattacker][weaponslot] *= GetWepAttribValue(clientweapon, "damage penalty");
		}
		if (WepAttribCheck(clientweapon, "damage penalty on bodyshot"))
		{
			if (GetWepAttribValue(clientweapon, "damage penalty on bodyshot") < 1.0)
			{
				TotalDamage[clientattacker][weaponslot] *= GetWepAttribValue(clientweapon, "damage penalty on bodyshot");
			}
		}
		if (WepAttribCheck(clientweapon, "damage penalty vs player"))
		{
			if (GetWepAttribValue(clientweapon, "damage penalty vs player") < 1.0)
			{
				TotalDamage[clientattacker][weaponslot] *= GetWepAttribValue(clientweapon, "damage penalty vs player")*0.30;
			}
		}
		
		//Flat DMG Reduc
		if (WepAttribCheck(clientweapon, "flat damage reduction"))
		{
			TotalDamage[clientattacker][weaponslot] -= GetWepAttribValue(clientweapon, "flat damage reduction");
		}
		if (WepAttribCheck(clientweapon, "flat damage increase"))
		{
			TotalDamage[clientattacker][weaponslot] += GetWepAttribValue(clientweapon, "flat damage increase");
		}
		
		//CalculateResist(clientvictim);
		
		FinalDMG[clientattacker][weaponslot] = (TotalDamage[clientattacker][weaponslot]+AccuracyScalesBonus[clientattacker][weaponslot])+AuxDMGMult[clientattacker][weaponslot];
		
		
		
		//PrintToChat(clientattacker, "Victim Armor: %.0f \n Your Total Damage %.2f \n Final Damage %.2f", FinalResist[clientvictim], TotalDamage[clientattacker], FinalDMG[clientattacker]);
		
		/*
		PrintToChat(clientvictim, "Your Armor: %.0f \n Attacker's Total Damage %.2f \n Final Damage %.2f", TotalResist[clientvictim], TotalDamage[clientattacker], FinalDMG[clientattacker]);
		*/
		//Final Calculations
	}
	else {return;}
}


//Custom Accuracy scales stuff
stock CalculateAccuracyScales(client, clientweapon, slot)
{
	if (!IsValidClient(client) || !IsValidEntity(clientweapon)){return;}
	
	if (AccuracyScalesStacks[client][slot] < 10)
	{
		AccuracyScalesStacks[client][slot] += 1;
		AccuracyScalesBonus[client][slot] += (FinalDMG[client][slot]*0.8)*GetWepAttribValue(clientweapon, "accuracy scales custom");
		UU_CalculateDmg(client, clientweapon, slot);
		PrintToConsole(client, "Damage added from Accuracy Scales: %.2f for weapon slot %d", AccuracyScalesBonus[client][slot], slot);
	}
}

stock ResetAccuracyScales(client, clientweapon, slot)
{
	if (!IsValidClient(client) || !IsValidEntity(clientweapon)){return;}
	
	AccuracyScalesBonus[client][slot] = 0.0;
	AccuracyScalesStacks[client][slot] = 0;
	Hits[client][slot] = 0;
	AccuracyScalesTimer[client][slot] = 0.0;
	AccuracyScalesActive[client][slot] = false;
	UU_CalculateDmg(client, clientweapon, slot);
	PrintToConsole(client, "Reset Accuracy Scales for weapon slot %d", slot);
}

//Fire rate to dmg, a little too good, tune later
stock FireRateToDMG(client, clientweapon, slot)
{
	if (!IsValidClient(client) || !IsValidEntity(clientweapon)){return;}
	
	AuxDMGMult[client][slot] = 0.0;
	
	if (WepAttribCheck(clientweapon, "fire rate bonus custom"))
	{
		AuxDMGMult[client][slot] += (FinalDMG[client][slot]*0.2)*(Pow(GetWepAttribValue(clientweapon, "fire rate bonus custom"),-0.81));
	}
	
	if (WepAttribCheck(clientweapon, "fire rate penalty custom"))
	{
		AuxDMGMult[client][slot] += (FinalDMG[client][slot]*0.2)*(Pow(GetWepAttribValue(clientweapon, "fire rate penalty custom"),-0.81));
	}
	PrintToChat(client, "Dmg mult from fire rate to dmg conversion: %.2f", AuxDMGMult[client][slot]);
	
}

//DLSS for dmg baby woooo... Doesn't actually do anything, just purely visual
stock CalculateFakeDMG(client, slot)
{
	if (!IsValidClient(client)) {return;}
	
	if (ClientAttribCheck(client, "dlss"))
	{
		for (int i = 0; i < 5; i++)
		{
			new ActiveSlot = TF2_GetClientActiveSlot(client);
			if (ActiveSlot == i)
			{
				FakeDmg[client][ActiveSlot] = (FinalDMG[client][slot]+(GetEngineTime()/(GetEngineTime()*2.0)))*((GetClientAttribValue(client, "dlss")*4.0));
			
			}
		}
	}
}
	
//Calculate Client Resistance, much easier using additive health instead of power supply
stock CalculateResist(client)
{
	if (!IsValidClient(client)){return;}
	
	new Float:clientHealth = GetClientAttribValue(client, "max health additive bonus");
	new Float:DmgReducMult = 1.0;
	
	if (IsFakeClient(client)){clientHealth = GetClientAttribValue(client, "max health additive penalty");}
	
	
	//Additional Resistance provided by armor supply
	AdditonalDMGReduction[client] = (Pow(clientHealth,0.85));
	//Prevent Division by Decimal
	if (ArmorAddtionalResistance[client] < 1.0)
	{
		ArmorAddtionalResistance[client] = 1.0;
	}

	if (ClientAttribCheck(client, "damage reduction"))
	{
		VictimResistance[client] = GetClientAttribValue(client, "damage reduction");
	}
	
	if (ClientAttribCheck(client, "damage reduction multiplier"))
	{
		DmgReducMult += GetClientAttribValue(client, "damage reduction multiplier");
	}
	ArmorAddtionalResistance[client] = (Pow(clientHealth ,0.29));
	
	//Formula 1 (test 1)
	//TotalResist[client] = (Pow(VictimResistance[client], (ArmorAddtionalResistance[client]*0.024))+AdditonalDMGReduction[client]);
	
	//Formula 2 (test 2)
	//TotalResist[client] = Pow((VictimResistance[client]*ArmorAddtionalResistance[client]), (ArmorAddtionalResistance[client]*0.023))+AdditonalDMGReduction[client]*2.1;
	
	//Formula 3 (Final)
	TotalResist[client] = clientHealth+(((VictimResistance[client]*ArmorAddtionalResistance[client]))*(DmgReducMult*Pow(VictimResistance[client], 0.1)));
	
	if (TotalResist[client] > 0.0)
	{
		FinalResist[client] = ((Pow(TotalResist[client], -0.025)-TotalResist[client])*(Pow(VictimResistance[client], -0.055)))*-1.0;
	}
	else
	{
		FinalResist[client] = 0.0;
	}
}

stock ResetResists(client)
{
	if (IsValidClient(client))
	{
		ArmorAddtionalResistance[client] = 1.0;
		ArmorReduction[client] = 1.0;
		VictimResistance[client] = 1.0;
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
	else{return 1.0;}
}


stock bool ClientAttribCheck(client, const char[] attribname)
{
	if (IsValidClient(client))
	{
		new Address:Attrib = TF2Attrib_GetByName(client, attribname);
		
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
	else{return 1.0;}
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
		if (weapon == GetPlayerWeaponSlot(client, i))
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

stock bool:IsCritBoosted(client) // Nergal :D
{
    if (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) || TF2_IsPlayerInCondition(client, TFCond_CritCanteen) || TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin) || TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) || TF2_IsPlayerInCondition(client, TFCond_CritOnKill) || TF2_IsPlayerInCondition(client, TFCond_CritMmmph) || TF2_IsPlayerInCondition(client, TFCond_CritOnDamage))
    {
        return true;
    }
    return false;
}