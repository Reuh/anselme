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
_[16]={tags=_[25],data="b"}
_[15]={tags=_[24],data="x"}
_[14]={tags=_[23],data="Force no checkpoint:"}
_[13]={tags=_[22],data="b"}
_[12]={tags=_[21],data="a"}
_[11]={tags=_[20],data="From checkpoint:"}
_[10]={tags=_[19],data="b"}
_[9]={tags=_[18],data="a"}
_[8]={tags=_[17],data="Force run from checkpoint:"}
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
      data = "Force run from checkpoint:",
      tags = {}
    }, {
      data = "a",
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