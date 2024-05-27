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
		this._search_gui.SetFont("s30", "Ms Shell Dlg 2")
		this.inputGuiCtrl := this._search_gui.Add("Text", "vT1 x420 y16 w40 h48 -Border c93ADE2", "+")
		this.inputGuiCtrl.OnEvent("Click", ObjBindMethod(this, "ClickAddUrl"))
		this._search_gui_ctrl_hwnd := this.searchGuiCtrl.Hwnd

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

	; 延迟400秒触发
	CtrlChange(GuiCtrlObj, Info) {
		if WinActive("_search_gui") {
			SetTimer this._time_func_obj, -500
		}
	}

	SearchInput() {
		txt := ControlGetText(this._search_gui_ctrl_hwnd)
		GuiCtrlObj := GuiCtrlFromHwnd(this._search_gui_ctrl_hwnd)

		if txt != ""
			this.InputChange(GuiCtrlObj, txt)
		else {
			if ControlGetItems(this._search_gui_ctrl_hwnd).Length < this._keys.Length
				this.ComboSetChooice(this._keys, txt)
		}
	}

	ClickAddUrl(GuiCtrlObj, Info) {
		StackWidght.ShowGui(this._url_input_gui)
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

		; 匹配符合的选项
		tamp_keys := []
		Loop this._keys.Length {
			button_txt := this._keys[A_Index]
			if InStr(button_txt, txt) > 0 {
				tamp_keys.Push button_txt
			}
		}

		; 重绘标志: 框架部分情况自动重绘有问题
		redraw_flag := 0
		; 判断是否需要切换选项
		change_flag := 0

		; 判断是否需要切换选项 - 长度不一样
		current_keys := ControlGetItems(this._search_gui_ctrl_hwnd)
		if current_keys.Length != tamp_keys.Length {
			change_flag := 1
			if current_keys.Length > tamp_keys.Length {
				redraw_flag := 1
			}
		}

		; 判断是否需要切换选项 - 无匹配
		if change_flag == 0 {
			if tamp_keys.Length == 0 {
				redraw_flag := 1
				change_flag := 1
			}
		}

		; 判断是否需要切换选项 - 内容不一样
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
			this.ComboSetChooice(tamp_keys, txt, redraw_flag)
		}

	}

	ComboSetChooice(items, txt := '', redraw_flag := 0) {
		searchGuiCtrl := GuiCtrlFromHwnd(this._search_gui_ctrl_hwnd)
		searchGuiCtrl.Delete
		if items.Length > 0
			searchGuiCtrl.Add items
		; 目前想不到别的触发重绘的方法. Opt和Redraw都没用, 看源码只有几个ctrl方法会自动调用, 比如SetFont
		; if redraw_flag == 1 {
		; 	; ControlHideDropDown searchGuiCtrl
		; }

		; 因为元素多, 限制Rows, 用这个选项必须重绘
		ControlHideDropDown searchGuiCtrl
		ControlShowDropDown searchGuiCtrl
		if txt != ''
			searchGuiCtrl.Text := txt
		SendInput "{End}"
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