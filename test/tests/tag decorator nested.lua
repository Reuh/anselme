local _={}
_[8]={2,3}
_[7]={1,a=_[8]}
_[6]={1}
_[5]={data="bar",tags=_[7]}
_[4]={data="foo",tags=_[6]}
_[3]={_[4],_[5]}
_[2]={"return"}
_[1]={"text",_[3]}
return {_[1],_[2]}
--[[
{ "text", { {
      data = "foo",
      tags = { 1 }
    }, {
      data = "bar",
      tags = { 1,
        a = { 2, 3 }
      }
    } } }
{ "return" }
]]--