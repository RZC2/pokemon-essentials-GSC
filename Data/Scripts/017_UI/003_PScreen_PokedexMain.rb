class Window_Pokedex < Window_DrawableCommand
  def initialize(x,y,width,height,viewport)
    @commands = []
    super(x,y,width,height,viewport)
    @selarrow     = AnimatedBitmap.new("Graphics/Pictures/Pokedex/cursor_list")
    @pokeballOwn  = AnimatedBitmap.new("Graphics/Pictures/Pokedex/icon_own")
    @pokeballSeen = AnimatedBitmap.new("Graphics/Pictures/Pokedex/icon_seen")
    self.baseColor   = Color.new(248,248,248)
    self.shadowColor = Color.new(0,0,0,0)
    self.windowskin  = nil
  end

  def commands=(value)
    @commands = value
    refresh
  end

  def dispose
    @pokeballOwn.dispose
    @pokeballSeen.dispose
    super
  end

  def species
    return (@commands.length==0) ? 0 : @commands[self.index][0]
  end

  def itemCount
    return @commands.length
  end

  def drawItem(index,_count,rect)
    return if index>=self.top_row+self.page_item_max
    rect = Rect.new(rect.x+16,rect.y-1,rect.width-16,rect.height)
    species     = @commands[index][0]
    indexNumber = @commands[index][4]
    indexNumber -= 1 if @commands[index][5]
    if $Trainer.seen[species]
      if $Trainer.owned[species]
        pbCopyBitmap(self.contents,@pokeballOwn.bitmap,rect.x-14,rect.y+17)
      else
        pbCopyBitmap(self.contents,@pokeballSeen.bitmap,rect.x-14,rect.y+17)
      end
      #text = sprintf("%03d%s %s",indexNumber," ",@commands[index][1])
	  text = @commands[index][1]
    else
      #text = sprintf("%03d  ----------",indexNumber)
	  text = "-----"
    end
    pbDrawShadowText(self.contents,rect.x+2,rect.y+6,rect.width,rect.height,
       text,self.baseColor,self.shadowColor)
  end

  def refresh
    @item_max = itemCount
    dwidth  = self.width-self.borderX
    dheight = self.height-self.borderY
    self.contents = pbDoEnsureBitmap(self.contents,dwidth,dheight)
    self.contents.clear
    for i in 0...@item_max
      next if i<self.top_item || i>self.top_item+self.page_item_max
      drawItem(i,@item_max,itemRect(i))
    end
    drawCursor(self.index,itemRect(self.index))
  end

  def update
    super
    @uparrow.visible   = false
    @downarrow.visible = false
  end
end



class PokedexSearchSelectionSprite < SpriteWrapper
  attr_reader :index
  attr_accessor :cmds
  attr_accessor :minmax

  def initialize(viewport=nil)
    super(viewport)
    @selbitmap = AnimatedBitmap.new("Graphics/Pictures/Pokedex/white_cursor")
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

  def mode=(value)
    @mode = value
    case @mode
    when 0    # Order
      @xstart = 20; @ystart = 72
      @xgap = 160; @ygap = 18
      @cols = 1
    when 1     # Name
      @xstart = 20; @ystart = 72
      @xgap = 32; @ygap = 18
      @cols = 7
    when 2     # Type
      @xstart = 20; @ystart = 72
      @xgap = 80; @ygap = 18
      @cols = 3
    when 3,4   # Height, weight
      @xstart = 54; @ystart = 74
      @xgap = 4; @ygap = 126
    when 5     # Color
      @xstart = 20; @ystart = 72
      @xgap = 112; @ygap = 18
      @cols = 2
    when 6     # Shape
      @xstart = 20; @ystart = 72
      @xgap = 52; @ygap = 48
      @cols = 5
    end
  end

  def refresh
    # Size and position cursor
    if @mode==-1   # Main search screen
      case @index
      when 0,1,5    # Order, Name, Color
        self.src_rect.y = 0; self.src_rect.height = 16
		self.src_rect.x = 0; self.src_rect.width = 16
      #when 1,5   # Name, color
       # self.src_rect.y = 44; self.src_rect.height = 44
      when 2     # Type
        self.src_rect.y = 18; self.src_rect.height = 16
		self.src_rect.x = 0; self.src_rect.width = 96
      when 3,4   # Height, weight
        self.src_rect.y = 0; self.src_rect.height = 34
		self.src_rect.x = 0; self.src_rect.width = 16
      when 6     # Form (shape)
        self.src_rect.y = 34; self.src_rect.height = 48
		self.src_rect.x = 0; self.src_rect.width = 52
      else       # Reset/start/cancel
        self.src_rect.y = 0; self.src_rect.height = 16
		self.src_rect.x = 32; self.src_rect.width = 16
      end
      case @index
      when 0         # Order
        self.x = 128; self.y = 48
      when 1         # Name
        self.x = 128; self.y = 66 #+(@index-1)*52
	  when 2         # Type
	    self.x = 128; self.y = 84
	  when 3         # Height
	    self.x = 128; self.y = 102
	  when 4         # Weight
	    self.x = 128; self.y = 138
      when 5         # Color
        self.x = 128; self.y = 174
      when 6         # Shape
        self.x = 190; self.y = 192
      when 7         # Reset
        self.x = 36; self.y =242 #+(@index-7)*176; self.y = 334
      when 8         # Start
	    self.x = 152; self.y = 242
	  when 9         # Cancel
	    self.x = 268; self.y = 242
	  end
    else   # Parameter screen
      case @index
      when -2,-3   # OK, Cancel
        self.src_rect.y = 0; self.src_rect.height = 16
		self.src_rect.x = 0; self.src_rect.width = 16
      else
        case @mode
        when 0     # Order
          self.src_rect.y = 0; self.src_rect.height = 16
		  self.src_rect.x = 0; self.src_rect.width = 16
        when 1     # Name
          self.src_rect.y = 0; self.src_rect.height = 16
		  self.src_rect.x = 0; self.src_rect.width = 16
        when 2,5   # Type, color
          self.src_rect.y = 0; self.src_rect.height = 16
		  self.src_rect.x = 0; self.src_rect.width = 16
        when 3,4   # Height, weight
          self.src_rect.y = 34; self.src_rect.height = 48
		  self.src_rect.x = 0; self.src_rect.width = 52
        when 6     # Shape
          self.src_rect.y = 34; self.src_rect.height = 48
		  self.src_rect.x = 0; self.src_rect.width = 52
        end
      end
      case @index
      when -1   # Blank option
        if @mode==3 || @mode==4   # Height/weight range
          self.x = @xstart+(@cmds+1)*@xgap*(@minmax%2)
          self.y = @ystart+@ygap*((@minmax+1)%2)
        else
          self.x = @xstart+(@cols-1)*@xgap
          self.y = @ystart+(@cmds/@cols).floor*@ygap
        end
      when -2   # OK
        self.x = 20; self.y = 258
      when -3   # Cancel
        self.x = 188; self.y = 258
      else
        case @mode
        when 0,1,2,5,6   # Order, name, type, color, shape
          if @index>=@cmds
            self.x = @xstart+(@cols-1)*@xgap
            self.y = @ystart+(@cmds/@cols).floor*@ygap
          else
            self.x = @xstart+(@index%@cols)*@xgap
            self.y = @ystart+(@index/@cols).floor*@ygap
          end
        when 3,4         # Height, weight
          if @index>=@cmds
            self.x = @xstart+(@cmds+1)*@xgap*((@minmax+1)%2)
          else
            self.x = @xstart+(@index+1)*@xgap
          end
          self.y = @ystart+@ygap*((@minmax+1)%2)
        end
      end
    end
  end
end



#===============================================================================
# Pokédex main screen
#===============================================================================
class PokemonPokedex_Scene
  MODENUMERICAL = 0
  MODEATOZ      = 1
  MODETALLEST   = 2
  MODESMALLEST  = 3
  MODEHEAVIEST  = 4
  MODELIGHTEST  = 5

  def pbUpdate
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
=begin
# Suggestion for changing the background depending on region. You can change
# the line above with the following:
    if pbGetPokedexRegion==-1   # Using national Pokédex
      addBackgroundPlane(@sprites,"background","Pokedex/bg_national",@viewport)
    elsif pbGetPokedexRegion==0   # Using first regional Pokédex
      addBackgroundPlane(@sprites,"background","Pokedex/bg_regional",@viewport)
    end
=end
    addBackgroundPlane(@sprites,"searchbg","Pokedex/bg_search",@viewport)
    @sprites["searchbg"].visible = false
    @sprites["pokedex"] = Window_Pokedex.new(110,0,210,272,@viewport)
    @sprites["icon"] = PokemonSprite.new(@viewport)
    @sprites["icon"].setOffset(PictureOrigin::Center)
    @sprites["icon"].x = 62
    @sprites["icon"].y = 72
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["searchcursor"] = PokedexSearchSelectionSprite.new(@viewport)
    @sprites["searchcursor"].visible = false
    @searchResults = false
    @searchParams  = [$PokemonGlobal.pokedexMode,-1,-1,-1,-1,-1,-1,-1,-1,-1]
    pbRefreshDexList($PokemonGlobal.pokedexIndex[pbGetSavePositionIndex])
    pbDeactivateWindows(@sprites)
    pbFadeInAndShow(@sprites)
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
    @sliderbitmap.dispose
    @typebitmap.dispose
    @shapebitmap.dispose
    @hwbitmap.dispose
    @selbitmap.dispose
    @searchsliderbitmap.dispose
    @viewport.dispose
  end

  # Gets the region used for displaying Pokédex entries. Species will be listed
  # according to the given region's numbering and the returned region can have
  # any value defined in the town map data file. It is currently set to the
  # return value of pbGetCurrentRegion, and thus will change according to the
  # current map's MapPosition metadata setting.
  def pbGetPokedexRegion
    if USE_CURRENT_REGION_DEX
      region = pbGetCurrentRegion
      region = -1 if region>=$PokemonGlobal.pokedexUnlocked.length-1
      return region
    else
      return $PokemonGlobal.pokedexDex   # National Dex -1, regional dexes 0 etc.
    end
  end

  # Determines which index of the array $PokemonGlobal.pokedexIndex to save the
  # "last viewed species" in. All regional dexes come first in order, then the
  # National Dex at the end.
  def pbGetSavePositionIndex
    index = pbGetPokedexRegion
    if index==-1   # National Dex
      index = $PokemonGlobal.pokedexUnlocked.length-1   # National Dex index comes
    end                                                 # after regional Dex indices
    return index
  end

  def pbCanAddForModeList?(mode,nationalSpecies)
    case mode
    when MODENUMERICAL
      return true
    when MODEATOZ
      return $Trainer.seen[nationalSpecies]
    when MODEHEAVIEST, MODELIGHTEST, MODETALLEST, MODESMALLEST
      return $Trainer.owned[nationalSpecies]
    end
  end

  def pbGetDexList
    dexlist = []
    speciesData = pbLoadSpeciesData
    region = pbGetPokedexRegion
    regionalSpecies = pbAllRegionalSpecies(region)
    if regionalSpecies.length==1
      # If no Regional Dex defined for the given region, use National Pokédex
      for i in 1..PBSpecies.maxValue
        regionalSpecies.push(i)
      end
    end
    for i in 1...regionalSpecies.length
      nationalSpecies = regionalSpecies[i]
      if pbCanAddForModeList?($PokemonGlobal.pokedexMode,nationalSpecies)
        form = $Trainer.formlastseen[nationalSpecies][1] || 0
        fspecies = pbGetFSpeciesFromForm(nationalSpecies,form)
        color  = speciesData[fspecies][SpeciesColor] || 0
        type1  = speciesData[fspecies][SpeciesType1] || 0
        type2  = speciesData[fspecies][SpeciesType2] || type1
        shape  = speciesData[fspecies][SpeciesShape] || 0
        height = speciesData[fspecies][SpeciesHeight] || 1
        weight = speciesData[fspecies][SpeciesWeight] || 1
        shift = DEXES_WITH_OFFSETS.include?(region)
        dexlist.push([nationalSpecies,PBSpecies.getName(nationalSpecies),
           height,weight,i,shift,type1,type2,color,shape])
      end
    end
    return dexlist
  end

  def pbRefreshDexList(index=0)
    dexlist = pbGetDexList
    case $PokemonGlobal.pokedexMode
    when MODENUMERICAL
      # Hide the Dex number 0 species if unseen
      dexlist[0] = nil if dexlist[0][5] && !$Trainer.seen[dexlist[0][0]]
      # Remove unseen species from the end of the list
      i = dexlist.length-1; loop do break unless i>=0
        break if !dexlist[i] || $Trainer.seen[dexlist[i][0]]
        dexlist[i] = nil
        i -= 1
      end
      dexlist.compact!
      # Sort species in ascending order by Regional Dex number
      dexlist.sort! { |a,b| a[4]<=>b[4] }
    when MODEATOZ
      dexlist.sort! { |a,b| (a[1]==b[1]) ? a[4]<=>b[4] : a[1]<=>b[1] }
    when MODEHEAVIEST
      dexlist.sort! { |a,b| (a[3]==b[3]) ? a[4]<=>b[4] : b[3]<=>a[3] }
    when MODELIGHTEST
      dexlist.sort! { |a,b| (a[3]==b[3]) ? a[4]<=>b[4] : a[3]<=>b[3] }
    when MODETALLEST
      dexlist.sort! { |a,b| (a[2]==b[2]) ? a[4]<=>b[4] : b[2]<=>a[2] }
    when MODESMALLEST
      dexlist.sort! { |a,b| (a[2]==b[2]) ? a[4]<=>b[4] : a[2]<=>b[2] }
    end
    @dexlist = dexlist
    @sprites["pokedex"].commands = @dexlist
    @sprites["pokedex"].index    = index
    @sprites["pokedex"].refresh
    if @searchResults
      @sprites["background"].setBitmap("Graphics/Pictures/Pokedex/bg_listsearch")
    else
      @sprites["background"].setBitmap("Graphics/Pictures/Pokedex/bg_list")
    end
    pbRefresh
  end

  def pbRefresh
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(248,248,248)
    shadow = Color.new(0,0,0,0)
    iconspecies = @sprites["pokedex"].species
    iconspecies = 0 if !$Trainer.seen[iconspecies]
    # Write various bits of text
    dexname = _INTL("Pokédex")
    if $PokemonGlobal.pokedexUnlocked.length>1
      thisdex = pbDexNames[pbGetSavePositionIndex]
      if thisdex!=nil
        dexname = (thisdex.is_a?(Array)) ? thisdex[0] : thisdex
      end
    end
    textpos = []
       #[dexname,64,160,2,Color.new(255,255,255),Color.new(0,0,0,0)]
    #textpos.push([PBSpecies.getName(iconspecies),112,52,2,base,shadow]) if iconspecies>0
    if @searchResults
      textpos.push([_INTL("FOUND:"),6,192,0,base,shadow])
      textpos.push([@dexlist.length.to_s,120,208,1,base,shadow])
    else
      textpos.push([_INTL("SEEN:"),6,168,0,base,shadow])
      textpos.push([$Trainer.pokedexSeen(pbGetPokedexRegion).to_s,118,184,1,base,shadow])
      textpos.push([_INTL("OWN:"),6,216,0,base,shadow])
      textpos.push([$Trainer.pokedexOwned(pbGetPokedexRegion).to_s,118,232,1,base,shadow])
    end
    # Draw all text
    pbDrawTextPositions(overlay,textpos)
    # Set Pokémon sprite
    setIconBitmap(iconspecies)
    # Draw slider arrows
    itemlist = @sprites["pokedex"]
    showslider = false
    if itemlist.top_row>0
      #overlay.blt(468,48,@sliderbitmap.bitmap,Rect.new(0,0,40,30))
      showslider = true
    end
    if itemlist.top_item+itemlist.page_item_max<itemlist.itemCount
      #overlay.blt(468,346,@sliderbitmap.bitmap,Rect.new(0,30,40,30))
      showslider = true
    end
    # Draw slider box
    if showslider
      #sliderheight = 268
      #boxheight = (sliderheight*itemlist.page_row_max/itemlist.row_max).floor
      #boxheight += [(sliderheight-boxheight)/2,sliderheight/6].min
      #boxheight = [boxheight.floor,40].max
      y = 10
	  y+=242*itemlist.index/(itemlist.row_max-1)
      #y += ((sliderheight-boxheight)*itemlist.top_row/(itemlist.row_max-itemlist.page_row_max)).floor
      #overlay.blt(468,y,@sliderbitmap.bitmap,Rect.new(40,0,40,8))
      #i = 0
      #while i*16<boxheight-8-16
        #height = [boxheight-8-16-i*16,16].min
        overlay.blt(308,y,@sliderbitmap.bitmap,Rect.new(0,0,10,10))
        #i += 1
      #end
      #overlay.blt(468,y+boxheight-16,@sliderbitmap.bitmap,Rect.new(40,24,40,16))
    end
  end

  def pbRefreshDexSearch(params,_index)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(248,248,248)
    shadow = Color.new(0,0,0,0)
    # Write various bits of text
    textpos = [
       [_INTL("SEARCH"),Graphics.width/2,8,2,base,shadow],
       [_INTL("ORDER"),20,40,0,base,shadow],
       [_INTL("NAME"),20,58,0,base,shadow],
       [_INTL("TYPE"),20,76,0,base,shadow],
       [_INTL("MIN HT"),20,94,0,base,shadow],
       [_INTL("MAX HT"),20,112,0,base,shadow],
       [_INTL("MIN WT"),20,130,0,base,shadow],
       [_INTL("MAX WT"),20,148,0,base,shadow],
	   [_INTL("COLOR"),20,166,0,base,shadow],
	   [_INTL("SHAPE"),20,184,0,base,shadow],
	   [_INTL("CLR"),20,250,0,base,shadow,1],
       [_INTL("GO"),160,250,2,base,shadow,1],
       [_INTL("[X]"),300,250,1,base,shadow,1]
    ]
    # Write order, name and color parameters
    textpos.push([@orderCommands[params[0]],288,40,1,base,shadow,1])
    textpos.push([(params[1]<0) ? "----" : @nameCommands[params[1]],288,58,1,base,shadow,1])
    textpos.push([(params[8]<0) ? "----" : @colorCommands[params[8]],288,166,1,base,shadow,1])
    # Draw type icons
    if params[2]>=0
      typerect = Rect.new(0,@typeCommands[params[2]]*28,64,28)
      overlay.blt(144,78,@typebitmap.bitmap,typerect)
    else
      textpos.push(["----",208,76,1,base,shadow,1])
    end
    if params[3]>=0
      typerect = Rect.new(0,@typeCommands[params[3]]*28,64,28)
      overlay.blt(224,78,@typebitmap.bitmap,typerect)
    else
      textpos.push(["----",288,76,1,base,shadow,1])
    end
    # Write height and weight limits
    ht1 = (params[4]<0) ? 0 : (params[4]>=@heightCommands.length) ? 999 : @heightCommands[params[4]]
    ht2 = (params[5]<0) ? 999 : (params[5]>=@heightCommands.length) ? 0 : @heightCommands[params[5]]
    wt1 = (params[6]<0) ? 0 : (params[6]>=@weightCommands.length) ? 9999 : @weightCommands[params[6]]
    wt2 = (params[7]<0) ? 9999 : (params[7]>=@weightCommands.length) ? 0 : @weightCommands[params[7]]
    hwoffset = false
    if pbGetCountry==0xF4   # If the user is in the United States
      ht1 = (params[4]>=@heightCommands.length) ? 99*12 : (ht1/0.254).round
      ht2 = (params[5]<0) ? 99*12 : (ht2/0.254).round
      wt1 = (params[6]>=@weightCommands.length) ? 99990 : (wt1/0.254).round
      wt2 = (params[7]<0) ? 99990 : (wt2/0.254).round
      textpos.push([sprintf("%d'%02d''",ht1/12,ht1%12),288,94,1,base,shadow,1])
      textpos.push([sprintf("%d'%02d''",ht2/12,ht2%12),288,112,1,base,shadow,1])
      textpos.push([sprintf("%.1f",wt1/10.0),288,130,1,base,shadow,1])
      textpos.push([sprintf("%.1f",wt2/10.0),288,148,1,base,shadow,1])
      hwoffset = true
    else
      textpos.push([sprintf("%.1f",ht1/10.0),288,94,1,base,shadow,1])
      textpos.push([sprintf("%.1f",ht2/10.0),288,112,1,base,shadow,1])
      textpos.push([sprintf("%.1f",wt1/10.0),288,130,1,base,shadow,1])
      textpos.push([sprintf("%.1f",wt2/10.0),288,148,1,base,shadow,1])
    end
    overlay.blt(288,102,@hwbitmap.bitmap,Rect.new(0,(hwoffset) ? 16 : 0,16,16))
	overlay.blt(288,120,@hwbitmap.bitmap,Rect.new(0,(hwoffset) ? 16 : 0,16,16))
    overlay.blt(288,138,@hwbitmap.bitmap,Rect.new(16,(hwoffset) ? 16 : 0,16,16))
    overlay.blt(288,156,@hwbitmap.bitmap,Rect.new(16,(hwoffset) ? 16 : 0,16,16))
    # Draw shape icon
    if params[9]>=0
      shaperect = Rect.new(0,params[9]*60,60,60)
      overlay.blt(186,184,@shapebitmap.bitmap,shaperect)
    end
    # Draw all text
    pbDrawTextPositions(overlay,textpos)
  end

  def pbRefreshDexSearchParam(mode,cmds,sel,_index)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(248,248,248)
    shadow = Color.new(0,0,0,0)
    # Write various bits of text
    textpos = [
       [_INTL("MODE"),Graphics.width/2,8,2,base,shadow],
       [_INTL("OK"),36,250,0,base,shadow,1],
       [_INTL("CANCEL"),Graphics.width-20,250,1,base,shadow,1]
    ]
    title = [_INTL("ORDER:"),_INTL("NAME:"),_INTL("TYPE:"),_INTL("HEIGHT:"),
             _INTL("WEIGHT:"),_INTL("COLOR:"),_INTL("SHAPE:")][mode]
    textpos.push([title,20,(mode==6) ? 40 : 40,0,base,shadow])
    case mode
    when 0   # Order
      xstart = 20; ystart = 66
      xgap = 160; ygap = 18
      halfwidth = 92; cols = 1
      selbuttony = 0; selbuttonheight = 16
    when 1   # Name
      xstart = 20; ystart = 66
      xgap = 32; ygap = 18
      halfwidth = 22; cols = 7
      selbuttony = 0; selbuttonheight = 16
    when 2   # Type
      xstart = 20; ystart = 60
      xgap = 80; ygap = 18
      halfwidth = 62; cols = 3
      selbuttony = 0; selbuttonheight = 16
    when 3,4   # Height, weight
      xstart = 20; ystart = 54
      xgap = 160/(cmds.length+1); ygap = 96
      halfwidth = 60; cols = cmds.length+1
    when 5   # Color
      xstart = 20; ystart = 66
      xgap = 112; ygap = 18
      halfwidth = 62; cols = 2
      selbuttony = 0; selbuttonheight = 16
    when 6   # Shape
      xstart = 12; ystart = 60
      xgap = 52; ygap = 48
      halfwidth = 0; cols = 5
      selbuttony = 16; selbuttonheight = 60
    end
    # Draw selected option(s) text in top bar
    case mode
    when 2   # Type icons
      for i in 0...2
        if !sel[i] || sel[i]<0
          textpos.push(["----",130+80*i,40,0,base,shadow,1])
        else
          typerect = Rect.new(0,@typeCommands[sel[i]]*28,64,28)
          overlay.blt(130+80*i,42,@typebitmap.bitmap,typerect)
        end
      end
    when 3   # Height range
      ht1 = (sel[0]<0) ? 0 : (sel[0]>=@heightCommands.length) ? 999 : @heightCommands[sel[0]]
      ht2 = (sel[1]<0) ? 999 : (sel[1]>=@heightCommands.length) ? 0 : @heightCommands[sel[1]]
      hwoffset = false
      if pbGetCountry==0xF4   # If the user is in the United States
        ht1 = (sel[0]>=@heightCommands.length) ? 99*12 : (ht1/0.254).round
        ht2 = (sel[1]<0) ? 99*12 : (ht2/0.254).round
        txt1 = sprintf("%d'%02d''",ht1/12,ht1%12)
        txt2 = sprintf("%d'%02d''",ht2/12,ht2%12)
        hwoffset = true
      else
        txt1 = sprintf("%.1f",ht1/10.0)
        txt2 = sprintf("%.1f",ht2/10.0)
      end
      #textpos.push([txt1,286,58,2,base,shadow,1])
      #textpos.push([txt2,414,58,2,base,shadow,1])
      #overlay.blt(462,52,@hwbitmap.bitmap,Rect.new(0,(hwoffset) ? 44 : 0,32,44))
    when 4   # Weight range
      wt1 = (sel[0]<0) ? 0 : (sel[0]>=@weightCommands.length) ? 9999 : @weightCommands[sel[0]]
      wt2 = (sel[1]<0) ? 9999 : (sel[1]>=@weightCommands.length) ? 0 : @weightCommands[sel[1]]
      hwoffset = false
      if pbGetCountry==0xF4   # If the user is in the United States
        wt1 = (sel[0]>=@weightCommands.length) ? 99990 : (wt1/0.254).round
        wt2 = (sel[1]<0) ? 99990 : (wt2/0.254).round
        txt1 = sprintf("%.1f",wt1/10.0)
        txt2 = sprintf("%.1f",wt2/10.0)
        hwoffset = true
      else
        txt1 = sprintf("%.1f",wt1/10.0)
        txt2 = sprintf("%.1f",wt2/10.0)
      end
      #textpos.push([txt1,286,58,2,base,shadow,1])
      #textpos.push([txt2,414,58,2,base,shadow,1])
      #overlay.blt(462,52,@hwbitmap.bitmap,Rect.new(32,(hwoffset) ? 44 : 0,32,44))
    when 6   # Shape icon
      if sel[0]>=0
        shaperect = Rect.new(0,@shapeCommands[sel[0]]*60,60,60)
        overlay.blt(332,50,@shapebitmap.bitmap,shaperect)
      end
    else
      if sel[0]<0
        text = ["----","-","----","","","----",""][mode]
        textpos.push([text,300,40,1,base,shadow,1])
      else
        textpos.push([cmds[sel[0]],300,40,1,base,shadow,1])
      end
    end
    # Draw selected option(s) button graphic
    if mode==3 || mode==4 # Height, weight
      xpos1 = xstart+(sel[0]+1)*xgap
      xpos1 = xstart if sel[0]<-1
      xpos2 = xstart+(sel[1]+1)*xgap
      xpos2 = xstart+cols*xgap if sel[1]<0
      xpos2 = xstart if sel[1]>=cols-1
      ypos1 = ystart+64-4+112
      ypos2 = ystart+32-4
      overlay.blt(16,84,@searchsliderbitmap.bitmap,Rect.new(0,192,32,44)) if sel[1]<cols-1
      overlay.blt(272,84,@searchsliderbitmap.bitmap,Rect.new(32,192,32,44)) if sel[1]>=0
      overlay.blt(16,192,@searchsliderbitmap.bitmap,Rect.new(0,192,32,44)) if sel[0]>=0
      overlay.blt(272,192,@searchsliderbitmap.bitmap,Rect.new(32,192,32,44)) if sel[0]<cols-1
      hwrect = Rect.new(0,0,120,96)
      overlay.blt(xpos2,ystart+6,@searchsliderbitmap.bitmap,hwrect)
      hwrect.y = 96
      overlay.blt(xpos1,ystart+ygap+16,@searchsliderbitmap.bitmap,hwrect)
      textpos.push([txt1,xpos1+halfwidth,ypos1,2,base,nil,1])
      textpos.push([txt2,xpos2+halfwidth,ypos2,2,base,nil,1])
    else
      for i in 0...sel.length
	  xadd = mode==6 ? 4 : 0
	  yadd = mode==2 ? 12 : 6
        if sel[i]>=0
          selrect = Rect.new(0,selbuttony,@selbitmap.bitmap.width,selbuttonheight)
          overlay.blt(xstart+(sel[i]%cols)*xgap+xadd,ystart+yadd+(sel[i]/cols).floor*ygap,@selbitmap.bitmap,selrect)
        else
          selrect = Rect.new(0,selbuttony,@selbitmap.bitmap.width,selbuttonheight)
          overlay.blt(xstart+(cols-1)*xgap+xadd,ystart+yadd+(cmds.length/cols).floor*ygap,@selbitmap.bitmap,selrect)
        end
      end
    end
    # Draw options
    case mode
    when 0,1,5 # Order, name, color
      for i in 0...cmds.length
        x = xstart+halfwidth+(i%cols)*xgap
        y = ystart+6+(i/cols).floor*ygap
        textpos.push([cmds[i],x,y,2,base,shadow,1])
      end
      if mode!=0
        textpos.push([(mode==1) ? "-" : "----",
           xstart+halfwidth+(cols-1)*xgap,ystart+6+(cmds.length/cols).floor*ygap,2,base,shadow,1])
      end
    when 2 # Type
      typerect = Rect.new(0,0,64,28)
      for i in 0...cmds.length
        typerect.y = @typeCommands[i]*28
        overlay.blt(xstart+14+(i%cols)*xgap,ystart+6+(i/cols).floor*ygap,@typebitmap.bitmap,typerect)
      end
      textpos.push(["----",
         xstart+halfwidth+(cols-1)*xgap,ystart+6+(cmds.length/cols).floor*ygap,2,base,shadow,1])
    when 6 # Shape
      shaperect = Rect.new(0,0,60,60)
      for i in 0...cmds.length
        shaperect.y = i*60
        overlay.blt(xstart+4+(i%cols)*xgap,ystart+4+(i/cols).floor*ygap,@shapebitmap.bitmap,shaperect)
      end
    end
    # Draw all text
    pbDrawTextPositions(overlay,textpos)
  end

  def setIconBitmap(species)
    gender = ($Trainer.formlastseen[species][0] rescue 0)
    form   = ($Trainer.formlastseen[species][1] rescue 0)
    @sprites["icon"].setSpeciesBitmap(species,(gender==1),form)
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
      stype1 = (params[2]>=0) ? @typeCommands[params[2]] : -1
      stype2 = (params[3]>=0) ? @typeCommands[params[3]] : -1
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

  def pbCloseSearch
    oldsprites = pbFadeOutAndHide(@sprites)
    oldspecies = @sprites["pokedex"].species
    @searchResults = false
    $PokemonGlobal.pokedexMode = MODENUMERICAL
    @searchParams  = [$PokemonGlobal.pokedexMode,-1,-1,-1,-1,-1,-1,-1,-1,-1]
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

  def pbDexEntry(index)
    oldsprites = pbFadeOutAndHide(@sprites)
    region = -1
    if !USE_CURRENT_REGION_DEX
      dexnames = pbDexNames
      if dexnames[pbGetSavePositionIndex].is_a?(Array)
        region = dexnames[pbGetSavePositionIndex][1]
      end
    end
    scene = PokemonPokedexInfo_Scene.new
    screen = PokemonPokedexInfoScreen.new(scene)
    ret = screen.pbStartScreen(@dexlist,index,region)
    if @searchResults
      dexlist = pbSearchDexList(@searchParams)
      @dexlist = dexlist
      @sprites["pokedex"].commands = @dexlist
      ret = @dexlist.length-1 if ret>=@dexlist.length
      ret = 0 if ret<0
    else
      pbRefreshDexList($PokemonGlobal.pokedexIndex[pbGetSavePositionIndex])
      $PokemonGlobal.pokedexIndex[pbGetSavePositionIndex] = ret
    end
    @sprites["pokedex"].index = ret
    @sprites["pokedex"].refresh
    pbRefresh
    pbFadeInAndShow(@sprites,oldsprites)
  end

  def pbDexSearchCommands(mode,selitems,mainindex)
    cmds = [@orderCommands,@nameCommands,@typeCommands,@heightCommands,
            @weightCommands,@colorCommands,@shapeCommands][mode]
    cols = [1,7,3,1,1,2,5][mode]
    ret = nil
    # Set background
    case mode
    when 0;   @sprites["searchbg"].setBitmap("Graphics/Pictures/Pokedex/bg_search")
    when 1;   @sprites["searchbg"].setBitmap("Graphics/Pictures/Pokedex/bg_search")
    when 2
      if PBTypes.regularTypesCount==18
        @sprites["searchbg"].setBitmap("Graphics/Pictures/Pokedex/bg_search")
      else
        @sprites["searchbg"].setBitmap("Graphics/Pictures/Pokedex/bg_search")
      end
    when 3,4; @sprites["searchbg"].setBitmap("Graphics/Pictures/Pokedex/bg_search")
    when 5;   @sprites["searchbg"].setBitmap("Graphics/Pictures/Pokedex/bg_search")
    when 6;   @sprites["searchbg"].setBitmap("Graphics/Pictures/Pokedex/bg_search")
    end
    selindex = selitems.clone
    index     = selindex[0]
    oldindex  = index
    minmax    = 1
    oldminmax = minmax
    if mode==3 || mode==4; index = oldindex = selindex[minmax]; end
    @sprites["searchcursor"].mode   = mode
    @sprites["searchcursor"].cmds   = cmds.length
    @sprites["searchcursor"].minmax = minmax
    @sprites["searchcursor"].index  = index
    nextparam = cmds.length%2
    pbRefreshDexSearchParam(mode,cmds,selindex,index)
    loop do
      pbUpdate
      if index!=oldindex || minmax!=oldminmax
        @sprites["searchcursor"].minmax = minmax
        @sprites["searchcursor"].index  = index
        oldindex  = index
        oldminmax = minmax
      end
      Graphics.update
      Input.update
      if mode==3 || mode==4
        if Input.trigger?(Input::UP)
          if index<-1; minmax = 0; index = selindex[minmax]   # From OK/Cancel
          elsif minmax==0; minmax = 1; index = selindex[minmax]
          end
          if index!=oldindex || minmax!=oldminmax
            pbPlayCursorSE
            pbRefreshDexSearchParam(mode,cmds,selindex,index)
          end
        elsif Input.trigger?(Input::DOWN)
          if minmax==1; minmax = 0; index = selindex[minmax]
          elsif minmax==0; minmax = -1; index = -2
          end
          if index!=oldindex || minmax!=oldminmax
            pbPlayCursorSE
            pbRefreshDexSearchParam(mode,cmds,selindex,index)
          end
        elsif Input.repeat?(Input::LEFT)
          if index==-3; index = -2
          elsif index>=-1
            if minmax==1 && index==-1
              index = cmds.length-1 if selindex[0]<cmds.length-1
            elsif minmax==1 && index==0
              index = cmds.length if selindex[0]<0
            elsif index>-1 && !(minmax==1 && index>=cmds.length)
              index -= 1 if minmax==0 || selindex[0]<=index-1
            end
          end
          if index!=oldindex
            selindex[minmax] = index if minmax>=0
            pbPlayCursorSE
            pbRefreshDexSearchParam(mode,cmds,selindex,index)
          end
        elsif Input.repeat?(Input::RIGHT)
          if index==-2; index = -3
          elsif index>=-1
            if minmax==1 && index>=cmds.length; index = 0
            elsif minmax==1 && index==cmds.length-1; index = -1
            elsif index<cmds.length && !(minmax==1 && index<0)
              index += 1 if minmax==1 || selindex[1]==-1 ||
                            (selindex[1]<cmds.length && selindex[1]>=index+1)
            end
          end
          if index!=oldindex
            selindex[minmax] = index if minmax>=0
            pbPlayCursorSE
            pbRefreshDexSearchParam(mode,cmds,selindex,index)
          end
        end
      else
        if Input.trigger?(Input::UP)
		if index==-1 && mode==5; index = cmds.length-1
          elsif index==-1; index = cmds.length-1-(cmds.length-1)%cols-1   # From blank
          elsif index==-2; index = ((cmds.length-1)/cols).floor*cols   # From OK
          elsif index==-3 && mode==0; index = cmds.length-1   # From Cancel
          elsif index==-3; index = -1   # From Cancel
          elsif index>=cols; index -= cols
          end
          pbPlayCursorSE if index!=oldindex
        elsif Input.trigger?(Input::DOWN)
          if index==-1; index = -3   # From blank
		  elsif index==cmds.length-1 && mode==5; index=-1
          elsif index>=0
            if index+cols<cmds.length; index += cols
            elsif (index/cols).floor<((cmds.length-1)/cols).floor
              index = (index%cols<cols/2.0) ? cmds.length-1 : -1
            else
              index = (index%cols<cols/2.0) ? -2 : -3
            end
          end
          pbPlayCursorSE if index!=oldindex
        elsif Input.trigger?(Input::LEFT)
          if index==-3; index = -2
          elsif index==-1; index = cmds.length-1
          elsif index>0 && index%cols!=0; index -= 1
          end
          pbPlayCursorSE if index!=oldindex
        elsif Input.trigger?(Input::RIGHT)
          if index==-2; index = -3
          elsif index==cmds.length-1 && mode!=0; index = -1
          elsif index>=0 && index%cols!=cols-1; index += 1
          end
          pbPlayCursorSE if index!=oldindex
        end
      end
      if Input.trigger?(Input::ENTER)
        index = -2
        pbPlayCursorSE if index!=oldindex
      elsif Input.trigger?(Input::B)
        pbPlayCloseMenuSE
        ret = nil
        break
      elsif Input.trigger?(Input::C)
        if index==-2      # OK
          pbPlayDecisionSE
          ret = selindex
          break
        elsif index==-3   # Cancel
          pbPlayCloseMenuSE
          ret = nil
          break
        elsif selindex!=index && mode!=3 && mode!=4
          if mode==2
            if index==-1
              nextparam = (selindex[1]>=0) ? 1 : 0
            elsif index>=0
              nextparam = (selindex[0]<0) ? 0 : (selindex[1]<0) ? 1 : nextparam
            end
            if index<0 || selindex[(nextparam+1)%2]!=index
              pbPlayDecisionSE
              selindex[nextparam] = index
              nextparam = (nextparam+1)%2
            end
          else
            pbPlayDecisionSE
            selindex[0] = index
          end
          pbRefreshDexSearchParam(mode,cmds,selindex,index)
        end
      end
    end
    Input.update
    # Set background image
    @sprites["searchbg"].setBitmap("Graphics/Pictures/Pokedex/bg_search")
    @sprites["searchcursor"].mode = -1
    @sprites["searchcursor"].index = mainindex
    return ret
  end

  def pbDexSearch
    oldsprites = pbFadeOutAndHide(@sprites)
    params = @searchParams.clone
    @orderCommands = []
    @orderCommands[MODENUMERICAL] = _INTL("NUMERICAL")
    @orderCommands[MODEATOZ]      = _INTL("A TO Z")
    @orderCommands[MODEHEAVIEST]  = _INTL("HEAVIEST")
    @orderCommands[MODELIGHTEST]  = _INTL("LIGHTEST")
    @orderCommands[MODETALLEST]   = _INTL("TALLEST")
    @orderCommands[MODESMALLEST]  = _INTL("SMALLEST")
    @nameCommands = [_INTL("A"),_INTL("B"),_INTL("C"),_INTL("D"),_INTL("E"),
                    _INTL("F"),_INTL("G"),_INTL("H"),_INTL("I"),_INTL("J"),
                    _INTL("K"),_INTL("L"),_INTL("M"),_INTL("N"),_INTL("O"),
                    _INTL("P"),_INTL("Q"),_INTL("R"),_INTL("S"),_INTL("T"),
                    _INTL("U"),_INTL("V"),_INTL("W"),_INTL("X"),_INTL("Y"),
                    _INTL("Z")]
    @typeCommands = []
    for i in 0..PBTypes.maxValue
      @typeCommands.push(i) if !PBTypes.isPseudoType?(i)
    end
    @heightCommands = [1,2,3,4,5,6,7,8,9,10,
                       11,12,13,14,15,16,17,18,19,20,
                       21,22,23,24,25,30,35,40,45,50,
                       55,60,65,70,80,90,100]
    @weightCommands = [5,10,15,20,25,30,35,40,45,50,
                       55,60,70,80,90,100,110,120,140,160,
                       180,200,250,300,350,400,500,600,700,800,
                       900,1000,1250,1500,2000,3000,5000]
    @colorCommands = []
    for i in 0..PBColors.maxValue
      j = PBColors.getName(i)
      @colorCommands.push(j) if j
    end
    @shapeCommands = []
    for i in 0...14; @shapeCommands.push(i); end
    @sprites["searchbg"].visible     = true
    @sprites["overlay"].visible      = true
    @sprites["searchcursor"].visible = true
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
        if index>=7; index = 6
        #elsif index==5; index = 0
        elsif index>0; index -= 1
        end
        pbPlayCursorSE if index!=oldindex
      elsif Input.trigger?(Input::DOWN)
        if index==6; index = 8
        elsif index<9; index += 1
        end
        pbPlayCursorSE if index!=oldindex
      elsif Input.trigger?(Input::LEFT)
        if index==6; index = 7
        #elsif index==6; index = 3
        elsif index>7; index -= 1
        end
        pbPlayCursorSE if index!=oldindex
      elsif Input.trigger?(Input::RIGHT)
        if index==6; index = 9
        #elsif index>=2 && index<=4; index = 6
        elsif index==6 && index<9; index +=1 #|| index==8; index += 1
        end
        pbPlayCursorSE if index!=oldindex
      elsif Input.trigger?(Input::ENTER)
        index = 8
        pbPlayCursorSE if index!=oldindex
      elsif Input.trigger?(Input::B)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE if index!=9
        case index
        when 0   # Choose sort order
          newparam = pbDexSearchCommands(0,[params[0]],index)
          params[0] = newparam[0] if newparam!=nil
          pbRefreshDexSearch(params,index)
        when 1   # Filter by name
          newparam = pbDexSearchCommands(1,[params[1]],index)
          params[1] = newparam[0] if newparam!=nil
          pbRefreshDexSearch(params,index)
        when 2   # Filter by type
          newparam = pbDexSearchCommands(2,[params[2],params[3]],index)
          if newparam!=nil
            params[2] = newparam[0]
            params[3] = newparam[1]
          end
          pbRefreshDexSearch(params,index)
        when 3   # Filter by height range
          newparam = pbDexSearchCommands(3,[params[4],params[5]],index)
          if newparam!=nil
            params[4] = newparam[0]
            params[5] = newparam[1]
          end
          pbRefreshDexSearch(params,index)
        when 4   # Filter by weight range
          newparam = pbDexSearchCommands(4,[params[6],params[7]],index)
          if newparam!=nil
            params[6] = newparam[0]
            params[7] = newparam[1]
          end
          pbRefreshDexSearch(params,index)
        when 5   # Filter by color filter
          newparam = pbDexSearchCommands(5,[params[8]],index)
          params[8] = newparam[0] if newparam!=nil
          pbRefreshDexSearch(params,index)
        when 6   # Filter by form
          newparam = pbDexSearchCommands(6,[params[9]],index)
          params[9] = newparam[0] if newparam!=nil
          pbRefreshDexSearch(params,index)
        when 7   # Clear filters
          for i in 0...10
            params[i] = (i==0) ? MODENUMERICAL : -1
          end
          pbRefreshDexSearch(params,index)
        when 8   # Start search (filter)
          dexlist = pbSearchDexList(params)
          if dexlist.length==0
            pbMessage(_INTL("No matching POKéMON were found."))
          else
            @dexlist = dexlist
            @sprites["pokedex"].commands = @dexlist
            @sprites["pokedex"].index    = 0
            @sprites["pokedex"].refresh
            @searchResults = true
            @searchParams = params
            break
          end
        when 9   # Cancel
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

  def pbPokedex
    pbActivateWindow(@sprites,"pokedex") {
      loop do
        Graphics.update
        Input.update
        oldindex = @sprites["pokedex"].index
        pbUpdate
        if oldindex!=@sprites["pokedex"].index
          $PokemonGlobal.pokedexIndex[pbGetSavePositionIndex] = @sprites["pokedex"].index if !@searchResults
          pbRefresh
        end
        if Input.trigger?(Input::ENTER)
          pbPlayDecisionSE
          @sprites["pokedex"].active = false
          pbDexSearch
          @sprites["pokedex"].active = true
        elsif Input.trigger?(Input::B)
          if @searchResults
            pbPlayCancelSE
            pbCloseSearch
          else
            pbPlayCloseMenuSE
            break
          end
        elsif Input.trigger?(Input::C)
          if $Trainer.seen[@sprites["pokedex"].species]
            pbPlayDecisionSE
            pbDexEntry(@sprites["pokedex"].index)
          end
        end
      end
    }
  end
end



class PokemonPokedexScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbPokedex
    @scene.pbEndScene
  end
end
