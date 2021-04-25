local _={}
_[9]={}
_[8]={}
_[7]={data="ye = ye",tags=_[9]}
_[6]={data="ok = ok",tags=_[8]}
_[5]={_[7]}
_[4]={_[6]}
_[3]={"return"}
_[2]={"text",_[5]}
_[1]={"text",_[4]}
return {_[1],_[2],_[3]}
--[[
{ "text", { {
      data = "ok = ok",
      tags = {}
    } } }
{ "text", { {
      data = "ye = ye",
      tags = {}
    } } }
{ "return" }
]]--