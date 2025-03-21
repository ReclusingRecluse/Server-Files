#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf_econ_dynamic>
#include <tf2attributes>

// This is a modification of AutoAim by Deathreus. Made to be controlled via weapon attributes instead of cvars and made to be less powerful and more of a typical aim assist system. Replicates how Destiny 2's aim assist works by having a range stat that affects the strength of aim assist.

stock bool IsValidClient( client, bool replaycheck = true )
{
    if ( client <= 0 || client > MaxClients ) return false; 
    if ( !IsClientInGame( client ) ) return false; 
    if ( !IsPlayerAlive( client ) ) return false; 
    return true; 
}

new ClientEyes[MAXPLAYERS+1];
new ActiveWeapon[MAXPLAYERS+1];
new Handle:g_hLookupBone, Handle:g_hGetBonePosition;
new g_iPlayerDesiredFOV[MAXPLAYERS+1];
new Float:g_flCvarSmoothAmount;
new Float:g_flGravity;

new bool:g_bToHead[MAXPLAYERS+1] = {false, ...};
bool:g_bAimFoV[MAXPLAYERS+1] = {false, ...};
new Float:FOISpeed[MAXPLAYERS+1] = {0.0, ...};

new Float:AimAssistTotalMult[MAXPLAYERS+1] = {1.0, ...};

public OnPluginStart()
{
	TF2EconDynAttribute attrib = new TF2EconDynAttribute();
	
	attrib.SetName("aim assist");
	attrib.SetClass("weapons_aim_assist");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("effective range");
	attrib.SetClass("weapons_effective_range");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("prioritize hit group");
	attrib.SetClass("weapons_prioritize_hit_group");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("aim assist multiplier");
	attrib.SetClass("weapons_aim_assist_multiplier");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.Register();
	
	/*
	for(new client=0; client<=MaxClients; client++)	if (IsValidClient(client))
		OnClientPutInServer(client);
		
	SDKHook(client, SDKHook_PreThink, OnPreThink);
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
	*/
	
	new Handle:hGameConf = LoadGameConfigFile("aimbot.games");
	if (hGameConf == INVALID_HANDLE) SetFailState("Could not locate gamedata file aimbot.games.txt, pausing plugin");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CBaseAnimating::LookupBone");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	if(!(g_hLookupBone=EndPrepSDKCall())) SetFailState("Could not initialize SDK call CBaseAnimating::LookupBone");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CBaseAnimating::GetBonePosition");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	if(!(g_hGetBonePosition=EndPrepSDKCall())) SetFailState("Could not initialize SDK call CBaseAnimating::GetBonePosition");
	
	HookEvent("player_spawn", Event_Spawn);
	HookEvent("post_inventory_application", Event_Inventory);
	
}

public OnClientPutInServer(iClient)
{
	g_iPlayerDesiredFOV[iClient] = 90;
	
	SDKHook(iClient, SDKHook_PreThink, OnPreThink);
	SDKHook(iClient, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
	
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

bool:ShouldAimToHead(iClient, iWeapon)
{
	// Check if a weapon has an attribute that allows it to deal crits on headshots
		
	if (IsValidEntity(iWeapon))
		{
			if (WepAttribCheck(iWeapon, "cannot delete"))
			{
				return true;
			}
			else
				return false;
		}
	}
	
	else
		return false;
}

public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:vVelocity[3], Float:vAngle[3], &iWeapon)
{
	new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	decl String:sWeapon[64];
	GetClientWeapon(iClient, sWeapon, sizeof(sWeapon));

	new clientweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	g_bToHead[iClient] = ShouldAimToHead(iClass, sWeapon, ActiveWeapon[iClient]);
	
	

	if(WepAttribCheck(clientweapon, "aim assist"))
	{
		new mButton;

		switch(g_iCvarAimKey)
		{
			case 1: mButton = IN_ATTACK2; // Secondary Attack
			case 2: mButton = IN_ATTACK3; // Special Attack
			case 3: mButton = IN_RELOAD;
			case 4: mButton = IN_ATTACK;
		}

		if(iButtons & mButton)
		{
			AimTick(iClient, iButtons, vAngle, vVelocity);
		}
	}
	else
	{
		AimTick(iClient, iButtons, vAngle, vVelocity);
	}

	return Plugin_Changed;
}




public AimTick(iClient, &iButtons, Float:vAngle[3], Float:vVelocity[3])
{
	static Float:flNextTargetTime[MAXPLAYERS+1];
	static iTarget[MAXPLAYERS+1];
	static iBone[MAXPLAYERS+1];
	
	decl Float:vClientEyes[3], Float:vCamAngle[3], 
	Float:vTargetEyes[3], Float:vTargetVel[3];
	
	GetClientEyePosition(iClient, vClientEyes);
	
	new iTeam = GetClientTeam(iClient);
	
	// Thanks Mitchell for this awesome code
	if(flNextTargetTime[iClient] <= GetEngineTime())
	{
		iTarget[iClient] = GetClosestClient(iClient);
		flNextTargetTime[iClient] = GetEngineTime() + 5.0;
	}
	if(!IsValidClient(iTarget[iClient]) || !IsPlayerAlive(iTarget[iClient]))
	{
		iTarget[iClient] = GetClosestClient(iClient);
		flNextTargetTime[iClient] = GetEngineTime() + 5.0;
		return;
	}
	else
	{
		GetClientEyePosition(iTarget[iClient], vTargetEyes);
		if(!CanSeeTarget(iClient, iTarget[iClient],	iTeam, g_bAimFoV[iClient]))
		{
			iTarget[iClient] = GetClosestClient(iClient);
			flNextTargetTime[iClient] = GetEngineTime() + 5.0;
			return;
		}
	}

	//GetClientEyePosition(iTarget[iClient], vTargetEyes);
	//vTargetEyes[0] += 1.5;
	GetEntPropVector(iTarget[iClient], Prop_Data, "m_vecAbsVelocity", vTargetVel);

	decl Float:vBoneAngle[3];
	iBone[iTarget[iClient]] = SDKCall(g_hLookupBone, iTarget[iClient], (g_bToHead[iClient]) ? "bip_head" : "bip_pelvis");
	SDKCall(g_hGetBonePosition, iTarget[iClient], iBone[iTarget[iClient]], vTargetEyes, vBoneAngle);
	
	FirstOrderIntercept(vClientEyes, Float:{0.0, 0.0, 0.0}, FOISpeed[iClient], vTargetEyes, vTargetVel, iTarget[iClient]);
	InterpolateVector(iClient, vTargetVel, vTargetEyes);
	
	switch(ActiveWeapon[iClient])
	{	// Calculate the dropoff
		case 39, 56, 351, 595, 740, 1005, 1081, 1092, 19, 206, 308, 
		996, 1007, 1151, 15077, 15079, 15091, 15092, 15116, 15117, 15142, 15158:
		{
			if(GetVectorDistance(vClientEyes, vTargetEyes) > 512.0)
				vTargetEyes[2] += GetGrenadeZ(vClientEyes, vTargetEyes, FOISpeed[iClient]);
		}
	}
	
	GetVectorAnglesTwoPoints(vClientEyes, vTargetEyes, vCamAngle);
	AnglesNormalize(vCamAngle);
	
	if(g_bSmoothAim[iClient])
	{
		vCamAngle[0] = ChangeAngle(iClient, vCamAngle[0], vAngle[0]);
		vCamAngle[1] = ChangeAngle(iClient, vCamAngle[1], vAngle[1]);
		AnglesNormalize(vCamAngle);
	}
	
	if(!g_bSilentAim[iClient])
	{
		TeleportEntity(iClient, NULL_VECTOR, vCamAngle, NULL_VECTOR);
		CopyVector(vCamAngle, vAngle);
	}
	else
	{
		decl Float:vMoveAng[3];
		GetVectorAngles(vVelocity, vMoveAng);
		
		new Float:flYaw = DegToRad(vCamAngle[1] - vAngle[1] + vMoveAng[1]);
		new Float:flSpeed = SquareRoot((vVelocity[0] * vVelocity[0]) + (vVelocity[1] * vVelocity[1]));
		vVelocity[0] = Cosine(flYaw) * flSpeed;
		vVelocity[1] = Sine(flYaw) * flSpeed;
		
		CopyVector(vCamAngle, vAngle);
	}
	
	if(g_bAimAndShoot[iClient] && IsLooking(iClient, iTarget[iClient])) // If the player is looking at the target
		iButtons |= IN_ATTACK;
}

stock GetClosestClient(iClient)
{
	decl Float:vPos1[3], Float:vPos2[3];
	GetClientEyePosition(iClient, vPos1);

	new iTeam = GetClientTeam(iClient);
	new iClosestEntity = -1;
	new Float:flClosestDistance = -1.0;
	new Float:flEntityDistance;

	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		if(GetClientTeam(i) != iTeam && IsPlayerAlive(i) && i != iClient)
		{
			GetClientEyePosition(i, vPos2);
			flEntityDistance = GetVectorDistance(vPos1, vPos2);
			if((flEntityDistance < flClosestDistance) || flClosestDistance == -1.0)
			{
				if(CanSeeTarget(iClient, i, iTeam, g_bAimFoV[iClient]))
				{
					flClosestDistance = flEntityDistance;
					iClosestEntity = i;
				}
			}
		}
	}
	return iClosestEntity;
}

stock bool:IsValidClient(iClient, bool:bAlive = false)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;

	if(IsClientSourceTV(iClient) || IsClientReplay(iClient))
		return false;
	
	if(bAlive && !IsPlayerAlive(iClient))
		return false;

	return true;
}

public CopyVector(float vIn[3], float vOut[3])
{
	vOut[0] = vIn[0];
	vOut[1] = vIn[1];
	vOut[2] = vIn[2];
}

bool CanSeeTarget(iClient, iTarget, iTeam, bool:bCheckFOV)
{
	decl Float:flStart[3], Float:flEnd[3];
	GetClientEyePosition(iClient, flStart);
	GetClientEyePosition(iTarget, flEnd);
	
	TR_TraceRayFilter(flStart, flEnd, MASK_SOLID, RayType_EndPoint, TraceRayFilterClients, iTarget);
	if(TR_GetEntityIndex() == iTarget)
	{
		if(TF2_GetPlayerClass(iTarget) == TFClass_Spy)
		{
			if(TF2_IsPlayerInCondition(iTarget, TFCond_Cloaked) || TF2_IsPlayerInCondition(iTarget, TFCond_Disguised))
			{
				if(TF2_IsPlayerInCondition(iTarget, TFCond_CloakFlicker)
				|| TF2_IsPlayerInCondition(iTarget, TFCond_OnFire)
				|| TF2_IsPlayerInCondition(iTarget, TFCond_Jarated)
				|| TF2_IsPlayerInCondition(iTarget, TFCond_Milked)
				|| TF2_IsPlayerInCondition(iTarget, TFCond_Bleeding))
				{
					return true;
				}

				return false;
			}
			if(TF2_IsPlayerInCondition(iTarget, TFCond_Disguised) && GetEntProp(iTarget, Prop_Send, "m_nDisguiseTeam") == iTeam)
			{
				return false;
			}

			return true;
		}
		
		if(TF2_IsPlayerInCondition(iTarget, TFCond_Ubercharged)
		|| TF2_IsPlayerInCondition(iTarget, TFCond_UberchargedHidden)
		|| TF2_IsPlayerInCondition(iTarget, TFCond_UberchargedCanteen)
		|| TF2_IsPlayerInCondition(iTarget, TFCond_UberchargedOnTakeDamage)
		|| TF2_IsPlayerInCondition(iTarget, TFCond_PreventDeath)
		|| TF2_IsPlayerInCondition(iTarget, TFCond_Bonked))
		{
			return false;
		}
		
		if(bCheckFOV)
		{
			decl Float:eyeAng[3], Float:reqVisibleAng[3];
			new Float:flFOV = float(g_iPlayerDesiredFOV[iClient]);
			
			GetClientEyeAngles(iClient, eyeAng);
			
			SubtractVectors(flEnd, flStart, reqVisibleAng);
			GetVectorAngles(reqVisibleAng, reqVisibleAng);
			
			new Float:flDiff = FloatAbs(reqVisibleAng[0] - eyeAng[0]) + FloatAbs(reqVisibleAng[1] - eyeAng[1]);
			if (flDiff > ((flFOV * 0.5) + 10.0)) 
				return false;
		}

		return true;
	}

	return false;
}

bool:IsLooking(iClient, iTarget)
{
	if(GetClientAimTarget(iClient, true) == iTarget)
		return true;
	
	return false;
}

public bool:TraceRayFilterClients(iEntity, iMask, any:hData)
{
	if(iEntity > 0 && iEntity <=MaxClients)
	{
		if(iEntity == hData)
		{
			return true;
		}
		else
		{
			return false;
		}
	}

	return true;
}


UpdateFirstOrderIntercept(iClient)
{
	switch(ActiveWeapon[iClient])
	{
		case 812,833,44,648,595: FOISpeed[iClient] = 3000.0;
		case 49,351,740,1081: FOISpeed[iClient] = 2000.0;
		case 442,588: FOISpeed[iClient] = 1200.0;
		case 997,305,1079: FOISpeed[iClient] = 2400.0;
		case 414: FOISpeed[iClient] = 1540.0;
		case 127: FOISpeed[iClient] = 1980.0;
		case 222,1121,58,1083,1105: FOISpeed[iClient] = 925.0;
		case 996: FOISpeed[iClient] = 1811.0;
		case 56,1005,1092: FOISpeed[iClient] = 1800.0;
		case 308: FOISpeed[iClient] = 1510.0;
		case 19,206,1007,1151: FOISpeed[iClient] = 1215.0;
		case 18,205,228,441,513,658,730,800,809,889,898,907,916,965,974,1085,1104,15006,15014,15028,15043,15052,15057: FOISpeed[iClient] = 1100.0;
		case 17,204,36,412,20,207,130,661,797,806,886,895,904,913,962,971,1150,15009,15012,15024,15038,15045,15048: FOISpeed[iClient] = 1000.0;
		default: FOISpeed[iClient] = 1000000.0;		// Arbitrary value for hitscan
	}
}

// sarysa plz
stock Float:GetVectorAnglesTwoPoints(const Float:vStartPos[3], const Float:vEndPos[3], Float:vAngles[3])
{
	static Float:tmpVec[3];
	tmpVec[0] = vEndPos[0] - vStartPos[0];
	tmpVec[1] = vEndPos[1] - vStartPos[1];
	tmpVec[2] = vEndPos[2] - vStartPos[2];
	GetVectorAngles(tmpVec, vAngles);
}

public AnglesNormalize(Float:vAngles[3])
{
	while(vAngles[0] >  89.0) vAngles[0]-=360.0;
	while(vAngles[0] < -89.0) vAngles[0]+=360.0;
	while(vAngles[1] > 180.0) vAngles[1]-=360.0;
	while(vAngles[1] <-180.0) vAngles[1]+=360.0;
}

public AngleNormalize(&Float:flAngle)
{
	if(flAngle > 180.0) flAngle-=360.0;
	if(flAngle <-180.0) flAngle+=360.0;
}

stock Float:ChangeAngle(iClient, Float:flIdeal, Float:flCurrent)
{
	static Float:flAimMoment[MAXPLAYERS+1], Float:flAlphaSpeed, Float:flAlpha;
	new Float:flDiff, Float:flDelta;
	
	flAlphaSpeed = g_flCvarSmoothAmount / 20.0;
	flAlpha = flAlphaSpeed * 0.21;
	
	flDiff = flIdeal - flCurrent;
	AngleNormalize(flDiff);
	
	flDelta = (flDiff * flAlpha) + (flAimMoment[iClient] * flAlphaSpeed);
	if(flDelta < 0.0)
		flDelta *= -1.0;
	
	flAimMoment[iClient] = (flAimMoment[iClient] * flAlphaSpeed) + (flDelta * (1.0 - flAlphaSpeed));
	if(flAimMoment[iClient] < 0.0)
		flAimMoment[iClient] *= -1.0;
	
	return flCurrent + flDelta;
}

InterpolateVector(iClient, Float:vVelocity[3], Float:vVector[3])
{
	if(IsFakeClient(iClient))
		return;
	
	new Float:flLatency = GetClientLatency(iClient, NetFlow_Both);
	for(new x = 0; x < 3; x++)
		vVector[x] -= (vVelocity[x] * flLatency);
}

// Props to Friagram
//first-order intercept using absolute target position (http://wiki.unity3d.com/index.php/Calculating_Lead_For_Projectiles)
FirstOrderIntercept(Float:shooterPosition[3], Float:shooterVelocity[3], Float:shotSpeed, Float:targetPosition[3], Float:targetVelocity[3], iTarget)
{
	new Float:originalPosition[3];
	CopyVector(targetPosition, originalPosition);
	
	decl Float:targetRelativePosition[3];
	SubtractVectors(targetPosition, shooterPosition, targetRelativePosition);
	decl Float:targetRelativeVelocity[3];
	SubtractVectors(targetVelocity, shooterVelocity, targetRelativeVelocity);
	new Float:t = FirstOrderInterceptTime(shotSpeed, targetRelativePosition, targetRelativeVelocity);

	ScaleVector(targetRelativeVelocity, t);
	AddVectors(targetPosition, targetRelativeVelocity, targetPosition);
	
	// Check if we are going to shoot a wall or the floor
	TR_TraceRayFilter(shooterPosition, targetPosition, MASK_SOLID, RayType_EndPoint, TraceRayFilterClients, iTarget);
	if(TR_DidHit())
	{
		new Float:vEndPos[3];
		new Float:fDist1 = GetVectorDistance(shooterPosition, vEndPos);
		new Float:fDist2 = GetVectorDistance(shooterPosition, targetPosition);
		if(fDist1 < fDist2 || TR_GetFraction() != 1.0)
			CopyVector(originalPosition, targetPosition);
	}
}

//first-order intercept using relative target position
Float:FirstOrderInterceptTime(Float:shotSpeed, Float:targetRelativePosition[3], Float:targetRelativeVelocity[3])
{
	new Float:velocitySquared = GetVectorLength(targetRelativeVelocity, true);
	if(velocitySquared < 0.001)
	{
		return 0.0;
	}

	new Float:a = velocitySquared - shotSpeed*shotSpeed;
	if (FloatAbs(a) < 0.001)  //handle similar velocities
	{
		new Float:t = -GetVectorLength(targetRelativePosition, true)/(2.0*GetVectorDotProduct(targetRelativeVelocity, targetRelativePosition));

		return t > 0.0 ? t : 0.0; //don't shoot back in time
	}

	new Float:b = 2.0*GetVectorDotProduct(targetRelativeVelocity, targetRelativePosition);
	new Float:c = GetVectorLength(targetRelativePosition, true);
	new Float:determinant = b*b - 4.0*a*c;

	if (determinant > 0.0)	//determinant > 0; two intercept paths (most common)
	{ 
		new Float:t1 = (-b + SquareRoot(determinant))/(2.0*a);
		new Float:t2 = (-b - SquareRoot(determinant))/(2.0*a);
		if (t1 > 0.0)
		{
			if (t2 > 0.0) 
			{
				return t2 < t2 ? t1 : t2; //both are positive
			}
			else
			{
				return t1; //only t1 is positive
			}
		}
		else
		{
			return t2 > 0.0 ? t2 : 0.0; //don't shoot back in time
		}
	}
	else if (determinant < 0.0) //determinant < 0; no intercept path
	{
		return 0.0;
	}
	else //determinant = 0; one intercept path, pretty much never happen
	{
		determinant = -b/(2.0*a);		// temp
		return determinant > 0.0 ? determinant : 0.0; //don't shoot back in time
	}
}

stock Float:GetGrenadeZ(const Float:vOrigin[3], const Float:vTarget[3], Float:flSpeed)
{
	new Float:flDist = GetVectorDistance(vOrigin, vTarget);
	new Float:flTime = flDist / (flSpeed * 0.707);
	
	return MIN(0.0, ((Pow(2.0, flTime) - 1.0) * (g_flGravity * 0.1)));
}

stock Float:MAX(Float:a, Float:b) {
	return (a < b) ? a : b;
}

stock Float:MIN(Float:a, Float:b) {
	return (a > b) ? a : b;
}