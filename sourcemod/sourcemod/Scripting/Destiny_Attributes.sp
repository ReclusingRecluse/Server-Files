#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <events>
#include <tf_econ_dynamic>
#include <custom_status_hud_Weapons>


bool:Crowd_Control_Active[MAXPLAYERS+1] = {false, ...};
Float:Crowd_Control_Duration[MAXPLAYERS+1] = {0.0, ...};

bool:Rampage_Active[MAXPLAYERS+1] = {false, ...};
Float:Rampage_Duration[MAXPLAYERS+1] = {0.0, ...};
int Rampage_Stacks[MAXPLAYERS+1] = {0, ...};

bool:RapidHit_Active[MAXPLAYERS+1] = {false, ...};
int RapidHit_Stacks[MAXPLAYERS+1] = {0, ...};
Float:RapidHit_Duration[MAXPLAYERS+1] = {0.0, ...};

bool:Feeding_Frenzy_Active[MAXPLAYERS+1] = {false, ...};
Float:Feeding_Frenzy_Duration[MAXPLAYERS+1] = {0.0, ...};
int Feeding_Frenzy_Stacks[MAXPLAYERS+1] = {0, ...};

bool:Outlaw_Active[MAXPLAYERS+1] = {false, ...};
Float:Outlaw_Duration[MAXPLAYERS+1] = {false, ...};

bool:Chaperone_Bonus[MAXPLAYERS+1] = {false, ...};
Float:Chaperone_Duration[MAXPLAYERS+1] = {0.0, ...};

bool:Duality_Bonus[MAXPLAYERS+1] = {false, ...};
Float:Duality_Duration[MAXPLAYERS+1] = {0.0, ...};


public Action:OnCustomStatusHUDUpdate3(int client, StringMap entries) 
{
	if (IsValidClient(client))
	{
		char Rampage[32];
		char Outlaw[32];
		char CrowdCon[32];
		char FeedingFren[32];
		char RoadBorn[32];
		
		new clientweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(clientweapon))
		{
			if(WepAttribCheck(clientweapon, "never craftable"))
			{
				if (Rampage_Active[client])
				{
					Format(Rampage, sizeof(Rampage), "Rampage x%i", Rampage_Stacks[client]);
					entries.SetString("destiny_rampage", Rampage);
				}
				
			}
			if (WepAttribCheck(clientweapon, "item in slot 1")
			{
				if (Outlaw_Active[client])
				{
					Format(Outlaw, sizeof(Outlaw), "Outlaw");
					entries.SetString("destiny_outlaw", Outlaw);
				}
			}
			if(WepAttribCheck(clientweapon, "obsolete ammo penalty"))
			{
				if (Crowd_Control_Active[client])
				{
					Format(CrowdCon, sizeof(CrowdCon), "Crowd Control");
					entries.SetString("destiny_crowd_control", CrowdCon);
				}
			}
			if (WepAttribCheck(clientweapon, "kill eater 3"))
			{
				if (Feeding_Frenzy_Active[client])
				{
					Format(FeedingFren, sizeof(FeedingFren), "Feeding Frenzy x%i", Feeding_Frenzy_Stacks[client]);
					entries.SetString("destiny_feeding_frenzy", FeedingFren);
				}
			}
			if(WepAttribCheck(clientweapon, "is commodity"))
			{
				if (Chaperone_Bonus[client])
				{
					Format(RoadBorn, sizeof(RoadBorn), "Roadborn");
					entries.SetString("destiny_chaperone_roadborn", RoadBorn);
				}
			}
		}
	}
	return Plugin_Changed;
}


public OnPluginStart()
{
	HookEvent("player_death", Event_Death, EventHookMode_Pre);
	for(new client=0; client<=MaxClients; client++)
	{
		if (!IsValidClient(client)){continue;}
		SDKHook(client, SDKHook_TraceAttack, TraceAttack);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_TraceAttack, TraceAttack);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
public OnClientDisconnect(client)
{
    if(IsClientInGame(client))
    {
        SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

public OnGameFrame()
{
	for ( new client = 1; client <= MaxClients; client++ )
	{
		if (IsValidClient(client))
		{
			new clientweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			
			if (IsValidEntity(clientweapon))
			{
				
				if(WepAttribCheck(clientweapon, "obsolete ammo penalty"))
				{
					if (Crowd_Control_Active[client])
					{
						if (Crowd_Control_Duration[client] <= GetEngineTime()){return;}
						Crowd_Control_Active[client] = false
					}
				}
				
				if(WepAttribCheck(clientweapon, "never craftable"))
				{
					if (Rampage_Active[client])
					{
						if (Rampage_Duration[client] <= GetEngineTime()){return;}
						Rampage_Active[client] = false;
						Rampage_Stacks[client] = 1;
					}
				}
				
				if (WepAttribCheck(clientweapon, "item in slot 1")
				{
					if (Outlaw_Active[client])
					{
						if (Outlaw_Duration[client] <= GetEngineTime()){return;}
						Outlaw_Active[client] = false;
					}
				}
				
				if (WepAttribCheck(clientweapon, "kill eater 3"))
				{
					if (Feeding_Frenzy_Active[client])
					{
						if (Feeding_Frenzy_Duration[client] <= GetEngineTime()){return;}
						Feeding_Frenzy_Active[client] = false;
						Feeding_Frenzy_Stacks[client] = 1;
					}
				}
					
				if(WepAttribCheck(clientweapon, "is commodity"))
				{
					if (Chaperone_Bonus[client])
					{
						if (Chaperone_Duration[client] <= GetEngineTime()){return;}
						Chaperone_Bonus[client] = false;
					}
				}
				
				if (WepAttribCheck(clientweapon, "bot custom jump particle"))
				{
					if (Duality_Bonus[client])
					{
						if (Duality_Duration[client] <= GetEngineTime()){return;}
						Duality_Bonus[client] = false;
					}
				}
			}
		}
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
	else{return 0.0;}
}
