# Backgrounds to show in credits. Found in Graphics/Titles/*stylefolder* folder
CreditsBackgroundList = ["credits1","credits2","credits3","credits4"]
CreditPokeList_GS     = ["bellossom","togepi","elekid","sentret"]
CreditPokeList_C      = ["pichu","smoochum","ditto","igglybuff"]
CreditsMusic          = "Ending Theme"
CreditsScrollSpeed    = 2
CreditsFrequency      = 9   # Number of seconds per credits slide
DIR                   = "Graphics/Titles"
CREDITS_OUTLINE       = Color.new(0,0,128, 0)#Color.new(0,0,128, 255)
CREDITS_SHADOW        = Color.new(0,0,0, 0)#Color.new(0,0,0, 100)
CREDITS_FILL_C        = Color.new(255,255,255, 255)
CREDITS_FILL_GS       = Color.new(0,0,0, 255)

GSStyle               = false # Format Credit GS (true) or Crystal (false)

#==============================================================================
# * Scene_Credits
#------------------------------------------------------------------------------
# Scrolls the credits you make below. Original Author unknown.
#
## Edited by MiDas Mike so it doesn't play over the Title, but runs by calling
# the following:
#    $scene = Scene_Credits.new
#
## New Edit 3/6/2007 11:14 PM by AvatarMonkeyKirby.
# Ok, what I've done is changed the part of the script that was supposed to make
# the credits automatically end so that way they actually end! Yes, they will
# actually end when the credits are finished! So, that will make the people you
# should give credit to now is: Unknown, MiDas Mike, and AvatarMonkeyKirby.
#                                             -sincerly yours,
#                                               Your Beloved
# Oh yea, and I also added a line of code that fades out the BGM so it fades
# sooner and smoother.
#
## New Edit 24/1/2012 by Maruno.
# Added the ability to split a line into two halves with <s>, with each half
# aligned towards the centre. Please also credit me if used.
#
## New Edit 22/2/2012 by Maruno.
# Credits now scroll properly when played with a zoom factor of 0.5. Music can
# now be defined. Credits can't be skipped during their first play.
#
## New Edit 25/3/2020 by Maruno.
# Scroll speed is now independent of frame rate. Now supports non-integer values
# for CreditsScrollSpeed.
#
## New Edit 21/8/2020 by Marin.
# Now automatically inserts the credits from the plugins that have been
# registered through the PluginManager module.
#==============================================================================

class Scene_Credits

# This next piece of code is the credits.
#Start Editing
CREDIT=<<_END_

POKéMON ESSENTIALS
GSC VERSION
STAFF


CREATED BY:
XAVERIUX


CONTRIBUTORS:
CARUBAN
BOONZEET
VENDILY
AWFULLYWAFFLEY
TECHSKYLANDER1518
JAMES DAVY
BO4P5687
INOKI

POKéMON ESSENTIALS:
FLAMEGURU
POCCIL (PETER O.)
MARUNO

CONTRIBUTIONS:
AVATARMONKEYKIRBY
MARIN
BOUSHY
MIDAS MIKE
BROTHER1440
NEAR FANTASTICA
FL.
PINKMAN
GENZAI KAWAKAMI
POPPER
HELP-14
RATAIME
ICEGOD64
SOUNDSPAWN
JACOB O. WOBBROCK
THE END
KITSUNEKOUTA
VENOM12
LISA ANTHONY
WACHUNGA
LUKA S.J.
And everyone else 
who helped out!


RPG Maker XP:
ENTERBRAIN


POKéMON is owned by:
The POKéMON COMPANY
NINTENDO
Affiliated with GAME FREAK

This is a non-profit
fan-made game.
No copyright 
infringements intended.


Please, support the
official games!

_END_
#Stop Editing

  def main
#-------------------------------
# Animated Background Setup
#-------------------------------
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 0
    @sprite = BitmapSprite.new(Graphics.width*2,Graphics.height,@viewport)#IconSprite.new(0,0)
    @backgroundList = CreditsBackgroundList
    @pokeList = GSStyle ? CreditPokeList_GS : CreditPokeList_C
    @frameCounter = 0
    @frameCounterTxt = 0
    # Number of game frames per background frame
    @framesPerBackground = CreditsFrequency * Graphics.frame_rate
    @dirstyle = GSStyle ? "gsStyle Credits" : "crystalStyle Credits"

    img = AnimatedBitmap.new("#{DIR}/#{@dirstyle}/#{@backgroundList[0]}")
    rect = Rect.new(0,0,img.bitmap.width,img.bitmap.height)
    @sprite.bitmap.blt(0,0,img.bitmap,rect)
    @sprite.bitmap.blt(img.bitmap.width,0,img.bitmap,rect)
    @sprite.x = GSStyle ? 0 : -Graphics.width
    @sprite.visible = true

    @endcredit = 1
    @creditend = IconSprite.new(0,0)
    @creditend.setBitmap("#{DIR}/#{@dirstyle}/creditEnd#{@endcredit}")
    @creditend.visible = false
#-------------------------------
# Animated Pokémon
#-------------------------------
    @sprite_anim = []
    @title = true
    @framepertext = 120
    i = 0
    frameskip = GSStyle ? 4 : 2
    size = GSStyle ? 10 : 5
    size.times do
      anim = AnimatedSprite.new("#{DIR}/#{@dirstyle}/#{@pokeList[0]}",4,64,64,frameskip)
      anim.x = 64*(i%5)
      anim.y = (i>=5) ? Graphics.height - 64 : 0
      anim.visible = false
      anim.play
      @sprite_anim.push(anim)
      i+=1
    end
#------------------
# Credits text Setup
#------------------
    plugin_credits = ""
    PluginManager.plugins.each do |plugin|
      pcred = PluginManager.credits(plugin)
      pos = 4
      if pcred.size == 1
        plugin_credits << "\n"
        pos -= 1
      end
      plugin_credits << "\"#{plugin}\" version #{PluginManager.version(plugin)}\n"
      if pcred.size >= 4
        plugin_credits << pcred[0] + "\n"
        pos -= 1
        i = 1
        until i >= pcred.size
          if pos == 0
            plugin_credits << "\"#{plugin}\" version #{PluginManager.version(plugin)}\n"
            pos = GSStyle ? 4 : 3
          end
          plugin_credits << pcred[i] + "<s>" + (pcred[i + 1] || "") + "\n"
          i += 2
          pos -= 1
          if GSStyle && pos == 1 && i < pcred.size
            plugin_credits << "\n"
            pos -= 1
          end
        end
        pos -= 1 if GSStyle
      else
        pcred.each do |name|
          plugin_credits << name + "\n"
          pos -= 1
        end
      end
      pos.times do
        plugin_credits << "\n"
      end
    end
    CREDIT.gsub!(/\{INSERTS_PLUGIN_CREDITS_DO_NOT_REMOVE\}/, plugin_credits)
    credit_lines = CREDIT.split(/\n/)
    credit_bitmap = Bitmap.new(Graphics.width,32 * credit_lines.size)
    credit_lines.each_index do |i|
      line = credit_lines[i]
      line = line.split("<s>")
      # LINE ADDED: If you use in your own game, you should remove this line
      pbSetSystemFont(credit_bitmap) # <--- This line was added
      xpos = 0
      align = 1 # Centre align
      linewidth = Graphics.width
      for j in 0...line.length
        if line.length>1
          xpos = (j==0) ? 0 : 20 + Graphics.width/2
          align = (j==0) ? 2 : 0 # Right align : left align
          linewidth = Graphics.width/2 - 20
        end
        credit_bitmap.font.color = CREDITS_SHADOW
        credit_bitmap.draw_text(xpos,i * 32 + 8,linewidth,32,line[j],align)
        credit_bitmap.font.color = CREDITS_OUTLINE
        credit_bitmap.draw_text(xpos + 2,i * 32 - 2,linewidth,32,line[j],align)
        credit_bitmap.draw_text(xpos,i * 32 - 2,linewidth,32,line[j],align)
        credit_bitmap.draw_text(xpos - 2,i * 32 - 2,linewidth,32,line[j],align)
        credit_bitmap.draw_text(xpos + 2,i * 32,linewidth,32,line[j],align)
        credit_bitmap.draw_text(xpos - 2,i * 32,linewidth,32,line[j],align)
        credit_bitmap.draw_text(xpos + 2,i * 32 + 2,linewidth,32,line[j],align)
        credit_bitmap.draw_text(xpos,i * 32 + 2,linewidth,32,line[j],align)
        credit_bitmap.draw_text(xpos - 2,i * 32 + 2,linewidth,32,line[j],align)
        credit_bitmap.font.color = GSStyle ? CREDITS_FILL_GS : CREDITS_FILL_C
        credit_bitmap.draw_text(xpos,i * 32,linewidth,32,line[j],align)
      end
    end
    @trim = Graphics.height/10
    @realOY = 0
    @oyChangePerFrame = CreditsScrollSpeed*20.0/Graphics.frame_rate
    @credit_sprite = Sprite.new(Viewport.new(0,@trim*3,Graphics.width,Graphics.height-(@trim*5)+16))#(@trim*2)))
    @credit_sprite.bitmap = credit_bitmap
    @credit_sprite.z      = 9998
    #@credit_sprite.oy     = @realOY
    @bg_index = 0
    @zoom_adjustment = 1.0/$ResizeFactor
    @last_flag = false
#--------
# Setup
#--------
    # Stops all audio but background music
    previousBGM = $game_system.getPlayingBGM
    pbMEStop
    pbBGSStop
    pbSEStop
    pbBGMFade(2.0)
    pbBGMPlay(CreditsMusic)
    Graphics.transition(20)
    loop do
      Graphics.update
      Input.update
      @sprite_anim.each { |anim| anim.update }
      update
      break if $scene != self
    end
    Graphics.freeze
    @sprite.dispose
    @viewport.dispose
    @credit_sprite.dispose
    @creditend.dispose
    @sprite_anim.each { |anim| anim.dispose }
    $PokemonGlobal.creditsPlayed = true
    pbBGMPlay(previousBGM)
  end

  # Check if the credits should be cancelled
  def cancel?
    if Input.trigger?(Input::C) && $PokemonGlobal.creditsPlayed
      $scene = Scene_Map.new
      pbBGMFade(1.0)
      return true
    end
    return false
  end

  # Checks if credits bitmap has reached its ending point
  def last?
    if @realOY > @credit_sprite.bitmap.height + @trim && @endcredit>=3
      $scene = ($game_map) ? Scene_Map.new : nil
      pbBGMFade(2.0)
      return true
    end
    return false
  end

  def update
    @frameCounter += 1
    @frameCounterTxt += 1
    if GSStyle
      @sprite.x -= 1
      @sprite.x = 0 if @sprite.x<=-Graphics.width
    else
      @sprite.x += 1
      @sprite.x = -Graphics.width if @sprite.x>=0
    end
    
    if @realOY > @credit_sprite.bitmap.height + @trim
      @credit_sprite.visible = false
      @creditend.visible = true
      if @frameCounterTxt >= @framepertext+(20*@endcredit)
        @frameCounterTxt = 0
        if @endcredit < 3
          @endcredit += 1
          @creditend.setBitmap("#{DIR}/#{@dirstyle}/creditEnd#{@endcredit}")
        end
      end
    else
      # Go to next text
      if @frameCounterTxt >= @framepertext && @credit_sprite.visible
        @frameCounterTxt = 0
        @realOY += 148 + 12 #@oyChangePerFrame*200
        @credit_sprite.oy = @realOY
        @credit_sprite.visible = false
      elsif @frameCounterTxt >= 10 && !@credit_sprite.visible
        @credit_sprite.visible = true
        # Go to next slide
        if @frameCounter >= @framesPerBackground && @bg_index < @backgroundList.length-1
          @frameCounter = 0#-= @framesPerBackground
          @bg_index += 1
          # BG
          img = AnimatedBitmap.new("#{DIR}/#{@dirstyle}/#{@backgroundList[@bg_index]}")
          rect = Rect.new(0,0,img.bitmap.width,img.bitmap.height)
          @sprite.bitmap.clear
          @sprite.bitmap.blt(0,0,img.bitmap,rect)
          @sprite.bitmap.blt(img.bitmap.width,0,img.bitmap,rect)
          # Poke
          poke_pos = []
          size = @sprite_anim.length
          @sprite_anim.each { |anim|
            poke_pos.push([anim.x,anim.y])
            anim.dispose
          }
          @sprite_anim = []
          i = 0
          size.times do
            frameskip = GSStyle ? 4 : 2
            anim = AnimatedSprite.new("#{DIR}/#{@dirstyle}/#{@pokeList[@bg_index]}",4,64,64,frameskip)
            anim.x = poke_pos[i][0]
            anim.y = poke_pos[i][1]
            anim.play
            @sprite_anim.push(anim)
            i+=1
          end
        end
        @frameCounterTxt = 0
        if @title
          @title = false
          @sprite_anim.each { |anim| anim.visible=true }
        end
      end
    end
    return if cancel?
    return if last?
    # @realOY += @oyChangePerFrame
    # @credit_sprite.oy = @realOY
  end
end
