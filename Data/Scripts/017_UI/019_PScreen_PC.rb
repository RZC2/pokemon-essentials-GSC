#===============================================================================
# PC menus
#===============================================================================
def pbPCItemStorage
  command = 0
  loop do
    command = pbShowCommandsWithHelp(nil,
       [_INTL("WITHDRAW ITEM"),
       _INTL("DEPOSIT ITEM"),
       _INTL("TOSS ITEM"),
       _INTL("LOG OFF")],
       [_INTL("Take out items."),
       _INTL("Store items."),
       _INTL("Throw away items."),
       _INTL("")],-1,command
    )
    case command
    when 0   # Withdraw Item
      if !$PokemonGlobal.pcItemStorage
        $PokemonGlobal.pcItemStorage = PCItemStorage.new
      end
      if $PokemonGlobal.pcItemStorage.empty?
        pbMessage(_INTL("There are no items."))
      else
        pbFadeOutIn {
          scene = WithdrawItemScene.new
          screen = PokemonBagScreen.new(scene,$PokemonBag)
          screen.pbWithdrawItemScreen
        }
      end
    when 1   # Deposit Item
      pbFadeOutIn {
        scene = PokemonBag_Scene.new
        screen = PokemonBagScreen.new(scene,$PokemonBag)
        screen.pbDepositItemScreen
      }
    when 2   # Toss Item
      if !$PokemonGlobal.pcItemStorage
        $PokemonGlobal.pcItemStorage = PCItemStorage.new
      end
      if $PokemonGlobal.pcItemStorage.empty?
        pbMessage(_INTL("There are no items."))
      else
        pbFadeOutIn {
          scene = TossItemScene.new
          screen = PokemonBagScreen.new(scene,$PokemonBag)
          screen.pbTossItemScreen
        }
      end
    else
      break
    end
  end
end

def pbPCMailbox
  if !$PokemonGlobal.mailbox || $PokemonGlobal.mailbox.length==0
    pbMessage(_INTL("There's no Mail here."))
  else
    loop do
      command = 0
      commands=[]
      for mail in $PokemonGlobal.mailbox
        commands.push(mail.sender)
      end
      commands.push(_INTL("CANCEL"))
      command = pbShowCommands(nil,commands,-1,command)
      if command>=0 && command<$PokemonGlobal.mailbox.length
        mailIndex = command
        commandMail = pbMessage(_INTL("What do you want to do with {1}'s Mail?",
           $PokemonGlobal.mailbox[mailIndex].sender),[
           _INTL("READ"),
           _INTL("MOVE TO BAG"),
           _INTL("GIVE"),
           _INTL("CANCEL")
           ],-1)
        case commandMail
        when 0   # Read
          pbFadeOutIn {
            pbDisplayMail($PokemonGlobal.mailbox[mailIndex])
          }
        when 1   # Move to Bag
          if pbConfirmMessage(_INTL("The message will be lost. Is that OK?"))
            if $PokemonBag.pbStoreItem($PokemonGlobal.mailbox[mailIndex].item)
              pbMessage(_INTL("The Mail was returned to the Bag with its message erased."))
              $PokemonGlobal.mailbox.delete_at(mailIndex)
            else
              pbMessage(_INTL("The BAG is full."))
            end
          end
        when 2   # Give
          pbFadeOutIn {
            sscene = PokemonParty_Scene.new
            sscreen = PokemonPartyScreen.new(sscene,$Trainer.party)
            sscreen.pbPokemonGiveMailScreen(mailIndex)
          }
        end
      else
        break
      end
    end
  end
end

def pbTrainerPCMenu
  command = 0
  loop do
    command = pbMessage(_INTL("What do you want to do?"),[
       _INTL("ITEM STORAGE"),
       _INTL("MAILBOX"),
       _INTL("LOG OFF")
       ],-1,nil,command)
    case command
    when 0; pbPCItemStorage
    when 1; pbPCMailbox
    else; break
    end
  end
end



class TrainerPC
  def shouldShow?
    return true
  end

  def name
    return _INTL("{1}'s PC",$Trainer.name)
  end

  def access
    pbMessage(_INTL("\\se[PC access]Accessed own PC."))
	pbMessage(_INTL("Item Storage System opened."))
    pbTrainerPCMenu
  end
end



def pbGetStorageCreator
  creator = pbStorageCreator
  creator = _INTL("BILL") if !creator || creator==""
  return creator
end



class StorageSystemPC
  def shouldShow?
    return true
  end

  def name
    if $PokemonGlobal.seenStorageCreator
      return _INTL("{1}'s PC",pbGetStorageCreator)
    else
      return _INTL("SOMEONE's PC")
    end
  end

  def access
  if $PokemonGlobal.seenStorageCreator
    pbMessage(_INTL("\\se[PC access]{1}'s PC accessed.",pbGetStorageCreator))
  else
    pbMessage(_INTL("\\se[PC access]SOMEONE'S PC accessed."))
  end
    pbMessage(_INTL("POKéMON Storage System opened."))
    command = 0
    loop do
      command = pbShowCommandsWithHelp(nil,
         [_INTL("ORGANIZE BOXES"),
         _INTL("WITHDRAW {}"),
         _INTL("DEPOSIT {}"),
         _INTL("SEE YA!")],
         [_INTL("What?"),
         _INTL("What?"),
         _INTL("What?"),
         _INTL("What?")],-1,command
      )
      if command>=0 && command<3
        if command==1   # Withdraw
          if $PokemonStorage.party.length>=6
            pbMessage(_INTL("Your party is full!"))
            next
          end
        elsif command==2   # Deposit
          count=0
          for p in $PokemonStorage.party
            count += 1 if p && !p.egg? && p.hp>0
          end
          if count<=1
            pbMessage(_INTL("Can't deposit the last POKéMON!"))
            next
          end
        end
        pbFadeOutIn {
          scene = PokemonStorageScene.new
          screen = PokemonStorageScreen.new(scene,$PokemonStorage)
          screen.pbStartScreen(command)
        }
      else
        break
      end
    end
  end
end



def pbTrainerPC
  pbMessage(_INTL("\\se[PC open]{1} turned on the PC.",$Trainer.name))
  pbTrainerPCMenu
  pbSEPlay("PC close")
end

def pbPokeCenterPC
  pbMessage(_INTL("\\se[PC open]{1} turned on the PC.",$Trainer.name))
  command = 0
  loop do
    commands = PokemonPCList.getCommandList
    command = pbMessage(_INTL("Access whose PC?"),commands,
       commands.length,nil,command)
    break if !PokemonPCList.callCommand(command)
  end
  pbSEPlay("PC close")
end



module PokemonPCList
  @@pclist = []

  def self.registerPC(pc)
    @@pclist.push(pc)
  end

  def self.getCommandList
    commands = []
    for pc in @@pclist
      commands.push(pc.name) if pc.shouldShow?
    end
    commands.push(_INTL("TURN OFF"))
    return commands
  end

  def self.callCommand(cmd)
    return false if cmd<0 || cmd>=@@pclist.length
    i = 0
    for pc in @@pclist
      next if !pc.shouldShow?
      if i==cmd
        pc.access
        return true
      end
      i += 1
    end
    return false
  end
end



PokemonPCList.registerPC(StorageSystemPC.new)
PokemonPCList.registerPC(TrainerPC.new)
