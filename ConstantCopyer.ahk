#Requires AutoHotkey v2.0
#SingleInstance Force
#Include <StackWidget>
#Include <IniFileUtils>
Persistent

; 常量
CONFIG_PATH := A_WorkingDir "\constant.ini"
CONFIG_SECTION := "constant"

class ConstantCopyer {

	_main_gui := ""
	_add_gui := ""
	_combo_gui_ctrl := ""
	_ini_file_util := ""
	_combo_items := []
	_time_func_obj := ObjBindMethod(this, "SearchInput")

	__New() {
		this.InitGui

		this.InitData

		; change前监听
		OnMessage(0x100, ObjBindMethod(this, "ChangeBefore"))
		; change后监听
		OnMessage(0x101, ObjBindMethod(this, "ChangeAfter"))
	}

	InitGui() {
		; 主窗口
		this._main_gui := Gui("+Caption", "main_gui")

		; 下拉框
		this._main_gui.SetFont("s17 Norm", "Myanmar Text")
		this._combo_gui_ctrl := this._main_gui.Add("ComboBox", "vCB R5 x10 y16 w400")
		this._combo_gui_ctrl.OnEvent("Change", ObjBindMethod(this, "ChangeText"))

		; 复制按钮
		this._main_gui.SetFont("s20", "Ms Shell Dlg 2")
		copy_gui_ctrl := this._main_gui.Add("Button", "vT1 x420 y16 w40 h48 -Border c93ADE2", "C")
		copy_gui_ctrl.OnEvent("Click", ObjBindMethod(this, "ClickCopy"))

		; 录入按钮
		this._main_gui.SetFont("s20", "Ms Shell Dlg 2")
		add_gui_ctrl := this._main_gui.Add("Button", "vT2 x470 y16 w40 h48 ", "+")
		add_gui_ctrl.OnEvent("Click", ObjBindMethod(this, "ClickAdd"))

		; 刪除按钮
		this._main_gui.SetFont("s20", "Ms Shell Dlg 2")
		del_gui_ctrl := this._main_gui.Add("Button", "vT3 x520 y16 w40 h48 ", "-")
		del_gui_ctrl.OnEvent("Click", ObjBindMethod(this, "ClickDelete"))
	}

	InitData() {
		this._ini_file_util := IniFileUtils(CONFIG_PATH)
		this._combo_items := this._ini_file_util.ReadSection(CONFIG_SECTION, true)
		for k in this._combo_items
			OutputDebug k "`n"
		this._combo_gui_ctrl.Add(this._combo_items)
	}

	ChangeText(GuiCtrlObj, Info) {
		if WinActive("main_gui") {
			SetTimer this._time_func_obj, -500
		}
	}

	SearchInput() {
		txt := ControlGetText(this._combo_gui_ctrl)
		if txt != "" {
			Loop this._combo_items.Length {
				key := this._combo_items[A_Index]
				OutputDebug key "`n"

				if InStr(key, txt) {
					if ControlGetIndex(this._combo_gui_ctrl) == A_Index {
						return
					}

					OutputDebug "匹配成功:" txt
					ControlChooseIndex A_Index, this._combo_gui_ctrl
					ControlShowDropDown this._combo_gui_ctrl
					return
				}
			}
		}
	}

	ClickAdd(GuiCtrlObj, Info) {
		text := Trim(ControlGetText(this._combo_gui_ctrl))

		if text == "" {
			MsgBox "Please input text"
			return
		}

		try {
			def_val := this._ini_file_util.ReadValue(CONFIG_SECTION, text)
		} catch {
			def_val := ""
		}
		OutputDebug "def_val:" def_val

		IB := InputBox("", "Input val", "h70", def_val)
		OutputDebug "text:" text " val:" IB.Value
		
		if IB.Value == "" && IB.Result == "OK" {
			MsgBox "Please input val"
		}

		this._ini_file_util.WriteValue(CONFIG_SECTION, text, IB.Value)

		try {
			ControlFindItem(text, this._combo_gui_ctrl)
		} catch {
			ControlAddItem(text, this._combo_gui_ctrl)
		}
		this.RefreshKeys()
	}

	RefreshKeys() {
		this._combo_items := this._ini_file_util.ReadSection(CONFIG_SECTION, true)
	}

	ClickDelete(GuiCtrlObj, Info) {
		text := ControlGetText(this._combo_gui_ctrl)
		this._ini_file_util.DeleteKey(CONFIG_SECTION, text)
		idx := ControlGetIndex(this._combo_gui_ctrl)
		ControlDeleteItem(idx, this._combo_gui_ctrl)
		this.RefreshKeys()
	}

	ClickCopy(GuiCtrlObj, Info) {
		try {
			text := ControlGetText(this._combo_gui_ctrl)
			A_Clipboard := this._ini_file_util.ReadValue(CONFIG_SECTION, text)
			OutputDebug A_Clipboard
			StackWidght.CloseGui()
		} catch {
			MsgBox("Input not found", "warning", "0x2000")
		}
	}

	; 触发
	ChangeBefore(wParam, lParam, msg, hwnd) {
		OutputDebug "ChangeBefore`n"
		; 监控esc
		if wParam == 27 {
			ControlHideDropDown this._combo_gui_ctrl
			StackWidght.CloseGui()
		}
		; 监控combo的回车键
		if wParam == 13 && WinActive("main_gui") && this._main_gui.FocusedCtrl && this._combo_gui_ctrl.Focused {
			this.ClickCopy(this._combo_gui_ctrl, "")
			Return
		}
	}

	ChangeAfter(wParam, lParam, msg, hwnd) {
		OutputDebug "ChangeAfter`n"
	}

}

; 初始化
constant_copyer := ConstantCopyer()

; 注册快捷键 Ctrl+Shift+c
^+c::
{
	StackWidght.ShowGui(constant_copyer._main_gui)
	return
}