begin
  module PBStats
    # NOTE: You can change the order that the compiler expects Pokémon base
    #       stats/EV yields (effort points) to be in, by simply renumbering the
    #       stats here. The "main" stats (i.e. not accuracy/evasion) must still
    #       use up numbers 0 to 5 inclusive, though. It's up to you to write the
    #       base stats/EV yields in pokemon.txt and pokemonforms.txt in the
    #       order expected.
    HP       = 0
    ATTACK   = 1
    DEFENSE  = 2
    SPEED    = 3
    SPATK    = 4
    SPDEF    = 5
    ACCURACY = 6
    EVASION  = 7

    def self.getName(id)
      id = getID(PBStats,id)
      names = []
      names[HP]       = _INTL("HP")
      names[ATTACK]   = _INTL("ATTACK")
      names[DEFENSE]  = _INTL("DEFENSE")
      names[SPEED]    = _INTL("SPEED")
      names[SPATK]    = _INTL("SPCL. ATK")
      names[SPDEF]    = _INTL("SPCL. DEF")
      names[ACCURACY] = _INTL("accuracy")
      names[EVASION]  = _INTL("evasiveness")
      return names[id]
    end

    def self.getNameBrief(id)
      id = getID(PBStats,id)
      names = []
      names[HP]       = _INTL("HP")
      names[ATTACK]   = _INTL("ATK")
      names[DEFENSE]  = _INTL("DEF")
      names[SPEED]    = _INTL("SPD")
      names[SPATK]    = _INTL("SPATK")
      names[SPDEF]    = _INTL("SPDEF")
      names[ACCURACY] = _INTL("acc")
      names[EVASION]  = _INTL("eva")
      return names[id]
    end

    def self.eachStat
      [HP,ATTACK,DEFENSE,SPATK,SPDEF,SPEED].each { |s| yield s }
    end

    def self.eachMainBattleStat
      [ATTACK,DEFENSE,SPATK,SPDEF,SPEED].each { |s| yield s }
    end

    def self.eachBattleStat
      [ATTACK,DEFENSE,SPATK,SPDEF,SPEED,ACCURACY,EVASION].each { |s| yield s }
    end

    def self.validBattleStat?(stat)
      self.eachBattleStat { |s| return true if s==stat }
      return false
    end
  end

rescue Exception
  if $!.is_a?(SystemExit) || "#{$!.class}"=="Reset"
    raise $!
  end
end
