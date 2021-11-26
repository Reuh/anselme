local _={}
_[13]={}
_[12]={}
_[11]={}
_[10]={tags=_[13],text="generic minus"}
_[9]={tags=_[12],text="heh minus lol"}
_[8]={tags=_[11],text="-3"}
_[7]={_[10]}
_[6]={_[9]}
_[5]={_[8]}
_[4]={"return"}
_[3]={"text",_[7]}
_[2]={"text",_[6]}
_[1]={"text",_[5]}
return {_[1],_[2],_[3],_[4]}
--[[
{ "text", { {
      tags = {},
      text = "-3"
    } } }
{ "text", { {
      tags = {},
      text = "heh minus lol"
    } } }
{ "text", { {
      tags = {},
      text = "generic minus"
    } } }
{ "return" }
]]--