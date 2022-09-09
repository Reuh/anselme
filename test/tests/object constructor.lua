local _={}
_[23]={}
_[22]={}
_[21]={}
_[20]={}
_[19]={}
_[18]={}
_[17]={}
_[16]={}
_[15]={}
_[14]={tags=_[23],text="bar"}
_[13]={tags=_[22],text=" != "}
_[12]={tags=_[21],text="hoho"}
_[11]={tags=_[20],text="bar"}
_[10]={tags=_[19],text=" == "}
_[9]={tags=_[18],text="bar"}
_[8]={tags=_[17],text="%object constructor.class(c=hoho)::&object constructor.class"}
_[7]={tags=_[16],text=", "}
_[6]={tags=_[15],text="%object constructor.class::&object constructor.class"}
_[5]={_[9],_[10],_[11],_[12],_[13],_[14]}
_[4]={_[6],_[7],_[8]}
_[3]={"return"}
_[2]={"text",_[5]}
_[1]={"text",_[4]}
return {_[1],_[2],_[3]}
--[[
{ "text", { {
      tags = {},
      text = "%object constructor.class::&object constructor.class"
    }, {
      tags = {},
      text = ", "
    }, {
      tags = {},
      text = "%object constructor.class(c=hoho)::&object constructor.class"
    } } }
{ "text", { {
      tags = {},
      text = "bar"
    }, {
      tags = {},
      text = " == "
    }, {
      tags = {},
      text = "bar"
    }, {
      tags = {},
      text = "hoho"
    }, {
      tags = {},
      text = " != "
    }, {
      tags = {},
      text = "bar"
    } } }
{ "return" }
]]--