module ArgvTests exposing (suite)

import Argv exposing (Element(Argument, Option))
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Argv"
        [ test "command is first argument" <|
            \_ ->
                [ "a" ]
                    |> Argv.parse
                    |> Result.map .program
                    |> Expect.equal (Ok "a")
        , test "command with several arguments" <|
            \_ ->
                [ "a", "b", "c" ]
                    |> Argv.parse
                    |> Result.map .arguments
                    |> Expect.equal (Ok [ Argument "b", Argument "c" ])
        , test "command with an option" <|
            \_ ->
                [ "a", "--b=c" ]
                    |> Argv.parse
                    |> Result.map .arguments
                    |> Expect.equal (Ok [ Option "b" (Just "c") ])
        , test "option followed by an argument" <|
            \_ ->
                [ "a", "--b", "c" ]
                    |> Argv.parse
                    |> Result.map .arguments
                    |> Expect.equal (Ok [ Option "b" Nothing, Argument "c" ])
        ]
