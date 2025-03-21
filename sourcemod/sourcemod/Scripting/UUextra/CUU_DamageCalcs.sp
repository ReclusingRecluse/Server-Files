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

#define PLUGIN_VERSION		"2.00"

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



//new Float:DMGMult[MAXPLAYERS+1] = {0.0, ...};
new Float:Bulletspershot[MAXPLAYERS+1] = {0.0, ...};
new Float:ExtraDmgBonus[MAXPLAYERS+1] = {0.0, ...};
new Float:Flatdmgreduction[MAXPLAYERS+1] = {0.0, ...};
new Float:Flatdmgincrease[MAXPLAYERS+1] = {0.0, ...};

new Float:DMGMultBullet[MAXPLAYERS+1] = {0.0, ...};
new Float:DMGMultBlast[MAXPLAYERS+1] = {0.0, ...};
new Float:DMGMultFire[MAXPLAYERS+1] = {0.0, ...};
new Float:DMGMultFlare[MAXPLAYERS+1] = {0.0, ...};
new Float:DMGMultMelee[MAXPLAYERS+1] = {0.0, ...};


new Float:FinalDMG[MAXPLAYERS+1] = {1.0, ...};
new Float:FinalDmgPre[MAXPLAYERS+1] = {1.0, ...};

new Float:DmgMultSentry[MAXPLAYERS+1] = {0.0, ...};

new Float:SentryFinalDMGPre[MAXPLAYERS+1] = {1.0, ...};
new Float:SentryFinalDMG[MAXPLAYERS+1] = {1.0, ...};
new Float:AdditionalDMGSentry[MAXPLAYERS+1] = {1.0, ...};
new Float:AdditonalDMGReductionSentry[MAXPLAYERS+1] = {1.0, ...};


//Resist Stuff
new Float:ArmorAddtionalResistance[MAXPLAYERS+1] = {1.0, ...};
new Float:ArmorReduction[MAXPLAYERS+1] = {0.0, ...};
new Float:VictimResistance[MAXPLAYERS+1] = {1.0, ...};
new Float:VictimSentryResistance[MAXPLAYERS+1] = {1.0, ...};

new Float:ArmorAddtionalResistanceSentry[MAXPLAYERS+1] = {1.0, ...};
new Float:ArmorReductionSentry[MAXPLAYERS+1] = {0.0, ...};

/*
public Plugin:myinfo =
{
	name		= "Uberupgrades Damage Manager",
	author		= "Recluse",
	description	= "General Damage Stuff",
	version		= PLUGIN_VERSION,
};
*/

//Hooks


//Secondary Hook in case of plugin reload

/*
public OnPluginStart()
{
	cvar_UseNewCalcs = CreateConVar("sm_damagecalcs", "0", "Use New Calcs. Default: 0");
	for(new i=0; i<=MaxClients; i++)
	{
		HookEvent("player_hurt", Event_Playerhurt);
		if(!IsValidClient(i)){continue;}
		SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public OnPluginEnd()
{
	for(new i=0; i<=MaxClients; i++)
	{
		if(!IsValidClient(i)){continue;}
		SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}
*/

/* || StrEqual(cls, "obj_attachment_sapper")*/

/*
public OnEntityCreated(Ent, const String:cls[])
{
	if (StrEqual(cls, "obj_sentrygun") || StrEqual(cls, "obj_dispenser") || StrEqual(cls, "tank_boss") || StrEqual(cls, "obj_teleporter"))
	{
		SDKHook(Ent, SDKHook_OnTakeDamage, OnTakeDamage_Ent);
	}
}
*/

/*
public OnClientPutInServer(client)
{
	if (IsValidClient(client))
	{
		//ResetResists(client);
	
		//SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		
		DMGMultBullet[client] = 1.0;
		DMGMultBlast[client] = 1.0;
		DMGMultFire[client] = 1.0;
		DMGMultFlare[client] = 1.0;
		DMGMultMelee[client] = 1.0;
		Bulletspershot[client] = 1.0;
		ExtraDmgBonus[client] = 1.0;
		FinalDMG[client] = 0.0;
	}
}
*/

/*
public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}
*/

/*
public Action:Event_Playerhurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Float:damage = GetEventFloat(event, "damageamount");
	
	if (IsValidClient(victim) && IsValidClient(attacker))
	{
		if (victim != attacker)
		{
			new AttackerWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			
			if (IsValidEntity(AttackerWeapon))
			{
				if (WepAttribCheck(AttackerWeapon, "is_operation_pass"))
				{
					new Float:ReturnHealth = ((damage*0.13)*(GetWepAttribValue(AttackerWeapon, "is_operation_pass")*1.15));
				
				
					AddPlayerHealth(attacker, RoundToFloor(ReturnHealth), 1.0);
					ShowHealthGain(attacker, RoundToFloor(ReturnHealth), victim);
				
					fl_CurrentArmor[attacker] += ReturnHealth*0.5;
				}
			}
		}
	}
}
*/

/*
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsValidClient(attacker) && IsPlayerAlive(attacker) && !(damagetype & DMG_NERVEGAS))
	{
		new AttackerWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		
		new String:classname[128]; 
		GetEdictClassname(AttackerWeapon, classname, sizeof(classname));
		
		if(strcmp("obj_sentrygun", classname))
		{
			new MeleeWeapon2=GetPlayerWeaponSlot(attacker,2);
			if (IsValidEntity(MeleeWeapon2))
			{
				UU_SentryCalc(MeleeWeapon2, attacker, victim);
				SentryFinalDMGPre[attacker] = (SentryFinalDMG[attacker]*1.20)*(AdditionalDMGSentry[attacker]*0.80);
			
				damage = (SentryFinalDMGPre[attacker]*0.17);
			
				if (IsFakeClient(victim))
				{
					damage *= 100000.0;
				}
			}
		}
		
		if (IsValidEntity(AttackerWeapon) && victim != attacker)
		{
			
			
			
			if (!IsFakeClient(victim))
			{
				if (IsFakeClient(attacker))
				{
					if (!IsMvM())
					{
						FinalDmgPre[attacker] = ((FinalDMG[attacker]*AdditionalDMG[attacker]*0.44))*2.0;
					}
					else
					{
						FinalDmgPre[attacker] = FinalDMG[attacker]*(AdditionalDMG[attacker]*0.44);
					}
				}
				else
				{
					FinalDmgPre[attacker] = (FinalDMG[attacker]*(AdditionalDMG[attacker]*0.44))*0.80;
				}
				
			}
			
			if (IsFakeClient(victim))
			{
				if (IsFakeClient(attacker))
				{
					FinalDmgPre[attacker] = (FinalDMG[attacker]*(AdditionalDMG[attacker]*0.44))*25.0;
				}
				else
				{
					FinalDmgPre[attacker] = (FinalDMG[attacker]*(AdditionalDMG[attacker]*0.44))*0.55;
				}
			}
			
			damage = FinalDmgPre[attacker];
				
			if (damagetype & DMG_BURN)
			{
				damage = (FinalDmgPre[attacker]*0.3)*0.10;
			}
			
			if (damagetype & DMG_SLASH)
			{
				damage *= 0.05;
			}
			
			if (strcmp(LightBulletWeapons, classname))
			{
				if (!IsFakeClient(victim) && !IsFakeClient(attacker))
				{
					if (!(damagetype & DMG_SLASH) && !(damagetype & DMG_BURN))
					{
						damage *= 2.0;
					}
				}
			}
			
			if (strcmp(Cleaver, classname))
			{
				damage *= 0.30;
				damagetype |= DMG_CLUB;
			}
			
			if (WepAttribCheck(AttackerWeapon, "dynamic fire rate increase"))
			{
				damage *= 0.20;
			}
			
			
			
			if (strcmp(Bows, classname))
			{
				damage += 1.0;
				
				if (damage > 1.0)
				{
					damage += 30.0;
					damage *= 20.0;
				}
			}
		}
	}
	return Plugin_Changed;
}
*/

/*
public Action:Timer_DmgCalc(Handle:Timer, any:attacker)
{
	if (IsValidClient(attacker))
	{
		for ( new victim = 1; victim <= MaxClients; victim++ )
		{
			if (IsValidClient(victim) && GetClientTeam(attacker) != GetClientTeam(victim))
			{
				new AttackerWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
				
				if (IsValidEntity(AttackerWeapon))
				{
					UU_CalculateDmg(AttackerWeapon, attacker, victim);
				}
			}
		}
	}
}
*/

stock UU_SentryCalc(c_weapon, clientattacker, clientvictim)
{
	if (IsValidEntity(c_weapon) && IsValidClient(clientattacker) && IsValidClient(clientvictim))
	{
		DmgMultSentry[clientattacker] = 0.0;
		AdditionalDMGSentry[clientattacker] = 1.0;
		
		//Additional Resistance provided by armor supply
		ArmorAddtionalResistanceSentry[clientvictim] = (Pow(fl_CurrentArmor[clientvictim]*1.8,0.8)*6.0);
		AdditonalDMGReductionSentry[clientvictim] = (Pow(fl_CurrentArmor[clientvictim],-0.10))*0.8;
		//Prevent Division by Decimal
		if (ArmorAddtionalResistanceSentry[clientvictim] < 1.0)
		{
			ArmorAddtionalResistanceSentry[clientvictim] = 1.0;
		}
		//Additional Damage Taken for having low armor supply
		ArmorReductionSentry[clientvictim] = (fl_CurrentArmor[clientvictim]/100.0)*1.75;
		AdditionalDMGSentry[clientattacker] = fl_CurrentArmor[clientvictim]/Pow((ArmorReductionSentry[clientvictim]),1.1);
		
		if (AdditionalDMGSentry[clientattacker] > 10.0)
		{
			AdditionalDMGSentry[clientattacker] = 10.0;
		}
		
		if (WepAttribCheck(c_weapon, "add cloak on hit"))
		{
			DmgMultSentry[clientattacker] += 3.0*Pow(1.9,GetWepAttribValue(c_weapon, "add cloak on hit"))*4.0;
		}
		if (WepAttribCheck(c_weapon, "flame_up_speed"))
		{
			DmgMultSentry[clientattacker] += 8.0*Pow(2.2,(GetWepAttribValue(c_weapon, "flame_up_speed")*0.66))*5.5;
		}
		if (WepAttribCheck(c_weapon, "flame_drag"))
		{
			DmgMultSentry[clientattacker] += 16.0*Pow(2.4,(GetWepAttribValue(c_weapon, "flame_up_speed")*0.66))*7.0;
		}
		
		if (ClientAttribCheck(clientvictim, "referenced item id low"))
		{
			VictimSentryResistance[clientvictim] = GetClientAttribValue(clientvictim, "referenced item id low")/10.0;
		}
		
		if (DmgMultSentry[clientattacker] > 0.0)
		{
			SentryFinalDMG[clientattacker] = ((DmgMultSentry[clientattacker]/(ArmorAddtionalResistanceSentry[clientvictim]*VictimSentryResistance[clientvictim]*0.5+ArmorReductionSentry[clientvictim]*10))*AdditonalDMGReductionSentry[clientvictim]);
			//PrintToChat(clientattacker, "Damage calc : %.0f", SentryFinalDMG[clientattacker]);
		}
	}
}

stock UU_CalculateDmg(cw, clientattacker, clientvictim)
{
	
	if (IsValidEntity(cw) && IsValidClient(clientattacker) && IsValidClient(clientvictim))
	{
		DMGMultBullet[clientattacker] = 1.0;
		DMGMultBlast[clientattacker] = 1.0;
		DMGMultFire[clientattacker] = 1.0;
		DMGMultFlare[clientattacker] = 1.0;
		DMGMultMelee[clientattacker] = 1.0;
		Bulletspershot[clientattacker] = 1.0;
		ExtraDmgBonus[clientattacker] = 1.0;
		Flatdmgreduction[clientattacker] = 0.0;
		Flatdmgincrease[clientattacker] = 0.0;
		ArmorReduction[clientvictim] = 1.0;
		ArmorAddtionalResistance[clientvictim] = 1.0;
		AdditonalDMGReduction[clientvictim] = 1.0;
		VictimResistance[clientvictim] = 1.0;
		
		//PrintToChat(clientattacker, "Victim armor %.0f", fl_CurrentArmor[clientvictim]);
		
		
		//Additional Resistance provided by armor supply
		ArmorAddtionalResistance[clientvictim] = (Pow(fl_CurrentArmor[clientvictim],0.8)*1.5);
		AdditonalDMGReduction[clientvictim] = (Pow(fl_CurrentArmor[clientvictim],-0.09));
		//Prevent Division by Decimal
		if (ArmorAddtionalResistance[clientvictim] < 1.0)
		{
			ArmorAddtionalResistance[clientvictim] = 1.0;
		}
		//Additional Damage Taken for having low armor supply
		ArmorReduction[clientvictim] = ((fl_CurrentArmor[clientvictim])/100.0)*0.60;
		AdditionalDMG[clientattacker] = fl_CurrentArmor[clientvictim]/Pow((ArmorReduction[clientvictim]),1.1);
		
		if (AdditionalDMG[clientattacker] > 8.0)
		{
			AdditionalDMG[clientattacker] = 8.0;
		}
		//36.41
		//final Calcualtion
		
		//DMG Mults
		
		//Bullets per shot bonus
		if (WepAttribCheck(cw, "bullets per shot bonus"))
		{
			Bulletspershot[clientattacker] += GetWepAttribValue(cw, "bullets per shot bonus")+3.0;
		}
		
		//Dmg Bonuses
		if (WepAttribCheck(cw, "damage bonus"))
		{
			ExtraDmgBonus[clientattacker] += GetWepAttribValue(cw, "damage bonus");
		}
		if (WepAttribCheck(cw, "damage bonus HIDDEN"))
		{
			ExtraDmgBonus[clientattacker] += GetWepAttribValue(cw, "damage bonus HIDDEN");
		}
		if (WepAttribCheck(cw, "damage penalty on bodyshot"))
		{
			if (GetWepAttribValue(cw, "damage penalty on bodyshot") >= 1.0)
			{
				ExtraDmgBonus[clientattacker] += GetWepAttribValue(cw, "damage penalty on bodyshot");
			}
		}
		if (WepAttribCheck(cw, "damage penalty vs player"))
		{
			if (GetWepAttribValue(cw, "damage penalty vs player") >= 1.0)
			{
				ExtraDmgBonus[clientattacker] += GetWepAttribValue(cw, "damage penalty vs player");
			}
		}
		
		//DMG Penalty
		if (WepAttribCheck(cw, "damage penalty"))
		{
			ExtraDmgBonus[clientattacker] *= GetWepAttribValue(cw, "damage penalty");
		}
		if (WepAttribCheck(cw, "damage penalty on bodyshot"))
		{
			if (GetWepAttribValue(cw, "damage penalty on bodyshot") < 1.0)
			{
				ExtraDmgBonus[clientattacker] *= GetWepAttribValue(cw, "damage penalty on bodyshot");
			}
		}
		if (WepAttribCheck(cw, "damage penalty vs player"))
		{
			if (GetWepAttribValue(cw, "damage penalty vs player") < 1.0)
			{
				ExtraDmgBonus[clientattacker] *= GetWepAttribValue(cw, "damage penalty vs player")*0.30;
			}
		}
		
		//Flat DMG Reduc
		if (WepAttribCheck(cw, "flat damage reduction"))
		{
			Flatdmgreduction[clientattacker] = GetWepAttribValue(cw, "flat damage reduction");
		}
		if (WepAttribCheck(cw, "flat damage increase"))
		{
			Flatdmgincrease[clientattacker] = GetWepAttribValue(cw, "flat damage increase");
		}
		
		
		//Bullet
		if (WepAttribCheck(cw, "cannot giftwrap"))
		{
			DMGMultBullet[clientattacker] += 1.0+Pow(1.70,GetWepAttribValue(cw, "cannot giftwrap")*0.21)*4.2;
		}
		if (WepAttribCheck(cw, "tool needs giftwrap"))
		{
			DMGMultBullet[clientattacker] *= 1.0+Pow(2.12,(GetWepAttribValue(cw, "tool needs giftwrap")*0.32))*4.2;
		}
		
		//Blast
		if (WepAttribCheck(cw, "custom_paintkit_seed_lo"))
		{
			DMGMultBlast[clientattacker] += 6.0+Pow(1.3,GetWepAttribValue(cw, "custom_paintkit_seed_lo"))*5.0;
		}
		if (WepAttribCheck(cw, "custom_paintkit_seed_hi"))
		{
			DMGMultBlast[clientattacker] *= 9.0+Pow(1.55,(GetWepAttribValue(cw, "custom_paintkit_seed_hi")*0.66))*5.0;
		}
		
		//Fire
		if (WepAttribCheck(cw, "random drop line item 0"))
		{
			DMGMultFire[clientattacker] += 3.0+Pow(1.9,GetWepAttribValue(cw, "random drop line item 0"))*3.9;
		}
		if (WepAttribCheck(cw, "random drop line item 1"))
		{
			DMGMultFire[clientattacker] *= 3.0+Pow(1.86,(GetWepAttribValue(cw, "random drop line item 1")*0.66))*4.3;
		}
		
		//Dragons Fury
		if (WepAttribCheck(cw, "tool target item"))
		{
			DMGMultFire[clientattacker] += 2.0+Pow(1.75,(GetWepAttribValue(cw, "tool target item")*0.55))*5.0;
		}
		if (WepAttribCheck(cw, "end drop date"))
		{
			DMGMultFire[clientattacker] *= 5.0+Pow(2.2,(GetWepAttribValue(cw, "end drop date")*0.66))*6.0;
		}
		if (WepAttribCheck(cw, "spellbook page attr id"))
		{
			DMGMultFire[clientattacker] += 2.7+Pow(1.55,(GetWepAttribValue(cw, "spellbook page attr id")*0.66))*4.0;
		}
		
		//Melee
		if (WepAttribCheck(cw, "custom texture hi"))
		{
			DMGMultMelee[clientattacker] += 1.0+Pow(1.45,GetWepAttribValue(cw, "custom texture hi"))*3.2;
		}
		if (WepAttribCheck(cw, "cannot_transmute"))
		{
			DMGMultMelee[clientattacker] *= 1.0+Pow(1.54,(GetWepAttribValue(cw, "cannot_transmute")*0.66))*4.5;
		}
		if (WepAttribCheck(cw, "always_transmit_so"))
		{
			DMGMultMelee[clientattacker] += 1.0+Pow(1.1,(GetWepAttribValue(cw, "always_transmit_so")*0.88))*8.0;
		}
		
		//Flare Guns
		if (WepAttribCheck(cw, "random drop line item 2"))
		{
			DMGMultFlare[clientattacker] *= 10.0+Pow(1.1,GetWepAttribValue(cw, "random drop line item 2"))*9.0;
		}
		if (WepAttribCheck(cw, "random drop line item 3"))
		{
			DMGMultFlare[clientattacker] *= 12.0+Pow(1.2,(GetWepAttribValue(cw, "random drop line item 3")*1.70))*9.0;
		}
		
		if (ClientAttribCheck(clientvictim, "referenced item id low"))
		{
			VictimResistance[clientvictim] = GetClientAttribValue(clientvictim, "referenced item id low")/10.0;
		}
		//maxed resist value: 0.029
		
		//Final Calculations
		if (DMGMultBullet[clientattacker] > 1.0)
		{
			FinalDMG[clientattacker] = ((((DMGMultBullet[clientattacker]*ExtraDmgBonus[clientattacker])+Flatdmgincrease[clientattacker])-Flatdmgreduction[clientattacker])/(ArmorReduction[clientvictim]*0.30/(AdditonalDMGReduction[clientvictim]*(VictimResistance[clientvictim]*9.0))))*Bulletspershot[clientattacker];
			
			/*
			PrintToChat(clientattacker, "Damage mult = %.2f", DMGMultBullet[clientattacker]);
			PrintToChat(clientattacker, "Victim Resistance Level = %.2f", (ArmorReduction[clientvictim]/(AdditonalDMGReduction[clientvictim]*(VictimResistance[clientvictim]*9.0))));
			PrintToChat(clientattacker, "Damage calc = %.2f", FinalDMG[clientattacker]);
			*/
		}
		else if (DMGMultBlast[clientattacker] > 1.0)
		{
			
			FinalDMG[clientattacker] = ((((DMGMultBlast[clientattacker]*ExtraDmgBonus[clientattacker])+Flatdmgincrease[clientattacker])-Flatdmgreduction[clientattacker])/(ArmorReduction[clientvictim]*0.60/(AdditonalDMGReduction[clientvictim]*(VictimResistance[clientvictim]*6.0))));
			/*
			PrintToChat(clientattacker, "Damage mult = %.2f", DMGMultBlast[clientattacker]);
			PrintToChat(clientattacker, "Victim Resistance Level = %.2f", (ArmorReduction[clientvictim]/(AdditonalDMGReduction[clientvictim]*(VictimResistance[clientvictim]*6.0))));
			PrintToChat(clientattacker, "Damage calc = %.2f", FinalDMG[clientattacker]);
			*/
		}
		else if (DMGMultFire[clientattacker] > 1.0)
		{
			
			FinalDMG[clientattacker] = ((((DMGMultFire[clientattacker]*ExtraDmgBonus[clientattacker])+Flatdmgincrease[clientattacker])-Flatdmgreduction[clientattacker])/(ArmorReduction[clientvictim]*0.30/(AdditonalDMGReduction[clientvictim]*(VictimResistance[clientvictim]*7.0))));
			/*
			PrintToChat(clientattacker, "Damage mult = %.2f", DMGMultFire[clientattacker]);
			PrintToChat(clientattacker, "Victim Resistance Level = %.2f", (ArmorReduction[clientvictim]/(AdditonalDMGReduction[clientvictim]*(VictimResistance[clientvictim]*7.0))));
			PrintToChat(clientattacker, "Damage calc = %.2f", FinalDMG[clientattacker]);
			*/
		}
		else if (DMGMultMelee[clientattacker] > 1.0)
		{
			
			FinalDMG[clientattacker] = ((((DMGMultMelee[clientattacker]*ExtraDmgBonus[clientattacker])+Flatdmgincrease[clientattacker])-Flatdmgreduction[clientattacker])/(ArmorReduction[clientvictim]*0.30/(AdditonalDMGReduction[clientvictim]*(VictimResistance[clientvictim]*7.0))));
			/*
			PrintToChat(clientattacker, "Damage mult = %.2f", DMGMultMelee[clientattacker]);
			PrintToChat(clientattacker, "Victim Resistance Level = %.2f", (ArmorReduction[clientvictim]/(AdditonalDMGReduction[clientvictim]*(VictimResistance[clientvictim]*7.0))));
			PrintToChat(clientattacker, "Damage calc = %.2f", FinalDMG[clientattacker]);
			*/
		}
		else if (DMGMultFlare[clientattacker] > 1.0)
		{
			FinalDMG[clientattacker] = ((((DMGMultFlare[clientattacker]*ExtraDmgBonus[clientattacker])+Flatdmgincrease[clientattacker])-Flatdmgreduction[clientattacker])/(ArmorReduction[clientvictim]*0.20/(AdditonalDMGReduction[clientvictim]*(VictimResistance[clientvictim]*11.0))));
			
			/*
			PrintToChat(clientattacker, "Damage mult = %.2f", DMGMultFlare[clientattacker]);
			PrintToChat(clientattacker, "Victim Resistance Level = %.2f", (ArmorReduction[clientvictim]/(AdditonalDMGReduction[clientvictim]*(VictimResistance[clientvictim]*11.0))));
			PrintToChat(clientattacker, "Damage calc = %.2f", FinalDMG[clientattacker]);
			*/
		}
		else
		{
			FinalDMG[clientattacker] = 1.0;
		}
	}
	else {return;}
}

public Action:OnTakeDamage_Ent(Ent, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (IsValidClient(attacker))
	{
		new AttackerWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		
		new String:classname[128]; 
		GetEdictClassname(inflictor, classname, sizeof(classname));
		
		if (IsValidEntity(AttackerWeapon))
		{
			if (strcmp(Bows, classname))
			{
				new Address:Dmg1 = TF2Attrib_GetByName(AttackerWeapon, "tool target item");
				new Address:Dmg2 = TF2Attrib_GetByName(AttackerWeapon, "tool needs giftwrap");
				
				if (Dmg1 && Dmg2!=Address_Null)
				{
					new Float:Noom = TF2Attrib_GetValue(Dmg1)+TF2Attrib_GetValue(Dmg2);
					damage *= Noom;
				}
				//damage += 700.0;
			}
		}
	}
	return Plugin_Changed;
}


stock ResetResists(client)
{
	if (IsValidClient(client))
	{
		ArmorAddtionalResistance[client] = 1.0;
		ArmorReduction[client] = 1.0;
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
