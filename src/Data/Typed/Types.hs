{-# LANGUAGE DeriveFoldable      #-}
{-# LANGUAGE DeriveFunctor       #-}
{-# LANGUAGE DeriveGeneric      #-}
{-# LANGUAGE DeriveAnyClass       #-}
{-# LANGUAGE DeriveTraversable   #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Data.Typed.Types(
  module Data.Model.Types
  ,LocalName(..),AbsoluteType,ADTEnv,AbsEnv,AbsType,AbsRef,AbsADT,RelADT,ADTRef(..),Ref(..)
  ,NonEmptyList(..),nonEmptyList
  ,TypedValue(..),TypedBytes(..),Label(..),Val(..)
  ,proxyOf
  ) where

import           Control.DeepSeq
import qualified Data.Map         as M
import           Data.Model.Types
import           Data.Word

data Label a = Label a (Maybe String) deriving (Eq, Ord, Show, NFData, Generic)

newtype LocalName = LocalName String deriving (Eq, Ord, Show, NFData, Generic)

data TypedBytes = TypedBytes AbsType [Word8] deriving (Eq, Ord, Show,NFData,  Generic)

data TypedValue a = TypedValue AbsType a deriving (Eq, Ord, Show, Functor,NFData,  Generic)

type AbsoluteType = (AbsType,AbsEnv)

-- BUG: Possible name clash.
type AbsEnv = M.Map String (AbsRef,AbsADT)

type ADTEnv = M.Map AbsRef AbsADT

-- Absolute Type
type AbsType = Type AbsRef

type AbsRef = Ref AbsADT

type AbsADT = NonEmptyList RelADT

type RelADT = ADT String ADTRef

data ADTRef =
  Var Word8     -- Variable
  | Rec String  -- Recursive reference, either to the type being defined or a mutually recursive type
  | Ext AbsRef -- Pointer to external definition
  deriving (Eq, Ord, Show, NFData, Generic)

data Ref a =
  Verbatim (NonEmptyList Word8) -- NO: must be explicitly padded. White padded serialisation (if required, exact bits can be recovered by decoding and recoding.. or byte padding has to be part of the definition!)
  -- | List Bit -- Express exactly the right number of bits (1/16 bits overhead per bit), useful property: adding serialised sequences without the need of decoding them.
  | Shake128 (NonEmptyList Word8)
  -- | Hash Shake128  -- A, possibly infinite sequence of bytes (useful up to 256 bit), shorter codes are prefixes of longer ones.
  deriving (Eq,Ord,Read,Show,NFData, Generic)

-- data Bytes = Bytes (NonEmptyList Word8)
-- data Shake128 = Shake128 (NonEmptyList Word8) deriving (Eq,Ord,Read,Show,Generic)

data NonEmptyList a = Elem a
                    | Cons a (NonEmptyList a)
                    deriving (Eq,Ord,Show,Read,NFData ,Generic,Functor,Foldable,Traversable)

nonEmptyList :: [a] -> NonEmptyList a
nonEmptyList [] = error "Cannot convert an empty list to NonEmptyList"
nonEmptyList (h:[]) = Elem h
nonEmptyList (h:t) = Cons h (nonEmptyList t)

  -- Generic value (used for dynamic decoding)
data Val = Val
    String -- Constructor name
    [Bool] -- Bit encoding (for debugging purposes)
    [Val]  -- Values to which the constructor is applied, if any
    deriving Show

proxyOf :: a -> (Proxy a)
proxyOf _ = Proxy ::Proxy a
