local _={}
_[65]={}
_[64]={}
_[63]={}
_[62]={}
_[61]={}
_[60]={}
_[59]={}
_[58]={}
_[57]={}
_[56]={}
_[55]={}
_[54]={}
_[53]={}
_[52]={}
_[51]={}
_[50]={}
_[49]={}
_[48]={}
_[47]={}
_[46]={}
_[45]={tags=_[65],text=" = b b 0"}
_[44]={tags=_[65],text="0"}
_[43]={tags=_[64],text="b"}
_[42]={tags=_[63],text="b"}
_[41]={tags=_[62],text=" = a 1"}
_[40]={tags=_[62],text="1"}
_[39]={tags=_[61],text="a"}
_[38]={tags=_[60],text=" = b a 1"}
_[37]={tags=_[60],text="1"}
_[36]={tags=_[59],text="a"}
_[35]={tags=_[58],text="b"}
_[34]={tags=_[57],text=" = a 1"}
_[33]={tags=_[57],text="1"}
_[32]={tags=_[56],text="a"}
_[31]={tags=_[55],text=" = b 0"}
_[30]={tags=_[55],text="0"}
_[29]={tags=_[54],text="b"}
_[28]={tags=_[53],text=" = a a 1"}
_[27]={tags=_[53],text="1"}
_[26]={tags=_[52],text="a"}
_[25]={tags=_[51],text="a"}
_[24]={tags=_[50],text=" = b 0"}
_[23]={tags=_[50],text="0"}
_[22]={tags=_[49],text="b"}
_[21]={tags=_[48],text=" = a b 0"}
_[20]={tags=_[48],text="0"}
_[19]={tags=_[47],text="b"}
_[18]={tags=_[46],text="a"}
_[17]={_[42],_[43],_[44],_[45]}
_[16]={_[39],_[40],_[41]}
_[15]={_[35],_[36],_[37],_[38]}
_[14]={_[32],_[33],_[34]}
_[13]={_[29],_[30],_[31]}
_[12]={_[25],_[26],_[27],_[28]}
_[11]={_[22],_[23],_[24]}
_[10]={_[18],_[19],_[20],_[21]}
_[9]={"return"}
_[8]={"text",_[17]}
_[7]={"text",_[16]}
_[6]={"text",_[15]}
_[5]={"text",_[14]}
_[4]={"text",_[13]}
_[3]={"text",_[12]}
_[2]={"text",_[11]}
_[1]={"text",_[10]}
return {_[1],_[2],_[3],_[4],_[5],_[6],_[7],_[8],_[9]}
--[[
{ "text", { {
      tags = {},
      text = "a"
    }, {
      tags = {},
      text = "b"
    }, {
      tags = <1>{},
      text = "0"
    }, {
      tags = <table 1>,
      text = " = a b 0"
    } } }
{ "text", { {
      tags = {},
      text = "b"
    }, {
      tags = <1>{},
      text = "0"
    }, {
      tags = <table 1>,
      text = " = b 0"
    } } }
{ "text", { {
      tags = {},
      text = "a"
    }, {
      tags = {},
      text = "a"
    }, {
      tags = <1>{},
      text = "1"
    }, {
      tags = <table 1>,
      text = " = a a 1"
    } } }
{ "text", { {
      tags = {},
      text = "b"
    }, {
      tags = <1>{},
      text = "0"
    }, {
      tags = <table 1>,
      text = " = b 0"
    } } }
{ "text", { {
      tags = {},
      text = "a"
    }, {
      tags = <1>{},
      text = "1"
    }, {
      tags = <table 1>,
      text = " = a 1"
    } } }
{ "text", { {
      tags = {},
      text = "b"
    }, {
      tags = {},
      text = "a"
    }, {
      tags = <1>{},
      text = "1"
    }, {
      tags = <table 1>,
      text = " = b a 1"
    } } }
{ "text", { {
      tags = {},
      text = "a"
    }, {
      tags = <1>{},
      text = "1"
    }, {
      tags = <table 1>,
      text = " = a 1"
    } } }
{ "text", { {
      tags = {},
      text = "b"
    }, {
      tags = {},
      text = "b"
    }, {
      tags = <1>{},
      text = "0"
    }, {
      tags = <table 1>,
      text = " = b b 0"
    } } }
{ "return" }
]]--