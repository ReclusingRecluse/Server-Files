

#define BulletWeapons		"tf_weapon_pistol | tf_weapon_minigun | tf_weapon_raygun | tf_weapon_drg_pomson | tf_weapon_syringegun_medic | tf_weapon_revolver | tf_weapon_smg | tf_weapon_charged_smg | tf_weapon_sniperrifle | tf_weapon_sniperrifle_classic | tf_weapon_sniperrifle_decap | tf_weapon_shotgun | tf_weapon_sentry_revenge | tf_weapon_shotgun_primary | tf_weapon_shotgun_building_rescue | tf_weapon_shotgun_hwg | tf_weapon_shotgun_pyro | tf_weapon_shotgun_soldier | tf_weapon_handgun_scout_secondary | tf_weapon_scattergun | tf_weapon_handgun_scout_primary | tf_weapon_soda_popper | tf_weapon_pep_brawler_blaster"

#define ExplosiveWeapons	"tf_weapon_pipebomblauncher | tf_weapon_grenadelauncher | tf_weapon_cannon | tf_weapon_rocketlauncher_airstrike | tf_weapon_rocketlauncher | tf_weapon_particle_cannon | tf_weapon_rocketlauncher_directhit"

#define Flareguns			"tf_weapon_flaregun | tf_weapon_flaregun_revenge"

#define MeleeWeapons		"tf_weapon_slap | saxxy | tf_weapon_bonesaw | tf_weapon_knife | tf_weapon_club | tf_weapon_breakable_sign | tf_weapon_wrench | tf_weapon_robot_arm | tf_weapon_fists | tf_weapon_bottle | tf_weapon_sword | tf_weapon_stickbomb | tf_weapon_fireaxe | tf_weapon_shovel | tf_weapon_katana | tf_weapon_bat_fish | tf_weapon_bat | tf_weapon_bat_giftwrap | tf_weapon_bat_wood | tf_weapon_bottle"

#define SpecialWeapons		"tf_weapon_rocketlauncher_fireball"

#define FlameThrowers		"tf_weapon_flamethrower"

#define Bows "tf_weapon_compound_bow | tf_weapon_crossbow"

#define Cleaver "tf_weapon_cleaver"

//Bot Stuff
new Float:lvlScale = 0.0;
new Float:damagebuy = 0.0;
new Float:damagebuy2 = 0.0;

new Float:healthbuy = 0.0;
new Float:buildinghealthbuy = 0.0;
new Float:resistbuy = 0.0;
new Float:resistbuy2 = 0.0;

new Float:regenbuy = 0.0;
new Float:regenbuy2 = 0.0;

new Float:Blastbuy = 0.0;

new Float:Sentrybuy1 = 0.0;
new Float:Sentrybuy2 = 0.0;
new Float:Sentrybuy3 = 0.0;

new Float:afterburnbuy = 0.0;
new Float:projbuy = 0.0;
new Float:timeburnbuy = 0.0;
new Float:Disruptorbuy = 0.0;

stock BotCalcs(client)
{
	lvlScale = GetConVarFloat(cvar_Botlevel);
	damagebuy = ((SquareRoot(RealStartMoney*1.50))/2.0)*(lvlScale);	//234 Base
	
	if (damagebuy2 < 1000.0)
	{
	damagebuy2 = ((SquareRoot(RealStartMoney*1.50))/10.0)*(lvlScale); //7.3 Base
	}
	
	healthbuy = (SquareRoot(RealStartMoney*1.30))*(lvlScale);
	buildinghealthbuy = (SquareRoot(RealStartMoney*1.10)*0.1)*(lvlScale);
	resistbuy = (SquareRoot(RealStartMoney*1.30)*0.4)*(lvlScale);
	resistbuy2 = (SquareRoot(RealStartMoney*0.7)*Pow(0.44,2.1))*(lvlScale);
	regenbuy = (SquareRoot(RealStartMoney*1.30)*1.2)*(lvlScale);
	regenbuy2 = (SquareRoot(RealStartMoney*1.50)*Pow(0.3,2.1))*(lvlScale);
	//new Float:regenbuy = (SquareRoot(RealStartMoney*1.30)*0.4)*(lvlScale);
	Blastbuy = (SquareRoot(RealStartMoney*1.30)*Pow(0.1,2.3))*(lvlScale);
	Sentrybuy1 = (SquareRoot(RealStartMoney*1.30)*Pow(0.2,2.4))*(lvlScale);
	Sentrybuy2 = (SquareRoot(RealStartMoney*1.30)*Pow(0.23,2.4))*(lvlScale);
	Sentrybuy3 = (SquareRoot(RealStartMoney*1.30)*Pow(0.23,3.5))*(lvlScale);
	afterburnbuy = (SquareRoot(RealStartMoney*1.30)*Pow(0.1,2.3))*(lvlScale);
	projbuy = (SquareRoot(RealStartMoney*1.30)*Pow(0.1,2.3))*(lvlScale);
	timeburnbuy = (SquareRoot(RealStartMoney*1.30)*Pow(0.1,2.3))*(lvlScale);
	Disruptorbuy = (SquareRoot(RealStartMoney*1.50)*Pow(0.23,2.4))*(lvlScale);
	if (lvlScale <= 1.0)
	{
		if (!IsMvM())
		{
			regenbuy *= Pow(0.1, 0.5);
			healthbuy *= 1.4;
			resistbuy *= 0.5;
		}
		if (IsMvM())
		{
			regenbuy *= Pow(0.1, 0.1);
			healthbuy *= 0.6;
			resistbuy *= 0.2;
			damagebuy *= 0.9
			damagebuy2 *= 1.1
		}
	}
	if (lvlScale == 2.0)
	{
		healthbuy *= 1.9;
		resistbuy *= 1.7;
		damagebuy *= 0.5;
		damagebuy2 *= 0.5;
		regenbuy *= 0.6;
	}
	if (lvlScale == 5.0)
	{
		healthbuy *= 2.3;
		resistbuy *= 2.5;
		damagebuy *= 0.3;
		damagebuy2 *= 0.3;
	}
	if (lvlScale > 5.0)
	{
		resistbuy *= 5.0;
		healthbuy *= 3.5;
		damagebuy *= 0.7;
		damagebuy2 *= 0.7;
	}
	if (Blastbuy > 2.0)
	{
		Blastbuy = 2.0;
	}
	if (afterburnbuy > 6.0)
	{
		afterburnbuy = 6.0;
	}
	if (timeburnbuy > 5.0)
	{
		timeburnbuy = 5.0;
	}
	if (projbuy > 2.0)
	{
		projbuy = 2.0;
	}
	if (Sentrybuy3 > 5.0)
	{
		Sentrybuy3 = 5.0;
	}
}

public Action:BotCalc(Handle:timer)
{
	for (new client = 0; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			if (IsFakeClient(client))
			{
				BotCalcs(client);
			}
		}
	}
}

public Action:BotTimer(Handle:timer, any:client)
{
	if (IsFakeClient(client))
	{
		new Float:Scaleactive = GetConVarFloat(cvar_Botlevel);
		
		new Melee=GetPlayerWeaponSlot(client,2);
		new Second=GetPlayerWeaponSlot(client,1);
		new Primary=GetPlayerWeaponSlot(client,0);
		new BotWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (regenbuy2 > 60.0)
		{
			regenbuy2 = 60.0;
		}
		TF2Attrib_SetByName(client, "max health additive penalty", (healthbuy*0.90));
		TF2Attrib_SetByName(client, "Blast radius increased", Blastbuy);
		TF2Attrib_SetByName(client, "Projectile speed decreased", projbuy);
		TF2Attrib_SetByName(client, "rocket jump damage reduction", 0.01);
		TF2Attrib_SetByName(client, "damage force reduction", 0.00);
		TF2Attrib_SetByName(client, "rocket jump damage reduction", 0.0);
		//TF2Attrib_SetByName(client, "dmg taken from fire reduced", 0.50);
		TF2Attrib_SetByName(client, "tmp dmgbuff on hit", regenbuy2);
		TF2Attrib_SetByName(client, "maxammo metal increased", 25.00);
		TF2Attrib_SetByName(client, "metal regen", 2500.0);
		TF2Attrib_SetByName(client, "damage reduction", resistbuy2);
		if (lvlScale == 5.0)
		{
			//TF2Attrib_SetByName(client, "tmp dmgbuff on hit", 40.0);
			TF2Attrib_SetByName(client, "reduce armor on hit", 20.0);
		}
		if (lvlScale > 5.0)
		{
			//TF2Attrib_SetByName(client, "tmp dmgbuff on hit", 40.0);
			TF2Attrib_SetByName(client, "reduce armor on hit", 10.0+lvlScale*1.30);
		}
		if (!IsMvM())
		{
			TF2Attrib_SetByName(client, "disguise on backstab", (regenbuy*0.50));
			//TF2Attrib_SetByName(i, "dmg taken from crit reduced", 0.50);
			TF2Attrib_SetByName(client, "obsolete ammo penalty", ((resistbuy*8.50)+1300.0));
		}
		if (IsMvM())
		{
			TF2Attrib_SetByName(client, "disguise on backstab", (regenbuy*0.05));
			TF2Attrib_SetByName(client, "obsolete ammo penalty", ((resistbuy*3.50)+2200.0));
		}
		TF2Attrib_SetByName(client, "weapon burn dmg increased", timeburnbuy);
		TF2Attrib_SetByName(client, "clip size bonus", timeburnbuy);
		TF2Attrib_SetByName(client, "referenced item id low", 0.08);
		if (RealStartMoney > 150000.0)
		{
			TF2Attrib_SetByName(client, "move speed bonus", 2.20);
			TF2Attrib_SetByName(client, "cannot be backstabbed", 1.00);
		}
		if (IsValidEntity(BotWeapon))
		{
			TF2Attrib_SetByName(BotWeapon, "cannot giftwrap", damagebuy*1.7);
			TF2Attrib_SetByName(BotWeapon, "tool needs giftwrap", damagebuy2);
			//TF2Attrib_SetByName(BotWeapon, "damage bonus", 1.90);
			//UU_ApplyWepDmgAttrib(BotWeapon, damagebuy, damagebuy2);
		}
		if (IsValidEntity(Primary))
		{
			TF2Attrib_SetByName(Primary, "weapon burn dmg increased", afterburnbuy);
			TF2Attrib_SetByName(Primary, "accuracy scales damage", timeburnbuy);
			TF2Attrib_SetByName(client, "fire rate bonus", 0.10);
			TF2Attrib_SetByName(client, "Reload time decreased", 0.10);
			TF2Attrib_SetByName(Primary, "flame_speed", 8000.0);
			TF2Attrib_SetByName(client, "unique craft index", 0.30);
			if (RealStartMoney > 150000.0)
			{
				TF2Attrib_SetByName(Primary, "item_meter_charge_rate", 0.15);
			}
			if (lvlScale > 5.0)
			{
				TF2Attrib_SetByName(Primary, "referenced item id low", Disruptorbuy);
				//TF2Attrib_SetByName(Primary, "item in slot 4", 12.0);
				TF2Attrib_SetByName(Primary, "Set DamageType Ignite", 1.0);
			}
		}
		if (IsValidEntity(Second))
		{
			TF2Attrib_SetByName(Second, "weapon burn dmg increased", afterburnbuy);
			TF2Attrib_SetByName(Second, "accuracy scales damage", timeburnbuy);
			TF2Attrib_SetByName(client, "fire rate bonus", 0.10);
			TF2Attrib_SetByName(client, "Reload time decreased", 0.10);
			TF2Attrib_SetByName(client, "unique craft index", 0.30);
			if (lvlScale > 5.0)
			{
				TF2Attrib_SetByName(Second, "referenced item id low", Disruptorbuy);
				//TF2Attrib_SetByName(Second, "item in slot 4", 12.0);
				TF2Attrib_SetByName(Second, "Set DamageType Ignite", 1.0);
			}
		}
		if (IsValidEntity(Melee))
		{
			TF2Attrib_SetByName(Melee, "add cloak on hit", (Sentrybuy1*0.1));
			TF2Attrib_SetByName(Melee, "flame_up_speed", (Sentrybuy2*0.1));
			TF2Attrib_SetByName(Melee, "weapon burn dmg increased", afterburnbuy);
			TF2Attrib_SetByName(Melee, "engy building health bonus", buildinghealthbuy);
			TF2Attrib_SetByName(Melee, "Construction rate increased", 4.00);
			TF2Attrib_SetByName(Melee, "Projectile speed decreased", (regenbuy*0.20));
			TF2Attrib_SetByName(Melee, "engy sentry fire rate increased", 0.50);
			TF2Attrib_SetByName(client, "fire rate bonus", 0.30);
			TF2Attrib_SetByName(client, "unique craft index", 0.30);
			if (RealStartMoney > 150000.0)
			{
				TF2Attrib_SetByName(Melee, "flame_drag", Sentrybuy3);
			}
			if (lvlScale > 5.0)
			{
				TF2Attrib_SetByName(Melee, "engy sentry fire rate increased", 0.15);
				TF2Attrib_SetByName(Melee, "referenced item id low", Disruptorbuy);
			}
		}
	}
	//return Plugin_Continue;
}

stock UU_ApplyWepDmgAttrib(c_weapon, Float:dmgbonus1 = 1.0, Float:dmgmult = 1.0)
{
	if (IsValidEntity(c_weapon))
	{
		new String:classname[128]; 
		GetEdictClassname(c_weapon, classname, sizeof(classname));
	
		if (strcmp(BulletWeapons, classname))
		{
			TF2Attrib_SetByName(c_weapon, "cannot giftwrap", dmgbonus1);
			TF2Attrib_SetByName(c_weapon, "tool needs giftwrap", dmgmult);
		}
		if (strcmp(ExplosiveWeapons, classname))
		{
			TF2Attrib_SetByName(c_weapon, "custom_paintkit_seed_lo", dmgbonus1);
			TF2Attrib_SetByName(c_weapon, "custom_paintkit_seed_hi", dmgmult);
		}
		if (strcmp(FlameThrowers, classname))
		{
			TF2Attrib_SetByName(c_weapon, "random drop line item 0", dmgbonus1);
			TF2Attrib_SetByName(c_weapon, "random drop line item 1", dmgmult);
		}
		if (strcmp(Flareguns, classname))
		{
			TF2Attrib_SetByName(c_weapon, "random drop line item 2", dmgbonus1);
			TF2Attrib_SetByName(c_weapon, "random drop line item 3", dmgmult);
		}
		if (strcmp(MeleeWeapons, classname))
		{
			TF2Attrib_SetByName(c_weapon, "custom texture hi", dmgbonus1);
			TF2Attrib_SetByName(c_weapon, "cannot_transmute", dmgmult);
		}
		if (strcmp(SpecialWeapons, classname))
		{
			TF2Attrib_SetByName(c_weapon, "tool target item", dmgbonus1);
			TF2Attrib_SetByName(c_weapon, "end drop date", dmgmult);
		}
		if (strcmp(Cleaver, classname))
		{
			TF2Attrib_SetByName(c_weapon, "tool target item", dmgbonus1);
			TF2Attrib_SetByName(c_weapon, "cannot_transmute", dmgmult);
		}
		if (strcmp(Bows, classname))
		{
			TF2Attrib_SetByName(c_weapon, "tool target item", dmgbonus1);
			TF2Attrib_SetByName(c_weapon, "tool needs giftwrap", dmgmult);
		}
		else
		{
			return;
		}
	}
	else
	{
		return;
	}
}