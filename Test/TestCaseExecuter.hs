module Test.TestCaseExecuter

where

import Test.DiagnosisTestCase
import DiagnosticConfig
import Util
import Data.Word
import Control.Monad
import Data.Maybe
import Com.DiagClient

type ErrorDesc = String

data TestResult = TR {
  testCount :: Int,
  errors :: [ErrorDesc]
} deriving (Show)

combine :: TestResult -> TestResult -> TestResult
combine (TR a as) (TR b bs) = TR (a+b) (as ++ bs)

expect :: [Word8] -> Maybe DiagnosisMessage -> IO (Maybe ErrorDesc)
expect xs Nothing = return Nothing
expect xs (Just msg) = 
    if (diagPayload msg == xs) 
      then return Nothing
      else return $ (Just errorMsg)
        where errorMsg = "damn it!! expected" ++ showAsHexString xs ++ " but was " ++ (showAsHexString $ diagPayload msg)
      

runTestCase ::  TestCase -> IO (Maybe ErrorDesc)
runTestCase (TestCase name msg expected timeout) =
  sendData conf (diagPayload msg) >>= expect expected 

runTestRun :: TestRun -> IO TestResult
runTestRun (SingleLevel ts) = do
  mes <- forM ts runTestCase
  return $ TR (length mes) (catMaybes mes)
runTestRun (MultiLevel rs) = do
  foldM comb (TR 0 []) rs 
    where comb acc tr =  (combine acc) `liftM` (runTestRun tr)
