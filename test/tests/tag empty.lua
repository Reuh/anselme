local _={}
_[6]={1}
_[5]={data="bar",tags=_[6]}
_[4]={data="foo",tags=_[6]}
_[3]={_[4],_[5]}
_[2]={"return"}
_[1]={"text",_[3]}
return {_[1],_[2]}
--[[
{ "text", { {
      data = "foo",
      tags = <1>{ 1 }
    }, {
      data = "bar",
      tags = <table 1>
    } } }
{ "return" }
]]--