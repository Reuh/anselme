local _={}
_[39]={}
_[38]={}
_[37]={}
_[36]={}
_[35]={}
_[34]={}
_[33]={}
_[32]={}
_[31]={}
_[30]={}
_[29]={}
_[28]={}
_[27]={}
_[26]={}
_[25]={tags=_[39],text="\194\163"}
_[24]={tags=_[38],text="generic symbol "}
_[23]={tags=_[37],text="escaping expressions abc and {stuff} \\ and quotes \""}
_[22]={tags=_[36],text=" {braces}"}
_[21]={tags=_[35],text="\9"}
_[20]={tags=_[34],text=" "}
_[19]={tags=_[33],text="\\"}
_[18]={tags=_[32],text=" "}
_[17]={tags=_[31],text="\n"}
_[16]={tags=_[30],text="other codes "}
_[15]={tags=_[29],text="\""}
_[14]={tags=_[28],text="quote "}
_[13]={tags=_[27],text="a"}
_[12]={tags=_[26],text="expression "}
_[11]={_[24],_[25]}
_[10]={_[23]}
_[9]={_[16],_[17],_[18],_[19],_[20],_[21],_[22]}
_[8]={_[14],_[15]}
_[7]={_[12],_[13]}
_[6]={"return"}
_[5]={"text",_[11]}
_[4]={"text",_[10]}
_[3]={"text",_[9]}
_[2]={"text",_[8]}
_[1]={"text",_[7]}
return {_[1],_[2],_[3],_[4],_[5],_[6]}
--[[
{ "text", { {
      tags = {},
      text = "expression "
    }, {
      tags = {},
      text = "a"
    } } }
{ "text", { {
      tags = {},
      text = "quote "
    }, {
      tags = {},
      text = '"'
    } } }
{ "text", { {
      tags = {},
      text = "other codes "
    }, {
      tags = {},
      text = "\n"
    }, {
      tags = {},
      text = " "
    }, {
      tags = {},
      text = "\\"
    }, {
      tags = {},
      text = " "
    }, {
      tags = {},
      text = "\t"
    }, {
      tags = {},
      text = " {braces}"
    } } }
{ "text", { {
      tags = {},
      text = 'escaping expressions abc and {stuff} \\ and quotes "'
    } } }
{ "text", { {
      tags = {},
      text = "generic symbol "
    }, {
      tags = {},
      text = "£"
    } } }
{ "return" }
]]--