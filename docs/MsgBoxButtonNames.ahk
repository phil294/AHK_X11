; Changing MsgBox's Button Names
; http://www.autohotkey.com
; This is a working example script that uses a timer to change
; the names of the buttons in a MsgBox dialog. Although the button
; names are changed, the IfMsgBox command still requires that the
; buttons be referred to by their original names.

#SingleInstance
SetTimer, ChangeButtonNames, 50 
MsgBox, 4, Add or Delete, Choose a button:
IfMsgBox, YES 
	MsgBox, You chose Add. 
else 
	MsgBox, You chose Delete. 
return 

ChangeButtonNames: 
IfWinNotExist, Add or Delete, , return  ; Keep waiting.
SetTimer, ChangeButtonNames, off 
WinActivate 
ControlSetText, &Yes, &Add 
ControlSetText, &No, &Delete 
return
