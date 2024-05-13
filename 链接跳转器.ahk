#Requires AutoHotkey v2.0
#SingleInstance Force
#Include <_JXON>

; 日志
InstallKeybdHook
Log(logMessage) {
    logFile := A_WorkingDir "\log.txt"
	
	if !FileExist(logFile)
		FileAppend("`n", logFile)
	
    FileAppend "[" A_PriorKey "]" logMessage "`n", logFile
}

; 窗口栈
stackWidght := []
ShowGui(GuiObj){
	; 隐藏上个窗口
	if stackWidght.Length > 0 
		stackWidght[-1].Hide()

	; 打开新窗口并记录
	GuiObj.show
	stackWidght.push(GuiObj)
}
CloseGui(){
	guiCount := stackWidght.Length
	guiObj := stackWidght.pop()
	; 两个窗口做窗口回退
	if guiCount > 1 {
		; 隐藏当前窗口
		guiObj.Hide()
		; 展示上个窗口
		stackWidght[-1].Show()
		Return 
	}	
	
	; 一个窗口做关闭
	WinClose
}


; Ctrl+j 触发
^j::
{
	ShowGui(SearchGui)
	return
}

; 初始化(只执行一次)
{	
	; 读取文件
	configPath := A_WorkingDir "\urls.json"
	if !FileExist(configPath)
		FileAppend("{}", configPath)
	config := FileRead(configPath)

	; 提取url数据
	urlMap := Jxon_load(&config)

	keys   := []
	for key, value in urlMap 
	    keys.Push key
	
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
	searchGui.SetFont("s17 Norm", "Myanmar Text")
	searchGuiCtrl := searchGui.Add("ComboBox", "x8 y16 w400", keys)
	searchGuiCtrl.OnEvent("Change", CtrlChange)
	; 录入按钮
	searchGui.SetFont("s30", "Ms Shell Dlg 2")
	searchGui.Add("Button", "x416 y16 w68 h48 -Border", "+").OnEvent("Click", ClickAddUrl)
	Global searchGuiCtrlHwnd := searchGuiCtrl.Hwnd

	; 录入框
	urlInputGui.SetFont("s16", "Segoe UI")
	urlInputGui.Add("Text", "x80 y96 w108 h43 +0x200 +Center", "Name")
	urlInputGui.Add("Edit", "vInputKey x192 y96 w372 h44", "")
	urlInputGui.Add("Text", "x80 y160 w108 h43 +0x200 +Center", "URL")
	urlInputGui.Add("Edit", "vInputVal x192 y160 w372 h44", "")
	; 确认
	urlInputGui.Add("Button", "", "save").OnEvent("Click", SaveUrl)
}

; 触发
ChangeBefore(wParam, lParam, msg, hwnd){
	 ; 监控esc
	 if wParam == 27 {
    	SetTimer SearchInput, 0
    	CloseGui()
    }
}

ChangeAfter(wParam, lParam, msg, hwnd){

	searchGuiCtrl := GuiCtrlFromHwnd(searchGuiCtrlHwnd)

	; 上下键 or esc 不触发搜索，需要中断valChange定时器
	if wParam == 38 || wParam == 40 
		SetTimer SearchInput, 0		

	txt := ControlGetText(searchGuiCtrlHwnd)
	; 监控combo的回车键
    if wParam == 13 && txt != "" && WinActive("searchGui"){
    	try
    		Run urlMap[ControlGetItems(searchGuiCtrlHwnd)[1]]
    	catch 
    		Return 
    	CloseGui()
    	Return
    }
}

; 延迟400秒触发
CtrlChange(GuiCtrlObj, Info){
	if WinActive("searchGui")
		SetTimer SearchInput, -300 
}

SearchInput(){
	txt := ControlGetText(searchGuiCtrlHwnd)
	GuiCtrlObj := GuiCtrlFromHwnd(searchGuiCtrlHwnd)

	if txt != ""
		InputChange(GuiCtrlObj, txt)
	else {
		ComboSetChooice(keys, txt)
	}
}

ClickAddUrl(GuiCtrlObj, Info){
	ShowGui(urlInputGui)
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
		ComboSetChooice(tamp_keys, txt)
	}

}

ComboSetChooice(items, txt){
	searchGuiCtrl := GuiCtrlFromHwnd(searchGuiCtrlHwnd)
	searchGuiCtrl.Delete
	searchGuiCtrl.Add items
	ControlHideDropDown searchGuiCtrl
	ControlShowDropDown searchGuiCtrl
	SendInput  txt
}


