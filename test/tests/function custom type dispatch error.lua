local _={}
_[16]={}
_[15]={}
_[14]={}
_[13]={tags=_[16],text=" is english or generic"}
_[12]={tags=_[16],text="idk::esperanto::name::string"}
_[11]={tags=_[15],text=" is french"}
_[10]={tags=_[15],text="pierre::french::name::string"}
_[9]={tags=_[14],text=" is english or generic"}
_[8]={tags=_[14],text="bob::name::string"}
_[7]={_[12],_[13]}
_[6]={_[10],_[11]}
_[5]={_[8],_[9]}
_[4]={"error","no compatible function found for call to a(number); potential candidates were:\n\9function custom type dispatch error.a(name::string) (at test/tests/function custom type dispatch error.ans:5): argument name is not of expected type string\n\9function custom type dispatch error.a(name:nom::french name) (at test/tests/function custom type dispatch error.ans:8): argument name is not of expected type french::name::string; at test/tests/function custom type dispatch error.ans:17"}
_[3]={"text",_[7]}
_[2]={"text",_[6]}
_[1]={"text",_[5]}
return {_[1],_[2],_[3],_[4]}
--[[
{ "text", { {
      tags = <1>{},
      text = "bob::name::string"
    }, {
      tags = <table 1>,
      text = " is english or generic"
    } } }
{ "text", { {
      tags = <1>{},
      text = "pierre::french::name::string"
    }, {
      tags = <table 1>,
      text = " is french"
    } } }
{ "text", { {
      tags = <1>{},
      text = "idk::esperanto::name::string"
    }, {
      tags = <table 1>,
      text = " is english or generic"
    } } }
{ "error", "no compatible function found for call to a(number); potential candidates were:\n\tfunction custom type dispatch error.a(name::string) (at test/tests/function custom type dispatch error.ans:5): argument name is not of expected type string\n\tfunction custom type dispatch error.a(name:nom::french name) (at test/tests/function custom type dispatch error.ans:8): argument name is not of expected type french::name::string; at test/tests/function custom type dispatch error.ans:17" }
]]--