local _={}
_[5]={}
_[4]={tags=_[5],data="[o, k]"}
_[3]={_[4]}
_[2]={"return"}
_[1]={"text",_[3]}
return {_[1],_[2]}
--[[
{ "text", { {
      data = "[o, k]",
      tags = {}
    } } }
{ "return" }
]]--