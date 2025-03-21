//Overshield Functions

new Float:fl_Overshield[MAXPLAYERS+1] = 0.0;
new Float:fl_CurrentOverShield[MAXPLAYERS+1] = 0.0;

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

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}


public bool:TraceEntityFilterPlayer(entity, contentsMask) // Thx RavensBro.
{
    return entity > GetMaxClients() || !entity;
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

stock EmitSoundFromOrigin(const String:sound[],const Float:orig[3]) // Thx Advanced Weaponiser
{
    EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}

#define SOUND_EXPLO	"weapons/explode1.wav"

public OnMapStart()
{
	PrecacheSound(SOUND_EXPLO);
}