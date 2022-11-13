#Persistent

frozen = 0

Gui, Add, Text, x5  y5, Window Title, Class and Process:
Gui, Add, Edit, x5  y25 h65 w320 r3 vgui_win
Gui, Add, Text, x5  y95, Mouse Position:
Gui, Add, Edit, x5  y115 h65 w320 r3 vgui_mouse
Gui, Add, Text, x5  y185, Focused Control:
Gui, Add, Edit, x5  y205 h105 w320 r3 vgui_control
Gui, Add, Text, x5  y315, Active Window Position:
Gui, Add, Edit, x5  y335 h45 w320 r3 vgui_win_pos
Gui, Add, Text, x5  y385, Status Bar Text:
Gui, Add, Edit, x5  y405 h45 w320 r3 vgui_status_bar
Gui, Add, Text, x5  y455, Visible Text:
Gui, Add, Edit, x5  y475 h45 w320 r3 vgui_visible_text
Gui, Add, Text, x5  y525, All Text:
Gui, Add, Edit, x5  y545 h45 w320 r3 vgui_all_text
Gui, Add, Text, x5  y595 vgui_frozen, (Win+A to freeze display)
Gui, Show,, Window Spy

SetTimer, Clock, 500

Return

~#a::
if frozen = 0
{
    GuiControl, , gui_frozen, FROZEN (Win+A to unfreeze)
    frozen = 1
} else {
    GuiControl, , gui_frozen, (Win+A to freeze display)
    frozen = 0
}
return

GuiClose:
ExitApp

Clock:
if frozen = 1
    Return
WinGet, win_id, ID, A
WinGetTitle, win_title, ahk_id %win_id%
if win_title = Window Spy
    Return
WinGetClass, win_class, ahk_id %win_id%
WinGetPos, win_x, win_y, win_w, win_h, ahk_id %win_id%
WinGetText, win_txt, ahk_id %win_id%
MouseGetPos, mouse_x_win, mouse_y_win
CoordMode, Mouse
MouseGetPos, mouse_x_screen, mouse_y_screen
ctrl_nn =
win_right = win_x
win_right += %win_w%
win_bottom = win_y
win_bottom += %win_h%
if mouse_x_win >= 0
    if mouse_y_win >= 0
        if mouse_x_win < %win_right%
            if mouse_y_win < %win_bottom%
                MouseGetPos, , , , ctrl_nn
PixelGetColor, pixel_color, %mouse_x_win%, %mouse_y_win%, RGB
StringMid, pixel_color_r, pixel_color, 1, 2
StringMid, pixel_color_g, pixel_color, 3, 2
StringMid, pixel_color_b, pixel_color, 5, 2
ctrl_x =
ctrl_y =
ctrl_w =
ctrl_h =
ctrl_txt =
if ctrl_nn <>
{
    ControlGetPos, ctrl_x, ctrl_y, ctrl_w, ctrl_h, %ctrl_nn%, ahk_id %win_id%
    ControlGetText, ctrl_txt, %ctrl_nn%, ahk_id %win_id%
}
GuiControl, , gui_win, %win_title%`nahk_class %win_class%
GuiControl, , gui_mouse, Screen:`t`t%mouse_x_screen%, %mouse_y_screen% (less often used)`nColor:`t`t%pixel_color% (Red=%pixel_color_r% Green=%pixel_color_g% Blue=%pixel_color_b%)`nWindow:`t%mouse_x_win%, %mouse_y_win% (default)
GuiControl, , gui_control, ClassNN:`t%ctrl_nn%`n`tText:`t%ctrl_txt%`nPos:`t`tx: %ctrl_x%`ty: %ctrl_y%`tw: %ctrl_w%`th: %ctrl_h%
GuiControl, , gui_win_pos, x: %win_x%`ty: %win_y%`tw: %win_w%`th: %win_h%
GuiControl, , gui_visible_text, %win_txt%
Return