local _={}
_[21]={}
_[20]={}
_[19]={}
_[18]={}
_[17]={}
_[16]={}
_[15]={data="plop",tags=_[21]}
_[14]={data="oh",tags=_[20]}
_[13]={data="ho",tags=_[19]}
_[12]={data="ok",tags=_[18]}
_[11]={data="ne",tags=_[17]}
_[10]={data="ye",tags=_[16]}
_[9]={_[15]}
_[8]={_[13],_[14]}
_[7]={_[12]}
_[6]={_[10],_[11]}
_[5]={"return"}
_[4]={"text",_[9]}
_[3]={"choice",_[8]}
_[2]={"text",_[7]}
_[1]={"choice",_[6]}
return {_[1],_[2],_[3],_[4],_[5]}
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
{ "choice", { {
      data = "ho",
      tags = {}
    }, {
      data = "oh",
      tags = {}
    } } }
{ "text", { {
      data = "plop",
      tags = {}
    } } }
{ "return" }
]]--