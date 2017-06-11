module Argv exposing (Element, parse)

{-| Argv lets you turn a list of unknown argument strings into a list of elements.

Basically, we need to know what's actually in each position of argv, which we
can then fold over to apply user semantics.

@docs Element, parse

-}

import Char
import Parser exposing (..)


{-| The members of Element encode the possible states of the parser:

1.  An argument alone: `x` becomes `Unspecialized "x"`
2.  An option alone: `--yes` becomes `Option "yes" Nothing`
3.  An option with a value: `--method=POST` becomes `Option "method" (Just "POST")`

-}
type Element
    = Option String (Maybe String)
    | PositionalOrValue String



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
    inContext "value" <|
        succeed PositionalOrValue
            |= (keep oneOrMore (always True))


element : Parser Element
element =
    inContext "command element" <| oneOf [ option, value ]


{-| parse applies our parsing logic to a list of raw argv.

These are, specifically:

1.  Anything that starts with `--` will be parsed as an `Option "{name}" Nothing`
2.  Anything that starts with `--` and is a valid option ending in `=` will be
    parsed as `Option "{portion before =}" (Just "{portion after =}")`
3.  Otherwise, we don't know what it is, so we stick the whole value in
    `PositionalOrValue`.

Valid characters in option names:

  - 0-9
  - a-z
  - dashes (`-`)

-}
parse : List String -> Result Error (List Element)
parse =
    List.foldr
        (\new elements ->
            Result.map2 (::) (run element new) elements
        )
        (Ok [])
