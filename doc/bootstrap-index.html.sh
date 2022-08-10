#!/bin/bash

# Concatenate all sub htm files into a single big one. Assumes the 1.0.24 chm file's contents to be in this directory as `./index.htm` and `./files/AutoTrim.htm` etc. Might be dependent on the extractor software so perhaps this script is not easily reusable. I think it was this one https://www.aconvert.com/ebook/chm-to-html/ but I'm not sure. Tried other archiving extractors and they didn't work so just resorted to some online service.
# Outputs `index.html`. Deletes all original files except those not processed.

set -e

head -909 index.htm > docs.html
rm index.htm

cd files

add_htm() {
    cat "$1" \
        | perl -0777 -pe 's/^.+?previous page(?:.+?next page)?.*?<\/div>\s*/<div class="calibreMain"><div class="calibreEbookContent">\n<a name="'$file'" href="#'$file'">#<\/a> /s' \
        | perl -0777 -pe 's/^(.+)<div class="calibreToc">.+/\1<\/div>/s' \
        | perl -0777 -pe 's/<a name="([^"]+)"([^>]*)><\/a>/<a name="'$file'__\1" href="#'$file'__\1"\2>#<\/a> /g' \
        | perl -0777 -pe 's/<a href="([^"]+)\.htm"/<a href="#\1.htm"/g' \
        | perl -0777 -pe 's/<a href="([^"]+)\.htm#([^"]+)"/<a href="#\1.htm__\2"/g' \
        >> ../docs.html
}

# these are all toc links in their order (which includes several duplicates)
for file in AutoHotkey.htm TutorialHelp.htm FAQHelp.htm AutoIt2Users.htm Hotkeys.htm Hotstrings.htm KeyList.htm Scripts.htm Variables.htm LastFoundWindow.htm commands.htm ChangeLogHelp.htm ClipWait.htm EnvSet.htm EnvUpdate.htm Drive.htm DriveGet.htm DriveSpaceFree.htm FileAppend.htm FileCopy.htm FileCopyDir.htm FileCreateDir.htm FileCreateShortcut.htm FileDelete.htm FileGetAttrib.htm FileGetShortcut.htm FileGetSize.htm FileGetTime.htm FileGetVersion.htm FileInstall.htm FileMove.htm FileMoveDir.htm FileReadLine.htm FileRecycle.htm FileRecycleEmpty.htm FileRemoveDir.htm FileSelectFile.htm FileSelectFolder.htm FileSetAttrib.htm FileSetTime.htm IfExist.htm IniDelete.htm IniRead.htm IniWrite.htm LoopFile.htm LoopReadFile.htm SetWorkingDir.htm SplitPath.htm _Include.htm Block.htm Break.htm Continue.htm Else.htm Exit.htm ExitApp.htm Gosub.htm Goto.htm Loop.htm LoopFile.htm LoopParse.htm LoopReadFile.htm LoopReg.htm OnExit.htm Pause.htm Return.htm SetBatchLines.htm SetTimer.htm Sleep.htm Suspend.htm FileSelectFile.htm FileSelectFolder.htm Gui.htm GuiControl.htm GuiControlGet.htm IfMsgBox.htm InputBox.htm MsgBox.htm Progress.htm Progress.htm SplashTextOn.htm ToolTip.htm TrayTip.htm Hotkeys.htm _HotkeyInterval.htm _HotkeyModifierTimeout.htm _Hotstring.htm _MaxHotkeysPerInterval.htm _MaxThreads.htm _MaxThreadsBuffer.htm _MaxThreadsPerHotkey.htm _UseHook.htm Hotkey.htm ListHotkeys.htm Pause.htm Reload.htm Suspend.htm _InstallKeybdHook.htm _InstallMouseHook.htm BlockInput.htm ControlSend.htm GetKeyState.htm KeyList.htm KeyHistory.htm KeyWait.htm Input.htm Send.htm SetKeyDelay.htm SetNumScrollCapsLockState.htm SetStoreCapslockMode.htm EnvAdd.htm EnvDiv.htm EnvMult.htm EnvSub.htm IfEqual.htm IfBetween.htm IfIs.htm Random.htm SetFormat.htm Transform.htm _NoTrayIcon.htm _SingleInstance.htm AutoTrim.htm BlockInput.htm CoordMode.htm ClipWait.htm Edit.htm ListLines.htm ListVars.htm Menu.htm PixelGetColor.htm PixelSearch.htm Reload.htm SetBatchLines.htm SetEnv.htm SetTimer.htm SysGet.htm Thread.htm Transform.htm URLDownloadToFile.htm ControlClick.htm MouseClick.htm MouseClickDrag.htm MouseGetPos.htm MouseMove.htm SetDefaultMouseSpeed.htm SetMouseDelay.htm Exit.htm ExitApp.htm OnExit.htm Process.htm Run.htm RunAs.htm Shutdown.htm Sleep.htm LoopReg.htm RegDelete.htm RegRead.htm RegWrite.htm SoundGet.htm SoundGetWaveVolume.htm SoundPlay.htm SoundSet.htm SoundSetWaveVolume.htm EnvSet.htm FormatTime.htm IfEqual.htm IfInString.htm IfIn.htm IfIs.htm LoopParse.htm SetEnv.htm SetFormat.htm Sort.htm StringCaseSense.htm StringGetPos.htm StringLeft.htm StringLen.htm StringLower.htm StringMid.htm StringReplace.htm StringSplit.htm StringTrimLeft.htm Control.htm ControlClick.htm ControlFocus.htm ControlGet.htm ControlGetFocus.htm ControlGetPos.htm ControlGetText.htm ControlMove.htm ControlSend.htm ControlSetText.htm Menu.htm PostMessage.htm SetControlDelay.htm WinMenuSelectItem.htm GroupActivate.htm GroupAdd.htm GroupClose.htm GroupDeactivate.htm _WinActivateForce.htm DetectHiddenText.htm DetectHiddenWindows.htm IfWinActive.htm IfWinExist.htm SetTitleMatchMode.htm SetWinDelay.htm StatusBarGetText.htm StatusBarWait.htm WinActivate.htm WinActivateBottom.htm WinClose.htm WinGet.htm WinGetActiveStats.htm WinGetActiveTitle.htm WinGetClass.htm WinGetPos.htm WinGetText.htm WinGetTitle.htm WinHide.htm WinKill.htm WinMaximize.htm WinMinimize.htm WinMinimizeAll.htm WinMove.htm WinRestore.htm WinSet.htm WinSetTitle.htm WinShow.htm WinWait.htm WinWaitActive.htm WinWaitClose.htm _AllowSameLineComments.htm _CommentFlag.htm _ErrorStdOut.htm _EscapeChar.htm _HotkeyInterval.htm _HotkeyModifierTimeout.htm _Hotstring.htm _Include.htm _InstallKeybdHook.htm _InstallMouseHook.htm _MaxHotkeysPerInterval.htm _MaxMem.htm _MaxThreads.htm _MaxThreadsBuffer.htm _MaxThreadsPerHotkey.htm _NoTrayIcon.htm _Persistent.htm _SingleInstance.htm _UseHook.htm _WinActivateForce.htm
do
    if ! test -f "$file"; then
        echo "skipped duplicate: $file" >&2
        continue
    fi
    # strip header and toc and unify into single large html
    add_htm "$file"
    rm "$file"
done

# there are some non-toc-indexed htm files as well
for file in *.htm; do
    echo "non-indexed added: $file" >&2
    add_htm "$file"
    rm "$file"
done

mv *.gif *.jpg *.ahk ..
cat page_styles.css stylesheet.css >> calibreHtmlOutBasicCss.css
rm page_styles.css stylesheet.css

cd ..

echo '</div></body></html>' >> docs.html

mv docs.html index.html