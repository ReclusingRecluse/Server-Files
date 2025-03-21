@echo off
copy ".\uu\uu_headers_defines.txt" /a + ".\uu\uu_headers_menus.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_headers.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_plugininfo.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_defineweaponlists.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_defineweaponliststabs.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_defineuptabs.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_gameevents_ongiveweaon.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_gameevents.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_gameevents_pldth.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_gameevents_rounds.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_gameevents_teams.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_clientcmds.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_clientcmds_admin.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_clientcmds_qbuy.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_loadcfgfiles.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_onpluginstart.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_givenewupgrade.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_putupgrades.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_resetups.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_defineattributes.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_menus_specialtweaks.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_menus_specialtweaks_handlers.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_menus.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_menus_handlers.txt" /a "tf2attributes_ubup.sp"
copy "tf2attributes_ubup.sp" /a + ".\uu\uu_db.txt" /a "tf2attributes_ubup.sp"

 
spcomp.exe tf2attributes_ubup.sp
if %errorlevel%==0 (
echo "yep"
move "tf2attributes_ubup.smx" "..\plugins"



) else (
echo "fail"
)
pause
