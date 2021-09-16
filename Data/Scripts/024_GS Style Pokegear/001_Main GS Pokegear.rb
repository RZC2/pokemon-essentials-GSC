################################################################################
# GS style Pokegear by Caruban
################################################################################
# How To :
# - USE
#   call script pbGSPokegear
# 
# - ADD CHANNEL
#   go to pbUpdateRadio, add the radio frequency and the text
#   the easiest channel to duplicate is the Lucky Number Show
#
# PS.
# - Lucky Number Show need a variable to save the number and a script to
#   only actived every week)
# - Pokedex Show using random number species on PBSpecies
# - Prof Oak Show using PBS encounter.txt to tell location a species is
################################################################################
# Setting
#-------------------------------------------------------------------------------
# Maximum "------" on contact list
MAX_DASH_CONTACT = 10

# BGM played on Radio
OAK_BGM           = "Radio - Professor Oak's Talk"
POKEDEX_BGM       = "Radio - Pokedex Show"
MARCH_BGM         = "Radio - Pokemon March"
LULLABY_BGM       = "Radio - Pokemon Lullaby"
LOTTERY_BGM       = "Radio - Lucky Channel, Game Corner"
PLACESNPEOPLE_BGM = "Radio - Places and People"
TEAMROCKET_BGM    = "Radio - Tower Occupied"

# Rocket Take Over Radio Station
# When ON every Channel will change into Team Rocket
# Broadcasting
ROCKET_TAKEOVER = 59

# Random People from Aroma Lady (6) to Rocket Grunt (57)
# in Places & People Channel
TRAINERTYPE_IN_RADIO = Array (6..57)

#===============================================================================
# Game_Temp to keep the last Radio Channel
#===============================================================================
class Game_Temp
  attr_accessor :lastRadioCh  
end
#===============================================================================
# Phone window related
#===============================================================================
module UpDownArrowMixin
  def hidArrow
    @uparrow.visible = false
    @downarrow.visible = false
  end
end

class Window_AdvancedTextPokemon < SpriteWindow_Base
  def allocPause
    return if @pausesprite
    windowpause = ""
    echo MessageConfig.pbGetSpeechFrame
    windowpause = "_pokegear" if MessageConfig.pbGetSpeechFrame == "Graphics/Windowskins/pokegear.png"
    @pausesprite = AnimatedSprite.create("Graphics/Pictures/pause"+windowpause,2,12)
    @pausesprite.z       = 100000
    @pausesprite.visible = false
  end
end

class Window_DrawableCommand < SpriteWindow_SelectableEx
  def refresh
    @item_max = itemCount()
    dwidth  = self.width-self.borderX
    dheight = self.height-self.borderY
    self.contents = pbDoEnsureBitmap(self.contents,dwidth,dheight)
    self.contents.clear
    for i in 0...@item_max
      next if i<self.top_item || i>self.top_item+self.page_item_max
      drawItem(i,@item_max,itemRect(i))
    end
  end

  def update
    oldindex = self.index
    super
    refresh if self.index!=oldindex
    hidArrow # hide UpDown Arrow from list
  end
end

class Window_CommandPokemon2 < Window_DrawableCommand
  attr_reader :commands

  def initialize(commands,width=nil)
    @starting=true
    @commands=[]
    dims=[]
    super(0,0,32,32)
    getAutoDims(commands,dims,width)
    self.width=dims[0]
    self.height=dims[1]
    @commands=commands
    self.active=true
    colors=getDefaultTextColors(self.windowskin)
    self.baseColor=colors[0]
    self.shadowColor=colors[1]
    refresh
    @starting=false
  end

  def self.newWithSize(commands,x,y,width,height,viewport=nil)
    ret=self.new(commands,width)
    ret.x=x
    ret.y=y
    ret.width=width
    ret.height=height
    ret.viewport=viewport
    return ret
  end

  def self.newEmpty(x,y,width,height,viewport=nil)
    ret=self.new([],width)
    ret.x=x
    ret.y=y
    ret.width=width
    ret.height=height
    ret.viewport=viewport
    return ret
  end

  def index=(value)
    super
    refresh if !@starting
  end

  def commands=(value)
    @commands=value
    @item_max=commands.length
    self.update_cursor_rect
    self.refresh
  end

  def width=(value)
    super
    if !@starting
      self.index=self.index
      self.update_cursor_rect
    end
  end

  def height=(value)
    super
    if !@starting
      self.index=self.index
      self.update_cursor_rect
    end
  end

  def resizeToFit(commands,width=nil)
    dims=[]
    getAutoDims(commands,dims,width)
    self.width=dims[0]
    self.height=dims[1]
  end

  def itemCount
    return @commands ? @commands.length : 0
  end

  def drawItem(index,_count,rect)
    pbSetSystemFont(self.contents) if @starting
    rect=drawCursor(index,rect)
    pbDrawShadowText(self.contents,rect.x,rect.y,rect.width,rect.height,
       @commands[index][0],self.baseColor,self.shadowColor)
    pbDrawShadowText(self.contents,rect.x+48,rect.y+16,rect.width,rect.height,
       @commands[index][1],self.baseColor,self.shadowColor)
  end
end

class Window_PhoneList2 < Window_CommandPokemon2
  def drawCursor(index,rect)
    selarrow = AnimatedBitmap.new("Graphics/Pictures/Pokegear/phoneSel")
    if self.index==index
      pbCopyBitmap(self.contents,selarrow.bitmap,rect.x,rect.y)
    end
    return Rect.new(rect.x+28,rect.y+8,rect.width-16,rect.height)
  end

  def drawItem(index,count,rect)
    return if index>=self.top_row+self.page_item_max
    super
    drawCursor(index-1,itemRect(index-1))
  end
end

#===============================================================================
# Pokegear
#===============================================================================
def pbGSPokegear
  pbFadeOutIn{
    scene = PokegearGS_Scene.new
    screen = PokegearGS_Screen.new(scene)
    ret = screen.pbStartScreen
  }
end

class PokegearGS_Screen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    ret = @scene.pbScene
    @scene.pbEndScene
    return ret
  end
end

class PokegearGS_Scene
  SQUAREWIDTH  = 16
  SQUAREHEIGHT = 16
  
  def pbStartScene
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @sprites={}
    @page=1
    @index = 0
    @index_radio = ($game_temp.lastRadioCh)? $game_temp.lastRadioCh : 0.5
    @frame = 0
    @anim = 0
    @map_id = $game_map.map_id
    @map_idx = 0
    @frame_radio = 0
    @radio = []
    @intro = true
    @oldline = ''
    @blankContact = 0
    
    @baseColor   = Color.new(0,0,0)
    @shadowColor = Color.new(255,255,255,0)
    
    # Sprites
    @sprites["background"] = IconSprite.new(0,0,@viewport)
    @sprites["background"].setBitmap("Graphics/Pictures/Pokegear/bg_1")
    
    @sprites["helpwindow"]=Window_UnformattedTextPokemon.new("")
    @helpwindow = @sprites["helpwindow"]
    @helpwindow.viewport = @viewport
    pbBottomLeftLines(@sprites["helpwindow"],2)
    @helpwindow.width = Graphics.width
    @helpwindow.text = _INTL("Press any button to exit.")
    @helpwindow.baseColor = @baseColor
    @helpwindow.shadowColor = @shadowColor
    @helpwindow.windowskin = nil
    @helpwindow.visible = true

    @sprites["pointer"]=IconSprite.new(144+4*((@index_radio/0.5)-1),16,@viewport)
    poinBitmap = Bitmap.new(2,48)
    poinRect = Rect.new(0,0,poinBitmap.width,poinBitmap.height)
    poinBitmap.fill_rect(poinRect,Color.new(248,152,80))
    @sprites["pointer"].bitmap = poinBitmap
    @sprites["pointer"].visible = false
    
    # Map
    @mapdata = pbLoadTownMapData
    @region = -1;@wallmap=true
    playerpos = (!$game_map) ? nil : pbGetMetadata($game_map.map_id,MetadataMapPosition)
    if !playerpos
      @mapindex = 0
      @map     = @mapdata[0]
      @mapX    = LEFT
      @mapY    = TOP
    elsif @region>=0 && @region!=playerpos[0] && @mapdata[@region]
      @mapindex = @region
      @map     = @mapdata[@region]
      @mapX    = LEFT
      @mapY    = TOP
    else
      @mapindex = playerpos[0]
      @map     = @mapdata[playerpos[0]]
      @mapX    = playerpos[1]
      @mapY    = playerpos[2]
      mapsize = (!$game_map) ? nil : pbGetMetadata($game_map.map_id,MetadataMapSize)
      if mapsize && mapsize[0] && mapsize[0]>0
        sqwidth  = mapsize[0]
        sqheight = (mapsize[1].length*1.0/mapsize[0]).ceil
        if sqwidth>1
          @mapX += ($game_player.x*sqwidth/$game_map.width).floor
        end
        if sqheight>1
          @mapY += ($game_player.y*sqheight/$game_map.height).floor
        end
      end
    end
    @sprites["map"] = IconSprite.new(0,0,@viewport)
    @sprites["map"].setBitmap("Graphics/Pictures/#{@map[1]}")
    @sprites["map"].x += (Graphics.width-@sprites["map"].bitmap.width)/2
    @sprites["map"].y += (Graphics.height-@sprites["map"].bitmap.height)/2
    @sprites["map"].visible = false
    @sprites["mapbar"] = IconSprite.new(0,0,@viewport)
    @sprites["mapbar"].setBitmap("Graphics/Pictures/Pokegear/bg_2_bar")
    @sprites["mapbar"].visible = false
    meta = pbGetMetadata(0,MetadataPlayerA+$PokemonGlobal.playerID)
    if playerpos && @mapindex==playerpos[0] && meta
      filename = pbGetPlayerCharset(meta,1,nil,true)
      @sprites["player"] = TrainerWalkingCharSprite.new(filename,@viewport)
      charwidth  = @sprites["player"].bitmap.width
      charheight = @sprites["player"].bitmap.height
      @sprites["player"].x = -SQUAREWIDTH/2+(@mapX*SQUAREWIDTH)+(Graphics.width-@sprites["map"].bitmap.width)/2
      @sprites["player"].y = -SQUAREHEIGHT/2+(@mapY*SQUAREHEIGHT)+(Graphics.height-@sprites["map"].bitmap.height)/2
      @sprites["player"].src_rect = Rect.new(0,0,charwidth/4,charheight/4)
      @sprites["player"].visible = false
    end
    @sprites["mapcursor"] = IconSprite.new(0,0,@viewport)
    @sprites["mapcursor"].setBitmap("Graphics/Pictures/Pokegear/mapcursor")
    @sprites["mapcursor"].x = -SQUAREWIDTH/2+(@mapX*SQUAREWIDTH)+(Graphics.width-@sprites["map"].bitmap.width)/2
    @sprites["mapcursor"].y = -SQUAREHEIGHT/2+(@mapY*SQUAREHEIGHT)+(Graphics.height-@sprites["map"].bitmap.height)/2
    @sprites["mapcursor"].visible = false
    townmapdata = @mapdata[@region][2]
    i=0
    for loc in townmapdata
      if loc[0] == @mapX && loc[1] == @mapY
        @map_idx = i
        break
      end
      i+=1
    end
    
    # Phone
    @commands = []
    @trainers = []
    if $PokemonGlobal.phoneNumbers
      for num in $PokemonGlobal.phoneNumbers
        if num[0]   # if visible
          if num.length==8   # if trainer
            @trainers.push([num[1],num[2],num[6],(num[4]>=2)])
          else               # if NPC
            @trainers.push([num[1],num[2],num[3]])
          end
        end
      end
    end
    @sprites["list"] = Window_PhoneList2.newEmpty(-12,29,288,176,@viewport)
    @sprites["list"].windowskin  = nil
    @sprites["list"].active=false
    @sprites["list"].visible = false
    @sprites["list"].shadowColor = Color.new(255,255,255,0)
    for trainer in @trainers
      if trainer.length==4
        name = _INTL("{1}:",pbGetMessageFromHash(MessageTypes::TrainerNames,trainer[1]))
        type = PBTrainers.getName(trainer[0])
        @commands.push([name.upcase,type.upcase]) # trainer's display name
      else
        @commands.push([_INTL("{1}:",trainer[1].upcase),""]) # NPC's display name
      end
    end
    if @commands.length<MAX_DASH_CONTACT
      @blankContact = MAX_DASH_CONTACT-@commands.length
      @blankContact.times do
        @commands.push(["----------",""])
      end
    end
    @sprites["list"].commands = @commands
    for i in 0...@sprites["list"].page_item_max
      @sprites["rematch[#{i}]"] = IconSprite.new(468,62+i*32,@viewport)
      j = i+@sprites["list"].top_item
      next if j>=@commands.length
      next if j>@trainers.length-1
      trainer = @trainers[j]
      if trainer.length==4
        if trainer[3]
          @sprites["rematch[#{i}]"].setBitmap("Graphics/Pictures/Pokegear/phoneRematch")
        end
      end
    end
    
    # Pages
    @pages = [1]
    @pages.push(2)
    @pages.push(3) if $PokemonGlobal.phoneNumbers && $PokemonGlobal.phoneNumbers.length>0
    @pages.push(4) 
    for i in @pages
      i-1
      @sprites["icon#{i}"] = IconSprite.new(0+32*(i-1),0,@viewport)
	  if $Trainer.male?
        @sprites["icon#{i}"].setBitmap("Graphics/Pictures/Pokegear/icons")
	  else
	    @sprites["icon#{i}"].setBitmap("Graphics/Pictures/Pokegear/icons_f")
	  end
      @sprites["icon#{i}"].src_rect = Rect.new(0+32*(i-1),0,32,32)
    end
    
    # Cursor
    @sprites["cursor"] = IconSprite.new(4,26,@viewport)
    @sprites["cursor"].setBitmap("Graphics/Pictures/Pokegear/cursor")
    
    # Text
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport) 
    pbUpdateText
    
    pbFadeInAndShow(@sprites) { pbUpdate }
  end
  
  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
  
  def pbUpdate
    # Auto update radio
    if @page==4
      @frame += 1
      if @frame == 80 && @radio[1] #update text
        @frame = 0
        text = @radio[2]
        text = @radio[1] if @intro && @radio[1] # for intro
        oldline = @oldline#text[@frame_radio]
        @frame_radio += 1
        if !@intro && text.length == 1
          @helpwindow.text = _INTL("{1}",text[0])
        elsif @frame_radio > text.length-1 # loop
          if @intro
            @intro = false
            text = @radio[2]
          else
            @radio = pbUpdateRadio
            text = @radio[2]
          end
          @frame_radio = 0
          @helpwindow.text = _INTL("{1}\n{2}",oldline,text[@frame_radio])
        else # run
          @helpwindow.text = _INTL("{1}\n{2}",oldline,text[@frame_radio])
        end
        @oldline = text[@frame_radio]
      end
    end
    # Sprite Hash Update
    pbUpdateSpriteHash(@sprites)
  end
  
  # Setting Radio Channel
  def pbUpdateRadio
    ret = []; array=[]
    index = @index_radio
    $PokemonMap.whiteFluteUsed = false if $PokemonMap
    $PokemonMap.blackFluteUsed = false if $PokemonMap
    case index
    when 4.5
      time = pbGetTimeNow
      name = (time.hour>= 4 && time.hour<=10) ? "Pokédex Show" : "OAK's Pokemon Talk"
      if time.hour>= 4 && time.hour<=10 # Pokédex Show
        array = pbGetPokedexShow(@helpwindow)
      else
        array = pbGetOakTalkShow(@helpwindow) # Prof. Oak's Talk Show
      end
    when 7.5 # Pokémon Music
      name = "Pokémon Music"
      array = pbGetPokemonMusicCh(@helpwindow)
    when 8.5
      name = "Lucky Channel"
      array = pbGetLotteryCh(@helpwindow)
    when 13.5
      name = "Unown Transmission" if $game_map.map_id == 41
	  pbBGMPlay("Radio - Unown Transmission", 100, 100)
    when 20.5
      name = "Evolution Transmission" if $game_map.map_id == 42
    when 16.5
      name = "Places & People"
      array = pbGetPlacesnPeopleCh(@helpwindow)
    #when 18.5
    #  name = "Let's All Sing"
    when 20
      name = "PokéFlute"
      pbBGMPlay("Radio - poke flute", 100, 100)
    else
      name = ""
    end
    if $game_switches[ROCKET_TAKEOVER] && (array.length>0 || name != "")
      array = pbGetRocketTakeOverCh(@helpwindow)
    end
    ret.push(name)
    for lines in array
      ret.push(lines)
    end
    return ret
  end
  
  def pbChangeMap(sum)
    map     = @mapdata[@region]
    townmapdata = map[2]
    @map_idx += sum
    @map_idx = 0 if @map_idx >= townmapdata.length
    @map_idx = townmapdata.length-1 if @map_idx <0
    @mapX = townmapdata[@map_idx][0]
    @mapY = townmapdata[@map_idx][1]
    @sprites["mapcursor"].x = -SQUAREWIDTH/2+(@mapX*SQUAREWIDTH)+(Graphics.width-@sprites["map"].bitmap.width)/2
    @sprites["mapcursor"].y = -SQUAREHEIGHT/2+(@mapY*SQUAREHEIGHT)+(Graphics.height-@sprites["map"].bitmap.height)/2
    pbUpdateText
  end
  
  def pbChangePage(oldpage)
    if @page==4
      $game_system.bgm_memorize
      pbBGMStop
    elsif oldpage == 4
      $game_system.bgm_restore
    end
    page = @page
    @index = 0
    @sprites["cursor"].x = 4 + 32*(@page-1)
    @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokegear/bg_{1}",page))
	if $Trainer.female? && @page==4
	  @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokegear/bgf_4"))
	end
    @sprites["list"].visible = (page==3)
    @sprites["list"].active = (page==3)
    @sprites["pointer"].visible = (page==4)
    @helpwindow.visible = (page != 2)
    @sprites["map"].visible = (page == 2)
    @sprites["mapbar"].visible = (page==2)
    @sprites["player"].visible = (page == 2)
    @sprites["mapcursor"].visible = (page == 2)
    
    pbUpdatePhone if page==3 # Update for phone
    pbUpdateText
  end
  
  def pbUpdateText
    if @sprites.include?("overlay")
      @sprites["overlay"].bitmap.clear
    end
    textPositions=[]
    @helpwindow.text = ""
    case @page
    when 1 # Jam / Clock
      time = pbGetTimeNow
      wday = time.wday
      day = [
       _INTL("Sunday"),
       _INTL("Monday"),
       _INTL("Tuesday"),
       _INTL("Wednesday"),
       _INTL("Thursday"),
       _INTL("Friday"),
       _INTL("Saturday")][wday]
      hour = (time.hour>12)? time.hour-12 : time.hour
      periode = (time.hour>12)? "PM" : "AM"
      textPositions=[
          [_INTL("{1}",day.upcase),168,88,2,@baseColor,@shadowColor],
          [sprintf("%02d : %02d",hour,time.min),176,120,1,@baseColor,@shadowColor],
          [_INTL("{1}",periode),224,120,1,@baseColor,@shadowColor],
        ]
      @helpwindow.text = _INTL("Press any button to exit.")
    when 2 # Map / Peta
      @maplocation = pbGetMapLocation(@mapX,@mapY)
      words = pbTextSpliter(@helpwindow,@maplocation,10)
      i=0
      for text in words
        textPositions.push([text.upcase,144,-8+16*i,0,@baseColor,@shadowColor])
        i+=1
      end
    when 3 # Phone
      @helpwindow.text = _INTL("Whom do you want to call?")
    when 4 # Radio
      pbSEPlay("RadioTuning") # Suara Tuning
      @frame = 0
      @frame_radio = 0
      @oldline = ''
      @intro = true
      @radio = pbUpdateRadio
      @helpwindow.text = @radio[1]? _INTL("{1}",@radio[1][0]) : ""
      @oldline = @helpwindow.text
      textPositions=[
        [_INTL("{1}",@radio[0]),32,136,0,@baseColor,@shadowColor],
      ]
    else
      textPositions=[]
    end
    pbSetSystemFont(@sprites["overlay"].bitmap)
    pbDrawTextPositions(@sprites["overlay"].bitmap,textPositions)
  end
  
  def pbUpdatePhone
    if @sprites["list"].index != @index
      trainer = @trainers[@sprites["list"].index]
      for i in 0...@sprites["list"].page_item_max
        @sprites["rematch[#{i}]"].clearBitmaps
        j = i+@sprites["list"].top_item
        next if j>=@commands.length
        trainer = @trainers[j]
        if trainer.length==4
          if trainer[3]
            @sprites["rematch[#{i}]"].setBitmap("Graphics/Pictures/phoneRematch")
          end
        end
      end
      @index = @sprites["list"].index
    end
  end
  
  def pbGetMapLocation(x,y)
    return "" if !@map[2]
    for loc in @map[2]
      if loc[0]==x && loc[1]==y
        if !loc[7] || (!@wallmap && $game_switches[loc[7]])
          maploc = pbGetMessageFromHash(MessageTypes::PlaceNames,loc[2])
          return @editor ? loc[2] : maploc
        else
          return ""
        end
      end
    end
    return ""
  end
  
  def pbScene
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::C)
        if @page==3 # phone
          pbPlayDecisionSE
          index = @sprites["list"].index
          if index>=0 && index < @commands.length-@blankContact
            oldskin = MessageConfig.pbGetSpeechFrame
            MessageConfig.pbSetSpeechFrame("Graphics/Windowskins/pokegear")
            pbCallTrainer(@trainers[index][0],@trainers[index][1])
            MessageConfig.pbSetSpeechFrame(oldskin)
          end
        end
      elsif Input.trigger?(Input::B)
        if $game_system.getPlayingBGM == nil
          $game_map.autoplay
        end
        $game_temp.lastRadioCh = @index_radio
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::UP)
        if @page==4 && @index_radio<20.5
          @index_radio+=0.5 # Naik Freq
          @sprites["pointer"].x += 4
          pbBGMStop
          pbUpdateText
        elsif @page==2
          pbChangeMap(1)
        end
      elsif Input.trigger?(Input::DOWN)
        if @page==4 && @index_radio>0.5
          @index_radio-=0.5 # Turun Freq
          @sprites["pointer"].x -= 4
          pbBGMStop
          pbUpdateText
        elsif @page==2
          pbChangeMap(-1)
        end
      elsif Input.trigger?(Input::LEFT)
        idx = @pages.index(@page)
        if idx>0
          @page = @pages[idx-1]
          pbChangePage(@pages[idx])
        end
      elsif Input.trigger?(Input::RIGHT)
        idx = @pages.index(@page)
        if idx < @pages.length-1
          @page = @pages[idx+1]
          pbChangePage(@pages[idx])
        end
      end
    end
    #return @index
  end  
end
