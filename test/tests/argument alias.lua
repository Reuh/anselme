local _={}
_[7]={}
_[6]={tags=_[7],text="bibi"}
_[5]={tags=_[7],text=" = "}
_[4]={tags=_[7],text="bibi"}
_[3]={_[4],_[5],_[6]}
_[2]={"return"}
_[1]={"text",_[3]}
return {_[1],_[2]}
--[[
{ "text", { {
      tags = <1>{},
      text = "bibi"
    }, {
      tags = <table 1>,
      text = " = "
    }, {
      tags = <table 1>,
      text = "bibi"
    } } }
{ "return" }
]]--