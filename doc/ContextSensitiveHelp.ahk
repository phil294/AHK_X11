; Context Sensitive Help in Any Editor -- by Rajat
; http://www.autohotkey.com
; This script Makes Ctrl+2 show the help file section for the selected command
; or keyword. If nothing is selected, the command name will be extracted from
; the editor's current line.

$^2::
; If desired, uncomment and adjust the section below to make this hotkey
; operate only when a certain editor is active and/or it has a script file open.
/*
; Do it this way to avoid the case sensitivity of IfWinNotActive:
WinGetTitle, ActiveTitle, A
if ActiveTitle not contains .ahk,.aut  ; A script does not appear to be open.
{
	send, ^2
	return
}
*/
if a_OSType = WIN32_WINDOWS  ; Windows 9x
	Sleep, 500  ; Give time for the user to release the key.

clipboard_prev = %clipboard%
clipboard =
; Use the highlighted word if there is one (since sometimes the user might
; intentionally highlight something that isn't a command):
Send, ^c
ClipWait, 0.05
if ErrorLevel <> 0
{
	; Get the entire line because editors treat cursor navigation keys differently:
	Send, {home}+{end}^c
	ClipWait, 0.2
	if ErrorLevel <> 0  ; Rare, so no error is reported.
	{
		clipboard = %clipboard_prev%
		return
	}
}
AutoTrim, on  ; Make sure it's at its default setting.
cmd = %clipboard%  ; This will trim leading and trailing tabs & spaces.
clipboard = %clipboard_prev%  ; Restore the original clipboard for the user.
Loop, parse, cmd, %a_space%`,  ; The first space or comma is the end of the command.
{
	cmd = %a_LoopField%
	break ; i.e. we only need one interation.
}
IfWinNotExist, AutoHotkey Help
{
	; Use non-abbreviated root key to support older versions of AHK:
	RegRead, ahk_dir, HKEY_LOCAL_MACHINE, SOFTWARE\AutoHotkey, InstallDir
	if ErrorLevel <> 0
	{
		; Older versions of AHK might not have the above registry entry,
		; so use a best guess location instead:
		ahk_dir = %ProgramFiles%\AutoHotkey
	}
	ahk_help_file = %ahk_dir%\AutoHotkey.chm
	IfNotExist, %ahk_help_file%
	{
		MsgBox, Could not find the help file: %ahk_help_file%.
		return
	}
	Run, %ahk_help_file%
	WinWait, AutoHotkey Help
}
; The above has set the "last found" window which we use below:
WinActivate
WinWaitActive
StringReplace, cmd, cmd, #, {#}
send, !n{home}+{end}%cmd%{enter}
return
