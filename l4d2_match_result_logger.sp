#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <l4d2_direct>



#define NAME "L4D2 Match Result Logger"
#define VERSION "0.1"

new Handle:g_cvar_enable = INVALID_HANDLE;
new Handle:g_cvar_logdir = INVALID_HANDLE;

new bool:g_enable = true;
new String:g_logdir[256] = "";

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
	g_cvar_logdir = CreateConVar("l4d2_mrl_logdir", "logs/l4d2_mrl", "Log file name");

	HookConVarChange(g_cvar_enable, SWLogs_ConvarsChanged);
	HookConVarChange(g_cvar_logdir, SWLogs_ConvarsChanged);

	g_enable = GetConVarBool(g_cvar_enable);
	GetConVarString(g_cvar_logdir, g_logdir, sizeof(g_logdir));

	HookEvent("versus_match_finished", event_versus_match_finished, EventHookMode_Post);

	l4d2_mrl_create_directory();

	//test_module();

}

public SWLogs_ConvarsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_enable = GetConVarBool(g_cvar_enable);
	GetConVarString(g_cvar_logdir, g_logdir, sizeof(g_logdir));

	
	new String:logdir_fullpath[128];

	BuildPath(Path_SM, logdir_fullpath, sizeof(logdir_fullpath), g_logdir);
	l4d2_mrl_create_directory();
	PrintToServer("setting directory : %s", logdir_fullpath);
	//test_module();
}


l4d2_mrl_create_directory()
{
	new String:logdir_fullpath[128];

	BuildPath(Path_SM, logdir_fullpath, sizeof(logdir_fullpath), g_logdir);

	if(!DirExists(logdir_fullpath))
	{
		CreateDirectory(logdir_fullpath, 511); 	// permission is decimal.not octal.
	}

}

SWLogs_Log(const String:str[])
{
	if(!g_enable)
		return;

	new String:g_logfile[256];
	new String:g_date[128];
	FormatTime(g_date, sizeof(g_date), "%F");
	g_logfile = g_logdir;
	StrCat(g_logfile, sizeof(g_logfile), "/");
	StrCat(g_logfile, sizeof(g_logfile), g_date);

	BuildPath(Path_SM, g_logfile, sizeof(g_logfile), g_logfile);
	LogToFileEx(g_logfile, str);
}


public Action:event_versus_match_finished(Handle:event, const String:name[], bool:dontBroadcast)
{
	new score1 = L4D2Direct_GetVSCampaignScore(0);
	new score2 = L4D2Direct_GetVSCampaignScore(1);

	new winner = GetEventInt(event, "winners");

	new String:output[1024] = "";

	Format(output, sizeof(output), "versus_match_finished:%d,%d", 0, score1);
	SWLogs_Log(output);

	Format(output, sizeof(output), "versus_match_finished:%d,%d", 1, score2);
	SWLogs_Log(output);

	Format(output, sizeof(output), "winner:%d", winner);
	SWLogs_Log(output);

	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			Format(output, sizeof(output), "\x03%N \x01(%d)", i, GetClientTeam(i)); //Display the users message
			SWLogs_Log(output);
		}
	}

}


test_module() {
	new String:output[1024] = "";

	new score1 = L4D2Direct_GetVSCampaignScore(0);
	new score2 = L4D2Direct_GetVSCampaignScore(1);


	Format(output, sizeof(output), "versus_match_finished:%d,%d", 0, score1);
	SWLogs_Log(output);
	PrintToChatAll(output);

	Format(output, sizeof(output), "versus_match_finished:%d,%d", 1, score2);
	SWLogs_Log(output);
	PrintToChatAll(output);
	
	decl String:sTeamName[16];
	//new iTeam = GetClientTeam(client);
	decl String:name[64];


	//if (iTeam == 3)
	//{
	//	sTeamName = "Infected";
	//}
	//else if (iTeam == 2)
	//{
	//	sTeamName = "Survivor";
	//}
	//else
	//{
	//	sTeamName = "Spectator";
	//}
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			GetClientName(i, name, sizeof(name));
			Format(output, sizeof(output), "\x03%N \x01(%d)", i, GetClientTeam(i)); //Display the users message
			SWLogs_Log(output);
		}
	}
}
