#===============================================================================
# Call Scene v1.1
#
# How to Use
# - call pbMessageCallingIn(caller) before the dialogue
#   then call pbMessageCallEnd to close the phone after dialogue
#===============================================================================
class PokemonTemp
  attr_accessor :calldataCaruban
end
def pbMessageCallingIn(caller="")
  viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
  viewport.z = 99999
  sprites={}
  sprites["callbg"] = IconSprite.new(0,0,viewport)
  sprites["callbg"].setBitmap("Graphics/Pictures/pokegear/phone_bg")
  sprites["call"] = IconSprite.new(0,0,viewport)
  sprites["call"].setBitmap("Graphics/Pictures/pokegear/phone_icon")
  sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,viewport)
  sprites["overlay"].bitmap.clear
  baseColor   = Color.new(0,0,0)
  shadowColor = Color.new(255,255,255,0)
  textPositions=[
    [_INTL("{1}:",caller),48,8,0,baseColor,shadowColor],
  ]
  pbSetSystemFont(sprites["overlay"].bitmap)
  pbDrawTextPositions(sprites["overlay"].bitmap,textPositions)
  frame = 0
  visible = true
  ret = [sprites,viewport]
  pbSEPlay("PhoneRingging", 100, 100)
  loop do
    Graphics.update
    Input.update
    pbUpdateSceneMap
    if frame == 100
      frame = 0
      pbSEStop
      pbSEPlay("PhoneRingging", 100, 100)
    end
    if frame%25 == 0
      visible = (!visible)
    end
    sprites["overlay"].visible = visible
    sprites["call"].visible = visible
    frame += 1
    if Input.trigger?(Input::C) || Input.trigger?(Input::B)
      break
    end
    yield if block_given?
  end
  pbSEStop
  sprites["overlay"].visible = true
  sprites["call"].visible = true
  pbSEPlay("GUI Storage pick up")
  $PokemonTemp.calldataCaruban = ret
end

def pbMessageCallEnd
  data = $PokemonTemp.calldataCaruban
  return if !data
  sprites = data[0]
  viewport = data[1]
  pbDisposeSpriteHash(sprites)
  viewport.dispose
  pbSEPlay("GUI Storage put down")
  $PokemonTemp.calldataCaruban = nil
end