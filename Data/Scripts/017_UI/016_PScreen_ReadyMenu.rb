class ReadyMenuButton < SpriteWrapper
  attr_reader :index   # ID of button
  attr_reader :selected
  attr_reader :side
  attr_reader :left
  attr_reader :right

  def initialize(index,command,selected,side,viewport=nil)
    super(viewport)
    @index = index
    @command = command   # Item/move ID, name, mode (T move/F item), pkmnIndex
    @selected = selected
    @side = side
    if @command[2]
      @button = AnimatedBitmap.new("Graphics/Pictures/Ready Menu/icon_movebutton")
    else
      @button = AnimatedBitmap.new("Graphics/Pictures/Ready Menu/icon_itembutton")
    end
    @contents = BitmapWrapper.new(@button.width,@button.height/2)
    self.bitmap = @contents
    pbSetSystemFont(self.bitmap)
    if @command[2]
      @icon = PokemonIconSprite.new($Trainer.party[@command[3]],viewport)
      @icon.setOffset(PictureOrigin::Center)
    else
      @icon = ItemIconSprite.new(0,0,@command[0],viewport)
    end
    @icon.z = self.z+1
    refresh
  end

  def dispose
    @button.dispose
    @contents.dispose
    @icon.dispose
    super
  end

  def visible=(val)
    @icon.visible = val
	refresh if val==true
    super(val)
  end

  def selected=(val)
    oldsel = @selected
    @selected = val
    refresh if oldsel!=val
  end

  def side=(val)
    oldsel = @side
    @side = val
    refresh if oldsel!=val
  end

  def refresh
    sel = (@selected==@index && (@side==0)==@command[2])
    self.y = (Graphics.height-@button.height/2)/2 - (@selected-@index)*(@button.height/2+4) - 32
    if @command[2]   # Pokémon
      self.x = 32 #(sel) ? 0 : -16
      @icon.x = self.x+31
      @icon.y = self.y+39
    else   # Item
      self.x = Graphics.width-@button.width-32#(sel) ? Graphics.width-@button.width : Graphics.width+16-@button.width
      @icon.x = self.x+31
      @icon.y = self.y+2+@button.height/4
    end
    self.bitmap.clear
    rect = Rect.new(0,(sel) ? @button.height/2 : 0,@button.width,@button.height/2)
    if @selected==@index
	  @icon.visible = true
	self.bitmap.blt(0,0,@button.bitmap,rect)
	else
	  @icon.visible = false
	end
	if (sel)
    textx = (@command[2]) ? 156 : (pbIsImportantItem?(@command[0])) ? 138 : 116
    textpos = [
       [@command[1],textx,10,2,Color.new(248,248,248),Color.new(40,40,40),1],
    ]
    if !@command[2]
      if !pbIsImportantItem?(@command[0])
        qty = $PokemonBag.pbQuantity(@command[0])
        if qty>99
          textpos.push([_INTL(">99"),222,10,1,
             Color.new(248,248,248),Color.new(40,40,40),1])
        else
          textpos.push([_INTL("x{1}",qty),222,10,1,
             Color.new(248,248,248),Color.new(40,40,40),1])
		 end
        end
      end
    end
    #pbDrawTextPositions(self.bitmap,textpos)
  end

  def update
    @down.update if @down
    super
  end
end



class PokemonReadyMenu_Scene
  attr_reader :sprites

  def pbStartScene(commands)
    @commands = commands
    @movecommands = []
    @itemcommands = []
    for i in 0...@commands[0].length
      @movecommands.push(@commands[0][i][1])
    end
    for i in 0...@commands[1].length
      @itemcommands.push(@commands[1][i][1])
    end
    @index = $PokemonBag.registeredIndex
    if @index[0]>=@movecommands.length && @movecommands.length>0
      @index[0] = @movecommands.length-1
    end
    if @index[1]>=@itemcommands.length && @itemcommands.length>0
      @index[1] = @itemcommands.length-1
    end
    if @index[2]==0 && @movecommands.length==0; @index[2] = 1
    elsif @index[2]==1 && @itemcommands.length==0; @index[2] = 0
    end
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @sprites = {}
	@sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["overlay"].z = 4
    @sprites["textbg"] = IconSprite.new(0,208,@viewport)
    @sprites["textbg"].setBitmap("Graphics/Pictures/Ready Menu/icon_namebg")
    @sprites["textbg"].visible = true
    @sprites["textbg"].viewport = @viewport
    @sprites["textbg"].z = 3
    @sprites["left"] = AnimatedSprite.new("Graphics/Pictures/leftarrow",8,40,28,2,@viewport)
    @sprites["left"].z = 1
    @sprites["left"].play
    @sprites["right"] = AnimatedSprite.new("Graphics/Pictures/rightarrow",8,40,28,2,@viewport)	
    @sprites["right"].z = 1
    @sprites["right"].play	
    @sprites["up"] = AnimatedSprite.new("Graphics/Pictures/uparrow",8,28,40,2,@viewport)
    @sprites["up"].z = 1
    @sprites["up"].play
    @sprites["down"] = AnimatedSprite.new("Graphics/Pictures/downarrow",8,28,40,2,@viewport)
    @sprites["down"].z = 1
    @sprites["down"].play
    @sprites["cmdwindow"] = Window_CommandPokemon.new((@index[2]==0) ? @movecommands : @itemcommands)
    @sprites["cmdwindow"].height = 6*32
    @sprites["cmdwindow"].visible = false
    @sprites["cmdwindow"].viewport = @viewport
	pbSetSystemFont(@sprites["overlay"].bitmap)
    for i in 0...@commands[0].length
      @sprites["movebutton#{i}"] = ReadyMenuButton.new(i,@commands[0][i],@index[0],@index[2],@viewport)
    end
    for i in 0...@commands[1].length
      @sprites["itembutton#{i}"] = ReadyMenuButton.new(i,@commands[1][i],@index[1],@index[2],@viewport)
    end
    pbSEPlay("GUI menu open")
  end

  def pbShowMenu
    @sprites["cmdwindow"].visible = false
    for i in 0...@commands[0].length
      @sprites["movebutton#{i}"].visible = true
    end
    for i in 0...@commands[1].length
      @sprites["itembutton#{i}"].visible = true
    end
  end

  def pbHideMenu
    @sprites["cmdwindow"].visible = false
    for i in 0...@commands[0].length
      @sprites["movebutton#{i}"].visible = false
    end
    for i in 0...@commands[1].length
      @sprites["itembutton#{i}"].visible = false
    end
  end

  def pbShowCommands
    ret = -1
    cmdwindow = @sprites["cmdwindow"]
    cmdwindow.commands = (@index[2]==0) ? @movecommands : @itemcommands
    cmdwindow.index    = @index[@index[2]]
    cmdwindow.visible  = false
    loop do
      pbUpdate
      if Input.trigger?(Input::LEFT) && @index[2]==1 && @movecommands.length>0
        @index[2] = 0
        pbChangeSide
      elsif Input.trigger?(Input::RIGHT) && @index[2]==0 && @itemcommands.length>0
        @index[2] = 1
        pbChangeSide
      elsif Input.trigger?(Input::B)
        pbPlayCloseMenuSE
        ret = -1
        break
      elsif Input.trigger?(Input::C)
        ret = [@index[2],cmdwindow.index]
        break
      end
    end
    return ret
  end

  def pbEndScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbChangeSide
    for i in 0...@commands[0].length
      @sprites["movebutton#{i}"].side = @index[2]
    end
    for i in 0...@commands[1].length
      @sprites["itembutton#{i}"].side = @index[2]
    end
    @sprites["cmdwindow"].commands = (@index[2]==0) ? @movecommands : @itemcommands
    @sprites["cmdwindow"].index = @index[@index[2]]
  end


  def pbUpdate
    oldindex = @index[@index[2]]
    @index[@index[2]] = @sprites["cmdwindow"].index
    if @index[@index[2]]!=oldindex
      if @index[2]==0
        for i in 0...@commands[0].length
          @sprites["movebutton#{i}"].selected = @index[@index[2]]
        end
      elsif @index[2]==1
        for i in 0...@commands[1].length
          @sprites["itembutton#{i}"].selected = @index[@index[2]]
        end
      end
    end
	if @index[2]==0	
      @sprites["left"].x = 14;  @sprites["left"].y = 98
      @sprites["right"].x = 74; @sprites["right"].y = 98
      @sprites["up"].x = 50;    @sprites["up"].y = 62
      @sprites["down"].x = 50;  @sprites["down"].y = 122	
      @sprites["left"].visible = false
      if @index[@index[2]] == 0
        @sprites["up"].visible = false	
      else	
        @sprites["up"].visible = true
      end
      if @index[@index[2]] == @commands[0].length-1
        @sprites["down"].visible = false
      else
        @sprites["down"].visible = true
      end
      if @commands[1].length == 0
        @sprites["right"].visible = false
      else
        @sprites["right"].visible = true
      end
    elsif @index[2]==1	
      @sprites["left"].x = 206;  @sprites["left"].y = 98
      @sprites["right"].x = 266; @sprites["right"].y = 98
      @sprites["up"].x = 242;    @sprites["up"].y = 62
      @sprites["down"].x = 242;  @sprites["down"].y = 122
      @sprites["right"].visible = false
      if @index[@index[2]] == 0
        @sprites["up"].visible = false
      else
        @sprites["up"].visible = true
      end	
      if @index[@index[2]] == @commands[1].length-1
        @sprites["down"].visible = false
      else
        @sprites["down"].visible = true	
      end
      if @commands[0].length == 0	
        @sprites["left"].visible = false	
      else	
        @sprites["left"].visible = true
      end	
    end
    pbUpdateSpriteHash(@sprites)
	@sprites["overlay"].bitmap.clear
    pbDrawTextPositions(@sprites["overlay"].bitmap,[
         [@commands[@index[2]][@index[@index[2]]][1],160,235,2,Color.new(0,0,0),Color.new(255,255,255,0)]	
      ])
    Graphics.update
    Input.update
    pbUpdateSceneMap
  end
  
  def pbRefresh; end
end



class PokemonReadyMenu
  def initialize(scene)
    @scene = scene
  end

  def pbHideMenu
    @scene.pbHideMenu
  end

  def pbShowMenu
    @scene.pbRefresh
    @scene.pbShowMenu
  end

  def pbStartReadyMenu(moves,items)
    commands = [[],[]]   # Moves, items
    for i in moves
      commands[0].push([i[0],PBMoves.getName(i[0]),true,i[1]])
    end
    commands[0].sort! { |a,b| a[1]<=>b[1] }
    for i in items
      commands[1].push([i,PBItems.getName(i),false])
    end
    commands[1].sort! { |a,b| a[1]<=>b[1] }
    @scene.pbStartScene(commands)
    loop do
      command = @scene.pbShowCommands
      break if command==-1
      if command[0]==0   # Use a move
        move = commands[0][command[1]][0]
        user = $Trainer.party[commands[0][command[1]][3]]
        if isConst?(move,PBMoves,:FLY)
          ret = nil
          pbFadeOutInWithUpdate(99999,@scene.sprites) {
            pbHideMenu
            scene = PokemonRegionMap_Scene.new(-1,false)
            screen = PokemonRegionMapScreen.new(scene)
            ret = screen.pbStartFlyScreen
            pbShowMenu if !ret
          }
          if ret
            $PokemonTemp.flydata = ret
            $game_temp.in_menu = false
            pbUseHiddenMove(user,move)
            break
          end
        else
          pbHideMenu
          if pbConfirmUseHiddenMove(user,move)
            $game_temp.in_menu = false
            pbUseHiddenMove(user,move)
            break
          else
            pbShowMenu
          end
        end
      else   # Use an item
        item = commands[1][command[1]][0]
        pbHideMenu
        if ItemHandlers.triggerConfirmUseInField(item)
          $game_temp.in_menu = false
          break if pbUseKeyItemInField(item)
          $game_temp.in_menu = true
        end
      end
      pbShowMenu
    end
    @scene.pbEndScene
  end
end



#===============================================================================
# Using a registered item
#===============================================================================
def pbUseKeyItem
  moves = [:CUT,:DEFOG,:DIG,:DIVE,:FLASH,:FLY,:HEADBUTT,:ROCKCLIMB,:ROCKSMASH,
           :SECRETPOWER,:STRENGTH,:SURF,:SWEETSCENT,:TELEPORT,:WATERFALL,
           :WHIRLPOOL]
  realmoves = []
  for i in moves
    move = getID(PBMoves,i)
    next if move==0
    for j in 0...$Trainer.party.length
      next if $Trainer.party[j].egg?
      if $Trainer.party[j].hasMove?(move)
        realmoves.push([move,j]) if pbCanUseHiddenMove?($Trainer.party[j],move,false)
        break
	  end
    end
  end
  realitems = []
  for i in $PokemonBag.registeredItems
    realitems.push(i) if $PokemonBag.pbHasItem?(i)
  end
  if realitems.length==0 && realmoves.length==0
    pbMessage(_INTL("An item in your PACK may be registered for use on F5 Button."))
  else
    $game_temp.in_menu = true
    $game_map.update
    sscene = PokemonReadyMenu_Scene.new
    sscreen = PokemonReadyMenu.new(sscene)
    sscreen.pbStartReadyMenu(realmoves,realitems)
    $game_temp.in_menu = false
  end
end
