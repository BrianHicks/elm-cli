# CLI Semantics Manifesto

This document defines the semantics I expect of command line tools.
These are the semantics I want to use in any Elm command line tools.

It's called `FIGHTME.md` because these are assumptions that I'm using, and want challenged.
But, please be kind!

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-generate-toc again -->
**Table of Contents**

- [CLI Semantics Manifesto](#cli-semantics-manifesto)
    - [API Semantics](#api-semantics)
        - [Getting Help](#getting-help)
            - [Ideas](#ideas)
        - [Flag and Argument Position](#flag-and-argument-position)
            - [Examples](#examples)
            - [Exceptions](#exceptions)
        - [Argument Uniqueness](#argument-uniqueness)
        - [Subcommands](#subcommands)
        - [Flag Uniqueness](#flag-uniqueness)
        - [Required Flags](#required-flags)
        - [Short Flags](#short-flags)
    - [Design Considerations](#design-considerations)
        - [Mirror Subcommands](#mirror-subcommands)

<!-- markdown-toc end -->

## API Semantics

### Getting Help

Every command and subcommand has a `--help` flag that takes precedence over all other flags.
It prints the usage for the command or subcommand that *would* have been invoked and exits with a non-zero error code.

In short, `--help` is a globally accessible modal flag.

#### Ideas

Showing the usage is a good place to start, but we don't have to end here.
The `--help` experience in default Unix tools is pretty bad for newcomers.
What if we looked at the rest of the options provided, and showed relevant details?

So `git commit --annotate --help` could, for example, suggest that you might want to also provide `--message`.

If a subcommand or flag is used incorrectly, the program could say *what* was wrong, instead of just printing the usage and exiting.

If a subcommand or flag was spelled wrong, the program could suggest corrections and exit with a non-zero error code.

### Flag and Argument Position

Args should be positional, flags should not.
Both should be unique, unless otherwise specified.

The following invocations are all valid and result in the same thing:

- `converge --log-level=debug apply file.hcl`
- `converge apply --log-level=debug file.hcl`
- `converge apply file.hcl --log-level=debug`

#### Examples

This matters because of two main cases:

When you're composing a command line string you often just want to tack options onto the end.
I often find myself doing this with `curl`:

1. Start with `curl localhost:8080` and oops, it doesn't work&hellip;
2. How about `curl localhost:8080 -v`?
   Oh, it says I need to send an `Accept` header&hellip;
3. `curl localhost:8080 -v --header "Accept: application/json"`

Second, when you're creating an alias you almost always want to have all your options at the beginning.
If flags are not positional, you can create a wrapper for whatever configuration you like.
I most often do this with `kubectl`: `alias ksystem="kubectl --namespace=kube-system"`.

#### Exceptions

It's reasonably common to accept `--` as an argument, after which no flag or argument parsing takes place.

Take, for example, `kubectl run test --image=ubuntu -- curl -I some.other.service`.
This only interprets `--image` as part of the command.
Everything after `--` is used as a raw command for the container.

### Argument Uniqueness

Arguments should be positional and unique by default.
If an argument is repeated (like a number of files to process), it must be the last argument, and the only repeated argument.
This is mostly uncontroversial, but why?

First, positional arguments enable subcommands.
`kubectl get pods` makes intuitive sense if you've done anything on the command line.
`kubectl pods get` doesn't work nearly as well.

Second, aside from position arguments have no meaning.
If you ignore the position of the arguments to `mv` or `ln`, you have no idea which is the source and which is the destination.
(Other usability issues here aside&hellip; source/destination confusion is really common.)

### Subcommands

If a parent subcommand has  children subcommands, the parent subcommand shouldn't do anything by default.
If it *does* do anything, it should only ever be informational (think `GET`, not `POST`).

### Flag Uniqueness

Flags should be unique by default.

In our example, providing `--log-level` twice is an error.
This is the most common case and should be the default.
But this should be configurable.
For example, Docker sets environment variables in containers with repeated use of `-e` or `--environment`, like so:

```
docker run --rm -e X=1 -e Y=2 busybox env
```

### Required Flags

Flags should not be required.
They don't act like subcommands, and they always have a reasonable default value to reduce typing for common operations.

Flags should never change top-level modes (subcommands) of the program.
Why?
Compare these examples:

- Subcommands as subcommands: `git commit` and `git diff` do different things, and have clearly established boundaries. 
  A plain invocation of `git` can list them all.
- Flags as subcommands: `gpg --encrypt`  and `gpg --sign` do completely different things and have no established boundaries.
  All modes of `gpg` share a huge set of sometimes mutually exclusive flags.

`--help` gets an exception since it's existed as a special (and importantly, *consistent*) mode across commands since the days of yore.

### Short Flags

We don't have short flags.
Quick, tell me what `curl -kLI https://localhost:8043` is doing!

![relevant xkcd](https://imgs.xkcd.com/comics/tar.png)

There *are* a few places where short flags make sense:

- `-y` for `--yes` or `--assume-yes`, as seen in `apt-get install`
- `-h` for `--help` almost everywhere, except when it means `--host` or `--header`.
- `-v` for verbose output, but it's inconsistent: `-vvvv` vs `-v=4` vs `--log-level=debug` (which is the best, IMO.)

In short, where we can be consistent, we should be consistent.
Where we can't be consistent, we should be explicit.
Short flags don't help out a lot here.

*Note*: I'm the least sure about this assertion, even though it's the strongest worded.
If you have a link to a paper or study about command-line usability with regards to short flags, please send me a link.
I can find opinions on my own, thanks.

## Design Considerations

These are things that we can't really enforce using the API, but we can encourage by documenting well.

### Mirror Subcommands

If two subcommands mirror each other, they should be intuitive opposites.
If there are two otherwise equally good opposites, the best tends to have the smallest edit distance (at least in English.)

For example:

- `encrypt` vs `decrypt`
- `install` vs `uninstall` (*not* `remove`, but aliases should be possible.)
- `encode` vs `decode`
- `push` vs `pull`
