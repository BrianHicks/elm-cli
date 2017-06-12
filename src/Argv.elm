module Argv exposing (Invocation, Error, parse)

{-| Argv lets you turn a list of unknown argument strings into a list of elements.

Basically, we need to know what's actually in each position of argv, which we
can then fold over to apply user semantics.

This is intended to be fairly low-level, so it really just parses options and
returns strings for everything. If you need more advanced behavior you'll want
to write your own option processor on top of this.

@docs Invocation, Error, parse

-}

import Char
import Dict exposing (Dict)
import Parser exposing (..)


{-| Invocation represents the data the user gave your program to start it.

Note that the program invoked (index 0) is separated into a separate field. This
means that you can trust the argument list.

Options are a bit odd. Consider that you can have --text-flag=foo`but also
``--binary-flag`. When you you look them up in a Dict, you'll find that some of
them are `Just Nothing`. This can be a little confusing. But what about when you
want to know if a binary flag was present or not? You do need to know that it
was present (outer `Maybe`) but not set (inner `Maybe`).

-}
type alias Invocation =
    { program : String
    , arguments : List String
    , options : Dict String (Maybe String)
    }


{-| The members of Element encode the possible states of the parser:

1.  An argument alone: `x` becomes `Argument "x"`
2.  An option alone: `--yes` becomes `Option "yes" Nothing`
3.  An option with a value: `--method=POST` becomes `Option "method" (Just "POST")`

-}
type Element
    = Option String (Maybe String)
    | Argument String



-- PARSER BITS AND BOBS


option : Parser Element
option =
    let
        usableNameChar : Char -> Bool
        usableNameChar char =
            let
                isNumber =
                    Char.isDigit char

                isAlpha =
                    char >= 'a' && char <= 'z'

                isDash =
                    char == '-'
            in
                isNumber || isAlpha || isDash

        optionName : Parser String
        optionName =
            inContext "name" <|
                keep oneOrMore usableNameChar
    in
        inContext "option" <|
            delayedCommit
                (symbol "--")
                (succeed Option
                    |= optionName
                    |= oneOf
                        [ {- TODO: this is a little odd. Because we're using
                             oneOf here, `--x=` is a valid option (but with no
                             value). We should figure out if that's the proper
                             behavior, or if we should commit as soon as we see
                             `=` so we can throw an error that the provided
                             value was empty (or a blank string.)
                          -}
                          inContext "option value" <|
                            delayedCommit
                                (symbol "=")
                                (succeed Just |= keep oneOrMore (always True))
                        , succeed Nothing
                        ]
                    |. end
                )


value : Parser Element
value =
    inContext "argument" <|
        succeed Argument
            |= (keep oneOrMore (always True))


element : Int -> Parser Element
element n =
    inContext ("command element " ++ toString n) <| oneOf [ option, value ]


{-| Error tells us what goes wrong if we can't successfully parse the argv into
an invocation. This will probably be parser errors most of the time. Missing a
binary is only realistically going to happen with artificially constructed
argvs.
-}
type Error
    = MissingBinaryName
    | ParserError Parser.Error


{-| Apply our parsing logic to an argv.

These are, specifically:

1.  Anything that starts with `--` will be parsed as an `Option "{name}" Nothing`
2.  Anything that starts with `--` and is a valid option ending in `=` will be
    parsed as `Option "{portion before =}" (Just "{portion after =}")`
3.  Otherwise, we don't know what it is, so we stick the whole value in
    `Argument` for you to sort out later, same as option values.

Valid characters in option names:

  - 0-9
  - a-z
  - dashes (`-`)

-}
parse : List String -> Result Error Invocation
parse =
    List.indexedMap (\i el -> ( i + 1, el ))
        >> List.foldr
            (\( n, new ) elements ->
                Result.map2 (::) (run (element n) new) elements
            )
            (Ok [])
        >> Result.mapError ParserError
        >> Result.map
            (List.foldr
                (\el ( options, arguments ) ->
                    case el of
                        Option name value ->
                            ( Dict.insert name value options, arguments )

                        Argument value ->
                            ( options, value :: arguments )
                )
                ( Dict.empty, [] )
            )
        >> Result.andThen
            (\( options, arguments ) ->
                case arguments of
                    binary :: args ->
                        Ok <| Invocation binary args options

                    [] ->
                        Err MissingBinaryName
            )
