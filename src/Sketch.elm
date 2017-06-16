module Sketch exposing (..)

import Options exposing (..)


-- sample config from elm-make


type alias Tiny =
    { x : String }


tiny : Decoder Tiny
tiny =
    flagsFor Tiny



-- tiny : Flags Tiny
-- tiny =
--     flag "x" string "x"
-- type alias Config =
--     { output : String
--     , assumeYes : Bool
--     , report : String
--     , debug : Bool
--     , warn : Bool
--     , docs : Bool
--     }
-- config : Flags Config
-- config =
--     flags Config
--         |~ flag "report" string "index.html"
--         |~ flag "yes" onOff False
--         |~ flag "report" string "text"
--         |~ flag "debug" onOff False
--         |~ flag "warn" onOff False
--         |~ flag "docs" (maybe string) Nothing
