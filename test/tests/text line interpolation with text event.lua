local _={}
_[16]={1}
_[15]={}
_[14]={1}
_[13]={}
_[12]={text=" to move.",tags=_[15]}
_[11]={text="joystick",tags=_[15]}
_[10]={text="left ",tags=_[16]}
_[9]={text="Use ",tags=_[15]}
_[8]={text="to jump.",tags=_[13]}
_[7]={text="A ",tags=_[14]}
_[6]={text="Press ",tags=_[13]}
_[5]={_[9],_[10],_[11],_[12]}
_[4]={_[6],_[7],_[8]}
_[3]={"return"}
_[2]={"text",_[5]}
_[1]={"text",_[4]}
return {_[1],_[2],_[3]}
--[[
{ "text", { {
      tags = <1>{},
      text = "Press "
    }, {
      tags = { 1 },
      text = "A "
    }, {
      tags = <table 1>,
      text = "to jump."
    } } }
{ "text", { {
      tags = <1>{},
      text = "Use "
    }, {
      tags = { 1 },
      text = "left "
    }, {
      tags = <table 1>,
      text = "joystick"
    }, {
      tags = <table 1>,
      text = " to move."
    } } }
{ "return" }
]]--