local _={}
_[15]={}
_[14]={}
_[13]={}
_[12]={}
_[11]={}
_[10]={data="ok",tags=_[15]}
_[9]={data="a.\240\159\145\129\239\184\143: 1",tags=_[14]}
_[8]={data="ko",tags=_[13]}
_[7]={data="In function:",tags=_[12]}
_[6]={data="a.\240\159\145\129\239\184\143: 0",tags=_[11]}
_[5]={_[7],_[8],_[9],_[10]}
_[4]={_[6]}
_[3]={"return"}
_[2]={"text",_[5]}
_[1]={"text",_[4]}
return {_[1],_[2],_[3]}
--[[
{ "text", { {
      data = "a.👁️: 0",
      tags = {}
    } } }
{ "text", { {
      data = "In function:",
      tags = {}
    }, {
      data = "ko",
      tags = {}
    }, {
      data = "a.👁️: 1",
      tags = {}
    }, {
      data = "ok",
      tags = {}
    } } }
{ "return" }
]]--