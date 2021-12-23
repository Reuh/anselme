Anselme
=======

The overengineered dialog scripting system in pure Lua.

**Documentation and language are still WIP and will change. I am using this in a project and modify it as my needs change.**

Purpose
-------

Once upon a time, I wanted to do a game with a branching story. I could store the current state in a bunch of variables and just write everything like the rest of my game's code. But no, that would be *too simple*. I briefly looked at [ink](https://github.com/inkle/ink), which looked nice but lacked some features I felt like I needed. Mainly, I wanted something more language independant and less linear. Also, I wasn't a fan of the syntax. And I'm a weirdo who make their game in Lua *and* likes making their own scripting languages (by the way, if you like Lua but not my weird idiosyncratic language, there's actually some other options ([Erogodic](https://github.com/oniietzschan/erogodic) looks nice)).

So, here we go. Let's make a new scripting language.

Anselme ended up with some features that are actually quite useful compared to the alternatives:

* allows for concurently running scripts (a conversation bores you? why not start another at the same time!)
* allows for script interuption with gracious fallback (so you can *finally* make that NPC shut up mid-sentence)
* a mostly consistent and easy to read syntax based around lines and whitespace
* easily extensible (at least from Lua ;))

And most stuff you'd expect from such a language:

* easy text writing, can integrate expressions into text, can assign tags to (part of) lines
* choices that lead to differents paths
* variables, functions, arbitrary expressions (not Lua, it's its own thing)
* can pause the interpreter when needed
* can save and restore state

And things that are halfway there but *should* be there eventually (i.e., TODO):
* language independant; scripts should (hopefully) be easily localizable into any language (it's possible, but doesn't provide any batteries for this right now)
    Defaults variables use emoji and then it's expected to alias them; works but not the most satisfying solution.
* a good documentation
    Need to work on consistent naming of Anselme concepts
    A step by step tutorial

Things that Anselme is not:
* a game engine. It's very specific to dialogs and text, so unless you make a text game you will need to do a lot of other stuff.
* a language based on Lua. It's imperative and arrays start at 1 but there's not much else in common.

Example
-------

Sometimes we need some simplicity:

```
HELLO SIR, HOW ARE YOU TODAY
> why are you yelling
    I LIKE TO
    > Well that's stupid.
        I DO NOT LIKE YOU SIR.
> I AM FINE AND YOU
    I AM FINE THANK YOU

    LOVELY WEATHER WE'RE HAVING, AREN'T WE?
    > Sure is!
        YEAH. YEAH.
    > I've seen better.
        NOT NICE.

WELL, GOOD BYE.
```

Othertimes we don't:

TODO: stupidly complex script

Reference
------------------

See [LANGUAGE.md](LANGUAGE.md) for a reference of the language.

See [API.md](API.md) for the Lua API's documentation.
