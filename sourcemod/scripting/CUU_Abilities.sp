#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <sdkhooks>
#include <tf_econ_dynamic>
#include <Abilities_include>
#include <UbUp-PowerSupply>
#include <custom_status_hud>
#include <custom_status_hud_Elements>

#pragma semicolon 1

//#define m_Yagorath		"tf/custom/Models/rec/cuddlyyagorath.mdl"
//#define m_YagorathTexture	"tf/custom/Materials/models/mic_pc_yagorath_id1_skin02a_lobby

#define PLUGIN_VERSION		"1.50"

public Plugin:myinfo =
{
	name		= "Uberupgrades Abilites",
	author		= "Recluse",
	description	= "Adds some buyable stuff",
	version		= PLUGIN_VERSION,
};


new LastButtons[MAXPLAYERS+1] = {-1 , ...};

//int ButtonPressedTimer[MAXPLAYERS+1];

//new Float:Regen_Effectiveness[MAXPLAYERS+1]

new Float:Delay[MAXPLAYERS+1] = {0.0, ...};

new Handle:cvar_MeleeFixActive;

new Handle:cvar_infchargeactive;

new Handle:cvar_chargemult;

Handle:Abilities_Hud;

//Handle:Abilities_Status_Hud[MAXPLAYERS+1];

//Handle:Charge_Hud[MAXPLAYERS+1];

//Basic Functions


public Action OnCustomStatusHUDUpdate(int client, StringMap entries) 
{
	if (IsValidClient(client))
	{
		char ShieldLeft[32];
		
		new Address:Charge = TF2Attrib_GetByName(client, "store sort override DEPRECATED");
		if(Charge!=Address_Null)
		{
			
			Format(ShieldLeft, sizeof(ShieldLeft), "Charge: %.0f/%.0f", current_charge[client], max_charge[client]);
			entries.SetString("uu_c_abilities_charge", ShieldLeft);
		}
	}
	return Plugin_Changed;
}

public Action OnCustomStatusHUDUpdate2(int client, StringMap entries) 
{
	if (IsValidClient(client))
	{
		char Bloodmoonlife[32];
		char King[32];
		char Reflect[32];
		char Supernova[32];
		char InfectionLeft[32];
		char SlowLeft[32];
		
		if (Plague_DOT1active[client] || Plague_DOT2active[client] == true && Plague_DOTduration[client] > 0.0)
		{
			Format(InfectionLeft, sizeof(InfectionLeft), "INFECTED %.1f", Plague_DOTduration[client]);
			entries.SetString("elements_effects_plague_infected", InfectionLeft);
		}
		
		if (Knockout_slow_duration[client] > 0.0)
		{
			Format(SlowLeft, sizeof(SlowLeft), "SLOWED %.1f", Knockout_slow_duration[client]);
			entries.SetString("elements_effects_knockout_slowed", SlowLeft);
		}
		
		if (BloodMoon_Buffed[client] || BloodMoon_Active[client])
		{
			Format(Bloodmoonlife, sizeof(Bloodmoonlife), "Bloodmoon Lifesteal");
			entries.SetString("elements_effects_bloodmoon", Bloodmoonlife);
		}
		
		if (King_boostactive[client])
		{
			Format(King, sizeof(King), "King 1.5x Damage Bonus");
			entries.SetString("elements_effects_king_bonus", King);
		}
		
		if (Reflect_dmgreflectactive[client])
		{
			Format(Reflect, sizeof(Reflect), "Damage Reflect Active");
			entries.SetString("elements_effects_reflect_dmgreflect", Reflect);
		}
		
		if (Supernova_afterburn[client] == 1.0)
		{
			Format(Supernova, sizeof(Supernova), "Supernova Afterburn");
			entries.SetString("elements_effects_supernova_burn", Supernova);
		}
	}
	return Plugin_Changed;
}

public void OnPluginStart()
{
	HookEvent("player_death", Event_Death);
	HookEvent("player_changeclass", Event_PlayerreSpawn);
	HookEvent("player_spawn", Event_PlayerreSpawn);
	HookEvent("player_death", Event_PlayerreSpawn);
	HookEvent("player_hurt", Event_Playerhurt);
	HookEvent("post_inventory_application", Event_PlayerreSpawn);
	HookEvent("mvm_reset_stats", Event_ResetStats);
	RegConsoleCmd("sm_abilities", Abilities);
	CreateTimer(0.1, Timer_charge, _, TIMER_REPEAT);
	CreateTimer(1.0, Timer_Supernova, _, TIMER_REPEAT);
	CreateTimer(2.1, Timer_Passivecharge, _, TIMER_REPEAT);
	CreateTimer(0.1, Cost_Calc, _, TIMER_REPEAT);
	
	Abilities_Hud = CreateHudSynchronizer();
	
	Abilities_AttribRegsiter();
	//PrintToServer("Attributes for Abilities Registered");
	
	cvar_MeleeFixActive = CreateConVar("sm_abilities_meleefixactive", "0", "Enables Melee attack rate fix. Default: 0");
	cvar_infchargeactive = CreateConVar("sm_abilities_infcharge", "0", "Enables infinite chare. Default: 0");
	cvar_chargemult = CreateConVar("sm_abilities_chargemult", "1", "Passive charge multiplier. Default: 1");
	PrintToChatAll("Abilities Loaded");
	for(new client=0; client<=MaxClients; client++)
	{
		if(!IsValidClient(client)){continue;}
		current_charge[client] = 0.0;
		max_charge[client] = 0.0;
		Agility_MoveTimer[client] = 0.0;
		//Abilities_Status_Hud[client] = CreateHudSynchronizer();
		//Charge_Hud[client] = CreateHudSynchronizer();
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_PreThink, OnClientPreThink);
		Overflow_Protection[client] = true;
	}
}

public Action Abilities(int client, int args)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		DisplayAbilitiesMenu(client);
	}
	return Plugin_Handled;
}

DisplayAbilitiesMenu(client)
{
	if (IsValidClient(client))
	{
		PrintToServer("Client %d Accessing Abilities.", client);
		/*
		new Address:BloodMoon = TF2Attrib_GetByName(client, "bloodmoon");
		new Address:Empowerment = TF2Attrib_GetByName(client, "empowerment");
		new Address:Supernova = TF2Attrib_GetByName(client, "supernova");
		new Address:Knockout = TF2Attrib_GetByName(client, "knockout");
		new Address:Agility = TF2Attrib_GetByName(client, "agility");
		new Address:Plague = TF2Attrib_GetByName(client, "plague");
		new Address:King = TF2Attrib_GetByName(client, "king");
		new Address:Reflect = TF2Attrib_GetByName(client, "reflect");
		new Address:Resistance = TF2Attrib_GetByName(client, "resistance");
		new Address:Precision = TF2Attrib_GetByName(client, "precision");
		new Address:Fireball = TF2Attrib_GetByName(client, "fireball");
		new Address:MeteorShower = TF2Attrib_GetByName(client, "meteor shower");
		new Address:Bats = TF2Attrib_GetByName(client, "bats");
		*/
		new Address:Immortal = TF2Attrib_GetByName(client, "custom name attr");
		new Address:Yagorath = TF2Attrib_GetByName(client, "no charge impact range");
		
		Menu menu = new Menu(MenuHandler1);
	
		menu.SetTitle("Abilities");
		menu.AddItem("ability_stats", "Ability Stats");
		if (ClientAttribCheck(client, "empowerment"))
		{
			menu.AddItem("empowerment", "Empowerment");
		}
		if (ClientAttribCheck(client, "bloodmoon"))
		{
			menu.AddItem("bloodmoon", "Bloodmoon");
		}
		if (ClientAttribCheck(client, "supernova"))
		{
			menu.AddItem("supernova", "Supernova");
		}
		if (ClientAttribCheck(client, "knockout"))
		{
			menu.AddItem("knockout", "Knockout");
		}
		if (ClientAttribCheck(client, "agility"))
		{
			menu.AddItem("agility", "Agility");
		}
		if (ClientAttribCheck(client, "plague"))
		{
			menu.AddItem("plague", "Plague");
		}
		if (ClientAttribCheck(client, "king"))
		{
			menu.AddItem("king", "King");
		}
		if (ClientAttribCheck(client, "reflect"))
		{
			menu.AddItem("reflect", "Reflect");
		}
		if (ClientAttribCheck(client, "resistance"))
		{
			menu.AddItem("resistance", "Resistance");
		}
		if (ClientAttribCheck(client, "precision"))
		{
			menu.AddItem("precision", "Precision");
		}
		if (Yagorath!=Address_Null)
		{
			menu.AddItem("yagorath", "Yagorath");
		}
		if (Immortal!=Address_Null)
		{
			menu.AddItem("immortal", "Immortal");
		}
		if (ClientAttribCheck(client, "fireball"))
		{
			menu.AddItem("throw_fireball", "Fireball");
		}
		if (ClientAttribCheck(client, "meteor shower"))
		{
			menu.AddItem("throw_meteorshower", "Meteor Shower");
		}
		if (ClientAttribCheck(client, "bats"))
		{
			menu.AddItem("throw_bats", "Bats Spell");
		}
		menu.ExitButton = true;
		menu.Display(client, 20);
	}
	return -1;
}

DisplayAbilityStatsMenu(int client){
	new Address:Yagorath = TF2Attrib_GetByName(client, "no charge impact range");
	new Address:Immortal = TF2Attrib_GetByName(client, "custom name attr");
	
	Menu stats = new Menu(StatsHandler);
	stats.SetTitle("Ability Stats");
	
	if (ClientAttribCheck(client, "empowerment"))
	{
		stats.AddItem("empowerment_stats", "Empowerment Stats");
	}
	if (ClientAttribCheck(client, "bloodmoon"))
	{
		stats.AddItem("bloodmoon_stats", "Bloodmoon Stats");
	}
	if (ClientAttribCheck(client, "supernova"))
	{
		stats.AddItem("supernova_stats", "Supernova Stats");
	}
	if (ClientAttribCheck(client, "knockout"))
	{
		stats.AddItem("knockout_stats", "Knockout Stats");
	}
	if (ClientAttribCheck(client, "agility"))
	{
		stats.AddItem("agility_stats", "Agility Stats");
	}
	if (ClientAttribCheck(client, "plague"))
	{
		stats.AddItem("infection_stats", "Plague Stats");
	}
	if (ClientAttribCheck(client, "king"))
	{
		stats.AddItem("king_stats", "King Stats");
	}
	if (ClientAttribCheck(client, "reflect"))
	{
		stats.AddItem("reflect_stats", "Reflect Stats");
	}
	if (ClientAttribCheck(client, "resistance"))
	{
		stats.AddItem("resistance_stats", "Resistance Stats");
	}
	if (ClientAttribCheck(client, "precision"))
	{
		stats.AddItem("precision_stats", "Precision Stats");
	}
	if (Yagorath!=Address_Null)
	{
		stats.AddItem("yagorath_stats",	"Yagorath Stats");
	}
	if (Immortal!=Address_Null)
	{
		stats.AddItem("immortal_stats", "Immortal Stats");
	}
	if (ClientAttribCheck(client, "fireball"))
	{
		stats.AddItem("fireball_stats",	"Fireball Stats");
	}
	if (ClientAttribCheck(client, "meteor shower"))
	{
		stats.AddItem("meteor_stats", "Meteor Shower Stats");
	}
	if (ClientAttribCheck(client, "bats"))
	{
		stats.AddItem("bats_stats", "Bats Stats");
	}
	//stats.Exitbutton = true;
	stats.ExitBackButton = true;
	stats.Display(client, 20);
}
public OnPluginEnd()
{
	for(new i=0; i<=MaxClients; i++)
	{
		if(!IsValidClient(i)){continue;}
		current_charge[i] = 0.0;
		max_charge[i] = 0.0;
		SDKUnhook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
		SDKUnhook(i, SDKHook_PreThink, OnClientPreThink);
		Overflow_Protection[i] = true;
	}
	UnhookEvent("player_death", Event_Death);
	UnhookEvent("player_changeclass", Event_PlayerreSpawn);
	UnhookEvent("player_spawn", Event_PlayerreSpawn);
	UnhookEvent("player_death", Event_PlayerreSpawn);
	UnhookEvent("post_inventory_application", Event_PlayerreSpawn);
	UnhookEvent("player_hurt", Event_Playerhurt);
	UnhookEvent("mvm_reset_stats", Event_ResetStats);
	PrintToChatAll("Abilities Unloaded");
}

public Event_ResetStats(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new client = 0; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			ResetAbilities(client);
		}
	}
}
public OnEntityCreated(Ent, const String:cls[])
{
	if (StrEqual(cls, "obj_sentrygun") || StrEqual(cls, "obj_dispenser") || StrEqual(cls, "obj_teleporter")/* || StrEqual(cls, "obj_attachment_sapper")*/)
	{
		SDKHook(Ent, SDKHook_OnTakeDamage, OnTakeDamage_Building);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
	if(!IsFakeClient(client))
	{
		ResetAbilities(client);
	}
}

public Action:Timer_charge(Handle:Timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{	
			if(current_charge[client] < 0.0)
			{
				current_charge[client] = 0.0;
			}
			if(current_charge[client] > max_charge[client] && Overflow_Protection[client] == true)
			{
				current_charge[client] = max_charge[client];
			}
			if(current_charge[client] > max_charge[client]*2 && Overflow_Protection[client] == false)
			{
				current_charge[client] = max_charge[client]*2;
			}
			new Address:Charge = TF2Attrib_GetByName(client, "store sort override DEPRECATED");
			if(Charge!=Address_Null)
			{
				new Float:MaxCharge = TF2Attrib_GetValue(Charge);
				max_charge[client] = MaxCharge;
				
				/*
				new String:ShieldLeft[32];
				Format(ShieldLeft, sizeof(ShieldLeft), "Charge %.0f / %.0f", current_charge[client], max_charge[client]); 
				new Float:pctShield =  current_charge[client]/max_charge[client];
				if (Overflow_Protection[client] == true)
				{
					if(pctShield > 0.5)
					{
						SetHudTextParams(-0.65, 0.83, 1.2, 0, 255, 0, 255, 0, 0.0, 0.0, 0.0);
						//ShowHudText(client, -1, ShieldLeft);
					}
					else if(pctShield <= 0.5 && pctShield > 0.25)
					{
						SetHudTextParams(-0.65, 0.83, 1.2, 255, 255, 0, 255, 0, 0.0, 0.0, 0.0);
						//ShowHudText(client, -1, ShieldLeft);				
					}
					else
					{
						SetHudTextParams(-0.65, 0.83, 1.2, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
						//ShowHudText(client, -1, ShieldLeft);				
					}
				}
				if (Overflow_Protection[client] == false)
				{	
					SetHudTextParams(-0.65, 0.83, 1.2, 127, 0, 127, 255, 0, 0.0, 0.0, 0.0);
					//ShowHudText(client, -1, ShieldLeft);
				}
				ShowSyncHudText(client, Charge_Hud[client], "%s", ShieldLeft);
				*/
			}
			else
			{
				max_charge[client] = 0.0;
			}
			if (Empowerment_Active[client] > 1.0)
			{
				Empowerment_Active[client] = 1.0;
			}
			if (is_lingering[client] > 1.0)
			{
				is_lingering[client] = 1.0;
			}
			if (Knockout_slow_duration[client] > 0.0)
			{
				Knockout_slow_duration[client] -= 0.1;
				
				TF2_AddCondition(client, TFCond_Dazed, 0.3);
				TF2Attrib_SetByName(client, "move speed penalty", 0.50);
				AttachParticle(client, "critgun_weaponmodel_red", 1.0);
			}
			if (Knockout_slow_duration[client] < 0.0)
			{
				Knockout_slow_duration[client] = 0.0;
				Knockout_isslowed[client] = 0.0;
				TF2Attrib_RemoveByName(client, "move speed penalty");
			}
			if (Plague_DOT1active[client] || Plague_DOT2active[client] == true && Plague_DOTduration[client] > 0.0)
			{
				Plague_DOTduration[client] -= 0.1;
			}
			if (Plague_DOTduration[client] < 0.0)
			{
				Plague_DOTduration[client] = 0.0;
				if (Plague_DOT1active[client] == true)
				{
					Plague_DOT1active[client] = false;
				}
				else
				{
					Plague_DOT2active[client] = false;
				}
			}
			
			Show_AbilitiyHud(client);
			/*
			if (Supernova_specialtimer[client] > 0.0 && Supernova_active[client] == true)
			{
				decl String:S_Timer[32];
				Format(S_Timer, sizeof(S_Timer), "Supernova Special - %.0f",Supernova_specialtimer[client]);
				SetHudTextParams(-0.65, 0.5, 1.2, 127, 0, 127, 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(client, -1, S_Timer);
			}
			if (Supernova_specialtimer[client] == 0.0 && Supernova_active[client] == true)
			{
				decl String:S_Timer2[32];
				Format(S_Timer2, sizeof(S_Timer2), "Supernova Special - READY");
				SetHudTextParams(-0.65, 0.5, 1.2, 127, 0, 127, 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(client, -1, S_Timer2);
			}
			if (Immortal_timer[client] > 0.0 && Immortal_active[client] == true && Immortal_ready[client] == false)
			{
				decl String:S_Timer[32];
				Format(S_Timer, sizeof(S_Timer), "Immortal - %.0f",Immortal_timer[client]);
				SetHudTextParams(-0.65, 0.5, 1.2, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(client, -1, S_Timer);
			}
			if (Immortal_timer[client] == 0.0 && Immortal_active[client] == true && Immortal_ready[client] == false)
			{
				decl String:S_Timer2[32];
				Format(S_Timer2, sizeof(S_Timer2), "Immortal - READY");
				SetHudTextParams(-0.65, 0.5, 1.2, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(client, -1, S_Timer2);
			}
			*/
			//if (Agility_invisduration[client] > 0.0 && Agility_isinvis[client] == 1.0)
			//{
				//Agility_invisduration[client] += Agility_invisdurationadd[client];
				//decl String:A_Timer[32];
				//Format(A_Timer, sizeof(A_Timer), "Invisible - %.1f",Agility_invisduration[client]);
				//SetHudTextParams(-0.65, 0.5, 1.2, 0, 0, 255, 255, 0, 0.0, 0.0, 0.0);
				//ShowHudText(client, -1, A_Timer);
			//}
			if (IsNearSpencer(client) == true)
			{
				new Float:RegenMult = 0.0;
				RegenMult = Pow(max_charge[client],0.3)*0.7;
				
				if (current_charge[client] < max_charge[client])
				{
					current_charge[client] += RegenMult;
				}
			}
			if (Reflect_active[client] == true && Current_HealthPool[client] < Reflect_HealthPool[client] && current_charge[client] > Reflect_cost[client])
			{
				new clientHealth = GetEntProp(client, Prop_Data, "m_iHealth");
				if (clientHealth <= TF2_GetMaxHealth(client)*0.75 && Reflect_InstantHealTriggered[client] == false)
				{
					current_charge[client] -= Reflect_cost[client];
					AddPlayerHealth(client, RoundToFloor(Current_HealthPool[client]), 2.0);
					ShowHealthGain(client, RoundToFloor(Current_HealthPool[client]), client);
					Reflect_dmgreflectactive[client] = true;
					Reflect_InstantHealTriggered[client] = true;
					if (fl_CurrentArmor[client] < fl_MaxArmor[client])
					{
						fl_CurrentArmor[client] += Current_HealthPool[client];
						PrintToConsole(client, "%0.f Armor Regenerated", Current_HealthPool[client]);
					}
					CreateTimer(0.1, HealthPool_Reset);
					CreateTimer(10.0, Timer_DMGReflect);
				}
			}
		}
	}
}

stock Show_AbilitiyHud(client)
{
	if (IsValidClient(client))
	{
		//Strings
		
		new String:S_Timer[32];
		new String:I_Timer[32];
		
		if (Supernova_specialtimer[client] > 0.0 && Supernova_active[client] == true)
		{
			Format(S_Timer, sizeof(S_Timer), "Supernova Special - %.0f",Supernova_specialtimer[client]);
			Cooldowns_Active[client] = true;
		}
		if (Supernova_specialtimer[client] == 0.0 && Supernova_active[client] == true)
		{
			Format(S_Timer, sizeof(S_Timer), "Supernova Special - READY");
			Cooldowns_Active[client] = false;
		}
		if (Immortal_timer[client] > 0.0 && Immortal_active[client] == true && Immortal_ready[client] == false)
		{
			Format(I_Timer, sizeof(I_Timer), "Immortal - %.0f",Immortal_timer[client]);
			Cooldowns_Active[client] = true;
		}
		if (Immortal_timer[client] == 0.0 && Immortal_active[client] == true && Immortal_ready[client] == false)
		{
			Format(I_Timer, sizeof(I_Timer), "Immortal - READY");
			Cooldowns_Active[client] = false;
		}
		SetHudTextParams(-0.65, 0.5, 1.2, 205, 0, 50, 255, 0, 0.0, 0.0, 0.0);
		
		if (Cooldowns_Active[client])
		{
			ShowSyncHudText(client, Abilities_Hud, "Acitve Cooldowns\n%s\n%s", S_Timer, I_Timer);
		}
	}
}

//Calculate Ability cost and effectiveness
public Action:Cost_Calc(Handle:timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			new Address:AbilityPower = TF2Attrib_GetByName(client, "powerup charges");

			Empowerment_Damage[client] = SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.6;
			
			BloodMoon_Effect[client] = SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*1.2;
			
			BloodMoon_Radius[client] = 300*(SquareRoot(max_charge[client]*0.1))*(ability_power[client]*0.3)*0.3;
			
			Supernova_radius[client] = 250.0*(SquareRoot(max_charge[client]*0.2))*(ability_power[client]*0.2)*0.3;
			
			Supernova_damage[client] = 250.0*SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.1)*0.6;
			
			Supernova_burntimerbonus = SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.4;
			
			k_duration[client] = 1.0+(SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.5);
			
			Knockout_slow_radius[client] = 150.0*SquareRoot(max_charge[client]*0.2)*(ability_power[client]*0.2)*0.3;
			
			Knockout_disruptor_add[client] = 1000*SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.2;
			
			Knockout_slowcost[client] = 100*SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.4;
			
			Plague_cost[client] = 120*SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.4;
			
			p_duration[client] = 1.0+(SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.1);
			
			Plague_DOTradius[client] = 250.0*SquareRoot(max_charge[client]*0.2)*(ability_power[client]*0.2)*0.3;
			
			King_boostradius[client] = 125.0*SquareRoot(max_charge[client]*0.2)*(ability_power[client]*0.4)*0.2;
			
			King_cost[client] = 75.0*SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.4;
			
			Reflect_HealthPool[client] = 750.0*(SquareRoot(max_charge[client]*0.2))*(ability_power[client]*0.2)*0.3;
			
			Reflect_cost[client] = 100.0*SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.2;
			
			Resistance_range[client] = 400.0*(SquareRoot(max_charge[client]*0.2))*(ability_power[client]*0.2)*0.3;
			
			Resistance_cost[client] = 30.0*SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.2;
			
			Precision_range[client] = 400.0*(SquareRoot(max_charge[client]*0.2))*(ability_power[client]*0.2)*0.3;
			
			Precision_cost[client] = 50.0*SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.2;
			
			Fireball_cost[client] = 25.0*SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.2;
			
			Fireball_damage[client] = 35.0*SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.7)*0.2;
			
			MetorShower_cost[client] = 55.0*SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.1)*0.2;
			
			MeteorShower_damage[client] = 105.0*SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.5)*0.2;
			
			Bats_cost[client] = 30.0*SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.3;
			
			Bats_damage[client] = 97.0*SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.5)*0.1;
			
			Immortal_radius[client] = 300.0*SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.5)*0.1;
			
			Immortal_cost[client] = 102.0*SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.2;
			
			//Yagorath Stuff
			
			Yagorath_healthadd[client] = 5000*(SquareRoot(max_charge[client]*0.2))*(ability_power[client]*0.2)*0.3;
			
			H_duration[client] = 2.0+(SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.1);
			
			Hardening_cost[client] = 40.5*SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.2;
			
			//MainFire_damage[client] = 25.5+(SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.5);
			
			MainFire_cost[client] = 15*SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.2;
			
			PiercingQuils_damage[client] = 60.5+(SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.5);
			
			Piercing_quils_cost[client] = 100*SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.2;
			
			PrimalVision_cost[client] = 130*SquareRoot(max_charge[client]*0.1)*(ability_power[client]*0.2)*0.2;
			
			
			
		
			if (AbilityPower!=Address_Null)
			{
				new Float:power = TF2Attrib_GetValue(AbilityPower);
		
				ability_power[client] = power;
			
				charge_cost[client] = SquareRoot(max_charge[client]*2.5)*(Pow(ability_power[client],2.3)*1.5);
				EmpowermentCost[client] = charge_cost[client];
				BloodMoonCost[client] = charge_cost[client]*1.30;
				Supernova_cost[client] = max_charge[client];
			}
			else
			{
				ability_power[client] = 1.0;
			}
			if (ability_power[client] > 2.0 && Overflow_Protection[client] == true)
			{
				ability_power[client] = 2.0;
			}
			if (ability_power[client] > 4.5)
			{
				ability_power[client] = 4.5;
			}
			if (EmpowermentCost[client] > max_charge[client])
			{
				EmpowermentCost[client] += max_charge[client]*0.30;
			}
			if (BloodMoonCost[client] > max_charge[client])
			{
				BloodMoonCost[client] += max_charge[client]*0.55;
			}
			if (Current_HealthPool[client] > Reflect_HealthPool[client])
			{
				Current_HealthPool[client] = Reflect_HealthPool[client];
			}
		}
	}
}

public Action:Timer_Passivecharge(Handle:Timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			new Float:chargemult = GetConVarFloat(cvar_chargemult);
			if(current_charge[client] < max_charge[client] && max_charge[client] > 0.0 && is_lingering[client] == 0.0 && Immortal_Own[client] == false)
			{
				current_charge[client] += (1.0+(max_charge[client]*0.15)*0.1)*chargemult;
			}
			if (Supernova_afterburn[client] == 1.0)
			{
				CreateTimer(0.3, Timer_AfterburnDMG, _, TIMER_REPEAT);
				CreateTimer(4.0+Supernova_burntimerbonus, Timer_Afterburn);
			}
			new Beopo = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			new HealingTarget = GetHealingTarget(client);
			if (IsValidEntity(Beopo))
			{
				new ItemDefinition = GetEntProp(Beopo, Prop_Send, "m_iItemDefinitionIndex");
				{
					if (ItemDefinition == 29 || 211 || 411 || 35)
					{
						new Address:Enveloper = TF2Attrib_GetByName(Beopo, "custom texture lo");
						{
							if (IsValidClient(HealingTarget) && Enveloper != Address_Null)
							{
								current_charge[HealingTarget] += max_charge[HealingTarget]*0.10;
							}
						}
					}
				}
			}
		}
	}
}

public Event_PlayerreSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		ResetAbilities(client);
	}
}

public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer=GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	charge_per[killer] = 4.0;
	if(IsValidClient(killer) && !IsFakeClient(killer) && IsValidClient(victim))
	{
		if (current_charge[killer] < max_charge[killer] && max_charge[killer] > 0.0 && is_lingering[killer] == 0.0)
		{
			new Float:KillCharge = charge_per[killer]+(Pow(max_charge[killer],0.50))*5;
			current_charge[killer] += KillCharge;
		}
		else
		{
			current_charge[killer] += 0.0;
		}
		if (Plague_active[killer] == true)
		{
			new slot = TF2_GetClientActiveSlot(killer);
			
			if (slot == 2)
			{
				new Float:Pos1[3];
				GetClientEyePosition(victim, Pos1);
				Pos1[2] -= 30.0;
			
				new particle6 = CreateEntityByName( "info_particle_system" );
				if ( IsValidEntity( particle6 ) )
				{
					TeleportEntity( particle6, Pos1, NULL_VECTOR, NULL_VECTOR );
					DispatchKeyValue( particle6, "effect_name", "gas_can_impact_red" );
					DispatchSpawn( particle6 );
					ActivateEntity( particle6 );
					AcceptEntityInput( particle6, "start" );
					SetVariantString( "OnUser1 !self:Kill::8:-1" );
					AcceptEntityInput( particle6, "AddOutput" );
					AcceptEntityInput( particle6, "FireUser1" );
				}
				
				for ( new i = 1; i <= MaxClients; i++ )
				{
					if(i != killer && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != GetClientTeam(killer))
					{
						new Float:Pos2[3];
						GetClientEyePosition(i, Pos2);
						Pos2[2] -= 30.0;
							
						new Float: distance = GetVectorDistance(Pos1, Pos2);
						if (distance <= Plague_DOTradius[killer])
						{
							decl Handle:Filter2;
							(Filter2 = INVALID_HANDLE);
								
							Filter2 = TR_TraceRayFilterEx(Pos1, Pos2, MASK_SOLID, RayType_EndPoint, TraceEntityFilterPlayer, i);
							if (Filter2 != INVALID_HANDLE)
							{
								if (!TR_DidHit(Filter2) && Plague_DOT2active[i] == false && current_charge[killer] > Plague_cost[killer]*1.20)
								{
									if (Plague_AOECooldownActive[killer] == false)
									{
										Plague_DOT2active[i] = true;
										Plague_DOTduration[i] = p_duration[killer];
										CreateTimer(0.6, Timer_Plague2, _, TIMER_REPEAT);
										current_charge[killer] -= Plague_cost[killer]*1.20;
										Plague_AOECooldownActive[killer] = true;
										CreateTimer(4.5, Timer_PlagueAOE, killer);
									}
								}
							}
							CloseHandle(Filter2);
						}
					}
				}
			}
		}
		if (Plague_DOTduration[victim] > 0.0)
		{
			Plague_DOTduration[victim] = 0.0;
			Plague_DOT1active[victim] = false;
			Plague_DOT2active[victim] = false;
		}
		if (Current_HealthPool[victim] > 0.0)
		{
			Current_HealthPool[victim] = 0.0;
		}
		new Float:MeleeFix = GetConVarFloat(cvar_MeleeFixActive);
		if (MeleeFix == 1.0)
		{
			new Beopo = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");	//Restore Health on Kill for Melee Fix
			if (IsValidEntity(Beopo))
			{
				new slot = TF2_GetClientActiveSlot(killer);
			
				if (slot == 2)
				{
					new Address:MeleeAttackRate = TF2Attrib_GetByName(Beopo, "melee attack rate bonus");
					new Address:RestoreHPonKill = TF2Attrib_GetByName(Beopo, "restore health on kill");
					new Address:MiniCritOnKill = TF2Attrib_GetByName(Beopo, "minicritboost on kill");
					if (MeleeAttackRate!=Address_Null && TF2Attrib_GetValue(MeleeAttackRate) < 0.30 && TF2_GetPlayerClass(killer) != TFClass_Spy)
					{
						if (RestoreHPonKill!=Address_Null)
						{
							new Float:Health = TF2_GetMaxHealth(killer)*(TF2Attrib_GetValue(RestoreHPonKill)/100);
							AddPlayerHealth(killer, RoundToFloor(Health), 2.5);
						}
						if (MiniCritOnKill!=Address_Null)
						{
							new Float:MiniCritDuration = TF2Attrib_GetValue(MiniCritOnKill);
							TF2_AddCondition(killer, TFCond_MiniCritOnKill, 1.0+MiniCritDuration);
						}
					}
				}
			}
		}
	}
}

//Buttons

public OnClientPreThink(client) OnPreThink(client);
public OnPreThink(client)
{
	new ButtonsLast = LastButtons[client];
	new Buttons = GetClientButtons(client);
	new Buttons2 = Buttons;
	
	// General Abilities
	Buttons = Attack3Abilities(client, Buttons, ButtonsLast);
	Buttons = OtherButtons(client, Buttons, ButtonsLast);
	Buttons = Agility_Move(client, Buttons, ButtonsLast);
	
	Buttons = EveloperUber(client, Buttons, ButtonsLast);
	
	// Yagorath
	Buttons = FormSwitch(client, Buttons, ButtonsLast);
	Buttons = SecondaryAttack(client, Buttons, ButtonsLast);
	Buttons = MainAttack(client, Buttons, ButtonsLast);
	
	if (Buttons != Buttons2) SetEntProp(client, Prop_Data, "m_nButtons", Buttons);	
	LastButtons[client] = Buttons;
}

Attack3Abilities(client, &Buttons, &ButtonsLast)
{
	if (IsValidClient(client))
	{
		new Address:Empowerment = TF2Attrib_GetByName(client, "empowerment");
		
		new Address:BloodMoon = TF2Attrib_GetByName(client, "bloodmoon");
		
		new Address:Supernova = TF2Attrib_GetByName(client, "supernova");
		
		if (Empowerment != Address_Null && max_charge[client] > 0.0 && Empowerment_Enable[client] == true)
		{
			if ((Buttons & IN_ATTACK3) == IN_ATTACK3)
			{
				if (EmpowermentCost[client]*1.3 <= current_charge[client] && is_lingering[client] == 0.0)
				{
					CreateTimer(1.8, Timer_Empowerment,_, TIMER_REPEAT);
					Empowerment_Active[client] += 1.0;
					is_lingering[client] += 1.0;
					PrintHintText(client, "Empowerment Active. All Damage done will be multiplied by: %.2f", Empowerment_Damage[client]*0.45);
				}
				if (EmpowermentCost[client]*1.3 > current_charge[client] && is_lingering[client] == 0.0)
				{
					PrintHintText(client, "Not Enough Charge. Minimum Charge Needed: %.0f", EmpowermentCost[client]*1.3);
				}
			}
		}
		if (BloodMoon != Address_Null && max_charge[client] > 0.0 && Bloodmoon_Enable[client] == true)
		{
			if ((Buttons & IN_ATTACK3) == IN_ATTACK3)
			{
				if (BloodMoonCost[client]*1.5 <= current_charge[client] && is_lingering[client] == 0.0)
				{
					CreateTimer(3.5, Timer_BloodMoon,_, TIMER_REPEAT);
					BloodMoon_Active[client] = true;
					is_lingering[client] += 1.0;
					PrintToChatAll("A Bloodmoon Rises...");
					EmitSoundToAll(BloodMoonSound);
				}
				if (BloodMoonCost[client]*1.5 > current_charge[client] && is_lingering[client] == 0.0)
				{
					PrintHintText(client, "Not Enough Charge. Minimum Charge Needed: %.0f", BloodMoonCost[client]*1.5);
				}
			}
		}
		if (Supernova != Address_Null && max_charge[client] > 0.0 && Supernova_active[client] == true)
		{
			if ((Buttons & IN_ATTACK3) == IN_ATTACK3)
			{
				if (Supernova_cost[client] == current_charge[client] && Supernova_special[client] == true)
				{
					Supernova_special[client] = false;
					current_charge[client] -= Supernova_cost[client];
					
					Supernova_specialtimer[client] = 30.0;
					
					
					new Float:Pos1[3];
					GetClientEyePosition(client, Pos1);
					Pos1[2] -= 30.0;
					
					EmitSoundToAll(Explosion);
					EmitSoundToAll(Explosion2);
					
					new particle2 = CreateEntityByName( "info_particle_system" );
					if ( IsValidEntity( particle2 ) )
					{
						TeleportEntity( particle2, Pos1, NULL_VECTOR, NULL_VECTOR );
						DispatchKeyValue( particle2, "effect_name", "fireSmoke_collumn" );
						DispatchSpawn( particle2 );
						ActivateEntity( particle2 );
						AcceptEntityInput( particle2, "start" );
						SetVariantString( "OnUser1 !self:Kill::8:-1" );
						AcceptEntityInput( particle2, "AddOutput" );
						AcceptEntityInput( particle2, "FireUser1" );
					}
					
					new particle3 = CreateEntityByName( "info_particle_system" );
					if ( IsValidEntity( particle3 ) )
					{
						TeleportEntity( particle2, Pos1, NULL_VECTOR, NULL_VECTOR );
						DispatchKeyValue( particle2, "effect_name", "skull_island_explosion" );
						DispatchSpawn( particle2 );
						ActivateEntity( particle2 );
						AcceptEntityInput( particle2, "start" );
						SetVariantString( "OnUser1 !self:Kill::8:-1" );
						AcceptEntityInput( particle2, "AddOutput" );
						AcceptEntityInput( particle2, "FireUser1" );
					}
					
					for ( new i = 1; i <= MaxClients; i++ )
					{
						if(i != client && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != GetClientTeam(client))
						{
							new Float:Pos2[3];
							GetClientEyePosition(i, Pos2);
							Pos2[2] -= 30.0;
								
							new Float: distance = GetVectorDistance(Pos1, Pos2);
							if (distance <= Supernova_radius[client])
							{
								decl Handle:Filter2;
								(Filter2 = INVALID_HANDLE);
									
								Filter2 = TR_TraceRayFilterEx(Pos1, Pos2, MASK_SOLID, RayType_EndPoint, TraceEntityFilterPlayer, i);
								if (Filter2 != INVALID_HANDLE)
								{
									if (!TR_DidHit(Filter2))
									{
										//DealDamage(i, RoundToFloor(Supernova_damage[client]), client, DMG_BLAST);
										SDKHooks_TakeDamage(i, client, client, Supernova_damage[client], DMG_NERVEGAS, -1, NULL_VECTOR, NULL_VECTOR, true);
										Supernova_afterburn[i] = 1.0;
									}
								}
								CloseHandle(Filter2);
							}
						}
					}
				}
				if (Supernova_cost[client] > current_charge[client] && Supernova_special[client] == true)
				{
					PrintHintText(client, "Not Enough Charge. Charge Needed: %.0f", Supernova_cost[client]);
				}
				if (Supernova_cost[client] == current_charge[client] && Supernova_special[client] == false && Supernova_specialtimer[client] > 0.0)
				{
					PrintHintText(client, "Special Ability Not Available. Time Remaining : %.0f", Supernova_specialtimer[client]);
				}
			}
		}
		if (Immortal_active[client] == true && max_charge[client] > 0.0)
		{
			if ((Buttons & IN_ATTACK3) == IN_ATTACK3)
			{
				if (Immortal_cost[client]*1.2 <= max_charge[client] && Immortal_ready[client] == true && Immortal_timer[client] == 0.0)
				{
					Immortal_buffed[client] = true;
					Immortal_Own[client] = true;
					Immortal_timer[client] = 40.0;
					TF2Attrib_SetByName(client, "CARD: move speed bonus", 0.20);
					
					CreateTimer(0.7, Timer_Immortal, client, TIMER_REPEAT);
				}
				if (Immortal_cost[client]*1.2 > current_charge[client] && Immortal_ready[client] == true)
				{
					PrintHintText(client, "Not Enough Charge. Charge Needed: %.0f", Immortal_cost[client]*1.2);
				}
				if (Immortal_cost[client]*1.2 < current_charge[client] && Immortal_timer[client] > 0.0 && Immortal_ready[client] == false)
				{
					PrintHintText(client, "Immortal Not Available. Time Remaining : %.0f", Immortal_timer[client]);
				}
			}
		}
	}
	return Buttons;
}

OtherButtons(client, &Buttons, &ButtonsLast)
{
	new Address:Knockout = TF2Attrib_GetByName(client, "knockout");
	
	if (Knockout != Address_Null && max_charge[client] > 0.0 && Knockout_active[client] == true)
	{
		//new Melee=GetPlayerWeaponSlot(client,2);
		new slot = TF2_GetClientActiveSlot(client);
		
		if (slot == 2 && (Buttons & IN_ATTACK) == IN_ATTACK && current_charge[client] > Knockout_slowcost[client])
		{
			new Float:Pos4[3];
			GetClientEyePosition(client, Pos4);
			Pos4[2] -= 30.0;
			
			AttachParticle(client, "unusual_robot_orbiting_sparks", 0.1);
			
			for ( new i = 1; i <= MaxClients; i++ )
			{
				if(i != client && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != GetClientTeam(client))
				{
					new Float:Pos3[3];
					GetClientEyePosition(i, Pos3);
					Pos3[2] -= 30.0;
							
					new Float: distance = GetVectorDistance(Pos4, Pos3);
					if (distance <= Knockout_slow_radius[client])
					{
						if (Knockout_slow_duration[i] == 0.0 && Knockout_isslowed[i] == 0.0)
						{
							current_charge[client] -= Knockout_slowcost[client];
							Knockout_slow_duration[i] = k_duration[client];
							Knockout_isslowed[i] = 1.0;
							EmitSoundToClient(i, Sound15);
							EmitSoundToClient(client, Sound15);
						}
					}
				}
			}
		}
	}
	return Buttons;
}

Agility_Move(client, &Buttons, &ButtonsLast)
{
	if (Agility_active[client] == true)
	{
		if ((Buttons & IN_FORWARD) || (Buttons & IN_BACK) || (Buttons & IN_LEFT) || (Buttons & IN_RIGHT))
		{
			if (Agility_MoveTimer[client] < 80.0)
			{
				Agility_MoveTimer[client] += 1.0;
			}
			if (Agility_MoveTimer[client] == 80.0)
			{
				Agility_Speedboostactive[client] = true;
			}
		}
	}
	return Buttons;
}

// Yagorath Specific Stuff

FormSwitch(client, &Buttons, &ButtonsLast)
{
	if (Yagorath_active[client] == true)
	{
		if ((Buttons & IN_RELOAD == IN_RELOAD))
        {
			Yagorath_Switch_Forms(client);
			//PrintToChat(client, "Delay %.0f", FormSwitch_Delay[client]);
		}
	}
	return Buttons;
}

MainAttack(client, &Buttons, &ButtonsLast)
{
	if (Yagorath_active[client] == true && TravelForm_active[client] == false)
	{
		if ((Buttons & IN_ATTACK) == IN_ATTACK)
		{
			//Yagorath_MainAttack(client);
		}
	}
	return Buttons;
}
SecondaryAttack(client, &Buttons, &ButtonsLast)
{
	if (Yagorath_active[client] == true && TravelForm_active[client] == false)
	{
		if ((Buttons & IN_ATTACK2 == IN_ATTACK2))
		{
			Yagorath_FireProjectile(client);
		}
	}
	return Buttons;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) 
{
	if (Yagorath_active[client] == true)
	{
		if (TravelForm_active[client] == true)
		{
			TF2Attrib_SetByName(client, "move speed penalty", 0.60);
			SetEntityMoveType(client, MOVETYPE_WALK);
			if (buttons & IN_ATTACK)
			{
				buttons &= ~IN_ATTACK;
				return Plugin_Continue;
			}
			if (buttons & IN_ATTACK2)
			{
				buttons &= ~IN_ATTACK2;
				return Plugin_Continue;
			}
		}
		else
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
		}
	}
	if (Overflow_Protection[client] == false && current_charge[client] > max_charge[client])
	{
		Overflow_Protection[client] = true;
	}
	if (Agility_active[client] == true)
	{
		if(Agility_Speedboostactive[client] == true)
		{
			TF2Attrib_SetByName(client, "CARD: move speed bonus", 1.20);
			AttachParticle(client, "unusual_robot_orbiting_sparks2", 0.1);
			new Float:Pos[3];
			
			GetClientEyePosition(client, Pos);
			EmitSoundFromOrigin(AgilitySpeedBoostActive, Pos);
			
			Pos[2] -= 30.0;
			new Float:Radius = 450.0;
			
			
			for ( new i = 1; i <= MaxClients; i++ )
			{
				if(i != client && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != GetClientTeam(client))
				{
					new Float:Pos2[3];
					GetClientEyePosition(i, Pos2);
					Pos2[2] -= 30.0;
						
					new Float: distance = GetVectorDistance(Pos, Pos2);
					if (distance <= Radius)
					{
						decl Handle:Filter2;
						(Filter2 = INVALID_HANDLE);
							
						Filter2 = TR_TraceRayFilterEx(Pos, Pos2, MASK_SOLID, RayType_EndPoint, TraceEntityFilterPlayer, i);
						if (Filter2 != INVALID_HANDLE)
						{
							if (!TR_DidHit(Filter2))
							{
								SDKHooks_TakeDamage(i, client, client, 7.0, DMG_NERVEGAS, -1, NULL_VECTOR, NULL_VECTOR, false);
								current_charge[client] -= 5.0;
							}
						}
						CloseHandle(Filter2);
					}
				}
			}
		}
		if (Agility_Speedboostactive[client] == false)
		{
			TF2Attrib_RemoveByName(client, "CARD: move speed bonus");
		}
		if ((buttons & IN_FORWARD) != IN_FORWARD && (buttons & IN_BACK) != IN_BACK && (buttons & IN_LEFT) != IN_LEFT && (buttons & IN_RIGHT) != IN_RIGHT)
		{
			Agility_MoveTimer[client] = 0.0;
		}
	}
	return Plugin_Changed;
}

// Custom Weapons

EveloperUber(client, &Buttons, &ButtonsLast)
{
	new Medigun = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	new HealingTarget = GetHealingTarget(client);
	
	if (IsValidEntity(Medigun))
	{
		new ItemDefinition = GetEntProp(Medigun, Prop_Send, "m_iItemDefinitionIndex");
		{
			if (ItemDefinition == 29 || 211 || 411 || 35)
			{
				if ((Buttons & IN_ATTACK2) == IN_ATTACK2)
				{
					if (IsValidClient(HealingTarget))
					{
						new Address:Enveloper = TF2Attrib_GetByName(Medigun, "custom texture lo");
						{
							if (Enveloper != Address_Null)
							{
								UberPercent[client] = GetEntPropFloat(Medigun, Prop_Send, "m_flChargeLevel");
								if (UberPercent[client] == 1)
								{
									new Float:Pos[3];
									
									GetClientEyeAngles(client, Pos);
									Eveloper_Buffed[HealingTarget] = true;
									current_charge[HealingTarget] = max_charge[HealingTarget]*2;
									EmitSoundFromOrigin(EnveloperUberSound, Pos);
								}
							}
						}
					}
				}
			}
		}
	}
	return Buttons;
}

// Actual Functions

public Action:OnTakeDamage_Building(Ent, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (IsValidClient(attacker))
	{
		new String:classname[128]; 
		GetEdictClassname(inflictor, classname, sizeof(classname));
		new Gunbs = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if (Empowerment_Active[attacker] == 1.0)
		{
			if (IsValidEntity(Gunbs))
			{
				damage *= Empowerment_Damage[attacker]*0.45;
			}
		}
		if (IsPlayerAlive(attacker) && (!strcmp("tf_projectile_spellfireball", classname)))
		{
			new Address:Fireball = TF2Attrib_GetByName(attacker, "cannot delete");
			if (Fireball!=Address_Null)
			{
				//damagetype |= DMG_NERVEGAS;
				damage *= Fireball_damage[attacker]*2.0;
				current_charge[attacker] += Fireball_cost[attacker]*0.4;
			}
		}
		if (IsPlayerAlive(attacker) && (!strcmp("tf_projectile_spellmeteorshower", classname)))
		{
			new Address:MeteorShower = TF2Attrib_GetByName(attacker, "force center wrap");
			if (MeteorShower!=Address_Null)
			{
				//damagetype |= DMG_NERVEGAS;
				damage *= MeteorShower_damage[attacker];
				current_charge[attacker] += MetorShower_cost[attacker]*0.4;
			}
		}
		if (IsPlayerAlive(attacker) && (!strcmp("tf_projectile_spellbats", classname)))
		{
			new Address:Bats = TF2Attrib_GetByName(attacker, "quest loaner id hi");
			if (Bats!=Address_Null)
			{
				//damagetype |= DMG_NERVEGAS;
				damage *= Bats_damage[attacker];
				current_charge[attacker] += Bats_cost[attacker]*0.4;
			}
		}
	}
	return Plugin_Changed;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	new String:classname[128]; 
	if (IsValidEdict(inflictor))
	{
		GetEdictClassname(inflictor, classname, sizeof(classname));
	}
	new HealingTarget = GetHealingTarget(victim);
	if (IsValidClient(attacker))
	{
		new Beopo = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		new slot = TF2_GetClientActiveSlot(attacker);
		if (Empowerment_Active[attacker] == 1.0)
		{
			if (IsValidEntity(Beopo))
			{
				damage *= Empowerment_Damage[attacker]*0.45;
				if (damagetype & DMG_BURN)
				{
					damage *= Empowerment_Damage[attacker]*0.45;
				}
				if (damagetype & DMG_SLASH)
				{
					damage *= Empowerment_Damage[attacker]*0.45;
				}
			}
		}
		if (Knockout_active[attacker] == true)
		{
			if (IsValidEntity(Beopo) && Knockout_isslowed[victim] == 1.0)
			{
				if (slot == 2)
				{
					damage *= 2.50;
					if (damagetype & DMG_BURN || DMG_SLASH)
					{
						damage *= 1.65;
					}
				}
			}
			/*
			if (victim != attacker && IsValidEntity(Beopo))
			{
				damagetype |= DMG_PREVENT_PHYSICS_FORCE;
			}
			*/
		}
		if (Supernova_active[attacker] == true)
		{
			if (IsValidEntity(Beopo) && damagetype & DMG_BLAST)
			{
				damage *= 1.75;
			}
		}
		if (Plague_active[attacker] == true && Plague_DOT1active[victim] == false && current_charge[attacker] > Plague_cost[attacker]*0.40)
		{
			if (IsValidEntity(Beopo))
			{
				if (slot == 2)
				{
					Plague_DOT1active[victim] = true;
					Plague_DOTduration[victim] = p_duration[attacker];
					CreateTimer(0.4, Timer_Plague1, _, TIMER_REPEAT);
					current_charge[attacker] -= Plague_cost[attacker]*0.40;
					PrintHintText(attacker, "Infected %N", victim);
					EmitSoundFromOrigin(PlagueHit, damagePosition);
				}
			}
		}
		if (Plague_active[attacker] == true && Plague_DOT1active[victim] || Plague_DOT2active[victim] == true)
		{
			if (IsValidEntity(Beopo) && damagetype & DMG_SLASH)
			{
				if (slot == 2)
				{
					current_charge[attacker] += 1.3;
				}
			}
		}
		if (King_active[attacker] == true && victim != attacker)
		{
			if (IsValidEntity(Beopo) && current_charge[attacker] >= King_cost[attacker])
			{
				damage *= 1.50;
				
				new Float:Pos5[3];
				Pos5[2] -= 30.0;
				GetClientEyePosition(attacker, Pos5);
				
				for ( new i = 1; i <= MaxClients; i++ )
				{
					if(IsClientInGame(i) && IsPlayerAlive(i) && !(GetClientTeam(i) != GetClientTeam(attacker)))
					{
						new Float:Pos6[3];
						GetClientEyePosition(i, Pos6);
						Pos6[2] -= 30.0;
				
						new Float:Distance = GetVectorDistance(Pos5, Pos6);
						if (Distance <= King_boostradius[attacker])
						{
							TF2_AddCondition(attacker, TFCond_InHealRadius, 1.0);
							if (King_boostactive[i] == false)
							{
								King_boostactive[i] = true;
								fl_AdditionalArmorRegen[i] = 5.0;
								current_charge[attacker] -= King_cost[attacker];
								CreateTimer(2.0, Timer_KingBoost);
							}
						}
						else
						{
							King_boostactive[i] = false;
						}
					}
				}
			}
		}
		if (King_boostactive[attacker] == true)
		{
			if (IsValidEntity(Beopo))
			{
				damage *= 1.50;
			}
		}
		if (victim != attacker && King_boostactive[victim] && King_active[victim] == true)
		{
			if (IsValidEntity(Beopo))
			{
				damagetype |= DMG_PREVENT_PHYSICS_FORCE;
			}
		}
		if (Reflect_active[victim] == true && IsValidClient(attacker))
		{
			if (IsValidEntity(Beopo))
			{
				damage *= 0.45;
			}
		}
		if (Resistance_active[victim] == true && IsValidClient(attacker)) //Resistance Range Damage Reduction
		{
			if (IsValidEntity(Beopo))
			{
				Resistance_minrange = 600.0;
				new Float:Pos4[3];
				GetClientEyePosition(victim, Pos4);
				Pos4[2] -= 30.0;
				
				new Float:Pos3[3];
				GetClientEyePosition(attacker, Pos3);
				Pos3[2] -= 30.0;
				new Float: distance = GetVectorDistance(Pos4, Pos3);
				
				if (distance <= Resistance_range[victim] && !(distance > Resistance_range[victim]) && distance > Resistance_minrange && current_charge[victim] > Resistance_cost[victim])
				{
					new Float:DmgReduc = distance/100.0;
					damage /= DmgReduc;
					current_charge[victim] -= Resistance_cost[victim];
					PrintToConsole(victim, "Damage taken Distance: %.0f. Damage Reduced by %.0f.", distance, DmgReduc);
				}
				if (Plague_active[attacker] == true && Plague_DOT1active[victim] || Plague_DOT2active[victim] == true)
				{
					if (damagetype & DMG_SLASH)
					{
						damage *= 0.40;
					}
				}
			}
		}
		if (Precision_active[attacker] == true && IsValidClient(attacker)) //Precision Range Damage Multiplier
		{
			if (IsValidEntity(Beopo))
			{
				Precision_minrange = 600.0;
				new Float:Pos4[3];
				GetClientEyePosition(victim, Pos4);
				Pos4[2] -= 30.0;
				
				new Float:Pos3[3];
				GetClientEyePosition(attacker, Pos3);
				Pos3[2] -= 30.0;
				new Float: distance = GetVectorDistance(Pos4, Pos3);
				
				if (distance <= Precision_range[attacker] && !(distance > Precision_range[attacker]) && distance > Precision_minrange && current_charge[attacker] > Precision_cost[attacker])
				{
					new Float:DmgMult = distance*0.75/200.0;
					current_charge[attacker] -= Precision_cost[attacker];
					
					if (Resistance_active[victim] == false)
					{
						damage *= 1.0+DmgMult;
						PrintToConsole(attacker, "Distance: %.0f. Damage Multiplied by %.1f.", distance, DmgMult);
						
						if(!strcmp("tf_projectile_spellmeteorshower", classname) || (!strcmp("tf_projectile_spellfireball", classname)) || (!strcmp("tf_projectile_spellbats", classname)))
						{
							damage *= 1.0+DmgMult;
						}
					}
					else
					{
						damage *= 1.0+DmgMult*0.5;
						PrintToConsole(attacker, "Distance: %.0f. Damage Multiplied by %.1f. Victim Has Resistance Active", distance, DmgMult*0.5+1);
						
						if(!strcmp("tf_projectile_spellmeteorshower", classname) || (!strcmp("tf_projectile_spellfireball", classname)) || (!strcmp("tf_projectile_spellbats", classname)))
						{
							damage *= 1.0+DmgMult*0.5;
						}
					}
				}
			}
		}
		if (IsPlayerAlive(attacker) && (!strcmp("tf_projectile_spellfireball", classname)) && victim != GetClientTeam(attacker))
		{
			new Address:Fireball = TF2Attrib_GetByName(attacker, "fireball");
			new Address:Fun = TF2Attrib_GetByName(victim, "obsolete ammo penalty");
			if (Fireball!=Address_Null)
			{
				damagetype |= DMG_PREVENT_PHYSICS_FORCE;
				damage = Fireball_damage[attacker];
				current_charge[attacker] += Fireball_cost[attacker]*0.4;
				if (IsFakeClient(victim))
				{
					damage *= 0.20;
				}
				if (!IsFakeClient(victim))
				{
					damage *= 0.70;
				}
				if (Empowerment_Active[attacker] == 1.0)
				{
					damage *= Empowerment_Damage[attacker]*0.45;
				}
				if (Fun != Address_Null)
				{
					damage *= Pow(TF2Attrib_GetValue(Fun),0.15);
				}
				else
				{
					damage *= 1.0;
				}
			}
		}
		if (IsPlayerAlive(attacker) && (!strcmp("tf_projectile_spellmeteorshower", classname)) && victim != GetClientTeam(attacker))
		{
			new Address:MeteorShower = TF2Attrib_GetByName(attacker, "meteor shower");
			new Address:Fun = TF2Attrib_GetByName(victim, "obsolete ammo penalty");
			if (MeteorShower!=Address_Null)
			{
				damagetype |= DMG_PREVENT_PHYSICS_FORCE;
				damage = MeteorShower_damage[attacker];
				current_charge[attacker] += MetorShower_cost[attacker]*0.4;
				if (IsFakeClient(victim))
				{
					damage *= 0.20;
				}
				if (!IsFakeClient(victim))
				{
					damage *= 0.30;
				}
				if (Empowerment_Active[attacker] == 1.0)
				{
					damage *= Empowerment_Damage[attacker]*0.45;
				}
				if (Fun != Address_Null)
				{
					damage *= Pow(TF2Attrib_GetValue(Fun),0.10);
				}
				else
				{
					damage *= 1.0;
				}
			}
		}
		if (IsPlayerAlive(attacker) && (!strcmp("tf_projectile_spellbats", classname)) && victim != GetClientTeam(attacker))
		{
			new Address:Bats = TF2Attrib_GetByName(attacker, "bats");
			new Address:Fun = TF2Attrib_GetByName(victim, "obsolete ammo penalty");
			if (Bats!=Address_Null)
			{
				damagetype |= DMG_PREVENT_PHYSICS_FORCE;
				damage = Bats_damage[attacker];
				current_charge[attacker] += Bats_cost[attacker]*0.4;
				if (IsFakeClient(victim))
				{
					damage *= 0.20;
				}
				if (!IsFakeClient(victim))
				{
					damage *= 1.15;
				}
				if (Empowerment_Active[attacker] == 1.0)
				{
					damage *= Empowerment_Damage[attacker]*0.45;
				}
				if (Fun != Address_Null)
				{
					damage *= Pow(TF2Attrib_GetValue(Fun),0.25);
				}
				else
				{
					damage *= 1.0;
				}
			}
		}
		if (IsValidClient(HealingTarget))
		{
			if (IsValidEntity(Beopo))
			{
				new ItemDefinition = GetEntProp(Beopo, Prop_Send, "m_iItemDefinitionIndex");
				{
					if (ItemDefinition == 29 || 211 || 411 || 35)
					{
						new Address:Enveloper = TF2Attrib_GetByName(Beopo, "custom texture lo");
						{
							if (Enveloper != Address_Null && HealingTarget == victim)
							{
								damage *= 0.75;
							}
						}
					}
				}
			}
		}
		if (Immortal_active[victim] == true && Immortal_buffed[victim] == false && IsValidClient(victim))
		{
			damage *= 0.70;
		}
		if (Immortal_buffed[victim] == true && IsValidClient(victim))
		{
			if (IsValidEntity(Beopo))
			{
				damage *= 0.50;
				
				new clientMaxHealth = TF2_GetMaxHealth(victim);
				
				if (clientMaxHealth <= TF2_GetMaxHealth(victim)*0.55)
				{
					damage *= 0.0;
				}
			}
		}
	}
	return Plugin_Changed;
}

public Event_Playerhurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new killer=GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim=GetClientOfUserId(GetEventInt(event, "userid"));
	new Float:damage = GetEventFloat(event, "damageamount");
	
	if (IsValidClient(killer))
	{
		new Beopo2 = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
	
		if (BloodMoon_Active[killer] && IsValidClient(killer))
		{
			if (IsValidEntity(Beopo2) && IsValidClient(killer) && GetClientTeam(victim) != GetClientTeam(killer))
			{
				Regen = damage*0.3*(BloodMoon_Effect[killer]*0.3);
				
				if (Regen > 200.0)
				{
					Regen = 200.0;
				}
				
				AddPlayerHealth(killer, RoundToFloor(Regen), 2.5);
				PrintToConsole(killer, "%0.f Health Healed", Regen);
				fl_CurrentArmor[killer] += Regen;
				PrintToConsole(killer, "%0.f Armor Regenerated", Regen);
			}
		}
		if (BloodMoon_Buffed[killer] && IsValidEntity(Beopo2) && IsValidClient(killer) && GetClientTeam(victim) != GetClientTeam(killer))
		{
			new Float:Regen2 = damage*0.3*(2.5*0.3);
			
			if (Regen > 200.0)
			{
				Regen = 200.0;
			}
			AddPlayerHealth(killer, RoundToFloor(Regen2), 2.5);
			PrintToConsole(killer, "%0.f Health Healed", Regen2);
			fl_CurrentArmor[killer] += Regen2;
			PrintToConsole(killer, "%0.f Armor Regenerated", Regen2);
		}
		
		if (Reflect_active[victim] == true && Current_HealthPool[victim] < Reflect_HealthPool[victim] && current_charge[victim] > Reflect_cost[victim])
		{
			Current_HealthPool[victim] += damage*0.40;
		}
		if (Reflect_active[victim] == true && Reflect_dmgreflectactive[victim] == true && current_charge[victim] > Reflect_cost[victim]*2.0)
		{
			if (IsValidClient(victim) && IsValidClient(killer))
			{
				new ClientWeapon = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(ClientWeapon))
				{
					decl String:logname[32];
					GetEdictClassname(ClientWeapon, logname, sizeof(logname));
					
					new Float:Reflect_Dmg = damage*0.65;
					current_charge[victim] -= Reflect_cost[victim]*2.0;
					SDKHooks_TakeDamage(killer, victim, victim, Reflect_Dmg, DMG_NERVEGAS, ClientWeapon, NULL_VECTOR, NULL_VECTOR, true);
				}
			}
		}
	}
}

public OnGameFrame()
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			if (BloodMoon_Active[client])
			{
				for ( new i = 1; i <= MaxClients; i++ )
				{
					if(IsValidClient(i) && IsValidClient(client) && GetClientTeam(i) != GetClientTeam(client))
					{
						SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1, 1);
					}
                }
				new Float:Pos5[3];
				Pos5[2] -= 30.0;
				GetClientEyePosition(client, Pos5);
		
				for ( new i = 1; i <= MaxClients; i++ )
				{
					if(i != client && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == GetClientTeam(client))
					{
						new Float:Pos6[3];
						GetClientEyePosition(i, Pos6);
						Pos6[2] -= 30.0;
				
						new Float:Distance = GetVectorDistance(Pos5, Pos6);
						if (Distance <= BloodMoon_Radius[client])
						{
							BloodMoon_Buffed[i] = true;
						}
						else
						{
							BloodMoon_Buffed[i] = false;
						}
					}
				}
			}
			if (BloodMoon_Buffed[client])
			{
				TF2_AddCondition(client, TFCond_InHealRadius, 1.0);
			}
			if (BloodMoon_Active[client])
			{
				TF2_AddCondition(client, TFCond_InHealRadius, 1.0);
			}
			else
			{
				TF2_RemoveCondition(client, TFCond_InHealRadius);
			}
			if (!BloodMoon_Active[client])
			{
				for ( new i = 1; i <= MaxClients; i++ )
				{
					if(IsValidClient(i) && IsValidClient(client) && GetClientTeam(i) != GetClientTeam(client))
					{
						SetEntProp(i, Prop_Send, "m_bGlowEnabled", 0, 1);
					}
                }
			}
			if (Knockout_active[client] == true)
			{
				new Melee=GetPlayerWeaponSlot(client,2);
				TF2Attrib_SetByName(Melee, "referenced item id low", Knockout_disruptor_add[client]);
			}
			if (!IsPlayerAlive(client))
			{
				Supernova_afterburn[client] = 0.0;
			}
			if (Plague_DOTduration[client] > 0.0)
			{
				TF2Attrib_SetByName(client, "health from healers reduced", 0.30);
				TF2Attrib_SetByName(client, "health from packs decreased", 0.30);
			}
			if (Plague_DOTduration[client] == 0.0)
			{
				TF2Attrib_RemoveByName(client, "health from packs decreased");
				TF2Attrib_RemoveByName(client, "health from healers reduced");
			}
			if (Reflect_active[client] == true && Current_HealthPool[client] > 0.0)
			{
				TF2Attrib_SetByName(client, "hidden maxhealth non buffed", Current_HealthPool[client]);
			}
			if (Current_HealthPool[client] == 0.0)
			{
				TF2Attrib_RemoveByName(client, "hidden maxhealth non buffed");
			}
			new HealingTarget = GetHealingTarget(client);
			if (IsValidClient(HealingTarget))
			{
				new Beopo = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(Beopo))
				{
					new ItemDefinition = GetEntProp(Beopo, Prop_Send, "m_iItemDefinitionIndex");
					{
						if (ItemDefinition == 29 || 211 || 411 || 35)
						{
							new Address:Enveloper = TF2Attrib_GetByName(Beopo, "custom texture lo");
							{
								if(Enveloper != Address_Null)
								{
									if (IsValidClient(HealingTarget))
									{
										Eveloper_BaseBuff[HealingTarget] = true;
									}
									else
									{
										CreateTimer(1.5, Timer_EvelBuffClear, HealingTarget);
									}
								}
							}
						}
					}
				}
			}
			if (Eveloper_BaseBuff[client] == true)
			{
				Overflow_Protection[client] = false;
				new Float:ChargeBonus[MAXPLAYERS+1];
				ChargeBonus[client] = max_charge[client]*2.0;
				current_charge[client] = ChargeBonus[client];
			
				ability_power[client] *= 1.5;
			}
			if (Eveloper_Buffed[client] == true && Overflow_Protection[client] == false)
			{
				ability_power[client] *= 1.5;
				Supernova_cost[client] *= 0.0;
				Resistance_cost[client] *= 0.0;
				Precision_cost[client] *= 0.0;
				Plague_cost[client] *= 0.0;
				EmpowermentCost[client] *= 0.0;
				BloodMoonCost[client] *= 0.0;
				Knockout_slowcost[client] *= 0.0;
				King_cost[client] *= 0.0;
				Reflect_cost[client] *= 0.0;
				Fireball_cost[client] *= 0.0;
				Bats_cost[client] *= 0.0;
				MetorShower_cost[client] *= 0.0;
			}
			if (Agility_MoveTimer[client] > 80.0)
			{
				Agility_MoveTimer[client] = 80.0;
			}
			if (Agility_MoveTimer[client] < 80.0)
			{
				Agility_Speedboostactive[client] = false;
			}
			if (Agility_active[client] == false)
			{
				Agility_MoveTimer[client] = 0.0;
			}
			if (Immortal_Own[client] == true)
			{
				new Float:Pos5[3];
				Pos5[2] -= 30.0;
				GetClientEyePosition(client, Pos5);
		
				for ( new i = 1; i <= MaxClients; i++ )
				{
					if(i != client && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == GetClientTeam(client))
					{
						new Float:Pos6[3];
						GetClientEyePosition(i, Pos6);
						Pos6[2] -= 30.0;
				
						new Float:Distance = GetVectorDistance(Pos5, Pos6);
						
						if (Distance <= Immortal_radius[client])
						{
							Immortal_buffed[i] = true;
							TF2_AddCondition(client, TFCond_InHealRadius, 1.0);
						}
						else
						{
							Immortal_buffed[i] = false;
							TF2_RemoveCondition(client, TFCond_InHealRadius);
						}
					}
				}
			}
			new Float:infinitecharge = GetConVarFloat(cvar_infchargeactive);
			if (TF2_IsPlayerInCondition(client, TFCond_CritOnWin) || infinitecharge == 1.0)
			{
				current_charge[client] = max_charge[client];
			}
			if (King_active[client] && King_boostactive[client] == false)
			{
				fl_AdditionalArmorRegen[client] = 0.0;
			}
		}
	}
}

// Timers N Stuff

public Action:Timer_Immortal(Handle:timer, any:client)
{
	if (IsValidClient(client))
	{
		if (Immortal_Own[client] == true)
		{
			max_charge[client] -= Immortal_cost[client];
		}
		if (current_charge[client] < 0.0)
		{
			Immortal_Own[client] = false;
			Immortal_buffed[client] = false;
			Immortal_timer[client] = 40.0;
			Immortal_ready[client] = false;
			TF2Attrib_RemoveByName(client, "CARD: move speed bonus");
			KillTimer(timer);
		}
	}
}

public Action:Timer_EvelBuffClear(Handle:timer, any:HealingTarget)
{
	if (IsValidClient(HealingTarget))
	{
		if (Overflow_Protection[HealingTarget] == false)
		{
			Overflow_Protection[HealingTarget] = true;
		}
		if (Eveloper_Buffed[HealingTarget] == true)
		{
			Eveloper_Buffed[HealingTarget] = false;
		}
		if (Eveloper_BaseBuff[HealingTarget] == true)
		{
			Eveloper_BaseBuff[HealingTarget] = false;
		}
	}
}
	
public Action:Timer_Empowerment(Handle:timer)
{
	for(new client = 1; client < MaxClients; client++)
	{	
		if (IsValidClient(client))
		{
			new Address:Empowerment = TF2Attrib_GetByName(client, "empowerment");
	
			if (Empowerment != Address_Null && is_lingering[client] == 1.0 && Empowerment_Active[client] == 1.0)
			{
				current_charge[client] -= EmpowermentCost[client]*0.7;
				
			}
		}
		if (current_charge[client] < 0.0)
		{
			is_lingering[client] = 0.0;
			Empowerment_Active[client] = 0.0;
			PrintToChat(client, "Damage Has Been Returned To Normal Values");
			KillTimer(timer);
		}
	}
}		

public Action:Timer_BloodMoon(Handle:timer)
{
	for(new client = 1; client < MaxClients; client++)
	{	
		if (IsValidClient(client))
		{
			new Address:BloodMoon = TF2Attrib_GetByName(client, "bloodmoon");
			
			if (BloodMoon != Address_Null && is_lingering[client] == 1.0 && BloodMoon_Active[client])
			{
				current_charge[client] -= BloodMoonCost[client]*0.60;
				
			}
		}
		if (current_charge[client] < 0.0)
		{
			is_lingering[client] = 0.0;
			BloodMoon_Active[client] = false;
			PrintToChatAll("The Bloodmoon Sets.");
			EmitSoundToAll(BloodMoonSound2);
			EmitSoundToAll(BloodMoonSound3);
			KillTimer(timer);
		}
	}
}

public Action:Timer_Supernova(Handle:timer)
{
	for(new client = 1; client < MaxClients; client++)
	{	
		if (IsValidClient(client))
		{
			if (Supernova_active[client] == true && Supernova_special[client] == false)
			{
				Supernova_specialtimer[client] -= 1.0;
				
				if (Supernova_specialtimer[client] < 0.0)
				{
					Supernova_specialtimer[client] = 0.0;
				}
				if (Supernova_specialtimer[client] == 0.0)
				{
					PrintToChat(client, "Supernova Special Ability Fully Charged (Middle Mouse to use)");
					Supernova_special[client] = true;
				}
			}
			if (Immortal_active[client] == true && Immortal_ready[client] == false)
			{
				Immortal_timer[client] -= 1.0;
				
				if (Immortal_timer[client] < 0.0)
				{
					Immortal_timer[client] = 0.0;
				}
				if (Immortal_timer[client] == 0.0 && Immortal_ready[client] == false)
				{
					PrintToChat(client, "Immortal Ready (Middle Mouse to use)");
					Immortal_ready[client] = true;
				}
			}
		}
	}
}

public Action:Timer_AfterburnDMG(Handle:timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			for(new i = 1; i < MaxClients; i++)
			{
				if(IsValidClient(i) && IsValidClient(client) && GetClientTeam(i) != GetClientTeam(client) && Supernova_active[client] == true)
				{
					if (IsValidClient(i) && Supernova_afterburn[i] == 1.0)
					{
						new Float:Dmg = 150+(TF2_GetMaxHealth(client)*0.05)*0.2;
						//DealDamage(i, RoundToFloor(Dmg), client, DMG_NERVEGAS,"pumpkindeath");
						SDKHooks_TakeDamage(i, client, client, Dmg, DMG_NERVEGAS, -1, NULL_VECTOR, NULL_VECTOR, true);
						EmitSoundToClient(i, BurnSound1);
					}
				}
			}
		}
	}
}

public Action:Timer_Afterburn(Handle:timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client) && Supernova_afterburn[client] == 1.0)
		{
			Supernova_afterburn[client] = 0.0;
		}
	}
}

public Action:Timer_Plague1(Handle:timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			if (Plague_DOT1active[client] == true && Plague_DOTduration[client] > 0.0)
			{
				for(new attacker = 1; attacker < MaxClients; attacker++)
				{
					//new Float:Dmg = TF2_GetMaxHealth(client)*0.02;
					if (IsValidClient(attacker) && Plague_active[attacker] == true && IsPlayerAlive(attacker))
					{
						new Beopo = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
						new slot = TF2_GetClientActiveSlot(attacker);
						
						if (IsValidEntity(Beopo))
						{
							if (slot == 2)
							{
								//DealDamage(client, RoundToFloor(Dmg), attacker, DMG_SLASH);
								SDKHooks_TakeDamage(client, Beopo, attacker, TF2_GetMaxHealth(client)*0.02, DMG_SLASH | DMG_PREVENT_PHYSICS_FORCE, Beopo, NULL_VECTOR, NULL_VECTOR, true);
							}
						}
					}
					//if (IsValidClient(attacker) && Plague_active[attacker] == true && IsPlayerAlive(attacker) && IsFakeClient(client))
					//{
						//DealDamage(client, RoundToFloor(405.0), attacker, DMG_SLASH);
					//}
				}
			}
		}
	}
}

public Action:Timer_Plague2(Handle:timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			if (Plague_DOT2active[client] == true && Plague_DOTduration[client] > 0.0)
			{
				for(new attacker = 1; attacker < MaxClients; attacker++)
				{
					//new Float:Dmg = TF2_GetMaxHealth(client)*0.08;
					if (IsValidClient(attacker) && Plague_active[attacker] == true && IsPlayerAlive(attacker))
					{
						new Beopo = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
						new slot = TF2_GetClientActiveSlot(attacker);
						
						if (IsValidEntity(Beopo))
						{
							if (slot == 2)
							{
								//DealDamage(client, RoundToFloor(Dmg), attacker, DMG_SLASH);
								SDKHooks_TakeDamage(client, Beopo, attacker, TF2_GetMaxHealth(client)*0.08, DMG_SLASH | DMG_PREVENT_PHYSICS_FORCE, -1, NULL_VECTOR, NULL_VECTOR, true);
							}
						}
					}
					//if (IsValidClient(attacker) && Plague_active[attacker] == true && IsPlayerAlive(attacker) && IsFakeClient(client))
					//{
						//DealDamage(client, RoundToFloor(415.0), attacker, DMG_SLASH);
					//}
				}
			}
		}
	}
}

public Action:Timer_PlagueAOE(Handle:Timer, any:killer)
{
	if (IsValidClient(killer))
	{
		if (Plague_AOECooldownActive[killer] == true)
		{
			Plague_AOECooldownActive[killer] = false;
		}
	}
}

public Action:Timer_KingBoost(Handle:Timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			if (King_boostactive[client] == true && Plague_DOT1active[client] || Plague_DOT2active[client] == false)
			{
				new Float:Health = TF2_GetMaxHealth(client)*0.50;
				AddPlayerHealth(client, RoundToFloor(Health), 3.0);
				TF2_AddCondition(client, TFCond_InHealRadius, 1.0);
				
				CreateTimer(1.5, Timer_KingBoostClear, client);
			}
		}
	}
}

public Action:Timer_KingBoostClear(Handle:Timer, any:client)
{
	if (IsValidClient(client))
	{
		if (King_boostactive[client] == true)
		{
			King_boostactive[client] = false;
			fl_AdditionalArmorRegen[client] = 0.0;
		}
	}
}


public Action:HealthPool_Reset(Handle:Timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			if (Reflect_active[client] == true && Current_HealthPool[client] > 0.0 && Reflect_InstantHealTriggered[client] == true)
			{
				Current_HealthPool[client] = 0.0;
				Reflect_InstantHealTriggered[client] = false;
			}
		}
	}
}

public Action:Timer_DMGReflect(Handle:Timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			if (Reflect_active[client] == true && Reflect_dmgreflectactive[client] == true)
			{
				Reflect_dmgreflectactive[client] = false;
			}
		}
	}
}

//Other Functions (Mainly for Yagorath)

Yagorath_Switch_Forms(client)
{
	if (FormSwitch_Delay[client] >= GetEngineTime()) return;
	
	FormSwitch_Delay[client] = GetEngineTime()+1.0;
	
	TravelForm_active[client] = !TravelForm_active[client];
	PrintHintText(client, "Travel Form %s.", TravelForm_active[client] ? "enabled" : "disabled");
	
	if (TravelForm_active[client] == true)
	{
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
	else
	{
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
}

Yagorath_FireProjectile(client)
{
	if (PiercingQuils_Delay[client] >= GetEngineTime()) return;
	
	PiercingQuils_Delay[client] = GetEngineTime()+3.0;
	
	decl Float:fAngles[3], Float:fVelocity[3], Float:fOrigin[3], Float:vBuffer[3];
	
	new iEntity = CreateEntityByName("tf_projectile_sentryrocket");
	if (IsValidEdict(iEntity)) 
	{
		new iTeam = GetClientTeam(client);
		SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

		SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
		SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
		
		SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
		
		GetClientEyePosition(client, fOrigin);
		GetClientEyeAngles(client, fAngles);
		
		GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		new Float:Speed = 3500.0;
		
		fVelocity[0] = vBuffer[0]*Speed;
		fVelocity[1] = vBuffer[1]*Speed;
		fVelocity[2] = vBuffer[2]*Speed;
		DispatchSpawn(iEntity);
		TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
	}
}

ThrowFireball(client)
{
	if (Delay[client] >= GetEngineTime()) return;
	
	Delay[client] = GetEngineTime()+0.2;
	
	decl Float:fAngles[3], Float:fVelocity[3], Float:fOrigin[3], Float:vBuffer[3];
	current_charge[client] -= Fireball_cost[client];
	
	new iEntity = CreateEntityByName("tf_projectile_spellfireball");
	if (IsValidEdict(iEntity)) 
	{
		new iTeam = GetClientTeam(client);
		SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

		SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
		SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
		
		SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
		
		GetClientEyePosition(client, fOrigin);
		GetClientEyeAngles(client, fAngles);
		
		GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		new Float:Speed = 3500.0;
		
		fVelocity[0] = vBuffer[0]*Speed;
		fVelocity[1] = vBuffer[1]*Speed;
		fVelocity[2] = vBuffer[2]*Speed;
		DispatchSpawn(iEntity);
		TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
	}
}

ThrowMeteor(client)
{
	if (Delay[client] >= GetEngineTime()) return;
	
	Delay[client] = GetEngineTime()+1.2;
	
	decl Float:fAngles[3], Float:fVelocity[3], Float:fOrigin[3], Float:vBuffer[3];
	current_charge[client] -= MetorShower_cost[client];
	
	new iEntity = CreateEntityByName("tf_projectile_spellmeteorshower");
	if (IsValidEdict(iEntity)) 
	{
		new iTeam = GetClientTeam(client);
		SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

		SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
		SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
		
		SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
		
		GetClientEyePosition(client, fOrigin);
		GetClientEyeAngles(client, fAngles);
		
		GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		new Float:Speed = 2400.0;
		
		fVelocity[0] = vBuffer[0]*Speed;
		fVelocity[1] = vBuffer[1]*Speed;
		fVelocity[2] = vBuffer[2]*Speed;
		DispatchSpawn(iEntity);
		TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
	}
}

ThrowBats(client)
{
	if (Delay[client] >= GetEngineTime()) return;
	
	Delay[client] = GetEngineTime()+0.2;
	
	decl Float:fAngles[3], Float:fVelocity[3], Float:fOrigin[3], Float:vBuffer[3];
	current_charge[client] -= Bats_cost[client];
	
	new iEntity = CreateEntityByName("tf_projectile_spellbats");
	if (IsValidEdict(iEntity)) 
	{
		new iTeam = GetClientTeam(client);
		SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

		SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
		SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
		
		SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
		
		GetClientEyePosition(client, fOrigin);
		GetClientEyeAngles(client, fAngles);
		
		GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		new Float:Speed = 2800.0;
		
		fVelocity[0] = vBuffer[0]*Speed;
		fVelocity[1] = vBuffer[1]*Speed;
		fVelocity[2] = vBuffer[2]*Speed;
		DispatchSpawn(iEntity);
		TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
	}
}
//Melee Fix

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	new Float:MeleeFix = GetConVarFloat(cvar_MeleeFixActive);
	new slot = TF2_GetClientActiveSlot(client);
	new ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if (IsValidEntity(ClientWeapon) && MeleeFix == 1.0)
	{
		if (slot == 2)
		{
			new Address:MeleeAttackRate = TF2Attrib_GetByName(ClientWeapon, "melee attack rate bonus");
			new Address:MeleeRange = TF2Attrib_GetByName(ClientWeapon, "melee range multiplier");
			new Address:MeleeDamagePenalty = TF2Attrib_GetByName(ClientWeapon, "damage penalty");
			new Address:MeleeHealonHit = TF2Attrib_GetByName(ClientWeapon, "heal on hit for rapidfire");
			//new Address:MeleeDmg = TF2Attrib_GetByName(ClientWeapon, "custom texture hi");
			//new Address:MeleeDmgMult = TF2Attrib_GetByName(ClientWeapon, "cannot_transmute");
			//new Address:MeleeDmgMult1 = TF2Attrib_GetByName(ClientWeapon, "always_transmit_so");
			new Address:SetDmgTypeIgnite = TF2Attrib_GetByName(ClientWeapon, "Set DamageType Ignite");
			
			if (MeleeAttackRate!=Address_Null && TF2Attrib_GetValue(MeleeAttackRate) < 0.30 && TF2_GetPlayerClass(client) != TFClass_Spy)
			{
				new Float:Pos5[3];
				Pos5[2] -= 30.0;
				GetClientEyePosition(client, Pos5);
				new Float:Range = 66.0;
				if (MeleeRange!=Address_Null)
				{
					Range *= TF2Attrib_GetValue(MeleeRange);
				}
				new Float:MeleeDamage = 65.0;
				new target = TraceClientViewEntity(client);
				if (target < 1 || target > MaxClients) return;
				if (!IsValidEdict(target)) return;
				
				if (IsValidClient(client) && GetClientTeam(target) != GetClientTeam(client))
				{
					new Float:Pos6[3];
					Pos6[2] -= 30.0;
					GetClientEyePosition(target, Pos6);
					
					new Float:Distance = GetVectorDistance(Pos5, Pos6);
					
					if (Distance <= Range)
					{
						decl String:logname[32];
						GetEdictClassname(ClientWeapon, logname, sizeof(logname));
						new ItemDefinition = GetEntProp(ClientWeapon, Prop_Send, "m_iItemDefinitionIndex");
						
						if (MeleeDamagePenalty != Address_Null)
						{
							MeleeDamage *= TF2Attrib_GetValue(MeleeDamagePenalty);
							if (IsValidEntity(ClientWeapon) && IsValidClient(client))
							{
								//SDKHooks_TakeDamage(target, ClientWeapon, client, MeleeDamage, DmgType, logname, NULL_VECTOR, NULL_VECTOR);
								if (IsCritBoosted(client))
								{
									SDKHooks_TakeDamage(target, ClientWeapon, client, MeleeDamage, DMG_CRIT, ItemDefinition, NULL_VECTOR, NULL_VECTOR, false);
								}
								else
								{
									SDKHooks_TakeDamage(target, ClientWeapon, client, MeleeDamage, DMG_CLUB, ItemDefinition, NULL_VECTOR, NULL_VECTOR, false);
								}
							}
						}
						else
						{
							if (IsValidEntity(ClientWeapon) && IsValidClient(client))
							{
								//SDKHooks_TakeDamage(target, ClientWeapon, client, MeleeDamage, DmgType, ItemDefinition, NULL_VECTOR, NULL_VECTOR);
								if (IsCritBoosted(client))
								{
									SDKHooks_TakeDamage(target, ClientWeapon, client, MeleeDamage, DMG_CRIT, ItemDefinition, NULL_VECTOR, NULL_VECTOR, false);
								}
								else
								{
									SDKHooks_TakeDamage(target, ClientWeapon, client, MeleeDamage, DMG_CLUB, ItemDefinition, NULL_VECTOR, NULL_VECTOR, false);
								}
							}
						}
						if (MeleeHealonHit != Address_Null)
						{
							new Float:Regen10 = TF2Attrib_GetValue(MeleeHealonHit);
							AddPlayerHealth(client, RoundToFloor(Regen10), 1.0);
							ShowHealthGain(client, RoundToFloor(Regen10), client);
						}
						if (SetDmgTypeIgnite != Address_Null)
						{
							TF2_IgnitePlayer(target, client, 5.0);
						}
					}
				}
			}
		}
	}
	if (Fireball_active[client] == true && current_charge[client] > Fireball_cost[client])
	{
		ThrowFireball(client);
	}
	if (Bats_active[client] == true && current_charge[client] > Bats_cost[client])
	{
		ThrowBats(client);
	}
	if (MeteorShower_active[client] == true && current_charge[client] > MetorShower_cost[client])
	{
		ThrowMeteor(client);
	}
}