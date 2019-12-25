Anselme quick reference
=======================

Anselme will read script files line per line, starting from the start of the file.
Every line can have children: a new line prefixed with a tabulation, or more if it's a children of a children, and so on.
Anselme will automatically read the top-level lines. Children reading will be decided by their parents.

Lines types and their properties
--------------------------------
* Lines starting with a character which isn't listed below are text. They will be said out loud. Text formatting apply. If the line ends with a \, the text will not be immediately sent to the engine (it will be sent along with the next text line encountered, concatenated).
    Example: Hello world!
    No children.
    No variables.
* Lines starting with ( are comments.
    Example: (Important comment)
    Their children are never read nor parsed, so it can be used for multiline comments.
    No variables.
* Lines starting with § are paragraphs. A paragraph can have parameters, between parantheses and seperated by commas. Parantheses can be ommited if there are no parameters. Missing parent paragraphs will be created. 
    Example: § the start of the adventure (hero name, size of socks collection)
    Their children are only read after a redirection to this paragraph.
     👁️: number of times the paragraph definition line has been encoutered before
     🗨️: number of times the paragraph's children have been executed before
* Lines starting with > are choices. The play can choose between this choice and every immediately following choice line. Text formatting apply. If a choice ends with a \, the choice will not immediately be sent to the engine (it will be send along with the next choice encoutered, with all choices available).
    Example: > Yes.
                Neat.
             > No.
                I'm sad now.
    Its children will be read if the player select this choice.
    No variables.
* Lines starting with : are variable definition. They will define and set to a specific value a currently undefined variable, which is searched in the closest paragraph only. Missing paragraphs will be created. They will always be run at compile time.
    Example: :(variable*2) variableSquared
    No children.
    No variables.
* Lines starting with =, +, -, *, /, %, ^, !, &, | are variable assignements. They will change the value of a variable, searched as described in Variables. When asked to change the value of a paragraph, special behaviour may occur; see Aliases.
    Example: +1 life point
    No children.
    No variables.
* Lines starting with ~ are redirections. They usually instruct the game to go to a specific paragraph (see Paragraph selection) and resume reading, but they will in practive evaluate any expression given to them. If the expression returns a paragraph, it will automatically be called (unless you redefine the ? operator). Redirections that immediately follow this one will only be read if this redirection failed (like a elseif). Expression default to true if not specified.
    Example: ~ the start of the adventure ("John Pizzapone", 9821)
             ~ life point > 5
                Life is good
             ~
                NOT GOOD ENOUGH
    Their children will be run only if the paragraph returns a truthy value.
    No variables.
* Lines starting with @ are value return statements. They set the return value of the current paragraph.
    Example: @1+1
    No children.
    No variables.
* Lines starting with # are tags marker. They will define tags for all text sent from their children. Name and value are expressions.
    Example: # "colour": "red", "big"
                Hey.
    "Hey" will be sent along with the tag table { colour = "red", "big" }.
    Their children are always run.
    No variables.

Line decorators
---------------
Every line can be suffixed with a ~ and a following condition; the line will only be run when the condition is verified.

Similarly, every line can be suffixed with a # and a list of tags that will be set for this line (won't affect its children). Tag decorators must be placed before condition decorators.

Lines can also be suffixed with a § and a name to behave like a paragraph (they will have variables, and can be redirected to).

Text formatting
---------------
Stuff inside braces { } will be replaced with the associated expression content. If the expression returns a paragraph, it will automatically be called.

Tags
----
Tags can be specified using the # line or decorator. If the expression returns a list, all of its elements will be recursively extracted and the final list will be provided to the engine. Paragraphs in the list will be automatically evaluated. If pairs are present, they will be used as key-value pairs in the tags table.

Expressions
-----------
A formula. Available operators: ? (thruth test), &, | (boolean and, or), ! (boolean not), +, -, *, /, //, %, ^ (arithmetic), >, <, >=, <= (comparaison), =, != (value (in)equality), : (pair), , (list).

Unusual operators:
    ?paragraph will recursively evaluate the paragraph until a non-paragraph is found, and returns a boolean
    -string will reverse the string
    string + string/number will concatenate
    string - number will returns everything before/after the last/first number characters
    string - string will remove every string from the string
    string * number will repeat the string
    string / number will returns the last/first number characters
    string/number % string/number will returns the position of string in string if found, no if not found
    string/number ^ boolean will uppercase/lowercase the string

Paragraph can have custom binary operator behaviour by having a sub paragraph named like _operator_ (eg, _+_ for the + operator). The function will receive (left, right) as parameters. This does not apply to lazy operators (&, |), you can only change their behaviour by changing the behaviour of the truth test (var is true if and only if ?var = 1), i.e., via redefining the ? operator).
Similarly, unary operators can be redefined by using the name -_.
Assignement operators can be redefined using their name (eg, = for direct assignement or + for addition).

Parantheses can be used for priority management.

Anselme test the falsity of value by comparing it with 0. Everything else is true, including the string "0".

Variables can be used by writing their name. Straigthforward.

Variables
---------
Variables names can contain every character except . { } § > < ( ) ~ + - * / % ^ = ! & | : , and space.

Value type:
    * number:
        0, 1, ...
    * string:
        "Text". Text formatting applies.
    * pair:
        name: value
    * list:
        value1, value2, ...
    * paragraph:
        a reference to a paragraph
    * luafunction:
        function defined by the engine

Variables need to be defined before use. Their type cannot be changed after definition.
The same rules as in Paragraph selection apply.

Functions
---------
Paragraphs can be used like functions. Use (var1, var2) to specify parameters in the paragraph definition. Theses variables will be set in the paragraph when it is called. Parantheses are not needed for functions without parameters.
When called in an expression, the paragraph will return a value that can be redefined using a @ line. By default, the return value is the empty string.

Addresses
---------
The path to a paragraph, subparagraph or any variable is called an address.
Anselme will search for variables from the current indentation level up to the top-level.
You can select sub-variables using a space between the parent paragraph name and its children, and so on.
You can select sub-variables using expression by putting them between braces (will automatically evaluate paragraph). For example,

    ~ foo {"bar"}

will select foo bar.
When a sub-variables is not found directly, it will be searched in the parent's return values.

Engine defined functions
------------------------
Functions (same as paragraphs) can be defined by the game engine. These always will be searched first. See Anselme's public API on how to add them (at the end of this file).

Built-in functions:
    * ↩️(destiation name, source name)
        will set up an alias so when the name "source name" is used but not found, it will be replaced with "destination name"

Anselme's public interface is definied at the end of anselme.can.

TODO: test/check redirections consistency/coverage
TODO: merge new scripts with an old state
TODO: translation thing. Linked with script merging. Simplest solution (which does not imply adding uuids to every text line in every file) would be to use a mapping file, which maps every save-relevant variable to its name in a translation.

(TODO changer anselme pour les sauvegardes - j'ai une feuille dessus, mais iirc la bonne solution c'était de changer les variables pour référerer au dernier checkpoint (paragraph / choix / if) et de commit les données qu'aux checkponts (autorise changements de texte, mais à voir comment identifier uniquement les choix et ifs...))
(TODO: autoriser type de variables custom (par ex list): définir type et actions avec les opérateurs)
(genre ici un type inventory: :inventory() raquettes / +"raquette sans fil" raquettes) (utiliser probablement les opérateurs custom)
(TODO: méthodes ? genre string:gsub(truc) signifie gsub(string, truc) idk ou juste des méthodes comme Lua (mais engine-defined))

TODO: functions with default value for arguments / named parameters. Use : as name-value delimiter (like with tags)
TODO: list methods