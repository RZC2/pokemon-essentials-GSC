#==============================================================================
# * Scene_Controls
#------------------------------------------------------------------------------
# Shows a help screen listing the keyboard controls.
# Display with:
#      pbEventScreen(ButtonEventScene)
#==============================================================================
class ButtonEventScene < EventScene
  def initialize(viewport = nil)
    super
    Graphics.freeze
    addImage(0, 0, "Graphics/Pictures/helpbg")
    pictureWait   # Update event scene with the changes
    Graphics.transition(20)
    # Go to next screen when user presses C
    onCTrigger.set(method(:pbOnScreen1))
  end

  def pbOnScreen1(scene,*args)
    # End scene
    Graphics.freeze
    scene.dispose
    Graphics.transition(20)
  end
end
