# Lister

[![Build Status](https://travis-ci.com/alloy-d/lister.svg?branch=master)](https://travis-ci.com/alloy-d/lister)

Lister is a tool for managing your lists.
"Lists" here is used in the sense of _Getting Things Done_.

Lister does not prescribe a structure for your lists; it assumes they
are scattered around your filesystem in some structure that makes sense
to you.  Lister provides you holistic operations on top of whatever
that nonsense looks like.

Lister understands the [TaskPaper][taskpaper] format.

## The problem

I used to use the wonderful [Things][things].  Then some complications
set in:

- I started using an untrusted machine for my daily work, one that
  I didn't want my personal credentials on and my personal lists syncing
  to.
- I started using Linux in my personal life.  Things is
  Apple-ecosystem-only.

Not to worry!  After some searching, I discovered [taskpaper.vim][],
which provides handy facilities for editing the simple plain-text format
from [TaskPaper][taskpaper].

I started making a bunch of ad-hoc TaskPaper lists.

Then I realized I was here:

```sh
$ lister list-files
/home/awl/code/lister/project.taskpaper
/home/awl/code/photobox/todo.taskpaper
/home/awl/.config/fish/todo.taskpaper
/home/awl/todo.taskpaper
```

One of the core principles of GTD is that you need to periodically
_review_ your lists.  That gets tricky if you don't even know where your
lists are.

## The solution

Lister exists to turn a collection like this of disparate plaintext
files into a holistic GTD system.

It provides some unixy tooling for working with lists.  For instance, if
I just want to see what's in some of my lists:

```
$ lister list-files | grep -v '/home/awl/todo.taskpaper' | xargs lister format
/home/awl/code/lister/project.taskpaper:

  Functionality:
    - write a taskpaper formatter @done(2020-06-12)
    - write a command to list projects
    - write a query function
    - figure out how to ignore files
    - add a curses interface for browsing

  Bookkeeping:
    - decide on a name @done(2020-06-08)
      "thingus"?
      "list processing"?
      "listmaster"?
      "listicle"?
      "blister"?
    - change name to `lister` @done(2020-06-08)
    - write a README
    - push to GitHub


/home/awl/code/photobox/todo.taskpaper:

  - script feh with some useful actions
  - figure out how to get photos into iCloud @done(2020-05-30)


/home/awl/.config/fish/todo.taskpaper:

  - audit for places to use `status --is-login` and `status --is-interactive`
```

And... well, that's it.  That's all it does so far.  Cool, right?!

### Future plans

That example up there includes what I'm planning to do with this.

First up is extending the CLI with various ways to filter information,
so it becomes more than a slower `find` and `cat`.

I also have grand dreams of adding a curses interface.

### Installation

You can use the included rockspec to build this with `luarocks`.

You can't just `luarocks install` yet, because I haven't submitted it to
the rocks server.  It doesn't do anything yet, so why would you want it?
:-D

### Why "Lister"?

I also considered `skutter` and `kryten`, but in addition to being more
obscure and harder to type, they were also (surprisingly) more commonly
in use.

### Code feedback welcome!

Part of my goal with this is to try out Lua.  I've been working on this
in parallel with reading _Programming in Lua_, and I haven't worked in
any other Lua codebases.

If you are an experienced Lua person, you might notice that this is the
code of an inexperienced Lua person.  If you see anything amiss and
you're feeling generous, I would very much welcome an issue, email, or
pull request about it!

[taskpaper]: https://guide.taskpaper.com/
[taskpaper.vim]: https://github.com/davidoc/taskpaper.vim
[things]: https://culturedcode.com/things/