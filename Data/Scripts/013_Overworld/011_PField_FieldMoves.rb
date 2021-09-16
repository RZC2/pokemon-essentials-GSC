#===============================================================================
# Hidden move handlers
#===============================================================================
class MoveHandlerHash < HandlerHash
  def initialize
    super(:PBMoves)
  end
end



module HiddenMoveHandlers
  CanUseMove     = MoveHandlerHash.new
  ConfirmUseMove = MoveHandlerHash.new
  UseMove        = MoveHandlerHash.new

  def self.addCanUseMove(item,proc);     CanUseMove.add(item,proc);     end
  def self.addConfirmUseMove(item,proc); ConfirmUseMove.add(item,proc); end
  def self.addUseMove(item,proc);        UseMove.add(item,proc);        end

  def self.hasHandler(item)
    return CanUseMove[item]!=nil && UseMove[item]!=nil
  end

  # Returns whether move can be used
  def self.triggerCanUseMove(item,pokemon,showmsg)
    return false if !CanUseMove[item]
    return CanUseMove.trigger(item,pokemon,showmsg)
  end

  # Returns whether the player confirmed that they want to use the move
  def self.triggerConfirmUseMove(item,pokemon)
    return true if !ConfirmUseMove[item]
    return ConfirmUseMove.trigger(item,pokemon)
  end

  # Returns whether move was used
  def self.triggerUseMove(item,pokemon)
    return false if !UseMove[item]
    return UseMove.trigger(item,pokemon)
  end
end



def pbCanUseHiddenMove?(pkmn,move,showmsg=true)
  return HiddenMoveHandlers.triggerCanUseMove(move,pkmn,showmsg)
end

def pbConfirmUseHiddenMove(pokemon,move)
  return HiddenMoveHandlers.triggerConfirmUseMove(move,pokemon)
end

def pbUseHiddenMove(pokemon,move)
  return HiddenMoveHandlers.triggerUseMove(move,pokemon)
end

# Unused
def pbHiddenMoveEvent
  Events.onAction.trigger(nil)
end

def pbCheckHiddenMoveBadge(badge=-1,showmsg=true)
  return true if badge<0   # No badge requirement
  return true if $DEBUG
  if (FIELD_MOVES_COUNT_BADGES) ? $Trainer.numbadges>=badge : $Trainer.badges[badge]
    return true
  end
  pbMessage(_INTL("Sorry, a new Badge is required.")) if showmsg
  return false
end



#===============================================================================
# Cut
#===============================================================================
def pbCut
  move = getID(PBMoves,:CUT)
  movefinder = pbCheckMove(move)
  if !pbCheckHiddenMoveBadge(BADGE_FOR_CUT,false) || (!$DEBUG && !movefinder)
    pbMessage(_INTL("This tree can be CUT!"))
    return false
  end
  pbMessage(_INTL("This tree can be CUT!\1"))
  if pbConfirmMessage(_INTL("Want to use CUT?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!",speciesname,PBMoves.getName(move)))
    return true
  end
  return false
end

HiddenMoveHandlers::CanUseMove.add(:CUT,proc { |move,pkmn,showmsg|
  next false if !pbCheckHiddenMoveBadge(BADGE_FOR_CUT,showmsg)
  facingEvent = $game_player.pbFacingEvent
  if !facingEvent || facingEvent.name.downcase!="tree"
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:CUT,proc { |move,pokemon|
  pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
  facingEvent = $game_player.pbFacingEvent
  if facingEvent
    pbSmashEvent(facingEvent)
  end
  next true
})

def pbSmashEvent(event)
  return if !event
  # TREE
  if event.name.downcase=="tree";    pbSEPlay("Cut",100)
    if PBDayNight.isMorning?
      pbMoveRoute(event,[
         PBMoveRoute::Graphic,"cuttree-a_animation",0,2,0,
         PBMoveRoute::Wait,4,
         PBMoveRoute::TurnLeft,
         PBMoveRoute::Wait,4,
         PBMoveRoute::TurnRight,
         PBMoveRoute::Wait,4,
         PBMoveRoute::TurnUp,
         PBMoveRoute::Wait,4
      ])
      pbWait(Graphics.frame_rate*4/10)
      event.erase
      $PokemonMap.addErasedEvent(event.id) if $PokemonMap
    elsif PBDayNight.isNight?
      pbMoveRoute(event,[
         PBMoveRoute::Graphic,"cuttree-c_animation",0,2,0,
         PBMoveRoute::Wait,4,
         PBMoveRoute::TurnLeft,
         PBMoveRoute::Wait,4,
         PBMoveRoute::TurnRight,
         PBMoveRoute::Wait,4,
         PBMoveRoute::TurnUp,
         PBMoveRoute::Wait,4
      ])
      pbWait(Graphics.frame_rate*4/10)
      event.erase
      $PokemonMap.addErasedEvent(event.id) if $PokemonMap
    else
      pbMoveRoute(event,[
         PBMoveRoute::Graphic,"cuttree-b_animation",0,2,0,
         PBMoveRoute::Wait,4,
         PBMoveRoute::TurnLeft,
         PBMoveRoute::Wait,4,
         PBMoveRoute::TurnRight,
         PBMoveRoute::Wait,4,
         PBMoveRoute::TurnUp,
         PBMoveRoute::Wait,4
      ])
      pbWait(Graphics.frame_rate*4/10)
      event.erase
      $PokemonMap.addErasedEvent(event.id) if $PokemonMap
    end
	# ROCK
  elsif event.name.downcase=="rock"; pbSEPlay("Rock Smash",100)
    pbShake(5,9,8)
	pbWait(8)
	pbMoveRoute(event,[
	   PBMoveRoute::StepAnimeOn,
	   PBMoveRoute::Wait,8
	])
	pbWait(Graphics.frame_rate*4/10)
	event.erase
	$PokemonMap.addErasedEvent(event.id) if $PokemonMap
  end
end



#===============================================================================
# Dig
#===============================================================================
HiddenMoveHandlers::CanUseMove.add(:DIG,proc { |move,pkmn,showmsg|
  escape = ($PokemonGlobal.escapePoint rescue nil)
  if !escape || escape==[]
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  if $game_player.pbHasDependentEvents?
    pbMessage(_INTL("It can't be used when you have someone with you.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::ConfirmUseMove.add(:DIG,proc { |move,pkmn|
  escape = ($PokemonGlobal.escapePoint rescue nil)
  next false if !escape || escape==[]
  mapname = pbGetMapNameFromId(escape[0])
  next pbConfirmMessage(_INTL("Want to escape from here and return to {1}?",mapname))
})

HiddenMoveHandlers::UseMove.add(:DIG,proc { |move,pokemon|
  escape = ($PokemonGlobal.escapePoint rescue nil)
  if escape
    pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
    pbFadeOutIn {
      $game_temp.player_new_map_id    = escape[0]
      $game_temp.player_new_x         = escape[1]
      $game_temp.player_new_y         = escape[2]
      $game_temp.player_new_direction = escape[3]
      $scene.transfer_player
      $game_map.autoplay
      $game_map.refresh
    }
    pbEraseEscapePoint
    next true
  end
  next false
})



#===============================================================================
# Dive
#===============================================================================
def pbDive
  divemap = pbGetMetadata($game_map.map_id,MetadataDiveMap)
  return false if !divemap
  move = getID(PBMoves,:DIVE)
  movefinder = pbCheckMove(move)
  if !pbCheckHiddenMoveBadge(BADGE_FOR_DIVE,false) || (!$DEBUG && !movefinder)
    pbMessage(_INTL("The sea is deep here. A POKéMON may be able to go underwater."))
    return false
  end
  if pbConfirmMessage(_INTL("The sea is deep here. Would you like to use DIVE?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!",speciesname,PBMoves.getName(move)))
    pbFadeOutIn {
       $game_temp.player_new_map_id    = divemap
       $game_temp.player_new_x         = $game_player.x
       $game_temp.player_new_y         = $game_player.y
       $game_temp.player_new_direction = $game_player.direction
       $PokemonGlobal.surfing = false
       $PokemonGlobal.diving  = true
       pbUpdateVehicle
       $scene.transfer_player(false)
       $game_map.autoplay
       $game_map.refresh
    }
    return true
  end
  return false
end

def pbSurfacing
  return if !$PokemonGlobal.diving
  divemap = nil
  meta = pbLoadMetadata
  for i in 0...meta.length
    if meta[i] && meta[i][MetadataDiveMap] && meta[i][MetadataDiveMap]==$game_map.map_id
      divemap = i; break
    end
  end
  return if !divemap
  move = getID(PBMoves,:DIVE)
  movefinder = pbCheckMove(move)
  if !pbCheckHiddenMoveBadge(BADGE_FOR_DIVE,false) || (!$DEBUG && !movefinder)
    pbMessage(_INTL("Light is filtering down from above. A POKéMON may be able to surface here."))
    return false
  end
  if pbConfirmMessage(_INTL("Light is filtering down from above. Would you like to use DIVE?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!",speciesname,PBMoves.getName(move)))
    pbFadeOutIn {
       $game_temp.player_new_map_id    = divemap
       $game_temp.player_new_x         = $game_player.x
       $game_temp.player_new_y         = $game_player.y
       $game_temp.player_new_direction = $game_player.direction
       $PokemonGlobal.surfing = true
       $PokemonGlobal.diving  = false
       pbUpdateVehicle
       $scene.transfer_player(false)
       surfbgm = pbGetMetadata(0,MetadataSurfBGM)
       (surfbgm) ?  pbBGMPlay(surfbgm) : $game_map.autoplayAsCue
       $game_map.refresh
    }
    return true
  end
  return false
end

def pbTransferUnderwater(mapid,x,y,direction=$game_player.direction)
  pbFadeOutIn {
    $game_temp.player_new_map_id    = mapid
    $game_temp.player_new_x         = x
    $game_temp.player_new_y         = y
    $game_temp.player_new_direction = direction
    $scene.transfer_player(false)
    $game_map.autoplay
    $game_map.refresh
  }
end

Events.onAction += proc { |_sender,_e|
  if $PokemonGlobal.diving
    if DIVING_SURFACE_ANYWHERE
      pbSurfacing
    else
      divemap = nil
      meta = pbLoadMetadata
      for i in 0...meta.length
        if meta[i] && meta[i][MetadataDiveMap] && meta[i][MetadataDiveMap]==$game_map.map_id
          divemap = i; break
        end
      end
      if divemap && PBTerrain.isDeepWater?($MapFactory.getTerrainTag(divemap,$game_player.x,$game_player.y))
        pbSurfacing
      end
    end
  else
    pbDive if PBTerrain.isDeepWater?($game_player.terrain_tag)
  end
}

HiddenMoveHandlers::CanUseMove.add(:DIVE,proc { |move,pkmn,showmsg|
  next false if !pbCheckHiddenMoveBadge(BADGE_FOR_DIVE,showmsg)
  if $PokemonGlobal.diving
    next true if DIVING_SURFACE_ANYWHERE
    divemap = nil
    meta = pbLoadMetadata
    for i in 0...meta.length
      if meta[i] && meta[i][MetadataDiveMap] && meta[i][MetadataDiveMap]==$game_map.map_id
        divemap = i; break
      end
    end
    if !PBTerrain.isDeepWater?($MapFactory.getTerrainTag(divemap,$game_player.x,$game_player.y))
      pbMessage(_INTL("Can't use that here.")) if showmsg
      next false
    end
  else
    if !pbGetMetadata($game_map.map_id,MetadataDiveMap)
      pbMessage(_INTL("Can't use that here.")) if showmsg
      next false
    end
    if !PBTerrain.isDeepWater?($game_player.terrain_tag)
      pbMessage(_INTL("Can't use that here.")) if showmsg
      next false
    end
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:DIVE,proc { |move,pokemon|
  wasdiving = $PokemonGlobal.diving
  if $PokemonGlobal.diving
    divemap = nil
    meta = pbLoadMetadata
    for i in 0...meta.length
      if meta[i] && meta[i][MetadataDiveMap] && meta[i][MetadataDiveMap]==$game_map.map_id
        divemap = i; break
      end
    end
  else
    divemap = pbGetMetadata($game_map.map_id,MetadataDiveMap)
  end
  next false if !divemap
  pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
  pbFadeOutIn {
    $game_temp.player_new_map_id    = divemap
    $game_temp.player_new_x         = $game_player.x
    $game_temp.player_new_y         = $game_player.y
    $game_temp.player_new_direction = $game_player.direction
    $PokemonGlobal.surfing = wasdiving
    $PokemonGlobal.diving  = !wasdiving
    pbUpdateVehicle
    $scene.transfer_player(false)
    $game_map.autoplay
    $game_map.refresh
  }
  next true
})



#===============================================================================
# Flash
#===============================================================================
HiddenMoveHandlers::CanUseMove.add(:FLASH,proc { |move,pkmn,showmsg|
  next false if !pbCheckHiddenMoveBadge(BADGE_FOR_FLASH,showmsg)
  if !pbGetMetadata($game_map.map_id,MetadataDarkMap)
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  if $PokemonGlobal.flashUsed
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:FLASH,proc { |move,pokemon|
  #darkness = $PokemonTemp.darknessSprite
  #next false if !darkness || darkness.disposed?
  pbMessage(_INTL("A blinding FLASH lights the \\se[Flash]area!")) #,pokemon.name,PBMoves.getName(move)))
  pbWait(8)
  $PokemonGlobal.flashUsed = true
  #radiusDiff = 8*20/Graphics.frame_rate
  #while darkness.radius<darkness.radiusMax
  #  Graphics.update
  #  Input.update
    pbUpdateSceneMap
  #  darkness.radius += radiusDiff
  #  darkness.radius = darkness.radiusMax if darkness.radius>darkness.radiusMax
  #end

  next true
})



#===============================================================================
# Fly
#===============================================================================
HiddenMoveHandlers::CanUseMove.add(:FLY,proc { |move,pkmn,showmsg|
  next false if !pbCheckHiddenMoveBadge(BADGE_FOR_FLY,showmsg)
  if $game_player.pbHasDependentEvents?
    pbMessage(_INTL("It can't be used when you have someone with you.")) if showmsg
    next false
  end
  if !pbGetMetadata($game_map.map_id,MetadataOutdoor)
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:FLY,proc { |move,pokemon|
  if !$PokemonTemp.flydata
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
  pbFadeOutIn {
    $game_temp.player_new_map_id    = $PokemonTemp.flydata[0]
    $game_temp.player_new_x         = $PokemonTemp.flydata[1]
    $game_temp.player_new_y         = $PokemonTemp.flydata[2]
    $game_temp.player_new_direction = 2
    $PokemonTemp.flydata = nil
    $scene.transfer_player
    $game_map.autoplay
    $game_map.refresh
  }
  pbEraseEscapePoint
  next true
})



#===============================================================================
# Headbutt
#===============================================================================
def pbHeadbuttEffect(event)
  a=((event[1]*event[2]+event[1]*event[2])/5)%10
  b=($Trainer.id&0xFFFF)%10
  chance=1
  if a==b
    chance=8
  elsif a>b && (a-b).abs<5
    chance=5
  elsif a<b && (a-b).abs>5
    chance=5
  end
  if rand(10)>=chance
    pbMessage(_INTL("Nope. Nothing..."))
  else
    if !pbEncounter(chance==1 ? EncounterTypes::HeadbuttLow : EncounterTypes::HeadbuttHigh)
      pbMessage(_INTL("Nope. Nothing..."))
    end
  end
end

def pbHeadbutt(event)
  movefinder=pbCheckMove(:HEADBUTT)
  if $DEBUG || movefinder
    if pbConfirmMessage(_INTL("A POKéMON could be in this tree.\nWant to HEADBUTT it?"))
      speciesname=!movefinder ? $Trainer.name : movefinder.name
      pbMessage(_INTL("{1} did a HEADBUTT!",speciesname))
      pbHeadbuttEffect(event)
    end
  else
    pbMessage(_INTL("A POKéMON could be in this tree."))
  end
  Input.update
  return
end

Events.onAction+=proc{|sender,e|
   terrain=pbFacingTerrainTag
   notCliff=$game_map.passable?($game_player.x,$game_player.y,$game_player.direction)
   if PBTerrain.isHeadbutt?(terrain)
     pbHeadbutt(pbFacingTile)
     return
   end
}

HiddenMoveHandlers::CanUseMove.add(:HEADBUTT,proc{|move,pkmn,showmsg|
   facingEvent=$game_player.pbFacingEvent
   if !facingEvent || facingEvent.name!="HeadbuttTree"
     pbMessage(_INTL("Can't use that here.")) if showmsg
     return false
   end
   return true
})

HiddenMoveHandlers::UseMove.add(:HEADBUTT,proc{|move,pokemon|
   if !pbHiddenMoveAnimation(pokemon)
     pbMessage(_INTL("{1} did a HEADBUTT!",pokemon.name))
   end
   facingEvent=$game_player.pbFacingEvent
   pbHeadbuttEffect(facingEvent)
}) 



#===============================================================================
# Rock Smash
#===============================================================================
def pbRockSmashRandomEncounter
  if rand(100)<25
    pbEncounter(EncounterTypes::RockSmash)
  end
end

def pbRockSmash
  move = getID(PBMoves,:ROCKSMASH)
  movefinder = pbCheckMove(move)
  if !pbCheckHiddenMoveBadge(BADGE_FOR_ROCKSMASH,false) || (!$DEBUG && !movefinder)
    pbMessage(_INTL("Maybe a POKéMON can break this."))
    return false
  end
  if pbConfirmMessage(_INTL("This rock looks breakable.\nWant to use ROCK SMASH?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!",speciesname,PBMoves.getName(move)))
    return true
  end
  return false
end

HiddenMoveHandlers::CanUseMove.add(:ROCKSMASH,proc { |move,pkmn,showmsg|
  next false if !pbCheckHiddenMoveBadge(BADGE_FOR_ROCKSMASH,showmsg)
  facingEvent = $game_player.pbFacingEvent
  if !facingEvent || facingEvent.name.downcase!="rock"
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:ROCKSMASH,proc { |move,pokemon|
  pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
  facingEvent = $game_player.pbFacingEvent
  if facingEvent
    pbSmashEvent(facingEvent)
    pbRockSmashRandomEncounter
  end
  next true
})



#===============================================================================
# Strength
#===============================================================================
def pbStrength
  if $PokemonMap.strengthUsed
    pbMessage(_INTL("STRENGTH made it possible to move boulders around."))
    return false
  end
  move = getID(PBMoves,:STRENGTH)
  movefinder = pbCheckMove(move)
  if !pbCheckHiddenMoveBadge(BADGE_FOR_STRENGTH,false) || (!$DEBUG && !movefinder)
    pbMessage(_INTL("It's a big boulder, but a POKéMON may be able to push it aside."))
    return false
  end
  pbMessage(_INTL("It's a big boulder, but a POKéMON may be able to push it aside.\1"))
  if pbConfirmMessage(_INTL("Would you like to use STRENGTH?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!",speciesname,PBMoves.getName(move)))
    pbMessage(_INTL("{1}'s STRENGTH made it possible to move boulders around!",speciesname))
    $PokemonMap.strengthUsed = true
    return true
  end
  return false
end

Events.onAction += proc { |_sender,_e|
  facingEvent = $game_player.pbFacingEvent
  pbStrength if facingEvent && facingEvent.name.downcase=="boulder"
}

HiddenMoveHandlers::CanUseMove.add(:STRENGTH,proc { |move,pkmn,showmsg|
  next false if !pbCheckHiddenMoveBadge(BADGE_FOR_STRENGTH,showmsg)
  if $PokemonMap.strengthUsed
    pbMessage(_INTL("STRENGTH is already being used.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:STRENGTH,proc { |move,pokemon|
  pbMessage(_INTL("{1} used {2}!\1",pokemon.name,PBMoves.getName(move)))
  pbMessage(_INTL("{1}'s STRENGTH made it possible to move boulders around!",pokemon.name))
  $PokemonMap.strengthUsed = true
  next true
})



#===============================================================================
# Surf
#===============================================================================
def pbSurf
  return false if $game_player.pbFacingEvent
  return false if $game_player.pbHasDependentEvents?
  move = getID(PBMoves,:SURF)
  movefinder = pbCheckMove(move)
  if !pbCheckHiddenMoveBadge(BADGE_FOR_SURF,false) || (!$DEBUG && !movefinder)
    return false
  end
  if pbConfirmMessage(_INTL("The water is calm.\nWant to SURF?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!",speciesname,PBMoves.getName(move)))
    pbCancelVehicles
    surfbgm = pbGetMetadata(0,MetadataSurfBGM)
    pbCueBGM(surfbgm,0.5) if surfbgm
    pbStartSurfing
    return true
  end
  return false
end

def pbStartSurfing
  pbCancelVehicles
  $PokemonEncounters.clearStepCount
  $PokemonGlobal.surfing = true
  pbUpdateVehicle
  $PokemonTemp.surfJump = $MapFactory.getFacingCoords($game_player.x,$game_player.y,$game_player.direction)
  pbJumpToward
  $PokemonTemp.surfJump = nil
  $game_player.check_event_trigger_here([1,2])
end

def pbEndSurf(_xOffset,_yOffset)
  return false if !$PokemonGlobal.surfing
  x = $game_player.x
  y = $game_player.y
  currentTag = $game_map.terrain_tag(x,y)
  facingTag = pbFacingTerrainTag
  if PBTerrain.isSurfable?(currentTag) && !PBTerrain.isSurfable?(facingTag)
    $PokemonTemp.surfJump = [x,y]
    if pbJumpToward(1,false,true)
      $game_map.autoplayAsCue
      $game_player.increase_steps
      result = $game_player.check_event_trigger_here([1,2])
      pbOnStepTaken(result)
    end
    $PokemonTemp.surfJump = nil
    return true
  end
  return false
end

def pbTransferSurfing(mapid,xcoord,ycoord,direction=$game_player.direction)
  pbFadeOutIn {
    $game_temp.player_new_map_id    = mapid
    $game_temp.player_new_x         = xcoord
    $game_temp.player_new_y         = ycoord
    $game_temp.player_new_direction = direction
    $scene.transfer_player(false)
    $game_map.autoplay
    $game_map.refresh
  }
end

Events.onAction += proc { |_sender,_e|
  next if $PokemonGlobal.surfing
  next if pbGetMetadata($game_map.map_id,MetadataBicycleAlways)
  next if !PBTerrain.isSurfable?(pbFacingTerrainTag)
  next if !$game_map.passable?($game_player.x,$game_player.y,$game_player.direction,$game_player)
  pbSurf
}

HiddenMoveHandlers::CanUseMove.add(:SURF,proc { |move,pkmn,showmsg|
  next false if !pbCheckHiddenMoveBadge(BADGE_FOR_SURF,showmsg)
  if $PokemonGlobal.surfing
    pbMessage(_INTL("You're already surfing.")) if showmsg
    next false
  end
  if $game_player.pbHasDependentEvents?
    pbMessage(_INTL("It can't be used when you have someone with you.")) if showmsg
    next false
  end
  if pbGetMetadata($game_map.map_id,MetadataBicycleAlways)
    pbMessage(_INTL("Let's enjoy cycling!")) if showmsg
    next false
  end
  if !PBTerrain.isSurfable?(pbFacingTerrainTag) ||
     !$game_map.passable?($game_player.x,$game_player.y,$game_player.direction,$game_player)
    pbMessage(_INTL("No surfing here!")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:SURF,proc { |move,pokemon|
  $game_temp.in_menu = false
  pbCancelVehicles
  pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
  surfbgm = pbGetMetadata(0,MetadataSurfBGM)
  pbCueBGM(surfbgm,0.5) if surfbgm
  pbStartSurfing
  next true
})



#===============================================================================
# Sweet Scent
#===============================================================================
def pbSweetScent
  if $game_screen.weather_type!=PBFieldWeather::None
    pbMessage(_INTL("The sweet scent faded for some reason..."))
    return
  end
  viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
  viewport.z = 99999
  count = 0
  viewport.color.red   = 255
  viewport.color.green = 0
  viewport.color.blue  = 0
  viewport.color.alpha -= 10
  alphaDiff = 12 * 20 / Graphics.frame_rate
  loop do
    if count==0 && viewport.color.alpha<128
      viewport.color.alpha += alphaDiff
    elsif count>Graphics.frame_rate/4
      viewport.color.alpha -= alphaDiff
    else
      count += 1
    end
    Graphics.update
    Input.update
    pbUpdateSceneMap
    break if viewport.color.alpha<=0
  end
  viewport.dispose
  enctype = $PokemonEncounters.pbEncounterType
  if enctype<0 || !$PokemonEncounters.isEncounterPossibleHere? ||
     !pbEncounter(enctype)
    pbMessage(_INTL("There appears to be nothing here..."))
  end
end

HiddenMoveHandlers::CanUseMove.add(:SWEETSCENT,proc { |move,pkmn,showmsg|
  next true
})

HiddenMoveHandlers::UseMove.add(:SWEETSCENT,proc { |move,pokemon|
  pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
  pbSweetScent
  next true
})



#===============================================================================
# Teleport
#===============================================================================
HiddenMoveHandlers::CanUseMove.add(:TELEPORT,proc { |move,pkmn,showmsg|
  if !pbGetMetadata($game_map.map_id,MetadataOutdoor)
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  healing = $PokemonGlobal.healingSpot
  healing = pbGetMetadata(0,MetadataHome) if !healing   # Home
  if !healing
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  if $game_player.pbHasDependentEvents?
    pbMessage(_INTL("It can't be used when you have someone with you.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::ConfirmUseMove.add(:TELEPORT,proc { |move,pkmn|
  healing = $PokemonGlobal.healingSpot
  healing = pbGetMetadata(0,MetadataHome) if !healing   # Home
  next false if !healing
  mapname = pbGetMapNameFromId(healing[0])
  next pbConfirmMessage(_INTL("Want to return to the healing spot used last in {1}?",mapname))
})

HiddenMoveHandlers::UseMove.add(:TELEPORT,proc { |move,pokemon|
  healing = $PokemonGlobal.healingSpot
  healing = pbGetMetadata(0,MetadataHome) if !healing   # Home
  next false if !healing
  pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
  pbFadeOutIn {
    $game_temp.player_new_map_id    = healing[0]
    $game_temp.player_new_x         = healing[1]
    $game_temp.player_new_y         = healing[2]
    $game_temp.player_new_direction = 2
    $scene.transfer_player
    $game_map.autoplay
    $game_map.refresh
  }
  pbEraseEscapePoint
  next true
})



#===============================================================================
# Waterfall
#===============================================================================
def pbAscendWaterfall(event=nil)
  event = $game_player if !event
  return if !event
  return if event.direction!=8   # can't ascend if not facing up
  oldthrough   = event.through
  oldmovespeed = event.move_speed
  terrain = pbFacingTerrainTag
  return if !PBTerrain.isWaterfall?(terrain)
  event.through = true
  event.move_speed = 2
  loop do
    event.move_up
    terrain = pbGetTerrainTag(event)
    break if !PBTerrain.isWaterfall?(terrain)
  end
  event.through    = oldthrough
  event.move_speed = oldmovespeed
end

def pbDescendWaterfall(event=nil)
  event = $game_player if !event
  return if !event
  return if event.direction!=2   # Can't descend if not facing down
  oldthrough   = event.through
  oldmovespeed = event.move_speed
  terrain = pbFacingTerrainTag
  return if !PBTerrain.isWaterfall?(terrain)
  event.through = true
  event.move_speed = 2
  loop do
    event.move_down
    terrain = pbGetTerrainTag(event)
    break if !PBTerrain.isWaterfall?(terrain)
  end
  event.through    = oldthrough
  event.move_speed = oldmovespeed
end

def pbWaterfall
  move = getID(PBMoves,:WATERFALL)
  movefinder = pbCheckMove(move)
  if !pbCheckHiddenMoveBadge(BADGE_FOR_WATERFALL,false) || (!$DEBUG && !movefinder)
    pbMessage(_INTL("A wall of water is crashing down with a mighty roar."))
    return false
  end
  if pbConfirmMessage(_INTL("Do you want to use WATERFALL?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!",speciesname,PBMoves.getName(move)))
    pbAscendWaterfall
    return true
  end
  return false
end

Events.onAction += proc { |_sender,_e|
  terrain = pbFacingTerrainTag
  if terrain==PBTerrain::Waterfall
    pbWaterfall
  elsif terrain==PBTerrain::WaterfallCrest
    pbMessage(_INTL("A wall of water is crashing down with a mighty roar."))
  end
}

HiddenMoveHandlers::CanUseMove.add(:WATERFALL,proc { |move,pkmn,showmsg|
  next false if !pbCheckHiddenMoveBadge(BADGE_FOR_WATERFALL,showmsg)
  if pbFacingTerrainTag!=PBTerrain::Waterfall
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:WATERFALL,proc { |move,pokemon|
  pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
  pbAscendWaterfall
  next true
})

#===============================================================================
# Defog
#===============================================================================
def pbDefog
  $game_screen.weather(0,0,0)
end

HiddenMoveHandlers::CanUseMove.add(:DEFOG,proc { |move,pkmn,showmsg|
  next false if $game_screen.weather_type!=PBFieldWeather::Fog
  next true
})

HiddenMoveHandlers::UseMove.add(:DEFOG,proc { |move,pokemon|
  pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
  pbDefog
  next true
})

