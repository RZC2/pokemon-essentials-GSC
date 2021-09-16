class MoveSelectionSprite < SpriteWrapper
  attr_reader :preselected
  attr_reader :index

  def initialize(viewport=nil,fifthmove=false)
    super(viewport)
    @movesel = AnimatedBitmap.new("Graphics/Pictures/Summary/cursor_move")
    @frame = 0
    @index = 0
    @fifthmove = fifthmove
    @preselected = false
    @updating = false
    refresh
  end

  def dispose
    @movesel.dispose
    super
  end

  def index=(value)
    @index = value
    refresh
  end

  def preselected=(value)
    @preselected = value
    refresh
  end
# Square Area
  def refresh
    w = @movesel.width
    h = @movesel.height/2
    self.x = 0
    self.y = 167+(self.index*16)
    self.y -= 15 if @fifthmove
    self.y += 15 if @fifthmove && self.index==5
    self.bitmap = @movesel.bitmap
    if self.preselected
      self.src_rect.set(0,h,w,h)
    else
      self.src_rect.set(0,0,w,h)
    end
  end

  def update
    @updating = true
    super
    @movesel.update
    @updating = false
    refresh
  end
end


class PokemonSummary_Scene
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(party,partyindex,inbattle=false)
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
	@viewport2=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport2.z=999999
    @party      = party
    @partyindex = partyindex
    @pokemon    = @party[@partyindex]
    @inbattle   = inbattle
    @page = 1
    @typebitmap    = AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
    @sprites = {}
    @sprites["background"] = IconSprite.new(0,0,@viewport)
    @sprites["pokemon"] = PokemonSprite.new(@viewport)
    @sprites["pokemon"].setOffset(PictureOrigin::Center)
    @sprites["pokemon"].x = 60
    @sprites["pokemon"].y = 65
    @sprites["pokemon"].setPokemonBitmap(@pokemon)
    @sprites["pokemon"].mirror = true
    @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon,@viewport)
    @sprites["pokeicon"].setOffset(PictureOrigin::Center)
    @sprites["pokeicon"].x       = 46
    @sprites["pokeicon"].y       = 92
    @sprites["pokeicon"].visible = false
    @sprites["itemicon"] = ItemIconSprite.new(30,320,@pokemon.item,@viewport)
    @sprites["itemicon"].blankzero = true
	@sprites["overlay2"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport2)
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["movepresel"] = MoveSelectionSprite.new(@viewport)
    @sprites["movepresel"].visible     = false
    @sprites["movepresel"].preselected = true
    @sprites["movesel"] = MoveSelectionSprite.new(@viewport)
    @sprites["movesel"].visible = false
    @sprites["uparrow"] = AnimatedSprite.new("Graphics/Pictures/uparrow",8,28,40,2,@viewport)
    @sprites["uparrow"].x = 350
    @sprites["uparrow"].y = 56
    @sprites["uparrow"].play
    @sprites["uparrow"].visible = false
    @sprites["downarrow"] = AnimatedSprite.new("Graphics/Pictures/downarrow",8,28,40,2,@viewport)
    @sprites["downarrow"].x = 350
    @sprites["downarrow"].y = 260
    @sprites["downarrow"].play
    @sprites["downarrow"].visible = false
    @sprites["messagebox"] = Window_AdvancedTextPokemon.new("")
    @sprites["messagebox"].viewport       = @viewport
    @sprites["messagebox"].visible        = false
    @sprites["messagebox"].letterbyletter = true
    pbBottomLeftLines(@sprites["messagebox"],2)
    drawPage(@page)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbStartForgetScene(party,partyindex,moveToLearn)
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @party      = party
    @partyindex = partyindex
    @pokemon    = @party[@partyindex]
    @page = 4
    @typebitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
    @sprites = {}
    @sprites["background"] = IconSprite.new(0,0,@viewport)
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon,@viewport)
    @sprites["pokeicon"].setOffset(PictureOrigin::Center)
    @sprites["pokeicon"].x       = 46
    @sprites["pokeicon"].y       = 92
    @sprites["movesel"] = MoveSelectionSprite.new(@viewport,moveToLearn>0)
    @sprites["movesel"].visible = false
    @sprites["movesel"].visible = true
    @sprites["movesel"].index   = 0
    drawSelectedMove(moveToLearn,@pokemon.moves[0].id)
    pbFadeInAndShow(@sprites)
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @typebitmap.dispose
    @viewport.dispose
  end

  def pbDisplay(text)
    @sprites["messagebox"].text = text
    @sprites["messagebox"].visible = true
    pbPlayDecisionSE()
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["messagebox"].busy?
        if Input.trigger?(Input::C)
          pbPlayDecisionSE() if @sprites["messagebox"].pausing?
          @sprites["messagebox"].resume
        end
      elsif Input.trigger?(Input::C) || Input.trigger?(Input::B)
        break
      end
    end
    @sprites["messagebox"].visible = false
  end

  def pbConfirm(text)
    ret = -1
    @sprites["messagebox"].text    = text
    @sprites["messagebox"].visible = true
    using(cmdwindow = Window_CommandPokemon.new([_INTL("YES"),_INTL("NO")])) {
      cmdwindow.z       = @viewport.z+1
      cmdwindow.visible = false
      pbBottomRight(cmdwindow)
      cmdwindow.y -= @sprites["messagebox"].height
      loop do
        Graphics.update
        Input.update
        cmdwindow.visible = true if !@sprites["messagebox"].busy?
        cmdwindow.update
        pbUpdate
        if !@sprites["messagebox"].busy?
          if Input.trigger?(Input::B)
            ret = false
            break
          elsif Input.trigger?(Input::C) && @sprites["messagebox"].resume
            ret = (cmdwindow.index==0)
            break
          end
        end
      end
    }
    @sprites["messagebox"].visible = false
    return ret
  end

  def pbShowCommands(commands,index=0)
    ret = -1
    using(cmdwindow = Window_CommandPokemon.new(commands)) {
       cmdwindow.z = @viewport.z+1
       cmdwindow.index = index
       pbBottomRight(cmdwindow)
       loop do
         Graphics.update
         Input.update
         cmdwindow.update
         pbUpdate
         if Input.trigger?(Input::B)
           pbPlayCancelSE
           ret = -1
           break
         elsif Input.trigger?(Input::C)
           pbPlayDecisionSE
           ret = cmdwindow.index
           break
         end
       end
    }
    return ret
  end

#===============================================================================
# Information for all pages
#===============================================================================
  def drawPage(page)
    if @pokemon.egg?
      drawPageOneEgg; return
    end
    @sprites["itemicon"].item = @pokemon.item
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(0,0,0)
    shadow = Color.new(255,255,255,0)
    dexNumBase   = (@pokemon.shiny?) ? Color.new(255,215,0) : Color.new(0,0,0)
    dexNumShadow = (@pokemon.shiny?) ? Color.new(255,255,255,0) : Color.new(255,255,255,0)
    # Set background image
    @sprites["background"].setBitmap("Graphics/Pictures/Summary/bg_#{page}")
    imagepos=[
    ["Graphics/Pictures/Summary/overlay_dexnumber",128,4]
    ]
	# Show ":L" graphic
	if @pokemon.level < 100
	  imagepos.push([sprintf("Graphics/Pictures/Summary/overlay_lv"),226,4])
	end
    # Show Pokérus cured icon
    if @pokemon.pokerusStage==2
      imagepos.push([sprintf("Graphics/Pictures/Summary/icon_pokerus"),160,104])
    end
    # Show shininess star
    if @pokemon.shiny?
      imagepos.push([sprintf("Graphics/Pictures/shiny"),304,0])
    end
    # Draw all images
    pbDrawImagePositions(overlay,imagepos)
    # Write various bits of text
    textpos = [
       [@pokemon.name,128,24,0,base,shadow],
       [_INTL("/{1}",PBSpecies.getName(@pokemon.species)),144,56,0,base,shadow]
    ]
	# Write the Pokémon's level
	if @pokemon.level < 100
	  textpos.push([@pokemon.level.to_s,240,-8,0,base,shadow])
	else
	  textpos.push([@pokemon.level.to_s,226,-8,0,base,shadow])
	end
    # Write the Regional/National Dex number
    dexnum = @pokemon.species
    dexnumshift = false
    if $PokemonGlobal.pokedexUnlocked[$PokemonGlobal.pokedexUnlocked.length-1]
      dexnumshift = true if DEXES_WITH_OFFSETS.include?(-1)
    else
      dexnum = 0
      for i in 0...$PokemonGlobal.pokedexUnlocked.length-1
        next if !$PokemonGlobal.pokedexUnlocked[i]
        num = pbGetRegionalNumber(i,@pokemon.species)
        next if num<=0
        dexnum = num
        dexnumshift = true if DEXES_WITH_OFFSETS.include?(i)
        break
      end
    end
    if dexnum<=0
      textpos.push(["???",160,-8,0,dexNumBase,dexNumShadow])
    else
      dexnum -= 1 if dexnumshift
      textpos.push([sprintf("%03d",dexnum),160,-8,0,dexNumBase,dexNumShadow])
    end
    # Write the gender symbol
    if @pokemon.male?
      textpos.push([_INTL("♂"),288,-6,0,Color.new(0,0,255),Color.new(255,255,255,0)])
    elsif @pokemon.female?
      textpos.push([_INTL("♀"),288,-6,0,Color.new(255,0,0),Color.new(255,255,255,0)])
    end
    # Draw all text
    pbDrawTextPositions(overlay,textpos)
    # Draw page-specific information
    case page
    when 1; drawPageOne
    when 2; drawPageTwo
    when 3; drawPageThree
	when 4; drawPageFour
	when 5; drawPageFive
    end
  end

#===============================================================================
# Page One: Pokémon general information
#===============================================================================
  def drawPageOne
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(0,0,0)
    shadow = Color.new(255,255,255,0)
	# Variable which stores the Pokémon next level value + conditions when level is lower or equal to 100
	if @pokemon.level < 100
	  nextlevel = @pokemon.level+1
	else
	  nextlevel = 100
	end
    # If a Shadow Pokémon, draw the heart gauge area and bar
    if @pokemon.shadowPokemon?
      shadowfract = @pokemon.heartgauge*1.0/PokeBattle_Pokemon::HEARTGAUGESIZE
      imagepos = [
         ["Graphics/Pictures/Summary/overlay_shadow",154,254],
         ["Graphics/Pictures/Summary/overlay_shadowbar",154,254,0,0,(shadowfract*248).floor,-1]
      ]
      pbDrawImagePositions(overlay,imagepos)
    end
    imagepos=[]
    # Show status/fainted/Pokérus infected icon
    status = -1
    status = 6 if @pokemon.pokerusStage==1
    status = @pokemon.status-1 if @pokemon.status>0
    status = 5 if @pokemon.hp==0
    if status>=0 && status != 6
      imagepos.push(["Graphics/Pictures/statuses",96,208,0,14*status,110,14])
	elsif status == 6
	imagepos.push(["Graphics/Pictures/statuses",16,208,0,14*status,110,14])
    elsif status == -1
      imagepos.push(["Graphics/Pictures/status_OK",96,208,0])
    end
    # Write various bits of text
    textpos = [
       [sprintf("%d/ %d",@pokemon.hp,@pokemon.totalhp),124,152,1,base,shadow],
       [_INTL("STATUS/"),0,184,0,base,shadow],
       [_INTL("TYPE/"),0,216,0,base,shadow]
    ]
	pbDrawTextPositions(overlay,textpos)
    # Write Exp text OR heart gauge message (if a Shadow Pokémon)
    if @pokemon.shadowPokemon?
      textpos.push([_INTL("HEART GAUGE"),152,120,0,base,shadow])
      heartmessage = [_INTL("Heart open! Undo the final lock!"),
                      _INTL("Its heart is almost fully open."),
                      _INTL("Its heart is nearly open."),
                      _INTL("Its heart is opening wider."),
                      _INTL("The door to its heart is opening up."),
                      _INTL("The door to its heart is tightly shut.")][@pokemon.heartStage]
      memo = sprintf("<c3=000000>%s\n",heartmessage)
      drawFormattedTextEx(overlay,160,136,160,memo)
    else
	  # Show ":L" from "TO NEXT LVL." information only when the Pokémon isn't level 100
	  if nextlevel < 100
	    imagepos.push(["Graphics/Pictures/Summary/overlay_lv",274,228,0])
	  end
	  textpos = [
	     [_INTL("EXP POINTS"),160,136,0,base,shadow],
         [_INTL("LEVEL UP"),160,184,0,base,shadow] 
	  ]
      endexp = PBExperience.pbGetStartExperience(@pokemon.level+1,@pokemon.growthrate)
      # EXP POINTS earned
      textpos.push([@pokemon.exp.to_s_formatted,320,152,1,base,shadow])
	  # TO NEXT LV. information
	  textpos.push([(endexp-@pokemon.exp).to_s_formatted,320,200,1,base,shadow])
      textpos.push([_INTL("TO"),224,216,0,base,shadow])
	  # Position of level text when level is between 1-9
	  if nextlevel < 10
	    textpos.push([nextlevel.to_s_formatted,304,216,1,base,shadow])
	  elsif nextlevel >= 10 # Position of level text when level is greater or equal to 10
	    textpos.push([nextlevel.to_s_formatted,318,216,1,base,shadow])
	  elsif nextlevel > 100 # Text which appears when next level is greater than 100
	    textpos.push([nextlevel.to_s_formatted,320,216,1,base,shadow])
	  end
    end
    # Draw all text and images
    pbDrawTextPositions(overlay,textpos)
	pbDrawImagePositions(overlay,imagepos)
    # Draw Pokémon type(s)
    type1rect = Rect.new(0,@pokemon.type1*14,126,14)
    type2rect = Rect.new(0,@pokemon.type2*14,126,14)
    if @pokemon.type1==@pokemon.type2
      overlay.blt(16,240,@typebitmap.bitmap,type1rect)
    else
      overlay.blt(16,240,@typebitmap.bitmap,type1rect)
      overlay.blt(16,256,@typebitmap.bitmap,type2rect)
    end
    # Draw HP bar
    if @pokemon.hp>0
      w = @pokemon.hp*96*1.0/@pokemon.totalhp
      w = 1 if w<1
      w = ((w/2).round)*2
      hpzone = 0
      hpzone = 1 if @pokemon.hp<=(@pokemon.totalhp/2).floor
      hpzone = 2 if @pokemon.hp<=(@pokemon.totalhp/4).floor
      imagepos = [
         ["Graphics/Pictures/Summary/overlay_hp",32,150,0,hpzone*4,w,4]
      ]
      pbDrawImagePositions(overlay,imagepos)
    end
    # Draw Exp bar
    if @pokemon.level<PBExperience.maxLevel
      w = @pokemon.expFraction*128
      w = ((w/2).round)*2
      pbDrawImagePositions(overlay,[
         ["Graphics/Pictures/Summary/overlay_exp",176,262,0,0,w,4]
      ])
    end
  end

#===============================================================================
# Egg Page
#===============================================================================
  def drawPageOneEgg
    @sprites["itemicon"].item = @pokemon.item
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(0,0,0)
    shadow = Color.new(255,255,255,0)
    # Set background image
    @sprites["background"].setBitmap("Graphics/Pictures/Summary/bg_egg")
	# Draw ID No. picture
    imagepos = [
       ["Graphics/Pictures/Summary/IDNo",130,52,0]
	]
    # Draw all images
    pbDrawImagePositions(overlay,imagepos)
    # Write various bits of text
    textpos = [
       [_INTL("EGG"),128,8,0,base,shadow],
	   [_INTL("?????"),176,38,0,base,shadow],
       [_INTL("OT/"),128,72,0,base,shadow],
	   [_INTL("?????"),176,70,0,base,shadow]
    ]
    # Draw all text
    pbDrawTextPositions(overlay,textpos)
    # Write Egg Status
    eggstate = _INTL("<c3=000000,F8F8F8>This EGG needs a lot more time to hatch.")
    eggstate = _INTL("<c3=000000,F8F8F8>Wonder what's inside? It needs more time, though.") if @pokemon.eggsteps<10200
    eggstate = _INTL("<c3=000000,F8F8F8>It moves around inside sometimes. It must be close to hatching.") if @pokemon.eggsteps<2550
    eggstate = _INTL("<c3=000000,F8F8F8>It's making sounds inside. It's going to hatch soon!") if @pokemon.eggsteps<1275
    # Draw eggstate
    drawFormattedTextEx(overlay,16,144,288,eggstate)
  end

#===============================================================================
# Page Two: Item and Moves
#===============================================================================
  def drawPageTwo
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(0,0,0)
    shadow = Color.new(255,255,255,0)
    moveBase   = Color.new(0,0,0)
    moveShadow = Color.new(255,255,255,0)
    ppBase   = [moveBase,                # More than 1/2 of total PP
                Color.new(248,192,0),    # 1/2 of total PP or less
                Color.new(248,136,32),   # 1/4 of total PP or less
                Color.new(248,72,72)]    # Zero PP
    ppShadow = [moveShadow,             # More than 1/2 of total PP
                Color.new(255,255,255,0),   # 1/2 of total PP or less
                Color.new(255,255,255,0),   # 1/4 of total PP or less
                Color.new(255,255,255,0)]   # Zero PP
    @sprites["pokemon"].visible  = true
    @sprites["pokeicon"].visible = false
    @sprites["itemicon"].visible = true
    textpos  = [
       [_INTL("ITEM"),2,120,0,base,shadow],
       [_INTL("MOVE"),0,152,0,base,shadow],
       [_INTL("INFO/"),0,200,0,base,shadow],
       [_INTL("PRESS Z"),0,216,0,base,shadow]	   
    ]
    # Write the held item's name
	itemName = PBItems.getName(@pokemon.item)
    if @pokemon.hasItem?
	  if itemName.to_s.length > 12
	    textpos.push([PBItems.getName(@pokemon.item),320,120,1,base,shadow])
	  else
	    textpos.push([PBItems.getName(@pokemon.item),128,120,0,base,shadow])
	  end
    else
      textpos.push([_INTL("---"),192,120,1,base,shadow])
    end
    imagepos = []
    # Write move names, types and PP amounts for each known move
    yPos = 152
    for i in 0...@pokemon.moves.length
      move=@pokemon.moves[i]
      if move.id>0
        textpos.push([PBMoves.getName(move.id),128,yPos,0,moveBase,moveShadow])
        if move.totalpp>0
          textpos.push([_INTL("pp"),192,yPos+14,0,moveBase,moveShadow])
          ppfraction = 0
          if move.pp==0;                 ppfraction = 3
          elsif move.pp*4<=move.totalpp; ppfraction = 2
          elsif move.pp*2<=move.totalpp; ppfraction = 1
          end
          textpos.push([sprintf("%d/%d",move.pp,move.totalpp),320,yPos+16,1,ppBase[ppfraction],ppShadow[ppfraction]])
        end
      else
        textpos.push(["-",130,yPos,0,moveBase,moveShadow])
        textpos.push(["--",194,yPos+16,0,moveBase,moveShadow])
      end
      yPos += 32
    end
    # Draw all text and images
    pbDrawTextPositions(overlay,textpos)
    pbDrawImagePositions(overlay,imagepos)
  end

#===============================================================================
# Selection Move
#===============================================================================
  def drawSelectedMove(moveToLearn,moveid)
    # Draw all of page four, except selected move's details
    drawMoveSelection(moveToLearn)
    # Set various values
    overlay = @sprites["overlay"].bitmap
    pbSetSystemFont(overlay)
    base   = Color.new(0,0,0)
    shadow = Color.new(255,255,255,0)
     @sprites["pokemon"].visible = false if @sprites["pokemon"]
     @sprites["pokeicon"].pokemon  = @pokemon
     @sprites["pokeicon"].visible  = false
     @sprites["itemicon"].visible  = false if @sprites["itemicon"]
    # Get data for selected move
    moveData   = pbGetMoveData(moveid)
    basedamage = moveData[MOVE_BASE_DAMAGE]
    #type       = moveData[MOVE_TYPE]
    category   = moveData[MOVE_CATEGORY]
    accuracy   = moveData[MOVE_ACCURACY]
    move = moveid
    textpos = []
    # Write power and accuracy values for selected move
    if basedamage==0 # Status move
      textpos.push(["---",200,260,1,base,shadow])
    elsif basedamage==1 # Variable power move
      textpos.push(["???",200,260,1,base,shadow])
    else
      textpos.push([sprintf("%d",basedamage),200,260,1,base,shadow])
    end
    if accuracy==0
      textpos.push(["---",308,260,1,base,shadow])
    else
      textpos.push([sprintf("%d",accuracy),308+overlay.text_size("%").width,260,1,base,shadow])
    end
    # Draw all text
    pbDrawTextPositions(overlay,textpos)
    # Draw selected move's damage category and type icon
    imagepos = [
	["Graphics/Pictures/category",8,268,0,category*14,122,14]
    ]
    pbDrawImagePositions(overlay,imagepos)
    # Draw selected move's description
    drawTextEx(overlay,0,0,320,6,
    pbGetMessage(MessageTypes::MoveDescriptions,moveid),base,shadow)
  end

#===============================================================================
# Selection move when a Pokémon wants to learn a new one
#===============================================================================
  def drawMoveSelection(moveToLearn)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(0,0,0)
    shadow = Color.new(255,255,255,0)
    moveBase   = Color.new(0,0,0)
    moveShadow = Color.new(176,176,176,0)
    ppBase   = [moveBase,                # More than 1/2 of total PP
                Color.new(248,192,0),    # 1/2 of total PP or less
                Color.new(248,136,32),   # 1/4 of total PP or less
                Color.new(248,72,72)]    # Zero PP
    ppShadow = [moveShadow,             # More than 1/2 of total PP
                Color.new(144,104,0),   # 1/2 of total PP or less
                Color.new(144,72,24),   # 1/4 of total PP or less
                Color.new(136,48,48)]   # Zero PP
    pbSetSystemFont(overlay)
    # Set background image
    if moveToLearn!=0
      @sprites["background"].setBitmap("Graphics/Pictures/Summary/bg_learnmove")
    else
      @sprites["background"].setBitmap("Graphics/Pictures/Summary/bg_2_move")
    end
    # Write various bits of text
    textpos = [
       [_INTL("CATEG"),8,240,0,base,shadow],
       [_INTL("POWER"),120,240,0,base,shadow],
       [_INTL("ACCUR"),230,240,0,base,shadow]
    ]
    imagepos = []
    # Write move names, types and PP amounts for each known move
    yPos = 160
    yPos -= 16 if moveToLearn!=0
    for i in 0...5
      move = @pokemon.moves[i]
      if i==4
        move = PBMove.new(moveToLearn) if moveToLearn!=0
        yPos += 0
      end
      if move && move.id>0
        textpos.push([PBMoves.getName(move.id),0,yPos,0,Color.new(0,0,0)])
        if move.totalpp>0
          ppfraction = 0
          if move.pp==0;                 ppfraction = 3
          elsif move.pp*4<=move.totalpp; ppfraction = 2
          elsif move.pp*2<=move.totalpp; ppfraction = 1
          end
          textpos.push([sprintf("%d/%d",move.pp,move.totalpp),320,yPos+0,1,Color.new(0,0,0)])
        end
      else
        textpos.push(["-",0,yPos,0,Color.new(0,0,0)])
        textpos.push(["--",320,yPos+0,1,Color.new(0,0,0)])
      end
      yPos += 16
    end
    # Draw all text and images
    pbDrawTextPositions(overlay,textpos)
    pbDrawImagePositions(overlay,imagepos)
  end

#===============================================================================
# Move info
#===============================================================================
  def drawInfoMove(pokemon)
    @sprites["background"].setBitmap("Graphics/Pictures/Summary/bg_2_move")
    @sprites["infomove"].visible = true
    @sprites["infomove"].setBitmap("Graphics/Pictures/Summary/info_move_key")
    @sprites["pokemon"].visible = true
    overlay2=@sprites["overlay2"].bitmap
    base=Color.new(0,0,0)
    shadow=Color.new(255,255,255,0)
    pbSetSystemFont(overlay2)
    # Ability
    abilityname=PBAbilities.getName(pokemon.ability)
    abilitydesc=pbGetMessage(MessageTypes::AbilityDescs,pokemon.ability)
    # Get data for selected move
    movedata   = pbGetMoveData(moveid)
    basedamage = moveData[MOVE_BASE_DAMAGE]
    #type       = moveData[MOVE_TYPE]
    category   = moveData[MOVE_CATEGORY]
    accuracy   = moveData[MOVE_ACCURACY]
    move = moveid
    textpos = []
    textpos.push([abilityname,10,10,308,base]) #ability name
    # Write the held item's name
    if @pokemon.hasItem?
      textpos.push([PBItems.getName(@pokemon.item),80,123,0,Color.new(0,0,0)])
    else
      textpos.push([_INTL("NONE"),160,123,0,Color.new(0,0,0)])
    end
    # Write power and accuracy values for selected move
    if basedamage==0 # Status move
      textpos.push(["---",304,40,1,base])
    elsif basedamage==1 # Variable power move
      textpos.push(["???",304,40,1,base])
    else
      textpos.push([sprintf("%d",basedamage),304,40,1,base])
    end
    if accuracy==0
      textpos.push(["---",302,56,1,base])
    else
      textpos.push([sprintf("%d",accuracy),302,56,1,base])
    end
    # Draw all text
    pbDrawTextPositions(overlay2,textpos)
    # Draw selected move's damage category icon
    imagepos = [
    ["Graphics/Pictures/category",8,268,0,category*14,122,14]
    ]
    pbDrawImagePositions(overlay,imagepos)
    loop do
      Input.update
      Graphics.update
      if Input.trigger?(Input::B)
        Input.update
        drawPageTwo
        @sprites["pokemon"].visible = true
        @sprites["infomove"].visible = false
        overlay2.clear
        break
      elsif Input.trigger?(Input::C)
        Input.update
        drawPageTwo
        @sprites["pokemon"].visible = false
        @sprites["background"].visible = true
        overlay2.clear
        break
      end
      pbUpdate
    end
  end
  
#===============================================================================
# Page Three: ID Number, OT, Nature and Stats.
#===============================================================================
  def drawPageThree
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(0,0,0)
    shadow = Color.new(255,255,255,0)
    # Determine which stats are boosted and lowered by the Pokémon's nature
    statsbase = []
    PBStats.eachStat { |s| statsbase[s] = base }
    if !@pokemon.shadowPokemon? || @pokemon.heartStage>3
      natup = PBNatures.getStatRaised(@pokemon.calcNature)
      natdn = PBNatures.getStatLowered(@pokemon.calcNature)
      statsbase[natup] = Color.new(255,0,0) if natup!=natdn
      statsbase[natdn] = Color.new(0,0,255) if natup!=natdn
    end
    # Write various bits of text
    textpos = [
       [_INTL("OT/"),0,184,0,base,shadow],
       [_INTL("NATURE/"),0,232,0,base,shadow],
       [PBNatures.getName(@pokemon.nature),116,248,1,base,shadow],
       [_INTL("ATTACK"),176,120,0,statsbase[PBStats::ATTACK]],
       [sprintf("%d",@pokemon.attack),320,136,1,base,shadow],
       [_INTL("DEFENSE"),176,152,0,statsbase[PBStats::DEFENSE]],
       [sprintf("%d",@pokemon.defense),320,168,1,base,shadow],
       [_INTL("SPCL. ATK"),176,184,0,statsbase[PBStats::SPATK]],
       [sprintf("%d",@pokemon.spatk),320,200,1,base,shadow],
       [_INTL("SPCL. DEF"),176,216,0,statsbase[PBStats::SPDEF]],
       [sprintf("%d",@pokemon.spdef),320,232,1,base,shadow],
       [_INTL("SPEED"),176,248,0,statsbase[PBStats::SPEED]],
       [sprintf("%d",@pokemon.speed),320,264,1,base,shadow]
    ]
    # Write Original Trainer's name and ID number
	$Trainer.male? ? gender = "♂" : "♀"
    if @pokemon.ot==""
      textpos.push([_INTL("RENTAL"),0,192,0,base,shadow])
      textpos.push(["?????",32,208,0,base,shadow])
    else
      textpos.push([_INTL("{1}{2}",@pokemon.ot,gender),32,200,0,base,shadow])
      textpos.push([sprintf("%05d",@pokemon.publicID),32,152,0,base,shadow])
    end
    # Draw all text
    pbDrawTextPositions(overlay,textpos)
    # Draw ID No. picture
      imagepos = [
         ["Graphics/Pictures/Summary/IDNo",2,148,0]
      ]
    pbDrawImagePositions(overlay,imagepos)
  end

#===============================================================================
# Page Four: Ability 
#===============================================================================
  def drawPageFour
  overlay = @sprites["overlay"].bitmap
  base = Color.new(0,0,0)
  shadow = Color.new(255,255,255,0)
  textpos = [
      [_INTL("ABILITY/"),2,120,0,base,shadow],
      [PBAbilities.getName(@pokemon.ability),320,136,1,base,shadow]
	  ]
   # Draw ability description
    abilitydesc = pbGetMessage(MessageTypes::AbilityDescs,@pokemon.ability)
    drawTextEx(overlay,2,160,318,4,abilitydesc,base,shadow)
    # Draw all text
    pbDrawTextPositions(overlay,textpos)
  end

#===============================================================================
# Page Five: Evs and Ivs
#===============================================================================
  def drawPageFive
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(0,0,0)
    shadow = Color.new(255,255,255,0)
    # Determine which stats are boosted and lowered by the Pokémon's nature
    statsbase = []
    PBStats.eachStat { |s| statsbase[s] = base }
    if !@pokemon.shadowPokemon? || @pokemon.heartStage>3
      natup = PBNatures.getStatRaised(@pokemon.calcNature)
      natdn = PBNatures.getStatLowered(@pokemon.calcNature)
      statsbase[natup] = Color.new(255,0,0) if natup!=natdn
      statsbase[natdn] = Color.new(0,0,255) if natup!=natdn
    end
	textpos = [
	   [_INTL("EV's/IV's"),2,120,0,base,shadow],
       [_INTL("HP"),32,144,0,base,shadow],
	   [_INTL("->"),180,144,0,base,shadow],
       [sprintf("%d/%d",@pokemon.ev[0],@pokemon.iv[0]),320,144,1,base,shadow],
       [_INTL("ATTACK"),32,168,0,statsbase[PBStats::ATTACK]],
	   [_INTL("->"),180,168,0,base,shadow],
       [sprintf("%d/%d",@pokemon.ev[1],@pokemon.iv[1]),320,168,1,base,shadow],
       [_INTL("DEFENSE"),32,192,0,statsbase[PBStats::DEFENSE]],
	   [_INTL("->"),180,192,0,base,shadow],
       [sprintf("%d/%d",@pokemon.ev[2],@pokemon.iv[2]),320,192,1,base,shadow],
       [_INTL("SPCL. ATK"),32,216,0,statsbase[PBStats::SPATK]],
	   [_INTL("->"),180,216,0,base,shadow],
       [sprintf("%d/%d",@pokemon.ev[4],@pokemon.iv[4]),320,216,1,base,shadow],
       [_INTL("SPCL. DEF"),32,240,0,statsbase[PBStats::SPDEF]],
	   [_INTL("->"),180,240,0,base,shadow],
       [sprintf("%d/%d",@pokemon.ev[5],@pokemon.iv[5]),320,240,1,base,shadow],
       [_INTL("SPEED"),32,264,0,statsbase[PBStats::SPEED]],
	   [_INTL("->"),180,264,0,base,shadow],
       [sprintf("%d/%d",@pokemon.ev[3],@pokemon.iv[3]),320,264,1,base,shadow]
    ]
    pbDrawTextPositions(overlay,textpos)
	end

  def pbGoToPrevious
    newindex = @partyindex
    while newindex>0
      newindex -= 1
      if @party[newindex] && (@page==1 || !@party[newindex].egg?)
        @partyindex = newindex
        break
      end
    end
  end

  def pbGoToNext
    newindex = @partyindex
    while newindex<@party.length-1
      newindex += 1
      if @party[newindex] && (@page==1 || !@party[newindex].egg?)
        @partyindex = newindex
        break
      end
    end
  end

  def pbChangePokemon
    @pokemon = @party[@partyindex]
    @sprites["pokemon"].setPokemonBitmap(@pokemon)
    @sprites["itemicon"].item = @pokemon.item
    pbSEStop
    pbPlayCry(@pokemon)
  end

  def pbMoveSelection
    @sprites["movesel"].visible = true
    @sprites["movesel"].index   = 0
    selmove    = 0
    oldselmove = 0
    switching = false
    drawSelectedMove(0,@pokemon.moves[selmove].id)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["movepresel"].index==@sprites["movesel"].index
        @sprites["movepresel"].z = @sprites["movesel"].z+1
      else
        @sprites["movepresel"].z = @sprites["movesel"].z
      end
      if Input.trigger?(Input::B)
        (switching) ? pbPlayCancelSE : pbPlayCloseMenuSE
        break if !switching
        @sprites["movepresel"].visible = false
        switching = false
      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE
        if selmove==4
          break if !switching
          @sprites["movepresel"].visible = false
          switching = false
        else
          if !@pokemon.shadowPokemon?
            if !switching
              @sprites["movepresel"].index   = selmove
              @sprites["movepresel"].visible = true
              oldselmove = selmove
              switching = true
            else
              tmpmove                    = @pokemon.moves[oldselmove]
              @pokemon.moves[oldselmove] = @pokemon.moves[selmove]
              @pokemon.moves[selmove]    = tmpmove
              @sprites["movepresel"].visible = false
              switching = false
              drawSelectedMove(0,@pokemon.moves[selmove].id)
            end
          end
        end
      elsif Input.trigger?(Input::UP)
        selmove -= 1
        if selmove<4 && selmove>=@pokemon.numMoves
          selmove = @pokemon.numMoves-1
        end
        selmove = 0 if selmove>=4
        selmove = @pokemon.numMoves-1 if selmove<0
        @sprites["movesel"].index = selmove
        newmove = @pokemon.moves[selmove].id
        pbPlayCursorSE
        drawSelectedMove(0,newmove)
      elsif Input.trigger?(Input::DOWN)
        selmove += 1
        selmove = 0 if selmove<4 && selmove>=@pokemon.numMoves
        selmove = 0 if selmove>=4
        selmove = 4 if selmove<0
        @sprites["movesel"].index = selmove
        newmove = @pokemon.moves[selmove].id
        pbPlayCursorSE
        drawSelectedMove(0,newmove)
      end
    end
    @sprites["movesel"].visible=false
  end

  def pbChooseMoveToForget(moveToLearn)
    selmove = 0
    maxmove = (moveToLearn>0) ? 4 : 3
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::B)
        selmove = 4
        pbPlayCloseMenuSE if moveToLearn>0
        break
      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE
        break
      elsif Input.trigger?(Input::UP)
        selmove -= 1
        selmove = maxmove if selmove<0
        if selmove<4 && selmove>=@pokemon.numMoves
          selmove = @pokemon.numMoves-1
        end
        @sprites["movesel"].index = selmove
        newmove = (selmove==4) ? moveToLearn : @pokemon.moves[selmove].id
        drawSelectedMove(moveToLearn,newmove)
      elsif Input.trigger?(Input::DOWN)
        selmove += 1
        selmove = 0 if selmove>maxmove
        if selmove<4 && selmove>=@pokemon.numMoves
          selmove = (moveToLearn>0) ? maxmove : 0
        end
        @sprites["movesel"].index = selmove
        newmove = (selmove==4) ? moveToLearn : @pokemon.moves[selmove].id
        drawSelectedMove(moveToLearn,newmove)
      end
    end
    return (selmove==4) ? -1 : selmove
  end

  def pbScene
    pbPlayCry(@pokemon)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      dorefresh = false
      if Input.trigger?(Input::A)
        if @page==2
	      pbPlayDecisionSE
		  pbMoveSelection
		  dorefresh = true
		end
      elsif Input.trigger?(Input::B)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::C)
        if @page==1
		  @page += 1
		  dorefresh = true
		elsif @page==2
          @page += 1
		  dorefresh = true
		elsif @page==3
		  @page += 1
		  dorefresh = true
		elsif @page==4
		  @page += 1
		  dorefresh = true
        elsif @page==5
		  break
		end
      elsif Input.trigger?(Input::UP) && @partyindex>0
        oldindex = @partyindex
        pbGoToPrevious
        if @partyindex!=oldindex
          pbChangePokemon
          dorefresh = true
        end
      elsif Input.trigger?(Input::DOWN) && @partyindex<@party.length-1
        oldindex = @partyindex
        pbGoToNext
        if @partyindex!=oldindex
          pbChangePokemon
          dorefresh = true
        end
      elsif Input.trigger?(Input::LEFT) && !@pokemon.egg?
        oldpage = @page
        @page -= 1
        @page = 5 if @page<1
        @page = 1 if @page>5
        if @page!=oldpage   # Move to next page
          dorefresh = true
        end
      elsif Input.trigger?(Input::RIGHT) && !@pokemon.egg?
        oldpage = @page
        @page += 1
        @page = 5 if @page<1
        @page = 1 if @page>5
        if @page!=oldpage   # Move to next page
          dorefresh = true
        end
      end
      if dorefresh
        drawPage(@page)
      end
    end
    return @partyindex
  end
end



class PokemonSummaryScreen
  def initialize(scene,inbattle=false)
    @scene = scene
    @inbattle = inbattle
  end

  def pbStartScreen(party,partyindex)
    @scene.pbStartScene(party,partyindex,@inbattle)
    ret = @scene.pbScene
    @scene.pbEndScene
    return ret
  end

  def pbStartForgetScreen(party,partyindex,moveToLearn)
    ret = -1
    @scene.pbStartForgetScene(party,partyindex,moveToLearn)
    loop do
      ret = @scene.pbChooseMoveToForget(moveToLearn)
      if ret>=0 && moveToLearn!=0 && pbIsHiddenMove?(party[partyindex].moves[ret].id) && !$DEBUG
        pbMessage(_INTL("HM moves can't be forgotten now.")) { @scene.pbUpdate }
      else
        break
      end
    end
    @scene.pbEndScene
    return ret
  end

  def pbStartChooseMoveScreen(party,partyindex,message)
    ret = -1
    @scene.pbStartForgetScene(party,partyindex,0)
    pbMessage(message) { @scene.pbUpdate }
    loop do
      ret = @scene.pbChooseMoveToForget(0)
      if ret<0
        pbMessage(_INTL("You must choose a move!")) { @scene.pbUpdate }
      else
        break
      end
    end
    @scene.pbEndScene
    return ret
  end
end
