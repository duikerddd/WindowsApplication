; Define the IniFileUtils class
class IniFileUtils {
    ; Constructor
    __New(iniFilePath) {
        this._iniFilePath := iniFilePath
    }

    ReadSectionList(){
        listStr := IniRead(this._iniFilePath)
        list := StrSplit(listStr, "`n")
        return list
    }

    ReadSection(section){
        hashStr := IniRead(this._iniFilePath, section, , "")
        hashArr := StrSplit(hashStr, "`n")
        hash := Map()
        Loop hashArr.Length {
            key_val_arr := StrSplit(hashArr[A_Index], "=")
            hash[key_val_arr[1]] := key_val_arr[2]
        }
        return hash
    }
    
    ReadValue(section, key) {
        return IniRead(this._iniFilePath, section, key)
    }
    
    WriteValue(section, key, value) {
        IniWrite(value, this._iniFilePath, section, key)
    }

    DeleteKey(section, key){
        IniDelete(this._iniFilePath, section, key)
    }

}