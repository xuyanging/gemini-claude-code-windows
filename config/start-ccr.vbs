' Silently start Claude Code Router daemon at user logon.
CreateObject("WScript.Shell").Run "cmd /c ccr start", 0, False
