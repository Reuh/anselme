local _={}
_[7]={}
_[6]={}
_[5]={data="ok bis",tags=_[7]}
_[4]={data="ok",tags=_[6]}
_[3]={_[4],_[5]}
_[2]={"return"}
_[1]={"text",_[3]}
return {_[1],_[2]}
--[[
{ "text", { {
      data = "ok",
      tags = {}
    }, {
      data = "ok bis",
      tags = {}
    } } }
{ "return" }
]]--