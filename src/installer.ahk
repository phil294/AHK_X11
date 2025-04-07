#Persistent

Echo, Starting graphical installer. Please see --help for more options.

If A_IsAdmin = 1
{
	MsgBox, It seems you are running this installer for AHK_X11 with administrator permission. This is currently not supported, so please don't do that. For a system-wide install, clone and install from the repository.`n`nThis means you probably ran the installer with "sudo". Please omit the sudo and try again.`n`nThe installer will exit now.
	ExitApp
}
IfExist, /usr/bin/ahk_x11
{
	MsgBox, 4,, AHK_X11 is installed and seems to be working well. Congrats!`n`nTo learn what to do next, please read "Creating a script" at`nhttps://phil294.github.io/AHK_X11/`n`nPlease click NO below.`n`n--------------------------------------------`n`nOtherwise, if you click YES, AHK_X11 will be installed ANOTHER TIME, but locally for the current user. Two simultaneous installations ins PROBABLY A BAD IDEA. Are you sure you want to continue?
	IfMsgBox, No
		ExitApp
	IfMsgBox, Cancel
		ExitApp
}

app_name = ahk_x11
app_ext = ahk
app_comment = AHK_X11: AutoHotkey for Linux
binary_dir = %A_Home%/.local/bin
binary_path = %binary_dir%/ahk_x11.AppImage
app_logo = /tmp/tmp_ahk_x11_logo.png

Gui, Add, Text, xm0, %app_comment%
Gui, Add, Text, xm0 y50, This is the installer.`nDocumentation: https://phil294.github.io/AHK_X11/#TutorialHelp.htm`n`nIf you click INSTALL below (recommended), this will install the binary and associate`nall .ahk files with it,so you can double click your scripts for execution.
Gui, Add, Button, xm0 y200 gInstall, Click here to Install
Gui, Add, Button, xm0 y235 gUninstall, Click here to Uninstall
Gui, Show, w300 h280, AHK_X11 Installer
Sleep, 9999999999999 ; no repl
Return

GuiClose:
ExitApp

Install:
	; Bin
	FileCreateDir, %binary_dir%
	if binary_path = %A_ScriptFullPath%
	{
		MsgBox, 4,, It looks like you are trying to install the very same version that is already running. Are you sure you want to continue?
		IfMsgBox, No
			ExitApp
	} else {
		FileCopy, %A_ScriptFullPath%, %binary_path%, 1
	}

	; Icon
	RunWait, xdg-icon-resource install --context mimetypes --size 48 %app_logo% application-x-%app_name%

	; Register MIME: application/x-ahk_x11
	FileAppend, <?xml version="1.0" encoding="UTF-8"?><mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info"><mime-type type="application/x-%app_name%"><comment>%app_comment%</comment><icon name="application-x-%app_name%"/><glob pattern="*.%app_ext%"/></mime-type></mime-info>, %app_name%-mime.xml
	RunWait, xdg-mime install %app_name%-mime.xml
	FileDelete, %app_name%-mime.xml
	RunWait, update-mime-database %A_Home%/.local/share/mime

	; Add main app
	FileAppend, [Desktop Entry]`n, %app_name%.desktop
	FileAppend, Name=%app_name%`n, %app_name%.desktop
	FileAppend, Exec=%binary_path% `%u`n, %app_name%.desktop
	FileAppend, MimeType=application/x-%app_name%`n, %app_name%.desktop
	FileAppend, Icon=application-x-%app_name%`n, %app_name%.desktop
	FileAppend, Terminal=false`n, %app_name%.desktop
	FileAppend, Type=Application`n, %app_name%.desktop
	FileAppend, Categories=`n, %app_name%.desktop
	FileAppend, Comment=%app_comment%`n, %app_name%.desktop
	RunWait, desktop-file-install --dir=%A_Home%/.local/share/applications %app_name%.desktop
	FileDelete, %app_name%.desktop

	; Set main app as default
	RunWait, xdg-mime default %app_name%.desktop application/x-%app_name%

	; Add compiler
	FileAppend, [Desktop Entry]`n, %app_name%-compiler.desktop
	FileAppend, Name=Compile with %app_name%`n, %app_name%-compiler.desktop
	FileAppend, Exec=%binary_path% --compile `%u`n, %app_name%-compiler.desktop
	FileAppend, MimeType=application/x-%app_name%`n, %app_name%-compiler.desktop
	FileAppend, Icon=application-x-%app_name%`n, %app_name%-compiler.desktop
	FileAppend, Terminal=false`n, %app_name%-compiler.desktop
	FileAppend, Type=Application`n, %app_name%-compiler.desktop
	FileAppend, Categories=`n, %app_name%-compiler.desktop
	FileAppend, Comment=%app_comment% - this is the compiler for %app_name% to create stand-alone binaries.`n, %app_name%-compiler.desktop
	RunWait, desktop-file-install --dir=%A_Home%/.local/share/applications %app_name%-compiler.desktop
	FileDelete, %app_name%-compiler.desktop

	; Add Window Spy
	FileAppend, [Desktop Entry]`n, %app_name%-windowspy.desktop
	FileAppend, Name=Window Spy`n, %app_name%-windowspy.desktop
	FileAppend, Exec=%binary_path% --windowspy`n, %app_name%-windowspy.desktop
	FileAppend, MimeType=application/x-%app_name%`n, %app_name%-windowspy.desktop
	FileAppend, Icon=application-x-%app_name%`n, %app_name%-windowspy.desktop
	FileAppend, Terminal=false`n, %app_name%-windowspy.desktop
	FileAppend, Type=Application`n, %app_name%-windowspy.desktop
	FileAppend, Categories=`n, %app_name%-windowspy.desktop
	FileAppend, Comment=%app_comment% - Window Spy is a tool to help with %app_name% scripting.`n, %app_name%-windowspy.desktop
	RunWait, desktop-file-install --dir=%A_Home%/.local/share/applications %app_name%-windowspy.desktop
	FileDelete, %app_name%-windowspy.desktop

	RunWait, update-desktop-database %A_Home%/.local/share/applications

	MsgBox, Installation complete.
Return

Uninstall:
	; Bin
	FileDelete, %binary_path%

	; Icon
	RunWait, xdg-icon-resource uninstall --context mimetypes --size 48 application-x-%app_name%

	; Unregister MIME
	RunWait, xdg-mime uninstall %A_Home%/.local/share/mime/application/x-%app_name%.xml
	RunWait, update-mime-database %A_Home%/.local/share/mime

	; Remove apps
	FileDelete %A_Home%/.local/share/applications/%app_name%.desktop
	FileDelete %A_Home%/.local/share/applications/%app_name%-compiler.desktop
	FileDelete %A_Home%/.local/share/applications/%app_name%-windowspy.desktop
	RunWait, update-desktop-database %A_Home%/.local/share/applications

	MsgBox, Uninstall complete.
Return
