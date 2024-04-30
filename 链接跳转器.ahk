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
	MyGui.Opt("-Caption")
	keys := []
	for key, value in json_data {
	    keys.Push key
	}
	;生成enter监控
	OnMessage(0x100, HandleEnterPress)
}

; 快捷键呼出
^j::
{
	ShowChoice(MyGui, keys)
	return
}

HandleEnterPress(wParam, lParam, msg, hwnd){
	txt := GuiCtrlFromHwnd(Hwnd).Text
	; 监控combo的回车键
    if wParam == 13 && txt != ""{
    	Run json_data[txt] 
    	MyGui.hide
    }
    ; 监控esc
    if wParam == 27 {
    	MyGui.hide
    }
}

ShowChoice(MyGui, keys) {
	MyGuiCtrl := MyGui.Add("ComboBox", "", keys)
	MyGuiCtrl.OnEvent("Change", InputChange)
	Global MyGuiCtrlHwnd := MyGuiCtrl.Hwnd
	MyGui.show
}

InputChange(GuiCtrlObj, Info) {  
	; 返回值是选项索引
	t := GuiCtrlObj.Text
	try {
    	ret := ControlChooseString(GuiCtrlObj.Text,  "ComboBox1")
    	ControlShowDropDown "ComboBox1"
	}
    Catch{
    	ControlHideDropDown MyGuiCtrlHwnd
    }

}
