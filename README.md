# Performing User Studies with the Elm IDE

This project extends the elm-lang.org IDE with the ability to embed arbitrary Elm code in the editor pane.

I have done this for a personal project -- my [undergraduate dissertation](https://github.com/spanners/dissertation).

EmbedMe.elm shows an example of some Elm code embedded in the editor pane that tracks the user's mouse position on mouse-down, which can be useful to model user behaviour during the activity of programming.

## NB: A lot of this code is by [Evan Czaplicki](https://github.com/evancz)

I merely extended it to add embedding Elm code in the editor, and input logging

### Set up

First make sure that you have the Elm compiler installed
([directions](https://github.com/evancz/Elm#elm)).

Then follow these steps to get the website running locally:

```bash
git clone https://github.com/spanners/elm-lang.org
cd elm-lang.org
cabal install --bindir=.
./run-elm-website
```

Great! You should be set up with [elm-lang.org](http://elm-lang.org/) running at
[localhost:8000/](http://localhost:8000/).

You can run `cabal clean` to clear out all cached build information and start fresh.

### Project Structure

- `public/` &mdash; all of the .elm files used for the site. This makes up the
  majority of client-side code.  You can change/delete the existing files and
  add entirely new files. The changes, deletions, and additions will be served
  automatically.

- `resources/` &mdash; the various resources needed for Elm. This is where you
  put all of your non-Elm content, like images, videos, JavaScript code, etc.

- `server/` &mdash; the Haskell files responsible for serving everything from
  .elm files to images. Look here if you need to change how a particular
  resource is served or if you want to disable some of the sites features (such
  as the online editor).
