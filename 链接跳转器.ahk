#Requires AutoHotkey v2.0
#SingleInstance Force
#Include <_JXON>

; init
{
	InstallKeybdHook
	SetControlDelay 20
	; 读取配置
	config_path := A_WorkingDir "\urls.json"
	if !FileExist(config_path){
			MsgBox "create success!"
			FileAppend("`n", config_path)
	}
	config := FileRead(config_path)
	; map
	json_data := Jxon_load(&config)
	MyGuiCtrlHwnd := ""
	MyGui := Gui()
	MyGui.Opt("-Caption -Border")
	keys := []
	for key, value in json_data {
	    keys.Push key
	}
	current_keys := keys
	AddChoice(MyGui, keys)
	ctrl_j_flag := 1

	; change前监听
	OnMessage(0x100, ChangeBefore)
	; change后监听
	OnMessage(0x101, ChangeAfter)

}

Log(logMessage) {
    logFile := A_WorkingDir "\log.txt"
	if !FileExist(logFile){
		FileAppend("`n", logFile)
	}
    FileAppend "[" A_PriorKey "]" logMessage "`n", logFile
}

; 快捷键呼出，优先级最高
^j::
{
	MyGui.show
	return
}


; 触发
ChangeBefore(wParam, lParam, msg, hwnd){
	guiCtrlObj := GuiCtrlFromHwnd(MyGuiCtrlHwnd)
	; 快捷键第一次触发, 代表进程正式创建, 不做任何操作
	Global ctrl_j_flag
	if ctrl_j_flag == 1 {
		ctrl_j_flag := 0
		Return
	}

	txt := ControlGetText(MyGuiCtrlHwnd)

    ; 监控esc
    if wParam == 27 {
    	WinClose
    }
}

ChangeAfter(wParam, lParam, msg, hwnd){
	guiCtrlObj := GuiCtrlFromHwnd(MyGuiCtrlHwnd)
	; 快捷键第一次触发, 代表进程正式创建, 不做任何操作
	Global ctrl_j_flag
	if ctrl_j_flag == 1 {
		ctrl_j_flag := 0
		Return
	}

	txt := ControlGetText(MyGuiCtrlHwnd)
	; 监控combo的回车键
    if wParam == 13 && txt != ""{
    	Run json_data[ControlGetItems(MyGuiCtrlHwnd)[1]]
    	WinClose
    	Return
    }
}


AddChoice(MyGui, keys){
	MyGuiCtrl := MyGui.Add("ComboBox", "", keys)
	MyGuiCtrl.OnEvent("Change", CtrlChange)
	Global MyGuiCtrlHwnd := MyGuiCtrl.Hwnd
}

CtrlChange(GuiCtrlObj, Info){
	txt := ControlGetText(MyGuiCtrlHwnd)

	if txt != ""
		InputChange(GuiCtrlObj, txt)
	else
		ComboReset(keys, txt)
}

InputChange(GuiCtrlObj, txt) {

	; 匹配符合的选项
	tamp_keys := []
	Loop keys.Length{
		button_txt := keys[A_Index]
		if InStr(button_txt, txt){
			tamp_keys.Push button_txt
		}
	}

	; 判断是否需要切换选项
	change_flag := 0
	Global current_keys
	if current_keys.Length != tamp_keys.Length{
		change_flag := 1
	}
	if change_flag == 0 {
		Loop tamp_keys.Length{
			if current_keys[A_Index] != tamp_keys[A_Index]{
				change_flag := 1
				break
			}
		}
	}

	; 重置选项
	if change_flag == 1 {
		current_keys := tamp_keys
		ComboReset(tamp_keys, txt)
	}

}

ComboReset(items, txt){
	GuiCtrlObj := GuiCtrlFromHwnd(MyGuiCtrlHwnd)
	GuiCtrlObj.Delete
	GuiCtrlObj.Add items
	ControlHideDropDown "ComboBox1"
	ControlShowDropDown "ComboBox1"
	ControlSend txt, MyGuiCtrlHwnd
}
