#===============================================================================
# Pokédex Regional Dexes list menu screen
# * For choosing which region list to view. Only appears when there is more
#   than one viable region list to choose from, and if USE_CURRENT_REGION_DEX is
#   false.
#===============================================================================
class Window_DexesList < Window_CommandPokemon
  def initialize(commands,commands2,width)
    @commands2 = commands2
    super(commands,width)
    @selarrow = AnimatedBitmap.new("Graphics/Pictures/selarrow_white")
    self.baseColor   = Color.new(248,248,248)
    self.shadowColor = Color.new(0,0,0)
    self.windowskin  = nil
  end

  def drawItem(index,count,rect)
    super(index,count,rect)
    if index>=0 && index<@commands2.length
      pbDrawShadowText(self.contents,rect.x+136,rect.y,96,rect.height,
         sprintf("%d",@commands2[index][0]),self.baseColor,self.shadowColor,1)
      pbDrawShadowText(self.contents,rect.x+200,rect.y,96,rect.height,
         sprintf("%d",@commands2[index][1]),self.baseColor,self.shadowColor,1)
      allseen = (@commands2[index][0]>=@commands2[index][2])
      allown  = (@commands2[index][1]>=@commands2[index][2])
      #pbDrawImagePositions(self.contents,[
       # ["Graphics/Pictures/Pokedex/icon_menuseenown",rect.x+236,rect.y+4,(allseen) ? 24 : 0,0,24,24],
        #["Graphics/Pictures/Pokedex/icon_menuseenown",rect.x+332,rect.y+4,(allown) ? 24 : 0,24,24,24]
      #])
    end
  end
end



class PokemonPokedexMenu_Scene
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(commands,commands2)
    @commands = commands
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["background"] = IconSprite.new(0,0,@viewport)
    @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/bg_menu"))
    @sprites["headings"]=Window_AdvancedTextPokemon.newWithSize(
       _INTL("<c3=FFFFFF,000000>SEE<r>OWN</c3>"),160,37,152,64,@viewport)
    @sprites["headings"].windowskin  = nil
    @sprites["commands"] = Window_DexesList.new(commands,commands2,Graphics.width-0)
    @sprites["commands"].x      = 0
    @sprites["commands"].y      = 85
    @sprites["commands"].height = 176
    @sprites["commands"].viewport = @viewport
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbScene
    ret = -1
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::B)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::C)
        ret = @sprites["commands"].index
        (ret==@commands.length-1) ? pbPlayCloseMenuSE : pbPlayDecisionSE
        break
      end
    end
    return ret
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end



class PokemonPokedexMenuScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    commands  = []
    commands2 = []
    dexnames = pbDexNames
    for i in 0...$PokemonGlobal.pokedexViable.length
      index = $PokemonGlobal.pokedexViable[i]
      if dexnames[index]==nil
        commands[i] = _INTL("POKéDEX")
      else
        if dexnames[index].is_a?(Array)
          commands[i] = dexnames[index][0]
        else
          commands[i] = dexnames[index]
        end
      end
      index = -1 if index>=$PokemonGlobal.pokedexUnlocked.length-1
      commands2[i] = [$Trainer.pokedexSeen(index),
                      $Trainer.pokedexOwned(index),
                      pbGetRegionalDexLength(index)]
    end
    commands.push(_INTL("EXIT"))
    @scene.pbStartScene(commands,commands2)
    loop do
      cmd = @scene.pbScene
      break if cmd<0 || cmd>=commands2.length   # Cancel/Exit
      $PokemonGlobal.pokedexDex = $PokemonGlobal.pokedexViable[cmd]
      $PokemonGlobal.pokedexDex = -1 if $PokemonGlobal.pokedexDex==$PokemonGlobal.pokedexUnlocked.length-1
      pbFadeOutIn {
        scene = PokemonPokedex_Scene.new
        screen = PokemonPokedexScreen.new(scene)
        screen.pbStartScreen
      }
    end
    @scene.pbEndScene
  end
end
