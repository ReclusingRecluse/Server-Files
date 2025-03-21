/**
 * =============================================================================
 * SteamTools - Exposes some SteamClient functions to SourceMod plugins.
 * Copyright (C) 2010 Asher Baker (asherkin).  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 * =============================================================================
 */

/**
 * =============================================================================
 * Attributions & Thanks:
 * =============================================================================
 * AzuiSleet          - Wrote the original example code to acquire the SteamClient
 *                      factory, information about GameServer auth tickets.
 * VoiDeD & AzuiSleet - The OpenSteamworks project.
 * Didrole            - Linux autoloading.
 * =============================================================================
 */

#ifdef WIN32
#ifdef _MSC_VER
#define atoui64(str) _strtoui64(str, 0, 10)
#else
#define atoui64(str) strtoul(str, 0, 10)
#endif
#else
#define atoui64(str) strtoull(str, 0, 10)
#endif

#include "extension.h"

#include "CDetour/detours.h"

#include "filesystem.h"
#include "tickets.h"
#include "utlmap.h"

/**
 * @file extension.cpp
 * @brief SteamTools extension code.
 */

SteamTools g_SteamTools;
SMEXT_LINK(&g_SteamTools);

SH_DECL_HOOK0_void(IServerGameDLL, GameServerSteamAPIActivated, SH_NOATTRIB, 0);
SH_DECL_HOOK0_void(IServerGameDLL, GameServerSteamAPIShutdown, SH_NOATTRIB, 0);

SH_DECL_HOOK0(ISteamGameServer, WasRestartRequested, SH_NOATTRIB, 0, bool);

SH_DECL_HOOK3(ISteamGameServer, BeginAuthSession, SH_NOATTRIB, 0, EBeginAuthSessionResult, const void *, int, CSteamID);
SH_DECL_HOOK1_void(ISteamGameServer, EndAuthSession, SH_NOATTRIB, 0, CSteamID);

ConVar SteamToolsVersion("steamtools_version", SMEXT_CONF_VERSION, FCVAR_NOTIFY|FCVAR_REPLICATED, SMEXT_CONF_DESCRIPTION);

CDetour *g_pGetCallbackDetour;

IServerGameDLL *g_pServerGameDLL = NULL;
ICvar *g_pLocalCVar = NULL;
IFileSystem *g_pFullFileSystem = NULL;

ISteamGameServer *g_pSteamGameServer = NULL;
ISteamUtils *g_pSteamUtils = NULL;
ISteamGameServerStats *g_pSteamGameServerStats = NULL;
ISteamHTTP *g_pSteamHTTP = NULL;

CSteamID g_CustomSteamID = k_steamIDNil;
CUtlVector<SteamAPICall_t> g_RequestUserStatsSteamAPICalls;
CUtlVector<SteamAPICall_t> g_HTTPRequestSteamAPICalls;

struct HTTPRequestCompletedContextFunction {
	IPluginContext *pContext;
	funcid_t uPluginFunction;
	bool bHasContext;
};

union HTTPRequestCompletedContextPack {
	uint64 ulContextValue;
	struct {
		HTTPRequestCompletedContextFunction *pCallbackFunction;
		cell_t iPluginContextValue;
	};
};

bool MapLessFunc(const uint32 &in1, const uint32 &in2)
{
	return (in1 < in2);
};

typedef CUtlMap<uint32, CCopyableUtlVector<uint32> > SubIDMap;
SubIDMap g_subIDs(MapLessFunc);

#if 0 // Need to rework the API before exposing this.
typedef CUtlVector<uint32> SubIDVector;

struct DLCInfo {
	uint32 uAppID;
	SubIDVector SubIDs;
};

typedef CUtlMap<uint32, CCopyableUtlVector<DLCInfo> > DLCMap;
#else
typedef CUtlMap<uint32, CCopyableUtlVector<uint32> > DLCMap;
#endif
DLCMap g_DLCs(MapLessFunc);

typedef HSteamPipe (*GetPipeFn)();
typedef HSteamUser (*GetUserFn)();

typedef bool (*GetCallbackFn)(HSteamPipe hSteamPipe, CallbackMsg_t *pCallbackMsg);
typedef void (*FreeLastCallbackFn)(HSteamPipe hSteamPipe);

GetPipeFn g_GameServerSteamPipe;
GetUserFn g_GameServerSteamUser;

GetCallbackFn GetCallback;
FreeLastCallbackFn FreeLastCallback;

int g_GameServerSteamAPIActivatedHookID = 0;
int g_GameServerSteamAPIShutdownHookID = 0;

int g_WasRestartRequestedHookID = 0;

int g_BeginAuthSessionHookID = 0;
int g_EndAuthSessionHookID = 0;

bool g_SteamServersConnected = false;
bool g_SteamLoadFailed = false;

IForward *g_pForwardGroupStatusResult = NULL;
IForward *g_pForwardReputation = NULL;
IForward *g_pForwardRestartRequested = NULL;

IForward *g_pForwardSteamServersConnected = NULL;
IForward *g_pForwardSteamServersDisconnected = NULL;

IForward *g_pForwardClientReceivedStats = NULL;
IForward *g_pForwardClientUnloadedStats = NULL;

IForward *g_pForwardLoaded = NULL;
IForward *g_pForwardShutdown = NULL;

extern "C" void SteamAPIWarningMessageHook(int hpipe, const char *message)
{
	g_pSM->LogError(myself, "SteamAPIWarning: %s", message);
}

void Hook_GameServerSteamAPIActivated(void)
{
#if defined _WIN32
	CSysModule *pModSteamApi = g_pFullFileSystem->LoadModule("../bin/steam_api.dll", "MOD", false);
#elif defined _LINUX
	CSysModule *pModSteamApi = g_pFullFileSystem->LoadModule("../bin/libsteam_api.so", "MOD", false);
#endif

	if ( !pModSteamApi )
	{
		g_pSM->LogError(myself, "Unable to get steam_api handle.");
		return;
	}

	HMODULE steam_api_library = reinterpret_cast<HMODULE>(pModSteamApi);

	g_GameServerSteamPipe = (GetPipeFn)GetProcAddress(steam_api_library, "SteamGameServer_GetHSteamPipe");
	g_GameServerSteamUser = (GetUserFn)GetProcAddress(steam_api_library, "SteamGameServer_GetHSteamUser");

	ISteamClient *client = NULL;

	if (!LoadSteamclient(&client))
		return;

	g_pSteamGameServer = (ISteamGameServer *)client->GetISteamGenericInterface(g_GameServerSteamUser(), g_GameServerSteamPipe(), STEAMGAMESERVER_INTERFACE_VERSION);
	g_pSteamUtils = (ISteamUtils *)client->GetISteamGenericInterface(g_GameServerSteamUser(), g_GameServerSteamPipe(), STEAMUTILS_INTERFACE_VERSION);
	g_pSteamGameServerStats = (ISteamGameServerStats *)client->GetISteamGenericInterface(g_GameServerSteamUser(), g_GameServerSteamUser(), STEAMGAMESERVERSTATS_INTERFACE_VERSION);
	g_pSteamHTTP = (ISteamHTTP *)client->GetISteamGenericInterface(g_GameServerSteamUser(), g_GameServerSteamPipe(), STEAMHTTP_INTERFACE_VERSION);

	if (!CheckInterfaces())
		return;

	g_WasRestartRequestedHookID = SH_ADD_HOOK(ISteamGameServer, WasRestartRequested, g_pSteamGameServer, SH_STATIC(Hook_WasRestartRequested), false);

	g_BeginAuthSessionHookID = SH_ADD_HOOK(ISteamGameServer, BeginAuthSession, g_pSteamGameServer, SH_STATIC(Hook_BeginAuthSession), true);
	g_EndAuthSessionHookID = SH_ADD_HOOK(ISteamGameServer, EndAuthSession, g_pSteamGameServer, SH_STATIC(Hook_EndAuthSession), true);

	g_pSteamUtils->SetWarningMessageHook(SteamAPIWarningMessageHook);

	g_SMAPI->ConPrintf("[STEAMTOOLS] Loading complete.\n");

	g_SteamServersConnected = g_pSteamGameServer->BLoggedOn();

	g_pForwardLoaded->Execute(NULL);

	if (g_SteamServersConnected)
	{
		g_pForwardSteamServersConnected->Execute(NULL);
	} else {
		g_pForwardSteamServersDisconnected->Execute(NULL);
	}

	if (g_GameServerSteamAPIActivatedHookID != 0)
	{
		SH_REMOVE_HOOK_ID(g_GameServerSteamAPIActivatedHookID);
		g_GameServerSteamAPIActivatedHookID = 0;
	}
	g_GameServerSteamAPIShutdownHookID = SH_ADD_HOOK(IServerGameDLL, GameServerSteamAPIShutdown, g_pServerGameDLL, SH_STATIC(Hook_GameServerSteamAPIShutdown), true);
}

void Hook_GameServerSteamAPIShutdown(void)
{
	g_GameServerSteamPipe = NULL;
	g_GameServerSteamUser = NULL;

	g_pSteamGameServer = NULL;
	g_pSteamUtils = NULL;
	g_pSteamGameServerStats = NULL;
	g_pSteamHTTP = NULL;

	if (g_WasRestartRequestedHookID != 0)
	{
		SH_REMOVE_HOOK_ID(g_WasRestartRequestedHookID);
		g_WasRestartRequestedHookID = 0;
	}
	if (g_BeginAuthSessionHookID != 0)
	{
		SH_REMOVE_HOOK_ID(g_BeginAuthSessionHookID);
		g_BeginAuthSessionHookID = 0;
	}
	if (g_EndAuthSessionHookID != 0)
	{
		SH_REMOVE_HOOK_ID(g_EndAuthSessionHookID);
		g_EndAuthSessionHookID = 0;
	}

	g_SteamServersConnected = false;

	g_pForwardShutdown->Execute(NULL);

	if (g_GameServerSteamAPIShutdownHookID != 0)
	{
		SH_REMOVE_HOOK_ID(g_GameServerSteamAPIShutdownHookID);
		g_GameServerSteamAPIShutdownHookID = 0;
	}
	g_GameServerSteamAPIActivatedHookID = SH_ADD_HOOK(IServerGameDLL, GameServerSteamAPIActivated, g_pServerGameDLL, SH_STATIC(Hook_GameServerSteamAPIActivated), true);
}

// This is O(n), but it's safe.
// Switch over to a CUtlMap in the future.
IPlugin *FindPluginByContext(IPluginContext *pContext) {
	IPlugin *pFoundPlugin = NULL;

	IPluginIterator *pPluginIterator = plsys->GetPluginIterator();
	while (pPluginIterator->MorePlugins())
	{
		IPlugin *pPlugin = pPluginIterator->GetPlugin();

		if (pPlugin->GetBaseContext() == pContext)
		{
			pFoundPlugin = pPlugin;
			break;
		}

		pPluginIterator->NextPlugin();
	}
	pPluginIterator->Release();

	return pFoundPlugin;
}

DETOUR_DECL_STATIC2(DetourGetCallback, bool, HSteamPipe, hSteamPipe, CallbackMsg_t *, pCallbackMsg)
{
	bool ret = DETOUR_STATIC_CALL(DetourGetCallback)(hSteamPipe, pCallbackMsg);
	if (!ret) {
		return false;
	}

	//g_SMAPI->ConPrintf("[STEAMTOOLS] Callback %d ...\n", pCallbackMsg->m_iCallback);

	switch (pCallbackMsg->m_iCallback)
	{
	case GSClientGroupStatus_t::k_iCallback:
		{
			GSClientGroupStatus_t *GroupStatus = (GSClientGroupStatus_t *)pCallbackMsg->m_pubParam;

			int i;
			for (i = 1; i <= playerhelpers->GetMaxClients(); ++i)
			{
				IGamePlayer *player = playerhelpers->GetGamePlayer(i);
				if (!player)
					continue;

				if (player->IsFakeClient())
					continue;

				if (!player->IsAuthorized())
					continue;

				edict_t *playerEdict = player->GetEdict();
				if (!playerEdict || playerEdict->IsFree())
					continue;

				if (*engine->GetClientSteamID(playerEdict) == GroupStatus->m_SteamIDUser)
					break;
			}

			if (i > playerhelpers->GetMaxClients())
			{
				i = -1;
				g_CustomSteamID = GroupStatus->m_SteamIDUser;
			}

			g_pForwardGroupStatusResult->PushCell(i);
			g_pForwardGroupStatusResult->PushCell(GroupStatus->m_SteamIDGroup.GetAccountID());
			g_pForwardGroupStatusResult->PushCell(GroupStatus->m_bMember);
			g_pForwardGroupStatusResult->PushCell(GroupStatus->m_bOfficer);
			g_pForwardGroupStatusResult->Execute(NULL);

			g_CustomSteamID = k_steamIDNil;

			FreeLastCallback(g_GameServerSteamPipe());
			return false;
		}
	case SteamServersConnected_t::k_iCallback:
		{
			if (!g_SteamServersConnected)
			{
				g_pForwardSteamServersConnected->Execute(NULL);
				g_SteamServersConnected = true;
			}
			break;
		}
	case SteamServersDisconnected_t::k_iCallback:
		{
			if (g_SteamServersConnected)
			{
				g_pForwardSteamServersDisconnected->Execute(NULL);
				g_SteamServersConnected = false;
			}
			break;
		}
	case GSStatsReceived_t::k_iCallback:
		{
			// The handler above dealt with this anyway, stop this getting to the engine.
			FreeLastCallback(g_GameServerSteamPipe());
			return false;
		}
	case GSStatsUnloaded_t::k_iCallback:
		{
			GSStatsUnloaded_t *StatsUnloaded = (GSStatsUnloaded_t *)pCallbackMsg->m_pubParam;

			int i;
			for (i = 1; i <= playerhelpers->GetMaxClients(); ++i)
			{
				IGamePlayer *player = playerhelpers->GetGamePlayer(i);
				if (!player)
					continue;

				if (player->IsFakeClient())
					continue;

				if (!player->IsAuthorized())
					continue;

				edict_t *playerEdict = player->GetEdict();
				if (!playerEdict || playerEdict->IsFree())
					continue;

				if (*engine->GetClientSteamID(playerEdict) == StatsUnloaded->m_steamIDUser)
					break;
			}

			if (i > playerhelpers->GetMaxClients())
			{
				i = -1;
				g_CustomSteamID = StatsUnloaded->m_steamIDUser;
			}

			g_pForwardClientUnloadedStats->PushCell(i);
			g_pForwardClientUnloadedStats->Execute(NULL);

			g_CustomSteamID = k_steamIDNil;

			FreeLastCallback(g_GameServerSteamPipe());
			return false;
		}
	case SteamAPICallCompleted_t::k_iCallback:
		{
			if (!g_pSteamUtils) {
				break;
			}

			SteamAPICallCompleted_t *APICallCompleted = (SteamAPICallCompleted_t *)pCallbackMsg->m_pubParam;
			SteamAPICall_t hSteamAPICall = APICallCompleted->m_hAsyncCall;

			if (g_RequestUserStatsSteamAPICalls.FindAndRemove(hSteamAPICall)) {
				do {
					bool bFailed = false;
					bool bComplete = g_pSteamUtils->IsAPICallCompleted(hSteamAPICall, &bFailed);
					//META_CONPRINTF("[STEAMTOOLS] (Stats) %llu: Completed: %s (Failed: %s)\n", hSteamAPICall, bComplete?"true":"false", bFailed?"true":"false");

					if (!bComplete) {
						g_pSM->LogError(myself, "Stats request was not complete!");
						g_RequestUserStatsSteamAPICalls.AddToTail(hSteamAPICall);
						break;
					}

					GSStatsReceived_t GSStatsReceived;
					g_pSteamUtils->GetAPICallResult(hSteamAPICall, &GSStatsReceived, sizeof(GSStatsReceived), GSStatsReceived.k_iCallback, &bFailed);

					if (bFailed)
					{
						ESteamAPICallFailure failureReason = g_pSteamUtils->GetAPICallFailureReason(hSteamAPICall);
						g_pSM->LogError(myself, "Getting stats failed. (ESteamAPICallFailure = %d)", failureReason);
						break;
					}

					if (GSStatsReceived.m_eResult != k_EResultOK)
					{
						if (GSStatsReceived.m_eResult == k_EResultFail)
							g_pSM->LogError(myself, "Getting stats for user %s failed, backend reported that the user has no stats.", GSStatsReceived.m_steamIDUser.Render());
						else
							g_pSM->LogError(myself, "Stats for user %s received with an unexpected eResult. (eResult = %d)", GSStatsReceived.m_steamIDUser.Render(), GSStatsReceived.m_eResult);
						break;
					}

					int x;
					for (x = 1; x <= playerhelpers->GetMaxClients(); ++x)
					{
						IGamePlayer *player = playerhelpers->GetGamePlayer(x);
						if (!player)
							continue;

						if (player->IsFakeClient())
							continue;

						if (!player->IsAuthorized())
							continue;

						edict_t *playerEdict = player->GetEdict();
						if (!playerEdict || playerEdict->IsFree())
							continue;

						if (*engine->GetClientSteamID(playerEdict) == GSStatsReceived.m_steamIDUser)
							break;
					}

					if (x > playerhelpers->GetMaxClients())
					{
						x = -1;
						g_CustomSteamID = GSStatsReceived.m_steamIDUser;
					}

					g_pForwardClientReceivedStats->PushCell(x);
					g_pForwardClientReceivedStats->Execute(NULL);

					g_CustomSteamID = k_steamIDNil;
				} while (0);
			} else if (g_HTTPRequestSteamAPICalls.FindAndRemove(hSteamAPICall)) {
				do {
					bool bFailed = false;
					bool bComplete = g_pSteamUtils->IsAPICallCompleted(hSteamAPICall, &bFailed);
					//META_CONPRINTF("[STEAMTOOLS] (HTTP) %llu: Completed: %s (Failed: %s)\n", hSteamAPICall, bComplete?"true":"false", bFailed?"true":"false");

					if (!bComplete) {
						g_pSM->LogError(myself, "HTTP request was not complete!");
						g_HTTPRequestSteamAPICalls.AddToTail(hSteamAPICall);
						break;
					}

					HTTPRequestCompleted_t HTTPRequestCompleted;
					g_pSteamUtils->GetAPICallResult(hSteamAPICall, &HTTPRequestCompleted, sizeof(HTTPRequestCompleted), HTTPRequestCompleted.k_iCallback, &bFailed);

					if (bFailed)
					{
						ESteamAPICallFailure failureReason = g_pSteamUtils->GetAPICallFailureReason(hSteamAPICall);
						g_pSM->LogError(myself, "HTTP request failed. (ESteamAPICallFailure = %d)", failureReason);
						break;
					}

					if (HTTPRequestCompleted.m_ulContextValue == 0)
					{
						g_pSM->LogError(myself, "Unable to find plugin in HTTPRequestCompleted handler. (No context value set)");
						break;
					}

					HTTPRequestCompletedContextPack contextPack;
					contextPack.ulContextValue = HTTPRequestCompleted.m_ulContextValue;

					IPlugin *pPlugin = FindPluginByContext(contextPack.pCallbackFunction->pContext);

					if (!pPlugin)
					{
						g_pSM->LogError(myself, "Unable to find plugin in HTTPRequestCompleted handler. (No plugin found matching context)");
						break;
					}

					IPluginFunction *pFunction = pPlugin->GetBaseContext()->GetFunctionById(contextPack.pCallbackFunction->uPluginFunction);

					if (!pFunction || !pFunction->IsRunnable())
					{
						if (!pFunction)
							g_pSM->LogError(myself, "Unable to find plugin in HTTPRequestCompleted handler. (Function not found in plugin)");

						break;
					}

					pFunction->PushCell(HTTPRequestCompleted.m_hRequest);
					pFunction->PushCell(HTTPRequestCompleted.m_bRequestSuccessful);
					pFunction->PushCell(HTTPRequestCompleted.m_eStatusCode);

					if (contextPack.pCallbackFunction->bHasContext)
						pFunction->PushCell(contextPack.iPluginContextValue);

					pFunction->Execute(NULL);

					delete contextPack.pCallbackFunction;
				} while (0);
			} else {
				break;
			}

			FreeLastCallback(g_GameServerSteamPipe());
			return false;
		}
	}

	return true;
}

bool CheckInterfaces()
{
	g_SteamLoadFailed = false;

	if (!g_pSteamGameServer)
	{
		g_pSM->LogError(myself, "Could not find interface %s", STEAMGAMESERVER_INTERFACE_VERSION);
		g_SteamLoadFailed = true;
	}

	if (!g_pSteamUtils)
	{
		g_pSM->LogError(myself, "Could not find interface %s", STEAMUTILS_INTERFACE_VERSION);
		g_SteamLoadFailed = true;
	}

	if (!g_pSteamGameServerStats)
	{
		g_pSM->LogError(myself, "Could not find interface %s", STEAMGAMESERVERSTATS_INTERFACE_VERSION);
		g_SteamLoadFailed = true;
	}

	if (!g_pSteamHTTP)
	{
		g_pSM->LogError(myself, "Could not find interface %s", STEAMHTTP_INTERFACE_VERSION);
		g_SteamLoadFailed = true;
	}

	if (g_SteamLoadFailed)
	{
		return false;
	} else {
		return true;
	}
}

bool LoadSteamclient(ISteamClient **pSteamClient, int method)
{
	if(!g_GameServerSteamPipe || !g_GameServerSteamUser || !g_GameServerSteamPipe() || !g_GameServerSteamUser())
		return false;

	HMODULE steamclient_library = NULL;
	ISteamClient *pLocalSteamClient = NULL;

	g_SMAPI->ConPrintf("[STEAMTOOLS] Trying method %d ...\n", (method + 1));

	switch(method)
	{
	case 0:
		{
#ifdef _LINUX
#if defined _WIN32
			CSysModule *pModSteamClient = g_pFullFileSystem->LoadModule("../bin/steamclient.dll", "MOD", false);
#elif defined _LINUX
			CSysModule *pModSteamClient = g_pFullFileSystem->LoadModule("../bin/steamclient.so", "MOD", false);
#endif
			if (!pModSteamClient)
			{
				g_pSM->LogError(myself, "Unable to get steamclient handle.");
				break;
			}
			steamclient_library = reinterpret_cast<HMODULE>(pModSteamClient);
#else
			g_SMAPI->ConPrintf("[STEAMTOOLS] Method 1 disabled on Windows...\n", (method + 1));
#endif
			break;
		}
#ifdef _WIN32
	case 1:
		{
			steamclient_library = GetModuleHandle("steamclient.dll");
			break;
		}
	case 2:
		{
			HKEY hRegKey;
			char pchSteamDir[MAX_PATH];
			if (RegOpenKeyExA(HKEY_LOCAL_MACHINE, "Software\\Valve\\Steam", 0, KEY_QUERY_VALUE, &hRegKey) != ERROR_SUCCESS)
			{
				g_pSM->LogError(myself, "Steam registry key not found.");
				break;
			}
			DWORD dwLength = sizeof(pchSteamDir);
			RegQueryValueExA(hRegKey, "InstallPath", NULL, NULL, (BYTE*)pchSteamDir, &dwLength);
			RegCloseKey(hRegKey);
			strcat(pchSteamDir, "/steamclient.dll");
			CSysModule *pModSteamClient = g_pFullFileSystem->LoadModule(pchSteamDir, "MOD", false);
			if (!pModSteamClient)
			{
				g_pSM->LogError(myself, "Unable to get steamclient handle.");
				break;
			}
			steamclient_library = reinterpret_cast<HMODULE>(pModSteamClient);
			break;
		}
#endif //_WIN32
	default:
		{
			g_pSM->LogError(myself, "Ran out of methods to acquire SteamWorks interfaces.");
			return false;
		}
	}

	if (!steamclient_library)
	{
		return LoadSteamclient(pSteamClient, (method + 1));
	}

	CreateInterfaceFn steamclient = (CreateInterfaceFn)GetProcAddress(steamclient_library, "CreateInterface");

	pLocalSteamClient = (ISteamClient *)steamclient(STEAMCLIENT_INTERFACE_VERSION, NULL);

	ISteamGameServer *gameserver = (ISteamGameServer *)pLocalSteamClient->GetISteamGenericInterface(g_GameServerSteamUser(), g_GameServerSteamPipe(), STEAMGAMESERVER_INTERFACE_VERSION);

	if (!gameserver)
	{
		return LoadSteamclient(pSteamClient, (method + 1));
	}

	g_SMAPI->ConPrintf("[STEAMTOOLS] Method %d worked!\n", (method + 1));

	*pSteamClient = pLocalSteamClient;

	GetCallback = (GetCallbackFn)GetProcAddress(steamclient_library, "Steam_BGetCallback");
	FreeLastCallback = (FreeLastCallbackFn)GetProcAddress(steamclient_library, "Steam_FreeLastCallback");

	if (g_pGetCallbackDetour) {
		g_pGetCallbackDetour->DisableDetour();
	}
	g_pGetCallbackDetour = DETOUR_CREATE_STATIC(DetourGetCallback, GetCallback);
	if (g_pGetCallbackDetour) {
		g_SMAPI->ConPrintf("[STEAMTOOLS] Detoured Steam_BGetCallback!\n");
		g_pGetCallbackDetour->EnableDetour();
	} else {
			g_SMAPI->ConPrintf("[STEAMTOOLS] FAILED to detour Steam_BGetCallback!\n");
	}

	return true;
}

bool SteamTools::SDK_OnLoad(char *error, size_t maxlen, bool late)
{
	CDetourManager::Init(smutils->GetScriptingEngine(), NULL);

	g_GameServerSteamAPIActivatedHookID = SH_ADD_HOOK(IServerGameDLL, GameServerSteamAPIActivated, g_pServerGameDLL, SH_STATIC(Hook_GameServerSteamAPIActivated), true);

	g_pShareSys->AddNatives(myself, g_ExtensionNatives);
	g_pShareSys->RegisterLibrary(myself, "SteamTools");

	plsys->AddPluginsListener(this);

	g_pForwardGroupStatusResult = g_pForwards->CreateForward("Steam_GroupStatusResult", ET_Ignore, 4, NULL, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_pForwardReputation = g_pForwards->CreateForward("Steam_Reputation", ET_Ignore, 6, NULL, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_pForwardRestartRequested = g_pForwards->CreateForward("Steam_RestartRequested", ET_Ignore, 0, NULL);

	g_pForwardSteamServersConnected = g_pForwards->CreateForward("Steam_SteamServersConnected", ET_Ignore, 0, NULL);
	g_pForwardSteamServersDisconnected = g_pForwards->CreateForward("Steam_SteamServersDisconnected", ET_Ignore, 0, NULL);

	g_pForwardClientReceivedStats = g_pForwards->CreateForward("Steam_StatsReceived", ET_Ignore, 1, NULL, Param_Cell);
	g_pForwardClientUnloadedStats = g_pForwards->CreateForward("Steam_StatsUnloaded", ET_Ignore, 1, NULL, Param_Cell);

	g_pForwardLoaded = g_pForwards->CreateForward("Steam_FullyLoaded", ET_Ignore, 0, NULL);
	g_pForwardShutdown = g_pForwards->CreateForward("Steam_Shutdown", ET_Ignore, 0, NULL);

	g_SMAPI->ConPrintf("[STEAMTOOLS] Initial loading stage complete...\n");

	//If this was a late load, we should try now since we wont get this until a reinit if already loaded...
	if (late)
	{
		Hook_GameServerSteamAPIActivated();

		if (g_SteamLoadFailed) // Hook_GameServerSteamAPIActivated() will have called CheckInterfaces() already.
		{
			snprintf(error, maxlen, "One or more SteamWorks interfaces failed to be acquired.");
			return false;
		}
	}

	return true;
}

void Hook_EndAuthSession(CSteamID steamID)
{
	if (steamID.BIndividualAccount() && steamID.GetUnAccountInstance() == 1)
	{
		g_subIDs.Remove(steamID.GetAccountID());
		g_DLCs.Remove(steamID.GetAccountID());
	}

	RETURN_META(MRES_IGNORED);
}

void SteamTools::OnPluginLoaded(IPlugin *plugin)
{
	if (!g_pSteamGameServer)
		return;

	cell_t result;

	IPluginContext *pluginContext = plugin->GetRuntime()->GetDefaultContext();

	IPluginFunction *steamToolsLoadedCallback = pluginContext->GetFunctionByName("Steam_FullyLoaded");

	if (steamToolsLoadedCallback)
	{
		steamToolsLoadedCallback->CallFunction(NULL, 0, &result);
	} else {
		// This plugin doesn't use SteamTools
		return;
	}

	IPluginFunction *steamConnectionStateCallback = NULL;
	if (g_SteamServersConnected)
	{
		steamConnectionStateCallback = pluginContext->GetFunctionByName("Steam_SteamServersConnected");
	} else {
		steamConnectionStateCallback = pluginContext->GetFunctionByName("Steam_SteamServersDisconnected");
	}

	if (steamConnectionStateCallback)
	{
		steamConnectionStateCallback->CallFunction(NULL, 0, &result);
	}
}

bool Hook_WasRestartRequested()
{
	cell_t cellResults = 0;
	bool bWasRestartRequested = false;
	if ((bWasRestartRequested = SH_CALL(g_pSteamGameServer, &ISteamGameServer::WasRestartRequested)()))
	{
		g_pForwardRestartRequested->Execute(&cellResults);
	}
	RETURN_META_VALUE(MRES_SUPERCEDE, (cellResults < Pl_Handled)?bWasRestartRequested:false);
}

/*
CON_COMMAND(st_ticket, "")
{
	FileHandle_t ticketFile = g_pFullFileSystem->Open("ticket.bin", "rb", "MOD");
	if (!ticketFile)
	{
		META_CONPRINT("Unable to open ticket.bin for reading\n");
	}

	int ticketSize = g_pFullFileSystem->Size(ticketFile);

	void *ticketBuffer = malloc(ticketSize);
	if (!ticketBuffer)
	{
		META_CONPRINT("Unable to allocate memory to read ticket.bin\n");

		free(ticketBuffer);
		return;
	}

	if (!g_pFullFileSystem->Read(ticketBuffer, ticketSize, ticketFile))
	{
		META_CONPRINT("Unable to read ticket.bin\n");

		free(ticketBuffer);
		return;
	}

	g_pFullFileSystem->Close(ticketFile);

	bool error = false;
	AuthBlob_t authblob(ticketBuffer, ticketSize, &error);

	if (error) // An error was encountered trying to parse the ticket.
	{
		CBlob authBlob(ticketBuffer, ticketSize);
		uint8 revVersion;
		if (authBlob.Read<uint8>(&revVersion) && revVersion == 83)
		{
			META_CONPRINT("Error detected parsing ticket. (RevEmu)\n");
		} else {
			META_CONPRINT("Error detected parsing ticket. (unknown)\n");
		}

		free(ticketBuffer);
		return;
	}

	META_CONPRINT("No error detected while parsing ticket.\n");

	free(ticketBuffer);
}
*/

//ConVar ParseBadTickets("steamtools_parse_bad_tickets", "1", FCVAR_NONE, "", true, 0.0, true, 1.0);
//ConVar DumpBadTickets("steamtools_dump_unknown_tickets", "1", FCVAR_NONE, "", true, 0.0, true, 1.0);
ConVar DumpTickets("steamtools_dump_tickets", "0", FCVAR_NONE, "", true, 0.0, true, 1.0);

EBeginAuthSessionResult Hook_BeginAuthSession(const void *pAuthTicket, int cbAuthTicket, CSteamID steamID)
{
	EBeginAuthSessionResult ret = META_RESULT_ORIG_RET(EBeginAuthSessionResult);

	bool bInvalidTicket = (ret == k_EBeginAuthSessionResultInvalidTicket);
	if (bInvalidTicket || DumpTickets.GetBool())
	{
		if (bInvalidTicket)
			g_pSM->LogMessage(myself, "Dumping Steam ticket as it's invalid...");

		char fileName[64];
		g_pSM->Format(fileName, 64, "ticket_%u_%u_%u.bin", steamID.GetAccountID(), cbAuthTicket, time(NULL));

		FileHandle_t ticketFile = g_pFullFileSystem->Open(fileName, "wb", "MOD");
		if (!ticketFile)
		{
			g_pSM->LogError(myself, "Unable to open %s for writing.", fileName);
		} else {
			g_pFullFileSystem->Write(pAuthTicket, cbAuthTicket, ticketFile);
			g_pFullFileSystem->Close(ticketFile);

			g_pSM->LogMessage(myself, "Wrote ticket to %s", fileName);
		}

		if (bInvalidTicket) // Bail out.
			RETURN_META_VALUE(MRES_IGNORED, (EBeginAuthSessionResult)NULL);
	}

	bool error = false;
	AuthBlob_t authblob(pAuthTicket, cbAuthTicket, &error);

	if (error) // An error was encountered trying to parse the ticket.
	{
		g_pSM->LogError(myself, "Failed to parse ticket from %s, subscription and DLC info will not be available.", steamID.Render());
		RETURN_META_VALUE(MRES_IGNORED, (EBeginAuthSessionResult)NULL);
	}

	if (authblob.ownership == NULL || authblob.ownership->ticket == NULL)
	{
		g_pSM->LogError(myself, "Missing sections in ticket from %s, subscription and DLC info will not be available.", steamID.Render());
		RETURN_META_VALUE(MRES_IGNORED, (EBeginAuthSessionResult)NULL);
	}

	SubIDMap::IndexType_t subIndex = g_subIDs.Insert(steamID.GetAccountID());
	g_subIDs.Element(subIndex).CopyArray(authblob.ownership->ticket->licenses, authblob.ownership->ticket->numlicenses);

	DLCMap::IndexType_t DLCIndex = g_DLCs.Insert(steamID.GetAccountID());
	g_DLCs.Element(DLCIndex).CopyArray(authblob.ownership->ticket->dlcs, authblob.ownership->ticket->numdlcs);

	RETURN_META_VALUE(MRES_IGNORED, (EBeginAuthSessionResult)NULL);
}

/*
bool Hook_SendUserConnectAndAuthenticate(uint32 unIPClient, const void *pvAuthBlob, uint32 cubAuthBlobSize, CSteamID *pSteamIDUser)
{
	bool ret = META_RESULT_ORIG_RET(bool);

	if (!ret && !ParseBadTickets.GetBool())
	{
		g_pSM->LogMessage(myself, "Client connecting from %u.%u.%u.%u was denied by Steam, but SteamTools has been configured not to gather additional info.", (unIPClient) & 0xFF, (unIPClient >> 8) & 0xFF, (unIPClient >> 16) & 0xFF, (unIPClient >> 24) & 0xFF);
		RETURN_META_VALUE(MRES_IGNORED, (bool)NULL);
	}

	bool error = false;
	AuthBlob_t authblob(pvAuthBlob, cubAuthBlobSize, &error);

	if (error) // An error was encountered trying to parse the ticket.
	{
		CBlob authBlob(pvAuthBlob, cubAuthBlobSize);
		uint8 revVersion;
		if (authBlob.Read<uint8>(&revVersion) && revVersion == 83)
		{
			g_pSM->LogMessage(myself, "Client connecting from %u.%u.%u.%u sent a non-steam auth blob. (RevEmu ticket detected)", (unIPClient) & 0xFF, (unIPClient >> 8) & 0xFF, (unIPClient >> 16) & 0xFF, (unIPClient >> 24) & 0xFF);
		} else {
			g_pSM->LogMessage(myself, "Client connecting from %u.%u.%u.%u sent a non-steam auth blob.", (unIPClient) & 0xFF, (unIPClient >> 8) & 0xFF, (unIPClient >> 16) & 0xFF, (unIPClient >> 24) & 0xFF);

			if (DumpBadTickets.GetBool())
			{
				char fileName[64];
				g_pSM->Format(fileName, 64, "ticket_%u_%u_%u_%u_%u_%u.bin", (unIPClient) & 0xFF, (unIPClient >> 8) & 0xFF, (unIPClient >> 16) & 0xFF, (unIPClient >> 24) & 0xFF, cubAuthBlobSize, time(NULL));

				FileHandle_t ticketFile = g_pFullFileSystem->Open(fileName, "wb", "MOD");
				if (!ticketFile)
				{
					g_pSM->LogError(myself, "Unable to open %s for writing.", fileName);
				} else {
					g_pFullFileSystem->Write(pvAuthBlob, cubAuthBlobSize, ticketFile);

					g_pFullFileSystem->Close(ticketFile);

					g_pSM->LogMessage(myself, "Wrote unknown ticket to %s, please send this file to asherkin@gmail.com", fileName);
				}
			}
		}

		RETURN_META_VALUE(MRES_IGNORED, (bool)NULL);
	}

	if (!ret)
	{
		if (!authblob.ownership)
		{
			g_pSM->LogMessage(myself, "Client connecting from %u.%u.%u.%u (%s) isn't using Steam.", (unIPClient) & 0xFF, (unIPClient >> 8) & 0xFF, (unIPClient >> 16) & 0xFF, (unIPClient >> 24) & 0xFF, (authblob.section)?(authblob.section->steamid.Render()):("NO STEAMID"));
		} else if (!authblob.section) {
			g_pSM->LogMessage(myself, "Client connecting from %u.%u.%u.%u (%s) is in offline mode.", (unIPClient) & 0xFF, (unIPClient >> 8) & 0xFF, (unIPClient >> 16) & 0xFF, (unIPClient >> 24) & 0xFF, authblob.ownership->ticket->steamid.Render());
		} else {
			g_pSM->LogMessage(myself, "Client connecting from %u.%u.%u.%u (%s) was denied by Steam for an unknown reason. (Maybe an expired or stolen ticket?).", (unIPClient) & 0xFF, (unIPClient >> 8) & 0xFF, (unIPClient >> 16) & 0xFF, (unIPClient >> 24) & 0xFF, authblob.ownership->ticket->steamid.Render());
		}

		RETURN_META_VALUE(MRES_IGNORED, (bool)NULL);
	}

	if (!authblob.section && authblob.ownership)
	{
		g_pSM->LogMessage(myself, "Client connecting from %u.%u.%u.%u (%s) is in offline mode but their ticket hasn't expired yet.", (unIPClient) & 0xFF, (unIPClient >> 8) & 0xFF, (unIPClient >> 16) & 0xFF, (unIPClient >> 24) & 0xFF, authblob.ownership->ticket->steamid.Render());
		RETURN_META_VALUE(MRES_IGNORED, (bool)NULL);
	} else if (!authblob.section || !authblob.ownership) {
		g_pSM->LogError(myself, "SendUserConnectAndAuthenticate: Aborting due to missing sections in ticket. (authblob.length = %u)", authblob.length);
		RETURN_META_VALUE(MRES_IGNORED, (bool)NULL);
	}

	if (authblob.ownership->ticket->version != 4)
	{
		g_pSM->LogError(myself, "SendUserConnectAndAuthenticate: Aborting due to unexpected ticket version. (ticketVersion = %u)", authblob.ownership->ticket->version);
		RETURN_META_VALUE(MRES_IGNORED, (bool)NULL);
	}

	SubIDMap::IndexType_t index = g_subIDs.Insert(pSteamIDUser->GetAccountID());
	g_subIDs.Element(index).CopyArray(authblob.ownership->ticket->licenses, authblob.ownership->ticket->numlicenses);

	RETURN_META_VALUE(MRES_IGNORED, (bool)NULL);
}
*/

bool SteamTools::SDK_OnMetamodLoad(ISmmAPI *ismm, char *error, size_t maxlen, bool late)
{
	GET_V_IFACE_CURRENT(GetServerFactory, g_pServerGameDLL, IServerGameDLL, INTERFACEVERSION_SERVERGAMEDLL);
	GET_V_IFACE_CURRENT(GetEngineFactory, g_pLocalCVar, ICvar, CVAR_INTERFACE_VERSION);
	GET_V_IFACE_CURRENT(GetFileSystemFactory, g_pFullFileSystem, IFileSystem, FILESYSTEM_INTERFACE_VERSION);

	g_pCVar = g_pLocalCVar;
	ConVar_Register(FCVAR_NONE, this);

	return true;
}

bool SteamTools::RegisterConCommandBase(ConCommandBase *pCommand)
{
		META_REGCVAR(pCommand);
		return true;
}

void SteamTools::SDK_OnUnload()
{
	plsys->RemovePluginsListener(this);

	if (g_GameServerSteamAPIActivatedHookID != 0)
	{
		SH_REMOVE_HOOK_ID(g_GameServerSteamAPIActivatedHookID);
		g_GameServerSteamAPIActivatedHookID = 0;
	}
	if (g_GameServerSteamAPIShutdownHookID != 0)
	{
		SH_REMOVE_HOOK_ID(g_GameServerSteamAPIShutdownHookID);
		g_GameServerSteamAPIShutdownHookID = 0;
	}
	if (g_WasRestartRequestedHookID != 0)
	{
		SH_REMOVE_HOOK_ID(g_WasRestartRequestedHookID);
		g_WasRestartRequestedHookID = 0;
	}
	if (g_BeginAuthSessionHookID != 0)
	{
		SH_REMOVE_HOOK_ID(g_BeginAuthSessionHookID);
		g_BeginAuthSessionHookID = 0;
	}
	if (g_EndAuthSessionHookID != 0)
	{
		SH_REMOVE_HOOK_ID(g_EndAuthSessionHookID);
		g_EndAuthSessionHookID = 0;
	}

	g_pForwards->ReleaseForward(g_pForwardGroupStatusResult);
	g_pForwards->ReleaseForward(g_pForwardReputation);

	g_pForwards->ReleaseForward(g_pForwardRestartRequested);

	g_pForwards->ReleaseForward(g_pForwardSteamServersConnected);
	g_pForwards->ReleaseForward(g_pForwardSteamServersDisconnected);
}

bool SteamTools::QueryRunning(char *error, size_t maxlen)
{
	if (g_SteamLoadFailed)
	{
		snprintf(error, maxlen, "One or more SteamWorks interfaces failed to be acquired.");
		return false;
	}
	return true;
}

CSteamID atocsteamid(const char *pRenderedID)
{
	// Convert the Steam2 ID string to a Steam2 ID structure
	TSteamGlobalUserID steam2ID;
	steam2ID.m_SteamInstanceID = 0;
	steam2ID.m_SteamLocalUserID.Split.High32bits = 0;
	steam2ID.m_SteamLocalUserID.Split.Low32bits	= 0;

	const char *pchTSteam2ID = pRenderedID;

	const char *pchOptionalLeadString = "STEAM_";
	if (Q_strnicmp(pRenderedID, pchOptionalLeadString, Q_strlen(pchOptionalLeadString)) == 0)
		pchTSteam2ID = pRenderedID + Q_strlen(pchOptionalLeadString);

	char cExtraCharCheck = 0;

	int cFieldConverted = sscanf(pchTSteam2ID, "%hu:%u:%u%c", &steam2ID.m_SteamInstanceID, &steam2ID.m_SteamLocalUserID.Split.High32bits, &steam2ID.m_SteamLocalUserID.Split.Low32bits, &cExtraCharCheck);

	// Validate the conversion ... a special case is steam2 instance ID 1 which is reserved for special DoD handling
	if (cExtraCharCheck != 0 || cFieldConverted == EOF || cFieldConverted < 2 || (cFieldConverted < 3 && steam2ID.m_SteamInstanceID != 1))
		return k_steamIDNil;

	// Now convert to steam ID from the Steam2 ID structure
	CSteamID steamID;
	steamID.SetFromSteam2(&steam2ID, k_EUniversePublic);
	return steamID;
}

static cell_t RequestGroupStatus(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamGameServer)
		return 0;

	const CSteamID *pSteamID;
	if(params[1] > -1)
	{
		pSteamID = engine->GetClientSteamID(engine->PEntityOfEntIndex(params[1]));
	} else {
		if (g_CustomSteamID.IsValid())
			pSteamID = &g_CustomSteamID;
		else
			return pContext->ThrowNativeError("Custom SteamID not set.");
	}
	if (!pSteamID)
		return pContext->ThrowNativeError("No SteamID found for client %d", params[1]);

	return g_pSteamGameServer->RequestUserGroupStatus(*pSteamID, CSteamID(params[2], k_EUniversePublic, k_EAccountTypeClan));
}

static cell_t RequestGameplayStats(IPluginContext *pContext, const cell_t *params)
{
	return pContext->ThrowNativeError("RequestGameplayStats function no longer operational.");
}

static cell_t RequestServerReputation(IPluginContext *pContext, const cell_t *params)
{
	return pContext->ThrowNativeError("RequestServerReputation function no longer operational.");
}

static cell_t ForceHeartbeat(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamGameServer)
		return 0;

	g_pSteamGameServer->ForceHeartbeat();
	return 0;
}

static cell_t IsVACEnabled(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamGameServer)
		return 0;

	return g_pSteamGameServer->BSecure();
}

static cell_t IsConnected(IPluginContext *pContext, const cell_t *params)
{
	/*
	if (!g_pSteamGameServer)
		return 0;

	return g_pSteamGameServer->LoggedOn();
	*/

	return g_SteamServersConnected;
}

static cell_t GetPublicIP(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamGameServer)
		return 0;

	uint32 ipAddress = g_pSteamGameServer->GetPublicIP();
	unsigned char octet[4]  = {0,0,0,0};

	for (int i=0; i<4; i++)
	{
		octet[i] = ( ipAddress >> (i*8) ) & 0xFF;
	}

	cell_t *addr;
	pContext->LocalToPhysAddr(params[1], &addr);

	addr[0] = octet[3];
	addr[1] = octet[2];
	addr[2] = octet[1];
	addr[3] = octet[0];

	return 0;
}

static cell_t SetKeyValue(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamGameServer)
		return 0;

	char *pKey;
	pContext->LocalToString(params[1], &pKey);
	char *pValue;
	pContext->LocalToString(params[2], &pValue);
	g_pSteamGameServer->SetKeyValue(pKey, pValue);
	return 0;
}

static cell_t ClearAllKeyValues(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamGameServer)
		return 0;

	g_pSteamGameServer->ClearAllKeyValues();
	return 0;
}

static cell_t AddMasterServer(IPluginContext *pContext, const cell_t *params)
{
	return pContext->ThrowNativeError("AddMasterServer function no longer operational.");
}

static cell_t RemoveMasterServer(IPluginContext *pContext, const cell_t *params)
{
	return pContext->ThrowNativeError("RemoveMasterServer function no longer operational.");
}

static cell_t GetNumMasterServers(IPluginContext *pContext, const cell_t *params)
{
	return pContext->ThrowNativeError("GetNumMasterServers function no longer operational.");
}

static cell_t GetMasterServerAddress(IPluginContext *pContext, const cell_t *params)
{
	return pContext->ThrowNativeError("GetMasterServerAddress function no longer operational.");
}

static cell_t SetGameDescription(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamGameServer)
		return 0;

	char *strGameDesc;
	pContext->LocalToString(params[1], &strGameDesc);

	g_pSteamGameServer->SetGameDescription(strGameDesc);
	return 0;
}

static cell_t RequestStats(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamGameServerStats)
		return 0;

	const CSteamID *pSteamID;
	if(params[1] > -1)
	{
		pSteamID = engine->GetClientSteamID(engine->PEntityOfEntIndex(params[1]));
	} else {
		if (g_CustomSteamID.IsValid())
			pSteamID = &g_CustomSteamID;
		else
			return pContext->ThrowNativeError("Custom SteamID not set.");
	}
	if (!pSteamID)
		return pContext->ThrowNativeError("No SteamID found for client %d", params[1]);

	g_RequestUserStatsSteamAPICalls.AddToTail(g_pSteamGameServerStats->RequestUserStats(*pSteamID));
	return 0;
}

static cell_t GetStatInt(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamGameServerStats)
		return 0;

	const CSteamID *pSteamID;
	if(params[1] > -1)
	{
		pSteamID = engine->GetClientSteamID(engine->PEntityOfEntIndex(params[1]));
	} else {
		if (g_CustomSteamID.IsValid())
			pSteamID = &g_CustomSteamID;
		else
			return pContext->ThrowNativeError("Custom SteamID not set.");
	}
	if (!pSteamID)
		return pContext->ThrowNativeError("No SteamID found for client %d", params[1]);

	char *strStatName;
	pContext->LocalToString(params[2], &strStatName);

	int32 data;
	if (g_pSteamGameServerStats->GetUserStat(*pSteamID, strStatName, &data))
	{
		return data;
	} else {
		return pContext->ThrowNativeError("Failed to get stat %s for client %d", strStatName, params[1]);
	}
}

static cell_t GetStatFloat(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamGameServerStats)
		return 0;

	const CSteamID *pSteamID;
	if(params[1] > -1)
	{
		pSteamID = engine->GetClientSteamID(engine->PEntityOfEntIndex(params[1]));
	} else {
		if (g_CustomSteamID.IsValid())
			pSteamID = &g_CustomSteamID;
		else
			return pContext->ThrowNativeError("Custom SteamID not set.");
	}
	if (!pSteamID)
		return pContext->ThrowNativeError("No SteamID found for client %d", params[1]);

	char *strStatName;
	pContext->LocalToString(params[2], &strStatName);

	float data;
	if (g_pSteamGameServerStats->GetUserStat(*pSteamID, strStatName, &data))
	{
		return sp_ftoc(data);
	} else {
		return pContext->ThrowNativeError("Failed to get stat %s for client %d", strStatName, params[1]);
	}
}

static cell_t IsAchieved(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamGameServerStats)
		return 0;

	const CSteamID *pSteamID;
	if(params[1] > -1)
	{
		pSteamID = engine->GetClientSteamID(engine->PEntityOfEntIndex(params[1]));
	} else {
		if (g_CustomSteamID.IsValid())
			pSteamID = &g_CustomSteamID;
		else
			return pContext->ThrowNativeError("Custom SteamID not set.");
	}
	if (!pSteamID)
		return pContext->ThrowNativeError("No SteamID found for client %d", params[1]);

	char *strAchName;
	pContext->LocalToString(params[2], &strAchName);

	bool bAchieved;
	if (g_pSteamGameServerStats->GetUserAchievement(*pSteamID, strAchName, &bAchieved))
	{
		return bAchieved;
	} else {
		return pContext->ThrowNativeError("Failed to get achievement %s for client %d", strAchName, params[1]);
	}
}

static cell_t GetNumClientSubscriptions(IPluginContext *pContext, const cell_t *params)
{
	const CSteamID *pSteamID;
	if(params[1] > -1)
	{
		pSteamID = engine->GetClientSteamID(engine->PEntityOfEntIndex(params[1]));
	} else {
		if (g_CustomSteamID.IsValid())
			pSteamID = &g_CustomSteamID;
		else
			return pContext->ThrowNativeError("Custom SteamID not set.");
	}
	if (!pSteamID)
		return pContext->ThrowNativeError("No SteamID found for client %d", params[1]);

	SubIDMap::IndexType_t index = g_subIDs.Find(pSteamID->GetAccountID());
	if (!g_subIDs.IsValidIndex(index))
		return 0;

	return g_subIDs.Element(index).Count();
}

static cell_t GetClientSubscription(IPluginContext *pContext, const cell_t *params)
{
	const CSteamID *pSteamID;
	if(params[1] > -1)
	{
		pSteamID = engine->GetClientSteamID(engine->PEntityOfEntIndex(params[1]));
	} else {
		if (g_CustomSteamID.IsValid())
			pSteamID = &g_CustomSteamID;
		else
			return pContext->ThrowNativeError("Custom SteamID not set.");
	}
	if (!pSteamID)
		return pContext->ThrowNativeError("No SteamID found for client %d", params[1]);

	SubIDMap::IndexType_t index = g_subIDs.Find(pSteamID->GetAccountID());
	if (!g_subIDs.IsValidIndex(index))
		return pContext->ThrowNativeError("No subscriptions were found for client %d", params[1]);

	if(!g_subIDs.Element(index).IsValidIndex(params[2]))
		return pContext->ThrowNativeError("Subscription index %u is out of bounds for client %d", index, params[1]);

	return g_subIDs.Element(index).Element(params[2]);
}

static cell_t GetNumClientDLCs(IPluginContext *pContext, const cell_t *params)
{
	const CSteamID *pSteamID;
	if(params[1] > -1)
	{
		pSteamID = engine->GetClientSteamID(engine->PEntityOfEntIndex(params[1]));
	} else {
		if (g_CustomSteamID.IsValid())
			pSteamID = &g_CustomSteamID;
		else
			return pContext->ThrowNativeError("Custom SteamID not set.");
	}
	if (!pSteamID)
		return pContext->ThrowNativeError("No SteamID found for client %d", params[1]);

	DLCMap::IndexType_t index = g_DLCs.Find(pSteamID->GetAccountID());
	if (!g_DLCs.IsValidIndex(index))
		return 0;

	return g_DLCs.Element(index).Count();
}

static cell_t GetClientDLC(IPluginContext *pContext, const cell_t *params)
{
	const CSteamID *pSteamID;
	if(params[1] > -1)
	{
		pSteamID = engine->GetClientSteamID(engine->PEntityOfEntIndex(params[1]));
	} else {
		if (g_CustomSteamID.IsValid())
			pSteamID = &g_CustomSteamID;
		else
			return pContext->ThrowNativeError("Custom SteamID not set.");
	}
	if (!pSteamID)
		return pContext->ThrowNativeError("No SteamID found for client %d", params[1]);

	DLCMap::IndexType_t index = g_DLCs.Find(pSteamID->GetAccountID());
	if (!g_DLCs.IsValidIndex(index))
		return pContext->ThrowNativeError("No DLCs were found for client %d", params[1]);

	if(!g_DLCs.Element(index).IsValidIndex(params[2]))
		return pContext->ThrowNativeError("DLC index %u is out of bounds for client %d", index, params[1]);

	return g_DLCs.Element(index).Element(params[2]);
}

static cell_t GetCSteamIDForClient(IPluginContext *pContext, const cell_t *params)
{
	const CSteamID *pSteamID;
	if(params[1] > -1)
	{
		pSteamID = engine->GetClientSteamID(engine->PEntityOfEntIndex(params[1]));
	} else {
		if (g_CustomSteamID.IsValid())
			pSteamID = &g_CustomSteamID;
		else
			return pContext->ThrowNativeError("Custom SteamID not set.");
	}
	if (!pSteamID)
		return pContext->ThrowNativeError("No SteamID found for client %d", params[1]);

	char *steamIDString;
	pContext->LocalToString(params[2], &steamIDString);

	int numbytes = g_pSM->Format(steamIDString, params[3], "%llu", pSteamID->ConvertToUint64());
	numbytes++; // Format's return value doesn't include the NULL terminator.

	return numbytes;
}

static cell_t RenderedIDToCSteamID(IPluginContext *pContext, const cell_t *params)
{
	char *pRenderedSteamID;
	pContext->LocalToString(params[1], &pRenderedSteamID);

	CSteamID steamID = atocsteamid(pRenderedSteamID);

	if (steamID.IsValid())
	{
		char *steamIDString;
		pContext->LocalToString(params[2], &steamIDString);

		int numbytes = g_pSM->Format(steamIDString, params[3], "%llu", steamID.ConvertToUint64());
		numbytes++; // Format's return value doesn't include the NULL terminator.

		return numbytes;
	} else {
		return pContext->ThrowNativeError("%s is not a valid SteamID", pRenderedSteamID);
	}
}

static cell_t CSteamIDToRenderedID(IPluginContext *pContext, const cell_t *params)
{
	char *pSteamID;
	pContext->LocalToString(params[1], &pSteamID);

	CSteamID steamID(atoui64(pSteamID));

	if (steamID.IsValid())
	{
		char *pRenderedSteamID;
		pContext->LocalToString(params[2], &pRenderedSteamID);

		int numbytes = g_pSM->Format(pRenderedSteamID, params[3], "%s", steamID.Render());
		numbytes++; // Format's return value doesn't include the NULL terminator.

		return numbytes;
	} else {
		return pContext->ThrowNativeError("%s is not a valid SteamID", pSteamID);
	}
}

static cell_t SetCustomSteamID(IPluginContext *pContext, const cell_t *params)
{
	char *pRenderedSteamID;
	pContext->LocalToString(params[1], &pRenderedSteamID);

	CSteamID steamID = atocsteamid(pRenderedSteamID);

	if (steamID.IsValid())
	{
		g_CustomSteamID = steamID;
		return true;
	} else {
		g_CustomSteamID = k_steamIDNil;
		return pContext->ThrowNativeError("%s is not a valid SteamID", pRenderedSteamID);
	}
}

static cell_t GetCustomSteamID(IPluginContext *pContext, const cell_t *params)
{
	if (!g_CustomSteamID.IsValid())
		return pContext->ThrowNativeError("Custom SteamID not set.");

	char *steamIDString;
	pContext->LocalToString(params[1], &steamIDString);

	int numbytes = g_pSM->Format(steamIDString, params[2], "%s", g_CustomSteamID.Render());
	numbytes++; // Format's return value doesn't include the NULL terminator.

	return numbytes;
}

static cell_t GroupIDToCSteamID(IPluginContext *pContext, const cell_t *params)
{
	char *steamIDString;
	pContext->LocalToString(params[2], &steamIDString);

	int numbytes = g_pSM->Format(steamIDString, params[3], "%llu", CSteamID(params[1], k_EUniversePublic, k_EAccountTypeClan).ConvertToUint64());
	numbytes++; // Format's return value doesn't include the NULL terminator.

	return numbytes;
}

static cell_t CSteamIDToGroupID(IPluginContext *pContext, const cell_t *params)
{
	char *pSteamID;
	pContext->LocalToString(params[1], &pSteamID);

	CSteamID steamID(atoui64(pSteamID));

	if (steamID.IsValid())
	{
		return steamID.GetAccountID();
	} else {
		return pContext->ThrowNativeError("%s is not a valid SteamID", pSteamID);
	}
}

static cell_t CreateHTTPRequest(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamHTTP)
		return 0;

	EHTTPMethod eHttpRequestMethod = (EHTTPMethod)params[1];

	char *pchAbsoluteURL;
	pContext->LocalToString(params[2], &pchAbsoluteURL);

	return g_pSteamHTTP->CreateHTTPRequest(eHttpRequestMethod, pchAbsoluteURL);
}

static cell_t SetHTTPRequestNetworkActivityTimeout(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamHTTP)
		return 0;

	HTTPRequestHandle hRequest = params[1];
	uint32 unTimeoutSeconds = params[2];

	if (!g_pSteamHTTP->SetHTTPRequestNetworkActivityTimeout(hRequest, unTimeoutSeconds))
		return pContext->ThrowNativeError("HTTPRequestHandle invalid or already sent");

	return 0;
}

static cell_t SetHTTPRequestHeaderValue(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamHTTP)
		return 0;

	HTTPRequestHandle hRequest = params[1];

	char *pchHeaderName;
	pContext->LocalToString(params[2], &pchHeaderName);

	char *pchHeaderValue;
	pContext->LocalToString(params[3], &pchHeaderValue);

	if (!g_pSteamHTTP->SetHTTPRequestHeaderValue(hRequest, pchHeaderName, pchHeaderValue))
		return pContext->ThrowNativeError("HTTPRequestHandle invalid or already sent");

	return 0;
}

static cell_t SetHTTPRequestGetOrPostParameter(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamHTTP)
		return 0;

	HTTPRequestHandle hRequest = params[1];

	char *pchParamName;
	pContext->LocalToString(params[2], &pchParamName);

	char *pchParamValue;
	pContext->LocalToString(params[3], &pchParamValue);

	if (!g_pSteamHTTP->SetHTTPRequestGetOrPostParameter(hRequest, pchParamName, pchParamValue))
		return pContext->ThrowNativeError("HTTPRequestHandle invalid or already sent");

	return 0;
}

static cell_t SendHTTPRequest(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamHTTP)
		return 0;

	HTTPRequestHandle hRequest = params[1];

	HTTPRequestCompletedContextPack contextPack;
	contextPack.pCallbackFunction = new HTTPRequestCompletedContextFunction;

	contextPack.pCallbackFunction->pContext = pContext;
	contextPack.pCallbackFunction->uPluginFunction = params[2];

	if (params[0] >= 3)
	{
		contextPack.pCallbackFunction->bHasContext = true;
		contextPack.iPluginContextValue = params[3];
	}

	if (!g_pSteamHTTP->SetHTTPRequestContextValue(hRequest, contextPack.ulContextValue))
		return pContext->ThrowNativeError("Unable to send HTTP request, couldn't pack context information");

	SteamAPICall_t hAPICall;
	if (!g_pSteamHTTP->SendHTTPRequest(hRequest, &hAPICall))
		return pContext->ThrowNativeError("Unable to send HTTP request, check handle is valid and that there is a network connection present");

	g_HTTPRequestSteamAPICalls.AddToTail(hAPICall);
	return 0;
}

static cell_t DeferHTTPRequest(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamHTTP)
		return 0;

	HTTPRequestHandle hRequest = params[1];

	if (!g_pSteamHTTP->DeferHTTPRequest(hRequest))
		return pContext->ThrowNativeError("HTTPRequestHandle invalid or not yet sent");

	return 0;
}

static cell_t PrioritizeHTTPRequest(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamHTTP)
		return 0;

	HTTPRequestHandle hRequest = params[1];

	if (!g_pSteamHTTP->PrioritizeHTTPRequest(hRequest))
		return pContext->ThrowNativeError("HTTPRequestHandle invalid or not yet sent");

	return 0;
}

static cell_t GetHTTPResponseHeaderSize(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamHTTP)
		return 0;

	HTTPRequestHandle hRequest = params[1];

	char *pchHeaderName;
	pContext->LocalToString(params[2], &pchHeaderName);

	uint32 unResponseHeaderSize = 0;
	if (!g_pSteamHTTP->GetHTTPResponseHeaderSize(hRequest, pchHeaderName, &unResponseHeaderSize))
		return -1;

	return unResponseHeaderSize;
}

static cell_t GetHTTPResponseHeaderValue(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamHTTP)
		return 0;

	HTTPRequestHandle hRequest = params[1];

	char *pchHeaderName;
	pContext->LocalToString(params[2], &pchHeaderName);

	uint32 unBufferSize = params[4];
	char *pHeaderValueBuffer;
	pContext->LocalToString(params[3], &pHeaderValueBuffer);

	if (!g_pSteamHTTP->GetHTTPResponseHeaderValue(hRequest, pchHeaderName, (uint8 *)pHeaderValueBuffer, unBufferSize))
		return pContext->ThrowNativeError("HTTPRequestHandle invalid, not yet sent, invalid buffer size or header not present");

	return 0;
}

static cell_t GetHTTPResponseBodySize(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamHTTP)
		return 0;

	HTTPRequestHandle hRequest = params[1];

	uint32 unBodySize = 0;
	if (!g_pSteamHTTP->GetHTTPResponseBodySize(hRequest, &unBodySize))
		return pContext->ThrowNativeError("HTTPRequestHandle invalid or not yet sent");

	return unBodySize;
}

static cell_t GetHTTPResponseBodyData(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamHTTP)
		return 0;

	HTTPRequestHandle hRequest = params[1];

	uint32 unBufferSize = params[3];
	char *pBodyDataBuffer;
	pContext->LocalToString(params[2], &pBodyDataBuffer);

	uint32 unBodySize = 0;
	if (!g_pSteamHTTP->GetHTTPResponseBodySize(hRequest, &unBodySize))
		return pContext->ThrowNativeError("HTTPRequestHandle invalid or not yet sent");

	if (unBufferSize < unBodySize)
		return pContext->ThrowNativeError("Buffer too small");

	if (!g_pSteamHTTP->GetHTTPResponseBodyData(hRequest, (uint8 *)pBodyDataBuffer, unBodySize))
		return pContext->ThrowNativeError("HTTPRequestHandle invalid, not yet sent or invalid buffer size");

	if (unBufferSize > unBodySize)
		pBodyDataBuffer[unBodySize] = '\0';

	return 0;
}

static cell_t WriteHTTPResponseBody(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamHTTP)
		return 0;

	HTTPRequestHandle hRequest = params[1];

	uint32 unBodySize = 0;
	if (!g_pSteamHTTP->GetHTTPResponseBodySize(hRequest, &unBodySize))
		return pContext->ThrowNativeError("HTTPRequestHandle invalid or not yet sent");

	uint8 *pBodyDataBuffer = (uint8 *)calloc(unBodySize, 1);
	if (!pBodyDataBuffer)
		return pContext->ThrowNativeError("Failed to allocate memory for response body");

	if (!g_pSteamHTTP->GetHTTPResponseBodyData(hRequest, pBodyDataBuffer, unBodySize))
		return pContext->ThrowNativeError("HTTPRequestHandle invalid, not yet sent or invalid buffer size");

	char *pchFilePath;
	pContext->LocalToString(params[2], &pchFilePath);

	FileHandle_t hDataFile = g_pFullFileSystem->Open(pchFilePath, "wb", "MOD");
	if (!hDataFile)
		return pContext->ThrowNativeError("Unable to open %s for writing", pchFilePath);

	g_pFullFileSystem->Write(pBodyDataBuffer, unBodySize, hDataFile);

	free(pBodyDataBuffer);
	g_pFullFileSystem->Close(hDataFile);

	return 0;
}

static cell_t ReleaseHTTPRequest(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamHTTP)
		return 0;

	HTTPRequestHandle hRequest = params[1];

	if (!g_pSteamHTTP->ReleaseHTTPRequest(hRequest))
		return pContext->ThrowNativeError("HTTPRequestHandle invalid");

	return 0;
}

static cell_t GetHTTPDownloadProgressPercent(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamHTTP)
		return 0;

	HTTPRequestHandle hRequest = params[1];

	float flPercent;

	if (!g_pSteamHTTP->GetHTTPDownloadProgressPct(hRequest, &flPercent))
		return pContext->ThrowNativeError("HTTPRequestHandle invalid or not yet sent");

	return sp_ftoc(flPercent);
}

static cell_t SetHTTPRequestRawPostBody(IPluginContext *pContext, const cell_t *params)
{
	if (!g_pSteamHTTP)
		return 0;

	HTTPRequestHandle hRequest = params[1];

	char *pData;
	pContext->LocalToString(params[2], &pData);
	uint32 unDataSize = params[3];

	char *pContentType;
	pContext->LocalToString(params[4], &pContentType);

	return g_pSteamHTTP->SetHTTPRequestRawPostBody(hRequest, pContentType, (uint8*)pData, unDataSize);
}

static cell_t SetHTTPRequestRawPostBodyFile(IPluginContext *pContext, const cell_t *params)
{
       if (!g_pSteamHTTP)
               return 0;

       HTTPRequestHandle hRequest = params[1];

       char *pchFilePath;
       pContext->LocalToString(params[2], &pchFilePath);

       char *pContentType;
       pContext->LocalToString(params[3], &pContentType);

       FileHandle_t hDataFile = g_pFullFileSystem->Open(pchFilePath, "rb", "MOD");
       if (!hDataFile)
               return pContext->ThrowNativeError("Unable to open %s for reading", pchFilePath);

       uint32 unDataSize = g_pFullFileSystem->Size(hDataFile);
       uint8 *pData = new uint8[unDataSize];
       g_pFullFileSystem->Read((void*)pData, unDataSize, hDataFile);

       g_pFullFileSystem->Close(hDataFile);

       bool result = g_pSteamHTTP->SetHTTPRequestRawPostBody(hRequest, pContentType, pData, unDataSize);

       if (result == false)
               g_pSM->LogError(myself, "Failed to insert %s into POST body.", pchFilePath);

       delete[] pData;

       return result;
}

sp_nativeinfo_t g_ExtensionNatives[] =
{
	{ "Steam_RequestGroupStatus",					RequestGroupStatus },
	{ "Steam_RequestGameplayStats",					RequestGameplayStats },
	{ "Steam_RequestServerReputation",				RequestServerReputation },
	{ "Steam_ForceHeartbeat",						ForceHeartbeat },
	{ "Steam_IsVACEnabled",							IsVACEnabled },
	{ "Steam_IsConnected",							IsConnected },
	{ "Steam_GetPublicIP",							GetPublicIP },
	{ "Steam_SetRule",								SetKeyValue },
	{ "Steam_ClearRules",							ClearAllKeyValues },
	{ "Steam_AddMasterServer",						AddMasterServer },
	{ "Steam_RemoveMasterServer",					RemoveMasterServer },
	{ "Steam_GetNumMasterServers",					GetNumMasterServers },
	{ "Steam_GetMasterServerAddress",				GetMasterServerAddress },
	{ "Steam_SetGameDescription",					SetGameDescription },
	{ "Steam_RequestStats",							RequestStats },
	{ "Steam_GetStat",								GetStatInt },
	{ "Steam_GetStatFloat",							GetStatFloat },
	{ "Steam_IsAchieved",							IsAchieved },
	{ "Steam_GetNumClientSubscriptions",			GetNumClientSubscriptions },
	{ "Steam_GetClientSubscription",				GetClientSubscription },
	{ "Steam_GetNumClientDLCs",						GetNumClientDLCs },
	{ "Steam_GetClientDLC",							GetClientDLC },
	{ "Steam_GetCSteamIDForClient",					GetCSteamIDForClient },
	{ "Steam_RenderedIDToCSteamID",					RenderedIDToCSteamID },
	{ "Steam_CSteamIDToRenderedID",					CSteamIDToRenderedID },
	{ "Steam_SetCustomSteamID",						SetCustomSteamID },
	{ "Steam_GetCustomSteamID",						GetCustomSteamID },
	{ "Steam_GroupIDToCSteamID",					GroupIDToCSteamID },
	{ "Steam_CSteamIDToGroupID",					CSteamIDToGroupID },
	{ "Steam_CreateHTTPRequest",					CreateHTTPRequest },
	{ "Steam_SetHTTPRequestNetworkActivityTimeout",	SetHTTPRequestNetworkActivityTimeout },
	{ "Steam_SetHTTPRequestHeaderValue",			SetHTTPRequestHeaderValue },
	{ "Steam_SetHTTPRequestGetOrPostParameter",		SetHTTPRequestGetOrPostParameter },
	{ "Steam_SendHTTPRequest",						SendHTTPRequest },
	{ "Steam_DeferHTTPRequest",						DeferHTTPRequest },
	{ "Steam_PrioritizeHTTPRequest",				PrioritizeHTTPRequest },
	{ "Steam_GetHTTPResponseHeaderSize",			GetHTTPResponseHeaderSize },
	{ "Steam_GetHTTPResponseHeaderValue",			GetHTTPResponseHeaderValue },
	{ "Steam_GetHTTPResponseBodySize",				GetHTTPResponseBodySize },
	{ "Steam_GetHTTPResponseBodyData",				GetHTTPResponseBodyData },
	{ "Steam_WriteHTTPResponseBody",				WriteHTTPResponseBody },
	{ "Steam_ReleaseHTTPRequest",					ReleaseHTTPRequest },
	{ "Steam_GetHTTPDownloadProgressPercent",		GetHTTPDownloadProgressPercent },
	{ "Steam_SetHTTPRequestRawPostBody",			SetHTTPRequestRawPostBody },
	{ "Steam_SetHTTPRequestRawPostBodyFile",		SetHTTPRequestRawPostBodyFile },
	{ NULL,											NULL }
};
