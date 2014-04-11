{-# LANGUAGE OverloadedStrings #-}
module Editor (editor,ide,empty) where

import Data.Monoid (mempty)
import Text.Blaze.Html
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A
import Network.HTTP.Base (urlEncode)
import qualified System.FilePath as FP

import qualified Elm.Internal.Utils as Elm
import Data.Maybe (fromMaybe)

import Generate (addSpaces)


-- | Display an editor and the compiled result side-by-side.
ide :: String -> FilePath -> String -> Html
ide cols fileName code =
    ideBuilder cols
               ("Elm Editor: " ++ FP.takeBaseName fileName)
               fileName
               ("/compile?input=" ++ urlEncode code)

-- | Display an editor and the compiled result side-by-side.
empty :: Html
empty = ideBuilder "50%,50%" "Try Elm" "Empty.elm" "/Try.elm"

ideBuilder :: String -> String -> String -> String -> Html
ideBuilder cols title input output =
    H.docTypeHtml $ do
      H.head . H.title . toHtml $ title
      preEscapedToMarkup $ 
         concat [ "<frameset cols=\"" ++ cols ++ "\">\n"
                , "  <frame name=\"input\" src=\"/code/", input, "\" />\n"
                , "  <frame name=\"output\" src=\"", output, "\" />\n"
                , "</frameset>" ]

-- | list of themes to use with CodeMirror
themes :: [String]
themes = [ "ambiance", "blackboard", "cobalt", "eclipse"
         , "elegant", "erlang-dark", "lesser-dark", "monokai", "neat", "night"
         , "rubyblue", "solarized", "twilight", "vibrant-ink", "xq-dark" ]

jsFiles :: [AttributeValue]
jsFiles = [ "/codemirror-3.x/lib/codemirror.js"
          , "/codemirror-3.x/mode/elm/elm.js"
          , "/misc/showdown.js"
          , "/misc/editor.js?0.11" ]


-- | Create an HTML document that allows you to edit and submit Elm code
--   for compilation.
editor :: FilePath -> String -> Html
editor filePath code =
    H.html $ do
      H.head $ do
        H.title . toHtml $ "Elm Editor: " ++ FP.takeBaseName filePath
        H.link ! A.rel "stylesheet" ! A.href "/codemirror-3.x/lib/codemirror.css"
        mapM_ (\theme -> H.link ! A.rel "stylesheet" ! A.href (toValue ("/codemirror-3.x/theme/" ++ theme ++ ".css" :: String))) themes
        H.link ! A.rel "stylesheet" ! A.type_ "text/css" ! A.href "/misc/editor.css"
        mapM_ script jsFiles
        script "/elm-runtime.js?0.11"
        script "http://cdn.firebase.com/v0/firebase.js"
      H.body $ do
        H.form ! A.id "inputForm" ! A.action "/compile" ! A.method "post" ! A.target "output" $ do
           H.div ! A.id "editor_box" $
             H.textarea ! A.name "input" ! A.id "input" $ toHtml ('\n':code)
           H.div ! A.id "options" $ do
             bar "documentation" docs
             bar "editor_options" editorOptions
             bar "always_on" (buttons >> options)
        embed "initEditor();"
  where jsAttr = H.script ! A.type_ "text/javascript"
        script jsFile = jsAttr ! A.src jsFile $ mempty
        embed jsCode = jsAttr $ jsCode

bar :: AttributeValue -> Html -> Html
bar id' body = H.div ! A.id id' ! A.class_ "option" $ body

buttons :: Html
buttons = H.div ! A.class_ "valign_kids"
                ! A.style "float:right; padding-right: 6px;"
                $ autoBox >> hotSwapButton >> compileButton
      where
        hotSwapButton = 
            H.input
                 ! A.type_ "button"
                 ! A.id "hot_swap_button"
                 ! A.value "Hot Swap"
                 ! A.onclick "hotSwap()"
                 ! A.title "Ctrl-Shift-Enter"

        compileButton = 
            H.input
                 ! A.type_ "button"
                 ! A.id "compile_button"
                 ! A.value "Compile (Ctrl-Enter)"
                 ! A.onclick "compile()"
                 ! A.title "Ctrl-Enter: change program behavior but keep the state"

        autoBox =
            H.span ! A.title "Attempt to hot-swap automatically." $ "Auto-update:" >>  
                H.input ! A.type_ "checkbox"
                        ! A.id "auto_hot_swap_checkbox"
                        ! A.onchange "setAutoHotSwap(this.checked)"
                        ! A.style "margin-right:20px;"

options :: Html
options = H.div ! A.class_ "valign_kids"
                ! A.style "float:left; padding-left:6px; padding-top:2px;"
                $ (docs' >> opts)
    where 
      docs' = 
        H.span  ! A.title "Show documentation and types." $ "Hints:" >>
            H.input ! A.type_ "checkbox"
                    ! A.id "show_type_checkbox"
                    ! A.onchange "showType(this.checked);"

      opts = 
        H.span  ! A.title "Show editor options." 
                ! A.style "padding-left: 12px;" $ "Options:" >>
            H.input ! A.type_ "checkbox"
                    ! A.id "options_checkbox" 
                    ! A.onchange "showOptions(this.checked);"

editorOptions :: Html
editorOptions = theme >> zoom >> lineNumbers
    where
      optionFor :: String -> Html
      optionFor text =
          H.option ! A.value (toValue text) $ toHtml text

      theme =
          H.select ! A.id "editor_theme"
                   ! A.onchange "setTheme(this.value)"
                   $ mapM_ optionFor themes
              
      zoom =
          H.select ! A.id "editor_zoom"
                   ! A.onchange "setZoom(this.options[this.selectedIndex].innerHTML)"
                   $ mapM_ optionFor ["100%", "80%", "150%", "200%"]

      lineNumbers = do
        H.span ! A.style "padding-left: 16px;" $ "Line Numbers:"
        H.input ! A.type_ "checkbox"
                ! A.id "editor_lines"
                ! A.onchange "showLines(this.checked);"

docs :: Html
docs = tipe >> desc
    where
      tipe = H.div ! A.class_ "type" $ message >> more

      message = H.div ! A.style "position:absolute; left:4px; right:36px; overflow:hidden; text-overflow:ellipsis;" $ ""

      more = H.a ! A.id "toggle_link"
                 ! A.style "display:none; float:right;"
                 ! A.href "javascript:toggleVerbose();"
                 ! A.title "Ctrl+H"
                 $ ""

      desc = H.div ! A.class_ "doc"
                   ! A.style "display:none;"
                   $ ""

