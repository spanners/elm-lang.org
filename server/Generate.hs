{-# LANGUAGE OverloadedStrings #-}
module Generate (logAndJS, logAndHtml, html, js, addSpaces) where

import Data.Maybe (fromMaybe)
import Text.Blaze (preEscapedToMarkup)
import Text.Blaze.Html5 ((!))
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A

import qualified Elm.Internal.Utils as Elm
import Utils

logAndJS :: String -> String -> (H.Html, Maybe String)
logAndJS name src =
    (getHtmlPage name name src, Nothing)

logAndHtml :: String -> String -> (H.Html, Maybe String)
logAndHtml name src =
    let elmname = "Elm." ++ fromMaybe "Main" (Elm.moduleName src) 
    in
      case Elm.compile src of
          Right jsSrc -> do
              (getHtmlPage name elmname jsSrc, Nothing)
          Left err -> do
              (getErrPage name err, Just err)

getHtmlPage :: String -> String -> String -> H.Html
getHtmlPage name elmname jsSrc =
  H.docTypeHtml $ do
      H.head $ do
        H.meta ! A.charset "UTF-8"
        H.title . H.toHtml $ name
        H.style ! A.type_ "text/css" $ preEscapedToMarkup
         ("a:link {text-decoration: none; color: rgb(15,102,230);}\n\
          \a:visited {text-decoration: none}\n\
          \a:active {text-decoration: none}\n\
          \a:hover {text-decoration: underline; color: rgb(234,21,122);}" :: String)
      H.body $ do
        let js = H.script ! A.type_ "text/javascript"
            runFullscreen = "var runningElmModule = Elm.fullscreen(" ++ elmname ++ ")"
        js ! A.src (H.toValue ("/elm-runtime.js?0.11" :: String)) $ ""
        js ! A.src (H.toValue ("/pixi.js" :: String)) $ ""
        js $ preEscapedToMarkup jsSrc
        js $ preEscapedToMarkup runFullscreen

getErrPage :: String -> String -> H.Html
getErrPage name err =
  H.docTypeHtml $ do
      H.head $ do
        H.meta ! A.charset "UTF-8"
        H.title . H.toHtml $ name
      H.body $
        H.span ! A.style "font-family: monospace;" $
        mapM_ (\line -> preEscapedToMarkup (addSpaces line) >> H.br) (lines err)
    
            

-- | Using a page title and the full source of an Elm program, compile down to
--   a valid HTML document.
html :: String -> String -> H.Html
html name src =
  H.docTypeHtml $ do
      H.head $ do
        H.meta ! A.charset "UTF-8"
        H.title . H.toHtml $ name
        H.style ! A.type_ "text/css" $ preEscapedToMarkup
         ("a:link {text-decoration: none; color: rgb(15,102,230);}\n\
          \a:visited {text-decoration: none}\n\
          \a:active {text-decoration: none}\n\
          \a:hover {text-decoration: underline; color: rgb(234,21,122);}" :: String)
      H.body $ do
        let js = H.script ! A.type_ "text/javascript"
            elmname = "Elm." ++ fromMaybe "Main" (Elm.moduleName src)
            runFullscreen = "var runningElmModule = Elm.fullscreen(" ++ elmname ++ ")"
        js ! A.src (H.toValue ("/elm-runtime.js?0.11" :: String)) $ ""
        case Elm.compile src of
          Right jsSrc -> do
              js $ preEscapedToMarkup jsSrc
              js $ preEscapedToMarkup runFullscreen
          Left err ->
              H.span ! A.style "font-family: monospace;" $
              mapM_ (\line -> preEscapedToMarkup (addSpaces line) >> H.br) (lines err)
        googleAnalytics

addSpaces :: String -> String
addSpaces str =
  case str of
    ' ' : ' ' : rest -> " &nbsp;" ++ addSpaces rest
    c : rest -> c : addSpaces rest
    [] -> []

js :: String -> String
js src = case Elm.compile src of
           Right js -> "{ \"success\" : " ++ show js ++ " }"
           Left err -> "{ \"error\" : " ++ show err ++ " }"
