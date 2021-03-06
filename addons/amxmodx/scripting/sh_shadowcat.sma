// SHADOWCAT! from the X-men, Kitty Pryde can walk thu walls.
// Hero Originally named NightCrawler, changed since powers did not fit.

/* CVARS - copy and paste to shconfig.cfg

//Shadowcat
shadowcat_level 0
shadowcat_cooldown 30		//# of seconds before Shadowcat can NoClip Again
shadowcat_cliptime 6		//# of seconds Shadowcat has in noclip mode.

*/

#include <superheromod>

// GLOBAL VARIABLES
new gHeroID
new const gHeroName[] = "Shadowcat"
new bool:gHasShadowcat[SH_MAXSLOTS+1]
new gShadowcatTimer[SH_MAXSLOTS+1]
new const gSoundShadowcat[] = "ambience/alien_zonerator.wav"
new gPcvarCooldown, gPcvarClipTime
new gMsgSync
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Shadowcat", SH_VERSION_STR, "{HOJ} Batman")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = register_cvar("shadowcat_level", "0")
	gPcvarCooldown = register_cvar("shadowcat_cooldown", "30")
	gPcvarClipTime = register_cvar("shadowcat_cliptime", "6")

	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel)
	sh_set_hero_info(gHeroID, "Walk Through Walls", "Can Walk Through Walls for Short Time - GET STUCK AND YOU'LL BE AUTO-SLAIN!")
	sh_set_hero_bind(gHeroID)

	// LOOP
	set_task(1.0, "shadowcat_loop", _, _, _, "b")

	gMsgSync = CreateHudSyncObj()
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_sound(gSoundShadowcat)
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if ( gHeroID != heroID ) return

	switch(mode) {
		case SH_HERO_ADD: {
			gHasShadowcat[id] = true

			// Make sure looop doesn't fire for them
			gShadowcatTimer[id] = -1
		}

		case SH_HERO_DROP: {
			gHasShadowcat[id] = false

			if ( gShadowcatTimer[id] >= 0 ) shadowcat_endnoclip(id)
		}
	}

	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED")
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	gPlayerInCooldown[id] = false

	gShadowcatTimer[id]= -1

	if ( gHasShadowcat[id] ) {
		shadowcat_endnoclip(id)
	}
}
//----------------------------------------------------------------------------------------------
public sh_hero_key(id, heroID, key)
{
	if ( gHeroID != heroID || sh_is_freezetime() || !is_user_alive(id) ) return

	if ( key == SH_KEYDOWN ) {
		// Make sure they're not in the middle of clip already
		// Let them know they already used their ultimate if they have
		if ( gPlayerInCooldown[id] || gShadowcatTimer[id] >= 0 ) {
			sh_sound_deny(id)
			return
		}

		//If the user already has noclip (prob from another hero) cancel this keydown
		if ( get_user_noclip(id) ) {
			sh_chat_message(id, gHeroID, "You are already using noclip")
			sh_sound_deny(id)
			return
		}

		gShadowcatTimer[id] = get_pcvar_num(gPcvarClipTime)

		set_user_noclip(id, 1)

		// Shadowcat Messsage
		set_hudmessage(255, 0, 0, -1.0, 0.3, 0, 0.25, 1.2, 0.0, 0.0, -1)
		ShowSyncHudMsg(id, gMsgSync, "Entered %s Mode^nDon't get Stuck or you will die", gHeroName)

		emit_sound(id, CHAN_STATIC, gSoundShadowcat, 0.2, ATTN_NORM, 0, PITCH_LOW)
	}
}
//----------------------------------------------------------------------------------------------
public shadowcat_loop()
{
	static players[SH_MAXSLOTS], playerCount, player, i
	static Float:cooldown, noclipTime
	cooldown = get_pcvar_float(gPcvarCooldown)
	get_players(players, playerCount, "ah")

	for ( i = 0; i < playerCount; i++ ) {
		player = players[i]

		if ( gHasShadowcat[player] ) {
			noclipTime = gShadowcatTimer[player]
			if ( noclipTime > 0 ) {
				set_hudmessage(255, 0, 0, -1.0, 0.3, 0, 1.0, 1.2, 0.0, 0.0, -1)
				ShowSyncHudMsg(player, gMsgSync, "%d second%s left of %s Mode^nDon't get Stuck or you will Die", noclipTime, noclipTime == 1 ? "" : "s", gHeroName)

				gShadowcatTimer[player]--
			}
			else if ( noclipTime == 0 ) {
				if ( cooldown > 0.0 ) sh_set_cooldown(player, cooldown)

				gShadowcatTimer[player]--

				shadowcat_endnoclip(player)
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
shadowcat_endnoclip(id)
{
	if ( !is_user_connected(id) ) return

	gShadowcatTimer[id] = -1

	// Stop noclip sound
	emit_sound(id, CHAN_STATIC, gSoundShadowcat, 0.0, ATTN_NORM, SND_STOP, PITCH_LOW)

	if ( !is_user_alive(id) ) return

	if ( get_user_noclip(id) ) {
		// Turn off no-clipping and kill user if stuck
		set_user_noclip(id, 0)

		// If player is stuck kill them
		new Float:origin[3], hulltype
		pev(id, pev_origin, origin)
		hulltype = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
		if ( !sh_hull_vacant(id, origin, hulltype) ) {
			user_kill(id)
		}
	}
}
//----------------------------------------------------------------------------------------------
public sh_client_death(victim)
{
	gPlayerInCooldown[victim] = false

	gShadowcatTimer[victim]= -1

	if ( gHasShadowcat[victim] ) {
		shadowcat_endnoclip(victim)
	}
}
//----------------------------------------------------------------------------------------------
