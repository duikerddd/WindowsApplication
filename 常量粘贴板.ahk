#Requires AutoHotkey v2.0
#SingleInstance Force
#Include <_JXON>

; 需求
; 一个窗口
; combos {String, Account}
; 选择弹出
; 弹出都是按钮

; init
{
	SetControlDelay 20
	; 读取配置
	config_path := A_WorkingDir "\constant.json"
	if !FileExist(config_path){
			MsgBox "create success!"
			FileAppend("{}`n", config_path)
	}
	config := FileRead(config_path)
	; map
	json_data := Jxon_load(&config)
	ComboGuiCtrlHwnd := ""
	MainGui := Gui()
	; MyGui.Opt("-Caption")
	StringKey := "String"
	AccountKey := "Account"
	Strings := []
	StringButtons := []
	Accounts := []
	AccountButtons := []
	for key, value in json_data {
		if key == StringKey {
			for k, v in value {
				Strings.Push k
			}
		}
		if key == AccountKey {
			for k, v in value {
				Accounts.Push k
			}
		}
	}
	ShowChoice
	AddButton
	;生成enter监控
	OnMessage(0x100, HandleEnterPress)
}

; 快捷键呼出
^+c::
{
	MainGui.show("W500 H500")
	return
}

changeButtons(buttonArr, flag) {
	for b in buttonArr {
	    if flag {
			ControlShow b
	    } else {
	    	ControlHide b
	    }
	}
}

HandleEnterPress(wParam, lParam, msg, hwnd){
	txt := GuiCtrlFromHwnd(ComboGuiCtrlHwnd).Text
	; 监控combo的回车键
    if wParam == 13 && txt != ""{
    	if txt == StringKey {
	    	changeButtons(StringButtons,true)
	    	changeButtons(AccountButtons,false)
    	}
    	if txt == AccountKey {
    		changeButtons(StringButtons,false)
    		changeButtons(AccountButtons,true)
    	}
    }
    ; 监控esc
    if wParam == 27 {
    	MainGui.hide
    }
}

ShowChoice() {
	ComboGuiCtrl := MainGui.Add("ComboBox", "", [StringKey, AccountKey])
	ComboGuiCtrl.OnEvent("Change", InputChange)
	Global ComboGuiCtrlHwnd := ComboGuiCtrl.Hwnd
}

AddButton() {
	for v in Strings {
		Btn := MainGui.Add("Button", "Default w80 ", v)
		Btn.OnEvent("Click", ClickButton)  
		ControlHide Btn
		StringButtons.Push Btn
	} 
	for v in Accounts {
		Btn := MainGui.Add("Button", "Default w80 ", v)
		Btn.OnEvent("Click", ClickButton2)  
		ControlHide Btn
		AccountButtons.Push Btn
	} 
}

InputChange(GuiCtrlObj, Info) {  
	; 返回值是选项索引
	t := GuiCtrlObj.Text
	try {
    	ret := ControlChooseString(GuiCtrlObj.Text,  "ComboBox1")
    	ControlShowDropDown "ComboBox1"
    	Sleep 500
	}
    Catch{
    }
    ControlHideDropDown ComboGuiCtrlHwnd
}

ClickButton(GuiCtrlObj, Info) {
	A_Clipboard := json_data[StringKey][GuiCtrlObj.Text] 
	MainGui.hide
}

ClickButton2(GuiCtrlObj, Info) {
	Account := GuiCtrlObj.Text
	Pwd := json_data[AccountKey][GuiCtrlObj.Text] 
	ControlSend Account "Chrome_RenderWidgetHostHWND1"
	MainGui.hide
}