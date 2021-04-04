local _={}
_[9]={}
_[8]={}
_[7]={tags=_[9],data="b c"}
_[6]={tags=_[8],data="a"}
_[5]={_[7]}
_[4]={_[6]}
_[3]={"return"}
_[2]={"text",_[5]}
_[1]={"text",_[4]}
return {_[1],_[2],_[3]}
--[[
{ "text", { {
      data = "a",
      tags = {}
    } } }
{ "text", { {
      data = "b c",
      tags = {}
    } } }
{ "return" }
]]--