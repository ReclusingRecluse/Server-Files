
cat ".\uu\uu_headers_defines.txt" ".\uu\uu_headers_menus.txt" ".\uu\uu_headers.txt"  ".\uu\uu_plugininfo.txt" ".\uu\uu_defineweaponlists.txt" ".\uu\uu_defineweaponliststabs.txt" ".\uu\uu_defineuptabs.txt" ".\uu\uu_gameevents_ongiveweaon.txt" ".\uu\uu_gameevents.txt"  ".\uu\uu_gameevents_pldth.txt"  ".\uu\uu_gameevents_rounds.txt"  ".\uu\uu_gameevents_teams.txt"  ".\uu\uu_clientcmds.txt"  ".\uu\uu_clientcmds_admin.txt"  ".\uu\uu_clientcmds_qbuy.txt"  ".\uu\uu_loadcfgfiles.txt"  ".\uu\uu_onpluginstart.txt"  ".\uu\uu_givenewupgrade.txt"  ".\uu\uu_putupgrades.txt"  ".\uu\uu_resetups.txt"  ".\uu\uu_defineattributes.txt"  ".\uu\uu_menus_specialtweaks.txt"  ".\uu\uu_menus_specialtweaks_handlers.txt"  ".\uu\uu_menus.txt"  ".\uu\uu_menus_handlers.txt"  ".\uu\uu_db.txt" > "tf2attributes_ubup.sp"
 
./spcomp tf2attributes_ubup.sp

mv "tf2attributes_ubup.smx" "..\plugins"

