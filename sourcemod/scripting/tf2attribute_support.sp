/**
 * TF2 Attribute Extended Support plugin
 * 
 * Certain combinations of attributes and weapons just don't work.  This plugin intends to fix
 * the known problematic combinations so modders can apply game attributes for their own uses.
 */
#pragma semicolon 1
#include <sourcemod>

#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#include <stocksoup/memory>
#include <stocksoup/tf/entity_prop_stocks>
#include <stocksoup/tf/tempents_stocks>
#include <stocksoup/tf/weapon>

#pragma newdecls required

#include <sourcescramble>
#include <tf2attributes>
#include <tf2utils>

#define PLUGIN_VERSION "1.13.0"
public Plugin myinfo = {
	name = "[TF2] TF2 Attribute Extended Support",
	author = "nosoop",
	description = "Improves support for game attributes on weapons.",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/SM-TFAttributeSupport"
}

Handle g_DHookBaseEntityGetDamage;
Handle g_DHookWeaponSendAnim;
Handle g_DHookGrenadeInit;
Handle g_DHookGrenadeGetDamageRadius;
Handle g_DHookWeaponGetProjectileSpeed;
Handle g_DHookFireJar;
Handle g_DHookRocketExplode;

Handle g_DHookPlayerRegenerate;

Handle g_SDKCallBaseWeaponSendAnim;
Handle g_SDKCallInitGrenade;
Handle g_SDKCallInternalGetEffectBarRechargeTime;

Handle g_SDKCallGetWeaponAfterburnRate;

int voffs_SendWeaponAnim;

int offs_CGameTrace_pEnt;

#define TF_ITEMDEF_FORCE_A_NATURE                45
#define TF_ITEMDEF_FORCE_A_NATURE_FESTIVE        1078

// this is dynamically set based on CTFWeaponInfo::m_flDamageRadius, but we'll just define it
#define TF_DMGRADIUS_GRENADE_LAUNCHER            146.0

#define DEFAULT_REQUIRED_DEPLOY_FOR_AIR_DASH     0.7

#define ITEM_METER_CHARGE_OVER_TIME (1 << 0)
#define ITEM_METER_CHARGE_BY_DAMAGE (1 << 1)

float g_flAirDashDeployTime;

enum eTFProjectileOverride {
	Projectile_NoOverride,
	Projectile_Bullet = 1,
	Projectile_Rocket = 2,
	Projectile_Pipebomb = 3,
	Projectile_Stickybomb = 4,
	Projectile_Syringe = 5,
	Projectile_Flare = 6,
	Projectile_Jar = 7,
	Projectile_Arrow = 8,
	Projectile_FlameRocket = 9, // late addition?
	Projectile_JarMilk = 10,
	Projectile_CrossbowBolt = 11,
	Projectile_EnergyBall = 12,
	Projectile_EnergyRing = 13,
	Projectile_TrainingSticky = 14,
	Projectile_Cleaver = 15,
	// 16 is not referecned in ::FireProjectile
	Projectile_Cannonball = 17,
	Projectile_RescueClaw = 18,
	Projectile_ArrowFestive = 19,
	Projectile_Spellbook = 20,
	// 21 is not referenced in ::FireProjectile
	Projectile_JarFestive = 22,
	Projectile_CrossbowBoltFestive = 23,
	Projectile_JarBread = 24,
	Projectile_JarMilkBread = 25,
	Projectile_GrapplingHook = 26,
	Projectile_JarGas = 29,
}

enum MeterType {
	Meter_Invalid,
	Meter_PlayerCloakMeter,
	Meter_PlayerChargeMeter,
	
	Meter_WeaponEffectBar,
}

enum struct MeterInfo {
	MeterType m_MeterType;
	int m_hWeapon;
	
	// normalized to 0.0 -> 1.0
	float m_flValue;
}

ArrayList g_SavedMeters[MAXPLAYERS + 1];

public void OnPluginStart() {
	Handle hGameConf = LoadGameConfigFile("tf2.attribute_support");
	if (!hGameConf) {
		SetFailState("Failed to load gamedata (tf2.attribute_support).");
	}
	
	g_DHookBaseEntityGetDamage = DHookCreateFromConf(hGameConf, "CBaseEntity::GetDamage()");
	
	voffs_SendWeaponAnim = GameConfGetOffset(hGameConf, "CBaseCombatWeapon::SendWeaponAnim()");
	g_DHookWeaponSendAnim = DHookCreateFromConf(hGameConf,
			"CBaseCombatWeapon::SendWeaponAnim()");
	
	g_DHookGrenadeGetDamageRadius = DHookCreateFromConf(hGameConf,
			"CBaseGrenade::GetDamageRadius()");
	
	g_DHookWeaponGetProjectileSpeed = DHookCreateFromConf(hGameConf,
			"CTFWeaponBaseGun::GetProjectileSpeed()");
	
	g_DHookFireJar = DHookCreateFromConf(hGameConf, "CTFWeaponBaseGun::FireJar()");
	
	g_DHookRocketExplode = DHookCreateFromConf(hGameConf, "CTFBaseRocket::Explode()");
	
	g_DHookGrenadeInit = DHookCreateFromConf(hGameConf,
			"CTFWeaponBaseGrenadeProj::InitGrenade(int float)");
	
	g_DHookPlayerRegenerate = DHookCreateFromConf(hGameConf, "CTFPlayer::Regenerate()");
	DHookEnableDetour(g_DHookPlayerRegenerate, false, OnPlayerRegeneratePre);
	DHookEnableDetour(g_DHookPlayerRegenerate, true, OnPlayerRegeneratePost);
	
	Handle dtPlayerCanAirDash = DHookCreateFromConf(hGameConf, "CTFPlayer::CanAirDash()");
	if (!dtPlayerCanAirDash) {
		SetFailState("Failed to create detour " ... "CTFPlayer::CanAirDash()");
	}
	DHookEnableDetour(dtPlayerCanAirDash, false, OnPlayerCanAirDashPre);
	
	Handle dtSharedPlayerRemoveAttribute = DHookCreateFromConf(hGameConf,
			"CTFPlayerShared::RemoveAttributeFromPlayer()");
	if (!dtSharedPlayerRemoveAttribute) {
		SetFailState("Failed to create detour CTFPlayerShared::RemoveAttributeFromPlayer()");
	}
	DHookEnableDetour(dtSharedPlayerRemoveAttribute, true, OnPlayerAttributesChangedPost);
	
	Handle dtSharedPlayerApplyAttribute = DHookCreateFromConf(hGameConf,
			"CTFPlayerShared::ApplyAttributeToPlayer()");
	if (!dtSharedPlayerApplyAttribute) {
		SetFailState("Failed to create detour CTFPlayerShared::ApplyAttributeToPlayer()");
	}
	// while we could (should?) handle the apply side in tf2attributes, it doesn't have any
	// knowledge of player equipment nor the speed refresh logic.  so we might as well put both
	// of them here for consistency's sake
	DHookEnableDetour(dtSharedPlayerApplyAttribute, true, OnPlayerAttributesChangedPost);
	
	Handle dtWeaponBaseVMFlipped = DHookCreateFromConf(hGameConf,
			"CTFWeaponBase::IsViewModelFlipped()");
	if (!dtWeaponBaseVMFlipped) {
		SetFailState("Failed to create detour " ... "CTFWeaponBase::IsViewModelFlipped()");
	}
	DHookEnableDetour(dtWeaponBaseVMFlipped, true, OnWeaponBaseVMFlippedPost);
	
	Handle dtWeaponBaseGunZoomIn = DHookCreateFromConf(hGameConf, "CTFWeaponBaseGun::ZoomIn()");
	if (!dtWeaponBaseGunZoomIn) {
		SetFailState("Failed to create detour " ... "CTFWeaponBaseGun::ZoomIn()");
	}
	DHookEnableDetour(dtWeaponBaseGunZoomIn, true, OnWeaponBaseGunZoomInPost);
	
	Handle dtWeaponBaseMeleeSwingHit = DHookCreateFromConf(hGameConf,
			"CTFWeaponBaseMelee::OnSwingHit()");
	if (!dtWeaponBaseMeleeSwingHit) {
		SetFailState("Failed to create detour " ... "CTFWeaponBaseMelee::OnSwingHit()");
	}
	DHookEnableDetour(dtWeaponBaseMeleeSwingHit, false, OnWeaponBaseMeleeSwingHitPre);
	
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual,
			"CTFWeaponBaseGrenadeProj::InitGrenade(int float)");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	g_SDKCallInitGrenade = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual,
			"CTFWeaponBase::InternalGetEffectBarRechargeTime()");
	PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
	g_SDKCallInternalGetEffectBarRechargeTime = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual,
			"CTFWeaponBase::GetAfterburnRateOnHit()");
	PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
	g_SDKCallGetWeaponAfterburnRate = EndPrepSDKCall();
	
	/*
	MemoryPatch patchAirDashDeployTime = MemoryPatch.CreateFromConf(hGameConf,
			"CTFPlayer::CanAirDash()::PatchRequiredDeployTime");
	if (!patchAirDashDeployTime.Validate()) {
		SetFailState("Failed to validate patch "
				... "CTFPlayer::CanAirDash()::PatchRequiredDeployTime");
	}
	patchAirDashDeployTime.Enable();
	
	
	Address ppValue = patchAirDashDeployTime.Address + view_as<Address>(4);
	Address pValue = DereferencePointer(ppValue);
	float value = view_as<float>(LoadFromAddress(pValue, NumberType_Int32));
	if (value != DEFAULT_REQUIRED_DEPLOY_FOR_AIR_DASH) {
		SetFailState("Unexpected value being overwritten for "
				... "CTFPlayer::CanAirDash()::PatchRequiredDeployTime "
				... "(expected %.2f, got %.2f / %08x)", DEFAULT_REQUIRED_DEPLOY_FOR_AIR_DASH,
				value, value);
	}
	g_flAirDashDeployTime = value;
	
	StoreToAddress(ppValue, view_as<any>(GetAddressOfCell(g_flAirDashDeployTime)),
			NumberType_Int32);
	*/
	offs_CGameTrace_pEnt = GameConfGetOffset(hGameConf, "CGameTrace::m_pEnt");
	if (offs_CGameTrace_pEnt <= 0) {
		SetFailState("Failed to determine offset of " ... "CGameTrace::m_pEnt");
	}
	
	delete hGameConf;
	
	for (int i = 1; i <= MaxClients; i++) {
		g_SavedMeters[i] = new ArrayList(sizeof(MeterInfo));
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnMapStart() {
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1) {
		if (!IsValidEdict(entity)) {
			continue;
		}
		
		if (TF2Util_IsEntityWeapon(entity)) {
			HookWeaponBase(entity);
		}
		if (IsWeaponBaseGun(entity)) {
			char className[64];
			GetEntityClassname(entity, className, sizeof(className));
			HookWeaponBaseGun(entity, className);
		}
	}
	
	// get the address of CTFWeaponBase::SendWeaponAnim() directly
	if (!g_SDKCallBaseWeaponSendAnim) {
		int shotgun = CreateEntityByName("tf_weapon_shotgun_primary");
		
		Address vmt = DereferencePointer(GetEntityAddress(shotgun));
		Address pfnBaseWeaponSendAnim = DereferencePointer(
				vmt + view_as<Address>(4 * voffs_SendWeaponAnim));
		
		RemoveEntity(shotgun);
		
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetAddress(pfnBaseWeaponSendAnim);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_SDKCallBaseWeaponSendAnim = EndPrepSDKCall();
		
		if (!g_SDKCallBaseWeaponSendAnim) {
			SetFailState("Failed to determine address of CBaseCombatWeapon::SendWeaponAnim()");
		}
	}
}

public void OnEntityCreated(int entity, const char[] className) {
	if (!IsValidEdict(entity)) {
		return;
	}
	
	if (StrEqual(className, "tf_projectile_energy_ring")) {
		RequestFrame(EnergyRingPostSpawnPost, EntIndexToEntRef(entity));
		
		// this is broken on SM1.10 ??
		DHookEntity(g_DHookBaseEntityGetDamage, true, entity,
				.callback = OnGetEnergyRingDamagePost);
	}
	
	if (strncmp(className, "tf_projectile_jar", strlen("tf_projectile_jar")) == 0) {
		DHookEntity(g_DHookGrenadeGetDamageRadius, true, entity,
				.callback = OnGetGrenadeDamageRadiusPost);
	}
	if (StrEqual(className, "tf_projectile_flare")) {
		DHookEntity(g_DHookRocketExplode, true, entity, .callback = OnRocketExplodePost);
	}
	
	if (TF2Util_IsEntityWeapon(entity)) {
		HookWeaponBase(entity);
		if (IsWeaponBaseGun(entity)) {
			HookWeaponBaseGun(entity, className);
		}
	}
	
	if (strncmp(className, "tf_projectile_pipe", strlen("tf_projectile_pipe")) == 0) {
		// unused. crashes inconsistently, because of course, virtual dhooks
		// DHookEntity(g_DHookGrenadeInit, false, entity, .callback = OnGrenadeInit);
	}
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_SpawnPost, OnClientSpawnPost);
	SDKHook(client, SDKHook_OnTakeDamageAlivePost, OnClientTakeDamageAlivePost);
	SDKHook(client, SDKHook_GroundEntChangedPost, OnClientGroundEntChangedPost);
}

/**
 * Called when the player is finished spawning in (e.g. changing classes).
 * Starts regenerating the effect bar on any items with item_meter_resupply_denied set.
 */
void OnClientSpawnPost(int client) {
	for (int i; i < 3; i++) {
		int weapon = GetPlayerWeaponSlot(client, i);
		if (IsValidEntity(weapon)) {
			PostSpawnUnsetItemCharge(weapon);
		}
	}
}

/**
 * Called when a player takes damage.
 */
void OnClientTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage,
		int damagetype, int weapon, const float damageForce[3], const float damagePosition[3],
		int damagecustom) {
	if (attacker < 1 || attacker >= MaxClients) {
		return;
	}
	
	if (attacker != victim) {
		// attacker gains charge on legacy meters on non-self damage
		for (int i; i < 3; i++) {
			int attackerWeapon = GetPlayerWeaponSlot(attacker, i);
			if (IsValidEntity(attackerWeapon)) {
				// the 'correct' way would be to implement this within `CTFPlayer::OnDamageDealt()`
				ApplyItemChargeDamageModifier(attackerWeapon, damage);
			}
		}
	}
	
	// modify victim burning duration, even on self-hits
	if (damagecustom != TF_CUSTOM_BURNING && IsValidEntity(weapon)
			&& TF2Util_IsEntityWeapon(weapon)) {
		// this should not be triggered on DOT effects
		ApplyItemBurnModifier(weapon, victim);
	}
}

/**
 * Called when the player has left the ground.  Attaches a jump particle to their feet.
 */
void OnClientGroundEntChangedPost(int client) {
	if (!IsPlayerAlive(client) || GetClientButtons(client) & IN_JUMP == 0) {
		return;
	}
	
	if (!IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity"))) {
		return;
	}
	
	if (!TF2Attrib_HookValueInt(0, "bot_custom_jump_particle", client)) {
		return;
	}
	
	int attachLeft = LookupEntityAttachment(client, "foot_L");
	int attachRight = LookupEntityAttachment(client, "foot_R");
	
	if (!attachLeft || !attachRight) {
		// feet attachment points are not on the model
		return;
	}
	
	int pc = view_as<int>(TF2_GetPlayerClass(client));
	TE_SetupTFParticleEffect("rocketjump_smoke", NULL_VECTOR, .entity = client,
			.attachType = PATTACH_POINT_FOLLOW, .attachPoint = attachLeft);
	TE_SendToAll();
	
	TE_SetupTFParticleEffect("rocketjump_smoke", NULL_VECTOR, .entity = client,
			.attachType = PATTACH_POINT_FOLLOW, .attachPoint = attachRight);
	TE_SendToAll();
}

MRESReturn OnPlayerRegeneratePre(int client, Handle hParams) {
	g_SavedMeters[client].Clear();
	
	for (int i; i < 5; i++) {
		int weapon = GetPlayerWeaponSlot(client, i);
		
		if (!IsValidEntity(weapon)) {
			// dumb hack for shield
			weapon = TF2Util_GetPlayerLoadoutEntity(client, i);
		}
		
		if (!IsValidEntity(weapon)) {
			continue;
		}
		
		MeterInfo info;
		info.m_hWeapon = EntIndexToEntRef(weapon);
		
		if (TF2Attrib_HookValueInt(0, "item_meter_resupply_denied", weapon) == 0) {
			// only save the state of the item if value is non-zero
			continue;
		}
		
		info.m_MeterType = GetItemMeterType(weapon);
		switch (info.m_MeterType) {
			case Meter_Invalid: {
				continue;
			}
			case Meter_PlayerChargeMeter: {
				info.m_flValue = GetEntPropFloat(client, Prop_Send, "m_flChargeMeter") / 100.0;
			}
			case Meter_WeaponEffectBar: {
				float flEffectBarRegenTime = GetEntPropFloat(weapon, Prop_Send,
						"m_flEffectBarRegenTime");
				if (TF2_GetWeaponAmmo(info.m_hWeapon)) {
					info.m_flValue = 1.0;
				} else if (flEffectBarRegenTime > 0.0) {
					info.m_flValue = 1.0 - (flEffectBarRegenTime - GetGameTime()) / GetEffectBarRechargeTime(weapon);
				} else {
					info.m_flValue = 1.0;
				}
			}
			case Meter_PlayerCloakMeter: {
				info.m_flValue = GetEntPropFloat(client, Prop_Send, "m_flCloakMeter") / 100.0;
			}
		}
#if defined _DEBUG
		PrintToServer("preserving slot %d / type: %d / value: %f", i, info.m_MeterType, info.m_flValue);
#endif
		g_SavedMeters[client].PushArray(info);
	}
	return MRES_Ignored;
}

/**
 * Called when the player is finished regenerating.
 * Clears ammo granted during regeneration on items with item_meter_resupply_denied set.
 */
MRESReturn OnPlayerRegeneratePost(int client, Handle hParams) {
	bool bRefillHealthAndAmmo = DHookGetParam(hParams, 1);
	if (!bRefillHealthAndAmmo) {
		return;
	}
	
	// restore saved meters
	while (g_SavedMeters[client].Length) {
		MeterInfo info;
		g_SavedMeters[client].GetArray(0, info);
		g_SavedMeters[client].Erase(0);
		
#if defined _DEBUG
		PrintToServer("restoring type: %d / value: %f", info.m_MeterType, info.m_flValue);
#endif
		if (!IsValidEntity(info.m_hWeapon)) {
#if defined _DEBUG
			PrintToServer("weapon not valid");
#endif
			continue;
		}
		
		// not attached to client
		int owner = GetEntPropEnt(info.m_hWeapon, Prop_Send, "m_hOwnerEntity");
		if (owner != client && info.m_MeterType != Meter_PlayerChargeMeter) {
#if defined _DEBUG
			PrintToServer("item not attached");
#endif
			continue;
		}
		
		// restore weapon
		switch (info.m_MeterType) {
			case Meter_PlayerChargeMeter: {
				SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", info.m_flValue * 100.0);
			}
			case Meter_WeaponEffectBar: {
				float flRechargeTime = GetEffectBarRechargeTime(info.m_hWeapon);
				float flSimulatedStartTime = GetGameTime() - (info.m_flValue * flRechargeTime);
				
				SetEntPropFloat(info.m_hWeapon, Prop_Send, "m_flEffectBarRegenTime", flSimulatedStartTime + flRechargeTime);
				SetEntPropFloat(info.m_hWeapon, Prop_Send, "m_flLastFireTime", flSimulatedStartTime);
				
				if (info.m_flValue < 1.0) {
					TF2_SetWeaponAmmo(info.m_hWeapon, 0);
				}
			}
			case Meter_PlayerCloakMeter: {
				SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", info.m_flValue * 100.0);
			}
		}
	}
	
	for (int i; i < 3; i++) {
		int weapon = GetPlayerWeaponSlot(client, i);
		if (IsValidEntity(weapon)) {
			ProcessItemRecharge(weapon);
		}
	}
}

static MRESReturn HookWeaponBase(int entity) {
	// currently stubbed
}

MRESReturn OnPlayerCanAirDashPre(int client) {
	g_flAirDashDeployTime = DEFAULT_REQUIRED_DEPLOY_FOR_AIR_DASH;
	
	int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(activeWeapon)) {
		return MRES_Ignored;
	}
	
	// doesn't quite cover every single deploy time-related attribute, but this will do for now
	g_flAirDashDeployTime *=
			TF2Attrib_HookValueFloat(1.0, "mult_deploy_time", activeWeapon)
			* TF2Attrib_HookValueFloat(1.0, "mult_single_wep_deploy_time", activeWeapon);
	return MRES_Ignored;
}

static void HookWeaponBaseGun(int entity, const char[] className) {
	DHookEntity(g_DHookWeaponGetProjectileSpeed, true, entity,
			.callback = OnGetProjectileSpeedPost);
	
	if (strncmp(className, "tf_weapon_jar", strlen("tf_weapon_jar")) != 0) {
		DHookEntity(g_DHookFireJar, false, entity, .callback = OnFireJarPre);
	}
	
	if (StrEqual(className, "tf_weapon_scattergun")
			|| StrEqual(className, "tf_weapon_soda_popper")) {
		DHookEntity(g_DHookWeaponSendAnim, false, entity, .callback = OnScattergunSendAnimPre);
	}
}

/**
 * Adds "mult_projectile_speed" support on the Pomson and Righteous Bison's energy projectiles.
 * Note that the velocity starts to break down around 3600HU/s (3x speed)
 */
void EnergyRingPostSpawnPost(int entref) {
	if (!IsValidEntity(entref)) {
		return;
	}
	
	int weapon = GetEntPropEnt(entref, Prop_Send, "m_hOriginalLauncher");
	if (!IsValidEntity(weapon)) {
		return;
	}
	
	float vecVelocity[3];
	GetEntPropVector(entref, Prop_Data, "m_vecAbsVelocity", vecVelocity);
	
	ScaleVector(vecVelocity, TF2Attrib_HookValueFloat(1.0, "mult_projectile_speed", weapon));
	TeleportEntity(entref, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

/**
 * Prevents a Scattergun-based weapon from using Force-a-Nature animations even if it has the
 * knockback attribute applied, as long as it's not actually a Force-a-Nature.
 */
MRESReturn OnScattergunSendAnimPre(int entity, Handle hReturn, Handle hParams) {
	int activity = DHookGetParam(hParams, 1);
	
	if (!TF2Attrib_HookValueInt(0, "set_scattergun_has_knockback", entity)) {
		return MRES_Ignored;
	}
	
	// dumb hack -- short of using econ data for schema-based markers this will have to do
	switch (GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex")) {
		case TF_ITEMDEF_FORCE_A_NATURE, TF_ITEMDEF_FORCE_A_NATURE_FESTIVE: {
			return MRES_Ignored;
		}
	}
	
	// bypass the ITEM2 conversion table and call the baseclass's SendWeaponAnim
	DHookSetReturn(hReturn, SendWeaponAnim(entity, activity));
	return MRES_Supercede;
}

/**
 * Adds "mult_dmg" support on the Pomson and Righteous Bison's energy projectiles.
 */
MRESReturn OnGetEnergyRingDamagePost(int entity, Handle hReturn) {
	int weapon = GetEntPropEnt(entity, Prop_Send, "m_hOriginalLauncher");
	if (!IsValidEntity(weapon)) {
		return MRES_Ignored;
	}
	
	float damage = DHookGetReturn(hReturn);
	DHookSetReturn(hReturn, TF2Attrib_HookValueFloat(damage, "mult_dmg", weapon));
	
	return MRES_Supercede;
}

/**
 * Allows the use of "mult_explosion_radius" to increase the effect radius on Jarate-based
 * entities (Jarate, Mad Milk, Gas Passer).
 */
MRESReturn OnGetGrenadeDamageRadiusPost(int grenade, Handle hReturn) {
	float radius = DHookGetReturn(hReturn);
	
	int weapon = GetEntPropEnt(grenade, Prop_Send, "m_hOriginalLauncher");
	if (!IsValidEntity(weapon)) {
		return MRES_Ignored;
	}
	
	DHookSetReturn(hReturn, TF2Attrib_HookValueFloat(radius, "mult_explosion_radius", weapon));
	return MRES_Supercede;
}

/**
 * Fixes initialized grenades so they have a default explosion radius set.
 */
MRESReturn OnGrenadeInit(int grenade, Handle hParams) {
	float flRadius = GetEntPropFloat(grenade, Prop_Send, "m_DmgRadius");
	if (!flRadius) {
		SetEntPropFloat(grenade, Prop_Send, "m_DmgRadius", TF_DMGRADIUS_GRENADE_LAUNCHER);
	}
	return MRES_Ignored;
}

/**
 * Patches unsupported weapons' projectile speed getters based on "override projectile type"
 */
MRESReturn OnGetProjectileSpeedPost(int weapon, Handle hReturn) {
	float speed = DHookGetReturn(hReturn);
	
	// TODO how should we deal with items that already have a speed?
	
	switch (TF2Attrib_HookValueInt(0, "override_projectile_type", weapon)) {
		case Projectile_Pipebomb, Projectile_Cannonball: {
			// CTFGrenadeLauncher::GetProjectileSpeed()
			speed = TF2Attrib_HookValueFloat(1200.0, "mult_projectile_speed", weapon);
		}
		case Projectile_Arrow, Projectile_ArrowFestive: {
			// CTFCompoundBow::GetProjectileSpeed()
			// 1800 + (charge * 800);
			speed = 2600.0;
		}
		case Projectile_CrossbowBolt, Projectile_CrossbowBoltFestive, Projectile_RescueClaw: {
			// CTFCrossbow::GetProjectileSpeed()
			// same as Projectile_Arrow but charge = 0.75
			speed = TF2Attrib_HookValueFloat(2400.0, "mult_projectile_speed", weapon);
		}
		case Projectile_EnergyBall: {
			// CTFParticleCannon::GetProjectileSpeed()
			speed = 1100.0;
		}
		case Projectile_EnergyRing: {
			// CTFRaygun::GetProjectileSpeed()
			speed = 1200.0;
		}
		case Projectile_GrapplingHook: {
			// CTFGrapplingHook::GetProjectileSpeed()
			// doesn't include CTFPlayerShared::GetCarryingRuneType() checks
			speed = FindConVar("tf_grapplinghook_projectile_speed").FloatValue;
		}
	}
	
	if (speed) {
		DHookSetReturn(hReturn, speed);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

MRESReturn OnRocketExplodePost(int rocket, Handle hParams) {
	int owner = TF2_GetEntityOwner(rocket);
	if (0 < owner < MaxClients
			&& TF2Attrib_HookValueInt(0, "use_large_smoke_explosion", owner)) {
		float origin[3], angles[3];
		GetEntPropVector(rocket, Prop_Data, "m_vecAbsOrigin", origin);
		GetEntPropVector(rocket, Prop_Data, "m_angAbsRotation", angles);
		
		TE_SetupTFParticleEffect("explosionTrail_seeds_mvm", origin, .vecAngles = angles);
		TE_SendToAll();
		
		TE_SetupTFParticleEffect("fluidSmokeExpl_ring_mvm", origin, .vecAngles = angles);
		TE_SendToAll();
	}
	return MRES_Ignored;
}

MRESReturn OnFireJarPre(int weapon, Handle hReturn, Handle hParams) {
	int owner = !DHookIsNullParam(hParams, 1) ?
			DHookGetParam(hParams, 1) : INVALID_ENT_REFERENCE;
	if (owner < 1 || owner > MaxClients) {
		return MRES_Ignored;
	}
	
	char className[64];
	switch (TF2Attrib_HookValueInt(0, "override_projectile_type", weapon)) {
		case Projectile_Jar, Projectile_JarBread, Projectile_JarFestive: {
			className = "tf_projectile_jar";
		}
		case Projectile_JarMilk, Projectile_JarMilkBread: {
			className = "tf_projectile_jar_milk";
		}
		case Projectile_Cleaver: {
			className = "tf_projectile_cleaver";
		}
		case Projectile_JarGas: {
			className = "tf_projectile_jar_gas";
		}
		case Projectile_Spellbook: {
			// not implemented
			return MRES_Ignored;
		}
		default: {
			return MRES_Ignored;
		}
	}
	if (!className[0]) {
		return MRES_Ignored;
	}
	
	float vecSpawnOrigin[3];
	TF2Util_GetPlayerShootPosition(owner, vecSpawnOrigin);
	
	float angEyes[3], vecEyeForward[3], vecEyeRight[3], vecEyeUp[3];
	
	GetClientEyeAngles(owner, angEyes);
	GetAngleVectors(angEyes, vecEyeForward, vecEyeRight, vecEyeUp);
	
	ScaleVector(vecEyeForward, 16.0);
	AddVectors(vecSpawnOrigin, vecEyeForward, vecSpawnOrigin);
	
	// fire projectile from center
	if (!TF2Attrib_HookValueInt(0, "centerfire_projectile", weapon)) {
		ScaleVector(vecEyeRight, 8.0); // TODO check if viewmodels are flipped
		AddVectors(vecSpawnOrigin, vecEyeRight, vecSpawnOrigin);
	}
	
	ScaleVector(vecEyeUp, -6.0);
	AddVectors(vecSpawnOrigin, vecEyeUp, vecSpawnOrigin);
	
	float vecSpawnAngles[3];
	GetEntPropVector(owner, Prop_Data, "m_angAbsRotation", vecSpawnAngles);
	
	GetAngleVectors(angEyes, vecEyeForward, vecEyeRight, vecEyeUp);
	
	float vecVelocity[3];
	vecVelocity = vecEyeForward;
	ScaleVector(vecVelocity, 1200.0);
	ScaleVector(vecEyeUp, 200.0);
	
	AddVectors(vecVelocity, vecEyeUp, vecVelocity);
	
	int jar = CreateEntityByName(className);
	DispatchSpawn(jar);
	TeleportEntity(jar, vecSpawnOrigin, vecSpawnAngles, NULL_VECTOR);
	
	float vecAngVelocity[3];
	vecAngVelocity[0] = 600.0;
	vecAngVelocity[1] = GetRandomFloat(-1200.0, 1200.0);
	
	SDKCall(g_SDKCallInitGrenade, jar, vecVelocity, vecAngVelocity, owner, 0, 3.0);
	SetEntProp(jar, Prop_Data, "m_bIsLive", true);
	
	SetEntPropEnt(jar, Prop_Send, "m_hOriginalLauncher", weapon);
	SetEntPropEnt(jar, Prop_Send, "m_hThrower", owner);
	
	DHookSetReturn(hReturn, false);
	return MRES_Supercede;
}

/**
 * Hardcoded lookup table to fix projectiles being shot from the wrong side.  The projectiles
 * correspond to the weapons that override `IsViewmodelFlipped`.
 * 
 * This fix only affects base items - the weapons with flipped viewmodels will still shoot from
 * the wrong side if their projectile type is overwritten.
 */
MRESReturn OnWeaponBaseVMFlippedPost(int weapon, Handle hReturn) {
	bool flipped = DHookGetReturn(hReturn);
	
	bool invert;
	switch (TF2Attrib_HookValueInt(0, "override_projectile_type", weapon)) {
		case Projectile_NoOverride: {
			// don't process weapons that have no projectile overrides
		}
		case Projectile_CrossbowBolt, Projectile_EnergyBall, Projectile_EnergyRing,
				Projectile_RescueClaw: {
			invert = true;
		}
		default: {
			switch (TF2Util_GetWeaponID(weapon)) {
				case TF_WEAPON_CROSSBOW, TF_WEAPON_DRG_POMSON, TF_WEAPON_PARTICLE_CANNON,
						TF_WEAPON_SHOTGUN_BUILDING_RESCUE: {
					invert = true;
				}
			}
		}
	}
	
	if (invert) {
		DHookSetReturn(hReturn, !flipped);
		return MRES_Override;
	}
	return MRES_Ignored;
}

MRESReturn OnWeaponBaseGunZoomInPost(int weapon) {
	int owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	if (!IsValidEntity(owner)) {
		return MRES_Ignored;
	}
	int fov = RoundFloat(TF2Attrib_HookValueFloat(20.0, "mult_zoom_fov", weapon));
	
	if (fov <= 75) {
		SetEntProp(owner, Prop_Send, "m_iFOV", fov);
	} else {
		// the game forces FOV values higher than 75 to always zoom in
		// we'll just raise a warning in that case
		LogMessage("WARNING: Cannot set mult_zoom_fov to a value higher than 3.5; ignoring "
				... "current value %.2f.", fov / 20.0);
	}
	return MRES_Ignored;
}

/**
 * Validates that we have a non-null entity in the trace.  This is a hotfix for
 * the non-schema `melee_cleave_attack` attribute class, as whatever it's doing may cause this.
 */
MRESReturn OnWeaponBaseMeleeSwingHitPre(int weapon, Handle hReturn, Handle hParams) {
	int pTraceEnt = DHookGetParamObjectPtrVar(hParams, 1, offs_CGameTrace_pEnt,
			ObjectValueType_Int);
	if (!pTraceEnt) {
		DHookSetReturn(hReturn, false);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

/**
 * Forces a cache refresh on a player's items when an attribute has been added / removed from
 * the player.  This fixes issues with weapon-centric attributes like reloading multipliers.
 */
MRESReturn OnPlayerAttributesChangedPost(Address pShared, Handle hParams) {
	int client = TF2Util_GetPlayerFromSharedAddress(pShared);
	for (int i; i < 5; i++) {
		int weapon = GetPlayerWeaponSlot(client, i);
		if (IsValidEntity(weapon)) {
			TF2Attrib_ClearCache(weapon);
		}
	}
	
	for (int i, n = TF2Util_GetPlayerWearableCount(client); i < n; i++) {
		int wearable = TF2Util_GetPlayerWearable(client, i);
		if (IsValidEntity(wearable)) {
			TF2Attrib_ClearCache(wearable);
		}
	}
}

/**
 * Checks if the given weapon should have their charge meter zeroed out during spawn.
 */
void PostSpawnUnsetItemCharge(int weapon) {
	if (!TF2Util_IsEntityWeapon(weapon)) {
		return;
	} else if (TF2Attrib_HookValueInt(0, "item_meter_resupply_denied", weapon) <= 0) {
		// item charges are only unset during spawn when item_meter_resupply_denied > 0
		// see https://gist.github.com/sigsegv-mvm/43e76b30cedca0717e88988ac9172526
		return;
	} else if (GetEffectBarRechargeTime(weapon) <= 0.0) {
		// this item doesn't use the legacy recharge method (Gas Passer uses a new interface)
		return;
	}
	
	/**
	 * If we have an item that wants to not have their meter filled on spawn, zero out their
	 * ammo.  We also set `m_flLastFireTime` and `m_flEffectBarRegenTime` since both of those
	 * determine how the meter is rendered on the client.
	 */
	float flRechargeTime = GetEffectBarRechargeTime(weapon);
	SetEntPropFloat(weapon, Prop_Send, "m_flEffectBarRegenTime", GetGameTime() + flRechargeTime);
	SetEntPropFloat(weapon, Prop_Send, "m_flLastFireTime", GetGameTime());
	TF2_SetWeaponAmmo(weapon, 0);
}

/**
 * Checks if the given weapon is recharging; if so, prevent ammo bring granted.
 */
void ProcessItemRecharge(int weapon) {
	if (!TF2Util_IsEntityWeapon(weapon)) {
		return;
	} else if (TF2Attrib_HookValueInt(0, "item_meter_resupply_denied", weapon) == 0) {
		// item charges are only unset on resupply when item_meter_resupply_denied != 0
		return;
	} else if (GetEffectBarRechargeTime(weapon) <= 0.0) {
		// this item doesn't use the legacy recharge method (Gas Passer uses a new interface)
		// however, lunchbox items do use the new recharge system but always recover ammo
		// regardless of resupply denial state
		int owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
		if (TF2Util_GetWeaponID(weapon) == TF_WEAPON_LUNCHBOX
				&& GetEntPropFloat(owner, Prop_Send, "m_flItemChargeMeter", .element = 1) < 100.0) {
			TF2_SetWeaponAmmo(weapon, 0);
		}
		return;
	}
	
	/**
	 * If we have an item that isn't fully charged, unset our ammo count for it; we don't have
	 * to do anything with `m_flEffectBarRegenTime` since it'll only update itself when ammo is
	 * full in a later function call.
	 */
	float flEffectBarRegenTime = GetEntPropFloat(weapon, Prop_Send, "m_flEffectBarRegenTime");
	if (flEffectBarRegenTime > GetGameTime()) {
		// TODO is it possible to have multiple copies of an item for recharge?
		// if so we should reset it to the last known ammo count
		TF2_SetWeaponAmmo(weapon, 0);
	} else if (GetEntPropFloat(weapon, Prop_Send, "m_flLastFireTime") == 0.0) {
		// this weapon appears to have been freshly spawned; force it to recharge
		float flRechargeTime = GetEffectBarRechargeTime(weapon);
		SetEntPropFloat(weapon, Prop_Send, "m_flEffectBarRegenTime", GetGameTime() + flRechargeTime);
		SetEntPropFloat(weapon, Prop_Send, "m_flLastFireTime", GetGameTime());
		TF2_SetWeaponAmmo(weapon, 0);
	}
}

/**
 * Updates recharge time for legacy item meters with both item_meter_charge_type and
 * item_meter_damage_for_full_charge attributes.
 */
void ApplyItemChargeDamageModifier(int weapon, float flDamage) {
	if (!TF2Util_IsEntityWeapon(weapon)) {
		return;
	} else if (TF2Attrib_HookValueInt(0, "item_meter_charge_type", weapon)
			& ITEM_METER_CHARGE_BY_DAMAGE == 0) {
		// item_meter_charge_type is not set to recharge when dealing damage
		return;
	}
	
	float flRechargeTime = GetEffectBarRechargeTime(weapon);
	if (flRechargeTime <= 0.0) {
		// this item doesn't use the legacy recharge method (Gas Passer uses a new interface)
		return;
	}
	
	float flDamageForFullCharge = TF2Attrib_HookValueFloat(0.0,
			"item_meter_damage_for_full_charge", weapon);
	if (flDamageForFullCharge <= 0.0) {
		ThrowError("item_meter_damage_for_full_charge is a non-positive value on entity %d",
				weapon);
		return;
	}
	
	// reduce the amount of time until recharge
	float flCurrentRegenTime = GetEntPropFloat(weapon, Prop_Send, "m_flEffectBarRegenTime");
	flCurrentRegenTime -= (flDamage / flDamageForFullCharge) * flRechargeTime;
	
	SetEntPropFloat(weapon, Prop_Send, "m_flEffectBarRegenTime", flCurrentRegenTime);
}

/**
 * Reset the given burn timer based on `set_dmgtype_ignite`.
 */
void ApplyItemBurnModifier(int weapon, int victim) {
	if (GetWeaponAfterburnRateOnHit(weapon) > 0.0
			|| !TF2_IsPlayerInCondition(victim, TFCond_OnFire)) {
		// this item has an afterburn on hit that we shouldn't override, or isn't on fire
		// (they should've been set on fire due to set_dmgtype_ignite)
		return;
	}
	
	float burnTime = TF2Attrib_HookValueFloat(0.0, "set_dmgtype_ignite", weapon);
	if (burnTime > 10.0) {
		// hack to limit the burn duration as the game does, for now
		// ideally we would call into `TF2_IgnitePlayer` (which calls `CTFPlayerShared::Burn`),
		// but that doesn't take a weapon - maybe this is something that can go in tf2utils
		burnTime = 10.0;
	}
	
	float currentBurnTime = TF2Util_GetPlayerBurnDuration(victim);
	if (burnTime > currentBurnTime) {
		TF2Util_SetPlayerBurnDuration(victim, burnTime);
	}
}

/**
 * Returns the type of the meter associated with a given item.
 */
MeterType GetItemMeterType(int item) {
	if (!TF2Util_IsEntityWeapon(item)) {
		char classname[64];
		GetEntityClassname(item, classname, sizeof(classname));
		
		if (StrEqual(classname, "tf_wearable_demoshield")) {
			return Meter_PlayerChargeMeter;
		}
		
		return Meter_Invalid;
	}
	
	switch (TF2Util_GetWeaponID(item)) {
		case TF_WEAPON_LUNCHBOX, TF_WEAPON_JAR, TF_WEAPON_JAR_MILK, TF_WEAPON_JAR_GAS,
				TF_WEAPON_BAT_WOOD, TF_WEAPON_BAT_GIFTWRAP, TF_WEAPON_CLEAVER: {
			if (GetEffectBarRechargeTime(item) > 0.0) {
				return Meter_WeaponEffectBar;
			}
		}
		case TF_WEAPON_INVIS: {
			return Meter_PlayerCloakMeter;
		}
	}
	return Meter_Invalid;
}

/**
 * Kludge to detect CTFWeaponBaseGun-derived entities.
 */
static bool IsWeaponBaseGun(int entity) {
	return HasEntProp(entity, Prop_Data, "CTFWeaponBaseGunZoomOutIn");
}

float GetWeaponAfterburnRateOnHit(int weapon) {
	return SDKCall(g_SDKCallGetWeaponAfterburnRate, weapon);
}

bool SendWeaponAnim(int weapon, int activity) {
	return SDKCall(g_SDKCallBaseWeaponSendAnim, weapon, activity);
}

float GetEffectBarRechargeTime(int entity) {
	if (!TF2Util_IsEntityWeapon(entity)) {
		ThrowError("Entity %d is not a weapon", entity);
	}
	float flRechargeTime = SDKCall(g_SDKCallInternalGetEffectBarRechargeTime, entity);
	return TF2Attrib_HookValueFloat(flRechargeTime, "effectbar_recharge_rate", entity);
}
