module Tangle (mangle) where

import Data.List
import System.Random

-- | Mangle a text by rotating its words by an offseted generated using the
-- supplied RNG, then splitting it into a list of lists of n contiguous
-- words, and iteratively merging the sublists based on shared prefixes and
-- suffixes.
mangle       :: Int -> StdGen -> String -> String
mangle n rng = unwords . snth . slices n . rot' . words
  where rot' l = let (rn,_) = randomR (0, length l - 1) rng in rot rn l

-- | Rotate lst to the left by n places.
rot n lst = t ++ h
  where (h,t) = splitAt n' lst
        n'    = n `mod` length lst

-- | Split a list into non-overlapping sublists of size n (except possibly for
-- the last sublist)
slices :: Int -> [a] -> [[a]]
slices _ [] = []
slices n ls = s : (slices n l)
  where (s, l) = splitAt n ls

-- | Longest Common 'Transfix'. The length of the longest suffix of x that is
-- a prefix of y.
lctx     :: Eq a => [a] -> [a] -> Int
lctx x y = lctx' (drop (lx - ly) x) y  -- chop x down to the size of y, since y
  where (lx,ly) = (length x, length y) -- can't begin with a suffix longer than itself
        lctx' x y
          | null x         = 0
          | isPrefixOf x y = length x
          | otherwise      = lctx' (tail x) y

-- | Given a `merge head' (a list of words) and a list of lists of words ls,
-- attempt to find a best match for the merge head, where the best match
-- is the list l with the greatest (lctx mh l). Returns the match, the length
-- of the match, and ls modified to exclude the match.
bestMerge       :: [String] -> [[String]] -> (Maybe ([String],Int), [[String]])
bestMerge mh cs = foldl mcheck (Nothing, []) cs
  where mcheck (m,l) c = case lctx mh c of
                           0 -> (m,c:l)
                           n -> case m of
                                  Nothing      -> (Just (c,n), l)
                                  Just (c',n') -> if n > n'
                                                  then (Just (c,n), c':l)
                                                  else (m, c:l)

-- | Synthesize the given list of lists of words into a list of words using
-- a merge rule.
snth        :: [[String]] -> [String]
snth []     = []
snth (mh:cs) = let (ms,_,_) = until (\(_,_,l) -> null l) snth' ([mh],mh,cs) in concat $ reverse ms
  where
    -- Given a list of merges, a current merge head, and a list of merge
    -- candidates, find a new merge head; then return an updated list of
    -- merges, the new merge head, and a list of candidates excluding
    -- the merge head.
    snth' (ms, mh, cs) = let (m,nxt) = bestMerge mh cs
                         in case m of Nothing    -> let nh = head nxt in (nh:ms, nh, tail nxt)
                                      Just (c,n) -> ((drop n c):ms, c, nxt)

