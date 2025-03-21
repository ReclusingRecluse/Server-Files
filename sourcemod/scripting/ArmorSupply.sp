#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client)
{
    if(IsClientInGame(client))
    {
        SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	new Primary = GetPlayerWeaponSlot(attacker,0);
	new Secondary = GetPlayerWeaponSlot(attacker,1);
	new Melee = GetPlayerWeaponSlot(attacker,2);
	
	if (IsValidEntity(Primary))
	{
		new Address:AddDamage = TF2Attrib_GetByName(Primary, "energy weapon no deflect");
		if (AddDamage != Address_Null)
		{
			damage += TF2Attrib_GetValue(AddDamage);
		}
	}
	if (IsValidEntity(Secondary))
	{
		new Address:AddDamage2 = TF2Attrib_GetByName(Secondary, "energy weapon no deflect");
		if (AddDamage2 != Address_Null)
		{
			damage += TF2Attrib_GetValue(AddDamage2);
		}
	}
	if (IsValidEntity(Melee))
	{
		new Address:AddDamage3 = TF2Attrib_GetByName(Melee, "energy weapon no deflect");
		if (AddDamage3 != Address_Null)
		{
			damage += TF2Attrib_GetValue(AddDamage3);
		}
	}
	return Plugin_Changed;
}