#if defined __custom_status_hud_Weapons_included
	#endinput
#endif

#define __custom_status_hud_Weapons_included

/**
 * Called whenever the plugin is ready to update the custom client HUD.
 * 
 * To add new lines for display, call `StringMap.SetString` on the `entries` argument with the
 * additional text as the value.
 * 
 * @param entries		A map of string values to be displayed.  Keys determine sorting in
 * 						alphabetical order.
 */
forward Action OnCustomStatusHUDUpdate3(int client, StringMap entries);

public SharedPlugin __pl_custom_status_hud_Weapons = {
	name = "custom_status_hud_Weapons",
	file = "custom_status_hud_Weapons.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
