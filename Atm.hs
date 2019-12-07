{-# LANGUAGE   CPP #-}

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

import  Transient.Move
import Transient.Move.Utils
import Control.Applicative
import Control.Monad
import Data.Typeable
import Data.IORef
import Control.Concurrent (threadDelay)
import Control.Monad.IO.Class
import Control.Concurrent.MVar
import System.Random
import System.IO.Unsafe

data Operation= Operation String

-- Follows  http://www.math-cs.gordon.edu/courses/cs211/ATMExample/
-- to demostrate how it is possible to program at the user requiremente level
-- the program follows closely the specifications and be clear enough to be understood
-- by the client

main= keep $ initNode atm



atm= do
   card <- waitCard
   pin <- enterPIN
   validateBank pin card
   setData card
   performTransactions <|> cancel
   returnCard

performTransactions = do
    clearScreen
    operation <- withdrawal <|> deposit <|> transfer <|> balanceInquiry
    printReceipt operation
    return ()

withdrawal= do
    local . render $ wlink ()  $ toElem "withdrawall"
    local . render $ wprint "choose bank account"
    account <- chooseAccount
    wprint "Enter the quantity"
    quantity <- getInt Nothing
    if quantity `rem` 20 /= 0
      then do
        wprint "multiples of $20.00 please"
        stop
      else do
        r <- approbalBank account quantity
        case r of
            False -> do
                wprint "operation denied. sorry"
                wprint "Another transaction?"
                r <- wlink True (b "yes ") <|> wlink False << (b "No")
                if not r then return ()
                                 else performTransactions
            True  ->  giveMoney r

deposit= do
    wlink () $ b "Deposit "
    wprint "choose bank account"
    account <- chooseAccount
    r <- approbalBankDeposit account
    case r of
        False -> do wprint "operation denied. sorry"
                    stop
        True  -> do
            r <- waitDeposit <|> timeout
            case r of
                False -> do wprint "timeout, sorry"; stop
                True  -> return ()

transfer= do
    wlink () $ b "Transfer "
    wprint "From"
    ac <- chooseAccount
    wprint "amount"
    amount <- inputDouble Nothing
    wprint "To"
    ac' <- chooseAccount
    transferAccBank ac ac' amount
    return()

balanceInquiry= do
    wprint "From"
    ac <- chooseAccount
    r <- getBalanceBank ac
    wprint $ "balance= "++ show r

validateBank pin card = atRemote $ validate' pin card (0 :: Int)
   where
   validate' pin card times= local $ do
    r <- verifyPinBank pin card
    if r then return () else do
     if times ==2
      then do
        wprint ("three tries. card will be retained" :: String)
        stop

      else validate' pin card $ times + 1

rtotal= unsafePerformIO $ newEmptyMVar
ractive= unsafePerformIO $ newMVar False

switchOnOff= on <|> off
  where
  on= do
     wbutton () "On"
     wprint "enter total amount of money"
     total <- getInt Nothing
     liftIO $ do
       tryTakeMVar rtotal
       putMVar rtotal total
  off= do
     wbutton () "Off"
     active <- liftIO $ readMVar ractive
     if active then stop else wprint "ATM stopped"

type AccountNumber= String
newtype Card= Card [AccountNumber]  deriving Typeable

waitCard = local $ render $ wbutton Card "enter card"

enterPIN= local $ do
      wprint "Enter PIN"
      render $ getInt Nothing `fire` OnChange

cancel= wbutton () "Cancel"

returnCard= wprint "Card returned"

clearScreen=  wraw $ forElems "body" $ this >> clear


printReceipt= do
    Operation str <- getSData <|> error "no operation"
    wprint $ "receipt: Operation:"++ str

chooseAccount= do
    Card accounts <- getSData <|> error "transfer: no card"
    wprint "choose an account"
    mconcat[wlink ac (fromStr $ ' ':show ac) | ac <- accounts]

approbalBank ac quantity= return True

giveMoney n= wprint $ "Your money : " ++ show n ++ " Thanks"

approbalBankDeposit ac= return True

transferAccBank ac ac' amount= wprint $ "transfer from "++show ac ++ " to "++show ac ++ " done"

getBalanceBank ac= liftIO $ do
    r <- rand
    return $ r * 1000

verifyPinBank _ _= liftIO $ do
    liftIO $ print "verifyPinBank"
    r <- rand
    if r > 0.2 then return True else return False

waitDeposit = do
     n <- liftIO rand
     if n > 0.5 then return True else return False

rand:: IO Double
rand= randomRIO

timeout t= threadDelay $ t * 1000000

