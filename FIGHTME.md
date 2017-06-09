# CLI Semantics Manifesto

This document defines the semantics I expect of command line tools.
These are the semantics I want to use in any Elm command line tools.

It's called `FIGHTME.md` because these are assumptions that I'm using, and want challenged.
But please be kind!

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-generate-toc again -->
**Table of Contents**

- [CLI Semantics Manifesto](#cli-semantics-manifesto)
    - [API Semantics](#api-semantics)
        - [`--help` Always Changes The Global Mode](#--help-always-changes-the-global-mode)
            - [Ideas](#ideas)
        - [Flags Can Go Anywhere in a Command](#flags-can-go-anywhere-in-a-command)
            - [Exceptions](#exceptions)
        - [Flags Can Only be Present Once Per Invocation](#flags-can-only-be-present-once-per-invocation)
            - [Exceptions](#exceptions)
        - [Flags Are Never Required](#flags-are-never-required)
            - [Exceptions](#exceptions)
        - [Arguments are Positional and Unique](#arguments-are-positional-and-unique)
            - [Exceptions](#exceptions)
        - [Subcommands: Yes Please](#subcommands-yes-please)
        - [We Don't Have Short Flags](#we-dont-have-short-flags)
        - [File Arguments or Flags take `-` for Console I/O](#file-arguments-or-flags-take---for-console-io)
            - [Possible Exceptions](#possible-exceptions)
    - [Design Considerations](#design-considerations)
        - [Mirror Subcommands Should Be Intuitive Opposites](#mirror-subcommands-should-be-intuitive-opposites)
        - [Parent Subcommands Have Responsibilities For Their Children](#parent-subcommands-have-responsibilities-for-their-children)
        - [Arguments That Imply Order Should Move From Left to Right](#arguments-that-imply-order-should-move-from-left-to-right)
        - [Output Should Be Appropriate for the Reader](#output-should-be-appropriate-for-the-reader)

<!-- markdown-toc end -->

## API Semantics

### `--help` Always Changes The Global Mode

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

### Flags Can Go Anywhere in a Command

It doesn't matter where you put flags in a command.
The following invocations are all valid and result in the same thing:

- `converge --log-level=debug apply file.hcl`
- `converge apply --log-level=debug file.hcl`
- `converge apply file.hcl --log-level=debug`

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

It's not unheard of to accept `--` as an argument, after which no flag or argument parsing takes place.

Take, for example, `kubectl run test --image=ubuntu -- curl -X DELETE some.other.service`.
This only interprets `--image` as part of the command.
Everything after `--` is used as a raw command for the container.

### Flags Can Only be Present Once Per Invocation

Providing multiple values for the same flag should cause an error.
Otherwise we create ambiguity.

Which method is used in `curl --method POST --method GET httpbin.org/get`?
Is it the first specified or the last?
And while it's easy to see there's a conflict *here*, what if the two `--method`s are separated by other flags?
It's easy to get weird behavior, from the user's perspective.

#### Exceptions

Sometimes flags need to repeat to build up a value.
For example, Docker sets environment variables in containers with repeated use of `-e` or `--environment`, like so:

```
docker run --rm -e X=1 -e Y=2 busybox env
```

This sets the environment variables `X` and `Y`, and is a totally normal invocation of `docker`.

### Flags Are Never Required

Flags should not be required.
They don't act like subcommands, and they always have a reasonable default value to reduce typing for common operations.

Flags should never change top-level modes (subcommands) of the program.
Why?
Compare these examples:

- Subcommands as subcommands: `git commit` and `git diff` do different things, and have clearly established boundaries.
  A plain invocation of `git` can list them all.
- Flags as subcommands: `gpg --encrypt`  and `gpg --sign` do completely different things and have no established boundaries.
  All modes of `gpg` share a huge set of sometimes mutually exclusive flags.

#### Exceptions

`--help` gets a pass since it's existed as a special (and *consistent*) mode across commands since the days of yore.

### Arguments are Positional and Unique

Arguments are positional in that `mv a b` and `mv b a` create different invocations.
They are unique by default in that only one value goes in each argument.

This is mostly uncontroversial, but why?

First, positional arguments enable subcommands.
`kubectl get pods` makes intuitive sense if you've done anything on the command line.
`kubectl pods get` doesn't work nearly as well.

Second, aside from position arguments have no meaning.
If you ignore the position of the arguments to `mv` or `ln`, you have no idea which is the source and which is the destination.
(Other usability issues here aside&hellip; source/destination confusion is really common.)

#### Exceptions

Sometimes an argument can repeat.
For example, you can run `mv a b x/` to move files `a` and `b` into directory `x`.
Or you can `cat a b` to concatenate them together.
In these cases, only one *kind* of argument is repeated (source files in both cases.)
Typically, only one argument is repeated.
It's possible to do more, but the user experience suffers.

### Subcommands: Yes Please

Subcommands are positional arguments that namespace functionality.
We should use them more.
They're great!

`git` is a nice example.
`git commit` does a different thing than `git push`, and each have a unique set of flags.
`git` becomes an entry point into a system of interrelated commands.
It makes commands discoverable and creates a nicer experience for the user.
`elm` does this too!

As a counterexample, consider `gpg`.
Instead of subcommands, `gpg` uses modal flags like `--encrypt` and `--decrypt`.
That seems fine at first, but then you pass `--armor` to the wrong mode and it blows up.
As a result, `gpg` is harder to use than it should be.

### We Don't Have Short Flags

Quick, tell me what `curl -kLI https://localhost:8043` is doing!

![relevant xkcd](https://imgs.xkcd.com/comics/tar.png)

To sum up, where we can be consistent, we should be consistent.
Where we can't be consistent, we should at least be explicit.
Short flags don't help out a lot with either of those goals.

*Note*: I'm the least sure about this assertion, even though it's the strongest worded.
If you have a link to a paper or study about command-line usability with regards to short flags, please send me a link.
I can find opinions on my own, thanks.

### File Arguments or Flags take `-` for Console I/O

Commands reading from files should accept `-` to indicate that they should read from `stdin` instead of disk.

Commands writing to files should accept `-` to indicate that they should write to `stdout` instead of disk.

#### Possible Exceptions

There *are* a few places where short flags make sense:

- `-y` for `--yes` or `--assume-yes`, as seen in `apt-get install`
- `-h` for `--help` almost everywhere, except when it means `--host` or `--header`.
- `-v` for verbose output, but it's inconsistent: `-vvvv` vs `-v=4` (although `--log-level=debug` makes more sense here.)

## Design Considerations

These are things that we can't really enforce using the API, but we can encourage by documenting well.

### Mirror Subcommands Should Be Intuitive Opposites

If two subcommands mirror each other, they should be intuitive opposites.
If there are two otherwise equally good opposites, the best tends to have the smallest edit distance (at least in English.)

For example:

- `encrypt` vs `decrypt`
- `install` vs `uninstall` (*not* `remove`, but aliases should be possible.)
- `encode` vs `decode`
- `push` vs `pull`

### Parent Subcommands Have Responsibilities For Their Children

If a parent subcommand has children, the parent has a few options.

First, it could execute query to provide information to the user.
Think `git status` here, but also `heroku ps`.

Second, it could provide an informational display on how to use the children.
See the default behavior of `git` here: it lists the most common subcommands and exits.

Third, it could provide a nicer thing than either of those.
This tool should enable creating pleasant user experience, so the programmer has the option of what to do.
For example, if you run `git` it could ask you if you want to initialize a repository in the current directory.

### Arguments That Imply Order Should Move From Left to Right

Arguments should use `command from to` for data that flows in a direction.
Think of `mv from to` or `cp from to`.

Likewise, commands that are creating a resource should be in the form of `command create-from to-create`.

### Output Should Be Appropriate for the Reader

When writing to `stdout` commands should detect whether or not it is a terminal before using control sequences.
Output should be formatted for human readability when writing for a terminal, and machine readability when writing to a file.
