#!/usr/bin/env execthirdlinedocker.sh

-- cd `dirname $1` && mkdir -p ./static && ghcjs -DDEBUG  -i../transient/src -i../transient-universe/src  -i../axiom/src  `basename $1` -o static/out && ghc -DDEBUG -threaded  -i../develold/TCache -i../transient/src -i../transient-universe/src -i../axiom/src  `basename $1` && ./`basename $1 .hs`  ${2} ${3}

-- cd `dirname $1` && mkdir -p ./static && ghcjs -DDEBUG `basename $1`  -o static/out && ghc -DDEBUG -threaded  `basename $1` && ./`basename $1 .hs`  ${2} ${3}


{-# LANGUAGE DeriveDataTypeable , ExistentialQuantification
    ,ScopedTypeVariables, StandaloneDeriving, RecordWildCards, FlexibleContexts, CPP
    ,GeneralizedNewtypeDeriving #-}

module Main where

import Prelude hiding (div)
import Transient.Base
#ifdef ghcjs_HOST_OS
   hiding ( option,runCloud')
#endif
import GHCJS.HPlay.View
#ifdef ghcjs_HOST_OS
   hiding (map)
#else
   hiding (map, option,runCloud')
#endif

import  Transient.Move  hiding(teleport)
import Control.Applicative
import Control.Monad
import Data.Typeable
import Data.IORef
import Control.Concurrent (threadDelay)
import Control.Monad.IO.Class
import Data.Monoid
import Data.String

{-
Example with different input fields with events and haskell combinators

The hplayground version is running at:

http://tryplayg.herokuapp.com/try/widgets.hs/edit

That running version uses the Haste haskell to JS compiler, while this has to be compiled
with GHCJS. Some differences:

This is a client AND server side app. while the hplayground one is purely client-side

If you have installed transient, transient-universe and ghcjs-hplay packages, just compile and run it with


ghcjs   examples/widgets.hs -o static/out
runghc  examples/widgets.hs

Also is different:
now Widgets run in his own monad. To render them and convert them to the Transient monad it
uses `render`. Since `simpleWebApp` expect a `Cloud` application, use `local` to run a local transient computation. `onBrowser` only execute in the web browser, so the server application does nothing. Simply stay watching at the port 8081 for browser requests.

Also the <br> tags have been moved to the widgets and the **> has been substituted by the more standard <|> operator. In the other side,  rawHtml (=== wraw) is more readable.

-}

data Person= Person{name :: String , age :: Int} deriving (Read,Show)

main= keep $ initNode $ onBrowser $ local $   buttons  <|> linksample
    where
    linksample= do
          r <-  render $ br ++> br ++> wlink "Hi!" (toElem "This link say Hi!")`fire` OnClick
          render $ rawHtml . b  $ " returns "++ r

    buttons :: TransIO ()
    buttons= do
           render . rawHtml $ p "Different input elements:"
           inputPerson <|> radio <|> checkButton <|> select



    inputPerson= do
       per <- render $ Person <$> (div <<< inputString Nothing) -- `fire` OnChange
                              <*> (div <<< inputInt Nothing) 
                              <** inputSubmit "send" `fire` OnClick
       render . rawHtml $ p per
    
    checkButton :: TransIO ()
    checkButton=do
           rs <- render $  br ++> br ++>  getCheckBoxes(
                           ((setCheckBox False "Red"   <++ b "red")   `fire` OnClick)
                        <> ((setCheckBox True "Green"  <++ b "green") `fire` OnClick) 
                        <> ((setCheckBox False "blue"  <++ b "blue")  `fire` OnClick))
           render $ rawHtml $ fromString " returns: " <> b (show rs)
           empty

    radio :: TransIO ()
    radio= do
           r <- render $ getRadio [fromString v ++> setRadioActive True v
                                    | v <- ["red","green","blue"]]

           render $ rawHtml $ fromString " returns: " <> b ( show r )

    select :: TransIO ()
    select= do
           r <- render $ br ++> br ++> getSelect
                          (   setOption "red"   (fromString "red")
                          <|> setOption "green" (fromString "green")
                          <|> setOption "blue"  (fromString "blue"))
                  `fire` OnClick

           render $ rawHtml $ fromString " returns: " <> b ( show r )
