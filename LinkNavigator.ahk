#Requires AutoHotkey v2.0
#SingleInstance Force
#Include <StackWidget>
#Include <_JXON>
#Include <Log>
; Persistent

class LinkNavigator {

	; 成员变量
	keys := []
	searchGuiCtrlHwnd := ""
	configPath := A_WorkingDir "\urls.json"
	searchGui := ""
	urlInputGui := ""
	urlMap := ""
	timer_func_obj := ObjBindMethod(this, "SearchInput")

	__New() {
		this.InitComboData

		this.InitGui

		; change前监听
		OnMessage(0x100, ObjBindMethod(this, "ChangeBefore"))
		; change后监听
		OnMessage(0x101, ObjBindMethod(this, "ChangeAfter"))
	}


	InitComboData() {
		; 读取文件
		if !FileExist(this.configPath)
			FileAppend("{}", this.configPath)
		config := FileRead(this.configPath)
		; 提取url数据
		this.urlMap := Jxon_load(&config)

		for key, value in this.urlMap
			this.keys.Push key
	}

	InitGui() {
		this.searchGui := Gui("-Caption -Border", "searchGui")
		this.urlInputGui := Gui("-Caption", "urlInputGui")

		; 搜索下拉框
		this.searchGui.SetFont("s17 Norm", "Myanmar Text")
		this.searchGuiCtrl := this.searchGui.Add("ComboBox", "R3 x10 y16 w400", this.keys)
		this.searchGuiCtrl.OnEvent("Change", ObjBindMethod(this, "CtrlChange"))
		; 录入按钮
		this.searchGui.SetFont("s30", "Ms Shell Dlg 2")
		this.inputGuiCtrl := this.searchGui.Add("Text", "x420 y16 w40 h48 -Border c93ADE2", "+")
		this.inputGuiCtrl.OnEvent("Click", ObjBindMethod(this, "ClickAddUrl"))
		this.searchGuiCtrlHwnd := this.searchGuiCtrl.Hwnd

		; 录入框
		this.urlInputGui.SetFont("s16", "Segoe UI")
		this.urlInputGui.Add("Text", "x0 y40 w108 h43 +0x200 +Center", "Name")
		this.urlInputGui.Add("Edit", "vInputKey x102 y40 w372 h44", "")
		this.urlInputGui.Add("Text", "x0 y100 w88 h43 +0x200 +Center", "URL")
		this.urlInputGui.Add("Edit", "vInputVal x102 y100 w372 h44", "")
		; 确认
		this.urlInputGui.Add("Button", "", "save").OnEvent("Click", ObjBindMethod(this, "SaveUrl"))
	}


	; 触发
	ChangeBefore(wParam, lParam, msg, hwnd) {
		; 监控esc
		if wParam == 27 {
			SetTimer this.timer_func_obj, 0
			StackWidght.CloseGui()
		}
	}

	ChangeAfter(wParam, lParam, msg, hwnd) {
		searchGuiCtrl := GuiCtrlFromHwnd(this.searchGuiCtrlHwnd)
		; 上下键 or esc 不触发搜索，需要中断valChange定时器
		if wParam == 38 || wParam == 40
			SetTimer this.timer_func_obj, 0
		txt := ControlGetText(this.searchGuiCtrlHwnd)
		; 监控combo的回车键
		if wParam == 13 && txt != "" && WinActive("searchGui") {
			try
				Run this.urlMap[ControlGetItems(this.searchGuiCtrlHwnd)[1]]
			catch
				Return
			StackWidght.CloseGui()
			Return
		}
	}

	; 延迟400秒触发
	CtrlChange(GuiCtrlObj, Info) {
		if WinActive("searchGui") {
			SetTimer this.timer_func_obj, -300
		}
	}

	SearchInput() {
		txt := ControlGetText(this.searchGuiCtrlHwnd)
		GuiCtrlObj := GuiCtrlFromHwnd(this.searchGuiCtrlHwnd)

		if txt != ""
			this.InputChange(GuiCtrlObj, txt)
		else {
			if ControlGetItems(this.searchGuiCtrlHwnd).Length < this.keys.Length
				this.ComboSetChooice(this.keys, txt)
		}
	}

	ClickAddUrl(GuiCtrlObj, Info) {
		StackWidght.ShowGui(this.urlInputGui)
	}

	SaveUrl(GuiCtrlObj, Info) {
		key := ControlGetText("Edit1")
		this.urlMap[ControlGetText("Edit1")] := ControlGetText("Edit2")
		jsonString := Jxon_dump(this.urlMap)
		this.keys.push key
		FileDelete(this.configPath)
		FileAppend(jsonString, this.configPath)
		ControlsetText "", "Edit1"
		ControlsetText "", "Edit2"
		MsgBox "save success"
		StackWidght.CloseGui()
	}

	InputChange(GuiCtrlObj, txt) {

		; 匹配符合的选项
		tamp_keys := []
		Loop this.keys.Length {
			button_txt := this.keys[A_Index]
			if InStr(button_txt, txt) > 0 {
				tamp_keys.Push button_txt
			}
		}

		; 判断是否需要切换选项
		change_flag := 0
		current_keys := ControlGetItems(this.searchGuiCtrlHwnd)
		if current_keys.Length != tamp_keys.Length {
			change_flag := 1
		}
		
		if change_flag == 0 {
			Loop tamp_keys.Length {
				if current_keys[A_Index] != tamp_keys[A_Index] {
					change_flag := 1
					break
				}
			}
		}

		; 重置选项
		if change_flag == 1 {
			this.ComboSetChooice(tamp_keys, txt)
		}

	}

	ComboSetChooice(items, txt) {
		searchGuiCtrl := GuiCtrlFromHwnd(this.searchGuiCtrlHwnd)
		searchGuiCtrl.Delete
		searchGuiCtrl.Add items
		ControlHideDropDown searchGuiCtrl
		ControlShowDropDown searchGuiCtrl
		searchGuiCtrl.Text := txt
		SendInput "{End}"
	}

}

; 初始化
linkNavigatorObj := LinkNavigator()

; 注册快捷键 Ctrl+j
^j::
{
	StackWidght.ShowGui(linkNavigatorObj.searchGui)
	; 透明
	;WinSetTransparent 200, "searchGui"
	return
}