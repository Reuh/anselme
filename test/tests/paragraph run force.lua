local _={}
_[23]={}
_[22]={}
_[21]={}
_[20]={}
_[19]={}
_[18]={}
_[17]={}
_[16]={}
_[15]={data="b",tags=_[23]}
_[14]={data="x",tags=_[22]}
_[13]={data="Force no checkpoint:",tags=_[21]}
_[12]={data="b",tags=_[20]}
_[11]={data="a",tags=_[19]}
_[10]={data="From checkpoint:",tags=_[18]}
_[9]={data="a",tags=_[17]}
_[8]={data="Force run checkpoint:",tags=_[16]}
_[7]={_[13],_[14],_[15]}
_[6]={_[10],_[11],_[12]}
_[5]={_[8],_[9]}
_[4]={"return"}
_[3]={"text",_[7]}
_[2]={"text",_[6]}
_[1]={"text",_[5]}
return {_[1],_[2],_[3],_[4]}
--[[
{ "text", { {
      data = "Force run checkpoint:",
      tags = {}
    }, {
      data = "a",
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