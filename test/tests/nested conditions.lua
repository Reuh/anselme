local _={}
_[11]={}
_[10]={}
_[9]={}
_[8]={data="da",tags=_[11]}
_[7]={data="ye",tags=_[10]}
_[6]={data="yes",tags=_[9]}
_[5]={_[7],_[8]}
_[4]={_[6]}
_[3]={"return"}
_[2]={"text",_[5]}
_[1]={"text",_[4]}
return {_[1],_[2],_[3]}
--[[
{ "text", { {
      data = "yes",
      tags = {}
    } } }
{ "text", { {
      data = "ye",
      tags = {}
    }, {
      data = "da",
      tags = {}
    } } }
{ "return" }
]]--