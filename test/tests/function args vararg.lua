local _={}
_[7]={}
_[6]={}
_[5]={tags=_[7],data="[o, k]"}
_[4]={tags=_[6],data="ok"}
_[3]={_[4],_[5]}
_[2]={"return"}
_[1]={"text",_[3]}
return {_[1],_[2]}
--[[
{ "text", { {
      data = "ok",
      tags = {}
    }, {
      data = "[o, k]",
      tags = {}
    } } }
{ "return" }
]]--