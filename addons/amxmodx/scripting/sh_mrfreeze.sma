// MR FREEZE! - from Batman
// Freeze the ground and make everyone slide around like on ice
// Anyone with Mr. Freeze is immune to this power

/* CVARS - copy and paste to shconfig.cfg

//Mr. Freeze
freeze_level 5
freeze_cooldown 45.0			//Time required between power uses
freeze_maxtime 16.0				//Time the ground is like ice

*/

#include <amxmod>
#include <Vexd_Utilities>
#include <superheromod>

// GLOBAL VARIABLES
new gHeroName[]="Mr. Freeze"
new bool:gHasFreezePower[SH_MAXSLOTS+1]
#define TASKID 546743
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Mr. Freeze","1.2.1","SRGrty / JTP10181")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	register_cvar("freeze_level", "5" )
	register_cvar("freeze_cooldown", "45.0" )
	register_cvar("freeze_maxtime", "16.0" )

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "Freeze the Ground", "Freeze the ground and make everyone slide around like on ice!", true, "freeze_level" )

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	register_srvcmd("freeze_init", "freeze_init")
	shRegHeroInit(gHeroName, "freeze_init")
	register_event("ResetHUD","newSpawn","b")

	// KD
	register_srvcmd("freeze_kd", "freeze_kd")
	shRegKeyDown(gHeroName, "freeze_kd")

	//Catch Round End
	register_logevent("round_end", 2, "1=Round_End")
	register_logevent("round_end", 2, "1&Restart_Round_")
}
//----------------------------------------------------------------------------------------------
public freeze_init()
{
	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has spiderman powers
	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)

	gHasFreezePower[id] = (hasPowers != 0)
}
//----------------------------------------------------------------------------------------------
public freeze_kd()
{
	if ( !hasRoundStarted() ) return PLUGIN_HANDLED

	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	if ( !is_user_alive(id) || !gHasFreezePower[id] ) return PLUGIN_HANDLED

	if ( gPlayerUltimateUsed[id] ) {
		playSoundDenySelect(id)
		return PLUGIN_HANDLED
	}

	if (task_exists(TASKID)) {
		playSoundDenySelect(id)
		client_print(id,print_chat,"[SH](Freeze) Ground is already frozen")
		return PLUGIN_HANDLED
	}

	freeze_floor()

	ultimateTimer(id, get_cvar_float("freeze_cooldown"))
	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public freeze_floor()
{
	freeze_hudmsg()
	set_task(1.0,"freeze_hudmsg",TASKID,"",0, "b")
	set_task(get_cvar_float("freeze_maxtime"),"melt_ice",TASKID+1)

	new players[32], plnum
	get_players(players,plnum,"a")
	for (new i = 0; i < plnum; i++) {
		ice_player(players[i])
	}
}
//----------------------------------------------------------------------------------------------
public freeze_hudmsg()
{
	set_hudmessage(50,100,255,-1.0,0.35,0,1.0,1.3,0.4,0.4,120)
	show_hudmessage(0,"Mr. Freeze Covered the Ground with ICE")
}
//----------------------------------------------------------------------------------------------
public ice_player(id)
{
	if (!is_user_alive(id) || gHasFreezePower[id]) return
	Entvars_Set_Float(id,EV_FL_friction,0.15)
}
//----------------------------------------------------------------------------------------------
public melt_ice()
{
	if (!task_exists(TASKID)) return
	
	remove_task(TASKID)
	remove_task(TASKID+1)

	new players[32], plnum
	get_players(players,plnum,"a")

	for (new i = 0; i < plnum; i++) {
		Entvars_Set_Float(players[i],EV_FL_friction,1.0)
	}

	set_hudmessage(50,80,255,-1.0,0.35,0,2.0,4.0,1.0,1.0,120)
	show_hudmessage(0,"All The ICE Has Melted")
}
//----------------------------------------------------------------------------------------------
public newSpawn(id)
{
	gPlayerUltimateUsed[id] = false
	if (task_exists(TASKID)) ice_player(id)
}
//----------------------------------------------------------------------------------------------
public round_end()
{
	melt_ice()
}
//----------------------------------------------------------------------------------------------