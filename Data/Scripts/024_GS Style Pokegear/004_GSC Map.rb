class PokemonRegionMap_Scene
    LEFT   = 0
    TOP    = 0
    RIGHT  = 29
    BOTTOM = 19
    SQUAREWIDTH  = 16
    SQUAREHEIGHT = 16
  
    def initialize(region=-1,wallmap=true)
      @region  = region
      @wallmap = wallmap
    end
  
    def pbUpdate
      pbUpdateSpriteHash(@sprites)
    end
  
    def pbStartScene(aseditor=false,mode=0)
        @editor = aseditor
        @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
        @viewport.z = 99999
        @sprites = {}
        @map_idx = 0
        @mode = mode
        @baseColor   = Color.new(0,0,0)
        @shadowColor = Color.new(255,255,255,0)

        # Sprites
        @sprites["background"] = IconSprite.new(0,0,@viewport)
        name_bg = "pokegear/bg_2"
        name_bg = "mapbg" if mode==1
        @sprites["background"].setBitmap("Graphics/Pictures/#{name_bg}")

        @sprites["helpwindow"]=Window_UnformattedTextPokemon.new("")
        @helpwindow = @sprites["helpwindow"]
        @helpwindow.viewport = @viewport
        pbBottomLeftLines(@sprites["helpwindow"],2)
        @helpwindow.width = Graphics.width
        @helpwindow.text = _INTL("")
        @helpwindow.baseColor = @baseColor
        @helpwindow.shadowColor = @shadowColor
        @helpwindow.windowskin = nil
        @helpwindow.visible = true

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
        @sprites["mapbar"] = IconSprite.new(0,0,@viewport)
        @sprites["mapbar"].setBitmap("Graphics/Pictures/#{name_bg}_bar")
        meta = pbGetMetadata(0,MetadataPlayerA+$PokemonGlobal.playerID)
        if playerpos && @mapindex==playerpos[0] && meta
        filename = pbGetPlayerCharset(meta,1,nil,true)
        @sprites["player"] = TrainerWalkingCharSprite.new(filename,@viewport)
        charwidth  = @sprites["player"].bitmap.width
        charheight = @sprites["player"].bitmap.height
        @sprites["player"].x = -SQUAREWIDTH/2+(@mapX*SQUAREWIDTH)+(Graphics.width-@sprites["map"].bitmap.width)/2
        @sprites["player"].y = -SQUAREHEIGHT/2+(@mapY*SQUAREHEIGHT)+(Graphics.height-@sprites["map"].bitmap.height)/2
        @sprites["player"].src_rect = Rect.new(0,0,charwidth/4,charheight/4)
        #@sprites["player"].visible = false
        end
        if mode==1
            @sprites["mapcursor"] = AnimatedSprite.create("Graphics/Pictures/flyCursor",2,3)
            @sprites["mapcursor"].viewport = @viewport
            @sprites["mapcursor"].play
        else
            @sprites["mapcursor"] = IconSprite.new(0,0,@viewport)
            @sprites["mapcursor"].setBitmap("Graphics/Pictures/Pokegear/mapcursor")
        end
        @sprites["mapcursor"].x = -SQUAREWIDTH/2+(@mapX*SQUAREWIDTH)+(Graphics.width-@sprites["map"].bitmap.width)/2
        @sprites["mapcursor"].y = -SQUAREHEIGHT/2+(@mapY*SQUAREHEIGHT)+(Graphics.height-@sprites["map"].bitmap.height)/2
        #@sprites["mapcursor"].visible = false
        townmapdata = @mapdata[@region][2]
        i=0
        for loc in townmapdata
            if loc[0] == @mapX && loc[1] == @mapY
                @map_idx = i
                break
            end
            i+=1
        end
        # Text
        @sprites["overlays"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
        pbChangeMap(0) if mode==1

        pbFadeInAndShow(@sprites) { pbUpdate }
        return true
    end
    def pbEndScene
        pbFadeOutAndHide(@sprites)
        pbDisposeSpriteHash(@sprites)
        @viewport.dispose
    end
    
    def pbGetHealingSpot(x,y)
        townmapdata = @mapdata[@region][2]
        return nil if !townmapdata
        for loc in townmapdata
        if loc[0]==x && loc[1]==y
            if !loc[4] || !loc[5] || !loc[6]
            return nil
            else
            return [loc[4],loc[5],loc[6]]
            end
        end
        end
        return nil
    end
    def pbChangeMap(sum)
        townmapdata = @mapdata[@region][2]
        @map_idx += sum
        @map_idx = 0 if @map_idx >= townmapdata.length
        @map_idx = townmapdata.length-1 if @map_idx <0
        @mapX = townmapdata[@map_idx][0]
        @mapY = townmapdata[@map_idx][1]
        sum = 1 if sum==0
        if @mode==1
            loop do
                healspot = pbGetHealingSpot(@mapX,@mapY)
                if healspot
                    if $PokemonGlobal.visitedMaps[healspot[0]] || $DEBUG
                        break
                    end
                else
                    @map_idx += sum
                    @map_idx = 0 if @map_idx >= townmapdata.length
                    @map_idx = townmapdata.length-1 if @map_idx <0
                    @mapX = townmapdata[@map_idx][0]
                    @mapY = townmapdata[@map_idx][1]
                end
            end
        #else
        end
        @sprites["mapcursor"].x = -SQUAREWIDTH/2+(@mapX*SQUAREWIDTH)+(Graphics.width-@sprites["map"].bitmap.width)/2
        @sprites["mapcursor"].y = -SQUAREHEIGHT/2+(@mapY*SQUAREHEIGHT)+(Graphics.height-@sprites["map"].bitmap.height)/2
        pbUpdateText
    end
    def pbUpdateText
        if @sprites.include?("overlays")
          @sprites["overlays"].bitmap.clear
        end
        textPositions=[]
        @maplocation = pbGetMapLocation(@mapX,@mapY)
        max = (@mode==1)? 16 : 10
        words = pbTextSpliter(@helpwindow,@maplocation,16)
        i=0
        for text in words
            if @mode==1
                textPositions.push([text.upcase,32,8+16*i,0,@baseColor,@shadowColor])
            else
                textPositions.push([text.upcase,144,-8+16*i,0,@baseColor,@shadowColor])
            end
            i+=1
        end
        pbSetSystemFont(@sprites["overlays"].bitmap)
        pbDrawTextPositions(@sprites["overlays"].bitmap,textPositions)
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

    def pbMapScene(mode=0)
        loop do
            Graphics.update
            Input.update
            pbUpdate
            if Input.trigger?(Input::C) && mode==1   # Choosing an area to fly to
                healspot = pbGetHealingSpot(@mapX,@mapY)
                return healspot if healspot
            elsif Input.trigger?(Input::B)
              pbPlayCloseMenuSE
              break
            elsif Input.trigger?(Input::UP)
                pbChangeMap(1)
            elsif Input.trigger?(Input::DOWN)
                pbChangeMap(-1)
            end
        end
    end
end

class PokemonRegionMapScreen
    def initialize(scene)
        @scene = scene
    end

    def pbStartFlyScreen
        @scene.pbStartScene(false,1)
        ret = @scene.pbMapScene(1)
        @scene.pbEndScene
        return ret
    end

    def pbStartScreen
        @scene.pbStartScene($DEBUG)
        @scene.pbMapScene
        @scene.pbEndScene
    end
end



def pbShowMap(region=-1,wallmap=true)
    pbFadeOutIn {
        scene = PokemonRegionMap_Scene.new(region,wallmap)
        screen = PokemonRegionMapScreen.new(scene)
        screen.pbStartScreen
    }
end
  