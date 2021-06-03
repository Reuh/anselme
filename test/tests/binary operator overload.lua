local _={}
_[13]={}
_[12]={}
_[11]={}
_[10]={data="generic minus",tags=_[13]}
_[9]={data="heh minus lol",tags=_[12]}
_[8]={data="-3",tags=_[11]}
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
      data = "-3",
      tags = {}
    } } }
{ "text", { {
      data = "heh minus lol",
      tags = {}
    } } }
{ "text", { {
      data = "generic minus",
      tags = {}
    } } }
{ "return" }
]]--