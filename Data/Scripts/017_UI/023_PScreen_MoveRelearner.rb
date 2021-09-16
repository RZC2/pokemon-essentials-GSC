def pbEachNaturalMove(pokemon)
  movelist=pokemon.getMoveList
  for i in movelist
    yield i[1],i[0]
  end
end

def pbHasRelearnableMove?(pokemon)
  return pbGetRelearnableMoves(pokemon).length>0
end

def pbGetRelearnableMoves(pokemon)
  return [] if !pokemon || pokemon.egg? || pokemon.shadowPokemon?
  moves=[]
  pbEachNaturalMove(pokemon) { |move,level|
    if level<=pokemon.level && !pokemon.hasMove?(move)
      moves.push(move) if !moves.include?(move)
    end
  }
  tmoves=[]
  if pokemon.firstmoves
    for i in pokemon.firstmoves
      tmoves.push(i) if !pokemon.hasMove?(i) && !moves.include?(i)
    end
  end
  trmoves=[]
  for i in pokemon.trmoves
    trmoves.push(i) if !pokemon.hasMove?(i) && !moves.include?(i)
  end
  moves=tmoves+trmoves+moves
  return moves|[]
end

################################################################################
# Scene class for handling appearance of the screen
################################################################################
class MoveRelearner_Scene
  VISIBLEMOVES = 4

  def pbDisplay(msg,brief=false)
    UIHelper.pbDisplay(@sprites["msgwindow"],msg,brief) { pbUpdate }
  end

  def pbConfirm(msg)
    UIHelper.pbConfirm(@sprites["msgwindow"],msg) { pbUpdate }
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(pokemon,moves)
    @pokemon=pokemon
    @moves=moves
    moveCommands=[]
    moves.each { |m| moveCommands.push(PBMoves.getName(m)) }
    # Create sprite hash
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @sprites={}
    addBackgroundPlane(@sprites,"bg","reminderbg",@viewport)
    @sprites["pokeicon"]=PokemonIconSprite.new(@pokemon,@viewport)
    @sprites["pokeicon"].setOffset(PictureOrigin::Center)
    @sprites["pokeicon"].x=32
    @sprites["pokeicon"].y=160
    @sprites["background"]=IconSprite.new(0,0,@viewport)
    @sprites["background"].setBitmap("Graphics/Pictures/reminderSel")
    @sprites["background"].y=172
    @sprites["background"].src_rect=Rect.new(0,16,320,16)
    @sprites["overlay"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["commands"]=Window_CommandPokemon.new(moveCommands,32)
    @sprites["commands"].height=32*(VISIBLEMOVES+1)
    @sprites["commands"].visible=false
    @sprites["msgwindow"]=Window_AdvancedTextPokemon.new("")
    @sprites["msgwindow"].visible=false
    @sprites["msgwindow"].viewport=@viewport
    @typebitmap=AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
    pbDrawMoveList
    pbDeactivateWindows(@sprites)
    # Fade in all sprites
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbDrawMoveList
    movesData = pbLoadMovesData
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    type1rect=Rect.new(0,@pokemon.type1*28,64,28)
    type2rect=Rect.new(0,@pokemon.type2*28,64,28)
    if @pokemon.type1==@pokemon.type2
      overlay.blt(400,70,@typebitmap.bitmap,type1rect)
    else
      overlay.blt(366,70,@typebitmap.bitmap,type1rect)
      overlay.blt(436,70,@typebitmap.bitmap,type2rect)
    end
    textpos=[
       [_INTL("Teach which move?"),320,144,1,Color.new(0,0,0),Color.new(255,255,255,0)]
    ]
    imagepos=[]
    yPos=165
    for i in 0...VISIBLEMOVES
      moveobject=@moves[@sprites["commands"].top_item+i]
      if moveobject
        moveData=movesData[moveobject]
        if moveData
          textpos.push([PBMoves.getName(moveobject),4,yPos,0,
             Color.new(0,0,0),Color.new(255,255,255,0)])
          if moveData[MOVE_TOTAL_PP]>0
            textpos.push([_INTL("{1}/{2}",
               moveData[MOVE_TOTAL_PP],moveData[MOVE_TOTAL_PP]),320,yPos,1,#+16
               Color.new(0,0,0),Color.new(255,255,255,0)])
          end
        else
          textpos.push(["-",80,yPos,0,Color.new(0,0,0),Color.new(255,255,255,0)])
          textpos.push(["--",228,yPos+32,1,Color.new(0,0,0),Color.new(255,255,255,0)])
        end
      end
      yPos+=16
    end
    imagepos.push(["Graphics/Pictures/reminderSel",
       0,172+(@sprites["commands"].index-@sprites["commands"].top_item)*16,
       0,0,320,16])
    selMoveData=movesData[@moves[@sprites["commands"].index]]
    basedamage=selMoveData[MOVE_BASE_DAMAGE]
    category=selMoveData[MOVE_CATEGORY]
    accuracy=selMoveData[MOVE_ACCURACY]
    textpos.push([_INTL("CATEG"),8,240,0,Color.new(0,0,0),Color.new(255,255,255,0)])
    textpos.push([_INTL("POWER"),120,240,0,Color.new(0,0,0),Color.new(255,255,255,0)])
    textpos.push([basedamage<=1 ? basedamage==1 ? "???" : "---" : sprintf("%d",basedamage),
          200,260,1,Color.new(0,0,0),Color.new(255,255,255,0)])
    textpos.push([_INTL("ACCUR"),230,240,0,Color.new(0,0,0),Color.new(255,255,255,0)])
    textpos.push([accuracy==0 ? "---" : sprintf("%d",accuracy),
          308,260,1,Color.new(0,0,0),Color.new(255,255,255,0)])
    pbDrawTextPositions(overlay,textpos)
    imagepos.push(["Graphics/Pictures/category",8,268,0,category*14,122,14])
    if @sprites["commands"].index<@moves.length-1
      imagepos.push(["Graphics/Pictures/reminderButtons",48,350,0,0,76,32])
    end
    if @sprites["commands"].index>0
      imagepos.push(["Graphics/Pictures/reminderButtons",134,350,76,0,76,32])
    end
	pbDrawImagePositions(overlay,imagepos)
    drawTextEx(overlay,0,0,320,5,
       pbGetMessage(MessageTypes::MoveDescriptions,@moves[@sprites["commands"].index]),
       Color.new(0,0,0),Color.new(255,255,255,0))
  end

  # Processes the scene
  def pbChooseMove
    oldcmd=-1
    pbActivateWindow(@sprites,"commands") {
      loop do
        oldcmd=@sprites["commands"].index
        Graphics.update
        Input.update
        pbUpdate
        if @sprites["commands"].index!=oldcmd
          @sprites["background"].x=0
          @sprites["background"].y=172+(@sprites["commands"].index-@sprites["commands"].top_item)*16
          pbDrawMoveList
        end
        if Input.trigger?(Input::B)
          return 0
        elsif Input.trigger?(Input::C)
          return @moves[@sprites["commands"].index]
        end
      end
    }
  end

  # End the scene here
  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @typebitmap.dispose
    @viewport.dispose
  end
end



# Screen class for handling game logic
class MoveRelearnerScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen(pokemon)
    moves=pbGetRelearnableMoves(pokemon)
    @scene.pbStartScene(pokemon,moves)
    loop do
      move=@scene.pbChooseMove
      if move<=0
        if @scene.pbConfirmMessage(_INTL("Give up trying to teach a new move to {1}?",pokemon.name))
          @scene.pbEndScene
          return false
        end
      else
        if @scene.pbConfirm(_INTL("Teach {1}?",PBMoves.getName(move)))
          if pbLearnMove(pokemon,move)
            @scene.pbEndScene
            return true
          end
        end
      end
    end
  end
end



def pbRelearnMoveScreen(pokemon)
  retval = true
  pbFadeOutIn {
    scene = MoveRelearner_Scene.new
    screen = MoveRelearnerScreen.new(scene)
    retval = screen.pbStartScreen(pokemon)
  }
  return retval
end
