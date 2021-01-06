objectdef basiclauncherSettings
{
   variable filepath GlobalFolder="${LavishScript.HomeDirectory}"
   variable filepath AgentFolder="${Script.CurrentDirectory}"
    
    variable uint LaunchSlots=3
    variable uint LaunchSlots2=3
    variable string UseGame
    variable string UseGame2
    variable string UseAgent1
    variable string UseLayout1
    variable jsonvalue UseLayout2

    method Initialize()
    {    
        This:Load
        This:LoadSettings
    }

    method Load()
    {
        variable jsonvalue jo
        if !${AgentFolder.FileExists[bl.Settings.json]}
            return

        if !${jo:ParseFile["${AgentFolder~}/bl.Settings.json"](exists)} || !${jo.Type.Equal[object]}
        {
            return
        }

        if ${jo.Has[launchSlots]}
            LaunchSlots:Set["${jo.Get[launchSlots]~}"]

        if ${jo.Has[useGame]}
            UseGame:Set["${jo.Get[useGame]~}"]
    }

    method Store()
    {
        variable jsonvalue jo
        jo:SetValue["${This.AsJSON~}"]
        jo:WriteFile["${AgentFolder~}/bl.Settings.json",multiline]
    }

    member AsJSON()
    {
        variable jsonvalue jo
        jo:SetValue["$$>
        {
            "launchSlots":${LaunchSlots.AsJSON~},
            "useGame":${UseGame.AsJSON~},
        }
        <$$"]
        return "${jo.AsJSON~}"
    }

    method LoadSettings()
    {
        variable jsonvalue ja

        if !${GlobalFolder.FileExists[Agents\\settings.json]}
            return
        if !${ja:ParseFile["${GlobalFolder~}/Agents/settings.json"](exists)} || !${ja.Type.Equal[object]}
        {
            return
        }
        if ${ja.Has[launchSlots]}
            LaunchSlots2:Set["${ja.Get[launchSlots]~}"]
        if ${ja.Has[useGame]}
            UseGame2:Set["${ja.Get[useGame]~}"]
        if ${ja.Has[agents]}
            UseAgent1:Set["${ja.Get[agents]~}"]
        if ${ja.Has[layouts]}
            UseLayout1:Set["${ja.Get[layouts]~}"]
        variable jsonvalue use

        if ${ja.Has[uselayout]}
            use:Set["${ja.Get[uselayout]~}"]
        if ${use.Has[use]}
            UseLayout2:SetValue["${use.Get[use]~}"]
    }

    method StoreSettings()
    {
        variable jsonvalue ja
        ja:SetValue["${This.AsJSONsettings~}"]
        ja:WriteFile["${GlobalFolder~}/Agents/bwl.config.json",multiline]
    }

    member AsJSONsettings()
    {
        variable jsonvalue ja
        ja:SetValue["$$>
        {
            "launchSlots":${LaunchSlots2.AsJSON~},
            "useGame":${UseGame2.AsJSON~},
            "agents":${UseAgent1.AsJSON~},
            "layouts":${UseLayout1.AsJSON~}
            "uselayout":${UseLayout2.AsJSON~}
        }
        <$$"]
        return "${ja.AsJSON~}"
    }
}

objectdef basiclauncher
{
    variable filepath GlobalFolder="${LavishScript.HomeDirectory}"
    
    variable basiclauncherSettings Settings
    variable bool ReplaceSlots=TRUE
    variable jsonvalue Games="[]"
    variable jsonvalue Games2="[]"
    variable jsonvalue Agents1="[]"
    variable jsonvalue Agents2="[]"
    variable jsonvalue Agents3="[]"
    variable jsonvalue Layout1="[]"
    variable jsonvalue Layout2="[]"
    
    method Initialize()
    {
        LavishScript:RegisterEvent[GamesChanged]
        LavishScript:RegisterEvent[SettingsChanged]
        LavishScript:RegisterEvent[LayoutChanged]
        Event[GamesChanged]:AttachAtom[This:RefreshGames]
        Event[SettingsChanged]:AttachAtom[This:RefreshSettings]
        Event[LayoutChanged]:AttachAtom[This:RefreshLayout]

        Settings:Store
        Settings:StoreSettings
        This:RefreshGames
        This:RefreshSettings

        LGUI2:LoadPackageFile[BasicLauncher.Uplink.lgui2Package.json]
    }

    method Shutdown()
    {
        LGUI2:UnloadPackageFile[BasicLauncher.Uplink.lgui2Package.json]
    }

    method InstallCharacter(uint Slot)
    {
        variable string UseGameProfile="${Settings.UseGame~} Default Profile"

        variable jsonvalue jo
        jo:SetValue["$$>
        {
            "id":${Slot},
            "display_name":"Generic Character",
            "game":${Settings.UseGame.AsJSON~},
            "gameProfile":${UseGameProfile.AsJSON~}
            "virtualFiles":[
                {
                    "pattern":"*/Config.WTF",
                    "replacement":"{1}/Config.Generic.JMB${Slot}.WTF"
                },
                {
                    "pattern":"Software/Blizzard Entertainment/World of Warcraft/Client/\*",
                    "replacement":"Software/Blizzard Entertainment/World of Warcraft/Client-JMB${Slot}/{1}"
                }
            ]
        }
        <$$"]
        JMB:AddCharacter["${jo.AsJSON~}"]
    }

    method Launch()
    {
        LGUI2.Element[bl.launchSlots]:PushTextBinding
        

        if ${ReplaceSlots}
        {
            JMB.Slots:ForEach["kill jmb\${ForEach.Value.Get[id]}"]
            JMB:ClearSlots
        }

        variable uint Slot
        variable uint NumAdded
        for (NumAdded:Set[1] ; ${NumAdded}<=${Settings.LaunchSlots} ; NumAdded:Inc)
        {
            Slot:Set["${JMB.AddSlot.ID}"]
            This:InstallCharacter[${Slot}]
            JMB.Slot[${Slot}]:SetCharacter[${Slot}]
            JMB.Slot[${Slot}]:Launch
        }
        timedcommand 60 BWLUplink:ApplyWindowLayout
    }

    method Relaunch(uint numSlot)
    {
        if !${JMB.Slot[${numSlot}].ProcessID}
            JMB.Slot[${numSlot}]:Launch
    }
    
    method RelaunchMissingSlots()
    {
        JMB.Slots:ForEach["This:Relaunch[\${ForEach.Value.Get[id]}]"]
    }


    method SetGame(string newValue)
    {
        if ${newValue.Equal["${Settings.UseGame~}"]}
            return

        Settings.UseGame:Set["${newValue~}"]
        Settings:Store
    }

    method SetLaunchSlots(uint newValue)
    {
        if ${newValue}==${Settings.LaunchSlots}
            return
        Settings.LaunchSlots:Set[${newValue}]
        Settings:Store
    }

     method SetUseLayout(string newValue)
    {
         if ${newValue.Equal["${BWLSettings.UseLayout~}"]}
            return
        Settings.UseLayout2:Set["${newValue~}"]
        Settings:StoreSettings
        BWLSettings:Initialize
        BWLSession:UpdateCurrentLayout
    }

    method SetAgents(string newValue)
    {
        switch ${newValue}
        {
            case Basic Global Hotkeys
                LGUI2.Element[basicWindowLayout.window]:SetVisibility[hidden]
                LGUI2.Element[basicRoundRobin.window]:SetVisibility[hidden]
                LGUI2.Element[basicPerformance.window]:SetVisibility[hidden]
                LGUI2.Element[basicGlobalHotkeys.window]:SetVisibility[visible]
                break
            case Basic Performance
                LGUI2.Element[basicWindowLayout.window]:SetVisibility[hidden]
                LGUI2.Element[basicRoundRobin.window]:SetVisibility[hidden]
                LGUI2.Element[basicGlobalHotkeys.window]:SetVisibility[hidden]
                LGUI2.Element[basicPerformance.window]:SetVisibility[visible]
                break
            case Basic Round-Robin
                LGUI2.Element[basicWindowLayout.window]:SetVisibility[hidden]
                LGUI2.Element[basicPerformance.window]:SetVisibility[hidden]
                LGUI2.Element[basicGlobalHotkeys.window]:SetVisibility[hidden]
                LGUI2.Element[basicRoundRobin.window]:SetVisibility[visible]
                break
            case Basic Window Layout
                LGUI2.Element[basicRoundRobin.window]:SetVisibility[hidden]
                LGUI2.Element[basicPerformance.window]:SetVisibility[hidden]
                LGUI2.Element[basicGlobalHotkeys.window]:SetVisibility[hidden]
                LGUI2.Element[basicWindowLayout.window]:SetVisibility[visible]
                break
            default
            case Reload
                BGHUplink:Initialize
                BPUplink:Initialize
                BRRUplink:Initialize
                BWLUplink:Initialize
                LGUI2.Element[basicGlobalHotkeys.window]:SetVisibility[hidden]
                LGUI2.Element[basicPerformance.window]:SetVisibility[hidden]
                LGUI2.Element[basicRoundRobin.window]:SetVisibility[hidden]
                LGUI2.Element[basicWindowLayout.window]:SetVisibility[hidden]
                break
        }
    }

    method AllFullScreen()
    {
        relay all "WindowCharacteristics -pos -viewable ${Display.Monitor.Left},${Display.Monitor.Top} -size -viewable ${Display.Monitor.Width}x${Display.Monitor.Height} -frame none"
    }

    method ShowConsoles()
    {
        relay all "LGUI2.Element[consoleWindow]:SetVisibility[Visible]"
    }

    method CloseAll()
    {
        relay all exit
    }

    method GenerateItemView_Game()
	{
       ; echo GenerateItemView_Game ${Context(type)} ${Context.Args}

		; build an itemview lgui2element json
		variable jsonvalue joListBoxItem
		joListBoxItem:SetValue["${LGUI2.Template["BasicLauncher.gameView"].AsJSON~}"]
        		
		Context:SetView["${joListBoxItem.AsJSON~}"]
	}

    method GenerateItemView_Agents()
	{

		; build an itemview lgui2element json
		variable jsonvalue jaListBoxItem
		jaListBoxItem:SetValue["${LGUI2.Template["BasicLauncher.agentView"].AsJSON~}"]
        		
		Context:SetView["${jaListBoxItem.AsJSON~}"]
	}

    method GenerateItemView_Layout()
	{

		; build an itemview lgui2element json
		variable jsonvalue joListBoxItem
		joListBoxItem:SetValue["${LGUI2.Template["BasicLauncher.layoutView"].AsJSON~}"]
        		
		Context:SetView["${joListBoxItem.AsJSON~}"]
	}

    method RefreshGames()
    {
        variable jsonvalue jo="${JMB.GameConfiguration.AsJSON~}"
        jo:Erase["_set_guid"]

        variable jsonvalue jaKeys
        jaKeys:SetValue["${jo.Keys.AsJSON~}"]
        jo:SetValue["[]"]

        variable uint i
        for (i:Set[1] ; ${i}<=${jaKeys.Used} ; i:Inc)
        {
            jo:Add["$$>
            {
                "display_name":${jaKeys[${i}].AsJSON~}
            }
            <$$"]
        }
    
        Games:SetValue["${jo.AsJSON~}"]
        LGUI2.Element[BasicLauncher.events]:FireEventHandler[onGamesUpdated]
    }

    method RefreshSettings()
    {
        Agents1:SetValue["${Settings.UseAgent1~}"]
        Layout1:SetValue["${Settings.UseLayout1~}"]
        Layout2:SetValue["${Settings.UseLayout2~}"]
        BWLSession.Settings.UseLayout:SetValue["${Settings.UseLayout2~}"]

        LGUI2.Element[BasicLauncher.events]:FireEventHandler[onSettingsUpdated]
        Settings:StoreSettings
    }
}

variable(global) basiclauncher BasicLauncher

function main()
{
    while 1
        waitframe
}