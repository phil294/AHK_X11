; Using a Joystick as a Mouse
; http://www.autohotkey.com
; This script converts a joystick into a two-button mouse.  It allows each button
; to drag just like a mouse button and it uses virtually no CPU time.
; Also, it will move the cursor faster depending on how far you push the joystick
; from center. You can personalize various settings at the top of the script.

; Increase this value to make the mouse cursor move faster:
JoyMultiplier = 0.40

; Decrease this value to require less joystick displacement-from-center
; to start moving the mouse.  However, you may need to calibrate your
; joystick -- ensuring it's properly centered -- to avoid cursor drift.
; A perfectly tight and centered joystick could use a value of 1:
JoyThreshold = 3

; Change these values to use joystick button numbers other than 1 & 2 for the
; left & right mouse buttons, respectively:
ButtonLeft = 1
ButtonRight = 2

; If your system has more than one joystick, increase this value to use a joystick
; other than the first:
JoystickNumber = 1

; END OF CONFIG SECTION -- Don't change anything below this point unless you want
; to alter the basic nature of the script.

#SingleInstance

Hotkey, %JoystickNumber%Joy%ButtonLeft%, ButtonLeft
Hotkey, %JoystickNumber%Joy%ButtonRight%, ButtonRight

; Calculate the axis displacements that are needed to start moving the cursor:
JoyThresholdUpper = 50
JoyThresholdUpper += %JoyThreshold%
JoyThresholdLower = 50
JoyThresholdLower -= %JoyThreshold%

SetTimer, WatchJoystick, 10  ; Monitor the movement of the joystick.
return  ; End of auto-execute section.


; The subroutines below do not use KeyWait because that would sometimes trap the
; WatchJoystick quasi-thread beneath the wait-for-button-up thread, which would
; effectively prevent mouse-dragging with the joystick.

ButtonLeft:
SetMouseDelay, -1  ; Makes movement smoother.
MouseClick, left,,, 1, 0, D  ; Hold down the left mouse button.
SetTimer, WaitForLeftButtonUp, 10
return

ButtonRight:
SetMouseDelay, -1  ; Makes movement smoother.
MouseClick, right,,, 1, 0, D  ; Hold down the right mouse button.
SetTimer, WaitForRightButtonUp, 10
return

WaitForLeftButtonUp:
GetKeyState, jstate1, %JoystickNumber%Joy%ButtonLeft%
if jstate1 = D  ; The button is still, down, so keep waiting.
	return
; Otherwise, the button has been released.
SetTimer, WaitForLeftButtonUp, off
SetMouseDelay, -1  ; Makes movement smoother.
MouseClick, left,,, 1, 0, U  ; Release the mouse button.
return

WaitForRightButtonUp:
GetKeyState, jstate2, %JoystickNumber%Joy%ButtonRight%
if jstate2 = D  ; The button is still, down, so keep waiting.
	return
; Otherwise, the button has been released.
SetTimer, WaitForRightButtonUp, off
MouseClick, right,,, 1, 0, U  ; Release the mouse button.
return

WatchJoystick:
MoveMouse? = n  ; Set default.
SetFormat, float, 03
GetKeyState, joyx, %JoystickNumber%JoyX
GetKeyState, joyy, %JoystickNumber%JoyY
if joyx > %JoyThresholdUpper%
{
	MoveMouse? = y
	DeltaX = %joyx%
	DeltaX -= %JoyThresholdUpper%
}
else if joyx < %JoyThresholdLower%
{
	MoveMouse? = y
	DeltaX = %joyx%
	DeltaX -= %JoyThresholdLower%
}
else
	DeltaX = 0
if joyy > %JoyThresholdUpper%
{
	MoveMouse? = y
	DeltaY = %joyy%
	DeltaY -= %JoyThresholdUpper%
}
else if joyy < %JoyThresholdLower%
{
	MoveMouse? = y
	DeltaY = %joyy%
	DeltaY -= %JoyThresholdLower%
}
else
	DeltaY = 0
if MoveMouse? = y
{
	DeltaX *= %JoyMultiplier%
	DeltaY *= %JoyMultiplier%
	SetMouseDelay, -1  ; Makes movement smoother.
	MouseMove, %DeltaX%, %DeltaY%, 0, R
}
return
