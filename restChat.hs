#!/usr/bin/env ./execthirdline.sh
-- compile and run within a docker image
-- set -e && executable=`basename -s .hs ${1}` &&  docker run -it -v $(pwd):/work agocorona/transient:04-02-2017  bash -c "ghc /work/${1} && /work/${executable} ${2} ${3}"

{-#LANGUAGE OverloadedStrings #-}

module Main where
import Transient.Base
import Transient.Move
import Control.Applicative
import Transient.Logged
import Transient.Move.Utils
import Data.Text hiding (empty)


main= keep $ initNode apisample

chatMessages= "chatmessages"

apisample= api  $ do
    paramName "chat"

    async (return "HTTP/1.0 200 OK\nContent-Type: text/plain\nConnection: close\n\n")
        <|>  sendMessages chatMessages
        <|>  waitMessages chatMessages

  where


  sendMessages  chatMessages = do
      text <- paramVal
      putMailbox chatMessages  (text :: Text)
      empty

  waitMessages chatMessages =   getMailbox chatMessages

