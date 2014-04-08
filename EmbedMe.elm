module Moose where

import Mouse
import Window
import JavaScript as JS
import JavaScript.Experimental as JEXP
import Http
import Json

(~>) = flip lift
infixl 4 ~>

-- Events can either be mouse clicks or reset events
clicks : Signal (Int,Int)
clicks = sampleOn Mouse.clicks Mouse.position

clickLocations =
    let update event locations = case event of
                                   (x,y) -> (x,y) :: locations
                                   _  -> []
    in  foldp update [] clicks


-- Show the stamp list on screen
scene (w,h) locs =
  let drawPentagon (x,y) =
          ngon 5 20 |> filled (hsva (toFloat x) 1 1 0.7)
                    |> move (toFloat x - toFloat w / 2, toFloat h / 2 - toFloat y)
                    |> rotate (toFloat x)
  in  collage w h (map drawPentagon locs)

main = lift2 scene Window.dimensions clickLocations

-- Export the number of stamps
port count : Signal Int
port count = length <~ clickLocations

firebaseRequest requestType requestData = Http.request requestType "https://spanners.firebaseio-demo.com/dissertation" requestData []

 
serialize r = r |> JEXP.fromRecord |> Json.fromJSObject |> Json.toJSString " " |> JS.toString
 
toRequestData (x,y) = {x = x, y = y} |> serialize
 
toRequest event = case event of 
  (x,y) -> firebaseRequest "post" (event |> toRequestData)
 
requests = clicks ~> toRequest
 
sendRequests = Http.send requests
