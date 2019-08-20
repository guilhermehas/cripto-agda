module Utils where

open import Prelude
open import Data.Unit using (⊤; tt)

vmap : ∀ {a b} {A : Set a} {B : Set b} {n} → (A → B) → Vec A n → Vec B n
vmap f []       = []
vmap f (x ∷ xs) = f x ∷ vmap f xs

++vec++ : ∀ {m n : Nat} {A : Set} → Vec (Vec A m) n → Vec A (n * m)
++vec++ [] = []
++vec++ (x ∷ xs) = x v++ ++vec++ xs

data +Vec : (s : Nat) (n : Nat) → Set where
  [] : +Vec 0 0
  _∷_ : {s : Nat} {n : Nat} → (el : Nat) → +Vec s n → +Vec (el + s) (suc n)

+vecSum : ∀ {s n : Nat} → +Vec s n → Nat
+vecSum {s} _ = s

data +VecHid : Nat → Set where
  +vec : ∀ {s n : Nat} → +Vec s n → +VecHid n

Vec→+Vec : {n : Nat} → Vec Nat n → +VecHid n
Vec→+Vec [] = +vec []
Vec→+Vec (x ∷ v) with Vec→+Vec v
... | +vec +v = +vec (x ∷ +v)

Amount = Nat

NonNil : ∀ {A : Set} → List A → Set
NonNil [] = ⊥
NonNil (_ ∷ _) = ⊤

NonNil? : ∀ {A : Set} → (lista : List A) → Dec (NonNil lista)
NonNil? [] = no (λ z → z)
NonNil? (_ ∷ _) = yes unit


data All {A : Set} : (P : A → Set) → List A → Set where
  [] : {P : A → Set} → All P []
  _∷_ : {x : A} {xs : List A} {P : A → Set} → P x → All P xs → All P (x ∷ xs)

data NonEmptyList : Set → Set where
  el : {A : Set} → A → NonEmptyList A
  _∷_ : {A : Set} → A → NonEmptyList A → NonEmptyList A

NonEmptyToList : {A : Set} → NonEmptyList A → List A
NonEmptyToList (el x) = x ∷ []
NonEmptyToList (x ∷ xs) = x ∷ NonEmptyToList xs

data SubList {A : Set} : List A → Set where
  []   : SubList []
  _¬∷_ : {xs : List A} → (x : A) → SubList xs → SubList (x ∷ xs)
  _∷_  : {xs : List A} → (x : A) → SubList xs → SubList (x ∷ xs)

sub→list : {A : Set} {xs : List A} → SubList xs → List A
sub→list [] = []
sub→list (x ¬∷ xs) = sub→list xs
sub→list (x ∷ xs) = x ∷ sub→list xs

list-sub : {A : Set} {xs : List A} → SubList xs → List A
list-sub [] = []
list-sub (x ¬∷ xs) = x ∷ list-sub xs
list-sub (x ∷ xs) = list-sub xs

nonEmptySub : {A : Set} {xs : List A} → SubList xs → Set
nonEmptySub [] = ⊥
nonEmptySub (_ ¬∷ xs) = nonEmptySub xs
nonEmptySub (_ ∷ _) = ⊤


data _≥n_ : (a b : Nat) → Set where
  z   : zero ≥n zero
  s≥z : ∀ (m n : Nat) → suc m ≥n zero
  s≥s : ∀ (m n : Nat) → m ≥n n → suc m ≥n suc n

_≥n?_ : (a b : Nat) → Dec $ a ≥n b
zero ≥n? zero = yes z
zero ≥n? suc b = no (λ ())
suc a ≥n? zero = yes (s≥z a a)
suc a ≥n? suc b with a ≥n? b
... | yes eq = yes (s≥s a b eq)
... | no ¬eq = no $ ¬suc a b ¬eq
  where
    ¬suc : ∀ (a b : Nat) → ¬ (a ≥n b) → ¬ (suc a ≥n suc b)
    ¬suc zero zero ineq eq = ineq z
    ¬suc zero (suc b) ineq (s≥s .0 .(suc b) ())
    ¬suc (suc a) b ineq (s≥s .(suc a) .b eq) = ineq eq

record SubListProof {A : Set} (lista : List A) (listSub : List A) : Set where
  field
    sub     : SubList lista
    proof   : sub→list sub ≡ listSub

list→subProof : ∀ {A : Set} {{_ : Eq A}} (lista : List A) (sub : List A)
  → Maybe $ SubListProof lista sub
list→subProof [] [] = just (record { sub = [] ; proof = refl })
list→subProof [] (_ ∷ _) = nothing
list→subProof (x ∷ lista) [] with list→subProof lista []
... | nothing  = nothing
... | just record { sub = sub ; proof = proof } = just $ record { sub = x ¬∷ sub ; proof = proof }
list→subProof (x ∷ lista) (y ∷ ys) with x == y
... | yes refl  with list→subProof lista ys
list→subProof (x ∷ lista) (x ∷ ys) | yes refl | nothing = nothing
list→subProof (x ∷ lista) (x ∷ ys) | yes refl | just record { sub = sub ; proof = proof } =
  just $ record { sub = x ∷ sub ; proof = cong (_∷_ x) proof }
list→subProof (x ∷ lista) (y ∷ ys) | no ¬eq with list→subProof lista (y ∷ ys)
list→subProof (x ∷ lista) (y ∷ ys) | no ¬eq | nothing = nothing
list→subProof (x ∷ lista) (y ∷ ys) | no ¬eq | just record { sub = sub ; proof = proof } =
  just $ record { sub = x ¬∷ sub ; proof = proof }

list→sub : ∀ {A : Set} {{_ : Eq A}} (lista : List A) (sub : List A)
  → Maybe $ SubList lista
list→sub [] [] = just []
list→sub [] (_ ∷ _) = nothing
list→sub (x ∷ lista) [] with list→sub lista []
... | nothing  = nothing
... | just sub = just $ x ¬∷ sub
list→sub (x ∷ lista) (y ∷ maySub) with list→sub lista maySub
... | nothing  = nothing
... | just sub with x == y
...    | yes refl = just $ x  ∷ sub
...    | no  ¬p   = just $ x ¬∷ sub

mutual
  data Distinct {A : Set} : (lista : List A) → Set where
    []   : Distinct []
    cons : {lista : List A} (el : A) (dist : Distinct lista) (isDist : isDistinct el lista)
      → Distinct (el ∷ lista)

  isDistinct : {A : Set} (el : A) (lista : List A) → Set
  isDistinct _ [] = ⊤
  isDistinct x (y ∷ lista) = (¬ (x ≡ y)) × isDistinct x lista
