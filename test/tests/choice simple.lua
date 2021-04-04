local _={}
_[11]={}
_[10]={}
_[9]={}
_[8]={tags=_[11],data="ok"}
_[7]={tags=_[10],data="ne"}
_[6]={tags=_[9],data="ye"}
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