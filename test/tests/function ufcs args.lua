local _={}
_[6]={}
_[5]={tags=_[6],text="k"}
_[4]={tags=_[6],text="o"}
_[3]={_[4],_[5]}
_[2]={"return"}
_[1]={"text",_[3]}
return {_[1],_[2]}
--[[
{ "text", { {
      tags = <1>{},
      text = "o"
    }, {
      tags = <table 1>,
      text = "k"
    } } }
{ "return" }
]]--