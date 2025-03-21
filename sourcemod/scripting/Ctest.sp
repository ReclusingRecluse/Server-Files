#include <sourcemod>
#include <sdktools>
#include <sdkhooks>



stock bool IsValidClient( client, bool replaycheck = true )
{
    if ( client <= 0 || client > MaxClients ) return false; 
    if ( !IsClientInGame( client ) ) return false; 
    if ( !IsPlayerAlive( client ) ) return false; 
    return true; 
}

public void OnEntityCreated(int entity, const char[] classname)
{
	int ent = -1;
	while((ent = FindEntityByClassname(ent, "tf_projectile_rocket")) != -1) 
	{
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if(IsValidClient(i) && !IsFakeClient(i))
			{
				new Float:Pos1[3]
				Pos1[2] -= 30.0;
				GetEntPropVector(ent, Prop_Send, "m_vecVelocity", Pos1);
				
				if (IsValidEntity(ent))
				{
					PrintToChat(i, "Veloctiy: %.0f", Pos1);
				}
			}
		}
	}
}