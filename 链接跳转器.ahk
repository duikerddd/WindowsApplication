#Requires AutoHotkey v2.0
#SingleInstance Force
#Include <_JXON>

; init
{
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
	MyGui.Opt("-Caption +Border")
	keys := []
	for key, value in json_data {
	    keys.Push key
	}
	current_keys := []
	AddChoice(MyGui, keys)
	ctrl_j_flag := 1
	;监听键盘输入
	OnMessage(0x101, HandlePress)
}

; 快捷键呼出，优先级最高
^j::
{
	MyGui.show
	return
}


; 触发
HandlePress(wParam, lParam, msg, hwnd){
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
    	Run json_data[txt] 
    	MyGui.hide
    	Return 
    }
    ; 监控esc
    if wParam == 27 {
    	MyGui.hide
    	Return 
    } 
    key := Ord(Chr(wParam))
    ; 字母,数字,刪除键,shift
    if (key == 8 || key == 16 || (key >= 65 && key <= 90) || (key >= 97 && key <= 122) || (key >= 48 && key <= 57)) {
    	if txt != "" {
    		InputChange(guiCtrlObj, txt)
    	} else {
    		ComboReset(keys, txt)
    	}
    	; MsgBox txt
    	Return
    }
}

AddChoice(MyGui, keys){
	MyGuiCtrl := MyGui.Add("ComboBox", "", keys)
	Global MyGuiCtrlHwnd := MyGuiCtrl.Hwnd
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
		current_keys := tamp_keys 
	}
	if change_flag == 0 {
		Loop tamp_keys.Length{
			if current_keys[A_Index] != tamp_keys[A_Index]{
				change_flag := 1
				current_keys := tamp_keys
				break
			}
		}
	}

	; 重置选项
	if change_flag == 1 {
		ComboReset(tamp_keys, txt)
	}

}

ComboReset(items, txt){
	GuiCtrlObj := GuiCtrlFromHwnd(MyGuiCtrlHwnd)
	GuiCtrlObj.Delete
	GuiCtrlObj.Add items
	if items.Length <= 0 && txt != "" {
		ControlHideDropDown "ComboBox1"
	}else {
		ControlHideDropDown "ComboBox1"
		ControlShowDropDown "ComboBox1"
	}
	
	GuiCtrlObj.Text := txt
	ControlSend "{Ctrl Down}{Right}{Ctrl Up}", MyGuiCtrlHwnd
}
