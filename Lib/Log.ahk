; 监听键盘
{
	InstallKeybdHook
}

class Log {

	static path := A_WorkingDir "\log.txt"

	static Info(logMessage) {
		
		if !FileExist(Log.path)
			FileAppend("`n", Log.path)
		
	    FileAppend "[" A_PriorKey "]" logMessage "`n", Log.path
	}
	
}