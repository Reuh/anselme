local _={}
_[31]={}
_[30]={}
_[29]={}
_[28]={}
_[27]={}
_[26]={}
_[25]={}
_[24]={}
_[23]={data="h",tags=_[31]}
_[22]={data="g",tags=_[30]}
_[21]={data="f",tags=_[29]}
_[20]={data="e",tags=_[28]}
_[19]={data="d",tags=_[27]}
_[18]={data="c",tags=_[26]}
_[17]={data="b",tags=_[25]}
_[16]={data="a",tags=_[24]}
_[15]={_[23]}
_[14]={_[22]}
_[13]={_[21]}
_[12]={_[20]}
_[11]={_[18],_[19]}
_[10]={_[17]}
_[9]={_[16]}
_[8]={"return"}
_[7]={"choice",_[15]}
_[6]={"text",_[14]}
_[5]={"choice",_[13]}
_[4]={"text",_[12]}
_[3]={"text",_[11]}
_[2]={"text",_[10]}
_[1]={"text",_[9]}
return {_[1],_[2],_[3],_[4],_[5],_[6],_[7],_[8]}
--[[
{ "text", { {
      data = "a",
      tags = {}
    } } }
{ "text", { {
      data = "b",
      tags = {}
    } } }
{ "text", { {
      data = "c",
      tags = {}
    }, {
      data = "d",
      tags = {}
    } } }
{ "text", { {
      data = "e",
      tags = {}
    } } }
{ "choice", { {
      data = "f",
      tags = {}
    } } }
{ "text", { {
      data = "g",
      tags = {}
    } } }
{ "choice", { {
      data = "h",
      tags = {}
    } } }
{ "return" }
]]--