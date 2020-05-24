local _={}
_[6]={}
_[5]={data="before: 2",tags=_[6]}
_[4]={_[5]}
_[3]={"return",""}
_[2]={"wait",0}
_[1]={"text",_[4]}
return {_[1],_[2],_[3]}
--[[
{ "text", { {
      data = "before: 2",
      tags = {}
    } } }
{ "wait", 0 }
{ "return", "" }
]]--