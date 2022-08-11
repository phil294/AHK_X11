; Using Keyboard Numpad as a Mouse -- by deguix
; http://www.autohotkey.com
; This script makes mousing with your keyboard almost as easy
; as using a real mouse (maybe even easier for some tasks).
; It supports up to five mouse buttons and the turning of the
; mouse wheel.  It also features customizable movement speed,
; acceleration, and "axis inversion".

/*
o------------------------------------------------------------o
|Using Keyboard Numpad as a Mouse                            |
(------------------------------------------------------------)
| By deguix           / A Script file for AutoHotkey 1.0.22+ |
|                    ----------------------------------------|
|                                                            |
|    This script is an example of use of AutoHotkey. It uses |
| the remapping of numpad keys of a keyboard to transform it |
| into a mouse. Some features are the acceleration which     |
| enables you to increase the mouse movement when holding    |
| a key for a long time, and the rotation which makes the    |
| numpad mouse to "turn". I.e. NumPadDown as NumPadUp        |
| and vice-versa. See the list of keys used below:           |
|                                                            |
|------------------------------------------------------------|
| Keys                  | Description                        |
|------------------------------------------------------------|
| ScrollLock (toggle on)| Activates numpad mouse mode.       |
|-----------------------|------------------------------------|
| NumPad0               | Left mouse button click.           |
| NumPad5               | Middle mouse button click.         |
| NumPadDot             | Right mouse button click.          |
| NumPadDiv/NumPadMult  | X1/X2 mouse button click. (Win 2k+)|
| NumPadSub/NumPadAdd   | Moves up/down the mouse wheel.     |
|                       |                                    |
|-----------------------|------------------------------------|
| NumLock (toggled off) | Activates mouse movement mode.     |
|-----------------------|------------------------------------|
| NumPadEnd/Down/PgDn/  | Mouse movement.                    |
| /Left/Right/Home/Up/  |                                    |
| /PgUp                 |                                    |
|                       |                                    |
|-----------------------|------------------------------------|
| NumLock (toggled on)  | Activates mouse speed adj. mode.   |
|-----------------------|------------------------------------|
| NumPad7/NumPad1       | Inc./dec. acceleration per         |
|                       | button press.                      |
| NumPad8/NumPad2       | Inc./dec. initial speed per        |
|                       | button press.                      |
| NumPad9/NumPad3       | Inc./dec. maximum speed per        |
|                       | button press.                      |
| ^NumPad7/^NumPad1     | Inc./dec. wheel acceleration per   |
|                       | button press*.                     |
| ^NumPad8/^NumPad2     | Inc./dec. wheel initial speed per  |
|                       | button press*.                     |
| ^NumPad9/^NumPad3     | Inc./dec. wheel maximum speed per  |
|                       | button press*.                     |
| NumPad4/NumPad6       | Inc./dec. rotation angle to        |
|                       | right in degrees. (i.e. 180° =     |
|                       | = inversed controls).              |
|------------------------------------------------------------|
| * = These options are affected by the mouse wheel speed    |
| adjusted on Control Panel. If you don't have a mouse with  |
| wheel, the default is 3 +/- lines per option button press. |
o------------------------------------------------------------o
*/

;START OF CONFIG SECTION

#SingleInstance force
#MaxHotkeysPerInterval 500

; Using the keyboard hook to implement the Numpad hotkeys prevents
; them from interfering with the generation of ANSI characters such
; as à.  This is because AutoHotkey generates such characters
; by holding down ALT and sending a series of Numpad keystrokes.
; Hook hotkeys are smart enough to ignore such keystrokes.
#UseHook

MouseSpeed = 1
MouseAccelerationSpeed = 1
MouseMaxSpeed = 5

;Mouse wheel speed is also set on Control Panel. As that
;will affect the normal mouse behavior, the real speed of
;these three below are times the normal mouse wheel speed.
MouseWheelSpeed = 1
MouseWheelAccelerationSpeed = 1
MouseWheelMaxSpeed = 5

MouseRotationAngle = 0

;END OF CONFIG SECTION

;This is needed or key presses would faulty send their natural
;actions. Like NumPadDiv would send sometimes "/" to the
;screen.       
#InstallKeybdHook

Temp = 0
Temp2 = 0

MouseRotationAnglePart = %MouseRotationAngle%
;Divide by 45º because MouseMove only supports whole numbers,
;and changing the mouse rotation to a number lesser than 45º
;could make strange movements.
;
;For example: 22.5º when pressing NumPadUp:
;  First it would move upwards until the speed
;  to the side reaches 1.
MouseRotationAnglePart /= 45

MouseCurrentAccelerationSpeed = 0
MouseCurrentSpeed = %MouseSpeed%

MouseWheelCurrentAccelerationSpeed = 0
MouseWheelCurrentSpeed = %MouseSpeed%

SetKeyDelay, -1
SetMouseDelay, -1

Hotkey, *NumPad0, ButtonLeftClick
Hotkey, *NumpadIns, ButtonLeftClickIns
Hotkey, *NumPad5, ButtonMiddleClick
Hotkey, *NumpadClear, ButtonMiddleClickClear
Hotkey, *NumPadDot, ButtonRightClick
Hotkey, *NumPadDel, ButtonRightClickDel
Hotkey, *NumPadDiv, ButtonX1Click
Hotkey, *NumPadMult, ButtonX2Click

Hotkey, *NumpadSub, ButtonWheelUp
Hotkey, *NumpadAdd, ButtonWheelDown

Hotkey, *NumPadUp, ButtonUp
Hotkey, *NumPadDown, ButtonDown
Hotkey, *NumPadLeft, ButtonLeft
Hotkey, *NumPadRight, ButtonRight
Hotkey, *NumPadHome, ButtonUpLeft
Hotkey, *NumPadEnd, ButtonUpRight
Hotkey, *NumPadPgUp, ButtonDownLeft
Hotkey, *NumPadPgDn, ButtonDownRight

Hotkey, Numpad8, ButtonSpeedUp
Hotkey, Numpad2, ButtonSpeedDown
Hotkey, Numpad7, ButtonAccelerationSpeedUp
Hotkey, Numpad1, ButtonAccelerationSpeedDown
Hotkey, Numpad9, ButtonMaxSpeedUp
Hotkey, Numpad3, ButtonMaxSpeedDown

Hotkey, Numpad6, ButtonRotationAngleUp
Hotkey, Numpad4, ButtonRotationAngleDown

Hotkey, !Numpad8, ButtonWheelSpeedUp
Hotkey, !Numpad2, ButtonWheelSpeedDown
Hotkey, !Numpad7, ButtonWheelAccelerationSpeedUp
Hotkey, !Numpad1, ButtonWheelAccelerationSpeedDown
Hotkey, !Numpad9, ButtonWheelMaxSpeedUp
Hotkey, !Numpad3, ButtonWheelMaxSpeedDown

Gosub, ~ScrollLock  ; Initialize based on current ScrollLock state.
return

;Key activation support

~ScrollLock::
; Wait for it to be released because otherwise the hook state gets reset
; while the key is down, which causes the up-event to get suppressed,
; which in turn prevents toggling of the ScrollLock state/light:
KeyWait, ScrollLock
GetKeyState, ScrollLockState, ScrollLock, T
If ScrollLockState = D
{
	Hotkey, *NumPad0, on
	Hotkey, *NumpadIns, on
	Hotkey, *NumPad5, on
	Hotkey, *NumPadDot, on
	Hotkey, *NumPadDel, on
	Hotkey, *NumPadDiv, on
	Hotkey, *NumPadMult, on

	Hotkey, *NumpadSub, on
	Hotkey, *NumpadAdd, on

	Hotkey, *NumPadUp, on
	Hotkey, *NumPadDown, on
	Hotkey, *NumPadLeft, on
	Hotkey, *NumPadRight, on
	Hotkey, *NumPadHome, on
	Hotkey, *NumPadEnd, on
	Hotkey, *NumPadPgUp, on
	Hotkey, *NumPadPgDn, on

	Hotkey, Numpad8, on
	Hotkey, Numpad2, on
	Hotkey, Numpad7, on
	Hotkey, Numpad1, on
	Hotkey, Numpad9, on
	Hotkey, Numpad3, on

	Hotkey, Numpad6, on
	Hotkey, Numpad4, on

	Hotkey, !Numpad8, on
	Hotkey, !Numpad2, on
	Hotkey, !Numpad7, on
	Hotkey, !Numpad1, on
	Hotkey, !Numpad9, on
	Hotkey, !Numpad3, on
}
else
{
	Hotkey, *NumPad0, off
	Hotkey, *NumpadIns, off
	Hotkey, *NumPad5, off
	Hotkey, *NumPadDot, off
	Hotkey, *NumPadDel, off
	Hotkey, *NumPadDiv, off
	Hotkey, *NumPadMult, off

	Hotkey, *NumpadSub, off
	Hotkey, *NumpadAdd, off

	Hotkey, *NumPadUp, off
	Hotkey, *NumPadDown, off
	Hotkey, *NumPadLeft, off
	Hotkey, *NumPadRight, off
	Hotkey, *NumPadHome, off
	Hotkey, *NumPadEnd, off
	Hotkey, *NumPadPgUp, off
	Hotkey, *NumPadPgDn, off

	Hotkey, Numpad8, off
	Hotkey, Numpad2, off
	Hotkey, Numpad7, off
	Hotkey, Numpad1, off
	Hotkey, Numpad9, off
	Hotkey, Numpad3, off

	Hotkey, Numpad6, off
	Hotkey, Numpad4, off

	Hotkey, !Numpad8, off
	Hotkey, !Numpad2, off
	Hotkey, !Numpad7, off
	Hotkey, !Numpad1, off
	Hotkey, !Numpad9, off
	Hotkey, !Numpad3, off
}
return

;Mouse click support

ButtonLeftClick:
GetKeyState, already_down_state, LButton
If already_down_state = D
	return
Button2 = NumPad0
ButtonClick = Left
Goto ButtonClickStart
ButtonLeftClickIns:
GetKeyState, already_down_state, LButton
If already_down_state = D
	return
Button2 = NumPadIns
ButtonClick = Left
Goto ButtonClickStart

ButtonMiddleClick:
GetKeyState, already_down_state, MButton
If already_down_state = D
	return
Button2 = NumPad5
ButtonClick = Middle
Goto ButtonClickStart
ButtonMiddleClickClear:
GetKeyState, already_down_state, MButton
If already_down_state = D
	return
Button2 = NumPadClear
ButtonClick = Middle
Goto ButtonClickStart

ButtonRightClick:
GetKeyState, already_down_state, RButton
If already_down_state = D
	return
Button2 = NumPadDot
ButtonClick = Right
Goto ButtonClickStart
ButtonRightClickDel:
GetKeyState, already_down_state, RButton
If already_down_state = D
	return
Button2 = NumPadDel
ButtonClick = Right
Goto ButtonClickStart

ButtonX1Click:
GetKeyState, already_down_state, XButton1
If already_down_state = D
	return
Button2 = NumPadDiv
ButtonClick = X1
Goto ButtonClickStart

ButtonX2Click:
GetKeyState, already_down_state, XButton2
If already_down_state = D
	return
Button2 = NumPadMult
ButtonClick = X2
Goto ButtonClickStart

ButtonClickStart:
MouseClick, %ButtonClick%,,, 1, 0, D
SetTimer, ButtonClickEnd, 10
return

ButtonClickEnd:
GetKeyState, kclickstate, %Button2%, P
if kclickstate = D
	return

SetTimer, ButtonClickEnd, off
MouseClick, %ButtonClick%,,, 1, 0, U
return

;Mouse movement support

ButtonSpeedUp:
MouseSpeed++
ToolTip, Mouse speed: %MouseSpeed% pixels
SetTimer, RemoveToolTip, 1000
return
ButtonSpeedDown:
If MouseSpeed > 1
	MouseSpeed--
If MouseSpeed = 1
	ToolTip, Mouse speed: %MouseSpeed% pixel
else
	ToolTip, Mouse speed: %MouseSpeed% pixels
SetTimer, RemoveToolTip, 1000
return
ButtonAccelerationSpeedUp:
MouseAccelerationSpeed++
ToolTip, Mouse acceleration speed: %MouseAccelerationSpeed% pixels
SetTimer, RemoveToolTip, 1000
return
ButtonAccelerationSpeedDown:
If MouseAccelerationSpeed > 1
	MouseAccelerationSpeed--
If MouseAccelerationSpeed = 1
	ToolTip, Mouse acceleration speed: %MouseAccelerationSpeed% pixel
else
	ToolTip, Mouse acceleration speed: %MouseAccelerationSpeed% pixels
SetTimer, RemoveToolTip, 1000
return

ButtonMaxSpeedUp:
MouseMaxSpeed++
ToolTip, Mouse maximum speed: %MouseMaxSpeed% pixels
SetTimer, RemoveToolTip, 1000
return
ButtonMaxSpeedDown:
If MouseMaxSpeed > 1
	MouseMaxSpeed--
If MouseMaxSpeed = 1
	ToolTip, Mouse maximum speed: %MouseMaxSpeed% pixel
else
	ToolTip, Mouse maximum speed: %MouseMaxSpeed% pixels
SetTimer, RemoveToolTip, 1000
return

ButtonRotationAngleUp:
MouseRotationAnglePart++
If MouseRotationAnglePart >= 8
	MouseRotationAnglePart = 0
MouseRotationAngle = %MouseRotationAnglePart%
MouseRotationAngle *= 45
ToolTip, Mouse rotation angle: %MouseRotationAngle%°
SetTimer, RemoveToolTip, 1000
return
ButtonRotationAngleDown:
MouseRotationAnglePart--
If MouseRotationAnglePart < 0
	MouseRotationAnglePart = 7
MouseRotationAngle = %MouseRotationAnglePart%
MouseRotationAngle *= 45
ToolTip, Mouse rotation angle: %MouseRotationAngle%°
SetTimer, RemoveToolTip, 1000
return

ButtonUp:
ButtonDown:
ButtonLeft:
ButtonRight:
ButtonUpLeft:
ButtonUpRight:
ButtonDownLeft:
ButtonDownRight:
If Button <> 0
{
	IfNotInString, A_ThisHotkey, %Button%
	{
		MouseCurrentAccelerationSpeed = 0
		MouseCurrentSpeed = %MouseSpeed%
	}
}
StringReplace, Button, A_ThisHotkey, *

ButtonAccelerationStart:
If MouseAccelerationSpeed >= 1
{
	If MouseMaxSpeed > %MouseCurrentSpeed%
	{
		Temp = 0.001
		Temp *= %MouseAccelerationSpeed%
		MouseCurrentAccelerationSpeed += %Temp%
		MouseCurrentSpeed += %MouseCurrentAccelerationSpeed%
	}
}

;MouseRotationAngle convertion to speed of button direction
{
	MouseCurrentSpeedToDirection = %MouseRotationAngle%
	MouseCurrentSpeedToDirection /= 90.0
	Temp = %MouseCurrentSpeedToDirection%

	if Temp >= 0
	{
		if Temp < 1
		{
			MouseCurrentSpeedToDirection = 1
			MouseCurrentSpeedToDirection -= %Temp%
			Goto EndMouseCurrentSpeedToDirectionCalculation
		}
	}
	if Temp >= 1
	{
		if Temp < 2
		{
			MouseCurrentSpeedToDirection = 0
			Temp -= 1
			MouseCurrentSpeedToDirection -= %Temp%
			Goto EndMouseCurrentSpeedToDirectionCalculation
		}
	}
	if Temp >= 2
	{
		if Temp < 3
		{
			MouseCurrentSpeedToDirection = -1
			Temp -= 2
			MouseCurrentSpeedToDirection += %Temp%
			Goto EndMouseCurrentSpeedToDirectionCalculation
		}
	}
	if Temp >= 3
	{
		if Temp < 4
		{
			MouseCurrentSpeedToDirection = 0
			Temp -= 3
			MouseCurrentSpeedToDirection += %Temp%
			Goto EndMouseCurrentSpeedToDirectionCalculation
		}
	}
}
EndMouseCurrentSpeedToDirectionCalculation:

;MouseRotationAngle convertion to speed of 90 degrees to right
{
	MouseCurrentSpeedToSide = %MouseRotationAngle%
	MouseCurrentSpeedToSide /= 90.0
	Temp = %MouseCurrentSpeedToSide%
	Transform, Temp, mod, %Temp%, 4

	if Temp >= 0
	{
		if Temp < 1
		{
			MouseCurrentSpeedToSide = 0
			MouseCurrentSpeedToSide += %Temp%
			Goto EndMouseCurrentSpeedToSideCalculation
		}
	}
	if Temp >= 1
	{
		if Temp < 2
		{
			MouseCurrentSpeedToSide = 1
			Temp -= 1
			MouseCurrentSpeedToSide -= %Temp%
			Goto EndMouseCurrentSpeedToSideCalculation
		}
	}
	if Temp >= 2
	{
		if Temp < 3
		{
			MouseCurrentSpeedToSide = 0
			Temp -= 2
			MouseCurrentSpeedToSide -= %Temp%
			Goto EndMouseCurrentSpeedToSideCalculation
		}
	}
	if Temp >= 3
	{
		if Temp < 4
		{
			MouseCurrentSpeedToSide = -1
			Temp -= 3
			MouseCurrentSpeedToSide += %Temp%
			Goto EndMouseCurrentSpeedToSideCalculation
		}
	}
}
EndMouseCurrentSpeedToSideCalculation:

MouseCurrentSpeedToDirection *= %MouseCurrentSpeed%
MouseCurrentSpeedToSide *= %MouseCurrentSpeed%

Temp = %MouseRotationAnglePart%
Transform, Temp, Mod, %Temp%, 2

If Button = NumPadUp
{
	if Temp = 1
	{
		MouseCurrentSpeedToSide *= 2
		MouseCurrentSpeedToDirection *= 2
	}

	MouseCurrentSpeedToDirection *= -1
	MouseMove, %MouseCurrentSpeedToSide%, %MouseCurrentSpeedToDirection%, 0, R
}
else if Button = NumPadDown
{
	if Temp = 1
	{
		MouseCurrentSpeedToSide *= 2
		MouseCurrentSpeedToDirection *= 2
	}

	MouseCurrentSpeedToSide *= -1
	MouseMove, %MouseCurrentSpeedToSide%, %MouseCurrentSpeedToDirection%, 0, R
}
else if Button = NumPadLeft
{
	if Temp = 1
	{
		MouseCurrentSpeedToSide *= 2
		MouseCurrentSpeedToDirection *= 2
	}

	MouseCurrentSpeedToSide *= -1
	MouseCurrentSpeedToDirection *= -1
	MouseMove, %MouseCurrentSpeedToDirection%, %MouseCurrentSpeedToSide%, 0, R
}
else if Button = NumPadRight
{
	if Temp = 1
	{
		MouseCurrentSpeedToSide *= 2
		MouseCurrentSpeedToDirection *= 2
	}

	MouseMove, %MouseCurrentSpeedToDirection%, %MouseCurrentSpeedToSide%, 0, R
}
else if Button = NumPadHome
{
	Temp = %MouseCurrentSpeedToDirection%
	Temp -= %MouseCurrentSpeedToSide%
	Temp *= -1
	Temp2 = %MouseCurrentSpeedToDirection%
	Temp2 += %MouseCurrentSpeedToSide%
	Temp2 *= -1
	MouseMove, %Temp%, %Temp2%, 0, R
}
else if Button = NumPadPgUp
{
	Temp = %MouseCurrentSpeedToDirection%
	Temp += %MouseCurrentSpeedToSide%
	Temp2 = %MouseCurrentSpeedToDirection%
	Temp2 -= %MouseCurrentSpeedToSide%
	Temp2 *= -1
	MouseMove, %Temp%, %Temp2%, 0, R
}
else if Button = NumPadEnd
{
	Temp = %MouseCurrentSpeedToDirection%
	Temp += %MouseCurrentSpeedToSide%
	Temp *= -1
	Temp2 = %MouseCurrentSpeedToDirection%
	Temp2 -= %MouseCurrentSpeedToSide%
	MouseMove, %Temp%, %Temp2%, 0, R
}
else if Button = NumPadPgDn
{
	Temp = %MouseCurrentSpeedToDirection%
	Temp -= %MouseCurrentSpeedToSide%
	Temp2 *= -1
	Temp2 = %MouseCurrentSpeedToDirection%
	Temp2 += %MouseCurrentSpeedToSide%
	MouseMove, %Temp%, %Temp2%, 0, R
}

SetTimer, ButtonAccelerationEnd, 10
return

ButtonAccelerationEnd:
GetKeyState, kstate, %Button%, P
if kstate = D
	Goto ButtonAccelerationStart

SetTimer, ButtonAccelerationEnd, off
MouseCurrentAccelerationSpeed = 0
MouseCurrentSpeed = %MouseSpeed%
Button = 0
return

;Mouse wheel movement support

ButtonWheelSpeedUp:
MouseWheelSpeed++
RegRead, MouseWheelSpeedMultiplier, HKCU, Control Panel\Desktop, WheelScrollLines
If MouseWheelSpeedMultiplier <= 0
	MouseWheelSpeedMultiplier = 1
MouseWheelSpeedReal = %MouseWheelSpeed%
MouseWheelSpeedReal *= %MouseWheelSpeedMultiplier%
ToolTip, Mouse wheel speed: %MouseWheelSpeedReal% lines
SetTimer, RemoveToolTip, 1000
return
ButtonWheelSpeedDown:
RegRead, MouseWheelSpeedMultiplier, HKCU, Control Panel\Desktop, WheelScrollLines
If MouseWheelSpeedMultiplier <= 0
	MouseWheelSpeedMultiplier = 1
If MouseWheelSpeedReal > %MouseWheelSpeedMultiplier%
{
	MouseWheelSpeed--
	MouseWheelSpeedReal = %MouseWheelSpeed%
	MouseWheelSpeedReal *= %MouseWheelSpeedMultiplier%
}
If MouseWheelSpeedReal = 1
	ToolTip, Mouse wheel speed: %MouseWheelSpeedReal% line
else
	ToolTip, Mouse wheel speed: %MouseWheelSpeedReal% lines
SetTimer, RemoveToolTip, 1000
return

ButtonWheelAccelerationSpeedUp:
MouseWheelAccelerationSpeed++
RegRead, MouseWheelSpeedMultiplier, HKCU, Control Panel\Desktop, WheelScrollLines
If MouseWheelSpeedMultiplier <= 0
	MouseWheelSpeedMultiplier = 1
MouseWheelAccelerationSpeedReal = %MouseWheelAccelerationSpeed%
MouseWheelAccelerationSpeedReal *= %MouseWheelSpeedMultiplier%
ToolTip, Mouse wheel acceleration speed: %MouseWheelAccelerationSpeedReal% lines
SetTimer, RemoveToolTip, 1000
return
ButtonWheelAccelerationSpeedDown:
RegRead, MouseWheelSpeedMultiplier, HKCU, Control Panel\Desktop, WheelScrollLines
If MouseWheelSpeedMultiplier <= 0
	MouseWheelSpeedMultiplier = 1
If MouseWheelAccelerationSpeed > 1
{
	MouseWheelAccelerationSpeed--
	MouseWheelAccelerationSpeedReal = %MouseWheelAccelerationSpeed%
	MouseWheelAccelerationSpeedReal *= %MouseWheelSpeedMultiplier%
}
If MouseWheelAccelerationSpeedReal = 1
	ToolTip, Mouse wheel acceleration speed: %MouseWheelAccelerationSpeedReal% line
else
	ToolTip, Mouse wheel acceleration speed: %MouseWheelAccelerationSpeedReal% lines
SetTimer, RemoveToolTip, 1000
return

ButtonWheelMaxSpeedUp:
MouseWheelMaxSpeed++
RegRead, MouseWheelSpeedMultiplier, HKCU, Control Panel\Desktop, WheelScrollLines
If MouseWheelSpeedMultiplier <= 0
	MouseWheelSpeedMultiplier = 1
MouseWheelMaxSpeedReal = %MouseWheelMaxSpeed%
MouseWheelMaxSpeedReal *= %MouseWheelSpeedMultiplier%
ToolTip, Mouse wheel maximum speed: %MouseWheelMaxSpeedReal% lines
SetTimer, RemoveToolTip, 1000
return
ButtonWheelMaxSpeedDown:
RegRead, MouseWheelSpeedMultiplier, HKCU, Control Panel\Desktop, WheelScrollLines
If MouseWheelSpeedMultiplier <= 0
	MouseWheelSpeedMultiplier = 1
If MouseWheelMaxSpeed > 1
{
	MouseWheelMaxSpeed--
	MouseWheelMaxSpeedReal = %MouseWheelMaxSpeed%
	MouseWheelMaxSpeedReal *= %MouseWheelSpeedMultiplier%
}
If MouseWheelMaxSpeedReal = 1
	ToolTip, Mouse wheel maximum speed: %MouseWheelMaxSpeedReal% line
else
	ToolTip, Mouse wheel maximum speed: %MouseWheelMaxSpeedReal% lines
SetTimer, RemoveToolTip, 1000
return

ButtonWheelUp:
ButtonWheelDown:

If Button <> 0
{
	If Button <> %A_ThisHotkey%
	{
		MouseWheelCurrentAccelerationSpeed = 0
		MouseWheelCurrentSpeed = %MouseWheelSpeed%
	}
}
StringReplace, Button, A_ThisHotkey, *

ButtonWheelAccelerationStart:
If MouseWheelAccelerationSpeed >= 1
{
	If MouseWheelMaxSpeed > %MouseWheelCurrentSpeed%
	{
		Temp = 0.001
		Temp *= %MouseWheelAccelerationSpeed%
		MouseWheelCurrentAccelerationSpeed += %Temp%
		MouseWheelCurrentSpeed += %MouseWheelCurrentAccelerationSpeed%
	}
}

If Button = NumPadSub
	MouseClick, wheelup,,, %MouseWheelCurrentSpeed%, 0, D
else if Button = NumPadAdd
	MouseClick, wheeldown,,, %MouseWheelCurrentSpeed%, 0, D

SetTimer, ButtonWheelAccelerationEnd, 100
return

ButtonWheelAccelerationEnd:
GetKeyState, kstate, %Button%, P
if kstate = D
	Goto ButtonWheelAccelerationStart

MouseWheelCurrentAccelerationSpeed = 0
MouseWheelCurrentSpeed = %MouseWheelSpeed%
Button = 0
return

RemoveToolTip:
SetTimer, RemoveToolTip, Off
ToolTip
return