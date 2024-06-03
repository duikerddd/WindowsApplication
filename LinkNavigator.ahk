#Requires AutoHotkey v2.0
#SingleInstance Force
#Include <StackWidget>
#Include <_JXON>
#Include <Log>
Persistent

class LinkNavigator {

	; 常量
	CONFIG_PATH := A_WorkingDir "\urls.json"
	BOOK_MARK := Map(
		'Edge', 'C:\Users\' A_UserName '\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks'
	)

	; 成员变量
	_keys := []
	_search_gui_ctrl_hwnd := ""
	_search_gui := ""
	_url_input_gui := ""
	_url_map := ""
	_time_func_obj := ObjBindMethod(this, "SearchInput")

	__New() {
		this.ReadConfigFile

		this.InitGui

		this.SyncEdgeBookMark

		this.InitComboData

		; change前监听
		OnMessage(0x100, ObjBindMethod(this, "ChangeBefore"))
		; change后监听
		OnMessage(0x101, ObjBindMethod(this, "ChangeAfter"))
	}


	ReadConfigFile() {
		; 读取文件
		if !FileExist(this.CONFIG_PATH)
			FileAppend("{}", this.CONFIG_PATH)
		config := FileRead(this.CONFIG_PATH)
		; 提取url数据
		this._url_map := Jxon_load(&config)
	}

	InitComboData() {
		For key in this._url_map
			this._keys.Push key
		searchGuiCtrl := GuiCtrlFromHwnd(this._search_gui_ctrl_hwnd)
		searchGuiCtrl.Delete
		searchGuiCtrl.Add this._keys
	}

	InitGui() {
		this._search_gui := Gui("-Caption -Border", "search_gui")
		this._url_input_gui := Gui("-Caption", "url_input_gui")

		; 搜索下拉框
		this._search_gui.SetFont("s17 Norm", "Myanmar Text")
		this.searchGuiCtrl := this._search_gui.Add("ComboBox", "vCB R5 x10 y16 w400")
		this.searchGuiCtrl.OnEvent("Change", ObjBindMethod(this, "CtrlChange"))
		; 录入按钮
		this._search_gui.SetFont("s20", "Ms Shell Dlg 2")
		this.inputGuiCtrl := this._search_gui.Add("Button", "vT1 x420 y16 w40 h48 -Border c93ADE2", "+")
		this.inputGuiCtrl.OnEvent("Click", ObjBindMethod(this, "ClickAddUrl"))
		this._search_gui_ctrl_hwnd := this.searchGuiCtrl.Hwnd

		; 删除按钮
		this._search_gui.SetFont("s20", "Ms Shell Dlg 2")
		this.inputGuiCtrl := this._search_gui.Add("Button", "vT2 x470 y16 w40 h48 ", "-")
		this.inputGuiCtrl.OnEvent("Click", ObjBindMethod(this, "ClickDeleteUrl"))

		; 录入框
		this._url_input_gui.SetFont("s16", "Segoe UI")
		this._url_input_gui.Add("Text", "x0 y40 w108 h43 +0x200 +Center", "Name")
		this._url_input_gui.Add("Edit", "vInputKey x102 y40 w372 h44", "")
		this._url_input_gui.Add("Text", "x0 y100 w88 h43 +0x200 +Center", "URL")
		this._url_input_gui.Add("Edit", "vInputVal x102 y100 w372 h44", "")
		; 确认
		this._url_input_gui.Add("Button", "", "save").OnEvent("Click", ObjBindMethod(this, "SaveUrl"))
	}


	; 触发
	ChangeBefore(wParam, lParam, msg, hwnd) {
		; 监控esc
		if wParam == 27 {
			SetTimer this._time_func_obj, 0
			StackWidght.CloseGui()
		}
	}

	ChangeAfter(wParam, lParam, msg, hwnd) {
		searchGuiCtrl := GuiCtrlFromHwnd(this._search_gui_ctrl_hwnd)
		; 上下键 or esc 不触发搜索，需要中断valChange定时器
		if wParam == 38 || wParam == 40
			SetTimer this._time_func_obj, 0
		txt := ControlGetText(this._search_gui_ctrl_hwnd)
		; 监控combo的回车键
		if wParam == 13 && txt != "" && WinActive("search_gui") {
			try {
				idx := ControlGetIndex(this._search_gui_ctrl_hwnd)
				; 没有在选项上，则匹配第一个
				if idx == 0 
					idx := 1
				choice_array := ControlGetItems(this._search_gui_ctrl_hwnd)
				Run this._url_map[choice_array[idx]]
			} catch
				Return
			StackWidght.CloseGui()
			Return
		}
	}

	; 延迟800秒触发
	CtrlChange(GuiCtrlObj, Info) {
		if WinActive("search_gui") {
			SetTimer this._time_func_obj, -800
		}
	}

	SearchInput() {
		txt := ControlGetText(this._search_gui_ctrl_hwnd)
		GuiCtrlObj := GuiCtrlFromHwnd(this._search_gui_ctrl_hwnd)
		ControlShowDropDown GuiCtrlFromHwnd(this._search_gui_ctrl_hwnd)
		if txt != ""{
			try
				ControlChooseString txt, GuiCtrlObj
		    catch {
				GuiCtrlObj.Text := txt
				SendInput "{End}"
			}
		}
	}

	ClickAddUrl(GuiCtrlObj, Info) {
		StackWidght.ShowGui(this._url_input_gui)
	}

	ClickDeleteUrl(GuiCtrlObj, Info) {
		try{
			txt := ControlGetText(this._search_gui_ctrl_hwnd)
			idx := ControlFindItem(txt, this._search_gui_ctrl_hwnd)
			ControlDeleteItem idx, this._search_gui_ctrl_hwnd
		}catch{
			return
		}
	}

	SaveUrl(GuiCtrlObj, Info) {
		key := ControlGetText("Edit1")
		this._url_map[ControlGetText("Edit1")] := ControlGetText("Edit2")
		jsonString := Jxon_dump(this._url_map)
		this._keys.push key
		FileDelete(this.CONFIG_PATH)
		FileAppend(jsonString, this.CONFIG_PATH)
		ControlsetText "", "Edit1"
		ControlsetText "", "Edit2"
		MsgBox "save success"
		StackWidght.CloseGui()
	}

	InputChange(GuiCtrlObj, txt) {
		ControlChooseString txt, GuiCtrlObj
	}

	SyncEdgeBookMark() {
		; 读取书签
		bookMarkPath := this.BOOK_MARK["Edge"]
		if !FileExist(bookMarkPath)
			Return
		bookMark := FileRead(bookMarkPath, "UTF-8")
		bookMarkMap := Jxon_load(&bookMark)
		this.RedeEdgeBookMark(bookMarkMap["roots"]["bookmark_bar"]["children"])
	}

	RedeEdgeBookMark(bookMarkMap, prefix := "") {
		; 提取url数据
		for value in bookMarkMap {
			key := Trim(value["name"])
			if value["type"] == "url" {
				if this._url_map.Get(key, false)
					Continue

				if prefix == ''
					this._url_map[key] := value["url"]
				else
					this._url_map[prefix "-" key] := value["url"]
			} else {
				; 目录
				this.RedeEdgeBookMark(value["children"], key)
			}
		}
	}

}

; 初始化
linkNavigatorObj := LinkNavigator()

; 注册快捷键 Ctrl+j
^j::
{
	StackWidght.ShowGui(linkNavigatorObj._search_gui)
	ControlShowDropDown GuiCtrlFromHwnd(linkNavigatorObj._search_gui_ctrl_hwnd)
	; 透明
	;WinSetTransparent 200, "_search_gui"
	return
}