module Transactions where

open import Prelude
open import Operators
open import Utils
open import Cripto

record TXField : Set where
  field
    amount : Amount
    address : Address

record TXFieldWithId : Set where
    field
      time     : Time
      position : Nat
      amount   : Amount
      address  : Address

removeId : TXFieldWithId → TXField
removeId record { time = time ; position = position ; amount = amount ; address = address }
  = record { amount = amount ; address = address }

addId : (position : Nat) (time : Time) (txs : List TXField) → List TXFieldWithId
addId position time [] = []
addId position time (record { amount = amount ; address = address } ∷ txs)
  = record { time = time ; position = position ; amount = amount ; address = address } ∷ addId (suc position) time txs

sameIdList : (time : Time) → (txs : NonEmptyList TXFieldWithId) → Set
sameIdList time (el tx)    =  TXFieldWithId.time tx ≡ time
sameIdList time (tx ∷ txs) = TXFieldWithId.time tx ≡ time × sameIdList time txs

incrementList : (order : Nat) → (txs : NonEmptyList TXFieldWithId) → Set
incrementList order (el tx) =  TXFieldWithId.position tx ≡ order
incrementList order (tx ∷ txs) =  TXFieldWithId.position tx ≡ order × incrementList (suc order) txs

data ListOutput : (time : Time) → Set where
  listOut : (time : Time) → (out : NonEmptyList TXFieldWithId)
    → sameIdList time out → incrementList zero out
    → ListOutput time

ListOutput→List : ∀ {time : Time} → (outs : ListOutput time) → List TXFieldWithId
ListOutput→List (listOut _ outs _ _) =  NonEmptyToList outs


TX→Msg : (tx : TXField) → Msg
TX→Msg record { amount = amount ; address = (nat address) } = nat amount +msg nat address

TXId→Msg : (tx : TXFieldWithId) → Msg
TXId→Msg record { time = (nat time) ; position = position ; amount = amount ; address = (nat address) }
  = nat time +msg nat position +msg nat amount +msg nat address

txInput→Msg : (input : TXFieldWithId) → (outputs : List TXField)
  → NonNil outputs → Msg
txInput→Msg input [] ()
txInput→Msg input (output ∷ outputs) _ with NonNil? outputs
... | yes nonNil =  TXId→Msg input +msg TX→Msg output +msg txInput→Msg input outputs nonNil
... | no nil = TXId→Msg input +msg TX→Msg output


txEls→Msg : ∀ {inputs : List TXFieldWithId}
  → (input : TXFieldWithId) → (outputs : List TXFieldWithId)
  → NonNil inputs × NonNil outputs → Msg
txEls→Msg input [] (_ , ())
txEls→Msg input (output ∷ outputs) _ = txInput→Msg input (map removeId (output ∷ outputs)) unit

txFieldList→TotalAmount : (txs : List TXFieldWithId) → Amount
txFieldList→TotalAmount txs = sum $ map amount txs
  where open TXFieldWithId

record TXSigned (inputs : List TXFieldWithId) (outputs : List TXFieldWithId) : Set where
  field
    nonEmpty : NonNil inputs × NonNil outputs
    signed   : All
      (λ input → SignedWithSigPbk (txEls→Msg input outputs nonEmpty) (TXFieldWithId.address input))
       inputs
    in≥out : txFieldList→TotalAmount inputs ≥n txFieldList→TotalAmount outputs

record RawTXSigned : Set where
  field
    inputs   : List TXFieldWithId
    outputs  : List TXFieldWithId
    tx       : TXSigned inputs outputs

record RawInput : Set where
  field
    time      : Time
    position  : Nat
    amount    : Amount
    msg       : Msg
    signature : Signature
    publicKey : PublicKey

record RawTransaction : Set where
  field
    inputs   : List RawInput
    outputs  : List TXField

sigInput : (input : RawInput) → (outputs : List TXFieldWithId)
  → Maybe $ SignedWithSigPbk (RawInput.msg input) $ publicKey2Address $ RawInput.publicKey input
sigInput record { time = time ; position = position ; amount = amount ;
  msg = msg ; signature = signature ; publicKey = publicKey }
  outputs with Signed? msg publicKey signature
... | yes signed = just $ record
         { publicKey = publicKey ; pbkCorrect = refl ; signature = signature ; signed = signed }
... | no _ = nothing

raw→TXField : (input : RawInput) → TXFieldWithId
raw→TXField record { time = time ; position = position ; amount = amount ;
  msg = msg ; signature = signature ; publicKey = publicKey }
   = record { time = time ; position = position ; amount = amount ; address = publicKey2Address publicKey }

raw→TXSigned : ∀ (time : Time) → (ftx : RawTransaction)
  → Maybe RawTXSigned
raw→TXSigned time record { inputs = inputs ; outputs = outputs } with NonNil? inputs
... | no _ = nothing
... | yes nonNilInp with NonNil? outputs
...    | no _ = nothing
...    | yes nonNilOut = ans
  where
    inpsField : List TXFieldWithId
    inpsField = map raw→TXField inputs

    outsField : List TXFieldWithId
    outsField = addId 0 time outputs

    nonNilMap : ∀ {A B : Set} {f : A → B} → (lista : List A) → NonNil lista → NonNil (map f lista)
    nonNilMap [] ()
    nonNilMap (_ ∷ _) nla = unit

    nonNilImpTX : NonNil inpsField
    nonNilImpTX = nonNilMap inputs nonNilInp

    nonNilAddId : {time : Time} (outputs : List TXField) (nonNilOut : NonNil outputs)
      → NonNil (addId 0 time outputs)
    nonNilAddId [] ()
    nonNilAddId (_ ∷ outputs) nonNil = nonNil

    nonNilOutTX : NonNil outsField
    nonNilOutTX = nonNilAddId outputs nonNilOut

    nonEmpty : NonNil inpsField × NonNil outsField
    nonEmpty = nonNilImpTX , nonNilOutTX

    All?Signed : (inputs : List RawInput) →
        Maybe (All (λ input → SignedWithSigPbk (txEls→Msg input outsField nonEmpty)
        (TXFieldWithId.address input)) (map raw→TXField inputs))
    All?Signed [] = just []
    All?Signed (input ∷ inputs)
      with Signed? (txEls→Msg (raw→TXField input) outsField nonEmpty)
      (RawInput.publicKey input) (RawInput.signature input)
    ... | no _ = nothing
    ... | yes signed with All?Signed inputs
    ...    | nothing = nothing
    ...    | just allInputs = just $ (record
                                        { publicKey = RawInput.publicKey input
                                        ; pbkCorrect = refl
                                        ; signature = RawInput.signature input
                                        ; signed = signed
                                        }) ∷ allInputs

    in≥out : Dec $ txFieldList→TotalAmount inpsField ≥n txFieldList→TotalAmount outsField
    in≥out =  txFieldList→TotalAmount inpsField ≥n? txFieldList→TotalAmount outsField

    ans : Maybe RawTXSigned
    ans with All?Signed inputs
    ... | nothing = nothing
    ... | just signed with in≥out
    ...    | no _       = nothing
    ...    | yes in>out = just $ record { inputs = inpsField ; outputs = outsField ;
      tx = record { nonEmpty = nonEmpty ; signed = signed ; in≥out = in>out } }
