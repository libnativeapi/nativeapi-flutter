' Runs job.ps1 (next to this file) with no window and writes its exit code to
' interactive.done when it is over. interactive.ps1 generates job.ps1.
Set fs = CreateObject("Scripting.FileSystemObject")
dir = fs.GetParentFolderName(WScript.ScriptFullName)
Set sh = CreateObject("WScript.Shell")
code = sh.Run("powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File " & dir & "\job.ps1", 0, True)
Set f = fs.CreateTextFile(dir & "\interactive.done", True)
f.WriteLine code
f.Close
