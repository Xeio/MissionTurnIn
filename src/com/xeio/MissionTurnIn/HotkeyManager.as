class com.xeio.MissionTurnIn.HotkeyManager
{
    public static function MissionReportHotkey()
	{
        GUI.Mission.MissionSignals.SignalMissionReportSent.Emit();
    }
}