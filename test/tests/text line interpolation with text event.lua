local _={}
_[16]={1}
_[15]={}
_[14]={1}
_[13]={}
_[12]={tags=_[15],text=" to move."}
_[11]={tags=_[15],text=" joystick"}
_[10]={tags=_[16],text="left"}
_[9]={tags=_[15],text="Use "}
_[8]={tags=_[13],text=" to jump."}
_[7]={tags=_[14],text="A"}
_[6]={tags=_[13],text="Press "}
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
      text = "A"
    }, {
      tags = <table 1>,
      text = " to jump."
    } } }
{ "text", { {
      tags = <1>{},
      text = "Use "
    }, {
      tags = { 1 },
      text = "left"
    }, {
      tags = <table 1>,
      text = " joystick"
    }, {
      tags = <table 1>,
      text = " to move."
    } } }
{ "return" }
]]--