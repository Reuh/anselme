local _={}
_[41]={}
_[40]={}
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
_[25]={tags=_[41],text="bar"}
_[24]={tags=_[40],text=" == "}
_[23]={tags=_[39],text="bar"}
_[22]={tags=_[38],text="foo"}
_[21]={tags=_[37],text=" != "}
_[20]={tags=_[36],text="haha"}
_[19]={tags=_[35],text="foo"}
_[18]={tags=_[34],text=" != "}
_[17]={tags=_[33],text="haha"}
_[16]={tags=_[32],text="foo"}
_[15]={tags=_[31],text=" == "}
_[14]={tags=_[30],text="foo"}
_[13]={tags=_[29],text="foo"}
_[12]={tags=_[28],text=" == "}
_[11]={tags=_[27],text="foo"}
_[10]={tags=_[26],text="%object simple.class::&object simple.class"}
_[9]={_[23],_[24],_[25]}
_[8]={_[17],_[18],_[19],_[20],_[21],_[22]}
_[7]={_[11],_[12],_[13],_[14],_[15],_[16]}
_[6]={_[10]}
_[5]={"return"}
_[4]={"text",_[9]}
_[3]={"text",_[8]}
_[2]={"text",_[7]}
_[1]={"text",_[6]}
return {_[1],_[2],_[3],_[4],_[5]}
--[[
{ "text", { {
      tags = {},
      text = "%object simple.class::&object simple.class"
    } } }
{ "text", { {
      tags = {},
      text = "foo"
    }, {
      tags = {},
      text = " == "
    }, {
      tags = {},
      text = "foo"
    }, {
      tags = {},
      text = "foo"
    }, {
      tags = {},
      text = " == "
    }, {
      tags = {},
      text = "foo"
    } } }
{ "text", { {
      tags = {},
      text = "haha"
    }, {
      tags = {},
      text = " != "
    }, {
      tags = {},
      text = "foo"
    }, {
      tags = {},
      text = "haha"
    }, {
      tags = {},
      text = " != "
    }, {
      tags = {},
      text = "foo"
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
    } } }
{ "return" }
]]--