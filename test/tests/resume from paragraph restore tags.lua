local _={}
_[32]={}
_[31]={a="a"}
_[30]={a="a",b="b"}
_[29]={a="a",b="b",c="c"}
_[28]={}
_[27]={a="a",b="b"}
_[26]={a="a"}
_[25]={data="e",tags=_[32]}
_[24]={data="d",tags=_[31]}
_[23]={data="c",tags=_[30]}
_[22]={data="b",tags=_[29]}
_[21]={data="e",tags=_[28]}
_[20]={data="d",tags=_[26]}
_[19]={data="c",tags=_[27]}
_[18]={data="a",tags=_[26]}
_[17]={_[25]}
_[16]={_[24]}
_[15]={_[23]}
_[14]={_[22]}
_[13]={_[21]}
_[12]={_[20]}
_[11]={_[19]}
_[10]={_[18]}
_[9]={"return"}
_[8]={"text",_[17]}
_[7]={"text",_[16]}
_[6]={"text",_[15]}
_[5]={"text",_[14]}
_[4]={"text",_[13]}
_[3]={"text",_[12]}
_[2]={"text",_[11]}
_[1]={"text",_[10]}
return {_[1],_[2],_[3],_[4],_[5],_[6],_[7],_[8],_[9]}
--[[
{ "text", { {
      data = "a",
      tags = {
        a = "a"
      }
    } } }
{ "text", { {
      data = "c",
      tags = {
        a = "a",
        b = "b"
      }
    } } }
{ "text", { {
      data = "d",
      tags = {
        a = "a"
      }
    } } }
{ "text", { {
      data = "e",
      tags = {}
    } } }
{ "text", { {
      data = "b",
      tags = {
        a = "a",
        b = "b",
        c = "c"
      }
    } } }
{ "text", { {
      data = "c",
      tags = {
        a = "a",
        b = "b"
      }
    } } }
{ "text", { {
      data = "d",
      tags = {
        a = "a"
      }
    } } }
{ "text", { {
      data = "e",
      tags = {}
    } } }
{ "return" }
]]--