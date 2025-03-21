

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <events>


public OnEntityCreated(int entity, const char[] classname)
{
	new String:classname[128]; 
	GetEdictClassname(inflictor, classname, sizeof(classname));
	for ( new i = 1; i <= MaxClients; i++ )
	{
		int entity = (!strcmp("item_currencypack_custom") || !(strcmp("item_currencypack_large"))
		{
			new Float: TargetPos[3];
			new Float: EntityPos[3];
			GetClientAbsOrigin (i, TargetPos);
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", EntityPos);
			new Float: distance = GetVectorDistance(EntityPos, TargetPos);

			if (distance > 0)

			 TeleportEntity( entity, i, NULL_VECTOR, 1000.0 )
		}
	}
}