local _={}
_[25]={}
_[24]={}
_[23]={}
_[22]={}
_[21]={}
_[20]={}
_[19]={}
_[18]={}
_[17]={}
_[16]={data="b",tags=_[25]}
_[15]={data="x",tags=_[24]}
_[14]={data="Force no checkpoint:",tags=_[23]}
_[13]={data="b",tags=_[22]}
_[12]={data="a",tags=_[21]}
_[11]={data="From checkpoint:",tags=_[20]}
_[10]={data="b",tags=_[19]}
_[9]={data="x",tags=_[18]}
_[8]={data="No checkpoint:",tags=_[17]}
_[7]={_[14],_[15],_[16]}
_[6]={_[11],_[12],_[13]}
_[5]={_[8],_[9],_[10]}
_[4]={"return"}
_[3]={"text",_[7]}
_[2]={"text",_[6]}
_[1]={"text",_[5]}
return {_[1],_[2],_[3],_[4]}
--[[
{ "text", { {
      data = "No checkpoint:",
      tags = {}
    }, {
      data = "x",
      tags = {}
    }, {
      data = "b",
      tags = {}
    } } }
{ "text", { {
      data = "From checkpoint:",
      tags = {}
    }, {
      data = "a",
      tags = {}
    }, {
      data = "b",
      tags = {}
    } } }
{ "text", { {
      data = "Force no checkpoint:",
      tags = {}
    }, {
      data = "x",
      tags = {}
    }, {
      data = "b",
      tags = {}
    } } }
{ "return" }
]]--