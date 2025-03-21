//A place for Elements forwards and natives n stuff

#if defined __D2Elements_included
	#endinput
#endif

#define __D2Elements_included	


/**
 *For When an Elemental Condition is applied to a player
 *
 *@param elementtype	Integer value for Element type (1 - Solar, 2 - Arc, 3 - Void, 4 - Stasis, 5 - Strand)
 *
 *@param condition	Condition (ie: Scorched from Solar or Poisoned from Strand)
 *
 *@param weapon		Client Weapon
 *
 *@noreturn
 *
 */

forward Action Elements_OnConditionAdded(int client, int elementtype, String:condition, int weapon);



/**
 *Get Weapon Element type, returns as integer
 *
 *@param client		Client index
 *
 *@param slot		Client weapon slot
 *
 *@return		The stored integer value for the Element (1 - Solar, 2 - Arc, 3 - Void, 4 - Stasis, 5 - Strand)
 *
 */

native int GetElementalDamageType(int client, int slot);


/**
 *Get Amount of Elemental Stacks on a player (Scorch, Slowed, etc), returns as Float
 *
 *@param client		Client index
 *
 *@param ElementType	Integer value for Element
 *
 *@return		Amount of Elemental Stacks
 *
 */

native float GetElementalStacks(int client, int ElementType);


/**
 *Custom Damage detection for Elemental weapons
 *
 *@param attacker	Client dealing damage
 *
 *@param victim		Client receiving damage
 *
 *@param slot		Attacker weapon slot
 *
 *@param damage		Elemental Damage delt
 *
 *@param ElementType	Integer value for Element type (1 - Solar, 2 - Arc, 3 - Void, 4 - Stasis, 5 - Strand)
 *
 *@noreturn
 *
 */

forward Action Elements_OnDamageTaken(int attacker, int victim, int slot, Float:damage, int ElementType);



public SharedPlugin __Destiny_Elements = {
	name = "Elements",
	file = "Elements.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
