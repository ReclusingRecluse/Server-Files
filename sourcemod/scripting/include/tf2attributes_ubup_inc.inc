#if defined __tf2attributes_ubup_inc_included
	#endinput
#endif

#define __tf2attributes_ubup_inc_included

forward Action Ubup_OnAttribAddedClient(int client, String:attrib[])

forward Action Ubup_OnAttribAddedWeapon(int client, iEnt, slot, String:attrib[])


native Address Ubup_GetAddedAttibClient(int client)

public SharedPlugin __tf2attributes_ubup = {
	name = "tf2attributes_ubup",
	file = "tf2attributes_ubup.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
