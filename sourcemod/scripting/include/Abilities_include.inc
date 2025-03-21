//Handles Stocks and other stuff

//Sounds

#define BloodMoonSound		"items/halloween/banshee02.wav"
#define BloodMoonSound02	"ambient/halloween/windgust_01.wav"
#define BloodMoonSound2		"ambient/wind_gust2.wav"
#define BloodMoonSound3		"ambient/hallow08.wav"

#define PlagueHit	"items/powerup_pickup_plague_infected.wav"
#define PlaugeActivate "items/powerup_pickup_plague.wav"

#define KingActivate	"items/powerup_pickup_king.wav"

#define PrecisionActivate	"items/powerup_pickup_precision.wav"

#define ResistanceActivate	"items/powerup_pickup_resistance.wav"

#define ReflectActivate	"items/powerup_pickup_reflect.wav"

#define SupernovaActivate	"items/powerup_pickup_supernova.wav"

#define KnockoutActivate	"items/powerup_pickup_knockout.wav"
#define KnockoutHit		"items/powerup_pickup_knockout_melee_hit.wav"

#define AgilityActivate		"items/powerup_pickup_agility.wav"
#define AgilitySpeedBoostActivate	"misc/hologram_malfunction.wav"
#define AgilitySpeedBoostActive	"misc/hologram_move.wav"

#define EnveloperUberSound	"items/powerup_pickup_uber.wav"

#define Explosion			"weapons/explode3.wav"
#define Explosion2			"weapons/gas_can_explode.wav"
#define BurnSound1			"weapons/dragons_fury_impact_bonus_damage_hit.wav"

#define Sound15         	"weapons/samurai/tf_marked_for_death_impact_03.wav"

#define Sound_Shot		"tf/custom/sounds/Yagorath/yagorath_fire1.flac"

public OnMapStart()
{
	PrecacheSound(BloodMoonSound);
	PrecacheSound(BloodMoonSound2);
	PrecacheSound(BloodMoonSound02);
	PrecacheSound(BloodMoonSound3);
	PrecacheSound(Explosion);
	PrecacheSound(Explosion2);
	PrecacheSound(BurnSound1);
	PrecacheSound(Sound15);
	PrecacheSound(PlagueHit);
	PrecacheSound(PlaugeActivate);
	PrecacheSound(KingActivate);
	PrecacheSound(PrecisionActivate);
	PrecacheSound(ResistanceActivate);
	PrecacheSound(ReflectActivate);
	PrecacheSound(SupernovaActivate);
	PrecacheSound(KnockoutActivate);
	PrecacheSound(KnockoutHit);
	PrecacheSound(EnveloperUberSound);
	PrecacheSound(AgilityActivate);
	PrecacheSound(AgilitySpeedBoostActivate);
	PrecacheSound(AgilitySpeedBoostActive);
	
	//PrecacheModel(m_Yagorath);
}

//Base Ability Stuff

//Base Floats
new Float:max_charge[MAXPLAYERS+1];
new Float:current_charge[MAXPLAYERS+1];
new Float:charge_per[MAXPLAYERS+1];
new Float:charge_cost[MAXPLAYERS+1];
new Float:ability_power[MAXPLAYERS+1];
new Float:is_lingering[MAXPLAYERS+1];

new bool:Overflow_Protection[MAXPLAYERS+1] = {false, ...};

bool:Cooldowns_Active[MAXPLAYERS+1] = {false, ...};


//Abilities

//Empowerment

bool:Empowerment_Enable[MAXPLAYERS+1] = {false, ...};

new Float:EmpowermentCost[MAXPLAYERS+1] = {0.0, ...};

new Float:Empowerment_Active[MAXPLAYERS+1] = {0.0, ...};

new Float:Empowerment_Damage[MAXPLAYERS+1] = {0.0, ...};

//BloodMoon

new bool:Bloodmoon_Enable[MAXPLAYERS+1] = {false, ...};

new Float:BloodMoonCost[MAXPLAYERS+1] = {0.0, ...};

new bool:BloodMoon_Active[MAXPLAYERS+1] = {false, ...};

new Float:BloodMoon_Radius[MAXPLAYERS+1] = {0.0, ...};

new bool:BloodMoon_Buffed[MAXPLAYERS+1] = {false, ...};

new Float:BloodMoon_Effect[MAXPLAYERS+1] = {0.0, ...};

new Float:Regen;

//Supernova

new bool:Supernova_active[MAXPLAYERS+1] = {false, ...};

new Float:Supernova_afterburn[MAXPLAYERS+1] = {0.0, ...};

new bool:Supernova_special[MAXPLAYERS+1] = {false, ...};

new Float:Supernova_burntimerbonus;

new Float:Supernova_specialtimer[MAXPLAYERS+1] = {0.0, ...};

new Float:Supernova_cost[MAXPLAYERS+1] = {0.0, ...};

new Float:Supernova_radius[MAXPLAYERS+1] = {0.0, ...};

new Float:Supernova_damage[MAXPLAYERS+1] = {0.0, ...};

//Knockout

new bool:Knockout_active[MAXPLAYERS+1] = {false, ...};

new Float:Knockout_isslowed[MAXPLAYERS+1] = {0.0, ...};

new Float:k_duration[MAXPLAYERS+1] = {0.0, ...};

new Float:Knockout_slow_radius[MAXPLAYERS+1] = {0.0, ...};

new Float:Knockout_slow_duration[MAXPLAYERS+1] = {0.0, ...};

new Float:Knockout_disruptor_add[MAXPLAYERS+1] = {0.0, ...};

new Float:Knockout_slowcost[MAXPLAYERS+1] = {0.0, ...};

//Agility

new bool:Agility_active[MAXPLAYERS+1] = {false, ...};

new bool:Agility_Speedboostactive[MAXPLAYERS+1] = {false, ...};

//new bool:Agility_IsAmplified[MAXPLAYERS+1];

new Float:Agility_MoveTimer[MAXPLAYERS+1] = {0.0, ...};

//Plague

new bool:Plague_active[MAXPLAYERS+1] = {false, ...};

new bool:Plague_DOT1active[MAXPLAYERS+1] = {false, ...};

new bool:Plague_AOECooldownActive[MAXPLAYERS+1] = {false, ...};

new bool:Plague_DOT2active[MAXPLAYERS+1] = {false, ...};

new Float:Plague_DOTradius[MAXPLAYERS+1] = {0.0, ...};

new Float:Plague_DOTduration[MAXPLAYERS+1] = {0.0, ...};

new Float:p_duration[MAXPLAYERS+1] = {0.0, ...};

new Float:Plague_cost[MAXPLAYERS+1] = {0.0, ...};

//King

new bool:King_active[MAXPLAYERS+1] = {false, ...};

new bool:King_boostactive[MAXPLAYERS+1] = {false, ...};

new Float:King_boostradius[MAXPLAYERS+1] = {0.0, ...};

new Float:King_cost[MAXPLAYERS+1] = {0.0, ...};

//Reflect

new bool:Reflect_active[MAXPLAYERS+1] = {false, ...};

new bool:Reflect_dmgreflectactive[MAXPLAYERS+1] = {false, ...};

new bool:Reflect_InstantHealTriggered[MAXPLAYERS+1] = {false, ...};

new Float:Reflect_HealthPool[MAXPLAYERS+1] = {0.0, ...};

new Float:Reflect_cost[MAXPLAYERS+1] = {0.0, ...};

new Float:Current_HealthPool[MAXPLAYERS+1] = {0.0, ...};

//Resistance

new bool:Resistance_active[MAXPLAYERS+1] = {false, ...};

new Float:Resistance_range[MAXPLAYERS+1] = {0.0, ...};

new Float:Resistance_minrange;

new Float:Resistance_cost[MAXPLAYERS+1] = {0.0, ...};

//Precision

new bool:Precision_active[MAXPLAYERS+1] = {false, ...};

new Float:Precision_range[MAXPLAYERS+1] = {0.0, ...};

new Float:Precision_minrange;

new Float:Precision_cost[MAXPLAYERS+1] = {0.0, ...};

//Fireball

new bool:Fireball_active[MAXPLAYERS+1] = {false, ...};

new Float:Fireball_cost[MAXPLAYERS+1] = {0.0, ...};

new Float:Fireball_damage[MAXPLAYERS+1] = {0.0, ...};

//Meteor Shower

new bool:MeteorShower_active[MAXPLAYERS+1] = {false, ...};

new Float:MetorShower_cost[MAXPLAYERS+1] = {0.0, ...};

new Float:MeteorShower_damage[MAXPLAYERS+1] = {0.0, ...};

//Bat Spell

new bool:Bats_active[MAXPLAYERS+1] = {false, ...};

new Float:Bats_cost[MAXPLAYERS+1] = {0.0, ...};

new Float:Bats_damage[MAXPLAYERS+1] = {0.0, ...};

//Immortal

new bool:Immortal_active[MAXPLAYERS+1] = {false, ...};

bool Immortal_ready[MAXPLAYERS+1] = {false, ...};

bool Immortal_buffed[MAXPLAYERS+1] = {false, ...};

bool Immortal_Own[MAXPLAYERS+1] = {false, ...};

new Float:Immortal_radius[MAXPLAYERS+1] = {0.0, ...};

new Float:Immortal_cost[MAXPLAYERS+1] = {0.0, ...};

new Float:Immortal_timer[MAXPLAYERS+1] = {40.0, ...};

//Revenge
/*
new bool:Revenge_active[MAXPLAYERS+1] = {false, ...};

new bool:Revenge_Marked[MAXPLAYERS+1] = {false, ...};

new Float:Revenge_MarkedDuration[MAXPLAYERS+1] = {0.0, ...};
*/




//Enveloper

new bool:Eveloper_Buffed[MAXPLAYERS+1] = {false, ...};

new bool:Eveloper_BaseBuff[MAXPLAYERS+1] = {false, ...};

new Float:UberPercent[MAXPLAYERS+1] = {0.0, ...};

//Yagorath

new bool:Yagorath_active[MAXPLAYERS+1] = {false, ...};

new bool:TravelForm_active[MAXPLAYERS+1] = {false, ...};

new Float:Yagorath_healthadd[MAXPLAYERS+1] = {0.0, ...};

new Float:H_duration[MAXPLAYERS+1] = {0.0, ...};

new Float:Hardening_cost[MAXPLAYERS+1] = {0.0, ...};

new Float:PrimalVision_cost[MAXPLAYERS+1] = {0.0, ...};

new Float:MainFire_cost[MAXPLAYERS+1] = {0.0, ...};

new Float:Piercing_quils_cost[MAXPLAYERS+1] = {0.0, ...};

new Float:PiercingQuils_damage[MAXPLAYERS+1] = {0.0, ...};

new Float:FormSwitch_Delay[MAXPLAYERS+1] = {0.0, ...};

new Float:PiercingQuils_Delay[MAXPLAYERS+1] = {0.0, ...};


// Stocks N Stuff

/*
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
*/

stock int min(int a, int b) 
{
    return a < b ? a : b;
} 
stock TF2_GetMaxHealth(iClient)
{
    new maxhealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, iClient);
    return ((maxhealth == -1 || maxhealth == 80896) ? GetEntProp(iClient, Prop_Data, "m_iMaxHealth") : maxhealth);
}

stock AddPlayerHealth(iClient, iAdd, Float:flOverheal = 1.5, bAdditive = false, bool:bEvent = false)
{
    new iHealth = GetClientHealth(iClient);
    new iNewHealth = iHealth + iAdd;
    new iMax = bAdditive ? (TF2_GetMaxHealth(iClient) + RoundFloat(flOverheal)) : TF2_GetMaxOverHeal(iClient, flOverheal);
    if (iHealth < iMax)
    {
        iNewHealth = min(iNewHealth, iMax);
        if (bEvent)
        {
            ShowHealthGain(iClient, iNewHealth-iHealth);
        }
        SetEntityHealth(iClient, iNewHealth);
    }
}

stock ShowHealthGain(iPatient, iHealth, iHealer = -1)
{
    new iUserId = GetClientUserId(iPatient);
    new Handle:hEvent = CreateEvent("player_healed", true);
    SetEventBool(hEvent, "sourcemod", true);
    SetEventInt(hEvent, "patient", iUserId);
    SetEventInt(hEvent, "healer", IsValidClient(iHealer) ? GetClientUserId(iHealer) : iUserId);
    SetEventInt(hEvent, "amount", iHealth);
    FireEvent(hEvent);

    hEvent = CreateEvent("player_healonhit", true);
    SetEventBool(hEvent, "sourcemod", true);
    SetEventInt(hEvent, "amount", iHealth);
    SetEventInt(hEvent, "entindex", iPatient);
    FireEvent(hEvent);
}

stock TF2_GetMaxOverHeal(iClient, Float:flOverHeal = 1.5) // Quick-Fix would be 1.25
{
    return RoundFloat(float(TF2_GetMaxHealth(iClient)) * flOverHeal);
}

stock DealDamage(victim, damage, attacker=0, dmg_type=DMG_GENERIC ,String:logname[]="")
{
    if(victim>0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage>0)
    {
        new String:dmg_str[16];
        IntToString(damage,dmg_str,16);
        new String:dmg_type_str[32];
        IntToString(dmg_type,dmg_type_str,32);
        new pointHurt=CreateEntityByName("point_hurt");
        if(pointHurt)
        {
            DispatchKeyValue(victim,"targetname","war3_hurtme");
            DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
            DispatchKeyValue(pointHurt,"Damage",dmg_str);
            DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
            if(!StrEqual(logname,""))
            {
                DispatchKeyValue(pointHurt,"classname",logname);
            }
            DispatchSpawn(pointHurt);
            AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:1);
            DispatchKeyValue(pointHurt,"classname","point_hurt");
            DispatchKeyValue(victim,"targetname","war3_donthurtme");
            RemoveEdict(pointHurt);
        }
    }
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

public bool:TraceEntityFilterPlayer(entity, contentsMask) // Thx RavensBro.
{
    return entity > GetMaxClients() || !entity;
}

stock int TF2_GetClientActiveSlot(int client)
{
	return GetWeaponSlot(client, GetActiveWeapon(client));
}

stock int GetWeaponSlot(int client, int weapon)
{
	if (client == 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsValidEntity(weapon))
	{
		return -1;
	}

	for (int i = 0; i < 5; i++)
	{
		if (GetPlayerWeaponSlot(client, i) == weapon)
		{
			return i;
		}
	}

	return -1;
}

stock int GetActiveWeapon(int client)
{
	if (!IsPlayerIndex(client) || !HasEntProp(client, Prop_Send, "m_hActiveWeapon"))
	{
		return 0;
	}

	return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

stock bool IsPlayerIndex(int index)
{
	return index > 0 && index <= MaxClients;
}

stock TraceClientViewEntity(client)
{
	new Float:m_vecOrigin[3];
	new Float:m_angRotation[3];
	GetClientEyePosition(client, m_vecOrigin);
	GetClientEyeAngles(client, m_angRotation);
	new Handle:tr = TR_TraceRayFilterEx(m_vecOrigin, m_angRotation, MASK_VISIBLE, RayType_Infinite, TRDontHitSelf, client);
	new pEntity = -1;
	if (TR_DidHit(tr))
	{
		pEntity = TR_GetEntityIndex(tr);
		CloseHandle(tr);
		return pEntity;
	}
	CloseHandle(tr);
	return -1;
}
public bool:TRDontHitSelf(entity, mask, any:data)
{
	if (entity == data) return false;
	return true;
}

stock bool:IsCritBoosted(client) // Nergal :D
{
    if (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) || TF2_IsPlayerInCondition(client, TFCond_CritCanteen) || TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin) || TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) || TF2_IsPlayerInCondition(client, TFCond_CritOnKill) || TF2_IsPlayerInCondition(client, TFCond_CritMmmph) || TF2_IsPlayerInCondition(client, TFCond_CritOnDamage))
    {
        return true;
    }
    return false;
}

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

stock int GetHealingTarget(const int client)
{
    int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
    if (!IsValidEdict(medigun) || !IsValidEntity(medigun))
        return -1;

    char s[32]; GetEdictClassname(medigun, s, sizeof(s));
    if ( !strcmp(s, "tf_weapon_medigun", false) ) {
        if ( GetEntProp(medigun, Prop_Send, "m_bHealing") )
            return GetEntPropEnt( medigun, Prop_Send, "m_hHealingTarget" );
    }
    return -1;
}

stock bool IsNearSpencer(const int client)
{
    int medics = 0;
    for ( int i=MaxClients ; i ; --i ) {
        if (!IsClientInGame(i))
            continue;
        if ( GetHealingTarget(i) == client )
            medics++;
    }
    return (GetEntProp(client, Prop_Send, "m_nNumHealers") > medics);
}

stock EmitSoundFromOrigin(const String:sound[],const Float:orig[3]) // Thx Advanced Weaponiser
{
    EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}

stock ResetAbilities(client)
{
	current_charge[client] = 0.0;
	Supernova_afterburn[client] = 0.0;
	Supernova_specialtimer[client] = 30.0;
	Knockout_active[client] = false;
	Knockout_isslowed[client] = 0.0;
	Plague_active[client] = false;
	Plague_AOECooldownActive[client] = false;
	King_active[client] = false;
	Reflect_active[client] = false;
	Reflect_dmgreflectactive[client] = false;
	Reflect_InstantHealTriggered[client] = false;
	Empowerment_Active[client] = 0.0;
	BloodMoon_Active[client] = false;
	Bloodmoon_Enable[client] = false;
	Agility_active[client] = false;
	Knockout_active[client] = false;
	Supernova_active[client] = false;
	Supernova_special[client] = false;
	King_active[client] = false;
	is_lingering[client] = 0.0;
	Precision_active[client] = false;
	Yagorath_active[client] = false;
	TravelForm_active[client] = false;
	Fireball_active[client] = false;
	Bats_active[client] = false;
	MeteorShower_active[client] = false;
	Agility_MoveTimer[client] = 0.0;
	Overflow_Protection[client] = true;
	Eveloper_Buffed[client] = false;
	Eveloper_BaseBuff[client] = false;
	Immortal_active[client] = false;
	Immortal_ready[client] = false;
	Immortal_timer[client] = 40.0
	Immortal_buffed[client] = false;
	Immortal_Own[client] = false;
	Cooldowns_Active[client] = false;
}

stock DisableAbilities(client)
{
	Supernova_specialtimer[client] = 30.0;
	Knockout_active[client] = false;
	Knockout_isslowed[client] = 0.0;
	Plague_active[client] = false;
	Plague_AOECooldownActive[client] = false;
	King_active[client] = false;
	Reflect_active[client] = false;
	Reflect_dmgreflectactive[client] = false;
	Reflect_InstantHealTriggered[client] = false;
	Empowerment_Active[client] = 0.0;
	BloodMoon_Active[client] = false;
	Bloodmoon_Enable[client] = false;
	Agility_active[client] = false;
	Knockout_active[client] = false;
	Supernova_active[client] = false;
	Supernova_special[client] = false;
	King_active[client] = false;
	Precision_active[client] = false;
	Fireball_active[client] = false;
	Bats_active[client] = false;
	MeteorShower_active[client] = false;
	Agility_MoveTimer[client] = 0.0;
	Immortal_active[client] = false;
	Immortal_ready[client] = false;
	Immortal_timer[client] = 40.0
}

// Menu Stuff

public int StatsHandler(Menu stats, MenuAction action, int client, int param2)
{
	if(!IsValidClient(client))
		return -1;

	if (action == MenuAction_Select)
	{
		//PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);
		char info[32];
		stats.GetItem(param2, info, sizeof(info));
		stats.DisplayAt(client, GetMenuSelectionPosition(), 20);
		if(!strcmp("empowerment_stats", info))
		{
			//new Address:Empowerment = TF2Attrib_GetByName(client, "empowerment");
			if (ClientAttribCheck(client, "empowerment"))
			{
				delete stats;
				Menu empstats = new Menu(AbilityDetailsHandler);
				empstats.SetTitle("Empowerment Stats");
				
				decl String:dBuffer[32];
				decl String:cBuffer[32];
				Format(dBuffer, sizeof(dBuffer), "Empowerment Damage Mult: %.2f", Empowerment_Damage[client]*0.45);
				Format(cBuffer, sizeof(cBuffer), "Empowerment Charge Drain: %.2f", EmpowermentCost[client]*0.7);
				
				empstats.AddItem("", dBuffer);
				empstats.AddItem("", "Empowerment Drain Interval: 1.8 Seconds");
				empstats.AddItem("", cBuffer);
				empstats.ExitBackButton = true;
				empstats.Display(client, 20);
			}
		}
		if(!strcmp("bloodmoon_stats", info))
		{
			//new Address:BloodMoon = TF2Attrib_GetByName(client, "bloodmoon");
			if (ClientAttribCheck(client, "bloodmoon"))
			{
				delete stats;
				Menu blstats = new Menu(AbilityDetailsHandler);
				blstats.SetTitle("Bloodmoon Stats");
				
				decl String:dBuffer[32];
				decl String:aBuffer[32];
				Format(dBuffer, sizeof(dBuffer), "Bloodmoon Radius: %.0f HU", BloodMoon_Radius[client]);
				Format(aBuffer, sizeof(aBuffer), "Bloodmoon Charge Drain: %0.f", BloodMoonCost[client]*0.60);
				
				blstats.AddItem("", dBuffer);
				blstats.AddItem("", "Bloodmoon Drain Interval: 3.5 Seconds");
				blstats.AddItem("", aBuffer);
				blstats.ExitBackButton = true; 
				blstats.Display(client, 20);
			}
		}
		if(!strcmp("supernova_stats", info))
		{
			//new Address:Supernova = TF2Attrib_GetByName(client, "supernova");
			if (ClientAttribCheck(client, "supernova"))
			{
				delete stats;
				Menu snstats = new Menu(AbilityDetailsHandler);
				snstats.SetTitle("Supernova Stats");
				
				decl String:dBuffer[32];
				decl String:cBuffer[32];
				decl String:aBuffer[32];
				
				Format(dBuffer, sizeof(dBuffer), "Supernova Radius: %.0f HU", Supernova_radius[client]);
				Format(cBuffer, sizeof(cBuffer), "Supernova Damage: %.0f", Supernova_damage[client]);
				Format(aBuffer, sizeof(aBuffer), "Supernova Cost: %0.f", Supernova_cost[client]);
				
				snstats.AddItem("", dBuffer);
				snstats.AddItem("", cBuffer);
				snstats.AddItem("", aBuffer);
				snstats.ExitBackButton = true; 
				snstats.Display(client, 20);
			}
		}
		if(!strcmp("knockout_stats", info))
		{
			//new Address:Knockout = TF2Attrib_GetByName(client, "knockout");
			if (ClientAttribCheck(client, "knockout"))
			{
				delete stats;
				Menu snstats = new Menu(AbilityDetailsHandler);
				snstats.SetTitle("Knockout Stats");
				
				decl String:dBuffer[32];
				decl String:cBuffer[32];
				decl String:aBuffer[32];
				decl String:bBuffer[32];
				
				Format(dBuffer, sizeof(dBuffer), "Slow Radius: %.0f HU", Knockout_slow_radius[client]);
				Format(cBuffer, sizeof(cBuffer), "Slow Duration: %.2f", k_duration[client]);
				Format(aBuffer, sizeof(aBuffer), "Slow Cost: %.0f", Knockout_slowcost[client]);
				Format(bBuffer, sizeof(bBuffer), "Disruptor Bonus: %.0f", Knockout_disruptor_add[client]);
				
				snstats.AddItem("", dBuffer);
				snstats.AddItem("", cBuffer);
				snstats.AddItem("", bBuffer);
				snstats.AddItem("", aBuffer);
				snstats.ExitBackButton = true; 
				snstats.Display(client, 20);
			}
		}
		if(!strcmp("infection_stats", info))
		{
			//new Address:Plague = TF2Attrib_GetByName(client, "plague");
			if (ClientAttribCheck(client, "plague"))
			{
				delete stats;
				Menu snstats = new Menu(AbilityDetailsHandler);
				snstats.SetTitle("Plague Stats");
				
				decl String:dBuffer[32];
				decl String:cBuffer[32];
				decl String:aBuffer[32];
				decl String:bBuffer[32];
				
				Format(dBuffer, sizeof(dBuffer), "Area Infection Radius: %.0f HU", Plague_DOTradius[client]);
				Format(cBuffer, sizeof(cBuffer), "Infection Duration: %.2f", p_duration[client]);
				Format(aBuffer, sizeof(aBuffer), "Infection on Hit Cost %.0f", Plague_cost[client]*0.40);
				Format(bBuffer, sizeof(bBuffer), "Area Infection Cost: %.0f", Plague_cost[client]*1.20);
				
				snstats.AddItem("", dBuffer);
				snstats.AddItem("", cBuffer);
				snstats.AddItem("", bBuffer);
				snstats.AddItem("", aBuffer);
				snstats.ExitBackButton = true; 
				snstats.Display(client, 20);
			}
		}
		if (!strcmp("king_stats", info))
		{
			//new Address:King = TF2Attrib_GetByName(client, "king");
			if (ClientAttribCheck(client, "king"))
			{
				delete stats;
				Menu snstats = new Menu(AbilityDetailsHandler);
				snstats.SetTitle("King Stats");
				
				decl String:dBuffer[32];
				decl String:cBuffer[32];
				decl String:aBuffer[32];
				decl String:bBuffer[32];
				
				Format(dBuffer, sizeof(dBuffer), "King Boost Radius: %.0f HU", King_boostradius[client]);
				Format(cBuffer, sizeof(cBuffer), "Boost Cost: %.0f", King_cost[client]);
				Format(aBuffer, sizeof(aBuffer), "Damage Bonus : 1.5x");
				Format(bBuffer, sizeof(bBuffer), "Percent of Max HP Regen: 15");
				
				snstats.AddItem("", dBuffer);
				snstats.AddItem("", cBuffer);
				snstats.AddItem("", bBuffer);
				snstats.AddItem("", aBuffer);
				snstats.ExitBackButton = true; 
				snstats.Display(client, 20);
			}
		}
		if (!strcmp("reflect_stats", info))
		{
			//new Address:Reflect = TF2Attrib_GetByName(client, "reflect");
			if (ClientAttribCheck(client, "reflect"))
			{
				delete stats;
				Menu snstats = new Menu(AbilityDetailsHandler);
				snstats.SetTitle("Reflect Stats");
				
				decl String:dBuffer[32];
				decl String:cBuffer[32];
				decl String:aBuffer[32];
				decl String:bBuffer[32];
				decl String:eBuffer[32];
				
				Format(dBuffer, sizeof(dBuffer), "Reflect Added Health Pool: %.0f", Reflect_HealthPool[client]);
				Format(cBuffer, sizeof(cBuffer), "Reflect Regen Cost: %.0f", Reflect_cost[client]);
				Format(aBuffer, sizeof(aBuffer), "Regen Threshold: 75 Percent");
				Format(bBuffer, sizeof(bBuffer), "Current Added Health Pool: %.0f", Current_HealthPool[client]);
				Format(eBuffer, sizeof(eBuffer), "Damage Reflection Cost: %.0f", Reflect_cost[client]*2.0);
				
				snstats.AddItem("", dBuffer);
				snstats.AddItem("", cBuffer);
				snstats.AddItem("", eBuffer);
				snstats.AddItem("", bBuffer);
				snstats.AddItem("", aBuffer);
				snstats.ExitBackButton = true; 
				snstats.Display(client, 20);
			}
		}
		if (!strcmp("resistance_stats", info))
		{
			//new Address:Resistance = TF2Attrib_GetByName(client, "resistance");
			if (ClientAttribCheck(client, "resistance"))
			{
				delete stats;
				Menu snstats = new Menu(AbilityDetailsHandler);
				snstats.SetTitle("Resistance Stats");
				
				decl String:dBuffer[32];
				decl String:cBuffer[32];
				decl String:aBuffer[32];
				
				Format(dBuffer, sizeof(dBuffer), "Resistance Range: %.0f HU", Resistance_range[client]);
				Format(cBuffer, sizeof(cBuffer), "Resistance Minimum Range: 600 HU");
				Format(aBuffer, sizeof(aBuffer), "Resistance Cost: %.0f", Resistance_cost[client]);
				
				snstats.AddItem("", dBuffer);
				snstats.AddItem("", cBuffer);
				snstats.AddItem("", aBuffer);
				snstats.ExitBackButton = true; 
				snstats.Display(client, 20);
			}
		}
		if (!strcmp("precision_stats", info))
		{
			//new Address:Precision = TF2Attrib_GetByName(client, "precision");
			if (ClientAttribCheck(client, "precision"))
			{			
				delete stats;
				Menu snstats = new Menu(AbilityDetailsHandler);
				snstats.SetTitle("Precision Stats");
				
				decl String:dBuffer[32];
				decl String:cBuffer[32];
				decl String:aBuffer[32];
				Format(dBuffer, sizeof(dBuffer), "Precision Range: %.0f HU", Precision_range[client]);
				Format(cBuffer, sizeof(cBuffer), "Precision Minimum Range: 600 HU");
				Format(aBuffer, sizeof(aBuffer), "Precision Cost: %.0f", Precision_cost[client]);
				
				snstats.AddItem("", dBuffer);
				snstats.AddItem("", cBuffer);
				snstats.AddItem("", aBuffer);
				snstats.ExitBackButton = true; 
				snstats.Display(client, 20);
			}
		}
		if (!strcmp("bats_stats", info))
		{
			//new Address:Bats = TF2Attrib_GetByName(client, "bats");
			if (ClientAttribCheck(client, "bats"))
			{
				delete stats;
				Menu snstats = new Menu(AbilityDetailsHandler);
				snstats.SetTitle("Bats Spell Stats");
				
				decl String:dBuffer[32];
				decl String:cBuffer[32];
				Format(dBuffer, sizeof(dBuffer), "Damage: %.0f", Bats_damage[client]);
				Format(cBuffer, sizeof(cBuffer), "Bats Spell Cost: %.0f", Bats_cost[client]);
				
				snstats.AddItem("", dBuffer);
				snstats.AddItem("", cBuffer);
				snstats.ExitBackButton = true;
				snstats.Display(client, 20);
			}
		}
		if (!strcmp("fireball_stats", info))
		{
			//new Address:Fireball = TF2Attrib_GetByName(client, "fireball");
			if (ClientAttribCheck(client, "fireball"))
			{
				delete stats;
				Menu snstats = new Menu(AbilityDetailsHandler);
				snstats.SetTitle("Fireball Stats");
				
				decl String:dBuffer[32];
				decl String:cBuffer[32];
				Format(dBuffer, sizeof(dBuffer), "Damage: %.0f", Fireball_damage[client]);
				Format(cBuffer, sizeof(cBuffer), "Fireball Cost: %.0f", Fireball_cost[client]);
				
				snstats.AddItem("", dBuffer);
				snstats.AddItem("", cBuffer);
				snstats.ExitBackButton = true; 
				snstats.Display(client, 20);
			}
		}
		if (!strcmp("meteor_stats", info))
		{
			//new Address:MeteorShower = TF2Attrib_GetByName(client, "meteor shower");
			if (ClientAttribCheck(client, "meteor shower"))
			{
				delete stats;
				Menu snstats = new Menu(AbilityDetailsHandler);
				snstats.SetTitle("Meteor Shower Stats");
				
				decl String:dBuffer[32];
				decl String:cBuffer[32];
				Format(dBuffer, sizeof(dBuffer), "Damage: %.0f", MeteorShower_damage[client]);
				Format(cBuffer, sizeof(cBuffer), "Meteor Shower Cost: %.0f", MetorShower_cost[client]);
				
				snstats.AddItem("", dBuffer);
				snstats.AddItem("", cBuffer);
				snstats.ExitBackButton = true; 
				snstats.Display(client, 20);
			}
		}
		if (!strcmp("immortal_stats", info))
		{
			new Address:Immortal = TF2Attrib_GetByName(client, "custom name attr");
			if (Immortal != Address_Null)
			{
				delete stats;
				Menu snstats = new Menu(AbilityDetailsHandler);
				snstats.SetTitle("Immortal Stats");
				
				decl String:dBuffer[32];
				decl String:cBuffer[32];
				Format(dBuffer, sizeof(dBuffer), "Immortal Radius: %.0f", Immortal_radius[client]);
				Format(cBuffer, sizeof(cBuffer), "Immortal Cost: %.0f", Immortal_cost[client]);
				
				snstats.AddItem("", dBuffer);
				snstats.AddItem("", cBuffer);
				snstats.ExitBackButton = true; 
				snstats.Display(client, 20);
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %d's Stat menu was cancelled.  Reason: %d", client, param2);
		if (param2 == MenuCancel_ExitBack)
			DisplayAbilitiesMenu(client);
	}
    /* If the menu has ended, destroy it */
	if (action == MenuAction_End)
    {
		delete stats;
	}
	return -1;
}
public int AbilityDetailsHandler(Menu stats, MenuAction action, int client, int param2)
{
	if(!IsValidClient(client))
		return -1;

	/* If the menu was cancelled, print a message to the server about it. */
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
			DisplayAbilityStatsMenu(client);
	}
    /* If the menu has ended, destroy it */
	if (action == MenuAction_End)
    {
		delete stats;
	}
	return -1;
}
stock SecondAbilAttribCheck(client)
{
	if (!IsValidClient(client)) {return;}
	
	if (!ClientAttribCheck(client, "empowerment") && Empowerment_Enable[client])
	{
		Empowerment_Enable[client] = false;
	}
	if (!ClientAttribCheck(client, "bloodmoon") && Bloodmoon_Enable[client])
	{
		Bloodmoon_Enable[client] = false;
	}
	if (!ClientAttribCheck(client, "supernova") && Supernova_active[client])
	{
		Supernova_active[client] = false;
	}
	if (!ClientAttribCheck(client, "knockout") && Knockout_active[client])
	{
		Knockout_active[client] = false;
	}
	if (!ClientAttribCheck(client, "king") && King_active[client])
	{
		King_active[client] = false;
	}
	if (!ClientAttribCheck(client, "resistance") && Resistance_active[client])
	{
		Resistance_active[client] = false;
	}
	if (!ClientAttribCheck(client, "precision") && Precision_active[client])
	{
		Precision_active[client] = false;
	}
	if (!ClientAttribCheck(client, "reflect") && Reflect_active[client])
	{
		Reflect_active[client] = false;
	}
	if (!ClientAttribCheck(client, "plague") && Plague_active[client])
	{
		Plague_active[client] = false;
	}
	if (!ClientAttribCheck(client, "agility") && Agility_active[client])
	{
		Agility_active[client] = false;
	}
	if (!ClientAttribCheck(client, "fireball") && Fireball_active[client])
	{
		Fireball_active[client] = false;
	}
	if (!ClientAttribCheck(client, "bats") && Bats_active[client])
	{
		Bats_active[client] = false;
	}
	if (!ClientAttribCheck(client, "meteor shower") && MeteorShower_active[client])
	{
		MeteorShower_active[client] = false;
	}
}

public int MenuHandler1(Menu menu, MenuAction action, int client, int param2)
{
	if(!IsValidClient(client))
		return -1;
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		menu.DisplayAt(client, GetMenuSelectionPosition(), 20);
		new Float:Pos[3];
		GetClientEyePosition(client, Pos);
		SecondAbilAttribCheck(client);
		if(!strcmp("empowerment", info))
		{
			//new Address:Empowerment = TF2Attrib_GetByName(client, "empowerment");
			if (ClientAttribCheck(client, "empowerment"))
			{
				Empowerment_Enable[client] = !Empowerment_Enable[client];
				PrintHintText(client, "Empowerment %s.", Empowerment_Enable[client] ? "enabled" : "disabled");
				PrintToServer("Client %d %s Empowerment.", client, Empowerment_Enable[client] ? "enabled" : "disabled");
				if (Empowerment_Enable[client] == true)
				{
					PrintToChat(client, "Empowerment Active. Press Middle Mouse to use when you have at least %.0f Charge", EmpowermentCost[client]*1.3);
				}
				
				if (Bloodmoon_Enable[client] == true)
				{
					Bloodmoon_Enable[client] = false;
					PrintHintText(client, "Bloodmoon disabled. You can only have one lingering ability enabled at once.");
				}
				if (Yagorath_active[client] == true)
				{
					DisableAbilities(client)
					PrintHintText(client, "Cannot have other abilities active while Yagorath is Active");
				}
			}
		}
		if(!strcmp("bloodmoon", info))
		{
			//new Address:BloodMoon = TF2Attrib_GetByName(client, "bloodmoon");
			if (ClientAttribCheck(client, "bloodmoon"))
			{
				Bloodmoon_Enable[client] = !Bloodmoon_Enable[client];
				PrintHintText(client, "Bloodmoon %s.", Bloodmoon_Enable[client] ? "enabled" : "disabled");
				PrintToServer("Client %d %s Bloodmoon.", client, Bloodmoon_Enable[client] ? "enabled" : "disabled");
				if (Bloodmoon_Enable[client] == true)
				{
					PrintToChat(client, "Bloodmoon Active. Press Middle Mouse to use when you have at least %.0f Charge", BloodMoonCost[client]*1.5);
				}
				
				if (Empowerment_Enable[client] == true)
				{
					Empowerment_Enable[client] = false;
					PrintHintText(client, "Empowerment disabled. You can only have one lingering ability enabled at once.");
				}
				if (Yagorath_active[client] == true)
				{
					DisableAbilities(client)
					PrintHintText(client, "Cannot have other abilities active while Yagorath is Active");
				}
			}
		}
		if(!strcmp("supernova", info))
		{
			//new Address:Supernova = TF2Attrib_GetByName(client, "supernova");
			if (ClientAttribCheck(client, "supernova"))
			{
				Supernova_active[client] = !Supernova_active[client];
				PrintHintText(client, "Supernova %s.", Supernova_active[client] ? "enabled" : "disabled");
				PrintToServer("Client %d %s Supernova.", client, Supernova_active[client] ? "enabled" : "disabled");
				
				if (Supernova_active[client] == true)
				{
					EmitSoundFromOrigin(SupernovaActivate, Pos);
				}
				
				if (Immortal_active[client] == true)
				{
					Immortal_active[client] = false;
					Immortal_ready[client] = false;
					Immortal_timer[client] = 40.0;
					PrintHintText(client, "Immortal disabled to prevent conflict with controls.");
				}
				if (Yagorath_active[client] == true)
				{
					DisableAbilities(client)
					PrintHintText(client, "Cannot have other abilities active while Yagorath is Active");
				}
				if (Supernova_active[client] == false)
				{
					Supernova_special[client] = false;
					Supernova_specialtimer[client] = 30.0;
				}
				if (Knockout_active[client] == true)
				{
					Knockout_active[client] = false;
					PrintHintText(client, "Knockout disabled. You can only have one powerup enabled at once.");
				}
				if (Agility_active[client] == true)
				{
					Agility_active[client] = false;
					PrintHintText(client, "Agility disabled. You can only have one powerup enabled at once.");
				}
				if (Plague_active[client] == true)
				{
					Plague_active[client] = false;
					PrintHintText(client, "Plague disabled. You can only have one powerup enabled at once.");
				}
				if (King_active[client] == true)
				{
					King_active[client] = false;
					PrintHintText(client, "King disabled. You can only have one powerup enabled at once.");
				}
				if (Reflect_active[client] == true)
				{
					Reflect_active[client] = false;
					Reflect_dmgreflectactive[client] = false;
					Reflect_InstantHealTriggered[client] = false;
					PrintHintText(client, "Reflect disabled. You can only have one powerup enabled at once.");
				}
				if (Resistance_active[client] == true)
				{
					Resistance_active[client] = false;
					PrintHintText(client, "Resistance disabled. You can only have one powerup enabled at once.");
				}
				if (Precision_active[client] == true)
				{
					Precision_active[client] = false;
					PrintHintText(client, "Precision disabled. You can only have one powerup enabled at once.");
				}
			}
		}
		if(!strcmp("knockout", info))
		{
			//new Address:Knockout = TF2Attrib_GetByName(client, "knockout");
			if (ClientAttribCheck(client, "knockout"))
			{
				Knockout_active[client] = !Knockout_active[client];
				PrintHintText(client, "Knockout %s.", Knockout_active[client] ? "enabled" : "disabled");
				PrintToServer("Client %d %s Knockout.", client, Knockout_active[client] ? "enabled" : "disabled");
				
				if (Knockout_active[client] == true)
				{
					EmitSoundFromOrigin(KnockoutActivate, Pos);
				}
				if (Yagorath_active[client] == true)
				{
					DisableAbilities(client)
					PrintHintText(client, "Cannot have other abilities active while Yagorath is Active");
				}
				if (Supernova_active[client] == true)
				{
					Supernova_active[client] = false;
					Supernova_special[client] = false;
					Supernova_specialtimer[client] = 30.0;
					PrintHintText(client, "Supernova disabled. You can only have one powerup enabled at once.");
				}
				if (Agility_active[client] == true)
				{
					Agility_active[client] = false;
					PrintHintText(client, "Agility disabled. You can only have one powerup enabled at once.");
				}
				if (Plague_active[client] == true)
				{
					Plague_active[client] = false;
					PrintHintText(client, "Plague disabled. You can only have one powerup enabled at once.");
				}
				if (King_active[client] == true)
				{
					King_active[client] = false;
					PrintHintText(client, "King disabled. You can only have one powerup enabled at once.");
				}
				if (Reflect_active[client] == true)
				{
					Reflect_active[client] = false;
					Reflect_dmgreflectactive[client] = false;
					PrintHintText(client, "Reflect disabled. You can only have one powerup enabled at once.");
				}
				if (Resistance_active[client] == true)
				{
					Resistance_active[client] = false;
					PrintHintText(client, "Resistance disabled. You can only have one powerup enabled at once.");
				}
				if (Precision_active[client] == true)
				{
					Precision_active[client] = false;
					PrintHintText(client, "Precision disabled. You can only have one powerup enabled at once.");
				}
			}
		}
		if(!strcmp("agility", info))
		{
			//new Address:Agility = TF2Attrib_GetByName(client, "agility");
			if (ClientAttribCheck(client, "agility"))
			{
				Agility_active[client] = !Agility_active[client];
				PrintHintText(client, "Agility %s.", Agility_active[client] ? "enabled" : "disabled");
				PrintToServer("Client %d %s Agility.", client, Agility_active[client] ? "enabled" : "disabled");
				
				if (Agility_active[client] == true)
				{
					EmitSoundFromOrigin(AgilityActivate, Pos);
				}
				if (Yagorath_active[client] == true)
				{
					DisableAbilities(client)
					PrintHintText(client, "Cannot have other abilities active while Yagorath is Active");
				}
				if (Supernova_active[client] == true)
				{
					Supernova_active[client] = false;
					Supernova_special[client] = false;
					Supernova_specialtimer[client] = 30.0;
					PrintHintText(client, "Supernova disabled. You can only have one powerup enabled at once.");
				}
				if (Knockout_active[client] == true)
				{
					Knockout_active[client] = false;
					PrintHintText(client, "Knockout disabled. You can only have one powerup enabled at once.");
				}
				if (Plague_active[client] == true)
				{
					Plague_active[client] = false;
					PrintHintText(client, "Plague disabled. You can only have one powerup enabled at once.");
				}
				if (King_active[client] == true)
				{
					King_active[client] = false;
					PrintHintText(client, "King disabled. You can only have one powerup enabled at once.");
				}
				if (Reflect_active[client] == true)
				{
					Reflect_active[client] = false;
					Reflect_dmgreflectactive[client] = false;
					Reflect_InstantHealTriggered[client] = false;
					PrintHintText(client, "Reflect disabled. You can only have one powerup enabled at once.");
				}
				if (Resistance_active[client] == true)
				{
					Resistance_active[client] = false;
					PrintHintText(client, "Resistance disabled. You can only have one powerup enabled at once.");
				}
				if (Precision_active[client] == true)
				{
					Precision_active[client] = false;
					PrintHintText(client, "Precision disabled. You can only have one powerup enabled at once.");
				}
			}
		}
		if(!strcmp("plague", info))
		{
			//new Address:Plague = TF2Attrib_GetByName(client, "plague");
			if (ClientAttribCheck(client, "plague"))
			{
				Plague_active[client] = !Plague_active[client];
				PrintHintText(client, "Plague %s.", Plague_active[client] ? "enabled" : "disabled");
				PrintToServer("Client %d %s Plague.", client, Plague_active[client] ? "enabled" : "disabled");
				
				if (Plague_active[client] == true)
				{
					EmitSoundFromOrigin(PlaugeActivate, Pos);
				}
				if (Yagorath_active[client] == true)
				{
					DisableAbilities(client)
					PrintHintText(client, "Cannot have other abilities active while Yagorath is Active");
				}
				if (Agility_active[client] == true)
				{
					Agility_active[client] = false;
					PrintHintText(client, "Agility disabled. You can only have one powerup enabled at once.");
				}
				if (Supernova_active[client] == true)
				{
					Supernova_active[client] = false;
					Supernova_special[client] = false;
					Supernova_specialtimer[client] = 30.0;
					PrintHintText(client, "Supernova disabled. You can only have one powerup enabled at once.");
				}
				if (Knockout_active[client] == true)
				{
					Knockout_active[client] = false;
					PrintHintText(client, "Knockout disabled. You can only have one powerup enabled at once.");
				}
				if (King_active[client] == true)
				{
					King_active[client] = false;
					PrintHintText(client, "King disabled. You can only have one powerup enabled at once.");
				}
				if (Reflect_active[client] == true)
				{
					Reflect_active[client] = false;
					Reflect_dmgreflectactive[client] = false;
					Reflect_InstantHealTriggered[client] = false;
					PrintHintText(client, "Reflect disabled. You can only have one powerup enabled at once.");
				}
				if (Resistance_active[client] == true)
				{
					Resistance_active[client] = false;
					PrintHintText(client, "Resistance disabled. You can only have one powerup enabled at once.");
				}
				if (Precision_active[client] == true)
				{
					Precision_active[client] = false;
					PrintHintText(client, "Precision disabled. You can only have one powerup enabled at once.");
				}
			}
		}
		if(!strcmp("king", info))
		{
			//new Address:King = TF2Attrib_GetByName(client, "king");
			if (ClientAttribCheck(client, "king"))
			{
				King_active[client] = !King_active[client];
				PrintHintText(client, "King %s.", King_active[client] ? "enabled" : "disabled");
				PrintToServer("Client %d %s King.", client, King_active[client] ? "enabled" : "disabled");
				
				if (King_active[client] == true)
				{
					EmitSoundFromOrigin(KingActivate, Pos);
				}
				if (Yagorath_active[client] == true)
				{
					DisableAbilities(client)
					PrintHintText(client, "Cannot have other abilities active while Yagorath is Active");
				}
				if (Agility_active[client] == true)
				{
					Agility_active[client] = false;
					PrintHintText(client, "Agility disabled. You can only have one powerup enabled at once.");
				}
				if (Supernova_active[client] == true)
				{
					Supernova_active[client] = false;
					Supernova_special[client] = false;
					Supernova_specialtimer[client] = 30.0;
					PrintHintText(client, "Supernova disabled. You can only have one powerup enabled at once.");
				}
				if (Knockout_active[client] == true)
				{
					Knockout_active[client] = false;
					PrintHintText(client, "Knockout disabled. You can only have one powerup enabled at once.");
				}
				if (Reflect_active[client] == true)
				{
					Reflect_active[client] = false;
					Reflect_dmgreflectactive[client] = false;
					Reflect_InstantHealTriggered[client] = false;
					PrintHintText(client, "Reflect disabled. You can only have one powerup enabled at once.");
				}
				if (Resistance_active[client] == true)
				{
					Resistance_active[client] = false;
					PrintHintText(client, "Resistance disabled. You can only have one powerup enabled at once.");
				}
				if (Precision_active[client] == true)
				{
					Precision_active[client] = false;
					PrintHintText(client, "Precision disabled. You can only have one powerup enabled at once.");
				}
			}
		}
		if (!strcmp("reflect", info))
		{
			//new Address:Reflect = TF2Attrib_GetByName(client, "reflect");
			if (ClientAttribCheck(client, "reflect"))
			{
				Reflect_active[client] = !Reflect_active[client];
				PrintHintText(client, "Reflect %s.", Reflect_active[client] ? "enabled" : "disabled");
				PrintToServer("Client %d %s Reflect.", client, Reflect_active[client] ? "enabled" : "disabled");
				
				if (Reflect_active[client] == true)
				{
					EmitSoundFromOrigin(ReflectActivate, Pos);
				}
				if (Yagorath_active[client] == true)
				{
					DisableAbilities(client)
					PrintHintText(client, "Cannot have other abilities active while Yagorath is Active");
				}
				if (Reflect_active[client] == false)
				{
					Reflect_dmgreflectactive[client] = false;
				}
				if (Supernova_active[client] == true)
				{
					Supernova_active[client] = false;
					Supernova_special[client] = false;
					Supernova_specialtimer[client] = 30.0;
					PrintHintText(client, "Supernova disabled. You can only have one powerup enabled at once.");
				}
				if (Knockout_active[client] == true)
				{
					Knockout_active[client] = false;
					PrintHintText(client, "Knockout disabled. You can only have one powerup enabled at once.");
				}
				if (Plague_active[client] == true)
				{
					Plague_active[client] = false;
					PrintHintText(client, "Plague disabled. You can only have one powerup enabled at once.");
				}
				if (King_active[client] == true)
				{
					King_active[client] = false;
					PrintHintText(client, "King disabled. You can only have one powerup enabled at once.");
				}
				if (Resistance_active[client] == true)
				{
					Resistance_active[client] = false;
					PrintHintText(client, "Resistance disabled. You can only have one powerup enabled at once.");
				}
				if (Precision_active[client] == true)
				{
					Precision_active[client] = false;
					PrintHintText(client, "Precision disabled. You can only have one powerup enabled at once.");
				}
			}
		}
		if (!strcmp("resistance", info))
		{
			//new Address:Resistance = TF2Attrib_GetByName(client, "resistance");
			if (ClientAttribCheck(client, "resistance"))
			{
				Resistance_active[client] = !Resistance_active[client];
				PrintHintText(client, "Resistance %s.", Resistance_active[client] ? "enabled" : "disabled");
				PrintToServer("Client %d %s Resistance.", client, Resistance_active[client] ? "enabled" : "disabled");
				
				if (Resistance_active[client] == true)
				{
					EmitSoundFromOrigin(ResistanceActivate, Pos);
				}
				if (Yagorath_active[client] == true)
				{
					DisableAbilities(client)
					PrintHintText(client, "Cannot have other abilities active while Yagorath is Active");
				}
				if (Agility_active[client] == true)
				{
					Agility_active[client] = false;
					PrintHintText(client, "Agility disabled. You can only have one powerup enabled at once.");
				}
				if (Supernova_active[client] == true)
				{
					Supernova_active[client] = false;
					Supernova_special[client] = false;
					Supernova_specialtimer[client] = 30.0;
					PrintHintText(client, "Supernova disabled. You can only have one powerup enabled at once.");
				}
				if (Knockout_active[client] == true)
				{
					Knockout_active[client] = false;
					PrintHintText(client, "Knockout disabled. You can only have one powerup enabled at once.");
				}
				if (Reflect_active[client] == true)
				{
					Reflect_active[client] = false;
					Reflect_dmgreflectactive[client] = false;
					Reflect_InstantHealTriggered[client] = false;
					PrintHintText(client, "Reflect disabled. You can only have one powerup enabled at once.");
				}
				if (Precision_active[client] == true)
				{
					Precision_active[client] = false;
					PrintHintText(client, "Precision disabled. You can only have one powerup enabled at once.");
				}
			}
		}
		if (!strcmp("precision", info))
		{
			//new Address:Precision = TF2Attrib_GetByName(client, "precision");
			if (ClientAttribCheck(client, "precision"))
			{
				Precision_active[client] = !Precision_active[client];
				PrintHintText(client, "Precision %s.", Precision_active[client] ? "enabled" : "disabled");
				PrintToServer("Client %d %s Precision.", client, Precision_active[client] ? "enabled" : "disabled");
				
				if (Precision_active[client] == true)
				{
					EmitSoundFromOrigin(PrecisionActivate, Pos);
				}
				if (Yagorath_active[client] == true)
				{
					DisableAbilities(client)
					PrintHintText(client, "Cannot have other abilities active while Yagorath is Active");
				}
				if (Agility_active[client] == true)
				{
					Agility_active[client] = false;
					PrintHintText(client, "Agility disabled. You can only have one powerup enabled at once.");
				}
				if (Supernova_active[client] == true)
				{
					Supernova_active[client] = false;
					Supernova_special[client] = false;
					Supernova_specialtimer[client] = 30.0;
					PrintHintText(client, "Supernova disabled. You can only have one powerup enabled at once.");
				}
				if (Knockout_active[client] == true)
				{
					Knockout_active[client] = false;
					PrintHintText(client, "Knockout disabled. You can only have one powerup enabled at once.");
				}
				if (Reflect_active[client] == true)
				{
					Reflect_active[client] = false;
					Reflect_dmgreflectactive[client] = false;
					Reflect_InstantHealTriggered[client] = false;
					PrintHintText(client, "Reflect disabled. You can only have one powerup enabled at once.");
				}
				if (Resistance_active[client] == true)
				{
					Resistance_active[client] = false;
					PrintHintText(client, "Resistance disabled. You can only have one powerup enabled at once.");
				}
			}
		}
		if (!strcmp("immortal", info))
		{
			new Address:Immortal = TF2Attrib_GetByName(client, "custom name attr");
			if (Immortal!=Address_Null)
			{
				Immortal_active[client] = !Immortal_active[client];
				PrintHintText(client, "Immortal %s.", Immortal_active[client] ? "enabled" : "disabled");
				PrintToServer("Client %d %s Immortal.", client, Immortal_active[client] ? "enabled" : "disabled");
				
				if (Immortal_active[client] == false)
				{
					Immortal_ready[client] = false;
					Immortal_timer[client] = 40.0;
					Immortal_buffed[client] = false;
					Immortal_Own[client] = false;
					TF2Attrib_RemoveByName(client, "CARD: move speed bonus");
				}
				if (Yagorath_active[client] == true)
				{
					DisableAbilities(client)
					PrintHintText(client, "Cannot have other abilities active while Yagorath is Active");
				}
				
				if (Supernova_active[client] == true)
				{
					Supernova_active[client] = false;
					Supernova_special[client] = false;
					Supernova_specialtimer[client] = 30.0;
					PrintHintText(client, "Supernova disabled to prevent conflict with controls.");
				}
			}
		}
		if (!strcmp("yagorath", info))
		{
			new Address:Yagorath = TF2Attrib_GetByName(client, "no charge impact range");
			if (Yagorath!=Address_Null)
			{
				Yagorath_active[client] = !Yagorath_active[client];
				PrintHintText(client, "Yagorath %s.", Yagorath_active[client] ? "enabled" : "disabled");
				PrintToServer("Client %d %s Yagorath.", client, Yagorath_active[client] ? "enabled" : "disabled");
				if (Yagorath_active[client] == true)
				{
					DisableAbilities(client);
					PrintHintText(client, "All other Abilities Disabled");
					//SetVariantString(m_Yagorath);
					//AcceptEntityInput(client, "SetCustomModel");
				}
				else
				{
					SetVariantInt(0);
					AcceptEntityInput(client, "SetForcedTauntCam");
					TravelForm_active[client] = false;
				}
			}
		}
		if (!strcmp("throw_fireball", info))
		{
			//new Address:Fireball = TF2Attrib_GetByName(client, "fireball");
			if (ClientAttribCheck(client, "fireball"))
			{
				Fireball_active[client] = !Fireball_active[client];
				PrintHintText(client, "Fireball %s.", Fireball_active[client] ? "enabled" : "disabled");
				if (Yagorath_active[client] == true)
				{
					DisableAbilities(client)
					PrintHintText(client, "Cannot have other abilities active while Yagorath is Active");
				}
				
				/*if (MeteorShower_active[client] == true)
				{
					MeteorShower_active[client] = false;
					PrintHintText(client, "Meteor Shower disabled. You can only have one spell enabled at once.");
				}
				if (Bats_active[client] == true)
				{
					Bats_active[client] = false;
					PrintHintText(client, "Bats Spell disabled. You can only have one spell enabled at once.");
				}*/
			}
		}
		if (!strcmp("throw_meteorshower", info))
		{
			//new Address:MeteorShower = TF2Attrib_GetByName(client, "meteor shower");
			if (ClientAttribCheck(client, "meteor shower"))
			{
				MeteorShower_active[client] = !MeteorShower_active[client];
				PrintHintText(client, "Meteor Shower %s.", MeteorShower_active[client] ? "enabled" : "disabled");
				if (Yagorath_active[client] == true)
				{
					DisableAbilities(client)
					PrintHintText(client, "Cannot have other abilities active while Yagorath is Active");
				}
				/*if (Bats_active[client] == true)
				{
					Bats_active[client] = false;
					PrintHintText(client, "Bats Spell disabled. You can only have one spell enabled at once.");
				}
				if (Fireball_active[client] == true)
				{
					Fireball_active[client] = false;
					PrintHintText(client, "Fireball Spell disabled. You can only have one spell enabled at once.");
				}*/
			}
		}
		if (!strcmp("throw_bats", info))
		{
			//new Address:Bats = TF2Attrib_GetByName(client, "bats");
			if (ClientAttribCheck(client, "bats"))
			{
				Bats_active[client] = !Bats_active[client];
				PrintHintText(client, "Bats Spell %s.", Bats_active[client] ? "enabled" : "disabled");
				
				if (Yagorath_active[client] == true)
				{
					DisableAbilities(client)
					PrintHintText(client, "Cannot have other abilities active while Yagorath is Active");
				}
				/*if (Fireball_active[client] == true)
				{
					Fireball_active[client] = false;
					PrintHintText(client, "Fireball Spell disabled. You can only have one spell enabled at once.");
				}
				if (MeteorShower_active[client] == true)
				{
					MeteorShower_active[client] = false;
					PrintHintText(client, "Meteor Shower disabled. You can only have one spell enabled at once.");
				}*/
			}
		}
		if (!strcmp("ability_stats", info))
		{
			if (IsValidClient(client) && IsPlayerAlive(client))
			{
				PrintToServer("Client %d Accessing Ability Stats.", client);
				DisplayAbilityStatsMenu(client);
			}
		}
    }
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
		PrintToServer("Client %d's Ability menu was cancelled.  Reason: %d", client, param2);
    /* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
		delete menu;

	return -1;
}

stock bool ClientAttribCheck(client, const char[] attribname)
{
	if (IsValidClient(client))
	{
		Address attrib = TF2Attrib_GetByName(client, attribname);
		
		if (attrib!=Address_Null && GetClientAttribValue(client, attribname) > 0.0)
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

stock float GetClientAttribValue(client, const char[] attribname)
{
	if (IsValidClient(client))
	{
		new Float:AttribValue = 1.0;
		new Address:Attrib = TF2Attrib_GetByName(client, attribname);
		
		if (Attrib != Address_Null)
		{
			AttribValue = TF2Attrib_GetValue(Attrib);
			
			return AttribValue;
		}
		else{return AttribValue;}
	}
	else{return 0.0;}
}

stock Abilities_AttribRegsiter()
{
	TF2EconDynAttribute attrib = new TF2EconDynAttribute();
	
	attrib.SetName("empowerment");
	attrib.SetClass("abilities.empowerment");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("bloodmoon");
	attrib.SetClass("abilities.bloodmoon");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("fireball");
	attrib.SetClass("abilities_spells.fireball");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("bats");
	attrib.SetClass("abilities_spells.bats");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("meteor Shower");
	attrib.SetClass("abilities_spells.meteor_shower");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("precision");
	attrib.SetClass("abilities_powerups.precision");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();

	attrib.SetName("resistance");
	attrib.SetClass("abilities_powerups.resistance");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("knockout");
	attrib.SetClass("abilities_powerups.knockout");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("reflect");
	attrib.SetClass("abilities_powerups.reflect");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("king");
	attrib.SetClass("abilities_powerups.king");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("agility");
	attrib.SetClass("abilities_powerups.agility");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("supernova");
	attrib.SetClass("abilities_powerups.supernova");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("plague");
	attrib.SetClass("abilities_powerups.plague");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	attrib.SetName("vampire");
	attrib.SetClass("abilities_powerups.vampire");
	attrib.SetDescriptionFormat("value_is_additive");
	attrib.Register();
	
	delete attrib;
}
