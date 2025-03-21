// orion.smx, moreaw2.smx, dota2.smx - v.8.05 -yeah
   
// Global define a la AW2~
// Slots : Primary(0), Secondary(1), Melee(2), PDA(3), PDA2(4) only. From 0 to 4
#define MAXSLOTS                      4
   
// Sounds / Models.
#define SOUND_EXPLOSION               "weapons/rocket_blackbox_explode3.wav"
#define SOUND_TBASH                   "weapons/samurai/tf_marked_for_death_impact_03.wav"
#define SOUND_UBER                    "player/invulnerable_on.wav"
#define SOUND_READY                   "player/recharged.wav"
#define SOUND_NOTREADY                  "replay/record_fail.wav" // This is the wanted sound, I just didn't find it anywhere else.
#define SOUND_DRINK                   "player/pl_scout_dodge_can_drink.wav"
#define SOUND_IMPACT_A                "physics/surfaces/underwater_impact_bullet1.wav"
#define SOUND_IMPACT_B                "physics/surfaces/underwater_impact_bullet2.wav"
#define SOUND_IMPACT_C                "physics/surfaces/underwater_impact_bullet3.wav"
#define SOUND_CHARGE_STICKYBOMB       "weapons/stickybomblauncher_charge_up.wav"
#define SOUND_SAPPER_BREAK            "weapons/sapper_removed.wav"
#define SOUND_STICKYEXPLOSION         "weapons/pipe_bomb3.wav"
#define SOUND_STICKYDETONATE          "weapons/stickybomblauncher_det.wav"
#define SOUND_GRENADE                 "weapons/grenade_launcher_shoot.wav"
#define SOUND_BBASH                   "weapons/halloween_boss/knight_axe_miss.wav"
#define SOUND_RADIANCE                "weapons/3rd_degree_hit_04.wav"
#define SOUND_REFLECT                 "weapons/samurai/tf_katana_06.wav"
#define SOUND_WEAPON_SHOTGUN          "weapons/shotgun_shoot.wav"
#define SOUND_VO_HEAVY_I_LIVE         "vo/heavy_battlecry06.mp3"
#define SOUND_SHIELD_BREAK            "player/spy_shield_break.wav"
#define MDL_BOMBLET                   "models/weapons/w_models/w_grenade_pipebomb.mdl"
//#define PARTICLE_ELECTRICITY          "electrocuted_blue"
#define PARTICLE_ZEUS                 "wrenchmotron_teleport_beam"
//#define PARTICLE_EXPLOSION_SMOKE            "bombinomicon_burning_piece_halloween"
//#define PARTICLE_EXPLOSION_FLASH            "Explosion_Flash_1"
//#define PARTICLE_EXPLOSION_BUBBLES          "Explosion_bubbles"

stock String:s_strMiniCritDeal[][PLATFORM_MAX_PATH] = {
    "player/crit_hit_mini.wav",
    "player/crit_hit_mini2.wav",
    "player/crit_hit_mini3.wav",
    "player/crit_hit_mini4.wav",
    "player/crit_hit_mini5.wav"
};
stock String:s_strCritTake[][PLATFORM_MAX_PATH] = {
    "player/crit_recieved1.wav",
    "player/crit_recieved2.wav",
    "player/crit_recieved3.wav"
};
stock String:g_strSoundExplosionBox[][PLATFORM_MAX_PATH] = {
    "weapons/rocket_blackbox_explode1.wav",
    "weapons/rocket_blackbox_explode2.wav",
    "weapons/rocket_blackbox_explode3.wav"
};


// DealDamage.
#define TF_DMG_GENERIC                      0
#define TF_DMG_CRUSH                        (1 << 0)
#define TF_DMG_BULLET                       (1 << 1)
#define TF_DMG_BLEED                        (1 << 2)
#define TF_DMG_BLAST                        (1 << 6)
#define TF_DMG_PREVENT_PHYSICS_FORCE        (1 << 11)
#define TF_DMG_ALWAYSGIB                    (1 << 13)
#define TF_DMG_CRIT                         (1 << 20)
#define TF_DMG_FIRE                         (1 << 24)
#define TF_DMG_AFTERBURN                    TF_DMG_PREVENT_PHYSICS_FORCE | (1 << 3)
#define TF_DMG_FLAMETHROWER                 TF_DMG_PREVENT_PHYSICS_FORCE | TF_DMG_FIRE
#define TF_DMG_FLAMETHROWER_CRIT            TF_DMG_FLAMETHROWER | TF_DMG_CRIT
#define TF_DMG_FLARE                        TF_DMG_FIRE | TF_DMG_BULLET
#define TF_DMG_FLARE_CRIT                   TF_DMG_FLARE | TF_DMG_CRIT
#define TF_DMG_REVOLVER                     (1 << 21) | TF_DMG_BULLET
#define TF_DMG_REVOLVER_CRIT                TF_DMG_REVOLVER | TF_DMG_CRIT
#define TF_DMG_RIFLE                        TF_DMG_BULLET
#define TF_DMG_RIFLE_CHARGED                (1 << 25) | TF_DMG_BULLET
#define TF_DMG_RIFLE_CRIT                   TF_DMG_RIFLE_CHARGED | TF_DMG_CRIT
#define TF_DMG_MELEE                        (1 << 27) | (1 << 12) | (1 << 7)
#define TF_DMG_MELEE_CRIT                   TF_DMG_MELEE | TF_DMG_CRIT
#define TF_DMG_DELAY                        (1 << 30)
#define TF_DMG_RADIANCE                     (1 << 8)

// Global stuff.
stock Handle:m_hGetPlayerMaxHealth = INVALID_HANDLE;

enum
{
    s_bGlowEnabled = 0,
    s_bBool
};
stock bool:s_bBools[MAXPLAYERS + 1][s_bBool];

public OnMapStart()
{
    PrecacheSound(SOUND_EXPLOSION);
    PrecacheSound(SOUND_TBASH);
    PrecacheSound(SOUND_UBER);
    PrecacheSound(SOUND_READY);
    PrecacheSound(SOUND_NOTREADY);
    PrecacheSound(SOUND_DRINK);
    PrecacheSound(SOUND_IMPACT_A);
    PrecacheSound(SOUND_IMPACT_B);
    PrecacheSound(SOUND_IMPACT_C);
    PrecacheSound(SOUND_CHARGE_STICKYBOMB);
    PrecacheSound(SOUND_STICKYDETONATE);
    PrecacheSound(SOUND_STICKYEXPLOSION);
    PrecacheSound(SOUND_GRENADE);
    PrecacheSound(SOUND_BBASH);
    PrecacheSound(SOUND_RADIANCE);
    PrecacheSound(SOUND_REFLECT);
    PrecacheSound(SOUND_VO_HEAVY_I_LIVE);
    PrecacheSound(SOUND_SHIELD_BREAK);
    PrecacheModel(MDL_BOMBLET);
//  PrecacheParticle(PARTICLE_ELECTRICITY);
    PrecacheParticle(PARTICLE_ZEUS);
}
stock TF2_SetHealth(client, NewHealth)
{
    SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
    SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}
stock Float:TF2_GetPlayerUberLevel(client) // Thx AW2
{
    new entity = GetPlayerWeaponSlot(client, 1);
    if (entity > 0)
    {
        new String:strClassname[64];
        GetEntityNetClass(entity, strClassname, sizeof(strClassname));
        if (StrEqual(strClassname, "CWeaponMedigun"))
            return GetEntPropFloat(entity, Prop_Send, "m_flChargeLevel")*100.0;
    }
    return 0.0;
}
stock GetClientMaxHealth(client)
{
    return SDKCall(m_hGetPlayerMaxHealth, client);
}
stock GetClientMetal(client) // Thx Nergal.
{
    return GetEntProp(client, Prop_Data, "m_iAmmo", 4, 3);
}
stock SetClientMetal(client, NewMetal) // Thx Nergal.
{
    if (NewMetal < 0) NewMetal = 0;
    if (NewMetal > 200) NewMetal = 200;
    SetEntProp(client, Prop_Data, "m_iAmmo", NewMetal, 4, 3);
}
stock Float:GetClientMovementSpeed(client)
{
    return GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
}
//Not used, because this can broke easily.
//stock Float:SetClientMovementSpeed(client, NewMoveSpeed)
//{
//    SetEntProp(client, Prop_Send, "m_flMaxspeed", NewMoveSpeed);
//}
stock GetClientMaxOverHeal(client)
{
    new Health = GetClientMaxHealth(client);
    return RoundFloat(float(Health)*1.5);
}
stock TF2_SetPlayerUberLevel(client, Float:level)
{
    new entity = GetPlayerWeaponSlot(client, 1);
    if (entity > 0) {
        new String:strClassname[64];
        GetEntityNetClass(entity, strClassname, sizeof(strClassname));
        if (StrEqual(strClassname, "CWeaponMedigun"))
        {
            if (level < 0.0) level = 0.0;
            if (level > 100.0) level = 100.0;
            SetEntPropFloat(entity, Prop_Send, "m_flChargeLevel", level / 100.0);
        }
    }
}
stock bool:IsValidClient(client, bool:replaycheck = true)
{
    if (client <= 0 || client > MaxClients) return false;
    if (!IsClientInGame(client)) return false;
    if (!IsClientConnected(client)) return false;
    if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
    if (replaycheck)
    {
        if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
    }
    return true;
}
stock GetVelocity(client, Float:vVector[3]) // Thx Advanced Weaponiser
{
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVector);
}
stock EmitSoundFromOrigin(const String:sound[],const Float:orig[3]) // Thx Advanced Weaponiser
{
    EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}
stock ReleaseUbercharge(client) // Thx Advanced Weaponiser
{
    new entity = GetPlayerWeaponSlot(client, 1);
    if (entity > 0)
    {
        new String:strClassname[64];
        GetEntityNetClass(entity, strClassname, sizeof(strClassname));
        if (StrEqual(strClassname, "CWeaponMedigun"))
        {
            SetEntProp(entity, Prop_Send, "m_bChargeRelease", 1);
        }
    }
}
stock bool:IsUberchargeDeployed(client) // Thx Advanced Weaponiser
{
    new entity = GetPlayerWeaponSlot(client, 1);
    if (entity > 0) {
        new String:strClassname[64];
        GetEntityNetClass(entity, strClassname, sizeof(strClassname));
        if (StrEqual(strClassname, "CWeaponMedigun"))
        {
            new released = GetEntProp(entity, Prop_Send, "m_bChargeRelease");
            if (released > 0) return true;
        }
    }
    return false;
}
stock StopTheUbercharge(client)
{
    new entity = GetPlayerWeaponSlot(client, 1);
    if (entity > 0)
    {
        new String:strClassname[64];
        GetEntityNetClass(entity, strClassname, sizeof(strClassname));
        if (StrEqual(strClassname, "CWeaponMedigun"))
        {
            SetEntProp(entity, Prop_Send, "m_bChargeRelease", 0);
        }
    }
}
public Action:RemoveBody(Handle:timer, any:client)
{
    new iBodyRagdoll;
    iBodyRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");

    if(IsValidEdict(iBodyRagdoll)) RemoveEdict(iBodyRagdoll);
}

public Action:RemoveGibs(Handle:timer, any:ent)
{
    if(IsValidEntity(ent))
    {
        decl String:sClassname[64];
        GetEdictClassname(ent, sClassname, sizeof(sClassname));

        if(StrEqual(sClassname, "tf_ragdoll", false))
        {
            RemoveEdict(ent);
        }
    }
}
public bool:TraceEntityFilterPlayer(entity, contentsMask) // Thx RavensBro.
{
    return entity > GetMaxClients() || !entity;
}
stock Float:GetVectorDistanceMeter(const Float:vec1[3], const Float:vec2[3], bool:squared=false) // Thx RavensBro.
{
    return ( GetVectorDistance( vec1, vec2, squared ) / 50.00 );
}
stock SetAmmo(client, slot, newAmmo) //Thx FlaminSarge
{
    new weapon = GetPlayerWeaponSlot(client, slot);
    if (!IsValidEntity(weapon)) return;
    new type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if (type < 0 || type > 32) return;
    SetEntProp(client, Prop_Send, "m_iAmmo", newAmmo, _, type);
}
stock GetAmmo(client, slot)
{
    if (!IsValidClient(client)) return 0;
    new weapon = GetPlayerWeaponSlot(client, slot);
    if (!IsValidEntity(weapon)) return 0;
    new type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if (type < 0 || type > 32) return 0;
    return GetEntProp(client, Prop_Send, "m_iAmmo", _, type);
}
stock SpawnThing(String:entity[32]="", Float:duration, victim, team)
{
    new ent = CreateEntityByName(entity);
    if (IsValidEntity(ent))
    {
        DispatchSpawn(ent);
	
        if (StrEqual(entity, "tf_zombie_spawner")) {
            SetEntProp(ent, Prop_Data, "m_nSkeletonType", 1);
            AcceptEntityInput(ent, "Enable");
        }
        else if (StrEqual(entity, "tf_zombie")) {
            if (team == 2) DispatchKeyValue(ent, "skin", "0");
            else if (team == 3) DispatchKeyValue(ent, "skin", "1");
            SetEntProp(ent, Prop_Send, "m_iTeamNum", team);
        }
        else if (StrEqual(entity, "eyeball_boss")) SetEntProp(ent, Prop_Data, "m_iTeamNum", 5);

        new Float:POSi[3];
        GetClientAbsOrigin(victim, POSi);
        TeleportEntity(ent, POSi, NULL_VECTOR, NULL_VECTOR);

        CreateTimer(duration, m_tSpawnSkeletonOnKill_TimerDuration, ent);
    }
}
stock bool:ClearTimer(&Handle:timer, bool:autoClose = false)
{
    if (timer != INVALID_HANDLE)
    {
        KillTimer(timer, autoClose);
        timer = INVALID_HANDLE;
        return true;
    }
    return false;
}
stock bool:IsCritBoosted(client) // Nergal :D
{
    if (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) || TF2_IsPlayerInCondition(client, TFCond_CritCanteen) || TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin) || TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) || TF2_IsPlayerInCondition(client, TFCond_CritOnKill) || TF2_IsPlayerInCondition(client, TFCond_CritMmmph) || TF2_IsPlayerInCondition(client, TFCond_CritOnDamage))
    {
        return true;
    }
    return false;
}
stock bool:IsValidClient2(client, attacker) // Nergal :D
{
    if (!IsValidClient(client)) return false;
    if (TF2_IsPlayerInCondition(client, TFCond_Ubercharged)) return false;
    if (GetClientTeam(attacker) == GetClientTeam(client)) return false;
    if (attacker == client) return false;

    return true;
}
stock bool:IsValidEntity2(ent, attacker) // Nergal :D
{
    if (!IsValidEntity(ent)) return false;
    if (attacker == ent) return false;

    return true;
}
stock SetClientSlot(client, slot)
{
    if (!IsValidClient(client)) return;
    if (!IsPlayerAlive(client)) return;

    new weapon = GetPlayerWeaponSlot(client, slot);

    SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
    
    TF2_RemoveCondition(client, TFCond_Slowed);
    TF2_RemoveCondition(client, TFCond_Zoomed);
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
            AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
            DispatchKeyValue(pointHurt,"classname","point_hurt");
            DispatchKeyValue(victim,"targetname","war3_donthurtme");
            RemoveEdict(pointHurt);
        }
    }
}
stock GetMax(const iValA, const iValB) // Thanks 11530
{
  return (iValA < iValB ? iValB : iValA);
}
stock SetHomingProjectile(client, const String:classname[], const Float:detect) // Thanks Tylerst
{
    new entity = -1; 
    while((entity = FindEntityByClassname(entity, classname))!=INVALID_ENT_REFERENCE)
    {
        if (entity == -1) continue;
        new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
        if (StrEqual(classname, "tf_projectile_sentryrocket", false)) owner = GetEntPropEnt(owner, Prop_Send, "m_hBuilder");
        if (!IsValidEntity(owner)) continue;        
        new Target = GetClosestTarget(entity, owner);
        if (!Target) continue;
        if (owner == client)
        {
            new Float:EntityPos[3];
            GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", EntityPos);
            new Float:TargetPos[3];
            GetClientAbsOrigin(Target, TargetPos);
            new Float:distance = GetVectorDistance(EntityPos, TargetPos);
            if(distance < detect)
            {
                new Float:ProjLocation[3], Float:ProjVector[3], Float:ProjSpeed, Float:ProjAngle[3], Float:TargetLocation[3], Float:AimVector[3];           
                GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", ProjLocation);
                GetClientAbsOrigin(Target, TargetLocation);
                TargetLocation[2] += 40.0;
                MakeVectorFromPoints(ProjLocation, TargetLocation , AimVector);
                GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", ProjVector);                    
                ProjSpeed = GetVectorLength(ProjVector);                    
                AddVectors(ProjVector, AimVector, ProjVector);  
                NormalizeVector(ProjVector, ProjVector);
                GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
                GetVectorAngles(ProjVector, ProjAngle);
                SetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);                    
                ScaleVector(ProjVector, ProjSpeed);
                SetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", ProjVector);
            }
        }
    }   
}
stock GetClosestTarget(entity, owner)
{
    new Float:TargetDistance = 0.0;
    new ClosestTarget = 0;
    for(new i = 1; i <= MaxClients; i++) 
    {
        if (!IsValidClient(owner) || !IsValidClient(i) || !IsPlayerAlive(i) || i == owner || (GetClientTeam(owner) == GetClientTeam(i))) continue;
        if (TF2_IsPlayerInCondition(i, TFCond_Cloaked)) continue;
        if (TF2_IsPlayerInCondition(i, TFCond_Ubercharged)) continue;
        if (TF2_IsPlayerInCondition(i, TFCond_Bonked)) continue;
        if (TF2_IsPlayerInCondition(i, TFCond_Stealthed)) continue;
        if (TF2_IsPlayerInCondition(i, TFCond_StealthedUserBuffFade)) continue;
        if (TF2_IsPlayerInCondition(i, TFCond_BlastImmune)) continue;
        if (TF2_IsPlayerInCondition(i, TFCond_HalloweenGhostMode)) continue;
        new iTeam = GetEntProp(entity, Prop_Send, "m_iTeamNum");
        if (TF2_IsPlayerInCondition(i, TFCond_Disguised) && GetEntProp(i, Prop_Send, "m_nDisguiseTeam") == iTeam) continue;
        new Float:EntityLocation[3], Float:TargetLocation[3];
        GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", EntityLocation);
        GetClientAbsOrigin(i, TargetLocation);
        
        new Handle:hTrace = TR_TraceRayFilterEx(TargetLocation, EntityLocation, MASK_SOLID, RayType_EndPoint, TraceFilterHoming, entity);
        if(hTrace != INVALID_HANDLE)
        {
            if(TR_DidHit(hTrace))
            {
                CloseHandle(hTrace);
                continue;
            }
            
            CloseHandle(hTrace);
            
            new Float:distance = GetVectorDistance(EntityLocation, TargetLocation);
            if(TargetDistance) {
                if(distance < TargetDistance) {
                    ClosestTarget = i;
                    TargetDistance = distance;          
            }} else {
                ClosestTarget = i;
                TargetDistance = distance;
            }
        }
    }
    return ClosestTarget;
}
public bool:TraceFilterHoming(entity, contentsMask, any:proj) {
    if(entity == proj || (entity >= 1 && entity <= MaxClients)) return false;

    return true;
}
stock ShowText(client, String:text[]="") {
    decl Float:vOrigin[3];
    GetClientEyePosition(client, vOrigin);
    vOrigin[2] += 2.0;

    new particle = CreateEntityByName("info_particle_system");
    if (IsValidEntity(particle))
    {
        TeleportEntity(particle, vOrigin, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", text);
        DispatchSpawn(particle);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        SetVariantString("OnUser1 !self:Kill::8:-1");
        AcceptEntityInput(particle, "AddOutput");
        AcceptEntityInput(particle, "FireUser1");
    }
}
stock bool:ShouldReveal(client) {
    if (TF2_IsPlayerInCondition(client, TFCond_Cloaked)) return true;
    if (TF2_IsPlayerInCondition(client, TFCond_Disguised)) return false;
    return true;
}
stock GetClientSlot(client) {
    if(!IsValidClient(client)) return -1;
    if(!IsPlayerAlive(client)) return -1;
    
    new slot = GetWeaponSlot(client, GetClientActiveWeapon(client));
    return slot;
}
stock GetWeaponSlot(client, weapon) {
    for(new i = 0; i < 7; i++) {
        if(weapon == GetPlayerWeaponSlot(client, i)) return i;
    }
    return -1;
}
stock GetClientActiveWeapon(client) {
    new weapon =  GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
    
    if (!IsValidEntity(weapon)) return INVALID_ENT_REFERENCE;
    return weapon;
}
stock SpawnBombz(m_iClient, m_iEnt, bool:m_bCritical = false, m_iCount = 0, Float:m_flDamage = 100.0, Float:m_flRadius = 196.0)
{
    new clientteam = GetClientTeam(m_iClient);         //Throwers team

    new Float:pos[3];
    GetEntPropVector(m_iEnt, Prop_Send, "m_vecOrigin", pos);
    EmitSoundFromOrigin(SOUND_STICKYDETONATE, pos);
    
    decl Float:g_angles[3], Float:g_angles2[3];     //Rotate sticky a bit when it shoots a bomblet
    GetEntPropVector(m_iEnt, Prop_Send, "m_angRotation", g_angles);

    g_angles2[0] = (g_angles[0] += GetRandomFloat(5.0,45.0));
    g_angles2[1] = (g_angles[1] += GetRandomFloat(5.0,45.0));
    g_angles2[2] = (g_angles[2] += GetRandomFloat(5.0,45.0));
        
    for (new i = 1; i <= m_iCount; i++)
    {
        decl Float:m_flAngle[3];
        m_flAngle[0] = GetRandomFloat(-196.0-(m_iCount/2), 196.0+m_iCount/2);       //Left, Right
        m_flAngle[1] = GetRandomFloat(-196.0-(m_iCount/2), 196.0+m_iCount/2);       //Forward, Back
        m_flAngle[2] = GetRandomFloat(196.0+m_iCount, 510.0+m_iCount);      //Up, Down
        
        new pitch = 150;
        new Float:volume = 0.5;
        EmitAmbientSound(SOUND_GRENADE, pos, m_iEnt, _, _, volume, pitch);
        
        new ent2 = CreateEntityByName("tf_projectile_pipe");
        
        if(ent2 != -1)
        {
            SetEntPropEnt(ent2, Prop_Data, "m_hThrower", m_iClient);
            SetEntProp(ent2, Prop_Send, "m_iTeamNum", clientteam);
            if (m_bCritical) SetEntProp(ent2, Prop_Send, "m_bCritical", true);
            SetEntPropFloat(ent2, Prop_Send, "m_flModelScale", 0.5);
            SetEntPropFloat(ent2, Prop_Send, "m_DmgRadius", m_flRadius);
            SetEntPropFloat(ent2, Prop_Send, "m_flDamage", m_flDamage);
            
            DispatchSpawn(ent2);
                
            SetEntityModel(ent2, MDL_BOMBLET);
                
            TeleportEntity(ent2, pos, NULL_VECTOR, m_flAngle);
            TeleportEntity(m_iEnt, NULL_VECTOR, g_angles2, NULL_VECTOR);  
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
stock SetWeaponAmmo(client, slot, ammo = -1, ammo2 = -1) {
    new weapon = GetPlayerWeaponSlot(client, slot);
    if(IsValidEntity(weapon)) {
        if (ammo >= 0) SetEntData(client,FindSendPropOffs("CTFPlayer", "m_iAmmo")+4,ammo);
        if (ammo2 >= 0) SetEntData(weapon,FindSendPropOffs("CBaseCombatWeapon", "m_iClip1"),ammo2,4);
    }
}
stock PrecacheParticle(String:name[]) {
    if(IsValidEntity(0))
    {
        new particle = CreateEntityByName("info_particle_system");
        if (IsValidEdict(particle)) {
            new String:tName[32];
            GetEntPropString(0, Prop_Data, "m_iName", tName, sizeof(tName));
            DispatchKeyValue(particle, "targetname", "tf2particle");
            DispatchKeyValue(particle, "parentname", tName);
            DispatchKeyValue(particle, "effect_name", name);
            DispatchSpawn(particle);
            SetVariantString(tName);
            AcceptEntityInput(particle, "SetParent", 0, particle, 0);
            ActivateEntity(particle);
            AcceptEntityInput(particle, "start");
            CreateTimer(0.01, RemoveParticle, particle);
        }
    }
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
stock AnglesToVelocity(Float:fAngle[3], Float:fVelocity[3], Float:fSpeed = 1.0) {
    fVelocity[0] = Cosine(DegToRad(fAngle[1]));
    fVelocity[1] = Sine(DegToRad(fAngle[1]));
    fVelocity[2] = Sine(DegToRad(fAngle[0])) * -1.0;
    
    NormalizeVector(fVelocity, fVelocity);
    
    ScaleVector(fVelocity, fSpeed);
}
stock bool:DamageWillKill(client, Float:damage, bool:beSure = false) {
    new health = GetClientHealth(client);
    new Damage = RoundFloat(damage);
    if (beSure) Damage += 5;
    if (Damage >= health) return true;
    return false;
}
stock Float:HealPlayer(target, Float:healed, Float:newOverheal = 1.0)
{
    new Float:healing;
    healing += healed;
    if (healing >= 1.0)
    {
        new heal = RoundToFloor(healing);
        if (heal >= 1)
        {
            healing -= float(heal);
            new health = GetClientHealth(target);
            new overheal = RoundFloat(GetClientMaxHealth(target) * (1.5 * newOverheal));
            if (health <= overheal)
            {
                health += heal;
                if (health > overheal) health = overheal;
                SetEntityHealth(target, health);
            }
        }
    }
}
stock GetHealTarget(client) {
    if(!IsValidClient(client)) return -1;
    if(TF2_GetPlayerClass(client) != TFClass_Medic) return -1;
    
    new iWeapon = GetPlayerWeaponSlot(client, 1);
    if (iWeapon == -1) return -1;
    if (!IsValidEdict(iWeapon)) return -1;
        
    new String:strClassname[64];
    GetEdictClassname(iWeapon, strClassname, 64);
    if(!StrEqual(strClassname, "tf_weapon_medigun"))
        return -1;
    
    return GetEntDataEnt2(iWeapon, FindSendPropInfo("CWeaponMedigun", "m_hHealingTarget"));
}