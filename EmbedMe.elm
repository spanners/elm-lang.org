module Moose where

import Mouse
import Window
import Keyboard
import JavaScript as JS
import JavaScript.Experimental as JEXP
import Http
import Json

(~>) = flip lift
infixl 4 ~>

clicks : Signal (Int,Int)
clicks = sampleOn (every (5 * second)) Mouse.position


firebaseRequest requestType requestData = Http.request requestType "https://sweltering-fire-9141.firebaseio.com/dissertation.json" requestData []

 
serialize r = r |> JEXP.fromRecord |> Json.fromJSObject |> Json.toJSString " " |> JS.toString
 
toRequestData (x,y) = {x = x, y = y} |> serialize
 
toRequest event = case event of 
  (x,y) -> firebaseRequest "post" (event |> toRequestData)
 
requests = clicks ~> toRequest
 
sendRequests = Http.send requests
