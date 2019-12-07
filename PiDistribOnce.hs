#!/usr/bin/env ./execthirdline.sh
-- compile and run within a docker image
-- set -e && executable=`basename -s .hs ${1}` &&  docker run -it -v $(pwd):/work agocorona/transient:05-02-2017  bash -c "ghc /work/${1} && /work/${executable} ${2} ${3}"


-- Distributed streaming using Transient
-- See the article: https://www.fpcomplete.com/user/agocorona/streaming-transient-effects-vi

{-# LANGUAGE ScopedTypeVariables, DeriveDataTypeable, MonadComprehensions  #-}
module MainOnce where
import Transient.Base
import Transient.Move
import Transient.Indeterminism
import Transient.Logged
import Transient.Stream.Resource
import Control.Applicative
import Data.Char
import Control.Monad
import Control.Monad.IO.Class
import System.Random
import Data.IORef
import System.IO
import GHC.Conc
import System.Environment



-- distributed calculation of PI
-- This example program is the closest  one to the defined in the spark examples: http://tldrify.com/bpr
-- But while the spark example does not contain the setup of the cluster and the confuguration/initalization
-- this examples includes everything

-- The nodes are simulated within the local process, but they communicate trough sockets and serialize data
-- just like real nodes. Each node spawn threads and return the result to the calling node.
-- when the number of result are reached `colect` kill the threads, the sockets are closed and the stream is stopped

-- for more details look at the article: https://www.fpcomplete.com/tutorial-edit/streaming-transient-effects-vi
--

main= do
   let numNodes= 5
       numSamples= 1000
       ports= [2000.. 2000 + numNodes -1]
       createLocalNode p= createNode "localhost"  p
       nodes= map createLocalNode ports


   keep $ do
      addNodes nodes
--     option "start" "start"
      xs <- collect  numSamples $ runCloud $ do
         foldl (<|>) empty (map listen nodes) <|> return()
         local $ threads 2 $ runCloud $
                 clustered[if x * x + y * y < (1 :: Double) then 1 else (0 :: Int)| x <- random, y <-random]

      liftIO $ print (4.0 * (fromIntegral $ sum xs) / (fromIntegral numSamples) :: Double)
      exit

     where
     random=  local $ waitEvents' randomIO :: Cloud Double

