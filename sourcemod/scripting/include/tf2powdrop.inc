#if defined _tf2powdrop_included_
  #endinput
#endif
#define _tf2powdrop_included_

/**
 * @brief Called when a random powerup drop is created
 *
 * @param iClientVictim		Client index
 * @param iClientAttacker	Client index
 * @return					Plugin_Handled to block the powerup spawn
 */
forward Action:PowDrop_OnPowerupDrop(iClientVictim, iClientAttacker);

public SharedPlugin:__pl_tf2powdrop =
{
	name = "tf2powdrop",
	file = "tf2powdrop.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_tf2powdrop_SetNTVOptional()
{
}
