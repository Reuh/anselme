local _={}
_[23]={}
_[22]={}
_[21]={}
_[20]={}
_[19]={}
_[18]={}
_[17]={}
_[16]={}
_[15]={tags=_[23],data="b"}
_[14]={tags=_[22],data="x"}
_[13]={tags=_[21],data="Force no checkpoint:"}
_[12]={tags=_[20],data="b"}
_[11]={tags=_[19],data="a"}
_[10]={tags=_[18],data="From checkpoint:"}
_[9]={tags=_[17],data="a"}
_[8]={tags=_[16],data="Force run checkpoint:"}
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