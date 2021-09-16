def pbFindEncounter(encounter,species)
  return false if !encounter
  for i in 0...encounter.length
    next if !encounter[i]
    for j in 0...encounter[i].length
      return true if encounter[i][j][0]==species
    end
  end
  return false
end



class PokemonPokedexInfo_Scene
  def pbStartScene(dexlist,index,region)
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @dexlist = dexlist
    @index   = index
    @region  = region
	  @entrypage = 0
    @page = 1
    @sprites = {}
    @sprites["background"] = IconSprite.new(0,0,@viewport)
    @sprites["infosprite"] = PokemonSprite.new(@viewport)
    @sprites["infosprite"].setOffset(PictureOrigin::Center)
    @sprites["infosprite"].x = 62
    @sprites["infosprite"].y = 72
    @mapdata = pbLoadTownMapData
    mappos = ($game_map) ? pbGetMetadata($game_map.map_id,MetadataMapPosition) : nil
    if @region<0                                   # Use player's current region
      @region = (mappos) ? mappos[0] : 0                      # Region 0 default
    end
    @sprites["areamap"] = IconSprite.new(0,0,@viewport)
    @sprites["areamap"].setBitmap("Graphics/Pictures/#{@mapdata[@region][1]}")
    @sprites["areamap"].x += (Graphics.width-@sprites["areamap"].bitmap.width)/2
    @sprites["areamap"].y += (Graphics.height-@sprites["areamap"].bitmap.height)/2
    for hidden in REGION_MAP_EXTRAS
      if hidden[0]==@region && hidden[1]>0 && $game_switches[hidden[1]]
        pbDrawImagePositions(@sprites["areamap"].bitmap,[
           ["Graphics/Pictures/#{hidden[4]}",
              hidden[2]*PokemonRegionMap_Scene::SQUAREWIDTH,
              hidden[3]*PokemonRegionMap_Scene::SQUAREHEIGHT]
        ])
      end
    end
    #@sprites["nestlocation"] = IconSprite.new(0,0,@viewport)
    @sprites["nestlocation"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    #@sprites["nestlocation"].setBitmap("Graphics/Pictures/Pokedex/icon_nest")
    @sprites["formfront"] = PokemonSprite.new(@viewport)
    @sprites["formfront"].setOffset(PictureOrigin::Center)
    @sprites["formfront"].x = 95
    @sprites["formfront"].y = 90
    @sprites["formback"] = PokemonSprite.new(@viewport)
    @sprites["formback"].setOffset(PictureOrigin::Bottom)
    @sprites["formback"].x = 230   # y is set below as it depends on metrics
    @sprites["uparrow"] = AnimatedSprite.new("Graphics/Pictures/uparrow",8,28,40,2,@viewport)
    @sprites["uparrow"].x = 242
    @sprites["uparrow"].y = 268
    @sprites["uparrow"].play
    @sprites["uparrow"].visible = false
    @sprites["downarrow"] = AnimatedSprite.new("Graphics/Pictures/downarrow",8,28,40,2,@viewport)
    @sprites["downarrow"].x = 242
    @sprites["downarrow"].y = 348
    @sprites["downarrow"].play
    @sprites["downarrow"].visible = false
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    pbUpdateDummyPokemon
    @available = pbGetAvailableForms
    drawPage(@page)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbStartSceneBrief(species)  # For standalone access, shows first page only
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
#    @region = 0
    dexnum = species
    dexnumshift = false
    if $PokemonGlobal.pokedexUnlocked[$PokemonGlobal.pokedexUnlocked.length-1]
      dexnumshift = true if DEXES_WITH_OFFSETS.include?(-1)
    else
      dexnum = 0
      for i in 0...$PokemonGlobal.pokedexUnlocked.length-1
        next if !$PokemonGlobal.pokedexUnlocked[i]
        num = pbGetRegionalNumber(i,species)
        next if num<=0
        dexnum = num
        dexnumshift = true if DEXES_WITH_OFFSETS.include?(i)
#        @region = pbDexNames[i][1] if pbDexNames[i].is_a?(Array)
        break
      end
    end
    @dexlist = [[species,"",0,0,dexnum,dexnumshift]]
    @index   = 0
    @page = 1
	@entrypage = 0
    @entrypagemax = 0
    @brief = true
	@sprites = {}
    @sprites["background"] = IconSprite.new(0,0,@viewport)
    @sprites["infosprite"] = PokemonSprite.new(@viewport)
    @sprites["infosprite"].setOffset(PictureOrigin::Center)
    @sprites["infosprite"].x = 62
    @sprites["infosprite"].y = 72
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    pbUpdateDummyPokemon
    drawPage(@page)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
	@selbitmap.dispose
    @viewport.dispose
  end

  def pbUpdate
    if @page==2
      intensity = (Graphics.frame_count%25)*12#(Graphics.frame_count%40)*12
      intensity = intensity>150 ? 255 : 0#intensity>240 ? 255 : 0
      @sprites["nestlocation"].opacity = intensity
    end
    pbUpdateSpriteHash(@sprites)
  end

  def pbUpdateDummyPokemon
    @species = @dexlist[@index][0]
    @gender  = ($Trainer.formlastseen[@species][0] rescue 0)
    @form    = ($Trainer.formlastseen[@species][1] rescue 0)
    @sprites["infosprite"].setSpeciesBitmap(@species,(@gender==1),@form)
    if @sprites["formfront"]
      @sprites["formfront"].setSpeciesBitmap(@species,(@gender==1),@form)
    end
    if @sprites["formback"]
      @sprites["formback"].setSpeciesBitmap(@species,(@gender==1),@form,false,false,true)
      @sprites["formback"].y = 160
      fSpecies = pbGetFSpeciesFromForm(@species,@form)
      @sprites["formback"].y += (pbLoadSpeciesMetrics[MetricBattlerPlayerY][fSpecies] || 0)*2
    end
  end

  def pbGetAvailableForms
    available = []   # [name, gender, form]
    formdata = pbLoadFormToSpecies
    possibleforms = []
    multiforms = false
    if formdata[@species]
      for i in 0...formdata[@species].length
        fSpecies = pbGetFSpeciesFromForm(@species,i)
        formname = pbGetMessage(MessageTypes::FormNames,fSpecies)
        genderRate = pbGetSpeciesData(@species,i,SpeciesGenderRate)
        if i==0 || (formname && formname!="")
          multiforms = true if i>0
          case genderRate
          when PBGenderRates::AlwaysMale,
               PBGenderRates::AlwaysFemale,
               PBGenderRates::Genderless
            gendertopush = (genderRate==PBGenderRates::AlwaysFemale) ? 1 : 0
            if $Trainer.formseen[@species][gendertopush][i] || DEX_SHOWS_ALL_FORMS
              gendertopush = 2 if genderRate==PBGenderRates::Genderless
              possibleforms.push([i,gendertopush,formname])
            end
          else   # Both male and female
            for g in 0...2
              if $Trainer.formseen[@species][g][i] || DEX_SHOWS_ALL_FORMS
                possibleforms.push([i,g,formname])
                break if (formname && formname!="")
              end
            end
          end
        end
      end
    end
    for thisform in possibleforms
      if thisform[2] && thisform[2]!=""   # Has a form name
        thisformname = thisform[2]
      else   # Necessarily applies only to form 0
        case thisform[1]
        when 0; thisformname = _INTL("MALE")
        when 1; thisformname = _INTL("FEMALE")
        else
          thisformname = (multiforms) ? _INTL("ONE FORM") : _INTL("GENDERLESS")
        end
      end
      # Push to available array
      gendertopush = (thisform[1]==2) ? 0 : thisform[1]
      available.push([thisformname,gendertopush,thisform[0]])
    end
    return available
  end

  def drawPage(page)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    # Make certain sprites visible
    @sprites["infosprite"].visible    = (@page==1) || (@page==3)
    @sprites["areamap"].visible       = (@page==2) if @sprites["areamap"]
    #@sprites["nestlocation"].visible  = (@page==2) if @sprites["nestlocation"]
    @sprites["nestlocation"].bitmap.clear if @sprites["nestlocation"]
    @sprites["formfront"].visible     = (@page==4) if @sprites["formfront"]
    @sprites["formback"].visible      = (@page==4) if @sprites["formback"]
    # Draw page-specific information
    case page
    when 1; drawPageInfo
    when 2; drawPageArea
	when 3; drawPageInfo("cry")
    when 4; drawPageForms
    end
  end

#=================================================================================================
# Page One: Info
#=================================================================================================
  def drawPageInfo(bg = "info")
    @selbitmap = AnimatedBitmap.new("Graphics/Pictures/Pokedex/white_cursor")
    @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/bg_{1}",bg))
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(248,248,248)
    shadow = Color.new(0,0,0,0)
    imagepos = []
    # Write various bits of text
    indexText = "???"
    if @dexlist[@index][4]>0
      indexNumber = @dexlist[@index][4]
      indexNumber -= 1 if @dexlist[@index][5]
      indexText = sprintf("%03d",indexNumber)
    end
    textpos = [
	    [_INTL("{1}",PBSpecies.getName(@species)),134,40,0,base,shadow],
		[_INTL("{1}",indexText),56,120,0,base,shadow]
    ]
    if $Trainer.owned[@species]
      speciesData = pbGetSpeciesData(@species,@form)
      fSpecies = pbGetFSpeciesFromForm(@species,@form)
      # Write the kind
      kind = pbGetMessage(MessageTypes::Kinds,fSpecies)
      kind = pbGetMessage(MessageTypes::Kinds,@species) if !kind || kind==""
      textpos.push([_INTL("{1}",kind),134,74,0,base,shadow])
      # Write the height and weight
      height = speciesData[SpeciesHeight] || 1
      weight = speciesData[SpeciesWeight] || 1
      if pbGetCountry==0xF4   # If the user is in the United States
        inches = (height/0.254).round
        pounds = (weight/0.45359).round
        textpos.push([_ISPRINTF("{1:d}'{2:02d}''",inches/12,inches%12),310,101,1,base,shadow])
        textpos.push([_ISPRINTF("{1:4.1f} lb",pounds/10.0),310,134,1,base,shadow])
      else
        textpos.push([_ISPRINTF("{1:.1f} m",height/10.0),310,101,1,base,shadow])
        textpos.push([_ISPRINTF("{1:.1f} kg",weight/10.0),310,134,1,base,shadow])
      end
      # Draw the Pokédex entry text
      entry = pbGetMessage(MessageTypes::Entries,fSpecies)
      entry = pbGetMessage(MessageTypes::Entries,@species) if !entry || entry==""
	  # Get the text divided into pages that will fit on screen
	  allPages = Array.new
	  
	  normtext = getLineBrokenChunks(overlay,entry,Graphics.width-40,nil,true)
	  
	  for i in 0...normtext.length
	  rownum = normtext[i][2]/32	
        pagenum = rownum / 3
        if allPages[pagenum].nil?	
          allPages[pagenum]=""
        end
        allPages[pagenum] += normtext[i][0]
      end
      @entrypagemax = allPages.length
      #make sure we're not out of bounds
      if @entrypage >= allPages.length	
        @entrypage = 0
      end
      #draw down arrow if there's more pages
      if @entrypage < allPages.length-1
        overlay.blt(292,240,@selbitmap.bitmap,Rect.new(32,0,16,16))
      end
      drawTextEx(overlay,11,167,Graphics.width-(40),3,allPages[@entrypage],base,shadow)
      # Draw the footprint
      footprintfile = pbPokemonFootprintFile(@species,@form)
      if footprintfile
        footprint = BitmapCache.load_bitmap(footprintfile)
        overlay.blt(278,16,footprint,footprint.rect)
        footprint.dispose
      end
    else
      # Write the kind
      textpos.push([_INTL("?????"),134,74,0,base,shadow])
      # Write the height and weight
      if pbGetCountry()==0xF4 # If the user is in the United States
        textpos.push([_INTL("?'??''"),310,101,1,base,shadow])
        textpos.push([_INTL("????.? lb"),310,134,1,base,shadow])
      else
        textpos.push([_INTL("????.? m"),310,101,1,base,shadow])
        textpos.push([_INTL("????.? kg"),310,134,1,base,shadow])
      end
    end
    # Draw all text
    pbDrawTextPositions(@sprites["overlay"].bitmap,textpos)
    # Draw all images
    pbDrawImagePositions(overlay,imagepos)
  end


#=================================================================================================
# Page Two: Area
#=================================================================================================
  def drawPageArea
    @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/bg_area"))
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(0,0,0)
    shadow = Color.new(255,255,255,0)
    # Fill the array "points" with all squares of the region map in which the
    # species can be found
    points = []
    mapwidth = 1+PokemonRegionMap_Scene::RIGHT-PokemonRegionMap_Scene::LEFT
    encdata = pbLoadEncountersData
    for enc in encdata.keys
      enctypes = encdata[enc][1]
      if pbFindEncounter(enctypes,@species)
        mappos = pbGetMetadata(enc,MetadataMapPosition)
        if mappos && mappos[0]==@region
          showpoint = true
          for loc in @mapdata[@region][2]
            showpoint = false if loc[0]==mappos[1] && loc[1]==mappos[2] &&
                                 loc[7] && !$game_switches[loc[7]]
          end
          if showpoint
            mapsize = pbGetMetadata(enc,MetadataMapSize)
            if mapsize && mapsize[0] && mapsize[0]>0
              sqwidth  = mapsize[0]
              sqheight = (mapsize[1].length*1.0/mapsize[0]).ceil
              for i in 0...sqwidth
                for j in 0...sqheight
                  if mapsize[1][i+j*sqwidth,1].to_i>0
                    points[mappos[1]+i+(mappos[2]+j)*mapwidth] = true
                  end
                end
              end
            else
              points[mappos[1]+mappos[2]*mapwidth] = true
            end
          end
        end
      end
    end
    # Draw icon_nest on each square of the region map with a nest
    sqwidth = PokemonRegionMap_Scene::SQUAREWIDTH
    sqheight = PokemonRegionMap_Scene::SQUAREHEIGHT
    imagepos = []
    for j in 0...points.length
      if points[j]
        x = (j%mapwidth)*sqwidth
        x += (Graphics.width-@sprites["areamap"].bitmap.width)/2
        y = (j/mapwidth)*sqheight
        y += (Graphics.height+0-@sprites["areamap"].bitmap.height)/2 # 32
        #@sprites["nestlocation"].x = x
        #@sprites["nestlocation"].y = y
        imagepos.push([_INTL("Graphics/Pictures/Pokedex/icon_nest"),x,y,0,0,-1,-1])
      end
    end
    pbDrawImagePositions(@sprites["nestlocation"].bitmap,imagepos)
    # Set the text
    textpos = []
    if points.length==0
	  #@sprites["nestlocation"].visible = false
      pbDrawImagePositions(overlay,[
         [sprintf("Graphics/Pictures/Pokedex/overlay_areanone"),16,128]
      ])
      textpos.push([_INTL("AREA UNKNOWN"),Graphics.width/2,Graphics.height/2-8,2,base,shadow])
    end
    textpos.push([pbGetMessage(MessageTypes::RegionNames,@region),414,44,2,base,shadow])
    textpos.push([_INTL("{1}'s NEST",PBSpecies.getName(@species)),
       280,-5,1,Color.new(248,248,248)])
    pbDrawTextPositions(overlay,textpos)
  end
  
#=================================================================================================
# Page Four: Forms
#=================================================================================================
  def drawPageForms
    @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/bg_forms"))
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(0,0,0)
    shadow = Color.new(255,255,255,0)
    # Write species and form name
    formname = ""
    for i in @available
      if i[1]==@gender && i[2]==@form
        formname = i[0]; break
      end
    end
    textpos = [
       [PBSpecies.getName(@species),Graphics.width/2,Graphics.height-93,2,base,shadow],
       [formname,Graphics.width/2,Graphics.height-61,2,base,shadow],
    ]
    # Draw all text
    pbDrawTextPositions(overlay,textpos)
  end

  def pbGoToPrevious
    newindex = @index
    while newindex>0
      newindex -= 1
      if $Trainer.seen[@dexlist[newindex][0]]
        @index = newindex
        break
      end
    end
  end

  def pbGoToNext
    newindex = @index
    while newindex<@dexlist.length-1
      newindex += 1
      if $Trainer.seen[@dexlist[newindex][0]]
        @index = newindex
        break
      end
    end
  end

  def pbChooseForm
    index = 0
    for i in 0...@available.length
      if @available[i][1]==@gender && @available[i][2]==@form
        index = i
        break
      end
    end
    oldindex = -1
    loop do
      if oldindex!=index
        $Trainer.formlastseen[@species][0] = @available[index][1]
        $Trainer.formlastseen[@species][1] = @available[index][2]
        pbUpdateDummyPokemon
        drawPage(@page)
        @sprites["uparrow"].visible   = (index>0)
        @sprites["downarrow"].visible = (index<@available.length-1)
        oldindex = index
      end
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::UP)
        pbPlayCursorSE
        index = (index+@available.length-1)%@available.length
      elsif Input.trigger?(Input::DOWN)
        pbPlayCursorSE
        index = (index+1)%@available.length
      elsif Input.trigger?(Input::B)
        pbPlayCancelSE
        break
      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE
        break
      end
    end
    @sprites["uparrow"].visible   = false
    @sprites["downarrow"].visible = false
  end

  def pbScene
    pbPlayCrySpecies(@species,@form)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      dorefresh = false
      if Input.trigger?(Input::B)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::C)
	    if @page==1
		@entrypage+=1
		dorefresh = true
		pbPlayCursorSE
		end
        if @page==2   # Area
#          dorefresh = true
        elsif @page==3 # Cry
		playingBGM = $game_system.getPlayingBGM
		$game_system.bgm_pause
		pbBGMStop
		pbSEStop
        pbPlayCrySpecies(@species,@form)
		pbWait(2)
		$game_system.bgm_resume(playingBGM)
        elsif @page==4   # Forms
          if @available.length>1
            pbPlayDecisionSE
            pbChooseForm
            dorefresh = true
          end
        end
      elsif Input.trigger?(Input::UP)
	  @entrypage = 0
        oldindex = @index
        pbGoToPrevious
        if @index!=oldindex
          pbUpdateDummyPokemon
          @available = pbGetAvailableForms
          pbSEStop
          (@page==1) ? pbPlayCrySpecies(@species,@form) : pbPlayCursorSE
          dorefresh = true
        end
      elsif Input.trigger?(Input::DOWN)
	  @entrypage = 0
        oldindex = @index
        pbGoToNext
        if @index!=oldindex
          pbUpdateDummyPokemon
          @available = pbGetAvailableForms
          pbSEStop
          (@page==1) ? pbPlayCrySpecies(@species,@form) : pbPlayCursorSE
          dorefresh = true
        end
      elsif Input.trigger?(Input::LEFT)
        @entrypage = 0
		oldpage = @page
        @page -= 1
        @page = 1 if @page<1
        @page = 4 if @page>4
        if @page!=oldpage
          pbPlayCursorSE
          dorefresh = true
        end
      elsif Input.trigger?(Input::RIGHT)
        @entrypage = 0
		oldpage = @page
        @page += 1
        @page = 1 if @page<1
        @page = 4 if @page>4
        if @page!=oldpage
          pbPlayCursorSE
          dorefresh = true
        end
      end
      if dorefresh
        drawPage(@page)
      end
    end
    return @index
  end

  def pbSceneBrief
    pbPlayCrySpecies(@species,@form)
    max = @entrypagemax
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::C) || Input.trigger?(Input::B)
		@entrypage+=1
        if @entrypage >= max
          pbPlayCloseMenuSE
          break
        else
          pbPlayDecisionSE
          drawPage(@page)
        end
      end
    end
  end
end



class PokemonPokedexInfoScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen(dexlist,index,region)
    @scene.pbStartScene(dexlist,index,region)
    ret = @scene.pbScene
    @scene.pbEndScene
    return ret   # Index of last species viewed in dexlist
  end

  def pbStartSceneSingle(species)   # For use from a Pokémon's summary screen
    region = -1
    if USE_CURRENT_REGION_DEX
      region = pbGetCurrentRegion
      region = -1 if region>=$PokemonGlobal.pokedexUnlocked.length-1
    else
      region = $PokemonGlobal.pokedexDex # National Dex -1, regional dexes 0 etc.
    end
    dexnum = pbGetRegionalNumber(region,species)
    dexnumshift = DEXES_WITH_OFFSETS.include?(region)
    dexlist = [[species,PBSpecies.getName(species),0,0,dexnum,dexnumshift]]
    @scene.pbStartScene(dexlist,0,region)
    @scene.pbScene
    @scene.pbEndScene
  end

  def pbDexEntry(species)   # For use when capturing a new species
    @scene.pbStartSceneBrief(species)
    @scene.pbSceneBrief
    @scene.pbEndScene
  end
end
