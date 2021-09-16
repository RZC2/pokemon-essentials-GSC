#================================================================================
# Trainer Card
#================================================================================
#================================================================================
# Trainer Card: Front
# - Content: Player's Name and Sprite, ID Nº, Money, Pokédex, Play Time and "Badges >" text.
#================================================================================
class TrainerCard
  def cardFront
    viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    viewport.z = 999999
    sprites={}
    sprites["background"]=Sprite.new
    sprites["background"].z=99999
    if $Trainer.isMale?
      sprites["background"].bitmap=BitmapCache.load_bitmap("Graphics/Pictures/Trainer Card/bg")
    else
      sprites["background"].bitmap=BitmapCache.load_bitmap("Graphics/Pictures/Trainer Card/bg_f")
    end
    sprites["trainer"]=IconSprite.new(0,0,viewport)
    if $Trainer.isMale?
      sprites["trainer"].setBitmap("Graphics/Trainers/trainer000")
    else
      sprites["trainer"].setBitmap("Graphics/Trainers/trainer001")
    end
    sprites["trainer"].x=200
    sprites["trainer"].y=17
    sprites["overlay"]=BitmapSprite.new(Graphics.width, Graphics.height, viewport)
    loop do
      Graphics.update
      Input.update
      if $Trainer.isMale?
        sprites["background"].bitmap=BitmapCache.load_bitmap("Graphics/Pictures/Trainer Card/bg")
      else
        sprites["background"].bitmap=BitmapCache.load_bitmap("Graphics/Pictures/Trainer Card/bg_f")
      end
      if $Trainer.isMale?
        sprites["trainer"].setBitmap("Graphics/Trainers/trainer000")
      else
        sprites["trainer"].setBitmap("Graphics/Trainers/trainer001")
      end
      overlay=sprites["overlay"].bitmap
      overlay.clear
      base=Color.new(0,0,0)
      shadow=Color.new(255,255,255,0)
      id=sprintf("%05d",$Trainer.publicID($Trainer.id))
      totalsec = Graphics.frame_count / Graphics.frame_rate
      hour = totalsec / 60 / 60
      min = totalsec / 60 % 60
      time=_ISPRINTF("{1:02d}:{2:02d}",hour,min)
      pbSetSystemFont(sprites["overlay"].bitmap)
      textos=[
      [_INTL("NAME/"),32,24,0,base,shadow],
      [_INTL("{1}",$Trainer.name),112,24,0,base,shadow],
      [_INTL("{1}",id),80,56,0,base,shadow],
      [_INTL("MONEY"),32,96,0,base,shadow],
      [_INTL("${1}",$Trainer.money),222,96,1,base,shadow],
      [_INTL("POKéDEX"),32,160,0,base,shadow],
      [sprintf("%d/%d",$Trainer.pokedexOwned,$Trainer.pokedexSeen),300,160,1,base,shadow],
      [_INTL("PLAY TIME"),32,192,0,base,shadow],
      [time,300,192,1,base,shadow],
      [_INTL("BADGES>"),192,240,0,base,shadow],
      ]
      pbDrawTextPositions(overlay,textos)
      if Input.trigger?(Input::B)
        pbSEPlay("GUI menu close")
        pbFadeOutAndHide(sprites){pbUpdateSpriteHash(sprites)}
        pbDisposeSpriteHash(sprites)
        viewport.dispose if viewport
        break
      end
      if Input.trigger?(Input::C) || Input.trigger?(Input::RIGHT)
        pbSEPlay("GUI sel decision")
        #pbFadeOutAndHide(sprites){pbUpdateSpriteHash(sprites)}
        pbDisposeSpriteHash(sprites)
        viewport.dispose if viewport
        cardBack
        break
      end
    end
  end

  
#==========================================================================================
# Trainer Card: Back
# - Content: Animated badges sprites.
#==========================================================================================
  def cardBack
    viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    viewport.z = 999999
    sprites={}
    sprites["background"]=Sprite.new
    sprites["background"].z=99999
    if $Trainer.isMale?
      sprites["background"].bitmap=BitmapCache.load_bitmap("Graphics/Pictures/Trainer Card/bg_badges")
    else
      sprites["background"].bitmap=BitmapCache.load_bitmap("Graphics/Pictures/Trainer Card/bgf_badges")
    end
    sprites["trainer"]=IconSprite.new(0,0,viewport)
    if $Trainer.isMale?
      sprites["trainer"].setBitmap("Graphics/Trainers/trainer000")
    else
      sprites["trainer"].setBitmap("Graphics/Trainers/trainer001")
    end
    sprites["trainer"].x=200
    sprites["trainer"].y=17
    #1st
    sprites["badge1"]=badg1=AnimatedSprite.create("Graphics/Pictures/Trainer Card/badge_1",4,5,viewport)
    sprites["badge1"].x=20
    sprites["badge1"].y=177
    sprites["badge1"].visible=false
    sprites["badge1"].play
    #2nd
    sprites["badge2"]=badg2=AnimatedSprite.create("Graphics/Pictures/Trainer Card/badge_2",4,5,viewport)
    sprites["badge2"].x=87
    sprites["badge2"].y=177
    sprites["badge2"].visible=false
    sprites["badge2"].play
    #3rd
    sprites["badge3"]=badg3=AnimatedSprite.create("Graphics/Pictures/Trainer Card/badge_3",4,5,viewport)
    sprites["badge3"].x=154
    sprites["badge3"].y=177
    sprites["badge3"].visible=false
    sprites["badge3"].play
    #4th
    sprites["badge4"]=badg4=AnimatedSprite.create("Graphics/Pictures/Trainer Card/badge_4",4,5,viewport)
    sprites["badge4"].x=221
    sprites["badge4"].y=177
    sprites["badge4"].visible=false
    sprites["badge4"].play
    #5th
    sprites["badge5"]=badg5=AnimatedSprite.create("Graphics/Pictures/Trainer Card/badge_5",4,5,viewport)
    sprites["badge5"].x=20
    sprites["badge5"].y=225
    sprites["badge5"].visible=false
    sprites["badge5"].play
    #6th
    sprites["badge6"]=badg6=AnimatedSprite.create("Graphics/Pictures/Trainer Card/badge_6",4,5,viewport)
    sprites["badge6"].x=87
    sprites["badge6"].y=225
    sprites["badge6"].visible=false
    sprites["badge6"].play
    #7th
    sprites["badge7"]=badg7=AnimatedSprite.create("Graphics/Pictures/Trainer Card/badge_7",4,5,viewport)
    sprites["badge7"].x=154
    sprites["badge7"].y=225
    sprites["badge7"].visible=false
    sprites["badge7"].play
    #8th
    sprites["badge8"]=badg8=AnimatedSprite.create("Graphics/Pictures/Trainer Card/badge_8",4,5,viewport)
    sprites["badge8"].x=221
    sprites["badge8"].y=225
    sprites["badge8"].visible=false
    sprites["badge8"].play
    sprites["overlay"]=BitmapSprite.new(Graphics.width, Graphics.height, viewport)
    loop do
      Graphics.update
      Input.update
      pbUpdateSpriteHash(sprites)
      if $Trainer.isMale?
        sprites["background"].bitmap=BitmapCache.load_bitmap("Graphics/Pictures/Trainer Card/bg_badges")
      else
        sprites["background"].bitmap=BitmapCache.load_bitmap("Graphics/Pictures/Trainer Card/bgf_badges")
      end
      overlay=sprites["overlay"].bitmap
      overlay.clear
      base=Color.new(0,0,0)
      shadow=Color.new(255,255,255,0)
      id=sprintf("%05d",$Trainer.publicID($Trainer.id))
      if $Trainer.badges[0]
        sprites["badge1"].visible=true
      else
        sprites["badge1"].visible=false
      end
      
      if $Trainer.badges[1]
        sprites["badge2"].visible=true
      else
        sprites["badge2"].visible=false
      end
      
      if $Trainer.badges[2]
        sprites["badge3"].visible=true
      else
        sprites["badge3"].visible=false
      end
      
      if $Trainer.badges[3]
        sprites["badge4"].visible=true
      else
        sprites["badge4"].visible=false
      end
      
      if $Trainer.badges[4]
        sprites["badge5"].visible=true
      else
        sprites["badge5"].visible=false
      end
      
      if $Trainer.badges[5]
        sprites["badge6"].visible=true
      else
        sprites["badge6"].visible=false
      end
      
      if $Trainer.badges[6]
        sprites["badge7"].visible=true
      else
        sprites["badge7"].visible=false
      end
      
      if $Trainer.badges[7]
        sprites["badge8"].visible=true
      else
        sprites["badge8"].visible=false
      end
      pbSetSystemFont(sprites["overlay"].bitmap)
      textos=[
      [_INTL("NAME/"),32,24,0,base,shadow],
      [_INTL("{1}",$Trainer.name),112,24,0,base,shadow],
      [_INTL("{1}",id),80,56,0,base,shadow],
      [_INTL("MONEY"),32,96,0,base,shadow],
      [_INTL("${1}",$Trainer.money),222,96,1,base,shadow],
      ]
      pbDrawTextPositions(overlay,textos)
      if Input.trigger?(Input::B)
        pbSEPlay("GUI menu close")
        #pbFadeOutAndHide(sprites){pbUpdateSpriteHash(sprites)}
        pbDisposeSpriteHash(sprites)
        viewport.dispose if viewport
        cardFront
        break
      end
      if Input.trigger?(Input::C) || Input.trigger?(Input::LEFT)
        pbSEPlay("GUI sel decision")
        #pbFadeOutAndHide(sprites){pbUpdateSpriteHash(sprites)}
        pbDisposeSpriteHash(sprites)
        viewport.dispose if viewport
        cardFront
        break
      end
    end
  end
end