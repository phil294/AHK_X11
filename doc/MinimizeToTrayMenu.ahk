; Minimize Window to Tray Menu
; http://www.autohotkey.com
; This script assigns a hotkey of your choice to hide any window so that
; it becomes an entry at the bottom of the script's tray menu.  Hidden
; windows can then be restored individually or all at once by selecting
; the corresponding item on the menu.  If the script exits for any reason,
; all the windows that it hid will be restored automatically.

; CHANGES:
; November 3, 2004 (changes provided by trogdor):
; - Program manager is prevented from being hidden.
; - If there is no active window, the minimize-to-tray hotkey will have
;   no effect rather than waiting indefinitely.
;
; October 23, 2004:
; - The taskbar is prevented from being hidden.
; - Some possible problems with long window titles have been fixed.
; - Windows without a title can be hidden without causing problems.
; - If the script is running under AHK v1.0.22 or greater, the
;   maximum length of each menu item is increased from 100 to 260.

; CONFIGURATION SECTION: Change the below values as desired.

; This is the maximum number of windows to allow to be hidden (having a
; limit helps performance):
mwt_MaxWindows = 50

; This is the hotkey used to hide the active window:
mwt_Hotkey = #h  ; Win+H

; If you prefer to have the tray menu empty of all the standard items,
; such as Help and Pause, use N.  Otherwise, use Y:
mwt_StandardMenu = N

; These next few performance settings help to keep the action within the
; #HotkeyModifierTimeout period, and thus avoid the need to release and
; press down the hotkey's modifier if you want to hide more than one
; window in a row.  These settings are not needed you choose to have the
; script use the keyboard hook via #InstallKeybdHook or other means:
#HotkeyModifierTimeout 100
SetWinDelay 10
SetKeyDelay 0

#SingleInstance  ; Allow only one instance of this script to be running.

; END OF CONFIGURATION SECTION (do not make changes below this point
; unless you want to change the basic functionality of the script).

Hotkey, %mwt_Hotkey%, mwt_Minimize

; If the user terminates the script by any means, unhide all the
; windows first:
OnExit, mwt_RestoreAllThenExit

if mwt_StandardMenu = Y
	Menu, Tray, Add
else
{
	Menu, Tray, NoStandard
	Menu, Tray, Add, E&xit and Restore All, mwt_RestoreAllThenExit
}
Menu, Tray, Add, &Restore All Hidden Windows, mwt_RestoreAll
Menu, Tray, Add  ; Another separator line to make the above more special.

if a_AhkVersion =   ; Since it's blank, version is older than 1.0.22.
	mwt_MaxLength = 100
else
	mwt_MaxLength = 260  ; Reduce this to restrict the width of the menu.

return  ; End of auto-execute section.


mwt_Minimize:
if mwt_WindowCount >= %mwt_MaxWindows%
{
	MsgBox No more than %mwt_MaxWindows% may be hidden simultaneously.
	return
}

; Set the "last found window" to simplify and help performance.
; Since in certain cases it is possible for there to be no active window,
; a timeout has been added:
WinWait, A,, 2
if ErrorLevel <> 0  ; It timed out, so do nothing.
	return

; Otherwise, the "last found window" has been set and can now be used:
WinGet, mwt_ActiveID, ID
WinGetTitle, mwt_ActiveTitle
WinGetClass, mwt_ActiveClass
if mwt_ActiveClass in Shell_TrayWnd,Progman
{
	MsgBox The desktop and taskbar cannot be hidden.
	return
}
; Because hiding the window won't deactivate it, activate the window
; beneath this one (if any). I tried other ways, but they wound up
; activating the task bar.  This way sends the active window (which is
; about to be hidden) to the back of the stack, which seems best:
Send, !{esc}
; Hide it only now that WinGetTitle/WinGetClass above have been run (since
; by default, those commands cannot detect hidden windows):
WinHide

; If the title is blank, use the class instead.  This serves two purposes:
; 1) A more meaningful name is used as the menu name.
; 2) Allows the menu item to be created (otherwise, blank items wouldn't
;    be handled correctly by the various routines below).
if mwt_ActiveTitle =
	mwt_ActiveTitle = ahk_class %mwt_ActiveClass%
; Ensure the title is short enough to fit. mwt_ActiveTitle also serves to
; uniquely identify this particular menu item.
StringLeft, mwt_ActiveTitle, mwt_ActiveTitle, %mwt_MaxLength%

; In addition to the tray menu requiring that each menu item name be
; unique, it must also be unique so that we can reliably look it up in
; the array when the window is later unhidden.  So make it unique if it
; isn't already:
Loop, %mwt_MaxWindows%
{
	if mwt_WindowTitle%a_index% = %mwt_ActiveTitle%
	{
		; Match found, so it's not unique.
		; First remove the 0x from the hex number to conserve menu space:
		StringTrimLeft, mwt_ActiveIDShort, mwt_ActiveID, 2
		StringLen, mwt_ActiveIDShortLength, mwt_ActiveIDShort
		StringLen, mwt_ActiveTitleLength, mwt_ActiveTitle
		mwt_ActiveTitleLength += %mwt_ActiveIDShortLength%
		mwt_ActiveTitleLength += 1 ; +1 the 1 space between title & ID.
		if mwt_ActiveTitleLength > %mwt_MaxLength%
		{
			; Since menu item names are limted in length, trim the title
			; down to allow just enough room for the Window's Short ID at
			; the end of its name:
			TrimCount = %mwt_ActiveTitleLength%
			TrimCount -= %mwt_MaxLength%
			StringTrimRight, mwt_ActiveTitle, mwt_ActiveTitle, %TrimCount%
		}
		; Build unique title:
		mwt_ActiveTitle = %mwt_ActiveTitle% %mwt_ActiveIDShort%
		break
	}
}

; First, ensure that this ID doesn't already exist in the list, which can
; happen if a particular window was externally unhidden (or its app unhid
; it) and now it's about to be re-hidden:
mwt_AlreadyExists = n
Loop, %mwt_MaxWindows%
{
	if mwt_WindowID%a_index% = %mwt_ActiveID%
	{
		mwt_AlreadyExists = y
		break
	}
}

; Add the item to the array and to the menu:
if mwt_AlreadyExists = n
{
	Menu, Tray, add, %mwt_ActiveTitle%, RestoreFromTrayMenu
	mwt_WindowCount += 1
	Loop, %mwt_MaxWindows%  ; Search for a free slot.
	{
		; It should always find a free slot if things are designed right.
		if mwt_WindowID%a_index% =  ; An empty slot was found.
		{
			mwt_WindowID%a_index% = %mwt_ActiveID%
			mwt_WindowTitle%a_index% = %mwt_ActiveTitle%
			break
		}
	}
}
return


RestoreFromTrayMenu:
Menu, Tray, delete, %A_ThisMenuItem%
; Find window based on its unique title stored as the menu item name:
Loop, %mwt_MaxWindows%
{
	if mwt_WindowTitle%a_index% = %A_ThisMenuItem%  ; Match found.
	{
		StringTrimRight, IDToRestore, mwt_WindowID%a_index%, 0
		WinShow, ahk_id %IDToRestore%
		WinActivate ahk_id %IDToRestore%  ; Sometimes needed.
		mwt_WindowID%a_index% =  ; Make it blank to free up a slot.
		mwt_WindowTitle%a_index% =
		mwt_WindowCount -= 1
		break
	}
}
return


mwt_RestoreAllThenExit:
Gosub, mwt_RestoreAll
ExitApp  ; Do a true exit.


mwt_RestoreAll:
Loop, %mwt_MaxWindows%
{
	if mwt_WindowID%a_index% <>
	{
		StringTrimRight, IDToRestore, mwt_WindowID%a_index%, 0
		WinShow, ahk_id %IDToRestore%
		WinActivate ahk_id %IDToRestore%  ; Sometimes needed.
		; Do it this way vs. DeleteAll so that the sep. line and first
		; item are retained:
		StringTrimRight, MenuToRemove, mwt_WindowTitle%a_index%, 0
		Menu, Tray, delete, %MenuToRemove%
		mwt_WindowID%a_index% =  ; Make it blank to free up a slot.
		mwt_WindowTitle%a_index% =
		mwt_WindowCount -= 1
	}
	if mwt_WindowCount = 0
		break
}
return
