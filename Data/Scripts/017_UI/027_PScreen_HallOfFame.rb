#===============================================================================
# * Hall of Fame - by FL (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It makes a recordable Hall of Fame
# like the Gen 3 games.
#
#===============================================================================
#
# To this scripts works, put it above main, put a 512x384 picture in
# hallfamebars and a 8x24 background picture in hallfamebg. To call this script,
# use 'pbHallOfFameEntry'. After you recorder the first entry, you can access
# the hall teams using a PC. You can also check the player Hall of Fame last
# number using '$PokemonGlobal.hallOfFameLastNumber'.
#
#===============================================================================
class HallOfFame_Scene
  # When true, all pokémon will be in one line
  # When false, all pokémon will be in two lines
  SINGLEROW = true
  # Make the pokémon movement ON in hall entry
  ANIMATION = true
  # Speed in pokémon movement in hall entry. Don't use less than 2!
  ANIMATIONSPEED = 12
  # Entry wait time (in 1/20 seconds) between showing each Pokémon (and trainer)
  ENTRYWAITTIME = 64
  # Maximum number limit of simultaneous hall entries saved.
  # 0 = Doesn't save any hall. -1 = no limit
  # Prefer to use larger numbers (like 500 and 1000) than don't put a limit
  # If a player exceed this limit, the first one will be removed
  HALLLIMIT = 50
  # The entry music name. Put "" to doesn't play anything
  ENTRYMUSIC = "Hall of Fame"
  # Allow eggs to be show and saved in hall
  ALLOWEGGS = true
  # Remove the hallbars when the trainer sprite appears
  REMOVEBARS = true
  # The final fade speed on entry
  FINALFADESPEED = 16
  # Sprites opacity value when them aren't selected
  OPACITY = 0
  BASECOLOR   = Color.new(0,0,0)
  SHADOWCOLOR = Color.new(0,0,0,0)

  # Placement for pokemon icons
  def pbStartScene
    @sprites={}
    @viewport=Viewport.new(0,0,Graphics.width, Graphics.height)
    @viewport.z=99999
    # Comment the below line to doesn't use a background
    addBackgroundPlane(@sprites,"bg","hallfamebg",@viewport)
    @sprites["hallbars"]=IconSprite.new(@viewport)
    @sprites["hallbars"].setBitmap("Graphics/Pictures/Hall of Fame/hallfamebars")
    @sprites["hallbars"].visible = false
    @sprites["overlay"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["overlay"].z=999#10
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @alreadyFadedInEnd=false
    @useMusic=false
    @battlerIndex=0
    @hallEntry=[]
    @passing = false
  end

  def pbStartSceneEntry
    pbStartScene
    @useMusic=(ENTRYMUSIC && ENTRYMUSIC!="")
    pbBGMPlay(ENTRYMUSIC) if @useMusic
    saveHallEntry
    @xmovement=[]
    @ymovement=[]
    createBattlers
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbStartScenePC
    pbStartScene
    @hallIndex=$PokemonGlobal.hallOfFame.size-1
    @hallEntry=$PokemonGlobal.hallOfFame[-1]
    createBattlers(false)
    pbFadeInAndShow(@sprites) { pbUpdate }
    pbUpdatePC
  end

  def pbEndScene
    $game_map.autoplay if @useMusic
    pbDisposeMessageWindow(@sprites["msgwindow"]) if @sprites.include?("msgwindow")
    pbFadeOutAndHide(@sprites) { pbUpdate } if !@alreadyFadedInEnd
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def slowFadeOut(sprites,exponent)   # 2 exponent
    # To handle values above 8
    extraWaitExponent=exponent-9
    exponent=8 if 8<exponent
    max=2**exponent
    speed=(2**8)/max
    for j in 0..max
      if extraWaitExponent>-1
        (2**extraWaitExponent).times do
          Graphics.update
          Input.update
          pbUpdate
        end
      end
      pbSetSpritesToColor(sprites,Color.new(0,0,0,j*speed))
      block_given? ? yield : pbUpdateSpriteHash(sprites)
    end
  end

  # Dispose the sprite if the sprite exists and make it null
  def restartSpritePosition(sprites,spritename)
    sprites[spritename].dispose if sprites.include?(spritename) && sprites[spritename]
    sprites[spritename]=nil
  end

  # Change the pokémon sprites opacity except the index one
  def setPokemonSpritesOpacity(index,opacity=255)
    for n in 0...@hallEntry.size
      @sprites["pokemon#{n}"].opacity=(n==index) ? 255 : opacity if @sprites["pokemon#{n}"]
    end
  end

  def saveHallEntry
    for i in 0...$Trainer.party.length
      # Clones every pokémon object
      @hallEntry.push($Trainer.party[i].clone) if !$Trainer.party[i].egg? || ALLOWEGGS
    end
    # Update the global variables
    $PokemonGlobal.hallOfFame.push(@hallEntry)
    $PokemonGlobal.hallOfFameLastNumber+=1
    $PokemonGlobal.hallOfFame.delete_at(0) if HALLLIMIT>-1 &&
                                        $PokemonGlobal.hallOfFame.size>HALLLIMIT
  end

  # Return the x/y point position in screen for battler index number
  # Don't use odd numbers!
  def xpointformula(battlernumber)
    ret=0
    if !SINGLEROW
      ret=100+0*xpositionformula(battlernumber)
    else
      ret=(60*(battlernumber/2)+48)*(xpositionformula(battlernumber)-1)
      ret+=Graphics.width/2-95
    end
    return ret
  end

  def ypointformula(battlernumber)
    ret=0
    if !SINGLEROW
      ret=56+0*ypositionformula(battlernumber)/2
    else
      ret=98-8*(battlernumber/2)
    end
    return ret
  end

  # Returns 0, 1 or 2 as the x/y column value
  def xpositionformula(battlernumber)
    ret=0
    if !SINGLEROW
      ret=(battlernumber/3%2==0) ? (19-battlernumber)%3 : (19+battlernumber)%3
    else
      ret=battlernumber%2*2
    end
    return ret
  end

  def ypositionformula(battlernumber)
    ret=0
    if !SINGLEROW
      ret=(battlernumber/3)%2*2
    else
      ret=1
    end
    return ret
  end

  def moveSprite(i)
    spritename=(i>-1) ? "pokemon#{i}" : "trainer"
    speed = ANIMATIONSPEED#(i>-1) ? ANIMATIONSPEED : 2
    speed -= 4 if @passing && speed > 4
    if(!ANIMATION)   # Skips animation
      @sprites[spritename].x-=speed*@xmovement[i]
      @xmovement[i]=0
      @sprites[spritename].y-=speed*@ymovement[i]
      @ymovement[i]=0
    end
    if @xmovement[i]!=0 && !@passing
      direction = (@xmovement[i]>0) ? 1 : -1#-1 : 1
      @sprites[spritename].x+=speed*direction
      if @sprites[spritename].x <= -@sprites[spritename].src_rect.width#bitmap.width
        @passing = true
        @sprites[spritename].y = @midy
        if spritename == "trainer"
          @sprites[spritename].setBitmap(pbTrainerSpriteFile($Trainer.trainertype))
        else
          @sprites[spritename].setPokemonBitmap(@hallEntry[i])
        end
      end
    elsif @xmovement[i]!=0 && @passing
      direction = (@xmovement[i]>0) ? -1 : 1
      @sprites[spritename].x+=speed#*direction
      @xmovement[i]+=direction
    end
    if(@ymovement[i]!=0)
      direction = (@ymovement[i]>0) ? -1 : 1
      @sprites[spritename].y+=speed*direction
      @ymovement[i]+=direction
    end
  end

  def createBattlers(hide=true)
    # Movement in animation
    for i in 0...6
      # Clear all 6 pokémon sprites and dispose the ones that exists every time
      # that this method is call
      restartSpritePosition(@sprites,"pokemon#{i}")
      next if i>=@hallEntry.size
      xpoint=xpointformula(1)
      ypoint=ypointformula(1)
      pok=@hallEntry[i]
      @sprites["pokemon#{i}"]=PokemonSprite.new(@viewport)
      @sprites["pokemon#{i}"].setOffset(PictureOrigin::TopLeft)
      @sprites["pokemon#{i}"].setPokemonBitmap(pok,true)
      # This method doesn't put the exact coordinates
      @sprites["pokemon#{i}"].x = xpoint
      @sprites["pokemon#{i}"].y = ypoint
      if @sprites["pokemon#{i}"].bitmap && !@sprites["pokemon#{i}"].disposed?
        @sprites["pokemon#{i}"].x += (128-@sprites["pokemon#{i}"].bitmap.width)/2 +64
        @sprites["pokemon#{i}"].y += (128-@sprites["pokemon#{i}"].bitmap.height)/2 -32
      end
      @sprites["pokemon#{i}"].z=7-i if SINGLEROW
      next if !hide
      # Animation distance calculation
      horizontal=1-xpositionformula(1)
      vertical=1-ypositionformula(1)
      xdistance=(horizontal==-1) ? -@sprites["pokemon#{i}"].bitmap.width : Graphics.width
      ydistance=(vertical==-1) ? -@sprites["pokemon#{i}"].bitmap.height : Graphics.height
      xdistance=((xdistance-@sprites["pokemon#{i}"].x)/ANIMATIONSPEED).abs+1
      ydistance=((ydistance-@sprites["pokemon#{i}"].y)/ANIMATIONSPEED).abs+1
      biggerdistance=(xdistance>ydistance) ? xdistance : ydistance
      @xmovement[i]=biggerdistance
      @xmovement[i]*=-1 if horizontal==-1
      @xmovement[i]=0   if horizontal== 0
      @ymovement[i]=biggerdistance
      @ymovement[i]*=-1 if vertical==-1
      @ymovement[i]=0   if vertical== 0
      # Hide the battlers
      @sprites["pokemon#{i}"].x+=@xmovement[i]*ANIMATIONSPEED
      @sprites["pokemon#{i}"].y+=@ymovement[i]*ANIMATIONSPEED
      @midy = @sprites["pokemon#{i}"].y
      @sprites["pokemon#{i}"].y = Graphics.height - @sprites["pokemon#{i}"].bitmap.height + 16
      fSpecies = pbGetFSpeciesFromForm($Trainer.party[i].species,$Trainer.party[i].form)
      @sprites["pokemon#{i}"].y += (pbLoadSpeciesMetrics[MetricBattlerPlayerY][fSpecies] || 0)*2
      @sprites["pokemon#{i}"].x = Graphics.width
    end
  end

  def createTrainerBattler
    @sprites["trainer"]=IconSprite.new(@viewport)
    @sprites["trainer"].setBitmap(pbTrainerSpriteFile($Trainer.trainertype))
    if !SINGLEROW
      @sprites["trainer"].x=Graphics.width-56
      @sprites["trainer"].y=132
    else
      @sprites["trainer"].x=Graphics.width/2
      @sprites["trainer"].y=160
    end
    @sprites["trainer"].z=9
    if REMOVEBARS
      @sprites["overlay"].bitmap.clear
      @sprites["hallbars"].visible=false
    end
    @xmovement[@battlerIndex]=0
    @ymovement[@battlerIndex]=0
    if(ANIMATION && !SINGLEROW)   # Trainer Animation
      startpoint=Graphics.width/2
      # 2 is the trainer speed
      @xmovement[@battlerIndex]=(startpoint-@sprites["trainer"].x)/2
      @sprites["trainer"].x=startpoint
    else
      @sprites["trainer"].x=Graphics.width-18 + @sprites["trainer"].bitmap.width/2
      @sprites["trainer"].y-=@sprites["trainer"].bitmap.height - 31
      xdistance=-@sprites["trainer"].bitmap.width
      xdistance=((xdistance-@sprites["trainer"].x)/ANIMATIONSPEED).abs+1
      @xmovement[@battlerIndex]=xdistance*-1
      
      @midy = @sprites["trainer"].y
      @sprites["trainer"].setBitmap(pbPlayerSpriteBackFile($Trainer.trainertype))
      @sprites["trainer"].src_rect.width = @sprites["trainer"].bitmap.width/5
      @sprites["trainer"].y = Graphics.height - @sprites["trainer"].bitmap.height
      @sprites["trainer"].x = Graphics.width
    end
  end

  def writeTrainerData
    totalsec = Graphics.frame_count / Graphics.frame_rate
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    pubid=sprintf("%05d",$Trainer.publicID($Trainer.id))
    if $Trainer.pokedexOwned >= 251
      meName = "Pokedex Evaluation... Complete!"
    elsif $Trainer.pokedexOwned >= 240
      meName = "Pokedex Evaluation... Just a Little More!"
    elsif $Trainer.pokedexOwned >= 180
      meName = "Pokedex Evaluation... Keep at It!"
    elsif $Trainer.pokedexOwned >= 120
      meName = "Pokedex Evaluation... Not Bad!"
    elsif $Trainer.pokedexOwned >= 60
      meName = "Pokedex Evaluation... You're on Your Way!"
    elsif $Trainer.pokedexOwned <= 59
      meName = "Pokedex Evaluation... No Good!"
    end
    lefttext= _INTL("<ac>{1}</ac>",$Trainer.name)
    lefttext+=_INTL("<r>{1}<br>",pubid)
    lefttext+=_INTL("PLAY TIME")
    lefttext+=_ISPRINTF("<ac>{1:02d}:{2:02d}<ac>",hour,min)
    imagePositions= [
      ["Graphics/Pictures/Hall of Fame/IDNo",18,91,0]
    ]
    overlay=@sprites["overlay"].bitmap
    pbDrawImagePositions(overlay,imagePositions)
    @sprites["messagebox"]=Window_AdvancedTextPokemon.new(lefttext)
    @sprites["messagebox"].viewport=@viewport
    @sprites["messagebox"].width=176 #if @sprites["messagebox"].width<192
    @sprites["messagebox"].y=32
    @sprites["msgwindow"]=pbCreateMessageWindow(@viewport)
    pbMessageDisplay(@sprites["msgwindow"],
        _INTL("{1} POKéMON seen\n{2} POKéMON owned",$Trainer.pokedexSeen,$Trainer.pokedexOwned))
    # Professor's Evaluation
    pbMessageDisplay(@sprites["msgwindow"],_INTL("PROF. OAK's\nRating:"))
    if $Trainer.pokedexOwned < 10
      pbMessageDisplay(@sprites["msgwindow"],_INTL("Look for POKéMON in grassy areas!\\wt[8]\\me[{1}]",meName))
    elsif $Trainer.pokedexOwned >= 10 && $Trainer.pokedexOwned <= 19
      pbMessageDisplay(@sprites["msgwindow"],_INTL("Good! I see you understand how to use POKé BALLS.\1\\me[{1}]",meName))
    elsif $Trainer.pokedexOwned >= 20 && $Trainer.pokedexOwned <= 34
      pbMessageDisplay(@sprites["msgwindow"],_INTL("You're getting good at this. But you have a long way to go."))
    elsif $Trainer.pokedexOwned >= 35 && $Trainer.pokedexOwned <= 49
      pbMessageDisplay(@sprites["msgwindow"],_INTL("You need to fill up the POKéDEX. Catch different kinds of POKéMON!"))
    elsif $Trainer.pokedexOwned >= 50 && $Trainer.pokedexOwned <= 64
      pbMessageDisplay(@sprites["msgwindow"],_INTL("You're trying--I can see that. Your POKéDEX is coming together."))
    elsif $Trainer.pokedexOwned >= 65 && $Trainer.pokedexOwned <= 80
      pbMessageDisplay(@sprites["msgwindow"],_INTL("To evolve, some POKéMON grow, others use the effects of STONES."))
    elsif $Trainer.pokedexOwned >= 81 && $Trainer.pokedexOwned <= 94
      pbMessageDisplay(@sprites["msgwindow"],_INTL("Have you gotten a fishing ROD? You can catch POKéMON by fishing."))
    elsif $Trainer.pokedexOwned >= 95 && $Trainer.pokedexOwned <= 109
      pbMessageDisplay(@sprites["msgwindow"],_INTL("Excellent! You seem to like collecting things!"))
    elsif $Trainer.pokedexOwned >= 110 && $Trainer.pokedexOwned <= 124
      pbMessageDisplay(@sprites["msgwindow"],_INTL("Some POKéMON only appear during certain times of the day."))
    elsif $Trainer.pokedexOwned >= 125 && $Trainer.pokedexOwned <= 139
      pbMessageDisplay(@sprites["msgwindow"],_INTL("Your POKéDEX is filling up. Keep up the good work!"))
    elsif $Trainer.pokedexOwned >= 140 && $Trainer.pokedexOwned <= 154
      pbMessageDisplay(@sprites["msgwindow"],_INTL("I'm impressed. You're evolving POKéMON, not just catching them."))
    elsif $Trainer.pokedexOwned >= 155 && $Trainer.pokedexOwned <= 169
      pbMessageDisplay(@sprites["msgwindow"],_INTL("Have you met KURT? His custom POKé BALLS should help."))
    elsif $Trainer.pokedexOwned >= 170 && $Trainer.pokedexOwned <= 184
      pbMessageDisplay(@sprites["msgwindow"],_INTL("Wow. You've found more POKéMON than the last POKéDEX research project."))
    elsif $Trainer.pokedexOwned >= 185 && $Trainer.pokedexOwned <= 199
      pbMessageDisplay(@sprites["msgwindow"],_INTL("Are you trading your POKéMON? It's tough to do this alone!"))
    elsif $Trainer.pokedexOwned >= 200 && $Trainer.pokedexOwned <= 214
      pbMessageDisplay(@sprites["msgwindow"],_INTL("Wow! You've hit 200! Your POKéDEX is looking great!"))
    elsif $Trainer.pokedexOwned >= 215 && $Trainer.pokedexOwned <= 229
      pbMessageDisplay(@sprites["msgwindow"],_INTL("You've found so many POKéMON! You've really helped my studies!"))
    elsif $Trainer.pokedexOwned >= 230 && $Trainer.pokedexOwned <= 244
      pbMessageDisplay(@sprites["msgwindow"],_INTL("Magnificent! You could become a POKéMON professor right now!"))
    elsif $Trainer.pokedexOwned >= 245 && $Trainer.pokedexOwned <= 249
      pbMessageDisplay(@sprites["msgwindow"],_INTL("Your POKéDEX is amazing! You're ready to turn professional!"))
    elsif $Trainer.pokedexOwned >= 250 && $Trainer.pokedexOwned <= 251
      pbMessageDisplay(@sprites["msgwindow"],_INTL("Whoa! A perfect POKéDEX! I've dreamt about this! Congratulations!"))
    end
  end

  def writePokemonData(pokemon,hallNumber=-1)
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    pokename=pokemon.name
    speciesname=PBSpecies.getName(pokemon.species)
    if pokemon.egg?
      speciesname = _INTL("EGG")
      pokename = _INTL("/EGG")
    end
    idno=(pokemon.ot=="" || pokemon.egg?) ? "?????" : sprintf("%05d",pokemon.publicID)
    dexnumber=pokemon.egg? ? _INTL("???") : _ISPRINTF("{1:03d}",pokemon.species)
    # Draw "No, :L , IDNo" icons
    imagePositions= [
      ["Graphics/Pictures/Hall of Fame/overlay_dexnumber",16,212,0],
      ["Graphics/Pictures/Hall of Fame/overlay_lv",18,260,0],
      ["Graphics/Pictures/Hall of Fame/IDNo",114,256,0]
    ]
    pbDrawImagePositions(overlay,imagePositions)
    textPositions=[
       [_INTL("New    Hall    of    Famer!"),16,24,0,BASECOLOR,SHADOWCOLOR],
       [dexnumber,50,200,0,BASECOLOR,SHADOWCOLOR],
       [speciesname,112,200,0,BASECOLOR,SHADOWCOLOR],
       [_INTL("/{1}",pokename),128,216,0,BASECOLOR,SHADOWCOLOR],
       [_INTL("{1}",pokemon.egg? ? "?" : pokemon.level),
           32,248,0,BASECOLOR,SHADOWCOLOR],
       [_INTL("{1}",pokemon.egg? ? "?????" : idno),
           199,248,2,BASECOLOR,SHADOWCOLOR]
    ]
    if pokemon.male?
      textPositions.push([_INTL("♂"),288,202,0,Color.new(0,0,255),SHADOWCOLOR])
    else
      textPositions.push([_INTL("♀"),290,202,0,Color.new(255,0,0),SHADOWCOLOR])
    end
    if (hallNumber>-1)
      textPositions.push([_INTL("Hall of Fame No."),Graphics.width/2-104,0,0,BASECOLOR,SHADOWCOLOR])
      textPositions.push([hallNumber.to_s,Graphics.width/2+104,0,1,BASECOLOR,SHADOWCOLOR])
    end
    pbDrawTextPositions(overlay,textPositions)
  end

  def writeWelcome
    for n in 0...@hallEntry.size
      @sprites["pokemon#{n}"].visible=false if @sprites["pokemon#{n}"]
    end
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    pbDrawTextPositions(overlay,[[_INTL("Welcome to the"),
        Graphics.width/2,Graphics.height-80,2,BASECOLOR,SHADOWCOLOR]])
    pbDrawTextPositions(overlay,[[_INTL("HALL OF FAME!"),
        Graphics.width/2,Graphics.height-48,2,BASECOLOR,SHADOWCOLOR]])
  end

  def pbAnimationLoop
    loop do
      Graphics.update
      Input.update
      pbUpdate
      pbUpdateAnimation
      break if @battlerIndex==@hallEntry.size+2
    end
  end

  def pbPCSelection
    loop do
      Graphics.update
      Input.update
      pbUpdate
      continueScene=true
      break if Input.trigger?(Input::B)   # Exits
      if Input.trigger?(Input::C)   # Moves the selection one entry backward
        @battlerIndex+=10
        continueScene=pbUpdatePC
      end
      if Input.trigger?(Input::LEFT)   # Moves the selection one pokémon forward
        @battlerIndex-=1
        continueScene=pbUpdatePC
      end
      if Input.trigger?(Input::RIGHT)   # Moves the selection one pokémon backward
        @battlerIndex+=1
        continueScene=pbUpdatePC
      end
      break if !continueScene
    end
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbUpdateAnimation
    if @battlerIndex<=@hallEntry.size
      if (@xmovement[@battlerIndex]!=0 || @ymovement[@battlerIndex]!=0)
        spriteIndex=(@battlerIndex<@hallEntry.size) ? @battlerIndex : -1
        moveSprite(spriteIndex)
      else
        @sprites["hallbars"].visible = true
        @passing = false
        @battlerIndex+=1
        if @battlerIndex<=@hallEntry.size
          # If it is a pokémon, write the pokémon text, wait the
          # ENTRYWAITTIME and goes to the next battler
          pbPlayCry(@hallEntry[@battlerIndex-1])
          writePokemonData(@hallEntry[@battlerIndex-1])
          (ENTRYWAITTIME*Graphics.frame_rate/20).times do
            Graphics.update
            Input.update
            pbUpdate
          end
          if @battlerIndex<@hallEntry.size   # Preparates the next battler
            setPokemonSpritesOpacity(@battlerIndex,OPACITY)
            @sprites["overlay"].bitmap.clear
          else   # Show the welcome message and preparates the trainer
            @sprites["hallbars"].visible = false
            setPokemonSpritesOpacity(@battlerIndex,OPACITY)
            @sprites["overlay"].bitmap.clear
            createTrainerBattler
          end
        end
        @sprites["hallbars"].visible = false
      end
    elsif @battlerIndex>@hallEntry.size
      # Write the trainer data and fade
      writeTrainerData
      (ENTRYWAITTIME*Graphics.frame_rate/20).times do
        Graphics.update
        Input.update
        pbUpdate
      end
      fadeSpeed=((Math.log(2**12)-Math.log(FINALFADESPEED))/Math.log(2)).floor
      pbBGMFade((2**fadeSpeed).to_f/20) if @useMusic
      slowFadeOut(@sprites,fadeSpeed) { pbUpdate }
      @alreadyFadedInEnd=true
      @battlerIndex+=1
    end
  end

  def pbUpdatePC
    # Change the team
    if @battlerIndex>=@hallEntry.size
      @hallIndex-=1
      return false if @hallIndex==-1
      @hallEntry=$PokemonGlobal.hallOfFame[@hallIndex]
      @battlerIndex=0
      createBattlers(false)
    elsif @battlerIndex<0
      @hallIndex+=1
      return false if @hallIndex>=$PokemonGlobal.hallOfFame.size
      @hallEntry=$PokemonGlobal.hallOfFame[@hallIndex]
      @battlerIndex=@hallEntry.size-1
      createBattlers(false)
    end
    # Change the pokemon
    pbPlayCry(@hallEntry[@battlerIndex])
    setPokemonSpritesOpacity(@battlerIndex,OPACITY)
    hallNumber=$PokemonGlobal.hallOfFameLastNumber + @hallIndex -
               $PokemonGlobal.hallOfFame.size + 1
    writePokemonData(@hallEntry[@battlerIndex],hallNumber)
    return true
  end
end



class HallOfFameScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreenEntry
    @scene.pbStartSceneEntry
    @scene.pbAnimationLoop
    @scene.pbEndScene
  end

  def pbStartScreenPC
    @scene.pbStartScenePC
    @scene.pbPCSelection
    @scene.pbEndScene
  end
end



class HallOfFamePC
  def shouldShow?
    return $PokemonGlobal.hallOfFameLastNumber>0
  end

  def name
    return _INTL("Hall of Fame")
  end

  def access
    pbMessage(_INTL("\\se[PC access]Accessed the Hall of Fame."))
    pbHallOfFamePC
  end
end



PokemonPCList.registerPC(HallOfFamePC.new)



class PokemonGlobalMetadata
  attr_writer :hallOfFame
  # Number necessary if hallOfFame array reach in its size limit
  attr_writer :hallOfFameLastNumber

  def hallOfFame
    @hallOfFame = [] if !@hallOfFame
    return @hallOfFame
  end

  def hallOfFameLastNumber
    return @hallOfFameLastNumber || 0
  end
end



def pbHallOfFameEntry
  scene=HallOfFame_Scene.new
  screen=HallOfFameScreen.new(scene)
  screen.pbStartScreenEntry
end

def pbHallOfFamePC
  scene=HallOfFame_Scene.new
  screen=HallOfFameScreen.new(scene)
  screen.pbStartScreenPC
end
