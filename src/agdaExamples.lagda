\begin{code}
open import Agda.Primitive as Prim
open import Agda.Builtin.String
open import Prelude using (_≡_ ; List ; [] ; _∷_ ; _×_ ; _,_ ; refl)
\end{code}

%<*Nat>
\begin{code}
data ℕ : Set where
  zero : ℕ
  suc : ℕ → ℕ
\end{code}
%</Nat>

%<*NatElim>
\begin{code}
ℕ-elim : (target : ℕ) (motive : (ℕ → Set))
  (base : motive zero)
  (step : (n : ℕ) → motive n → motive (suc n) )
  → motive target
ℕ-elim zero motive base step = base
ℕ-elim (suc target) motive base step =
  step target (ℕ-elim target motive base step)
\end{code}
%</NatElim>

\begin{code}
infix 0 _≃_

\end{code}
%<*isomorphism>
\begin{code}
record _≃_ (A B : Set) : Set where
  field
    to   : A → B
    from : B → A
    from∘to : ∀ (x : A) → from (to x) ≡ x
    to∘from : ∀ (y : B) → to (from y) ≡ y
\end{code}
%</isomorphism>

\begin{code}
open _≃_

infix 8 1#_
\end{code}

%<*bin>
\begin{code}
data Bit : Set where
  0# : Bit
  1# : Bit

Bin⁺ : Set
Bin⁺ = List Bit

data Bin : Set where
  0#  : Bin
  1#_ : (bs : Bin⁺) → Bin

postulate Bin≃ℕ : Bin ≃ ℕ
\end{code}
%</bin>

%<*sumElim>
\begin{code}
_+_ : ℕ → ℕ → ℕ
n + m = ℕ-elim n (λ _ → ℕ) m λ _ v → suc v
\end{code}
%</sumElim>

%<*sum>
\begin{code}
_+'_ : ℕ → ℕ → ℕ
zero +' m = m
suc n +' m = suc (n + m)
\end{code}
%</sum>

%<*trivialType>
\begin{code}
data ⊤ : Set where
  tt : ⊤
\end{code}
%</trivialType>

%<*botType>
\begin{code}
data ⊥ : Set where

⊥-elim : {A : Set} (bot : ⊥) → A
⊥-elim ()
\end{code}
%</botType>

%<*eitherType>
\begin{code}
data Either {l : Level} (A : Set l) (B : Set l) : Set l where
  left  : (l : A) → Either A B
  right : (r : B) → Either A B

Either-elim : {l l2 : Level} {A B : Set l}
  {motive : (eab : Either A B) → Set l2}
  (target : Either A B)
  (on-left  : (l : A) → (motive (left  l)))
  (on-right : (r : B) → (motive (right r)))
  ------------------------------------------
  → motive target
Either-elim (left  l) onleft onright = onleft  l
Either-elim (right r) onleft onright = onright r
\end{code}
%</eitherType>

%<*boolType>
\begin{code}
Bool : Set
Bool = Either ⊤ ⊤
\end{code}
%</boolType>

%<*ifThenElse>
\begin{code}
if_then_else_ : {l : Level} {A : Set l}
  (b : Bool) (tRes fRes : A) → A
if b then tRes else fRes =
  Either-elim b (λ _ → tRes) λ _ → fRes
\end{code}
%</ifThenElse>

%<*piType>
\begin{code}
∀-elim : ∀ {A : Set} {B : A → Set}
  (L : ∀ (x : A) → B x)
  (M : A)
  -----------------
  → B M
∀-elim L M = L M
\end{code}
%</piType>

%<*mulType>
\begin{code}
data ∑ (A : Set) (B : A → Set) : Set where
  ⟨_,_⟩ : (x : A) → B x → ∑ A B

∑-elim : ∀ {A : Set} {B : A → Set} {C : Set}
  → (∀ x → B x → C)
  → ∑ A B
  ---------------
  → C
∑-elim f ⟨ x , y ⟩ = f x y
\end{code}
%</mulType>

\begin{code}
infixr 5 _::_

data Vector {a} (A : Set a) : ℕ → Set a where
  []  : Vector A zero
  _::_ : ∀ {n} (x : A) (xs : Vector A n) → Vector A (suc n)

Matrix : (A : Set) (m : ℕ) (n : ℕ) → Set
Matrix A m n = Vector (Vector A n) m
\end{code}

%<*vecHead>
\begin{code}
head : {A : Set} {n : ℕ} (vec : Vector A (suc n)) → A
head (x :: vec) = x
\end{code}
%</vecHead>

\begin{code}
_+v_ : {n : ℕ} (P Q : Vector ℕ n) → Vector ℕ n
[] +v [] = []
(x :: P) +v (y :: Q) = (x + y) :: (P +v Q)
\end{code}

%<*matrixSum>
\begin{code}
_+m_ : {m n : ℕ} (P Q : Matrix ℕ m n) → Matrix ℕ m n
[] +m [] = []
(vx :: P) +m (vy :: Q) = (vx +v vy) :: (P +m Q)
\end{code}
%</matrixSum>

%<*funcType>
\begin{code}
bool→Set : (b : Bool) → Set
bool→Set b = if b then ℕ else Bool
\end{code}
%</funcType>

%<*funcTypeUnd>
\begin{code}
bool→Set-und : Bool → Set
bool→Set-und b = if_then_else_ b ℕ Bool
\end{code}
%</funcTypeUnd>

%<*funcType2>
\begin{code}
bool→Set' : Bool → Set
bool→Set' b = if b then ℕ else Bool
\end{code}
%</funcType2>

%<*dataConstructor>
\begin{code}
data Boolean : Set where
  true  : Boolean
  false : Boolean
\end{code}
%</dataConstructor>

%<*vector>
\begin{code}
data Vec : ℕ → Set where
  []   : Vec zero
  _::_ : {size : ℕ} → ℕ → Vec size → Vec (suc size)

nil : Vec zero
nil = []

vec-one : Vec (suc zero)
vec-one = zero :: nil
\end{code}
%</vector>

%<*mulEx>
\begin{code}
∃-vec : {A : Set} → ∑ ℕ (λ n → Vector A n)
∃-vec = ⟨ zero , [] ⟩
\end{code}
%</mulEx>

%<*patternMatch>
\begin{code}
boolean→Set : (b : Boolean) → Set
boolean→Set true = ℕ
boolean→Set false = Bool
\end{code}
%</patternMatch>

%<*record>
\begin{code}
record Person : Set where
  constructor person
  field
    name : String
    age  : ℕ

agePerson : (person : Person) → ℕ
agePerson (person name age) = age
\end{code}
%</record>

%<*id>
\begin{code}
id : {A : Set} (x : A) → A
id x = x
\end{code}
%</id>

%<*idNat>
\begin{code}
zeroℕ : ℕ
zeroℕ = id zero
\end{code}
%</idNat>

%<*funcs>
\begin{code}
id-nat : ℕ → ℕ
id-nat x = x

id-nat' : ℕ → ℕ
id-nat' = λ x → x
\end{code}
%</funcs>

\begin{code}
Rel : Set → Set₁
Rel A = A → A → Set

_∘_ : ∀ {A B C : Set} → (A → B) → (B → C) → (A → C)
_∘_ f g x = g (f x)

\end{code}

%<*wf>
\begin{code}
module WF {A : Set} (_<_ : Rel A) where
  data Acc (x : A) : Set where
    acc : (∀ y → y < x → Acc y) → Acc x

  Well-founded : Set
  Well-founded = ∀ x → Acc x
\end{code}
%</wf>

%<*category>
\begin{code}
record Category (C : Set → Set → Set) : Set₁ where
  constructor cat
  field
    idc : {a : Set} → C a a
    comp : {a b c : Set} → C a b → C b c → C a c

catFunc : Category λ x y → (x → y)
catFunc = cat id _∘_
\end{code}
%</category>

%<*caseOf>
\begin{code}
case_of_ : ∀ {a b} {A : Set a} {B : Set b} → A → (A → B) → B
case x of f = f x
\end{code}
%</caseOf>

%<*filter>
\begin{code}
filter : {A : Set} → (A → Boolean) → List A → List A
filter p [] = []
filter p (x ∷ xs) =
  case p x of
  λ { true  → x ∷ filter p xs
    ; false → filter p xs
    }
\end{code}
%</filter>

%<*filterWith>
\begin{code}
filter' : {A : Set} → (A → Boolean) → List A → List A
filter' p [] = []
filter' p (x ∷ xs) with p x
... | true = x ∷ filter' p xs
... | false = filter p xs
\end{code}
%</filterWith>

%<*postulate>
\begin{code}
postulate someBot : ⊥
\end{code}
%</postulate>

%<*and>
\begin{code}
_and_ : {A B : Set} → A → B → A × B
a and b = a , b
\end{code}
%</and>

%<*equality>
\begin{code}
eq : ∀ {A : Set} (x : A) → x ≡ x
eq x = refl {_} {_} {x}
\end{code}
%</equality>

%<*rewrite>
\begin{code}
postulate P : ℕ → Set
postulate plus-commute : (a b : ℕ) → a + b ≡ b + a

thm : (a b : ℕ) → P (a + b) → P (b + a)
thm a b t rewrite plus-commute a b = t
\end{code}
%</rewrite>
