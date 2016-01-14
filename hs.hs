{-#LANGUAGE BangPatterns,TransformListComp #-}

module Main (main) where
    
import qualified Data.Vector.Unboxed.Mutable as MV
import qualified Data.Vector.Unboxed as V
import qualified Data.Vector.Mutable as BMV
import qualified Data.Vector as BV
import GHC.Exts (groupWith,the)
    
import System.IO 
import Control.Monad (forM_)
import Control.Applicative ((<$>))

import Data.Time.Clock.POSIX
import Text.Printf

type Graph = BV.Vector (V.Vector (Int,Int))

main::IO ()
main = 
  withFile "agraph" ReadMode $ \hnd -> do
         (numNodes,graph) <- parse hnd
         visited <- MV.replicate numNodes False
         !start <- getPOSIXTime
         ans <- longestPath visited 0 graph
         !end <- getPOSIXTime
         printf "%d LANGUAGE Haskell %d\n" ans (round $ 1000 * (end - start)::Int)

parse::Handle->IO (Int,Graph)
parse hnd = do
  numNodes <- read <$> hGetLine hnd
  ls <- lines <$> hGetContents hnd
  let graph' = [(the from, edge)|
                l<- ls,
                let [fs,ts,cs]=words l,
                let from = read fs::Int,
                let edge = (read ts,read cs),
                then group by from using groupWith]
  let graph = BV.create $ do
                 v <- BMV.new numNodes
                 forM_ graph' $ \(i,es) -> BMV.write v i (V.fromList es)
                 return v
  return (numNodes,graph)

longestPath :: MV.IOVector Bool -> Int -> Graph -> IO Int
longestPath visited start graph =
    do
      MV.unsafeWrite visited start True
      let neigh = graph `BV.unsafeIndex` start
      ans <- V.foldM' findBest 0 neigh
      MV.unsafeWrite visited start False
      return ans
    where
      findBest cur (t,c) = do
            v <- MV.unsafeRead visited t
            if v then 
              return cur
            else do
              d <- longestPath visited t graph
              return (max cur (c+d))
             
