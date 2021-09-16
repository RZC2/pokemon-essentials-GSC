module PBNatures
  HARDY   = 0
  LONELY  = 1
  BRAVE   = 2
  ADAMANT = 3
  NAUGHTY = 4
  BOLD    = 5
  DOCILE  = 6
  RELAXED = 7
  IMPISH  = 8
  LAX     = 9
  TIMID   = 10
  HASTY   = 11
  SERIOUS = 12
  JOLLY   = 13
  NAIVE   = 14
  MODEST  = 15
  MILD    = 16
  QUIET   = 17
  BASHFUL = 18
  RASH    = 19
  CALM    = 20
  GENTLE  = 21
  SASSY   = 22
  CAREFUL = 23
  QUIRKY  = 24

  def self.maxValue; 24; end
  def self.getCount; 25; end

  def self.getName(id)
    id = getID(PBNatures,id)
    names = [
       _INTL("HARDY"),
       _INTL("LONELY"),
       _INTL("BRAVE"),
       _INTL("ADAMANT"),
       _INTL("NAUGHTY"),
       _INTL("BOLD"),
       _INTL("DOCILE"),
       _INTL("RELAXED"),
       _INTL("IMPISH"),
       _INTL("LAX"),
       _INTL("TIMID"),
       _INTL("HASTY"),
       _INTL("SERIOUS"),
       _INTL("JOLLY"),
       _INTL("NAIVE"),
       _INTL("MODEST"),
       _INTL("MILD"),
       _INTL("QUIET"),
       _INTL("BASHFUL"),
       _INTL("RASH"),
       _INTL("CALM"),
       _INTL("GENTLE"),
       _INTL("SASSY"),
       _INTL("CAREFUL"),
       _INTL("QUIRKY")
    ]
    return names[id]
  end

  def self.getStatRaised(id)
    m = (id%25)/5   # 25 here is (number of stats)**2, not PBNatures.getCount
    return [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
            PBStats::SPATK,PBStats::SPDEF][m]
  end

  def self.getStatLowered(id)
    m = id%5   # Don't need to %25 here because 25 is a multiple of 5
    return [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
            PBStats::SPATK,PBStats::SPDEF][m]
  end

  def self.getStatChanges(id)
    id = getID(PBNatures,id)
    up = PBNatures.getStatRaised(id)
    dn = PBNatures.getStatLowered(id)
    ret = []
    PBStats.eachStat do |s|
      ret[s] = 100
      ret[s] += 10 if s==up
      ret[s] -= 10 if s==dn
    end
    return ret
  end
end
