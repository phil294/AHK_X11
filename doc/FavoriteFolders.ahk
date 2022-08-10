; Easy Access to Favorite Folders -- by Savage
; http://www.autohotkey.com
; When you click the middle mouse button while certain types of
; windows are active, this script displays a menu of your favorite
; folders.  Upon selecting a favorite, the script will instantly
; switch to that folder within the active window.  The following
; window types are supported: 1) Standard file-open or file-save
; dialogs; 2) Explorer windows; 3) Console (command prompt) windows.
; The menu can also be optionally shown for unsupported window
; types, in which case the chosen favorite will be opened as a new
; Explorer window.

; Note: In Windows Explorer, if "View > Toolbars > Address Bar" is
; not enabled, the menu will not be shown if the hotkey chosen below
; has a tilde.  If it does have a tilde, the menu will be shown
; but the favorite will be opened in a new Explorer window rather
; than switching the active Explorer window to that folder.

; CONFIG: CHOOSE YOUR HOTKEY
; If your mouse has more than 3 buttons, you could try using
; XButton1 (the 4th) or XButton2 (the 5th) instead of MButton.
; You could also use a modified mouse button (such as ^MButton) or
; a keyboard hotkey.  In the case of MButton, the tilde (~) prefix
; is used so that MButton's normal functionality is not lost when
; you click in other window types, such as a browser.  The presence
; of a tilde tells the script to avoid showing the menu for
; unsupported window types.  In other words, if there is no tilde,
; the hotkey will always display the menu; and upon selecting a
; favorite while an unsupported window type is active, a new
; Explorer window will be opened to display the contents of that
; folder.
f_Hotkey = ~MButton

; CONFIG: CHOOSE YOUR FAVORITES
; Update the special commented section below to list your favorite
; folders.  Specify the name of the menu item first, followed by a
; semicolon, followed by the name of the actual path of the favorite.
; Use a blank line to create a separator line.

/*
ITEMS IN FAVORITES MENU <-- Do not change this string.
Desktop      ; %UserProfile%\Desktop
Favorites    ; %UserProfile%\Favorites
My Documents ; %UserProfile%\My Documents

Program Files; %ProgramFiles%
*/


; END OF CONFIGURATION SECTION
; Do not make changes below this point unless you want to change
; the basic functionality of the script.

#SingleInstance  ; Needed since the hotkey is dynamically created.

Hotkey, %f_Hotkey%, f_DisplayMenu
StringLeft, f_HotkeyFirstChar, f_Hotkey, 1
if f_HotkeyFirstChar = ~  ; Show menu only for certain window types.
	f_AlwaysShowMenu = n
else
	f_AlwaysShowMenu = y

; Used to reliably determine whether script is compiled:
SplitPath, A_ScriptName,,, f_FileExt
if f_FileExt = Exe  ; Read the menu items from an external file.
	f_FavoritesFile = %A_ScriptDir%\Favorites.ini
else  ; Read the menu items directly from this script file.
	f_FavoritesFile = %A_ScriptFullPath%

;----Read the configuration file.
f_AtStartingPos = n
f_MenuItemCount = 0
Loop, Read, %f_FavoritesFile%
{
	if f_FileExt <> Exe
	{
		; Since the menu items are being read directly from this
		; script, skip over all lines until the starting line is
		; arrived at.
		if f_AtStartingPos = n
		{
			IfInString, A_LoopReadLine, ITEMS IN FAVORITES MENU
				f_AtStartingPos = y
			continue  ; Start a new loop iteration.
		}
		; Otherwise, the closing comment symbol marks the end of the list.
		if A_LoopReadLine = */
			break  ; terminate the loop
	}
	; Menu separator lines must also be counted to be compatible
	; with A_ThisMenuItemPos:
	f_MenuItemCount++
	if A_LoopReadLine =  ; Blank indicates a separator line.
		Menu, Favorites, Add
	else
	{
		StringSplit, f_line, A_LoopReadLine, `;
		f_line1 = %f_line1%  ; Trim leading and trailing spaces.
		f_line2 = %f_line2%  ; Trim leading and trailing spaces.
		; Resolve any references to variables within either field, and
		; create a new array element containing the path of this favorite:
		Transform, f_path%f_MenuItemCount%, deref, %f_line2%
		Transform, f_line1, deref, %f_line1%
		Menu, Favorites, Add, %f_line1%, f_OpenFavorite
	}
}
return  ;----End of auto-execute section.


;----Open the selected favorite
f_OpenFavorite:
; Fetch the array element that corresponds to the selected menu item:
StringTrimLeft, f_path, f_path%A_ThisMenuItemPos%, 0
if f_path =
	return
if f_class = #32770    ; It's a dialog.
{
	if f_Edit1Pos <>   ; And it has an Edit1 control.
	{
		; Activate the window so that if the user is middle-clicking
		; outside the dialog, subsequent clicks will also work:
		WinActivate ahk_id %f_window_id%
		; Retrieve any filename that might already be in the field so
		; that it can be restored after the switch to the new folder:
		ControlGetText, f_text, Edit1, ahk_id %f_window_id%
		ControlSetText, Edit1, %f_path%, ahk_id %f_window_id%
		ControlSend, Edit1, {Enter}, ahk_id %f_window_id%
		Sleep, 100  ; It needs extra time on some dialogs or in some cases.
		ControlSetText, Edit1, %f_text%, ahk_id %f_window_id%
		return
	}
	; else fall through to the bottom of the subroutine to take standard action.
}
else if f_class in ExploreWClass,CabinetWClass  ; In Explorer, switch folders.
{
	if f_Edit1Pos <>   ; And it has an Edit1 control.
	{
		ControlSetText, Edit1, %f_path%, ahk_id %f_window_id%
		; Tekl reported the following: "If I want to change to Folder L:\folder
		; then the addressbar shows http://www.L:\folder.com. To solve this,
		; I added a {right} before {Enter}":
		ControlSend, Edit1, {Right}{Enter}, ahk_id %f_window_id%
		return
	}
	; else fall through to the bottom of the subroutine to take standard action.
}
else if f_class = ConsoleWindowClass ; In a console window, CD to that directory
{
	WinActivate, ahk_id %f_window_id% ; Because sometimes the mclick deactivates it.
	SetKeyDelay, 0  ; This will be in effect only for the duration of this thread.
	IfInString, f_path, :  ; It contains a drive letter
	{
		StringLeft, f_path_drive, f_path, 1
		Send %f_path_drive%:{enter}
	}
	Send, cd %f_path%{Enter}
	return
}
; Since the above didn't return, one of the following is true:
; 1) It's an unsupported window type but f_AlwaysShowMenu is y (yes).
; 2) It's a supported type but it lacks an Edit1 control to facilitate the custom
;    action, so instead do the default action below.
Run, Explorer %f_path%  ; Might work on more systems without double quotes.
return


;----Display the menu
f_DisplayMenu:
; These first few variables are set here and used by f_OpenFavorite:
WinGet, f_window_id, ID, A
WinGetClass, f_class, ahk_id %f_window_id%
if f_class in #32770,ExploreWClass,CabinetWClass  ; Dialog or Explorer.
	ControlGetPos, f_Edit1Pos,,,, Edit1, ahk_id %f_window_id%
if f_AlwaysShowMenu = n  ; The menu should be shown only selectively.
{
	if f_class in #32770,ExploreWClass,CabinetWClass  ; Dialog or Explorer.
	{
		if f_Edit1Pos =  ; The control doesn't exist, so don't display the menu
			return
	}
	else if f_class <> ConsoleWindowClass
		return ; Since it's some other window type, don't display menu.
}
; Otherwise, the menu should be presented for this type of window:
Menu, Favorites, show
return
