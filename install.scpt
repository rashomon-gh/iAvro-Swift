#!/usr/bin/env osascript

use AppleScript version "2.5"
use scripting additions

set appName to "Avro Keyboard.app"
set sourcePath to POSIX path of (path to me as text) & appName
set destDir to POSIX path of (path to home folder) & "Library/Input Methods/"
set destPath to destDir & appName

tell application "Finder"
	if not (exists (POSIX file destDir as alias)) then
		make new folder at (POSIX path of (path to home folder) & "Library/" as POSIX file as alias) with properties {name:"Input Methods"}
	end if
end tell

display dialog "Copy " & appName & " to ~/Library/Input Methods/?" buttons {"Cancel", "Copy"} default button "Copy" with title "Install iAvro-Swift" with icon note

if button returned of result is "Copy" then
	do shell script "cp -R " & quoted form of sourcePath & " " & quoted form of destPath with administrator privileges
	display dialog "iAvro-Swift has been installed." & return & return & "Add it from System Settings → Keyboard → Input Sources." buttons {"OK"} default button "OK" with title "Installation Complete" with icon note
end if
