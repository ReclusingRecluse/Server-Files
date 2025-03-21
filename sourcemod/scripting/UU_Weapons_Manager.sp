#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <sdkhooks>
#include <dhooks>
#include <UU_StatusEffects>
#include <tf_econ_dynamic>
#include <morecolors>
#include <tf2utils>
#include <custom_status_hud_Weapons>


//#define UpdateURl	"http://drive.google.com/file/d/1I8fz1dhmWfWa5gqo3tw5IbGv_EE_S_oK/view?usp=sharing"

//Weapon Specific SPs
#include "UU_Weapons/Black Box.sp"
#include "UU_Weapons/Cow Mangler.sp"
#include "UU_Weapons/Liberty Launcher.sp"
#include "UU_Weapons/Direct Hit.sp"
#include "UU_Weapons/Scorch Shot.sp"
#include "UU_Weapons/Flare gun.sp"
#include "UU_Weapons/Fortified Compound.sp"
#include "UU_Weapons/Brass Beast.sp"
//#include "UU_Weapons/Airstrike.sp"
//#include "UU_Weapons/Enforcer.sp"
//#include "UU_Weapons/Beggars Bazooka.sp"
//#include "UU_Weapons/Phlog.sp"
//#include "UU_Weapons/QuickieBomb.sp"
//#include "UU_Weapons/Natascha.sp"
//#include "UU_Weapons/Loch N Load.sp"

//Important Functions
#include "UU_Weapons/CalcAttackCritical.sp"
#include "UU_Weapons/OnGameFrame.sp"
#include "UU_Weapons/TenthSecondTimer.sp"
#include "UU_Weapons/TwentiethSecondTimer.sp"
#include "UU_Weapons/OnClientPreThink.sp"
#include "UU_Weapons/OnTakeDamageAlive.sp"




//Handle g_UU_weapons_hud;


public OnMapStart()
{
	PrecacheSound(SOUND_EXPLO);
}

public Action:OnCustomStatusHUDUpdate3(int client, StringMap entries) 
{
	if (IsValidClient(client))
	{
		char P_Arrow[32];
		char Ember[32];
		char Amplified[32];
		char MangleMult[32];
		char Thunder[32];
		char Arcstrike[32];
		
		new clientweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(clientweapon))
		{
			if (WepAttribCheck(clientweapon, "scorch shot extreme"))
			{
				Format(Ember, sizeof(Ember), "Ember %.0f", Ember_stacks[client]);
				entries.SetString("weapons_ember", Ember);
			}
			if (WepAttribCheck(clientweapon, "void mangler"))
			{
				Format(MangleMult, sizeof(MangleMult), "Damage Mult %.2f", Totaldamage[client]);
				entries.SetString("weapons_mangler", MangleMult);
			}
			if (WepAttribCheck(clientweapon, "strand poison explosion"))
			{
				Format(P_Arrow, sizeof(P_Arrow), "Poison Arrow Ready");
				entries.SetString("weapons_lemonarque", P_Arrow);
			}
			if (WepAttribCheck(clientweapon, "thunderlord"))
			{
				if (HitBonusActive[client])
				{
					Format(Thunder, sizeof(Thunder), "Unleash The Thunder");
					entries.SetString("weapons_thunder_lord", Thunder);
				}
			}
			if (WepAttribCheck(clientweapon, "abbadon"))
			{
				if (HitBonusActive[client])
				{
					Format(Thunder, sizeof(Thunder), "Unleash The Flames");
					entries.SetString("weapons_abbadon", Thunder);
				}
			}
			if (WepAttribCheck(clientweapon, "nova mortis"))
			{
				if (HitBonusActive[client])
				{
					Format(Thunder, sizeof(Thunder), "Unleash The Void");
					entries.SetString("weapons_nova_mortis", Thunder);
				}
			}
			if (WepAttribCheck(clientweapon, "arcstrike") || WepAttribCheck(clientweapon, "airborne bonus arc"))
			{
				if (Arcstrike_bonus_active[client])
				{
					Format(Arcstrike, sizeof(Arcstrike), "Airborne Bonus");
					entries.SetString("weapons_arc_strike", Arcstrike);
				}
			}
		}
	}
	return Plugin_Changed;
}

/*
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UpdateURl);
	}
}
*/
public OnPluginStart()
{
	//Handle Updating Plugin if needed
	
	/*
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UpdateURl);
	}
	*/
	
	//g_UU_weapons_hud = CreateHudSynchronizer();
	HookEvent("post_inventory_application", Event_Postinven);
	//HookEvent("player_changeclass", Event_PlayerreSpawn);
	//HookEvent("player_spawn", Event_Postinven);
	
	HookEvent("player_death", Event_Death);
	HookEvent("player_hurt", Event_PlayerhurtBlackBox);
	
	//HookEvent("post_inventory_application", Event_RespawnMangler);
	HookEvent("player_death", Event_PlayerDeathDR);
	
	//Offsets
	LookupOffset(g_iOffsetBow, "CTFCompoundBow", "m_flChargeBeginTime");
	
	
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			//SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageMangler);
			
			//SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageDirectHit);
			
			//SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageScorchShot);
			
			//SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageBrassBeast);
			
			SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
			
			SDKHook(client, SDKHook_PreThink, OnClientPreThink);
			
			//Floats
			Siphoned_Health[client] = 1.0;
			Radius[client] = 270.0;
			Ember_stacks[client] = 0.0;
			Arcstrike_bonus_active[client] = false;
			HitCounter[client] = 0;
			HitBonusActive[client] = false;
		}
	}
	
	//Register Attributes
	TF2EconDynAttribute attrib = new TF2EconDynAttribute();
	
	//Custom Weapons (cw3)
	attrib.SetName("cw3 weapon");
	attrib.SetClass("weapons_cw3_custom");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("eyes of tomorrow");
	attrib.SetClass("weapons_cw3_eot");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("wall break");
	attrib.SetClass("weapons_cw3_wallbreak");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	
	//Custom Weapons (uu)
	attrib.SetName("three tailed fox");
	attrib.SetClass("weapons_ttr");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("void mangler");
	attrib.SetClass("weapons_void_mangler");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("arcstrike");
	attrib.SetClass("weapons_arcstrike");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("solar flare");
	attrib.SetClass("weapons_solar_flare");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("scorch shot extreme");
	attrib.SetClass("weapons_ss_extreme");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("forged volcanic fragment");
	attrib.SetClass("weapons_fvf");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("flare gun extreme");
	attrib.SetClass("weapons_flg_extreme");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("third degree extreme");
	attrib.SetClass("weapons_ttd_extreme");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("arc explode on last chain");
	attrib.SetClass("weapons_arc_explode_on_last_chain");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("arc damage chain max");
	attrib.SetClass("weapons_arc_chain_max");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("arc damage chain increase per chain");
	attrib.SetClass("weapons_arc_damage_increase_per_chain");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("elemental polymorph");
	attrib.SetClass("weapons_elemental_polymorph");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("autoloading holster");
	attrib.SetClass("weapons_autoloading_holster");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("charged shot");
	attrib.SetClass("weapons_charged_shot");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("feedback loop");
	attrib.SetClass("weapons_feedback_loop");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("opening shot");
	attrib.SetClass("weapons_opening_shot");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("airborne bonus arc");
	attrib.SetClass("weapons_ab_bonus_arc");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("Blast radius increased custom");
	attrib.SetClass("weapons_bri_custom");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.Register();
	
	attrib.SetName("fuller court");
	attrib.SetClass("weapons_fuller_court");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.Register();
	
	attrib.SetName("buff weapon on consect hits");
	attrib.SetClass("weapons_buff_on_consect_hits");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("thunderlord");
	attrib.SetClass("weapons_thunderlord");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("abbadon");
	attrib.SetClass("weapons_abbadon");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("nova mortis");
	attrib.SetClass("weapons_nova_mortis");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("xenophage");
	attrib.SetClass("weapons_void_xenophage");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("amplified on kill");
	attrib.SetClass("weapons_amp_on_kill");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.Register();
	
	attrib.SetName("fire rate bonus custom");
	attrib.SetClass("weapons_frb_custom");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.Register();
	
	attrib.SetName("fire rate penalty custom");
	attrib.SetClass("weapons_frp_custom");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.Register();
	
	attrib.SetName("fire rate to damage");
	attrib.SetClass("weapons_fr_to_damage");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("dynamic fire rate minigun");
	attrib.SetClass("weapons_dynamic_fr_minigun");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("dynamic fire rate increase");
	attrib.SetClass("weapons_dynamic_fr_increase");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("damage penalty vs player");
	attrib.SetClass("weapons_dmg_penalty_vs_player");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("reduce armor on hit");
	attrib.SetClass("weapons_reduce_armor_on_hit");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("flat armor reduction on hit");
	attrib.SetClass("weapons_flat_armorreduc_onhit");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("armor regen penalty");
	attrib.SetClass("weapons_armor_regen_penalty");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("armor additional regen");
	attrib.SetClass("weapons_armor_additional_regen");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.Register();
	
	attrib.SetName("super conductor");
	attrib.SetClass("weapons_super_conductor");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("incandescent");
	attrib.SetClass("weapons_incandescent");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("uses custom clip");
	attrib.SetClass("weapons_ucc");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("firefly");
	attrib.SetClass("weapons_firefly");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("causality arrows");
	attrib.SetClass("weapons_ca");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("tranquility");
	attrib.SetClass("weapons_tranquility");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("arc damage chain max");
	attrib.SetClass("weapons_arc_chain_max");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("le monarque");
	attrib.SetClass("weapons_le_monarque");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("last squeak");
	attrib.SetClass("weapons_last_squeak");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	
	//Timers
	
	//CreateTimer(0.05, Timer_Count, _, TIMER_REPEAT);
	//CreateTimer(0.1, Timer_Ember, _, TIMER_REPEAT);
	
	//CreateTimer(0.2, Timer_DealDamage, _, TIMER_REPEAT);
	//CreateTimer(0.1, Timer_RadiusCalc, _, TIMER_REPEAT);
	//CreateTimer(0.2, Timer_SpeedCalc, _, TIMER_REPEAT);
	CreateTimer(0.1, Timer_TenthSecond, _, TIMER_REPEAT);
	CreateTimer(0.2, Timer_TwentiethSecond, _, TIMER_REPEAT);
}

public OnClientPutInServer(client)
{
	if (IsValidClient(client))
	{
		//SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageMangler);
		
		//SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageDirectHit);
		
		//SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageScorchShot);
		
		//SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageBrassBeast);
		
		SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
		
		SDKHook(client, SDKHook_PreThink, OnClientPreThink);
		
		//Floats
		Siphoned_Health[client] = 1.0;
		Ember_stacks[client] = 0.0
		ExplosionReady[client] = false;
		Arcstrike_bonus_active[client] = false;
		HitBonusActive[client] = false;
		
		Radius[client] = 270.0;
	}
}

/*
public OnGameFrame()
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			new clientweapon = GetPlayerWeaponSlot(client,0);
			
			if (IsValidEntity(clientweapon))
			{
				ElementSwitch(client);
				
				//FlareProjRadius(client);
			}
		}
	}
}
*/




//Set Attributes to Weapons
public Event_Postinven(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		new clientweapon = GetPlayerWeaponSlot(client,0);
		new clientweapon2 = GetPlayerWeaponSlot(client,1);
		new clientweapon3 = GetPlayerWeaponSlot(client,2);
		
		if (IsValidEntity(clientweapon))
		{
			if (!WepAttribCheck(clientweapon, "cw3 weapon"))
			{
				new ItemDefinition = GetEntProp(clientweapon, Prop_Send, "m_iItemDefinitionIndex");
				
				switch(ItemDefinition)
				{
					case 228:
					{
						TF2Attrib_SetByName(clientweapon, "three tailed fox", 1.0);
						CPrintToChat(client, "\x07FFD700Black Box; Three-Tailed Fox: \nWeapon changes element type depending on current clip. \nSwaps between Solar, Stasis, and Arc.");
					}
					
					/*
					case 205:
					{
						TF2Attrib_SetByName(clientweapon, "three tailed fox", 1.0);
						CPrintToChat(client, "\x07FFD700Black Box; Three-Tailed Fox: \nWeapon changes element type depending on current clip. \nSwaps between Solar, Stasis, and Arc.");
					}
					*/
					case 1104:
					{
						TF2Attrib_SetByName(clientweapon, "arcstrike", 1.0);
						TF2Attrib_SetByName(clientweapon, "throwable particle trail only", 0.45);
						TF2Attrib_SetByName(clientweapon, "fire rate to damage", 1.0);
						TF2Attrib_SetByName(clientweapon, "damage penalty vs player", 2.00);
						CPrintToChat(client, "\x07FFD700Arcstrike: \n45 percent chance to chain damage. \nWhile Airborne: Increased chaining capability, increased projectile speed, last victim hit by damage chain explodes. \nConverts fire rate to damage.");
					}
					
					case 441:
					{
						Siphoned_Health[client] = 1.0;
						TF2Attrib_SetByName(clientweapon, "void mangler", 1.0);
						TF2Attrib_SetByName(clientweapon3, "damage penalty", 0.90);
						TF2Attrib_SetByName(clientweapon, "strange restriction user value 3", 35.0);
						TF2Attrib_SetByName(clientweapon3, "fire rate to damage", 1.0);
						CPrintToChat(client, "\x07FFD700Cow Mangler; Void Mangler: \nSiphons 3 percent of victim's health on kill, converting it into damage and projectile speed. \nConverts fire rate into damage.");
					}
					
					case 414:
					{
						TF2Attrib_SetByName(clientweapon, "solar flare", 1.0);
						TF2Attrib_SetByName(clientweapon, "Blast radius decreased", 0.10);
						TF2Attrib_SetByName(clientweapon, "damage penalty vs player", 3.00);
						TF2Attrib_SetByName(clientweapon, "scorch", 70.0);
						Radius[client] = 270.0;
						CPrintToChat(client, "\x07FFD700Liberty Launcher; Solar Flare: \nProjectile damages enemies within a 270HU radius and ignites them. \nApplies 70 Scorch from Afterburn. \nLooses all Blast radius");
					}
					
					case 127:
					{
						TF2Attrib_SetByName(clientweapon, "fuller court", 1.0);
						TF2Attrib_SetByName(clientweapon, "Projectile speed decreased", 0.4);
						TF2Attrib_SetByName(clientweapon, "throwable particle trail only", 0.3);
						//TF2Attrib_SetByName(clientweapon, "amplified on kill", 1.0);
						CPrintToChat(client, "\x07FFD700Direct Hit: \nProjectile speed and damage increases as distance traveled increases, has a 30 percent chance to chain damage. \nBecome Amplified on kill.");
					}
					case 56:
					{
						TF2Attrib_SetByName(clientweapon, "le monarque", 1.0);
						TF2Attrib_SetByName(clientweapon, "strand element", 1.0);
						TF2Attrib_SetByName(clientweapon, "flat damage increase", 850.0);
						
						CPrintToChat(client, "\x07FFD700Le Monarque: \nPoison Enemies on hit for a base of 2 seconds; Duration increases as bow charge increases. \nAt full charge: Release an explosive poisonous arrow, poisoning enemies in a 500 HU radius, Strong against Overload Champions.");
					}
					
					case 1092:
					{
						TF2Attrib_SetByName(clientweapon, "le monarque", 1.0);
						TF2Attrib_SetByName(clientweapon, "strand element", 1.0);
						TF2Attrib_SetByName(clientweapon, "flat damage increase", 850.0);
						
						CPrintToChat(client, "\x07FFD700Le Monarque: \nPoison Enemies on hit for a base of 2 seconds; Duration increases as bow charge increases. \nAt full charge: Release an explosive poisonous arrow, poisoning enemies in a 500 HU radius, Strong against Overload Champions.");
					}
					
					case 1005:
					{
						TF2Attrib_SetByName(clientweapon, "le monarque", 1.0);
						TF2Attrib_SetByName(clientweapon, "strand element", 1.0);
						TF2Attrib_SetByName(clientweapon, "flat damage increase", 850.0);
						
						CPrintToChat(client, "\x07FFD700Le Monarque: \nPoison Enemies on hit for a base of 2 seconds; Duration increases as bow charge increases. \nAt full charge: Release an explosive poisonous arrow, poisoning enemies in a 500 HU radius, Strong against Overload Champions.");
					}
					
					
					case 312:
					{
						TF2Attrib_SetByName(clientweapon, "thunderlord", 1.0);
						TF2Attrib_SetByName(clientweapon, "throwable particle trail only", 0.2);
						TF2Attrib_SetByName(clientweapon, "fire rate bonus", 0.8);
						TF2Attrib_SetByName(clientweapon, "buff weapon on consect hits", 1.0);
						CPrintToChat(client, "\x07FFD700Thunderlord: \n20 percent chance to chain damage to nearby enemies. \nEvery 30 hits: Empower Thunderlord, gaining increased chaining capability, damage, fire rate, and cause an explosion every 5 hits for 5 seconds.");
					}
					
					case 811:
					{
						TF2Attrib_SetByName(clientweapon, "abbadon", 1.0);
						TF2Attrib_SetByName(clientweapon, "scorch", 45.0);
						TF2Attrib_SetByName(clientweapon, "fire rate bonus", 0.8);
						TF2Attrib_SetByName(clientweapon, "Set DamageType Ignite", 1.0);
						TF2Attrib_SetByName(clientweapon, "buff weapon on consect hits", 1.0);
						CPrintToChat(client, "\x07FFD700Abbadon: \nApplies 45 Scorch to victims of afterburn. \nEvery 30 hits: Empower Abbadon, gaining Incandescent, damage, fire rate, and apply 80 Scorch to anyone within a 400 HU radius around the victim on hit.");
					}
					
					case 424:
					{
						TF2Attrib_SetByName(clientweapon, "nova mortis", 1.0);
						TF2Attrib_SetByName(clientweapon, "fire rate bonus", 0.8);
						TF2Attrib_SetByName(clientweapon, "buff weapon on consect hits", 1.0);
						TF2Attrib_SetByName(clientweapon, "strange restriction user value 3", 3.0);
						CPrintToChat(client, "\x07FFD700Nova Mortis: \nEvery 30 hits: Empower Nova Mortis, gaining increased damage, fire rate, and making victims Volatile every 5 hits.");
					}
					case 215:
					{
						TF2Attrib_SetByName(clientweapon, "throwable particle trail only", 0.45);
						TF2Attrib_SetByName(clientweapon, "polyute", 1.0);
						TF2Attrib_SetByName(clientweapon, "weaken on damage chain", 1.0);
						TF2Attrib_SetByName(clientweapon, "damage penalty", 0.7);
						CPrintToChat(client, "\x07FFD700Degreaser: \n30 percent chance to chain damage to nearby enemies.\nChain damage weakens enemies and can retarget the same victim multiple time.");
					}
					case 415:
					{
						TF2Attrib_SetByName(clientweapon, "autoloading holster", 1.0);
						TF2Attrib_SetByName(clientweapon, "opening shot", 1.0);
						TF2Attrib_SetByName(clientweapon, "feedback loop", 1.0);
						TF2Attrib_SetByName(clientweapon, "charged shot", 1.0);
						TF2Attrib_SetByName(clientweapon, "throwable particle trail only", 0.40);
						
						CPrintToChat(client, "\x07FFD700Reserve Shooter: \n 40 percent chance to chain damage.\nInital shot of the clip has more bullets per shot, is more accurate, and has a higher chance to chain damage.\nKills with the initial shot refresh the bonus and increase fire rate by 35 percent, consecutive kills siphon 15 percent of the victim's health and max armor, regenating the user.\nAutomatically reloads the clip after 3 seconds of being stowed.");
					}
					case 45:
					{
						TF2Attrib_SetByName(clientweapon, "strand element", 1.0);
						TF2Attrib_SetByName(clientweapon, "unraveling rounds", 1.0);
						TF2Attrib_SetByName(clientweapon, "burst fire count", -3.0);
						TF2Attrib_SetByName(clientweapon, "burst fire rate mult", 3.0);
						TF2Attrib_SetByName(clientweapon, "clip size penalty", 1.0);
						TF2Attrib_SetByName(clientweapon, "clip size bonus", 2.0);
						TF2Attrib_SetByName(clientweapon, "last squeak", 1.0);
						SetEntProp(clientweapon, Prop_Send, "m_iClip1", 12);
						CPrintToChat(client, "\x07FFD700Force-A-Nature; Last Squeak:\nFires a 3 round burst.\nRapid kills grant Unraveling Rounds.");
					}
					/*
					case 308:
					{
						TF2Attrib_SetByName(clientweapon, "elemental polymorph", 1.0);
						CPrintToChat(client, "\x07FFD700Loch N Load: Copies current elemental of victim's weapon on hit, this can happen every 3 seconds. Kills empower the current element, increasing it's base attributes.");
					}
					
					case 130:
					{
						CPrintToChat(client, "\x07FFD700The Scottish Resistance: Has a 30% chance to apply 30 Slowed Stacks and chain damage to nearby enemies. Dealing damage to Frozen targets causes them to immediately shatter.");
					}
					
					case 1150:
					{
						CPrintToChat(client, "\x07FFD700The QuickieBomb Launcher: Applies 50 Scorch from afterburn. Increases the damage the victim takes by 30% while they are burning. No clip size upgrade.");
					}
					*/
					
				}
			}
		}
		if (IsValidEntity(clientweapon2))
		{
		
			new ItemDefinition = GetEntProp(clientweapon2, Prop_Send, "m_iItemDefinitionIndex");
				
			switch(ItemDefinition)
			{
				case 740:
				{
					TF2Attrib_SetByName(clientweapon2, "scorch shot extreme", 1.0);
					TF2Attrib_SetByName(clientweapon2, "fire rate to damage", 1.0);
					TF2Attrib_SetByName(clientweapon2, "scorch", 60.0);
					TF2Attrib_SetByName(clientweapon2, "damage bonus", 2.0);
					CPrintToChat(client, "\x07FFD700Scorch Shot: \nScorching an enemy adds to Ember stacks, increasing blast radius, buffing Afterburn, increasing fire rate, and increasing Scorch applied. \nConsume Ember stacks using Reload Key.");
				}
				case 39:
				{
					TF2Attrib_SetByName(clientweapon2, "flare gun extreme", 1.0);
					TF2Attrib_SetByName(clientweapon2, "scorch", 40.0);
					//TF2Attrib_SetByName(clientweapon2, "throwable particle trail only", 0.07);
					ExplosionReady[client] = true;
					CPrintToChat(client, "\x07FFD700Flare Gun: \nChain Chance increases as the weapon is fired. \nChain chance and damage increases further against burning victims. \nExplode when you take Arc damage.");
				}
			}
		}
		if (IsValidEntity(clientweapon3))
		{
			new ItemDefinition = GetEntProp(clientweapon3, Prop_Send, "m_iItemDefinitionIndex");
				
			switch(ItemDefinition)
			{
				case 593:
				{
					TF2Attrib_SetByName(clientweapon3, "arc explode on last chain", 1.0);
					TF2Attrib_SetByName(clientweapon3, "throwable particle trail only", 1.0);
					TF2Attrib_SetByName(clientweapon3, "arc damage chain max", 8.0);
					TF2Attrib_SetByName(clientweapon3, "third degree extreme", 1.0);
					TF2Attrib_SetByName(clientweapon3, "fire rate to damage", 1.0);
					TF2Attrib_SetByName(clientweapon3, "arc damage chain increase per chain", 1.0);
					TF2Attrib_SetByName(clientweapon3, "taunt attack name", 1.0);
					//TF2Attrib_SetByName(clientweapon3, "damage penalty", 0.30);
					TF2Attrib_SetByName(clientweapon3, "flat damage increase", 440.0);
					CPrintToChat(client, "\x07FFD700The Third Degree: \n100 percent chance to Chain damage to up to 8 victims. \nCreate a 700 HU explosion at the last victim hit by Chain damage. \nConvert fire rate to damage. Strong Against Overload Champions");
				}
				
				case 450:
				{
					TF2Attrib_SetByName(clientweapon3, "throwable particle trail only", 0.45);
					TF2Attrib_SetByName(clientweapon3, "taunt attack name", 1.0);
					TF2Attrib_SetByName(clientweapon3, "flat damage increase", 440.0);
					TF2Attrib_SetByName(clientweapon3, "airborne bonus arc", 1.0);
					
					CPrintToChat(client, "\x07FFD700The Atomizer: \n45 percent chance to Chain damage to nearby enemies. \nGain increased chaining capabilities and chain damage while airborne. \nStrong Against Overload Champions");
				}
				
				case 348:
				{
					TF2Attrib_SetByName(clientweapon3, "fire rate to damage", 1.0);
					TF2Attrib_SetByName(clientweapon3, "special taunt", 1.0);
					TF2Attrib_SetByName(clientweapon3, "forged volcanic fragment", 1.0);
					TF2Attrib_SetByName(clientweapon3, "recipe component defined item 7", 1.0);
					TF2Attrib_SetByName(clientweapon3, "scorch", 70.0);
					TF2Attrib_SetByName(clientweapon3, "weapon burn dmg reduced", 0.30);
					TF2Attrib_SetByName(clientweapon3, "single wep deploy time decreased", 1.85);
					TF2Attrib_SetByName(clientweapon3, "incandescent", 320.0);
					TF2Attrib_SetByName(clientweapon3, "flat damage increase", 420.0);
					CPrintToChat(client, "\x07FFD700Sharpened Volcano Fragment: \nIncreased damage against victims with higher Scorch stacks. Strong Against Unstoppable Champions. \nVictims explode when killed with this weapon, Scorching and damaging enemies nearby. \nConvert fire rate to damage.");
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

public bool:TraceEntityFilterPlayer(entity, contentsMask) // Thx RavensBro.
{
    return entity > GetMaxClients() || !entity;
}

stock TF2_GetMaxHealth(iClient)
{
    new maxhealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, iClient);
    return ((maxhealth == -1 || maxhealth == 80896) ? GetEntProp(iClient, Prop_Data, "m_iMaxHealth") : maxhealth);
}

public bool TraceFilterIgnoreSelf( entity, contentsMask, any:hiok )
{
    if ( entity == hiok || entity > 0 && entity <= MaxClients ) return false; 
    return true; 
}

stock CreateBulletTrace(const Float:origin[3], const Float:dest[3], const Float:speed = 6000.0, const Float:startwidth = 0.5, const Float:endwidth = 0.2, const String:color[] = "200 200 0")
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
	DispatchKeyValueFloat(entity, "lifetime", 240.0 / speed);
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

public Action:RemoveParticle( Handle:timer, any:particle ) {
    if ( particle >= 0 && IsValidEntity(particle) ) {
        new String:classname[32];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false)) {
            AcceptEntityInput(particle, "stop");
            AcceptEntityInput(particle, "Kill");
            particle = -1;
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

LookupOffset(&iOffset, const String:strClass[], const String:strProp[])
{
	iOffset = FindSendPropInfo(strClass, strProp);
	if(iOffset <= 0)
	{
		SetFailState("Could not locate offset for %s::%s!", strClass, strProp);
	}
}