local _={}
_[6]={1}
_[5]={tags=_[6],data="bar"}
_[4]={tags=_[6],data="foo"}
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