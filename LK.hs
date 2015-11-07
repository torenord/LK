import Data.Ord  (comparing)
import Data.Char (toUpper)
import Data.List (delete, intercalate, intersect, minimumBy)

data Formula = Var     Char
             | Not     Formula
             | Or      Formula Formula
             | And     Formula Formula
             | Implies Formula Formula deriving (Show, Eq)

-- Using lists in favor of bags; should be OK as the order is ignored.
type Sequent = ([Formula], [Formula])

data Rule = AlphaRule Sequent
          | BetaRule  Sequent Sequent deriving Show

isAtomic :: Formula -> Bool
isAtomic (Var p) = True
isAtomic _       = False

isAxiom :: Sequent -> Bool
isAxiom (gamma, delta) = filter isAtomic formulas /= []
    where formulas = intersect gamma delta

applyRule :: Sequent -> Maybe Rule
applyRule (gamma, delta)
    | (not . null) nonAtoms =
        Just $ addAtoms $ case nonAtoms of
                 (Not phi:gamma)       -> AlphaRule (gamma, (phi:delta))
                 (Or phi psi:gamma)      -> BetaRule  ((phi:gamma), delta) ((psi:gamma), delta)
                 (And phi psi:gamma)     -> AlphaRule ((phi:psi:gamma), delta)
                 (Implies phi psi:gamma) -> BetaRule  (gamma, (phi:delta)) ((psi:gamma), delta)
    | (not . null) nonAtoms' =
        Just $ addAtoms $ case nonAtoms' of
                 (Not phi:delta)       -> AlphaRule ((phi:gamma), delta)
                 (Or phi psi:delta)      -> AlphaRule (gamma, (phi:psi:delta))
                 (And phi psi:delta)     -> BetaRule  (gamma, (phi:delta)) (gamma, (psi:delta))
                 (Implies phi psi:delta) -> AlphaRule ((phi:gamma), (psi:delta))
    | otherwise = Nothing
    where (atoms,  nonAtoms)  = partition isAtomic gamma
          (atoms', nonAtoms') = partition isAtomic delta
          addAtoms (AlphaRule (gamma, delta)) =
              AlphaRule (gamma++atoms, delta++atoms')
          addAtoms (BetaRule (gamma, delta) (gamma', delta')) =
              BetaRule (gamma++atoms, delta++atoms') (gamma'++atoms, delta'++atoms')

data DeductionTree = Leaf Sequent
                   | Alpha Sequent DeductionTree
                   | Beta Sequent DeductionTree DeductionTree
                     deriving Show

buildTree :: Sequent -> DeductionTree
buildTree sequent = case applyRule sequent of
                      Just (AlphaRule seq) ->
                          Alpha sequent (buildTree seq)
                      Just (BetaRule seq1 seq2) ->
                          Beta sequent (buildTree seq1) (buildTree seq2)
                      Nothing -> Leaf sequent

leaves :: DeductionTree -> [Sequent]
leaves (Leaf sequent) = [sequent]
leaves (Alpha _ tree) = leaves tree
leaves (Beta _ tree1 tree2) = leaves tree1 ++ leaves tree2

isValidSequent :: Sequent -> Bool
isValidSequent seq = all isAxiom $ leaves $ buildTree seq

isValid :: Formula -> Bool
isValid phi = isValidSequent ([], [phi])
