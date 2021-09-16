def pbSave(safesave=false)
  $Trainer.metaID=$PokemonGlobal.playerID
  begin
    File.open(RTP.getSaveFileName("Game.rxdata"),"wb") { |f|
       Marshal.dump($Trainer,f)
       Marshal.dump(Graphics.frame_count,f)
       if $data_system.respond_to?("magic_number")
         $game_system.magic_number = $data_system.magic_number
       else
         $game_system.magic_number = $data_system.version_id
       end
       $game_system.save_count+=1
       Marshal.dump($game_system,f)
       Marshal.dump($PokemonSystem,f)
       Marshal.dump($game_map.map_id,f)
       Marshal.dump($game_switches,f)
       Marshal.dump($game_variables,f)
       Marshal.dump($game_self_switches,f)
       Marshal.dump($game_screen,f)
       Marshal.dump($MapFactory,f)
       Marshal.dump($game_player,f)
       $PokemonGlobal.safesave=safesave
       Marshal.dump($PokemonGlobal,f)
       Marshal.dump($PokemonMap,f)
       Marshal.dump($PokemonBag,f)
       Marshal.dump($PokemonStorage,f)
       Marshal.dump(ESSENTIALS_VERSION,f)
    }
    Graphics.frame_reset
  rescue
    return false
  end
  return true
end

def pbEmergencySave
  oldscene=$scene
  $scene=nil
  pbMessage(_INTL("The script is taking too long. The game will restart."))
  return if !$Trainer
  if safeExists?(RTP.getSaveFileName("Game.rxdata"))
    File.open(RTP.getSaveFileName("Game.rxdata"),  'rb') { |r|
      File.open(RTP.getSaveFileName("Game.rxdata.bak"), 'wb') { |w|
        while s = r.read(4096)
          w.write s
        end
      }
    }
  end
  if pbSave
    pbMessage(_INTL("\\ts[2]SAVING... DON'T TURN OFF THE \\wtnp[1]POWER.\\wtnp[25]"))
    pbMessage(_INTL("\\se[]\\ts[2]The game was saved.\\me[GUI save game] The previous save file has been backed up.\\wtnp[30]"))
  else
    pbMessage(_INTL("\\se[]Save failed.\\wtnp[30]"))
  end
  $scene=oldscene
end



class PokemonSave_Scene
  def pbStartScreen
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @sprites={}
    totalsec = Graphics.frame_count / Graphics.frame_rate
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    mapname=$game_map.name
    loctext=_INTL("PLAYER<r><c2=0000ffff>{1}</c2><br>",$Trainer.name) # +
	loctext+=_INTL("BADGES<r><c2=0000ffff>{1}</c2><br>",$Trainer.numbadges)
	if $Trainer.pokedex
      loctext+=_INTL("POKéDEX<r><c2=0000ffff>{1}</c2><br>",$Trainer.pokedexOwned) #$Trainer.pokedexSeen
    end
    if hour>0
      loctext+=_INTL("TIME<r><c2=0000ffff>{1}h {2}m</c2><br>",hour,min)
    else
      loctext+=_INTL("TIME<r><c2=0000ffff>{1}m</c2><br>",min)
    end
    @sprites["locwindow"]=Window_AdvancedTextPokemon.new(loctext)
    @sprites["locwindow"].viewport=@viewport
    @sprites["locwindow"].x=0
    @sprites["locwindow"].y=0
    @sprites["locwindow"].width=228 if @sprites["locwindow"].width<228
    @sprites["locwindow"].visible=true
  end

  def pbEndScreen
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end



class PokemonSaveScreen
  def initialize(scene)
    @scene=scene
  end

  def pbDisplay(text,brief=false)
    @scene.pbDisplay(text,brief)
  end

  def pbDisplayPaused(text)
    @scene.pbDisplayPaused(text)
  end

  def pbConfirm(text)
    return @scene.pbConfirm(text)
  end

  def pbSaveScreen
    ret=false
    @scene.pbStartScreen
    if pbConfirmMessage(_INTL("Would you like to save the game?"))
      if safeExists?(RTP.getSaveFileName("Game.rxdata"))
        if $PokemonTemp.begunNewGame
          pbMessage(_INTL("WARNING!"))
          pbMessage(_INTL("There is a different game file that is already saved."))
          pbMessage(_INTL("If you save now, the other file's adventure, including items and POKéMON, will be entirely lost."))
          if !pbConfirmMessageSerious(
             _INTL("Are you sure you want to save now and overwrite the other save file?"))
            @scene.pbEndScreen
            return false
          end
		  else
		  if !pbConfirmMessage(_INTL("There is already a save file. Is it OK to overwrite?"))
		  @scene.pbEndScreen
		  return false
		  end
        end
      end
      $PokemonTemp.begunNewGame=false
      if pbSave
	    pbMessage(_INTL("\\ts[2]SAVING... DON'T TURN OFF THE \\wtnp[1]POWER.\\wtnp[25]"))
        pbMessage(_INTL("\\se[]\\ts[2]{1} saved the game.\\me[GUI save game]\\wtnp[30]",$Trainer.name))
        ret=true
      else
        pbMessage(_INTL("\\se[]Save failed.\\wtnp[30]"))
        ret=false
      end
    end
    @scene.pbEndScreen
    return ret
  end
end



def pbSaveScreen
  scene = PokemonSave_Scene.new
  screen = PokemonSaveScreen.new(scene)
  ret = screen.pbSaveScreen
  return ret
end
