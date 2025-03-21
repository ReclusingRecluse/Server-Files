#include <sdkhooks>
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

//ConVar g_botlevel;

//ConVar g_moneymult;

//int BotLevel;

//int CurrentBotLevel;
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
	HookEvent("mvm_wave_failed", Event_mvm_wave_failed);
	HookEvent("mvm_reset_stats", Event_ResetStats);
}

public OnMapStart()
{
	CreateTimer(0.1, Timer_Tags, _, TIMER_REPEAT);
	if (!IsMvM())
	{
		ServerCommand("sm plugins unload champions");
	}
	if (IsMvM())
	{
		//SetMVMParams();
	}
}
public Action:Timer_Tags(Handle:Timer)
{
	new String:buffer[128];
	GetConVarString(FindConVar("sv_tags"), buffer, sizeof(buffer));
	
	if (StrContains(buffer, "uber,upgrades,custom-weapons", true) == -1)
	{
		SetConVarString(FindConVar("sv_tags"), "uber,upgrades,custom-weapons", true, false);
		KillTimer(Timer);
	}
}


public Event_mvm_wave_failed(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetMVMParams();
}


public Event_ResetStats(Handle:event, const String:name[], bool:dontBroadcast)
{
	char responseBuffer[4096];
	int ObjResc = FindEntityByClassname(-1, "tf_objective_resource");
	GetEntPropString(ObjResc, Prop_Send, "m_iszMvMPopfileName", responseBuffer, sizeof(responseBuffer));
	
	/*
	if (StrContains(responseBuffer, "InfiniteMoney", true) != -1)
	{
		ServerCommand("sm_uu_moneystart 750000");
		//ServerCommand("sm_setcash @all 750000");
	}
	*/
	if (StrContains(responseBuffer, "Normal", true) != -1)
	{
		ServerCommand("sm_uu_moneystart 60000");
		//ServerCommand("sm_setcash @all 60000");
	}
	else if (StrContains(responseBuffer, "Hard", true) != -1)
	{
		ServerCommand("sm_uu_moneystart 80000");
		//ServerCommand("sm_setcash @all 80000");
	}
	else if (StrContains(responseBuffer, "Extreme", true) != -1)
	{
		ServerCommand("sm_uu_moneystart 100000");
		//ServerCommand("sm_setcash @all 100000");
	}
	else if (StrContains(responseBuffer, "Nightmare", true) != -1)
	{
		ServerCommand("sm_uu_moneystart 250000");
		//ServerCommand("sm_setcash @all 250000");
	}
	else if (StrContains(responseBuffer, "Armageddon", true) != -1)
	{
		ServerCommand("sm_uu_moneystart 500000");
		//ServerCommand("sm_setcash @all 500000");
	}
	else if (StrContains(responseBuffer, "InfiniteMoney", true) != -1)
	{
		ServerCommand("sm_uu_moneystart 1000000");
		//ServerCommand("sm_setcash @all 1000000");
	}
	else
	{
		ServerCommand("sm_uu_moneystart 60000");
		//ServerCommand("sm_setcash @all 60000");
	}
}


stock SetMVMParams()
{
	char responseBuffer[4096];
	int ObjResc = FindEntityByClassname(-1, "tf_objective_resource");
	GetEntPropString(ObjResc, Prop_Send, "m_iszMvMPopfileName", responseBuffer, sizeof(responseBuffer));
	ServerCommand("sm_tfrebalance_refresh");
	ServerCommand("sm plugins unload customvotes");
	ServerCommand("sm plugins unload botnames");
	ServerCommand("sm plugins unload tf_bots_on_plr");
	ServerCommand("sm plugins unload tf_bot_melee_enabler");
	ServerCommand("sm plugins unload ClassRestrictionsForBots");
	ServerCommand("tf_bot_quota 0");
	ServerCommand("sm_kick @bots");
	ServerCommand("sm_cw3_bots 0");
	ServerCommand("mp_timelimit 0");

	if (IsValidEntity(ObjResc))
	{
		if (StrContains(responseBuffer, "Normal", true) != -1)
		{
			SetConVarFloat(FindConVar("sm_uu_mvm_money_mult"), 0.7, true, false); //Multiply Money Given by Bots
			SetConVarFloat(FindConVar("sm_uu_bot_scaling"), 1.0, true, false); //Multiply Money Given by Bots
			PrintToChatAll("Parameters for Normal difficulty have been set.");
			//PrintToChatAll("PopFile: %s", ObjResc);
			ServerCommand("sm_uu_moneystart 60000");
		}
		else if (StrContains(responseBuffer, "Intermediate", true) != -1)
		{
			SetConVarFloat(FindConVar("sm_uu_mvm_money_mult"), 1.3, true, false); //Multiply Money Given by Bots
			SetConVarFloat(FindConVar("sm_uu_bot_scaling"), 1.0, true, false); //Multiply Money Given by Bots
			PrintToChatAll("Parameters for Intermediate difficulty have been set.");
			ServerCommand("sm_uu_moneystart 60000");
		}
		else if (StrContains(responseBuffer, "Hard", true) != -1)
		{
			SetConVarFloat(FindConVar("sm_uu_mvm_money_mult"), 2.0, true, false); //Multiply Money Given by Bots
			SetConVarFloat(FindConVar("sm_uu_bot_scaling"), 2.0, true, false); //Multiply Money Given by Bots
			PrintToChatAll("Parameters for Hard difficulty have been set.");
			ServerCommand("sm_uu_moneystart 80000");
		}
		else if (StrContains(responseBuffer, "Extreme", true) != -1)
		{
			SetConVarFloat(FindConVar("sm_uu_mvm_money_mult"), 6.0, true, false); //Multiply Money Given by Bots
			SetConVarFloat(FindConVar("sm_uu_bot_scaling"), 5.0, true, false); //Multiply Money Given by Bots
			PrintToChatAll("Parameters for Extreme difficulty have been set.");
			ServerCommand("sm_uu_moneystart 100000");
		}
		else if (StrContains(responseBuffer, "Nightmare", true) != -1)
		{
			SetConVarFloat(FindConVar("sm_uu_mvm_money_mult"), 10.0, true, false); //Multiply Money Given by Bots
			SetConVarFloat(FindConVar("sm_uu_bot_scaling"), 8.0, true, false); //Multiply Money Given by Bots
			PrintToChatAll("Parameters for Nightmare difficulty have been set.");
			ServerCommand("sm_uu_moneystart 250000");
		}
		else if (StrContains(responseBuffer, "Armageddon", true) != -1)
		{
			SetConVarFloat(FindConVar("sm_uu_mvm_money_mult"), 15.0, true, false); //Multiply Money Given by Bots
			SetConVarFloat(FindConVar("sm_uu_bot_scaling"), 12.0, true, false); //Multiply Money Given by Bots
			PrintToChatAll("Parameters for Armageddon difficulty have been set.");
			ServerCommand("sm_uu_moneystart 500000");
		}
		else if (StrContains(responseBuffer, "InfiniteMoney", true) != -1)
		{
			SetConVarFloat(FindConVar("sm_uu_mvm_money_mult"), 50.0, true, false); //Multiply Money Given by Bots
			SetConVarFloat(FindConVar("sm_uu_bot_scaling"), 30.0, true, false); //Multiply Money Given by Bots
			PrintToChatAll("Parameters for Infinite Money have been set.");
			ServerCommand("sm_uu_moneystart 1000000");
		}
		else if (StrContains(responseBuffer, "666", true) != -1)
		{
			ServerCommand("sm_uu_moneystart 100000");
			SetConVarFloat(FindConVar("sm_uu_mvm_money_mult"), 3.0, true, false); //Multiply Money Given by Bots
			SetConVarFloat(FindConVar("sm_uu_bot_scaling"), 2.0, true, false); //Multiply Money Given by Bots
			PrintToChatAll("Parameters for Wave 666 have been set.");
		}
		else
		{
			SetConVarFloat(FindConVar("sm_uu_mvm_money_mult"), 0.3, true, false); //Multiply Money Given by Bots
			SetConVarFloat(FindConVar("sm_uu_bot_scaling"), 1.0, true, false); //Multiply Money Given by Bots
			PrintToChatAll("Parameters for Base MVM(Lame) have been set.");
			//PrintToChatAll("PopFile: %s", ObjResc);
			ServerCommand("sm_uu_moneystart 60000");
		}
	}
}