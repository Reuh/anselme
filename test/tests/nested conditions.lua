local _={}
_[11]={}
_[10]={}
_[9]={}
_[8]={tags=_[11],text="da"}
_[7]={tags=_[10],text="ye"}
_[6]={tags=_[9],text="yes"}
_[5]={_[7],_[8]}
_[4]={_[6]}
_[3]={"return"}
_[2]={"text",_[5]}
_[1]={"text",_[4]}
return {_[1],_[2],_[3]}
--[[
{ "text", { {
      tags = {},
      text = "yes"
    } } }
{ "text", { {
      tags = {},
      text = "ye"
    }, {
      tags = {},
      text = "da"
    } } }
{ "return" }
]]--