#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <sdkhooks>
#include <dhooks>

#define Sound_Shot		"custom/Yagorath/yagorath_fire1.flac"


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

new LastButtons[MAXPLAYERS+1] = -1;

new Float:FormSwitch_Delay[MAXPLAYERS+1] = 0.2;

int ButtonPressedTimer[MAXPLAYERS+1] = 0.0;
public OnPluginStart()
{
	//HookEvent("player_hurt", Event_Playerhurt);
	for(new i=0; i<=MaxClients; i++)
	{
		if(!IsValidClient(i)){continue;}
		SDKHook(i, SDKHook_PreThink, OnClientPreThink);
	}
}

public OnPluginEnd()
{
	//UnhookEvent("player_hurt", Event_Playerhurt);
	for(new i=0; i<=MaxClients; i++)
	{
		if(!IsValidClient(i)){continue;}
		SDKUnhook(i, SDKHook_PreThink, OnClientPreThink);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
}



public OnClientPreThink(client) OnPreThink(client);
public OnPreThink(client)
{
	new ButtonsLast = LastButtons[client];
	new Buttons = GetClientButtons(client);
	new Buttons2 = Buttons;
	
	Buttons = FormSwitch(client, Buttons, ButtonsLast);
	//Buttons = MainAttack(client, Buttons, ButtonsLast);
	
	if (Buttons != Buttons2) SetEntProp(client, Prop_Data, "m_nButtons", Buttons);	
	LastButtons[client] = Buttons;
}

FormSwitch(client, &Buttons, &ButtonsLast)
{
	if (Yagorath_active[client] == true)
	{
		if ((Buttons & IN_RELOAD == IN_RELOAD))
        {
			Yagorath_Switch_Forms(client);
			PrintToChat(client, "Delay %.0f", FormSwitch_Delay[client]);
		}
	}
	return Buttons;
}

Yagorath_Switch_Forms(client)
{
	if (FormSwitch_Delay[client] >= GetEngineTime()) return;
	
	FormSwitch_Delay[client] = GetEngineTime();
	
	TravelForm_active[client] = !TravelForm_active[client];
	PrintHintText(client, "Travel Form %s.", TravelForm_active[client] ? "enabled" : "disabled");
}