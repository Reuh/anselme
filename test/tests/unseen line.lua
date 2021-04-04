local _={}
_[13]={}
_[12]={}
_[11]={}
_[10]={}
_[9]={}
_[8]={tags=_[13],data="b"}
_[7]={tags=_[12],data="a"}
_[6]={tags=_[11],data="b"}
_[5]={tags=_[10],data="seen only once"}
_[4]={tags=_[9],data="a"}
_[3]={_[4],_[5],_[6],_[7],_[8]}
_[2]={"return"}
_[1]={"text",_[3]}
return {_[1],_[2]}
--[[
{ "text", { {
      data = "a",
      tags = {}
    }, {
      data = "seen only once",
      tags = {}
    }, {
      data = "b",
      tags = {}
    }, {
      data = "a",
      tags = {}
    }, {
      data = "b",
      tags = {}
    } } }
{ "return" }
]]--