module Args exposing (..)

import Parser exposing (Parser)


-- ROUTE


type Route args flags
    = Route args flags



-- FLAG


type Flag a
    = Flag String (Parser a) String


flag : String -> Parser a -> String -> Flag a
flag =
    Flag



-- onOff : String -> Flag Bool
-- onOff name =
--     Flag
--         name
--         (Maybe.map (always True) >> Maybe.withDefault False)


anything : String -> Parser String
anything name =
    Parser.inContext name <| Parser.keep (Parser.AtLeast 1) (always True)



-- FLAGS


type Flags a b
    = FDone a


noFlags : Flags () ()
noFlags =
    FDone ()


flags : a -> Flags a b
flags =
    FDone



-- (|--) : Flags (a -> b) -> Flags a -> Flags b
-- (|--) =
--     FMore
