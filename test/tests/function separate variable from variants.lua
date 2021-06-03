local _={}
_[5]={}
_[4]={data="2 = 2",tags=_[5]}
_[3]={_[4]}
_[2]={"return"}
_[1]={"text",_[3]}
return {_[1],_[2]}
--[[
{ "text", { {
      data = "2 = 2",
      tags = {}
    } } }
{ "return" }
]]--