import Control.Monad
import Data.List
import Random

data Student a = Student a deriving Show
data Lecturer a = Lecturer a deriving Show
data Room a = Room a deriving Show
data Requirement a = Requirement { student :: Student a, lecturer :: Lecturer a, room :: Room a } deriving Show
data Unit requirements = Unit requirements deriving Show
data Solution units = Solution units deriving Show

instance Ord a => Eq (Student a) where
	(Student a1) == (Student a2) = (a1 == a2)

instance Ord a => Eq (Lecturer a) where
	(Lecturer a1) == (Lecturer a2) = (a1 == a2)

instance Ord a => Eq (Room a) where
	(Room a1) == (Room a2) = (a1 == a2)


readRequirements :: a -> [Requirement Int]
readRequirements file = undefined

collisions (Solution units) = case units of
	[] -> 0
	unit : units' -> if collides(unit)
									 then 1 + collisions(Solution units')
									 else 0 + collisions(Solution units')

collides (Unit requirements) = or $ do
	requirement1 : ys <- tails requirements
	requirement2 <- ys
	return $ student(requirement1) == student(requirement2)
		|| lecturer(requirement1) == lecturer(requirement2)
		|| room(requirement1) == room(requirement2)

-- mutate (units) = do
-- 2 Zahlen würfeln, der größe nach sortieren, die kleine von der größeren abziehen und zwemal splitAt verwenden

-- | This is a /fancy/ @documentation@ for 'perm'
perm :: [a] -> IO [a]
perm xs = if null xs then return [] else do
	i <- randomRIO(0, length(xs) - 1)
	let (pre, this : post) = splitAt i xs
	ys <- perm $ pre ++ post
	return $ this : ys
	
-- exchange :: [a] -> IO [a]
-- exchange xs = do
--  i <- randomRIO(0, length xs - 1)
--  j <- randomRIO(0, length xs - 1)
--  let a = min i j
--  let b = max i j
--  if a == b
--  then return xs
--  else
--    let (pre, postTemp) = splitAt a xs
--    let (y : mid, z : post) = splitAt (b - a) postTemp
--    return $ pre ++ [z] ++ mid ++ [y] ++ post2

getRandomNumber maxNum = do
	-- stdgen <- getStdGen
	-- let (number, gen) = randomR (0, maxNum - 1) stdgen :: (Int, StdGen)
	-- newStdGen
	x <- randomRIO(0, maxNum - 1)
	return x

-- solveRandomly solution = 
-- 	if collisions(solution) > 0
-- 	then solveRandomly(mutate(solution))
-- 	else solution

rs = [Requirement (Student 1) (Lecturer 1) (Room 1), Requirement (Student 2) (Lecturer 1) (Room 2)]