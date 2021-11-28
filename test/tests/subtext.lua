local _={}
_[33]={1,[3]=3}
_[32]={1}
_[31]={}
_[30]={1,2}
_[29]={}
_[28]={5}
_[27]={}
_[26]={}
_[25]={5}
_[24]={}
_[23]={tags=_[31],text=" to jump."}
_[22]={tags=_[32],text="-"}
_[21]={tags=_[33],text="button"}
_[20]={tags=_[32],text="-"}
_[19]={tags=_[31],text="Press "}
_[18]={tags=_[29],text="to jump."}
_[17]={tags=_[30],text="A "}
_[16]={tags=_[29],text="Press "}
_[15]={tags=_[27],text=" to jump."}
_[14]={tags=_[28],text="A"}
_[13]={tags=_[27],text="Press "}
_[12]={tags=_[26],text="to jump."}
_[11]={tags=_[25],text="A "}
_[10]={tags=_[24],text="Press "}
_[9]={_[19],_[20],_[21],_[22],_[23]}
_[8]={_[16],_[17],_[18]}
_[7]={_[13],_[14],_[15]}
_[6]={_[10],_[11],_[12]}
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
      tags = { 5 },
      text = "A "
    }, {
      tags = {},
      text = "to jump."
    } } }
{ "text", { {
      tags = <1>{},
      text = "Press "
    }, {
      tags = { 5 },
      text = "A"
    }, {
      tags = <table 1>,
      text = " to jump."
    } } }
{ "text", { {
      tags = <1>{},
      text = "Press "
    }, {
      tags = { 1, 2 },
      text = "A "
    }, {
      tags = <table 1>,
      text = "to jump."
    } } }
{ "text", { {
      tags = <1>{},
      text = "Press "
    }, {
      tags = <2>{ 1 },
      text = "-"
    }, {
      tags = { 1,
        [3] = 3
      },
      text = "button"
    }, {
      tags = <table 2>,
      text = "-"
    }, {
      tags = <table 1>,
      text = " to jump."
    } } }
{ "return" }
]]--