local _={}
_[13]={}
_[12]={}
_[11]={}
_[10]={}
_[9]={}
_[8]={tags=_[13],text="b"}
_[7]={tags=_[12],text="a"}
_[6]={tags=_[11],text="b"}
_[5]={tags=_[10],text="seen only once"}
_[4]={tags=_[9],text="a"}
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
      text = "seen only once"
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