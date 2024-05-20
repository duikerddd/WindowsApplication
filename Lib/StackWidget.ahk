class StackWidght {               
	       
    static winStack := []           
                                  
	static ShowGui(GuiObj){       
		; 隐藏上个窗口                  
		if StackWidght.winStack.Length > 0    
			StackWidght.winStack[-1].Hide()   
                                  
		; 打开新窗口并记录                
		GuiObj.show               
		StackWidght.winStack.push(GuiObj)     
	}                             
                                  
	static CloseGui(){            
		guiCount   := StackWidght.winStack.Length
		guiObj     := StackWidght.winStack.pop() 
		; 两个窗口做窗口回退               
		if guiCount > 1 {         
			; 隐藏当前窗口              
			guiObj.Hide()         
			; 展示上个窗口              
			StackWidght.winStack[-1].Show()   
			Return                
		}			              
		; 一个窗口做关闭                 
		WinClose                  
	}                             
                                  
}                                 