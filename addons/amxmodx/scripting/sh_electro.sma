#include <amxmod>
#include <superheromod>

// GLOBAL VARIABLES
new gHeroName[]="Electro"
new bool:gHasElectroPower[SH_MAXSLOTS+1]
new bool:BeenStruck[SH_MAXSLOTS+1]=false
new gSpriteLightning, gmsgDamage
//****Plugin Init****-------------------------------------------------------------------
public plugin_init()
{
  // Plugin Info
  register_plugin("SUPERHERO Electro","1.0","Prowler")

  // DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
  register_cvar("electro_level", "0" )
  register_cvar("electro_radius", "400" )
  register_cvar("electro_cooldown", "30" )
  // FIRE THE EVENT TO CREATE THIS SUPERHERO!
  shCreateHero(gHeroName, "Chain Lightning", "Shock several people at once!", true, "Electro_level" )

  // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
  register_event("ResetHUD","newRound","b")

  register_srvcmd("Electro_kd", "Electro_kd")
  shRegKeyDown(gHeroName, "Electro_kd")

  // INIT
  register_srvcmd("Electro_init", "Electro_init")
  shRegHeroInit(gHeroName, "Electro_init")

  // OTHER
  gmsgDamage = get_user_msgid("Damage")
}
//****Hero Init****---------------------------------------------------------------------
public Electro_init()
{
  new temp[6]

  read_argv(1,temp,5)
  new id=str_to_num(temp)
  read_argv(2,temp,5)
  new hasPower=str_to_num(temp)

  if ( hasPower != 0 )
    gHasElectroPower[id]=true
  else
    gHasElectroPower[id]=false
}
//****KeyDown****-----------------------------------------------------------------------
public Electro_kd()
{
  new temp[6]
  read_argv(1,temp,5)
  new id = str_to_num(temp)

  if ( !is_user_alive(id) || !gHasElectroPower[id]) return
  if ( gPlayerUltimateUsed[id]) {
    playSoundDenySelect(id)
    return
  }
  ultimateTimer(id, get_cvar_float("electro_cooldown"))

  new ElectroRadius = get_cvar_num("electro_radius")
  new OriginA[3]
  new OriginB[3]
  new players[32], inum
  new oid = id

  get_user_origin(id,OriginA)
  get_players(players,inum,"a")

  message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
  write_byte(28) //TE_ELIGHT
  write_short(id) // entity
  write_coord(OriginA[0])  // initial position
  write_coord(OriginA[1])
  write_coord(OriginA[2])
  write_coord(100)    // radius
  write_byte(230)  // red
  write_byte(230)  // green
  write_byte(0) // blue
  write_byte(10)  // life
  write_coord(0)  // decay rate
  message_end()
  playSound(id)

  for(new i = 0 ;i < inum; ++i)
  {
    get_user_origin(players[i],OriginB)
    if(get_distance(OriginA,OriginB) < ElectroRadius && players[i]!=id)
    {
      BeenStruck[players[i]]=true
      Lightning(id,players[i],oid,OriginB)
      LightningEffects(id,players[i])
      LightningDamage(players[i],id,OriginB)
    }
  }
}
//****Precache****----------------------------------------------------------------------
public plugin_precache()
{
  gSpriteLightning = precache_model("sprites/lgtning.spr")
  precache_sound("ambience/deadsignal1.wav")
  return PLUGIN_CONTINUE
}
//****New Round****---------------------------------------------------------------------
public newRound(id)
{
  gPlayerUltimateUsed[id] = false
}
//****Lightning****---------------------------------------------------------------------
public Lightning(id,tid,oid,Origin[3])
{
  new ElectroRadius = get_cvar_num("electro_radius")
  new OriginA[3]
  new OriginB[3]
  new players[32], inum
  get_user_origin(tid,OriginA)
  get_players(players,inum,"a")
  BeenStruck[tid]=true
  for(new i = 0 ;i < inum; ++i)
  {
    get_user_origin(players[i],OriginB)
    if(get_distance(OriginA,OriginB) < ElectroRadius && tid!=players[i] && !BeenStruck[players[i]])
    {
      Lightning(tid,players[i],oid,OriginB)
      LightningEffects(tid,players[i])
      LightningDamage(players[i],oid,OriginB)
    }
  }
}
//****Damage****------------------------------------------------------------------------
public LightningDamage(tid,oid,Origin[3])
{
    if(get_user_team(tid) != get_user_team(oid) && !gHasElectroPower[tid])
    {
      shExtraDamage(tid, oid, 50, "Electrocuted")
      message_begin(MSG_ONE, gmsgDamage, Origin, tid)
      write_byte(30) // dmg_save
      write_byte(30) // dmg_take
      write_long(1<<21) // visibleDamageBits
      write_coord(Origin[0]) // damageOrigin.x
      write_coord(Origin[1]) // damageOrigin.y
      write_coord(Origin[2]) // damageOrigin.z
      message_end()
    }
  }
//****Graphic****-----------------------------------------------------------------------
public LightningEffects(id,tid)
{
  new iRed,iGreen,iBlue,iWidth,iNoise
  iRed = random_num(0,100)
  iGreen = random_num(0,100)
  iBlue = random_num(100,255)
  iWidth = random_num(10,40)
  iNoise = random_num(10,40)

  if(iRed > iBlue) iBlue = (iRed + 10)
  if(iGreen > iBlue) iBlue = (iGreen + 10)
  if(iBlue > 255) iBlue = 255

  message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
  write_byte(8) //TE_BEAMENTS
  write_short(id)  // start entity
  write_short(tid)  // entity
  write_short(gSpriteLightning) // model/sprite
  write_byte(0) // starting frame
  write_byte(15)  // frame rate in 0.1's
  write_byte(10)  // life in 0.1's
  write_byte(iWidth)  // line width in 0.1's
  write_byte(iNoise)  // noise amplitude in 0.01's
  write_byte(iRed)  // Red
  write_byte(iGreen)  // Green
  write_byte(iBlue)  // Blue
  write_byte(190)  // brightness
  write_byte(0)  // scroll speed in 0.1's
  message_end()

  new origin[3]
  get_user_origin(tid,origin)
  message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
  write_byte(27) //TE_DLIGHT  dynamic light, effect world, minor entity effect
  write_coord(origin[0]) //initial position
  write_coord(origin[1])
  write_coord(origin[2])
  write_byte(20) //radius in 10's
  write_byte(230) //color red
  write_byte(230) //color green
  write_byte(0) //color blue
  write_byte(5) //life in 10's
  write_byte(10) //decay rate in 10's
  message_end()
}
//-****Sound Start****-------------------------------------------------------------------
public playSound(id)
{
  new parm[1]
  parm[0] = id

  emit_sound(id, CHAN_AUTO, "ambience/deadsignal1.wav", 1.0, ATTN_NORM, 0, PITCH_HIGH)
  set_task(1.5,"stopSound", 0, parm, 1)
}
//-****Sound Stop****--------------------------------------------------------------------
public stopSound(parm[])
{
  new sndStop=(1<<5)
  emit_sound(parm[0], CHAN_AUTO, "ambience/deadsignal1.wav", 1.0, ATTN_NORM, sndStop, PITCH_NORM)
}
//-****END****---------------------------------------------------------------------------



