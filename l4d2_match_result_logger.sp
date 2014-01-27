#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <l4d2_direct>
#include <left4downtown>


#define NAME "L4D2 Match Result Logger"
#define VERSION "0.1"


#define MAX_STEAMID_LENGTH 21 
#define MAX_COMMUNITYID_LENGTH 18 

new Handle:g_cvar_enable = INVALID_HANDLE;
new Handle:g_cvar_logfile = INVALID_HANDLE;

new bool:g_enable = true;
new String:g_logfile[256] = "";

new Handle:teamMember[2];

new bool:clientsaved = false;

public Plugin:myinfo = {
	name = NAME,
	author = "faru",
	description = "",
	version = VERSION,
	url = "http://sunbowworld.com/"
};

public OnPluginStart()
{
	g_cvar_enable = CreateConVar("l4d2_mrl_enable", "1", "Enable logging", 0, true, 0.0, true, 1.0);
	g_cvar_logfile = CreateConVar("l4d2_mrl_logfile", "logs/mrl.log", "Log file name");

	HookConVarChange(g_cvar_enable, SWLogs_ConvarsChanged);
	HookConVarChange(g_cvar_logfile, SWLogs_ConvarsChanged);

	g_enable = GetConVarBool(g_cvar_enable);
	GetConVarString(g_cvar_logfile, g_logfile, sizeof(g_logfile));

	HookEvent("versus_match_finished", event_versus_match_finished, EventHookMode_Post);


	teamMember[0] = CreateArray(ByteCountToCells(MAX_COMMUNITYID_LENGTH) * 4);
	teamMember[1] = CreateArray(ByteCountToCells(MAX_COMMUNITYID_LENGTH) * 4);

	RegServerCmd("mrl_test1", test_module1);
	RegServerCmd("mrl_test2", test_module2);
	RegServerCmd("mrl_test3", test_module3);

	clientsaved = false;
}

public SWLogs_ConvarsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_enable = GetConVarBool(g_cvar_enable);
	GetConVarString(g_cvar_logfile, g_logfile, sizeof(g_logfile));

	decl String:logfile_fullpath[128];

	BuildPath(Path_SM, logfile_fullpath, sizeof(logfile_fullpath), g_logfile);
	PrintToServer("setting log file : %s", logfile_fullpath);
	//test_module();
}

public OnMapStart()
{
	clientsaved = false;
}

public Handle:MRL_FileOpen()
{
	decl String:logfilepath[256];

	BuildPath(Path_SM, logfilepath, sizeof(logfilepath), g_logfile);

	return OpenFile(logfilepath, "a");
}

public Action:event_versus_match_finished(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_enable)
		return Plugin_Continue;

	decl String:sCurMap[64];
	decl String:stemamId64[MAX_COMMUNITYID_LENGTH];
	decl String:output[1024];

	new Handle:file = MRL_FileOpen();

	new score1 = L4D2Direct_GetVSCampaignScore(0);
	new score2 = L4D2Direct_GetVSCampaignScore(1);

	GetCurrentMap(sCurMap, sizeof(sCurMap));

	Format(output, sizeof(output), "{\"versus_at\":%u,", GetTime());
	Format(output, sizeof(output), "%s\"map_name\":\"%s\",", output, sCurMap);
	Format(output, sizeof(output), "%s\"teams\":[{", output);
	Format(output, sizeof(output), "%s\"steam_users\":[", output);


	
	// survivor in first round
	for(new i=0; i<GetArraySize(teamMember[0]); i++ )
   {
		GetArrayString(teamMember[0], i, stemamId64, sizeof(stemamId64));
		Format(output, sizeof(output), "%s%s", output, stemamId64);
		if(GetArraySize(teamMember[0]) != i+1)
			Format(output, sizeof(output), "%s,", output);
   }

	Format(output, sizeof(output), "%s],", output);
	Format(output, sizeof(output), "%s\"score\":%d},{", output, score1);

	Format(output, sizeof(output), "%s\"steam_users\":[", output);

	// survivor in second round
	for(new i=0; i<GetArraySize(teamMember[1]); i++ )
   {
		GetArrayString(teamMember[1], i, stemamId64, sizeof(stemamId64));
		Format(output, sizeof(output), "%s%s", output, stemamId64);
		if(GetArraySize(teamMember[0]) != i+1)
			Format(output, sizeof(output), "%s,", output);
   }

	Format(output, sizeof(output), "%s],", output);
	Format(output, sizeof(output), "%s\"score\":%d},{", output, score2);


	Format(output, sizeof(output), "%s}]}", output);


	WriteFileLine(file, output);

	CloseHandle(file);

	clientsaved = false;


	return Plugin_Continue;
}

public Action:test_module1(args) {

	decl String:sTeamName[32];
	decl String:sCurMap[64];
	decl String:stemamId[MAX_STEAMID_LENGTH];
	decl String:stemamId64[MAX_COMMUNITYID_LENGTH];

	new Handle:file = MRL_FileOpen();

	new score1 = L4D2Direct_GetVSCampaignScore(0);
	new score2 = L4D2Direct_GetVSCampaignScore(1);

	GetCurrentMap(sCurMap, sizeof(sCurMap));


	WriteFileLine(file, "versus_at:%u", GetTime());


	WriteFileLine(file, "mapname:%s", sCurMap);

	WriteFileLine(file, "team%d:%d", 0, score1);
	WriteFileLine(file, "team%d:%d", 1, score2);


	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
	
			if (GetClientTeam(i) == 3)
			{
				sTeamName = "Infected";
			}
			else if (GetClientTeam(i) == 2)
			{
				sTeamName = "Survivor";
			}
			else
			{
				sTeamName = "Spectator";
			}

			GetClientAuthString(i, stemamId, sizeof(stemamId));
			GetCommunityIDString(stemamId, stemamId64, sizeof(stemamId64));
			WriteFileLine(file, "%N (%s:%d) %s", i, sTeamName, GetClientTeam(i), stemamId64);
		}
	}


	ClearArray(teamMember[0]);
	ClearArray(teamMember[1]);
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && (GetClientTeam(i)==2 || GetClientTeam(i)==3))
		{
			GetClientAuthString(i, stemamId, sizeof(stemamId));
			GetCommunityIDString(stemamId, stemamId64, sizeof(stemamId64));
			PushArrayString(teamMember[GetClientTeam(i)-2], stemamId64);
		}
	}
	
	WriteFileLine(file, "Survivor");
	for(new i=0; i<GetArraySize(teamMember[0]); i++ )
   {
		GetArrayString(teamMember[0], i, stemamId64, sizeof(stemamId64));
		WriteFileLine(file, "%s::0", stemamId64);
   }

	WriteFileLine(file, "Infected");
	for(new i=0; i<GetArraySize(teamMember[1]); i++ )
   {
		GetArrayString(teamMember[1], i, stemamId64, sizeof(stemamId64));
		WriteFileLine(file, "%s::1", stemamId64);
   }

	CloseHandle(file);

	PrintToChatAll("test_module finished.");
}



public Action:L4D_OnFirstSurvivorLeftSafeArea(client)
{
	if (clientsaved)
		return Plugin_Continue;

	if(!L4D_IsMissionFinalMap())
		return Plugin_Continue;

	decl String:stemamId[MAX_STEAMID_LENGTH];
	decl String:stemamId64[MAX_COMMUNITYID_LENGTH];


	ClearArray(teamMember[0]);
	ClearArray(teamMember[1]);
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && (GetClientTeam(i)==2 || GetClientTeam(i)==3))
		{
			GetClientAuthString(i, stemamId, sizeof(stemamId));
			GetCommunityIDString(stemamId, stemamId64, sizeof(stemamId64));
			PushArrayString(teamMember[GetClientTeam(i)-2], stemamId64);
		}
	}

	clientsaved = true;
	
	return Plugin_Continue;
}









stock bool:GetCommunityIDString(const String:SteamID[], String:CommunityID[], const CommunityIDSize) 
{ 
    decl String:SteamIDParts[3][11]; 
    new const String:Identifier[] = "76561197960265728"; 
     
    if ((CommunityIDSize < 1) || (ExplodeString(SteamID, ":", SteamIDParts, sizeof(SteamIDParts), sizeof(SteamIDParts[])) != 3)) 
    { 
        CommunityID[0] = '\0'; 
        return false; 
    } 

    new Current, CarryOver = (SteamIDParts[1][0] == '1'); 
    for (new i = (CommunityIDSize - 2), j = (strlen(SteamIDParts[2]) - 1), k = (strlen(Identifier) - 1); i >= 0; i--, j--, k--) 
    { 
        Current = (j >= 0 ? (2 * (SteamIDParts[2][j] - '0')) : 0) + CarryOver + (k >= 0 ? ((Identifier[k] - '0') * 1) : 0); 
        CarryOver = Current / 10; 
        CommunityID[i] = (Current % 10) + '0'; 
    } 

    CommunityID[CommunityIDSize - 1] = '\0'; 
    return true; 
} 



public Action:test_module2(args) {
	decl String:logfilepath[256];
	BuildPath(Path_SM, logfilepath, sizeof(logfilepath), g_logfile);

	new Handle:file = INVALID_HANDLE;
	file = OpenFile(logfilepath, "a");
	if(file == INVALID_HANDLE)
	{
		PrintToServer("file open error!");
		return;
	}

	WriteFileLine(file, "test2");
	
	new res = CloseHandle(file);

	if(res)
		PrintToServer("file close success:%d", res);
	else
		PrintToServer("file close failed:%d", res);
}



public Action:test_module3(args) {

	decl String:sCurMap[64];
	decl String:stemamId64[MAX_COMMUNITYID_LENGTH];
	decl String:output[1024];

	new Handle:file = MRL_FileOpen();

	new score1 = L4D2Direct_GetVSCampaignScore(0);
	new score2 = L4D2Direct_GetVSCampaignScore(1);

	GetCurrentMap(sCurMap, sizeof(sCurMap));

	Format(output, sizeof(output), "{\"versus_at\":%u,", GetTime());
	Format(output, sizeof(output), "%s\"map_name\":\"%s\",", output, sCurMap);
	Format(output, sizeof(output), "%s\"teams\":[{", output);
	Format(output, sizeof(output), "%s\"steam_users\":[", output);


	
	// survivor in first round
	for(new i=0; i<GetArraySize(teamMember[0]); i++ )
   {
		GetArrayString(teamMember[0], i, stemamId64, sizeof(stemamId64));
		Format(output, sizeof(output), "%s%s", output, stemamId64);
		if(GetArraySize(teamMember[0]) != i+1)
			Format(output, sizeof(output), "%s,", output);
   }

	Format(output, sizeof(output), "%s],", output);
	Format(output, sizeof(output), "%s\"score\":%d},{", output, score1);

	Format(output, sizeof(output), "%s\"steam_users\":[", output);

	// survivor in second round
	for(new i=0; i<GetArraySize(teamMember[1]); i++ )
   {
		GetArrayString(teamMember[1], i, stemamId64, sizeof(stemamId64));
		Format(output, sizeof(output), "%s%s", output, stemamId64);
		if(GetArraySize(teamMember[0]) != i+1)
			Format(output, sizeof(output), "%s,", output);
   }

	Format(output, sizeof(output), "%s],", output);
	Format(output, sizeof(output), "%s\"score\":%d},{", output, score2);


	Format(output, sizeof(output), "%s}]}", output);


	WriteFileLine(file, output);

	CloseHandle(file);

	PrintToChatAll("test_module3 finished.");
}