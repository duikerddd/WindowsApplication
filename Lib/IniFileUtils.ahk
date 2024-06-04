; Define the IniFileUtils class
class IniFileUtils {
    ; Constructor
    __New(iniFilePath) {
        this._iniFilePath := iniFilePath
    }
    
    ; Method to read a value from the INI file
    ReadValue(section, key) {
        return IniRead(this._iniFilePath, section, key)
    }
    
    ; Method to write a value to the INI file
    WriteValue(section, key, value) {
        IniWrite(value, this._iniFilePath, section, key)
    }

    DeleteValue(section, key){
        IniDelete(this._iniFilePath, section, key)
    }

}