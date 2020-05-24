local _={}
_[8]={}
_[7]={}
_[6]={data="b c",tags=_[8]}
_[5]={data="a",tags=_[7]}
_[4]={type="string",value=""}
_[3]={_[5],_[6]}
_[2]={"return",_[4]}
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
{ "return", {
    type = "string",
    value = ""
  } }
]]--