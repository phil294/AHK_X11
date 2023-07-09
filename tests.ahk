; AUTOMATED TEST SUITE
; Mostly to prevent regression bugs
; Right now, only commands that can be easily tested in 1-2 lines are tested.
;;;;;;;;;;;;;;;;;;;;;;

N_TESTS = 52

GoSub, run_tests
if tests_run != %N_TESTS%
{
	fail_reason = %tests_run% tests completed does not match the expected N_TESTS=%N_TESTS%
	GoSub, fail
}
echo All tests completed successfully!
ExitApp

assert:
	tests_run += 1
	If expect =
	{
		fail_reason = "expect" not set
		GoSub, fail
	}

	; StringSplit, split, expect, `,
	; ^ does not exist yet in ahk_x11 so we'll imitate it for now:
	StringGetPos, first_comma_pos, expect, `,
	If first_comma_pos < 0
	{
		fail_reason = expect: var missing: %expect%
		GoSub, fail
	}
	StringMid, test_title, expect, , %first_comma_pos%
	first_comma_pos += 2
	StringMid, expect, expect, %first_comma_pos%, 9999
	StringGetPos, second_comma_pos, expect, `,
	If second_comma_pos < 0
	{
		fail_reason = expect: condition missing (value): %expect%
		GoSub, fail
	}
	StringMid, test_var, expect, , %second_comma_pos%
	second_comma_pos += 2
	StringMid, test_value, expect, %second_comma_pos%, 9999

	StringLeft, test_var_value, %test_var%, 9999
	If test_var_value <> %test_value%
	{
		fail_reason = ❌ (%tests_run%/%N_TESTS%) %test_title%: '%test_var%' is '%test_var_value%' but should be '%test_value%'
		GoSub, fail
	}
	echo ✔ (%tests_run%/%N_TESTS%) %test_title%
	expect =
	first_comma_pos =
	test_title =
	second_comma_pos =
	test_var =
	test_value =
	test_var_value =
Return

fail:
	echo %fail_reason%
	msgbox %fail_reason%
	exitapp 1
Return

timeout:
	settimer, timeout_over, 250
	loop
	{
		stringleft, timeout_var_value, %timeout_var%, 9999
		if timeout_var_value <>
		{
			settimer, timeout_over, OFF
			tests_run += 1
			echo ✔ (%tests_run%/%N_TESTS%) %timeout_var%
			%timeout_var% =
			timeout_var_value =
			return
		}
		sleep 10
	}
return
timeout_over:
	fail_reason = ❌ (%tests_run%/%N_TESTS%) %timeout_var%: Timeout!
	gosub fail
return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

run_tests:

setup = 2
expect = test setup works,setup,2
gosub assert

timeout_var = test_setup_timeout_works
settimer, l_test_setup_timeout_timer, 1
goto l_test_setup_timeout
			l_test_setup_timeout_timer:
				settimer, l_test_setup_timeout_timer, off
				test_setup_timeout_works = 1
			return
l_test_setup_timeout:
gosub timeout
expect = test setup: timeout: reset timeout_var,test_setup_timeout_works,
gosub assert

; helper gui for various interaction tests:
gui -caption
gui add, picture, x0 y0 h47 w-1, assets/logo.png
gui add, button, x10 y50 ggui_button_clicked, btn txt 1
gui add, edit, x20 y70 vgui_edit, edit txt 1
gui +resize
gui show, x10 y20, ahk_x11_test_gui
goto l_after_gui
			gui_button_clicked:
				gui_button_clicked_success = 1
			return
l_after_gui:
sleep 10

;;;;;;;;;;;;;;;;;;; TESTS ;;;;;;;;;;;;;;;;;;;

ifwinnotexist, ahk_x11_test_gui
{
	fail_reason = gui win not exist
	gosub fail
}
ifwinnotexist, ahk_x11_test_gui, btn txt 1
{
	fail_reason = gui win not exist 1
	gosub fail
}
ifwinexist, ahk_x11_test_gui, btn txt 2
{
	fail_reason = gui win exist 2
	gosub fail
}
ifwinexist, ahk_x11_test_gui,,, btn txt 1
{
	fail_reason = gui win exist 3
	gosub fail
}
ifwinnotexist, ahk_x11_test_gui,,, btn txt 2
{
	fail_reason = gui win not exist 4
	gosub fail
}
ifwinnotexist, ahk_x11_test_gui, btn txt 1,banana,btn txt 2
{
	fail_reason = gui win not exist 5
	gosub fail
}
ifwinexist,,,ahk_x11_test_gui
{
	fail_reason = gui win not exist 6
	gosub fail
}
winactivate
ifwinnotactive, ahk_x11_test_gui
{
	fail_reason = gui win not active
	gosub fail
}

WinGetPos, x, y, w, h
expect = gui show pos,x,10
gosub assert
expect = gui show pos,y,20
gosub assert

WinMove, ,, 0, 0, 233, 234
sleep 10
WinGetPos, x, y, w, h
expect = winmove,x,0
gosub assert
expect = winmove,y,0
gosub assert
expect = winmove,w,233
gosub assert
expect = winmove,h,234
gosub assert
WinMove, ,, 10, 20
sleep 10


;;CommentFlag NewString
;;ErrorStdOut
;;EscapeChar NewChar
;;HotkeyInterval Value
;;HotkeyModifierTimeout Value
;;MaxHotkeysPerInterval Value
;;MaxMem Megabytes
;;MaxThreads Value
;;MaxThreadsBuffer On|Off
;;MaxThreadsPerHotkey Value
;;NoTrayIcon
;Persistent
;SingleInstance [force|ignore|off|prompt]
;;WinActivateForce
;;BlockInput, Mode
;Break
;;ClipWait [, SecondsToWait]
;Continue
;;Control, Cmd [, Value, Control, WinTitle, WinText, ExcludeTitle, ExcludeText]

ControlClick, push_button_0_1
expect = controlclick gui button,gui_button_clicked_success,1
gosub assert
gui_button_clicked_success =

;;ControlFocus [, Control, WinTitle, WinText, ExcludeTitle, ExcludeText]
;;ControlGet, OutputVar, Cmd [, Value, Control, WinTitle, WinText, ExcludeTitle, ExcludeText]
;;ControlGetFocus, OutputVar [WinTitle, WinText, ExcludeTitle, ExcludeText]

ControlGetPos, x, y, w, h, icon_0_0_0
expect = controlgetpos,x,0
gosub assert
expect = controlgetpos,y,0
gosub assert
expect = controlgetpos,w,47
gosub assert

ControlGetText, edit_txt, edit txt 1
expect = controlgettext,edit_txt,edit txt 1
gosub assert

ControlSetText, text_0_2, edit txt 2
controlgettext, edit_txt, text_0_2
expect = controlgettext settext,edit_txt,edit txt 2
gosub assert

;;ControlMove, Control, X, Y, Width, Height [, WinTitle, WinText, ExcludeTitle, ExcludeText]

CoordMode, Mouse, Relative
MouseMove, 0, 0
CoordMode, Mouse, Screen
mousegetpos, x, y
expect = coordmode mousepos,x,10
gosub assert
expect = coordmode mousepos,y,20
gosub assert

;;DetectHiddenText, On|Off
;;DetectHiddenWindows, On|Off
;;Drive, Sub-command [, Drive , Value]
;;DriveGet, OutputVar, Cmd [, Value]
;;DriveSpaceFree, OutputVar, Path
;Else
;EnvAdd, Var, Value [, TimeUnits]
;Var += Value [, TimeUnits]
;EnvDiv, Var, Value
;EnvGet, OutputVar, EnvVarName
;EnvMult, Var, Value
;EnvSet, EnvVar, Value
;EnvSub, Var, Value [, TimeUnits]
;Var -= Value [, TimeUnits]
;Exit [, ExitCode]
;ExitApp [, ExitCode]

txt =
tmp_file = ahk_x11_test_%a_now%.txt
FileAppend, txt, %tmp_file%
FileCopy, %tmp_file%, %tmp_file%2
FileDelete, %tmp_file%
FileRead, txt, %tmp_file%
FileRead, txt2, %tmp_file%2
expect = file append copy read,txt2,txt
gosub assert
expect = file delete,txt,
gosub assert
FileDelete, %tmp_file%2


;;FileCopyDir, Source, Dest [, Flag]
;FileCreateDir, DirName
;;FileCreateShortcut, Target, LinkFile [, WorkingDir, Args, Description, IconFile, ShortcutKey, IconNumber, RunState]
;FileGetAttrib, OutputVar [, Filename]
;;FileGetShortcut, LinkFile [, OutTarget, OutDir, OutArgs, OutDescription, OutIcon, OutIconNum, OutRunState]
;;FileGetSize, OutputVar [, Filename, Units]
;;FileGetTime, OutputVar [, Filename, WhichTime]
;;FileGetVersion, OutputVar [, Filename]
;;FileInstall, Source, Dest, Flag
;;FileMove, SourcePattern, DestPattern [, Flag]
;;FileMoveDir, Source, Dest [, Flag]
;FileReadLine, OutputVar, Filename, LineNum
;;FileRecycle, FilePattern
;;FileRecycleEmpty [, DriveLetter]
;;FileRemoveDir, DirName [, Recurse?]
;FileSelectFile, OutputVar [, Options, RootDir, Prompt, Filter]
;FileSelectFolder, OutputVar [, RootPath, Options, Prompt]
;FileSetAttrib, Attributes [, FilePattern, OperateOnFolders?, Recurse?]
;;FileSetTime [, YYYYMMDDHH24MISS, FilePattern, WhichTime, OperateOnFolders?, Recurse?]
;;FormatTime, OutputVar [, YYYYMMDDHH24MISS, Format]

Send {a down}
sleep 20
GetKeyState, a_state, a
expect = getkeystate,a_state,D
gosub assert
send {a up}
sleep 20
GetKeyState, a_state, a
expect = getkeystate,a_state,U
gosub assert

;GoSub, Label
;Goto, Label
;;GroupActivate, GroupName [, R]
;;GroupAdd, GroupName, WinTitle [, WinText, Label, ExcludeTitle, ExcludeText]
;;GroupClose, GroupName [, A|R]
;;GroupDeactivate, GroupName [, R]
;GUI, sub-command [, Param2, Param3, Param4]

GuiControl, , gui_edit, edit txt 3
gui submit, nohide
expect = guicontrol settext,gui_edit,edit txt 3
gosub assert

;;GuiControlGet, OutputVar [, Sub-command, ControlID, Param4]

goto l_after_hotkey_a
			hotkey_a:
				hotkey_a_success = 1
			return
l_after_hotkey_a:
Hotkey, a, hotkey_a
runwait, xdotool type --delay=0 a
expect = hotkey a trigger,hotkey_a_success,1
gosub assert
Hotkey, a, OFF

;if Var between LowerBound and UpperBound
;if var is not type
;if var is type
;if Var not between LowerBound and UpperBound
;IfEqual, var, value (same: if var = value)
;IfExist, FilePattern
;IfGreater, var, value (same: if var > value)
;IfGreaterOrEqual, var, value (same: if var >= value)
;IfInString, var, SearchString
;IfLess, var, value (same: if var < value)
;IfLessOrEqual, var, value (same: if var <= value)
;IfMsgBox, ButtonName
;IfNotEqual, var, value (same: if var <> value) (same: if var != value)
;IfNotExist, FilePattern
;IfNotInString, var, SearchString
;IniDelete, Filename, Section [, Key]
;IniRead, OutputVar, Filename, Section, Key [, Default]
;IniWrite, Value, Filename, Section, Key

goto l_input
			input_send_key:
				settimer, input_send_key, OFF
				runwait xdotool type --delay=0 b
			return
l_input:
settimer, input_send_key, 1
Input, keys, v l1 t1
expect = input,keys,b
gosub assert
keys =

goto l_input_extended
			input_send_key_extended:
				settimer, input_send_key_extended, OFF
				runwait xdotool type --delay=0 abc.
				runwait xdotool key space
				runwait xdotool type --delay=0 xy
				runwait xdotool key BackSpace
				runwait xdotool type --delay=0 yz
			return
l_input_extended:
settimer, input_send_key_extended, 1
Input, keys, *t1, {esc}, abc , xyz
_errorlevel = %errorlevel%
expect = input extended errorlevel,_errorlevel,Match
gosub assert
expect = input extended keys,keys,abc. xyz
gosub assert
keys =
_errorlevel =

Input, keys, t0.00001, {esc}
_errorlevel = %errorlevel%
expect = input timeout,_errorlevel,Timeout
gosub assert
keys =
_errorlevel =

;;InputBox, OutputVar [, Title, Prompt, HIDE, Width, Height, X, Y, Font, Timeout, Default]
;;KeyHistory
;KeyWait, KeyName [, Options]
;;ListHotkeys
;;ListLines
;;ListVars
;Loop [, Count]
;Loop, FilePattern [, IncludeFolders?, Recurse?]
;Loop, Parse, InputVar [, Delimiters, OmitChars, FutureUse]
;Loop, Read, InputFile [, OutputFile, FutureUse]
;Menu, MenuName, Cmd [, P3, P4, P5, FutureUse]

MouseClick, L, 45, 80
sleep 20
expect = click gui button,gui_button_clicked_success,1
gosub assert
gui_button_clicked_success =

;;MouseClickDrag, WhichButton, X1, Y1, X2, Y2 [, Speed, R]

MouseGetPos,,,, ctrl
expect = mousegetpos,ctrl,push_button_0_1
gosub assert

;MsgBox [, Options, Title, Text, Timeout]
;MsgBox, Text
;;OnExit [, Label, FutureUse]
;Pause [, On|Off|Toggle]

coordmode, pixel, relative
PixelGetColor, color, 26, 8, rgb
expect = pixelgetcolor,color,79BE79
gosub assert

PixelSearch, x, y, 0, 0, 100, 100, 0x79BE79, 0, rgb
expect = pixelsearch,x,26
gosub assert
expect = pixelsearch,y,8
gosub assert

;;PostMessage, Msg [, wParam, lParam, Control, WinTitle, WinText, ExcludeTitle, ExcludeText]
;;Process, Cmd, PID-or-Name [, Param3]
;;Random, OutputVar [, Min, Max]
;RegExGetPos, OutputVar, InputVar, SearchText [, L#|R#]
;RegExReplace, OutputVar, InputVar, RegExSearchText [, ReplaceText, ReplaceAll?]
;Reload
;Return
;RunAs [, User, Password, Domain]
;SendRaw, Keys
;;SetBatchLines, 20ms
;;SetBatchLines, LineCount
;;SetControlDelay, Delay
;;SetDefaultMouseSpeed, Speed
;;SetFormat, NumberType, Format
;;SetKeyDelay [, Delay, PressDuration]
;;SetMouseDelay, Delay
;;SetStoreCapslockMode, On|Off
;;SetTitleMatchMode, Fast|Slow
;;SetTitleMatchMode, MatchMode
;;SetWinDelay, Delay
;SetWorkingDir, DirName
;;Shutdown, Code
;Sleep, Delay
;;Sort, VarName [, Options]
;;SoundGet, OutputVar [, ComponentType, ControlType, DeviceNumber]
;;SoundGetWaveVolume, OutputVar [, DeviceNumber]
;;SoundPlay, Filename [, wait]
;;SoundSet, NewSetting [, ComponentType, ControlType, DeviceNumber]
;;SoundSetWaveVolume, Percent [, DeviceNumber]
;;SplitPath, InputVar [, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive]
;;StatusBarGetText, OutputVar [, Part#, WinTitle, WinText, ExcludeTitle, ExcludeText]
;;StatusBarWait [, BarText, Seconds, Part#, WinTitle, WinText, Interval, ExcludeTitle, ExcludeText]
;;StringCaseSense, On|Off
;StringGetPos, OutputVar, InputVar, SearchText [, L#|R#]
;StringLeft, OutputVar, InputVar, Count
;StringLen, OutputVar, InputVar
;StringLower, OutputVar, InputVar [, T]
;StringMid, OutputVar, InputVar, StartChar, Count [, L]
;StringReplace, OutputVar, InputVar, SearchText [, ReplaceText, ReplaceAll?]
;StringRight, OutputVar, InputVar, Count
;;StringSplit, OutputArray, InputVar [, Delimiters, OmitChars, FutureUse]
;;StringTrimLeft, OutputVar, InputVar, Count
;;StringTrimRight, OutputVar, InputVar, Count
;StringUpper, OutputVar, InputVar [, T]
;Suspend [, Mode]
;;SysGet, OutputVar, Sub-command [, Param3]
;;Thread, Setting, P2 [, P3]
;;Transform, OutputVar, Cmd, Value1 [, Value2]
;URLDownloadToFile, URL, Filename
;;WinActivateBottom [, WinTitle, WinText, ExcludeTitle, ExcludeText]
;WinClose [, WinTitle, WinText, SecondsToWait, ExcludeTitle, ExcludeText]
;WinGet, OutputVar [, Cmd, WinTitle, WinText, ExcludeTitle, ExcludeText]
;;WinGetActiveStats, Title, Width, Height, X, Y
;;WinGetActiveTitle, OutputVar

WinGetClass, class
EnvGet, is_appimage, APPIMAGE
if is_appimage =
	expect = wingetclass,class,Ahk_x11
else
	expect = wingetclass,class,AppRun.wrapped
gosub assert

WinGetText, txt
expect = wingettext,txt,ahk_x11_test_gui`nbtn txt 1`nedit txt 3
gosub assert

WinGetTitle, title
expect = wingettitle,title,ahk_x11_test_gui
gosub assert

;;WinHide [, WinTitle, WinText, ExcludeTitle, ExcludeText]
;WinKill [, WinTitle, WinText, SecondsToWait, ExcludeTitle, ExcludeText]
;WinMaximize [, WinTitle, WinText, ExcludeTitle, ExcludeText]
;;WinMenuSelectItem, WinTitle, WinText, Menu [, SubMenu1, SubMenu2, SubMenu3, SubMenu4, SubMenu5, SubMenu6, ExcludeTitle, ExcludeText]
;WinMinimize [, WinTitle, WinText, ExcludeTitle, ExcludeText]
;;WinMinimizeAll
;;WinMinimizeAllUndo
;;WinMove, X, Y
;WinRestore [, WinTitle, WinText, ExcludeTitle, ExcludeText]
;WinSet, Attribute, Value [, WinTitle, WinText, ExcludeTitle, ExcludeText]
;;WinSetTitle, NewTitle
;;WinSetTitle, WinTitle, WinText, NewTitle [, ExcludeTitle, ExcludeText]
;;WinShow [, WinTitle, WinText, ExcludeTitle, ExcludeText]
;;WinWait, WinTitle, WinText, Seconds [, ExcludeTitle, ExcludeText]
;;WinWaitActive [, WinTitle, WinText, Seconds, ExcludeTitle, ExcludeText]
;;WinWaitClose, WinTitle, WinText, Seconds [, ExcludeTitle, ExcludeText]
;;WinWaitNotActive [, WinTitle, WinText, Seconds, ExcludeTitle, ExcludeText]

; ### SEND/HOTKEY/HOTSTRING TESTS ###

send {tab}^a{del} ; focus and reset
sleep 20
send 123
sleep 20
gui submit, nohide
expect = send numbers - issue 22,gui_edit,123
gosub assert

send ^a{del}
sleep 20
send aBc
sleep 20
gui submit, nohide
expect = send aBc - issue 13,gui_edit,aBc
gosub assert

send ^a{del}
sleep 20
send +d
sleep 20
gui submit, nohide
expect = send +d,gui_edit,D
gosub assert

; TODO
; send ^a{del}
; sleep 20
; send @
; sleep 20
; gui submit, nohide
; expect = send @ - issue 32,gui_edit,@
; gosub assert

goto l_hotstring_tests
			test_hotstring:
				send ^a{del}
				sleep 10
				runwait xdotool type --delay=0 %hotstring_input%
				loop
				{
					x = %a_index%
					sleep 10
					gui submit, nohide
					if gui_edit = %hotstring_output%
						break
					if a_index > 50
						break
				}
				expect = hotstring %hotstring_input%,gui_edit,%hotstring_output%
				gosub assert
			return
l_hotstring_tests:

; ::testhotstringbtw::by the way
hotstring_input = .testhotstringbtw.
hotstring_output = .by the way.
gosub test_hotstring

; TODO: case detection doesn't work when input comes from xdotool but with normal typing it does
; hotstring_input = .testhotstringcAsE.
; hotstring_output = .sensitive.
; gosub test_hotstring

hotstring_input = .testhotstringcase.
hotstring_output = .testhotstringcase.
gosub test_hotstring

; :r:testhotstringraw::^a
hotstring_input = .testhotstringraw.
hotstring_output = .^a.
gosub test_hotstring

; :o:testhotstringbs::{bs}
hotstring_input = .testhotstringbs.
hotstring_output =
gosub test_hotstring

; :*:testhotstringnoendchar::immediate
hotstring_input = .testhotstringnoendchar
hotstring_output = .immediate
gosub test_hotstring

send ^a{del}
sleep 10

goto l_after_f2_hotkey
			hotkey_f2:
				hotkey_f2_success = 1
			return
l_after_f2_hotkey:
hotkey, f2, hotkey_f2
runwait, xdotool key F2
expect = hotkey f2 lowercase,hotkey_f2_success,1
gosub assert
hotkey_f2_success =
hotkey, f2, off
hotkey, F2, hotkey_f2
runwait, xdotool key F2
expect = hotkey f2 uppercase,hotkey_f2_success,1
gosub assert
hotkey, F2, off

goto l_after_shift_s_hotkey
			hotkey_shift_s:
				hotkey_shift_s_success = 1
			return
l_after_shift_s_hotkey:
hotkey, +s, hotkey_shift_s
runwait, xdotool key shift+s
expect = hotkey shift_s lowercase,hotkey_shift_s_success,1
gosub assert
hotkey_shift_s_success =
hotkey, +s, off
hotkey, +S, hotkey_shift_s
runwait, xdotool key shift+s
expect = hotkey shift_s lowercase,hotkey_shift_s_success,1
gosub assert

; esc and xbutton2 share the same keycode:
goto l_after_esc_hotkey
			hotkey_esc:
				hotkey_esc_success = 1
			return
l_after_esc_hotkey:
hotkey, esc, hotkey_esc
runwait, xdotool key Escape
expect = hotkey esc,hotkey_esc_success,1
gosub assert
hotkey, esc, off
goto l_after_xbutton2_hotkey
			hotkey_xbutton2:
				hotkey_xbutton2_success = 1
			return
l_after_xbutton2_hotkey:
hotkey, xbutton2, hotkey_xbutton2
runwait, xdotool click 9
expect = hotkey xbutton2,hotkey_xbutton2_success,1
gosub assert
hotkey, xbutton2, off

goto l_after_hotkey_with_send_hotkey
			hotkey_hotkey_with_send:
				send, bcd
			return
l_after_hotkey_with_send_hotkey:
hotkey, a, hotkey_hotkey_with_send
runwait, xdotool key a
sleep 20
gui submit, nohide
expect = hotkey with send,gui_edit,bcd
gosub assert
hotkey, a, off
send ^a{del}
sleep 10
goto l_after_hotkey_with_send_not_first_cmd_hotkey
			hotkey_hotkey_with_send_not_first_cmd:
				sleep 1
				send, efg
			return
l_after_hotkey_with_send_not_first_cmd_hotkey:
hotkey, a, hotkey_hotkey_with_send_not_first_cmd
runwait, xdotool key a
sleep 20
gui submit, nohide
expect = hotkey with send,gui_edit,efg
gosub assert
hotkey, a, off

Send, {LButton}
sleep 20
expect = send {lbutton},gui_button_clicked_success,1
gosub assert
gui_button_clicked_success =

Return

; ### ### ###

; TODO: hotstring with _ in it doesn't work
::testhotstringbtw::by the way
:C:testhotstringcAsE::sensitive
:r:testhotstringraw::^a
:o:testhotstringbs::{bs}
:*:testhotstringnoendchar::immediate