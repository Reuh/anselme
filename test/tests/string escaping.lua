local _={}
_[24]={}
_[23]={}
_[22]={}
_[21]={}
_[20]={tags=_[24],text="escaping expressions abc and stuff \\ and quotes \""}
_[19]={tags=_[23],text="\9"}
_[18]={tags=_[23],text=" "}
_[17]={tags=_[23],text="\\"}
_[16]={tags=_[23],text=" "}
_[15]={tags=_[23],text="\n"}
_[14]={tags=_[23],text="other codes "}
_[13]={tags=_[22],text="\""}
_[12]={tags=_[22],text="quote "}
_[11]={tags=_[21],text="a"}
_[10]={tags=_[21],text="expression "}
_[9]={_[20]}
_[8]={_[14],_[15],_[16],_[17],_[18],_[19]}
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
    } } }
{ "text", { {
      tags = {},
      text = 'escaping expressions abc and stuff \\ and quotes "'
    } } }
{ "return" }
]]--