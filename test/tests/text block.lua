local _={}
_[7]={}
_[6]={}
_[5]={data="b c",tags=_[7]}
_[4]={data="a",tags=_[6]}
_[3]={_[4],_[5]}
_[2]={"return"}
_[1]={"text",_[3]}
return {_[1],_[2]}
--[[
{ "text", { {
      data = "a",
      tags = {}
    }, {
      data = "b c",
      tags = {}
    } } }
{ "return" }
]]--