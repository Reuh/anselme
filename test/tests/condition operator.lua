local _={}
_[13]={}
_[12]={}
_[11]={}
_[10]={tags=_[13],text="c"}
_[9]={tags=_[13],text="a "}
_[8]={tags=_[11],text=" c"}
_[7]={tags=_[12],text="b"}
_[6]={tags=_[11],text="a "}
_[5]={_[9],_[10]}
_[4]={_[6],_[7],_[8]}
_[3]={"return"}
_[2]={"text",_[5]}
_[1]={"text",_[4]}
return {_[1],_[2],_[3]}
--[[
{ "text", { {
      tags = <1>{},
      text = "a "
    }, {
      tags = {},
      text = "b"
    }, {
      tags = <table 1>,
      text = " c"
    } } }
{ "text", { {
      tags = <1>{},
      text = "a "
    }, {
      tags = <table 1>,
      text = "c"
    } } }
{ "return" }
]]--