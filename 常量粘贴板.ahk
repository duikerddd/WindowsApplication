#Requires AutoHotkey v2.0
#SingleInstance Force
#Include <_JXON>

; 快捷键
^+c::
{
	MainGui.show("W500 H500")
	return
}


; 初始化
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
		Btn2 := MainGui.Add("Button", "Default w80 ", v)
		Btn2.OnEvent("Click", ClickButton2)  
		ControlHide Btn2
		AccountButtons.Push Btn2
	} 
}

; 触发
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

HandleEnterPress(wParam, lParam, msg, hwnd){
	txt := GuiCtrlFromHwnd(ComboGuiCtrlHwnd).Text
	; 监控combo的回车键
    if wParam == 13 && txt != ""{
    	if txt == StringKey {
	    	openStringButtons
    	}
    	if txt == AccountKey {
    		openAccountButtons
    	}
    }
    ; 监控esc
    if wParam == 27 {
    	MainGui.hide
    }
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


;按钮操作
openStringButtons(){
	changeButtons(StringButtons,true)
	changeButtons(AccountButtons,false)
}

openAccountButtons(){
	changeButtons(StringButtons,false)
    changeButtons(AccountButtons,true)
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