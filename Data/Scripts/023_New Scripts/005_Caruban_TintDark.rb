def pbDarkMapTint(object)
    return if !$scene.is_a?(Scene_Map)
    object.tone.set(-255,-255,-255,-255)
end