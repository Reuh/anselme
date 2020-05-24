local _={}
_[11]={}
_[10]={}
_[9]={}
_[8]={data="ok",tags=_[11]}
_[7]={data="ne",tags=_[10]}
_[6]={data="ye",tags=_[9]}
_[5]={_[8]}
_[4]={_[6],_[7]}
_[3]={"return"}
_[2]={"text",_[5]}
_[1]={"choice",_[4]}
return {_[1],_[2],_[3]}
--[[
{ "choice", { {
      data = "ye",
      tags = {}
    }, {
      data = "ne",
      tags = {}
    } } }
{ "text", { {
      data = "ok",
      tags = {}
    } } }
{ "return" }
]]--