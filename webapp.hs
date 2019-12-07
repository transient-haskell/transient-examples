#!/usr/bin/env execthirdlinedocker.sh
-- compile it with ghcjs and  execute it with runghc
-- mkdir -p static && ghcjs ${1} -o static/out && runghc ${1} ${2} ${3}

-- To execute directly from source, you need docker installed

-- usage: ./webapp.hs -p start/<docker ip>/<port>

{-# LANGUAGE CPP #-}

module Main where

import Prelude hiding (div, id, span)
import Transient.Internals
import GHCJS.HPlay.View
import Transient.Move
import Transient.Indeterminism
import Data.IORef
import Control.Concurrent (threadDelay)
import Control.Monad.IO.Class
import Data.Monoid

-- Show the composability of transient web aplications
-- with three examples composed together, each one is a widget that execute
-- code in the browser AND the server.
main = keep $ initNode $ demo <|> demo2 <|> counters

demo :: Cloud ()
demo = onBrowser $ do 
    name <- local . render $ do
          rawHtml $ do
               hr
               p "This snippet captures the essence of this demonstration"
               p $ do
                    span "it's a blend of server and browser code in a "
                    span $ b "composable"
                    span " piece"
               div ! id (fs "fibs") $ i "Fibonacci numbers should appear here"

          wlink () (p " stream fibonacci numbers")
     -- stream fibonacci
    r <- do  --  atRemote $ do
          let fibs = 0 : 1 : zipWith (+) fibs (tail fibs) :: [Int]  -- fibonacci numb. definition
          r <- local . threads 1 . choose $ take 10 fibs
          localIO $ print r
          localIO $ threadDelay 1000000
          return r

    local . render . at (fs "#fibs") Append $ rawHtml $ (h2 r)

demo2 :: Cloud ()
demo2 = do 
     name <- local . render $  do
          rawHtml $ do
               hr
               br
               br
               p "In this example you enter your name and the server will salute you"
               br
          --       inputString (Just "Your name") `fire` OnKeyUp       -- send once a char is entered
          inputString Nothing !
            atr "placeholder" (fs "enter your name") `fire`
            OnKeyUp <++
            br     
                                               -- new line
     r <-  atRemote . localIO $ print (name ++ " calling") >> return ("Hi " ++ name)
     local . render . rawHtml $  do p " returned"
                                    h2 r

fs = toJSString

counters :: Cloud ()
counters = do
     local . render . rawHtml $ do
          hr
          p "To demonstrate the use of teleport, widgets, interactive streaming"
          p "and composability in a web application."
          br
          p "This is one of the most complicated interactions: how to control a stream in the server"
          p "by means of a web interface without loosing composability."
          br
          p "in this example, events flow from the server to the browser (a counter) and back from"
          p "the browser to the server (initiating and cancelling the counters)"

     counter <|> counter 
     where 
     counter  = onBrowser $ do

             id1 <- local  genNewId
             rstop <- fixRemote $ liftIO $ newIORef  False
             
             local $ render $ rawHtml $ span ""
             op <- counterInterface id1

             r <- atRemote $ local $ do -- run in the server
                    case op of
                      
                      "start"  -> do single $ stream  rstop 
                      "cancel" -> do liftIO $ writeIORef rstop True >> print "SETSET"; stop
                     
             local $ render $ at ( toJSString "#" <> id1) Insert  $ rawHtml $ h1 r

     counterInterface id1 = local $ render $
             inputSubmit "start"  `fire` OnClick <|>
             inputSubmit "cancel" `fire` OnClick <++ do
                      br
                      div ! id id1 $ h1 "0"

        -- executes a remote non-serilizable action whose result can be used by subsequent `atRemote` sentences
     fixRemote mx= do
             r <- lazy mx
             fixClosure
             return r
        
        -- experimental: remote invocatioms will not re-execute non serializable statements before it
        -- to be added to the library in next releases probably
     fixClosure= atRemote $ local $ return ()
        
        -- generates a sequence of numbers
     stream rstop  = do
             liftIO $  writeIORef rstop False ;
             counter <- liftIO $ newIORef (1 :: Int)
             r <- parallel $ do
                  s <- readIORef rstop
                  if s then return SDone else SMore <$> do
                    n <- atomicModifyIORef counter $ \r -> (r + 1,r)
                    threadDelay 1000000
                    putStr "generating: " >> print n
                    return n
             case r of
                 SMore n -> return n
                 SDone   -> empty



