local _={}
_[20]={1}
_[19]={}
_[18]={1}
_[17]={}
_[16]={text=" to move.",tags=_[19]}
_[15]={text=" joystick",tags=_[19]}
_[14]={text="left",tags=_[20]}
_[13]={text="Use ",tags=_[19]}
_[12]={text=" to jump.",tags=_[17]}
_[11]={text="A",tags=_[18]}
_[10]={text="Press ",tags=_[17]}
_[9]={_[15],_[16]}
_[8]={_[13],_[14]}
_[7]={_[12]}
_[6]={_[10],_[11]}
_[5]={"return"}
_[4]={"text",_[9]}
_[3]={"text",_[8]}
_[2]={"text",_[7]}
_[1]={"text",_[6]}
return {_[1],_[2],_[3],_[4],_[5]}
--[[
{ "text", { {
      tags = {},
      text = "Press "
    }, {
      tags = { 1 },
      text = "A"
    } } }
{ "text", { {
      tags = {},
      text = " to jump."
    } } }
{ "text", { {
      tags = {},
      text = "Use "
    }, {
      tags = { 1 },
      text = "left"
    } } }
{ "text", { {
      tags = <1>{},
      text = " joystick"
    }, {
      tags = <table 1>,
      text = " to move."
    } } }
{ "return" }
]]--