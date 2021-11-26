local _={}
_[9]={}
_[8]={tags=_[9],text="abc"}
_[7]={tags=_[9],text=" = "}
_[6]={tags=_[9],text="abc"}
_[5]={tags=_[9],text=" = "}
_[4]={tags=_[9],text="abc"}
_[3]={_[4],_[5],_[6],_[7],_[8]}
_[2]={"return"}
_[1]={"text",_[3]}
return {_[1],_[2]}
--[[
{ "text", { {
      tags = <1>{},
      text = "abc"
    }, {
      tags = <table 1>,
      text = " = "
    }, {
      tags = <table 1>,
      text = "abc"
    }, {
      tags = <table 1>,
      text = " = "
    }, {
      tags = <table 1>,
      text = "abc"
    } } }
{ "return" }
]]--