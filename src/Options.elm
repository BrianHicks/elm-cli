module Options exposing (..)

import Argv exposing (Element)


-- import Parser as P
-- DECODERS


type Error
    = TODO


type Decoder a
    = Decoder (List Element -> ( Result Error a, List Element ))


flagsFor : a -> Decoder a
flagsFor a =
    Decoder ((,) (Ok a))


map : (a -> b) -> Decoder a -> Decoder b
map next (Decoder decoder) =
    Decoder (decoder >> Tuple.mapFirst (Result.map next))


map2 : (a -> b -> c) -> Decoder a -> Decoder b -> Decoder c
map2 next (Decoder fst) (Decoder snd) =
    Decoder <|
        \elements ->
            -- TODO: there's probably some pipeline or functional composition
            -- way of doing this. But would it be clearer? I kinda doubt it?
            let
                ( a, inter1 ) =
                    fst elements

                ( b, inter2 ) =
                    snd inter1
            in
                ( Result.map2 next a b, inter2 )


custom : Decoder a -> Decoder (a -> b) -> Decoder b
custom =
    map2 (|>)
