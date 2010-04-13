module Com.DiagMessage

where

import Text.Regex(splitRegex,mkRegex)
import Numeric(showHex,readHex)
import Data.Char(chr,ord)
import Data.Word(Word8)
import Util
import Com.HSFZMessage
import Data.Bits
import Data.List(intersperse,intercalate)

headerLen = 6
diagTimeout = 5000 :: Int -- ms

data DiagnosisMessage = DiagnosisMessage {
  diagSource :: Word8,
  diagTarget :: Word8,
  diagPayload :: [Word8]
} deriving (Eq)
instance Show DiagnosisMessage where
  show (DiagnosisMessage s t xs)  = '[':(showAsHex s) ++ "][" ++ (showAsHex t) ++ "]"
      ++ (showAsHexString xs)

diagMsg2bytes ::  DiagnosisMessage -> [Word8]
diagMsg2bytes m = (diagSource m):(diagTarget m):(diagPayload m)

matchPayload :: DiagnosisMessage -> [Word8] -> Bool
matchPayload (DiagnosisMessage _ _ p) exp =
  length p >= length exp && (take (length exp) p) == exp

diag2hsfz :: DiagnosisMessage -> ControlBit -> HSFZMessage
diag2hsfz dm cb = HSFZMessage cb (length payload) payload
  where payload = diagMsg2bytes dm

hsfz2diag ::  HSFZMessage -> DiagnosisMessage
hsfz2diag hm = DiagnosisMessage (diagBytes!!0) (diagBytes!!1) (drop 2 diagBytes)
  where diagBytes = payload hm

msg2ByteString :: HSFZMessage -> String
msg2ByteString (HSFZMessage bit len payload) =
  map chr $ encodeLength len ++ [0,control2Int bit] ++ (map word8ToInt payload)

bytes2msg :: String -> Maybe HSFZMessage
bytes2msg s =
  nothingIf (length s < headerLen) >>
    let payloadLength = parseLength s in
        nothingIf (length s /= headerLen + payloadLength) >>
          let b = int2control $ ord $ head $ drop 5 s 
              payload = ["hi"] in 
            Just $ HSFZMessage b payloadLength (map (int2Word8 . ord) $ drop headerLen s)

nothingIf ::  Bool -> Maybe Int
nothingIf True = Nothing
nothingIf False = Just 0

parseLength :: String -> Int
parseLength s = (ord $ s!!3) .|. 
  ((ord $ s!!2) `shiftL` 7)  .|. 
  ((ord $ s!!1) `shiftL` 16) .|. 
  ((ord $ s!!0) `shiftL` 24)  

convert :: String -> Char
convert = chr . fst . head . readHex
