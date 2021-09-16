################################################################################
# Radio text copied from
# https://gamefaqs.gamespot.com/gbc/198308-pokemon-gold-version/faqs/49457
################################################################################
# Core Code
################################################################################
def pbTextSpliter(window,str,maxchar=nil)
  words = str.split(' ')
  words = [""] if words==[]
  line = words[0]
  arr = []
  if words.length > 1
    for word in words[1...words.length]
        test = line+" "+word
        maxlength = window.contents.width
        if window.contents.text_size(test).width>maxlength || 
          (maxchar && test.length > maxchar)
            arr.push(line)
            line = word
        else
            line = test
        end
    end
  end
  arr.push(line)
  return arr
end
def pbGetRadioFormatLine(window,looptext,intro=nil)
  text = [looptext]
  text.unshift(intro) if intro
  i=0; array =[[],[]]
  for item in text
    for lines in item
      breakline = pbTextSpliter(window,lines)
      for line in breakline
        array[i].push(line)
      end
    end
    i+=1
  end
  return array
end
################################################################################
# Pokedex Show
################################################################################

def pbGetPokedexShow(window)
  pbBGMPlay(POKEDEX_BGM, 100, 100)
  input = []
  formdata = pbLoadFormToSpecies
  2.times do
    species = 1+rand(PBSpecies.maxValue)
    form = (formdata[species])? rand(formdata[species].length) : 0 
    fSpecies = pbGetFSpeciesFromForm(species,form)
    #formname = (!formdata[species])? "" : pbGetMessage(MessageTypes::FormNames,fSpecies)
    
    # Write the kind
    kind = pbGetMessage(MessageTypes::Kinds,fSpecies)
    kind = pbGetMessage(MessageTypes::Kinds,species) if !kind || kind==""
  
    # Draw the Pokédex entry text
    entry = pbGetMessage(MessageTypes::Entries,fSpecies)
    entry = pbGetMessage(MessageTypes::Entries,species) if !entry || entry==""
    
    input.push([PBSpecies.getName(species).upcase,
                                kind.upcase,entry])
  end
  array = pbGetRadioFormatLine(window,input[0],input[1])
  return array
end
################################################################################
# Prof Oak TalkShow
################################################################################
def pbGetOakTalkShow(window)
  pbBGMPlay(OAK_BGM, 100, 100)
  array=[]
  route = []
  encdata = pbLoadEncountersData
  for mapID in encdata.keys
      route.push(mapID)
  end
  mapid = route[rand(route.length)]
  enctypes = $PokemonEncounters.pbGetEncounterTables(mapid)
  species = 0
  loop do
    species = pbRandomEncounterSpecies(enctypes[EncounterTypes::Land])
    species = pbRandomEncounterSpecies(enctypes[EncounterTypes::Cave]) if species==0
    species = pbRandomEncounterSpecies(enctypes[EncounterTypes::LandDay]) if species==0
    species = pbRandomEncounterSpecies(enctypes[EncounterTypes::LandMorning]) if species==0
    species = pbRandomEncounterSpecies(enctypes[EncounterTypes::LandNight]) if species==0
    species = pbRandomEncounterSpecies(enctypes[EncounterTypes::Water]) if species==0
    break if species>0
  end
  mapname = pbGetMapNameFromId(mapid)
  
  text1 = [
      "almost poisonously",
      "aptly named and",
      "evolution must be",
      "heart-meltingly",
      "looks in water is",
      "ooh, so sensually",
      "provocatively",
      "so flipped out and",
      "so mischievously",
      "so very topically",
      "so, so unbearably",
      "sure addictively",
      "sweet and adorably",
      "undeniably kind of",
      "wiggly and slickly",
      "wow, impressively",
  ]
  text2 = [
      "bold, sort of.",
      "cute",
      "exciting",
      "friendly.",
      "frightening.",
      "guarded.",
      "hot, hot, hot!",
      "inspiring.",
      "lovely.",
      "now!",
      "pleasant.",
      "powerful.",
      "speedy.",
      "stimulating.",
      "suave & debonair!",
      "weird.",
  ]
  a = PBSpecies.getName(species).upcase
  b = text1[rand(text1.length)]
  c = text2[rand(text2.length)]
  intro = [
      #"PROF.OAK's POKEMON TALK! Please tune in next time!",
      #"POKEMON CHANNEL!",
      #"This is DJ MARY, your co-host!",
      #"POKEMON! POKEMON CHANNEL...",
      "Mary : PROF.OAK'S POKEMON TALK! With me, MARY!"
  ]
  oak = _INTL("Oak : {1} may be seen around {2}.",a,mapname.upcase)
  mary = _INTL("Mary : {1}'s {2} {3}.",a,b,c)
  array = pbGetRadioFormatLine(window,[oak,mary],intro)
  return array
end
################################################################################
# POKEMON Music
################################################################################
def pbGetPokemonMusicCh(window)
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
  intro = (wday%2==0)? 
          _INTL("so let us jam to") :
          _INTL("so chill out to")
  if wday%2==0 # March
    pbBGMPlay(MARCH_BGM, 100, 100)
    $PokemonMap.whiteFluteUsed = true if $PokemonMap
    $PokemonMap.blackFluteUsed = false if $PokemonMap
  else
    pbBGMPlay(LULLABY_BGM, 100, 100)
    $PokemonMap.blackFluteUsed = true if $PokemonMap
    $PokemonMap.whiteFluteUsed = false if $PokemonMap
  end
  loop = (wday%2==0)? 
          _INTL("POKEMON MARCH!") :
          _INTL("POKEMON Lullaby!")
  text = ["Ben : POKEMON MUSIC CHANNEL!",
          _INTL("It's me, DJ BEN! Today's {1}, {2}",day.upcase,intro)]
  array = pbGetRadioFormatLine(window,[loop],text)
  return array
end
################################################################################
# Lucky Number Show 
# - Need script to save the LotteNumber and change it every week
################################################################################
def pbGetLotteryCh(window)
  pbSetLotteryNumber(1) # always generate for now
  pbBGMPlay(LOTTERY_BGM, 100, 100)
  number = pbGet(1)
  loop = ["Reed : Yeehaw! How y'al doin' now?",
          "Whether you're up or way down low, don't you miss the LUCKY NUMBER SHOW!",
          _INTL("This week's Lucky Number is {1}!",number),
          _INTL("I'll repeat that! This week's Lucky Number is {1}!",number),
          "Match it and go to the RADIO TOWER!"
          ]
  array = pbGetRadioFormatLine(window,loop,loop)
  return array
end
################################################################################
# Places & People
################################################################################
def pbGetPlacesnPeopleCh(window)
  pbBGMPlay(PLACESNPEOPLE_BGM, 100, 100)
  text2 = [
    "is actually great.",
    "is always happy.",
    "is cute",
    "is definitely odd!",
    "is inspiring!",
    "is just my type.",
    "is just so-so.",
    "is kind of weird.",
    "is precocious.",
    "is quite noisy.",
    "is right for me?",
    "is so cool, no?",
    "is sort of OK.",
    "is sort of lazy.",
    "is somewhat bold.",
    "is too picky!",
  ]
  loop = []
  trainers = pbLoadTrainersData
  2.times do
    if rand(100) < 50
      # Place
      mapdata = pbLoadTownMapData
      data = mapdata[-1][2]
      name = data[rand(data.length)][2]
      #id = MAPID_IN_POKEGEAR[rand(MAPID_IN_POKEGEAR.length)]
      #name = pbGetBasicMapNameFromId(id)
    else
      # Trainer
      randtrainer = []
      loop do
        randtrainer = trainers[rand(trainers.length)]
        break if TRAINERTYPE_IN_RADIO.include?(randtrainer[0])
      end
      trainertype = randtrainer[0]
      trainername = randtrainer[1]
      name = _INTL("{1} {2}",PBTrainers.getName(trainertype),
       pbGetMessageFromHash(MessageTypes::TrainerNames,trainername))
    end
    adj = text2[rand(text2.length)]
    loop.push(_INTL("{1} {2}!",name.upcase,adj))
  end
  intro = ["Lily : PLACES AND PEOPLE!",
           "Brought to you by me, DJ LILY!"
          ]
  array = pbGetRadioFormatLine(window,loop,intro)
  return array
end
################################################################################
# Team Rocket Take Over the Radio
################################################################################
def pbGetRocketTakeOverCh(window)
  pbBGMPlay(TEAMROCKET_BGM, 100, 100)
  loop = ["... ...Ahem,","we are TEAM ROCKET!",
          "After three years of preparation,",
          "we have risen again from the ashes!",
          "GIOVANNI!",
          "Can you hear?",
          "We did it!",
          "Where is our Boss?",
          "Is he listening?"
          ]
  array = pbGetRadioFormatLine(window,loop,loop)
  return array
end