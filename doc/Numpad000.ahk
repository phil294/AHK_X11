; Numpad 000 Key
; http://www.autohotkey.com
; This example script makes the special 000 key that appears on certain
; keypads into an equals key.  You can change the action by replacing the
; “Send, =” line with line(s) of your choice.

#MaxThreadsPerHotkey 5  ; Allow multiple threads for this hotkey.
$Numpad0::
#MaxThreadsPerHotkey 1
; Above: Use the $ to force the hook to be used, which prevents an
; infinite loop since this subroutine itself sends Numpad0, which
; would otherwise result in a recursive call to itself.
SetBatchLines, 100 ; Make it run a little faster in this case.
DelayBetweenKeys = 30 ; Adjust this value if it doesn't work.
if A_PriorHotkey = %A_ThisHotkey%
{
	if A_TimeSincePriorHotkey < %DelayBetweenKeys%
	{
		if Numpad0Count =
			Numpad0Count = 2 ; i.e. This one plus the prior one.
		else if Numpad0Count = 0
			Numpad0Count = 2
		else
		{
			; Since we're here, Numpad0Count must be 2 as set by
			; prior calls, which means this is the third time the
			; the key has been pressed. Thus, the hotkey sequence
			; should fire:
			Numpad0Count = 0
			Send, = ; ******* This is the action for the 000 key
		}
		; In all the above cases, we return without further action:
		CalledReentrantly = y
		return
	}
}
; Otherwise, this Numpad0 event is either the first in the series
; or it happened too long after the first one (e.g. perhaps the
; user is holding down the Numpad0 key to auto-repeat it, which
; we want to allow).  Therefore, after a short delay -- during
; which another Numpad0 hotkey event may re-entrantly call this
; subroutine -- we'll send the key on through if no reentrant
; calls occurred:
Numpad0Count = 0
CalledReentrantly = n
; During this sleep, this subroutine may be reentrantly called
; (i.e. a simultaneous "thread" which runs in parallel to the
; call we're in now):
Sleep, %DelayBetweenKeys%
if CalledReentrantly = y ; Another "thread" changed the value.
{
	; Since it was called reentrantly, this key event was the first in
	; the sequence so should be suppressed (hidden from the system):
	CalledReentrantly = n
	return
}
; Otherwise it's not part of the sequence so we send it through normally.
; In other words, the *real* Numpad0 key has been pressed, so we want it
; to have its normal effect:
Send, {Numpad0}
return
