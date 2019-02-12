#NoTrayIcon
#RequireAdmin
#AutoIt3Wrapper_Res_Fileversion=0.0.4.0

#include <AutoItConstants.au3>
#include <TrayConstants.au3>
#include <MsgBoxConstants.au3>
#include <ProcessConstants.au3>
#include <SecurityConstants.au3>
#include <Security.au3>
#include <WinAPI.au3>
#include <WinAPIProc.au3>

Opt("TrayMenuMode", 3)

Global Const $iconFile = "shell32.dll"
Global Const $idIconError = -110
Global Const $idIconRunning = -138
Global Const $idIconPaused = -245

Global $sTaskDir = ''
Global $sTaskName = 'PrimoCacheBackupDetect'
Global $sTaskFullName = $sTaskDir & '\' & $sTaskName

ReadConfig()
PrimoCacheBackupDetect()

Func ReadConfig()
	Global Const $configFile = @ScriptDir & "\PrimoCacheBackupDetect.ini"
	Global $configInterval = Int(IniRead($configFile, "Config", "Interval", "60000"))
	Global $configProcess = IniRead($configFile, "Config", "Process", "backupService-ab.exe")
	Global $configThreshold = Int(IniRead($configFile, "Config", "Threshold", "50000000"))
	Global $configPauseCmd = IniRead($configFile, "Config", "PauseCmd", '"C:\Program Files\PrimoCache\rxpcc.exe" pause -s -a')
	Global $configResumeCmd = IniRead($configFile, "Config", "ResumeCmd", '"C:\Program Files\PrimoCache\rxpcc.exe" resume -s -a')
EndFunc

Func PrimoCacheBackupDetect()
	Local $idCheckProcess = TrayCreateItem("Check Process")
	Global $idTask = TrayCreateItem("-")
	RenameTrayTask()
	Local $idExit = TrayCreateItem("Exit")
	
	TraySetIcon($iconFile, $idIconRunning)
	TraySetToolTip("PrimoCache running, no Backup-Process detected.")
	TraySetState($TRAY_ICONSTATE_SHOW)

	Local $hTimer = TimerInit() ; Begin the timer and store the handle in a variable.
	Local $fDiff = 0
	Local $isRunning = 0, $wasRunning = 0
	
	Local $processList

	While 1
	$fDiff = TimerDiff($hTimer) ; Find the difference in time from the previous call of TimerInit
	If $fDiff > $configInterval Then ; If the difference is greater than interval then check if the named process is running
		TraySetState($TRAY_ICONSTATE_SHOW) ; try to show the trayicon if it has not been initialized correctly on startup, due to a premature boot via scheduled tasks
		$isRunning = 0
		If ProcessExists($configProcess) Then ; Check if the process is running.
			Local $pData = GetProcessDetails($configProcess)
			If $pData <> False Then
				If $pData[2] > $configThreshold Then
					$isRunning = 1
				EndIf
			EndIf
		EndIf
		If $isRunning == 1 Then
			If $wasRunning == 0 Then
				PauseCache()
			EndIf
			$wasRunning = 1
		Else
			If $wasRunning == 1 Then
				ResumeCache()
			EndIf
			$wasRunning = 0
		EndIf
		$hTimer = TimerInit() ; Reset the timer.
	EndIf

	Switch TrayGetMsg()
		Case $idExit ; Exit the loop.
			ExitLoop
		Case $idCheckProcess
			CheckProcess()
		Case $idTask
			If IsTaskInstalled() Then
				If Not UninstallTask() Then
					MsgBox(BitOR($MB_SYSTEMMODAL, $MB_ICONERROR), "Error!", "Could not remove Autostart!")
				EndIf
			Else
				If MsgBox($MB_ICONQUESTION + $MB_YESNO, 'Proceed with Installation?', 'This will install a new scheduled Task to run this Program on boot.' & @CRLF & 'The Program has to remain at the current location which is: ' &  @ScriptFullPath & @CRLF & @CRLF & 'Do you want to proceed?') = $IDYES Then
					If Not InstallTask() Then
						MsgBox(BitOR($MB_SYSTEMMODAL, $MB_ICONERROR), "Error!", "Could not create Autostart!")
					EndIf
				EndIf
			EndIf
			RenameTrayTask()
	EndSwitch
	WEnd
EndFunc

Func PauseCache()
	Local $iPID = Run(@ComSpec & ' /C ' & $configPauseCmd, @SystemDir, @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
	ProcessWaitClose($iPID)
	Local $sOutput = StdoutRead($iPID)
	Local $sError = StderrRead($iPID)
	If $sError <> "" Then
		TraySetToolTip("Could not switch PrimoCache! An Error occured!")
		TraySetIcon($iconFile, $idIconError)
		MsgBox(BitOR($MB_SYSTEMMODAL, $MB_ICONERROR), "Could not pause the PrimoCache!", $sError)
	Else
		TraySetToolTip("PrimoCache paused, Process " & $configProcess & " is running.")
		TraySetIcon($iconFile, $idIconPaused)
	EndIf
EndFunc

Func ResumeCache()
	Local $iPID = Run(@ComSpec & ' /C ' & $configResumeCmd, @SystemDir, @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
	ProcessWaitClose($iPID)
	Local $sOutput = StdoutRead($iPID)
	Local $sError = StderrRead($iPID)
	If $sError <> "" Then
		TraySetToolTip("Could not switch PrimoCache! An Error occured!")
		TraySetIcon($iconFile, $idIconError)
		MsgBox(BitOR($MB_SYSTEMMODAL, $MB_ICONERROR), "Could not resume the PrimoCache!", $sError)
	Else
		TraySetToolTip("PrimoCache running, no Backup-Process detected.")
		TraySetIcon($iconFile, $idIconRunning)
	EndIf
EndFunc

Func CheckProcess()
	If ProcessExists($configProcess) Then
		Local $pData = GetProcessDetails($configProcess)
		If $pData == False Then Return False
		
		MsgBox($MB_SYSTEMMODAL, "Process-Details", $configProcess & @CRLF & "number of page faults: " & $pData[0] & @CRLF & "The peak working set size, in bytes: " & $pData[1] & @CRLF & "current working set size, in bytes: " & $pData[2] & @CRLF & "peak paged pool usage, in bytes: " & $pData[3] & @CRLF & "current paged pool usage, in bytes: " & $pData[4] & @CRLF & "peak nonpaged pool usage, in bytes: " & $pData[5] & @CRLF & "current nonpaged pool usage, in bytes: " & $pData[6] & @CRLF & "current space allocated for the pagefile, in bytes: " & $pData[7] & @CRLF & "peak space allocated for the pagefile, in bytes: " & $pData[8] & @CRLF & "current amount of memory that cannot be shared with other processes, in bytes: " & $pData[9])
		If $pData[2] > $configThreshold Then
			MsgBox($MB_SYSTEMMODAL, "Threshold reached", "The process " & $configProcess & " has reached the configured Threshold of " & $configThreshold & " Bytes.")
		Else
			MsgBox($MB_SYSTEMMODAL, "Threshold not reached", "The process " & $configProcess & " has not reached the configured Threshold of " & $configThreshold & " Bytes.")
		EndIf
	Else
		MsgBox($MB_SYSTEMMODAL, "Process not running", "The configured process " & $configProcess & " is not running.")
	EndIf
EndFunc

Func InstallTask()
	Local $sXML = _
		'<?xml version="1.0" encoding="UTF-16"?>' & @CRLF & _
		'<Task version="1.3" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">' & @CRLF & _
		'  <Triggers>' & @CRLF & _
		'    <LogonTrigger>' & @CRLF & _
		'      <Enabled>true</Enabled>' & @CRLF & _
		'      <Delay>PT1M</Delay>' & @CRLF & _
		'    </LogonTrigger>' & @CRLF & _
		'  </Triggers>' & @CRLF & _
		'  <Principals>' & @CRLF & _
		'    <Principal id="Author">' & @CRLF & _
		'      <GroupId>S-1-1-0</GroupId>' & @CRLF & _
		'      <RunLevel>HighestAvailable</RunLevel>' & @CRLF & _
		'    </Principal>' & @CRLF & _
		'  </Principals>' & @CRLF & _
		'  <Settings>' & @CRLF & _
		'    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>' & @CRLF & _
		'    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>' & @CRLF & _
		'    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>' & @CRLF & _
		'    <AllowHardTerminate>true</AllowHardTerminate>' & @CRLF & _
		'    <StartWhenAvailable>false</StartWhenAvailable>' & @CRLF & _
		'    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>' & @CRLF & _
		'    <IdleSettings>' & @CRLF & _
		'      <StopOnIdleEnd>false</StopOnIdleEnd>' & @CRLF & _
		'      <RestartOnIdle>false</RestartOnIdle>' & @CRLF & _
		'    </IdleSettings>' & @CRLF & _
		'    <AllowStartOnDemand>true</AllowStartOnDemand>' & @CRLF & _
		'    <Enabled>true</Enabled>' & @CRLF & _
		'    <Hidden>false</Hidden>' & @CRLF & _
		'    <RunOnlyIfIdle>false</RunOnlyIfIdle>' & @CRLF & _
		'	<DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>' & @CRLF & _
		'	<UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>' & @CRLF & _
		'    <WakeToRun>false</WakeToRun>' & @CRLF & _
		'    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>' & @CRLF & _
		'    <Priority>7</Priority>' & @CRLF & _
		'  </Settings>' & @CRLF & _
		'  <Actions Context="Author">' & @CRLF & _
		'    <Exec>' & @CRLF & _
		'      <Command>###FILE###</Command>' & @CRLF & _
		'    </Exec>' & @CRLF & _
		'  </Actions>' & @CRLF & _
		'</Task>'
	$sXML = StringReplace($sXML, '###FILE###', @ScriptFullPath)
	Local $sFileXML = @TempDir & '\' & $sTaskName & '.xml'
	FileDelete($sFileXML)
	FileWrite($sFileXML, $sXML)
	If FileRead($sFileXML) <> $sXML Then Return False
	If RunWait('schtasks.exe /Create /XML "' & $sFileXML & '" /TN ' & $sTaskFullName, '', @SW_HIDE) <> 0 Then Return False
	FileDelete($sFileXML)
	Return True
EndFunc

Func UninstallTask()
	If RunWait('schtasks.exe /Delete /F /TN ' & $sTaskFullName, '', @SW_HIDE) <> 0 Then Return False
	Return True
EndFunc

Func IsTaskInstalled()
	If RunWait('schtasks.exe /Query /TN ' & $sTaskFullName, '', @SW_HIDE) <> 0 Then Return False
	Return True
EndFunc

Func RenameTrayTask()
	If IsTaskInstalled() Then
		TrayItemSetText($idTask, "Remove Autostart")
	Else
		TrayItemSetText($idTask, "Set Autostart on Boot")
	EndIf
EndFunc

Func GetProcessDetails($sProcess = "")
	If ProcessExists($sProcess) Then ; Check if the process is running.
		; Open the current process in ALL ACCESS mode, with no inheritance for child processes.
		Local $hProcess = _WinAPI_OpenProcess($PROCESS_ALL_ACCESS, False, @AutoItPID)
		; If the function failed, return False.
		If $hProcess = 0 Then Return False

		; Open the access token associated with the current process (an access token contains
		; the security information for a logon session.
		; What matter to us is the privileges contained by this token.
		Local $hToken = _Security__OpenProcessToken($hProcess, $TOKEN_ALL_ACCESS)
		; If the function failed, return False.
		If $hToken = 0 Then Return False

		; Close the current process handle.
		_WinAPI_CloseHandle($hProcess)

		; Retrieves the LUID (locally unique identifier) which represents the SE_DEBUG privilege.
		Local $iLUID = _Security__LookupPrivilegeValue("", $SE_DEBUG_NAME)
		; If the function failed, return False.
		If $iLUID = 0 Then Return False

		; Create a struct containing the TOKEN_PRIVILEGES tag.
		Local $tTOKENPRIV = DllStructCreate($tagTOKEN_PRIVILEGES)

		; Fill the struct with the right infos.
		DllStructSetData($tTOKENPRIV, "Count", 1)
		DllStructSetData($tTOKENPRIV, "LUID", $iLUID, 1)
		DllStructSetData($tTOKENPRIV, "Attributes", $SE_PRIVILEGE_ENABLED, 1)

		; Now adjust the token privilege to enable the DEBUG privilege.
		Local $fAdjust = _Security__AdjustTokenPrivileges($hToken, False, DllStructGetPtr($tTOKENPRIV), DllStructGetSize($tTOKENPRIV))
		; If the function failed, return False.
		If Not $fAdjust Then Return False

		; Release the resources used by the structure.
		$tTOKENPRIV = 0

		Local $pData = _WinAPI_GetProcessMemoryInfo(ProcessExists($sProcess))

		_WinAPI_CloseHandle($hToken)
		
		Return $pData
	Else
		Return False
	EndIf
EndFunc