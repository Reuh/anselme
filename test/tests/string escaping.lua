local _={}
_[25]={}
_[24]={}
_[23]={}
_[22]={}
_[21]={text="escaping expressions abc and {stuff} \\ and quotes \"",tags=_[25]}
_[20]={text=" {braces}",tags=_[24]}
_[19]={text="\9",tags=_[24]}
_[18]={text=" ",tags=_[24]}
_[17]={text="\\",tags=_[24]}
_[16]={text=" ",tags=_[24]}
_[15]={text="\n",tags=_[24]}
_[14]={text="other codes ",tags=_[24]}
_[13]={text="\"",tags=_[23]}
_[12]={text="quote ",tags=_[23]}
_[11]={text="a",tags=_[22]}
_[10]={text="expression ",tags=_[22]}
_[9]={_[21]}
_[8]={_[14],_[15],_[16],_[17],_[18],_[19],_[20]}
_[7]={_[12],_[13]}
_[6]={_[10],_[11]}
_[5]={"return"}
_[4]={"text",_[9]}
_[3]={"text",_[8]}
_[2]={"text",_[7]}
_[1]={"text",_[6]}
return {_[1],_[2],_[3],_[4],_[5]}
--[[
{ "text", { {
      tags = <1>{},
      text = "expression "
    }, {
      tags = <table 1>,
      text = "a"
    } } }
{ "text", { {
      tags = <1>{},
      text = "quote "
    }, {
      tags = <table 1>,
      text = '"'
    } } }
{ "text", { {
      tags = <1>{},
      text = "other codes "
    }, {
      tags = <table 1>,
      text = "\n"
    }, {
      tags = <table 1>,
      text = " "
    }, {
      tags = <table 1>,
      text = "\\"
    }, {
      tags = <table 1>,
      text = " "
    }, {
      tags = <table 1>,
      text = "\t"
    }, {
      tags = <table 1>,
      text = " {braces}"
    } } }
{ "text", { {
      tags = {},
      text = 'escaping expressions abc and {stuff} \\ and quotes "'
    } } }
{ "return" }
]]--