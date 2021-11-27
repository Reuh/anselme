local _={}
_[13]={}
_[12]={}
_[11]={}
_[10]={}
_[9]={}
_[8]={text="b",tags=_[13]}
_[7]={text="a",tags=_[12]}
_[6]={text="b",tags=_[11]}
_[5]={text="seen only once ",tags=_[10]}
_[4]={text="a",tags=_[9]}
_[3]={_[4],_[5],_[6],_[7],_[8]}
_[2]={"return"}
_[1]={"text",_[3]}
return {_[1],_[2]}
--[[
{ "text", { {
      tags = {},
      text = "a"
    }, {
      tags = {},
      text = "seen only once "
    }, {
      tags = {},
      text = "b"
    }, {
      tags = {},
      text = "a"
    }, {
      tags = {},
      text = "b"
    } } }
{ "return" }
]]--