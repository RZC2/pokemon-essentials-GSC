#=begin
class PokedexSearchSelectionSprite < SpriteWrapper
  attr_reader :index

  def initialize(viewport=nil)
    super(viewport)
    @selbitmap = AnimatedBitmap.new("Graphics/Pictures/selarrow_white")
    self.bitmap = @selbitmap.bitmap
    self.mode = -1
    @index = 0
    refresh
  end

  def dispose
    @selbitmap.dispose
    super
  end

  def index=(value)
    @index = value
    refresh
  end

  def refresh
    #self.src_rect.y = 0; self.src_rect.height = 16
	#self.src_rect.x = 0; self.src_rect.width = 16
    case @index
	when 0; self.x = 34; self.y = 53
	when 1; self.x = 34; self.y = 85
	when 2; self.x = 34; self.y = 197
	when 3; self.x = 34; self.y = 229
	end
  end
end
#===============================================================================
# Pokédex main screen
#===============================================================================
class PokemonPokedex_Scene
  def pbUpdate
	if @sprites["searchbg"].visible
		if @frame == 10
			@frame = 0
			@sprites["searchcursor"].visible = !(@sprites["searchcursor"].visible)
		end
		@frame += 1
	end
    pbUpdateSpriteHash(@sprites)
  end
  
  def pbStartScene
    @sliderbitmap       = AnimatedBitmap.new("Graphics/Pictures/Pokedex/icon_slider")
    @typebitmap         = AnimatedBitmap.new(_INTL("Graphics/Pictures/Pokedex/icon_types"))
    @shapebitmap        = AnimatedBitmap.new("Graphics/Pictures/Pokedex/icon_shapes")
    @hwbitmap           = AnimatedBitmap.new("Graphics/Pictures/Pokedex/icon_hw")
    @selbitmap          = AnimatedBitmap.new("Graphics/Pictures/Pokedex/icon_searchsel")
    @searchsliderbitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/Pokedex/icon_searchslider"))
    @sprites = {}
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    addBackgroundPlane(@sprites,"background","Pokedex/bg_list",@viewport)
#=end
=begin
# Suggestion for changing the background depending on region. You can change
# the line above with the following:
    if pbGetPokedexRegion==-1   # Using national Pokédex
      addBackgroundPlane(@sprites,"background","Pokedex/bg_national",@viewport)
    elsif pbGetPokedexRegion==0   # Using first regional Pokédex
      addBackgroundPlane(@sprites,"background","Pokedex/bg_regional",@viewport)
    end
=end
#=begin
    addBackgroundPlane(@sprites,"searchbg","Pokedex/bg_search",@viewport)
    @sprites["searchbg"].visible = false
    @sprites["pokedex"] = Window_Pokedex.new(110,0,210,272,@viewport)
	@sprites["bgicon"]=IconSprite.new(6,16,@viewport)
	barBitmap = Bitmap.new(112,112)
	barRect = Rect.new(0,0,barBitmap.width,barBitmap.height)
	barBitmap.fill_rect(barRect,Color.new(88,184,0))
	@sprites["bgicon"].bitmap = barBitmap
    @sprites["icon"] = PokemonSprite.new(@viewport)
    @sprites["icon"].setOffset(PictureOrigin::Center)
    @sprites["icon"].x = 62
    @sprites["icon"].y = 72
    @sprites["icon"].tone = Tone.new(0,0,0,255)
    @sprites["overlayscrn"] = IconSprite.new(0,0,@viewport)
    @sprites["overlayscrn"].setBitmap("Graphics/Pictures/Pokedex/OverlayScreen")
    @sprites["overlayscrn"].blend_type=2
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["searchcursor"] = PokedexSearchSelectionSprite.new(@viewport)
    @sprites["searchcursor"].visible = false
    @sprites["searchanim"] = IconSprite.new(128,144,@viewport)
    @sprites["searchanim"].setBitmap("Graphics/Pictures/Pokedex/icon_searching")
    @sprites["searchanim"].src_rect.set(0,0,48,48)
	@sprites["searchanim"].visible = false
	@frame = 0
    @searchResults = false
    @searchParams  = [$PokemonGlobal.pokedexMode,-1,0,-1,-1,-1,-1,-1,-1,-1]
    pbRefreshDexList($PokemonGlobal.pokedexIndex[pbGetSavePositionIndex])
    pbDeactivateWindows(@sprites)
    pbFadeInAndShow(@sprites)
  end
  
  def pbDexSearch
    oldsprites = pbFadeOutAndHide(@sprites)
    params = @searchParams.clone
    #@orderCommands = []
    #@orderCommands[MODENUMERICAL] = _INTL("NUMERICAL")
    #@orderCommands[MODEATOZ]      = _INTL("A TO Z")
    #@orderCommands[MODEHEAVIEST]  = _INTL("HEAVIEST")
    #@orderCommands[MODELIGHTEST]  = _INTL("LIGHTEST")
    #@orderCommands[MODETALLEST]   = _INTL("TALLEST")
    #@orderCommands[MODESMALLEST]  = _INTL("SMALLEST")
    #@nameCommands = [_INTL("A"),_INTL("B"),_INTL("C"),_INTL("D"),_INTL("E"),
    #                _INTL("F"),_INTL("G"),_INTL("H"),_INTL("I"),_INTL("J"),
    #                _INTL("K"),_INTL("L"),_INTL("M"),_INTL("N"),_INTL("O"),
    #                _INTL("P"),_INTL("Q"),_INTL("R"),_INTL("S"),_INTL("T"),
    #                _INTL("U"),_INTL("V"),_INTL("W"),_INTL("X"),_INTL("Y"),
    #                _INTL("Z")]
    @typeCommands = []
    for i in 0..PBTypes.maxValue
      @typeCommands.push(i) if !PBTypes.isPseudoType?(i)
    end
    #@heightCommands = [1,2,3,4,5,6,7,8,9,10,
    #                   11,12,13,14,15,16,17,18,19,20,
    #                   21,22,23,24,25,30,35,40,45,50,
    #                   55,60,65,70,80,90,100]
    #@weightCommands = [5,10,15,20,25,30,35,40,45,50,
    #                   55,60,70,80,90,100,110,120,140,160,
    #                   180,200,250,300,350,400,500,600,700,800,
    #                   900,1000,1250,1500,2000,3000,5000]
    #@colorCommands = []
    #for i in 0..PBColors.maxValue
    #  j = PBColors.getName(i)
    #  @colorCommands.push(j) if j
    #end
    #@shapeCommands = []
    #for i in 0...14; @shapeCommands.push(i); end
    @sprites["searchbg"].visible     = true
    @sprites["overlay"].visible      = true
    @sprites["searchcursor"].visible = true
	@sprites["searchanim"].visible = true
    index = 0
    oldindex = index
    @sprites["searchcursor"].mode    = -1
    @sprites["searchcursor"].index   = index
    pbRefreshDexSearch(params,index)
    pbFadeInAndShow(@sprites)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if index!=oldindex
        @sprites["searchcursor"].index = index
        oldindex = index
      end
      if Input.trigger?(Input::UP)
        index -= 1 if index>0
        pbPlayCursorSE if index!=oldindex
      elsif Input.trigger?(Input::DOWN)
        index += 1 if index<3
        pbPlayCursorSE if index!=oldindex
      elsif Input.trigger?(Input::LEFT)
        if index==0 || index==1
			param_index = (index==0)? 2 : 3
			param = params[param_index]
			param -= 1
			param -= 1 if PBTypes.isPseudoType?(param)
			if index == 1 && param < 0
				param = (param<-1)? PBTypes.maxValue : -1
			elsif param < 0
				param = PBTypes.maxValue
			end
			params[param_index] = param
			pbRefreshDexSearch(params,index)
			pbPlayCursorSE
        end
      elsif Input.trigger?(Input::RIGHT)
        if index==0 || index==1
			param_index = (index==0)? 2 : 3
			param = params[param_index]
			param += 1
			param += 1 if PBTypes.isPseudoType?(param)
			if index == 1 && param > PBTypes.maxValue
				param = -1
			elsif param > PBTypes.maxValue
				param = 0
			end
			params[param_index] = param
			pbRefreshDexSearch(params,index)
			pbPlayCursorSE
        end
      elsif Input.trigger?(Input::B)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE if index!=2
		case index
        when 2   # Start search (filter)
		  @frame = 0
		  @sprites["searchcursor"].visible = true
		  pbAnimSearch
          dexlist = pbSearchDexList(params)
          if dexlist.length==0
            pbMessage(_INTL("<c3=FFFFFFFF,00000000>No matching POKéMON were found.</c3>\\wtnp[40]"),nil,0,"Graphics/Windowskins/search")
          else
            @dexlist = dexlist
            @sprites["pokedex"].commands = @dexlist
            @sprites["pokedex"].index    = 0
            @sprites["pokedex"].refresh
            @searchResults = true
            @searchParams = params
            break
          end
        when 3   # Cancel
          pbPlayCloseMenuSE
          break
        end
      end
    end
    pbFadeOutAndHide(@sprites)
    if @searchResults
      @sprites["background"].setBitmap("Graphics/Pictures/Pokedex/bg_listsearch")
    else
      @sprites["background"].setBitmap("Graphics/Pictures/Pokedex/bg_list")
    end
    pbRefresh
    pbFadeInAndShow(@sprites,oldsprites)
    Input.update
    return 0
  end
  
  def pbAnimSearch
	pbWait(20)
	5.times do
		i = 0
		5.times do
			@sprites["searchanim"].src_rect.set(0+48*i,0,48,48)
			pbWait(4)
			i+=1
		end
	end
  end
  
  def pbRefreshDexSearch(params,_index)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(248,248,248)
    shadow = Color.new(0,0,0,0)
    # Write various bits of text
    textpos = []
    # Draw type text
    if params[2]>=0
	  textpos.push([_INTL("{1}",PBTypes.getName(params[2])),208,56,2,base,shadow,1])
    else
      textpos.push(["----",208,56,2,base,shadow,1])
    end
    if params[3]>=0
      textpos.push([_INTL("{1}",PBTypes.getName(params[3])),208,88,2,base,shadow,1])
    else
      textpos.push(["----",208,88,2,base,shadow,1])
    end
    # Draw all text
    pbDrawTextPositions(overlay,textpos)
  end
  def pbCloseSearch
    oldsprites = pbFadeOutAndHide(@sprites)
    oldspecies = @sprites["pokedex"].species
    @searchResults = false
    $PokemonGlobal.pokedexMode = MODENUMERICAL
    @searchParams  = [$PokemonGlobal.pokedexMode,-1,0,-1,-1,-1,-1,-1,-1,-1]
    pbRefreshDexList($PokemonGlobal.pokedexIndex[pbGetSavePositionIndex])
    for i in 0...@dexlist.length
      next if @dexlist[i][0]!=oldspecies
      @sprites["pokedex"].index = i
      pbRefresh
      break
    end
    $PokemonGlobal.pokedexIndex[pbGetSavePositionIndex] = @sprites["pokedex"].index
    pbFadeInAndShow(@sprites,oldsprites)
  end
  
  def pbSearchDexList(params)
    $PokemonGlobal.pokedexMode = params[0]
    dexlist = pbGetDexList
    # Filter by name
    if params[1]>=0
      scanNameCommand = @nameCommands[params[1]].scan(/./)
      dexlist = dexlist.find_all { |item|
        next false if !$Trainer.seen[item[0]]
        firstChar = item[1][0,1]
        next scanNameCommand.any? { |v| v==firstChar }
      }
    end
    # Filter by type
    if params[2]>=0 || params[3]>=0
      stype1 = (params[2]>=0) ? params[2] : -1#@typeCommands[params[2]] : -1
      stype2 = (params[3]>=0) ? params[3] : -1#@typeCommands[params[3]] : -1
      dexlist = dexlist.find_all { |item|
        next false if !$Trainer.owned[item[0]]
        type1 = item[6]
        type2 = item[7]
        if stype1>=0 && stype2>=0
          # Find species that match both types
          next (type1==stype1 && type2==stype2) || (type1==stype2 && type2==stype1)
        elsif stype1>=0
          # Find species that match first type entered
          next type1==stype1 || type2==stype1
        elsif stype2>=0
          # Find species that match second type entered
          next type1==stype2 || type2==stype2
        else
          next false
        end
      }
    end
    # Filter by height range
    if params[4]>=0 || params[5]>=0
      minh = (params[4]<0) ? 0 : (params[4]>=@heightCommands.length) ? 999 : @heightCommands[params[4]]
      maxh = (params[5]<0) ? 999 : (params[5]>=@heightCommands.length) ? 0 : @heightCommands[params[5]]
      dexlist = dexlist.find_all { |item|
        next false if !$Trainer.owned[item[0]]
        height = item[2]
        next height>=minh && height<=maxh
      }
    end
    # Filter by weight range
    if params[6]>=0 || params[7]>=0
      minw = (params[6]<0) ? 0 : (params[6]>=@weightCommands.length) ? 9999 : @weightCommands[params[6]]
      maxw = (params[7]<0) ? 9999 : (params[7]>=@weightCommands.length) ? 0 : @weightCommands[params[7]]
      dexlist = dexlist.find_all { |item|
        next false if !$Trainer.owned[item[0]]
        weight = item[3]
        next weight>=minw && weight<=maxw
      }
    end
    # Filter by color
    if params[8]>=0
      colorCommands = []
      for i in 0..PBColors.maxValue
        j = PBColors.getName(i)
        colorCommands.push(i) if j
      end
      scolor = colorCommands[params[8]]
      dexlist = dexlist.find_all { |item|
        next false if !$Trainer.seen[item[0]]
        color = item[8]
        next color==scolor
      }
    end
    # Filter by shape
    if params[9]>=0
      sshape = @shapeCommands[params[9]]+1
      dexlist = dexlist.find_all { |item|
        next false if !$Trainer.seen[item[0]]
        shape = item[9]
        next shape==sshape
      }
    end
    # Remove all unseen species from the results
    dexlist = dexlist.find_all { |item| next $Trainer.seen[item[0]] }
    case $PokemonGlobal.pokedexMode
    when MODENUMERICAL; dexlist.sort! { |a,b| a[4]<=>b[4] }
    when MODEATOZ;      dexlist.sort! { |a,b| a[1]<=>b[1] }
    when MODEHEAVIEST;  dexlist.sort! { |a,b| b[3]<=>a[3] }
    when MODELIGHTEST;  dexlist.sort! { |a,b| a[3]<=>b[3] }
    when MODETALLEST;   dexlist.sort! { |a,b| b[2]<=>a[2] }
    when MODESMALLEST;  dexlist.sort! { |a,b| a[2]<=>b[2] }
    end
    return dexlist
  end

end
#=end