#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook

; Each shortcut remembers its own return window.
; Press once to switch to the app, then again in the app to return.
!+c::ToggleApp("ahk_exe chrome.exe ahk_class Chrome_WidgetWin_1", EnvGet("ProgramFiles") "\Google\Chrome\Application\chrome.exe")
!+v::ToggleApp("ahk_exe Code.exe ahk_class Chrome_WidgetWin_1", EnvGet("LOCALAPPDATA") "\Programs\Microsoft VS Code\Code.exe")
!+x::ToggleApp("ahk_exe JaimieOS.exe", EnvGet("LOCALAPPDATA") "\Programs\jaimieos\JaimieOS.exe")
!+e::ToggleApp("ahk_exe emacs.exe ahk_class Emacs", A_AppData "\Microsoft\Windows\Start Menu\Programs\Doom Emacs.lnk")

ToggleApp(criteria, executable) {
    static returnWindows := Map()

    if WinActive(criteria) {
        if returnWindows.Has(criteria) && WinExist("ahk_id " returnWindows[criteria])
            WinActivate "ahk_id " returnWindows[criteria]
        return
    }

    returnWindows[criteria] := WinExist("A")
    targetWindow := WinExist(criteria)
    if targetWindow {
        WinActivate "ahk_id " targetWindow
    } else {
        SplitPath executable, , &workingDirectory
        Run '"' executable '"', workingDirectory
    }
}
