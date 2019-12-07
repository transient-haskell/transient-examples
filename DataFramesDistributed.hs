import Frames
import qualified Control.Foldl as L

instance (Loggable a) => Distributable DV.Vector a where
   singleton = DV.singleton
   splitAt= DV.splitAt
   fromList = DV.fromList