#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>

#define VERSION "1.11"

public Plugin:myinfo = {
	name = "Multiple Rocket",
	author = "[E]c",
	description = "Allows soldier to shoot multiple projectile.",
	version = VERSION,
	url = ""
};

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	new BaseWep3 = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	new Address:ArrowShoot = TF2Attrib_GetByName(BaseWep3, "item slot criteria 2");
	if (ArrowShoot!=Address_Null)
	{
		new Float:vAngles[3]; // pass
		new Float:vAngles2[3]; // original
		new Float:vPosition[3]; // pass
		new Float:vPosition2[3]; // original
		new Float:Amount = TF2Attrib_GetValue(ArrowShoot);
		new ClientTeam = GetClientTeam(client);
		new Float:Random = 1.0;
	
		GetClientEyeAngles(client, vAngles2);
		GetClientEyePosition(client, vPosition2);
				
		vPosition[0] = vPosition2[0];
		vPosition[1] = vPosition2[1];
		vPosition[2] = vPosition2[2];

		new Float:Random2 = Random*-1;
		new counter = 0;
		for (new i = 0; i < Amount; i++)
		{
			vAngles[0] = vAngles2[0] + GetRandomFloat(Random2,Random);
			vAngles[1] = vAngles2[1] + GetRandomFloat(Random2,Random);
			// avoid unwanted collision
			new i2 = i%4;
			switch(i2)
			{
				case 0:
				{
					counter++;
					vPosition[0] = vPosition2[0] + counter;
				}
				case 1:
				{	
					vPosition[1] = vPosition2[1] + counter;
				}
				case 2:
				{
					vPosition[0] = vPosition2[0] - counter;
				}
				case 3:
				{
					vPosition[1] = vPosition2[1] - counter;
				}
			}
			fireProjectile(vPosition, vAngles, 3000.0, 10.0, ClientTeam, client);
		}
	}
	return Plugin_Continue;
}

fireProjectile(Float:vPosition[3], Float:vAngles[3] = NULL_VECTOR, Float:flSpeed = 1100.0, Float:flDamage = 90.0, iTeam, client)
{
	new String:strClassname[32] = "";
	new String:strEntname[32] = "";

	strClassname = "CTFProjectile_Arrow";
	strEntname = "tf_projectile_arrow";

	new iRocket = CreateEntityByName(strEntname);
	
	if(!IsValidEntity(iRocket))
		return -1;
	
	decl Float:vVelocity[3];
	decl Float:vBuffer[3];
	
	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
	
	vVelocity[0] = vBuffer[0]*flSpeed;
	vVelocity[1] = vBuffer[1]*flSpeed;
	vVelocity[2] = vBuffer[2]*flSpeed;
	
	SetEntPropEnt(iRocket, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(iRocket,    Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= 5)? 1 : 0, 1);
	SetEntProp(iRocket,    Prop_Send, "m_iTeamNum",     iTeam, 1);
	SetEntData(iRocket, FindSendPropOffs(strClassname, "m_nSkin"), (iTeam-2), 1, true);

	SetEntDataFloat(iRocket, FindSendPropOffs(strClassname, "m_iDeflected") + 4, flDamage, true); // set damage
	TeleportEntity(iRocket, vPosition, vAngles, vVelocity);

	SetVariantInt(iTeam);
	AcceptEntityInput(iRocket, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(iRocket, "SetTeam", -1, -1, 0); 
	
	DispatchSpawn(iRocket);
	
	return iRocket;
}