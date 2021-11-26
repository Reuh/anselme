local _={}
_[19]={}
_[18]={}
_[17]={1}
_[16]={}
_[15]={text="No",tags=_[19]}
_[14]={text=" to jump.",tags=_[16]}
_[13]={text="JOIN",tags=_[16]}
_[12]={text="Suprise choice!",tags=_[18]}
_[11]={text="A",tags=_[17]}
_[10]={text="Press ",tags=_[16]}
_[9]={text="ok",tags=_[16]}
_[8]={_[15]}
_[7]={_[12],_[13],_[14]}
_[6]={_[10],_[11]}
_[5]={_[9]}
_[4]={_[6],_[7],_[8]}
_[3]={"return"}
_[2]={"text",_[5]}
_[1]={"choice",_[4]}
return {_[1],_[2],_[3]}
--[[
{ "choice", { { {
        tags = <1>{},
        text = "Press "
      }, {
        tags = { 1 },
        text = "A"
      } }, { {
        tags = {},
        text = "Suprise choice!"
      }, {
        tags = <table 1>,
        text = "JOIN"
      }, {
        tags = <table 1>,
        text = " to jump."
      } }, { {
        tags = {},
        text = "No"
      } } } }
{ "text", { {
      tags = {},
      text = "ok"
    } } }
{ "return" }
]]--