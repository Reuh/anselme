local _={}
_[10]={}
_[9]={}
_[8]={}
_[7]={text="c",tags=_[10]}
_[6]={text="",tags=_[10]}
_[5]={text="b ",tags=_[9]}
_[4]={text="a ",tags=_[8]}
_[3]={_[4],_[5],_[6],_[7]}
_[2]={"return"}
_[1]={"text",_[3]}
return {_[1],_[2]}
--[[
{ "text", { {
      tags = {},
      text = "a "
    }, {
      tags = {},
      text = "b "
    }, {
      tags = <1>{},
      text = ""
    }, {
      tags = <table 1>,
      text = "c"
    } } }
{ "return" }
]]--