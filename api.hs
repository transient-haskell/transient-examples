#!/usr/bin/env ./execthirdline.sh
-- compile it with ghcjs and  execute it with runghc
-- set -e && port=`echo ${3} | awk -F/ '{print $(3)}'` && docker run -it -p ${port}:${port} -v $(pwd):/work agocorona/transient:05-02-2017  bash -c "runghc /work/${1} ${2} ${3}"

{- execute as ./api.hs  -p start/<docker ip>/<port>

 invoque: curl http://<docker ip>/<port>/api/hello/john
          curl http://<docker ip>/<port>/api/hellos/john
-}

import Transient.Base
import Transient.Move
import Transient.Move.Utils
import Transient.Indeterminism
import Control.Applicative
import Transient.Logged

import qualified Data.ByteString.Lazy.Char8 as BS

main = keep' . freeThreads $ initNode   apisample



apisample= api $ hello <|> hellostream
    where
    hello= do
        paramName "hello"
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
