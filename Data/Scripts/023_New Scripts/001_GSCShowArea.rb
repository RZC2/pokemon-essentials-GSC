#============================================================================
## This script will change the Location signpost to match that of G/S/C's  ##
##                                                                         ##
##                 GSC Location by Pia Carrot                              ##
#============================================================================
class LocationWindow 
  def initialize(name) 
    @window=Window_AdvancedTextPokemon.new(name) 
    @window.setSkin("Graphics/Windowskins/showarea") 
    @window.baseColor=Color.new(0,0,0)
    @window.shadowColor=Color.new(248,248,248,0)
    @window.width=320 
    @window.height=64 
    @window.x=0 
    @window.y=-@window.height 
    @window.z=99999 
    @currentmap=$game_map.map_id
    @frames=0 
  end 
  
  def disposed? 
    @window.disposed? 
  end 
  
  def dispose 
    @window.dispose 
  end 
  
  def update 
    return if @window.disposed? 
    @window.update 
    if $game_temp.message_window_showing || 
      @currentmap!=$game_map.map_id 
      @window.dispose 
      return 
    end 
    if @frames>80 
      @window.y-=288 
      @window.dispose if @window.y+@window.height<0 
    else @window.y+=288 if @window.y<0 
      @frames+=1 
    end 
  end 
end