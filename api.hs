#!/usr/bin/env execthirdlinedocker.sh

-- runghc -DDEBUG -threaded  -i../develold/TCache -i../transient/src -i../transient-universe/src -i../axiom/src    $1  ${2} ${3} 

-- mkdir -p ./static && ghcjs --make  -DDEBUG  -i../transient/src -i../transient-universe/src  -i../axiom/src   $1 -o static/out && runghc -DDEBUG -threaded  -i../develold/TCache -i../transient/src -i../transient-universe/src -i../axiom/src    $1  ${2} ${3} 

 
{- execute as ./api.hs  -p start/<docker ip>/<port>

 invoque: curl http://<docker ip>/<port>/api/hello/john
          curl http://<docker ip>/<port>/api/hellos/john
-}

import Transient.Base
import Transient.Move.Internals
import Transient.Move.Utils
import Transient.Indeterminism
import Control.Applicative
import Transient.Logged

import qualified Data.ByteString.Lazy.Char8 as BS

main = keep' . freeThreads $ initNode   apisample



apisample= api $ hello <|> hellostream
    where
    hello= do
        param "hello"
        name <- paramVal
        let msg=  "hello " ++ name ++ "\n"
            len= length msg
        return $ BS.pack $ "HTTP/1.0 200 OK\nContent-Type: text/plain\nContent-Length: "++ show len
                 ++ "\nConnection: close\n\n" ++ msg


    hellostream = do
        paramName "hellos"
        name <- paramVal

        async (return $ BS.pack
                "HTTP/1.0 200 OK\nContent-Type: text/plain\nConnection: close\n\n")
            <|> do i <- threads 0 $ choose [1 .. 1000]
                   return . BS.pack $ " hello " ++ name ++ show i
