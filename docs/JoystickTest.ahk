; Joystick Test Script
; http://www.autohotkey.com
; This script might help determine the button numbers of your joystick.
; It might also reveal if your joystick is in need of calibration,
; that is, whether the range of motion of each of its axes is from 0
; to 100 percent as it should be. If calibration is needed, use the
; operating system's control panel or the software that came with your
; joystick.

#SingleInstance
SetFormat, float, 03  ; Omit decimal point from axis position percentages.
JoystickNumber = 1  ; Increase this to test a joystick other than the first.
GetKeyState, axis_count, %JoystickNumber%JoyAxes
if axis_count < 1
{
	MsgBox Joystick #%JoystickNumber% does not appear to be attached to the system.
	ExitApp
}
GetKeyState, joy_buttons, %JoystickNumber%JoyButtons
GetKeyState, joy_name, %JoystickNumber%JoyName
GetKeyState, joy_info, %JoystickNumber%JoyInfo
GetKeyState, joy_axes, %JoystickNumber%JoyAxes
Loop
{
	buttons_down =
	Loop, %joy_buttons%
	{
		GetKeyState, joy%a_index%, %JoystickNumber%joy%a_index%
		if joy%a_index% = D
			buttons_down = %buttons_down%%a_space%%a_index%
	}
	GetKeyState, joyx, %JoystickNumber%JoyX
	axis_info = X%joyx%
	GetKeyState, joyy, %JoystickNumber%JoyY
	axis_info = %axis_info%%a_space%%a_space%Y%joyy%
	IfInString, joy_info, Z
	{
		GetKeyState, joyz, %JoystickNumber%JoyZ
		axis_info = %axis_info%%a_space%%a_space%Z%joyz%
	}
	IfInString, joy_info, R
	{
		GetKeyState, joyr, %JoystickNumber%JoyR
		axis_info = %axis_info%%a_space%%a_space%R%joyr%
	}
	IfInString, joy_info, U
	{
		GetKeyState, joyu, %JoystickNumber%JoyU
		axis_info = %axis_info%%a_space%%a_space%U%joyu%
	}
	IfInString, joy_info, V
	{
		GetKeyState, joyv, %JoystickNumber%JoyV
		axis_info = %axis_info%%a_space%%a_space%V%joyv%
	}
	IfInString, joy_info, P
	{
		GetKeyState, joyp, %JoystickNumber%JoyPOV
		axis_info = %axis_info%%a_space%%a_space%POV%joyp%
	}
	ToolTip, %joy_name%:`n%axis_info%`nButtons Down: %buttons_down%`n`n(right-click the tray icon to exit)
	Sleep, 100
}
return
