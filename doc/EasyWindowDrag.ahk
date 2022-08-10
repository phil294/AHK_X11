; Easy Window Dragging (requires XP/2k/NT)
; http://www.autohotkey.com
; Normally, a window can only be dragged by clicking on its title bar.
; This script extends that so that any point inside a window can be dragged.
; To activate this mode, hold down CapsLock or the middle mouse button while
; clicking, then drag the window to a new position.

; Note: You can optionally release Capslock or the middle mouse button after
; the first click rather than holding it down the whole time.

~MButton & LButton::
CapsLock & LButton::
CoordMode, Mouse  ; Switch to screen/absolute coordinates.
MouseGetPos, EWD_MouseStartX, EWD_MouseStartY, EWD_MouseWin
SetTimer, EWD_WatchMouse, 10 ; Track the mouse as the user drags it.
return

EWD_WatchMouse:
GetKeyState, LButtonState, LButton, P
if LButtonState = U  ; Button has been released, so drag is complete.
{
	SetTimer, EWD_WatchMouse, off
	return
}
; Otherwise, reposition the window to match the change in mouse coordinates
; caused by the user having dragged the mouse:
CoordMode, Mouse
MouseGetPos, EWD_MouseX, EWD_MouseY
EWD_DeltaX = %EWD_MouseX%
EWD_DeltaX -= %EWD_MouseStartX%
EWD_DeltaY = %EWD_MouseY%
EWD_DeltaY -= %EWD_MouseStartY%
EWD_MouseStartX = %EWD_MouseX%  ; Update for the next timer call to this subroutine.
EWD_MouseStartY = %EWD_MouseY%
WinGetPos, EWD_WinX, EWD_WinY,,, ahk_id %EWD_MouseWin%
EWD_WinX += %EWD_DeltaX%
EWD_WinY += %EWD_DeltaY%
SetWinDelay, -1   ; Makes the below move faster/smoother.
WinMove, ahk_id %EWD_MouseWin%,, %EWD_WinX%, %EWD_WinY%
return
