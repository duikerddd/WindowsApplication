#Requires AutoHotkey v2.0
#SingleInstance Force
#Include <_JXON>


; Ctrl+j 触发
^j::
{
	SearchGui.show
	return
}

; 初始化(只执行一次)
{
	; 安装键盘钩子
	InstallKeybdHook
	
	; 读取文件
	configPath := A_WorkingDir "\urls.json"
	if !FileExist(configPath)
		FileAppend("{}", configPath)
	config := FileRead(configPath)

	; 提取url数据
	urlMap := Jxon_load(&config)
	keys   := []
	for key, value in urlMap {
	    keys.Push key
	}
	current_keys := keys
	
	; 生成窗口
	searchGuiCtrlHwnd := ""
	searchGui := Gui("-Caption -Border", "searchGui")
	urlInputGui := Gui("-Caption -Border", "urlInputGui")
	InitGuiCtrl(searchGui, keys)

	; change前监听
	OnMessage(0x100, ChangeBefore)
	; change后监听
	OnMessage(0x101, ChangeAfter)
}

InitGuiCtrl(searchGui, keys){
	; 搜索下拉框
	searchGuiCtrl := searchGui.Add("ComboBox", "", keys)
	searchGuiCtrl.OnEvent("Change", CtrlChange)
	; 录入按钮
	searchGui.Add("Button", "-Default").OnEvent("Click", ClickButton1)
	Global searchGuiCtrlHwnd := searchGuiCtrl.Hwnd

	; 录入框
	urlInputGui.Add("Edit", "vInputKey", "")
	urlInputGui.Add("Edit", "vInputVal", "")
	; 确认
	urlInputGui.Add("Button", "", "save").OnEvent("Click", SaveUrl)
}

Log(logMessage) {
    logFile := A_WorkingDir "\log.txt"
	if !FileExist(logFile){
		FileAppend("`n", logFile)
	}
    FileAppend "[" A_PriorKey "]" logMessage "`n", logFile
}

; 触发
ChangeBefore(wParam, lParam, msg, hwnd){
	guiCtrlObj := GuiCtrlFromHwnd(searchGuiCtrlHwnd)
    ; 监控esc
    if wParam == 27 {
    	WinClose
    }
}

ChangeAfter(wParam, lParam, msg, hwnd){
	guiCtrlObj := GuiCtrlFromHwnd(searchGuiCtrlHwnd)

	txt := ControlGetText(searchGuiCtrlHwnd)
	; 监控combo的回车键
    if wParam == 13 && txt != ""{
    	Run urlMap[ControlGetItems(searchGuiCtrlHwnd)[1]]
    	WinClose
    	Return
    }
}


CtrlChange(GuiCtrlObj, Info){
	txt := ControlGetText(searchGuiCtrlHwnd)

	if txt != ""
		InputChange(GuiCtrlObj, txt)
	else
		ComboReset(keys, txt)
}

ClickButton1(GuiCtrlObj, Info){
	urlInputGui.show()
}

SaveUrl(GuiCtrlObj, Info){
	Global urlMap
	key := ControlGetText("Edit1")
	urlMap[ControlGetText("Edit1")] :=  ControlGetText("Edit2")
	jsonString := Jxon_dump(urlMap)
	Global keys    
	keys.push key
	FileDelete(configPath)
	FileAppend(jsonString, configPath)
	MsgBox "save success"
	WinClose
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
	GuiCtrlObj := GuiCtrlFromHwnd(searchGuiCtrlHwnd)
	GuiCtrlObj.Delete
	GuiCtrlObj.Add items
	ControlHideDropDown "ComboBox1"
	ControlShowDropDown "ComboBox1"
	ControlSend txt, searchGuiCtrlHwnd
}


