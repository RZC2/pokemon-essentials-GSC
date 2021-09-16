#===============================================================================
# * Egg Hatch Animation - by FL (Credits will be apreciated)
#                         Tweaked by Maruno
#                         Tweaked for GSC by Caruban
#===============================================================================
# This script is for Pokémon Essentials. It's an egg hatch animation that
# works even with special eggs like Manaphy egg.
#===============================================================================
# To this script works, put it above Main and put a picture (a 3 frames
# sprite sheet) with egg sprite height and 3 times the egg sprite width at
# Graphics/Battlers/eggCracks.
#===============================================================================
class PokemonEggHatch_Scene
  def pbStartScene(pokemon)
    @sprites={}
    @pokemon=pokemon
    @nicknamed=false
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    # Create background image
    addBackgroundOrColoredPlane(@sprites,"background","hatchbg",
       Color.new(248,248,248),@viewport)
    # Create egg sprite/Pokémon sprite
    @sprites["pokemon"]=PokemonSprite.new(@viewport)
    @sprites["pokemon"].setOffset(PictureOrigin::Bottom)
    @sprites["pokemon"].x = Graphics.width/2
    @sprites["pokemon"].y = 264+56 -120  # 56 to offset the egg sprite 120 offset GSC
    @sprites["pokemon"].mirror = true
    @sprites["pokemon"].setSpeciesBitmap(@pokemon.species,@pokemon.female?,
                                         (@pokemon.form rescue 0),@pokemon.shiny?,
                                         false,false,true)   # Egg sprite
    # Load egg cracks bitmap
    crackfilename=sprintf("Graphics/Battlers/%seggCracks",
       getConstantName(PBSpecies,@pokemon.species)) rescue nil
    if !pbResolveBitmap(crackfilename)
      crackfilename=sprintf("Graphics/Battlers/%03deggCracks",@pokemon.species)
      crackfilename=sprintf("Graphics/Battlers/eggCracks") if !pbResolveBitmap(crackfilename)
    end
    crackfilename=pbResolveBitmap(crackfilename)
    @hatchSheet=AnimatedBitmap.new(crackfilename)
    # Create egg cracks sprite
    @sprites["hatch"]=SpriteWrapper.new(@viewport)
    @sprites["hatch"].x = @sprites["pokemon"].x
    @sprites["hatch"].y = @sprites["pokemon"].y
    @sprites["hatch"].ox = @sprites["pokemon"].ox
    @sprites["hatch"].oy = @sprites["pokemon"].oy
    @sprites["hatch"].bitmap = @hatchSheet.bitmap
    @sprites["hatch"].src_rect = Rect.new(0,0,@hatchSheet.width/3,@hatchSheet.height)
    @sprites["hatch"].visible = false
    # Load Flashes bitmap
    crackfilename=sprintf("Graphics/Battlers/EggCrackEffect") rescue nil
    crackfilename=pbResolveBitmap(crackfilename)
    @flashSheet=AnimatedBitmap.new(crackfilename)
    # Create egg flash sprite
    @sprites["flash"]=SpriteWrapper.new(@viewport)
    @sprites["flash"].x = 0
    @sprites["flash"].y = 0
    @sprites["flash"].bitmap = @flashSheet.bitmap
    @sprites["flash"].src_rect = Rect.new(0,0,@flashSheet.width/18,@flashSheet.height)
    @sprites["flash"].visible = false
    # Create flash overlay
    @sprites["overlay"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["overlay"].z=200
    @sprites["overlay"].bitmap=Bitmap.new(Graphics.width,Graphics.height)
    @sprites["overlay"].bitmap.fill_rect(0,0,Graphics.width,Graphics.height,
        Color.new(255,255,255))
    @sprites["overlay"].opacity=0
    # Start up scene
    pbFadeInAndShow(@sprites)
  end

  def pbMain
    pbBGMPlay("Evolution")
    # Egg animation
    updateScene(Graphics.frame_rate)
	#
    pbSEPlay("Battle ball shake")
    swingEgg(6,1)
    updateScene(Graphics.frame_rate/2)
    pbSEPlay("Battle ball shake")
    swingEgg(6,3)
    updateScene(Graphics.frame_rate/2)
    pbSEPlay("Battle ball shake")
    swingEgg(6,4)
    pbPositionHatchMask(0)#
    updateScene(Graphics.frame_rate/2)
    pbSEPlay("Battle ball shake")
    swingEgg(6,6)
    pbPositionHatchMask(1)#
    updateScene(Graphics.frame_rate/2)
    pbSEPlay("Battle ball shake")
    swingEgg(6,6)
    pbPositionHatchMask(2)#
    updateScene(Graphics.frame_rate/2)
    pbSEPlay("Battle ball shake")
    swingEgg(6,6)
    updateScene(Graphics.frame_rate/2)
	#
    pbSEPlay("Battle recall")
    @sprites["flash"].visible = true
    for i in 0..3
      pbPositionFlash(i)
      updateScene(Graphics.frame_rate/40)
    end
    # Fade and change the sprite
    #fadeTime = Graphics.frame_rate*4/10
    #toneDiff = (255.0/fadeTime).ceil
    #for i in 1..fadeTime
    #  @sprites["pokemon"].tone=Tone.new(i*toneDiff,i*toneDiff,i*toneDiff)
    #  @sprites["overlay"].opacity=i*toneDiff
    #  updateScene
    #end
    
    #updateScene(Graphics.frame_rate*3/4)
    @sprites["pokemon"].setPokemonBitmap(@pokemon) # Pokémon sprite
    @sprites["pokemon"].x = Graphics.width/2
    @sprites["pokemon"].y = 264 -120
    pbApplyBattlerMetricsToSprite(@sprites["pokemon"],1,@pokemon.fSpecies)
    @sprites["hatch"].visible=false
    #for i in 1..fadeTime
    #  @sprites["pokemon"].tone=Tone.new(255-i*toneDiff,255-i*toneDiff,255-i*toneDiff)
    #  @sprites["overlay"].opacity=255-i*toneDiff
    #  updateScene
    #end
    for i in 4..18
      pbPositionFlash(i)
      updateScene(Graphics.frame_rate/40)
    end
    #@sprites["pokemon"].tone=Tone.new(0,0,0)
    @sprites["overlay"].opacity=0
    # Finish scene
    frames=pbCryFrameLength(@pokemon)
    pbPlayCry(@pokemon)
    updateScene(frames)
    pbBGMStop()
    pbMEPlay("Evolution success")
    pbMessage(_INTL("\\se[]{1} came out of its EGG!\\wt[80]",@pokemon.name)) { update }
    if pbConfirmMessage(
        _INTL("Give a nickname to {1}?",@pokemon.name)) { update }
      nickname=pbEnterPokemonName(_INTL("{1}'s nickname?",@pokemon.name),
         0,PokeBattle_Pokemon::MAX_POKEMON_NAME_SIZE,"",@pokemon,true)
      @pokemon.name=nickname if nickname!=""
      @nicknamed=true
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { update } if !@nicknamed
    pbDisposeSpriteHash(@sprites)
    @hatchSheet.dispose
    @viewport.dispose
  end

  def pbPositionHatchMask(index)
    @sprites["hatch"].src_rect.x = index*@sprites["hatch"].src_rect.width
  end
  
  def pbPositionFlash(index)
    @sprites["flash"].src_rect.x = index*@sprites["flash"].src_rect.width
  end

  def swingEgg(speed,swingTimes=1)
    @sprites["hatch"].visible = true
    speed = speed.to_f*20/Graphics.frame_rate
    amplitude = 6
    targets = []
    swingTimes.times do
      targets.push(@sprites["pokemon"].x+amplitude)
      targets.push(@sprites["pokemon"].x-amplitude)
    end
    targets.push(@sprites["pokemon"].x)
    targets.each_with_index do |target,i|
      loop do
        break if i%2==0 && @sprites["pokemon"].x>=target
        break if i%2==1 && @sprites["pokemon"].x<=target
        @sprites["pokemon"].x += speed
        @sprites["hatch"].x    = @sprites["pokemon"].x
        updateScene
      end
      speed *= -1
    end
    @sprites["pokemon"].x = targets[targets.length-1]
    @sprites["hatch"].x   = @sprites["pokemon"].x
  end

  def updateScene(frames=1)   # Can be used for "wait" effect
    frames.times do
      Graphics.update
      Input.update
      self.update
    end
  end

  def update
    pbUpdateSpriteHash(@sprites)
  end
end



class PokemonEggHatchScreen
  def initialize(scene)
    @scene=scene
  end

  def pbStartScreen(pokemon)
    @scene.pbStartScene(pokemon)
    @scene.pbMain
    @scene.pbEndScene
  end
end


# For testing scene only
#def pbHatchAnimationz(pokemon)
#  pbMessage(_INTL("Huh?\1"))
#  pbFadeOutInWithMusic {
#    scene=PokemonEggHatchz_Scene.new
#    screen=PokemonEggHatchScreen.new(scene)
#    screen.pbStartScreen(pokemon)
#  }
#  return true
#end

def pbHatch(pokemon)
  speciesname = pokemon.speciesName
  pokemon.name           = speciesname
  pokemon.trainerID      = $Trainer.id
  pokemon.ot             = $Trainer.name
  pokemon.happiness      = 120
  pokemon.timeEggHatched = pbGetTimeNow
  pokemon.obtainMode     = 1   # hatched from egg
  pokemon.hatchedMap     = $game_map.map_id
  $Trainer.seen[pokemon.species]  = true
  $Trainer.owned[pokemon.species] = true
  pbSeenForm(pokemon)
  pokemon.pbRecordFirstMoves
  if !pbHatchAnimation(pokemon)
    pbMessage(_INTL("Huh?\1"))
    pbMessage(_INTL("...\1"))
    pbMessage(_INTL("... .... .....\1"))
    pbMessage(_INTL("{1} hatched from the Egg!",speciesname))
    if pbConfirmMessage(_INTL("Would you like to nickname the newly hatched {1}?",speciesname))
      nickname = pbEnterPokemonName(_INTL("{1}'s nickname?",speciesname),
         0,PokeBattle_Pokemon::MAX_POKEMON_NAME_SIZE,"",pokemon)
      pokemon.name = nickname if nickname!=""
    end
  end
end
