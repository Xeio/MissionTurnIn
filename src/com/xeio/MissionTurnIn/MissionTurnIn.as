import com.GameInterface.Quests;
import com.Utils.Archive;
import com.xeio.MissionTurnIn.Utils;
import mx.utils.Delegate;


class com.xeio.MissionTurnIn.MissionTurnIn
{    
    private var m_swfRoot: MovieClip;
    private var m_savedMissions: Array = [];
    
    private var MISSION_IDS: String = "MISSION_IDS";

    public static function main(swfRoot:MovieClip):Void 
    {
        var missionTurnIn = new MissionTurnIn(swfRoot);

        swfRoot.onLoad = function() { missionTurnIn.OnLoad(); };
        swfRoot.OnUnload =  function() { missionTurnIn.OnUnload(); };
        swfRoot.OnModuleActivated = function(config:Archive) { missionTurnIn.Activate(config); };
        swfRoot.OnModuleDeactivated = function() { return missionTurnIn.Deactivate(); };
    }

    public function MissionTurnIn(swfRoot: MovieClip) 
    {
        m_swfRoot = swfRoot;
    }

    public function OnUnload()
    {
        GUI.Mission.MissionSignals.SignalMissionReportSent.Connect(_root.missionrewardcontroller.SlotMissionReportSent, _root.missionrewardcontroller);
        GUI.Mission.MissionSignals.SignalMissionReportSent.Disconnect(OnSignalMissionReportSent, this);
        com.GameInterface.Input.RegisterHotkey(148, "", _global.Enums.Hotkey.eHotkeyDown, 0);
    }
	
    public function Activate(config: Archive)
    {
        m_savedMissions = config.FindEntryArray(MISSION_IDS) || [];
    }
    
    public function Deactivate(): Archive
    {
        var archive: Archive = new Archive();
        
		for (var i = 0; i < m_savedMissions.length; i++ )
		{
			archive.AddEntry(MISSION_IDS, m_savedMissions[i]);
		}
        
        return archive;
    }
    
    public function OnLoad()
    {		
        setTimeout(Delegate.create(this, Initialize), 1000);
    }
    
    function Initialize()
    {
        GUI.Mission.MissionSignals.SignalMissionReportSent.Disconnect(_root.missionrewardcontroller.SlotMissionReportSent, _root.missionrewardcontroller);
        GUI.Mission.MissionSignals.SignalMissionReportSent.Connect(OnSignalMissionReportSent, this);
        com.xeio.MissionTurnIn.HotkeyManager.MissionTurnIn = this;
        com.GameInterface.Input.RegisterHotkey(148, "com.xeio.MissionTurnIn.HotkeyManager.MissionReportHotkey", _global.Enums.Hotkey.eHotkeyDown, 0);
    }
    
    function OnSignalMissionReportSent()
    {
        var listChanged:Boolean = false;
        if (!Key.isDown(Key.SHIFT))
        {
            var rewardList:Array = Quests.GetAllRewards();
            for (var i in rewardList)
            {
                var reward = rewardList[i];

                if (reward.m_OptionalRewards.length > 0) continue; //Don't auto-handle missions with an optional reward

                var questId = reward.m_QuestTaskID;
                
                if (Utils.Contains(m_savedMissions, questId))
                {
                    Quests.AcceptQuestReward(questId, 0);
                    listChanged = true;
                }
            }
        }
        
        if (listChanged)
        {
            //If we updated the list, give the server a moment to respond with reports
            setTimeout(Delegate.create(this, CallBaseMissionReportSent), 500);
        }
        else
        {
            CallBaseMissionReportSent();
        }
    }
    
    function CallBaseMissionReportSent()
    {
        _root.missionrewardcontroller.SlotMissionReportSent(_root.missionrewardcontroller);
        
        setTimeout(Delegate.create(this, HookIntoCollectButton), 500);
    }
    
    function HookIntoCollectButton()
    {
        var windows:Array = _root.missionrewardcontroller.m_RewardWindows;
        for (var i in windows)
        {
            var rewardWindow:MovieClip = windows[i];
            rewardWindow.m_Content.m_CollectButton.addEventListener("click", this, "CollectButtonClicked");
        }
    }
    
    function CollectButtonClicked(event:Object)
    {
        var questId:Number = event.target._parent.m_QuestID;
        if (!Utils.Contains(m_savedMissions, questId))
        {
            m_savedMissions.push(questId);
        }
    }
}