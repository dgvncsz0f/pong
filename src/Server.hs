module Server where

import Data.IORef
import Text.Printf
import Control.Monad
import Network.Socket
import Data.Time.Clock
import Data.Time.Format
import Control.Concurrent

info :: String -> IO ()
info msg = do
  time <- formatTime defaultTimeLocale rfc822DateFormat <$> getCurrentTime
  putStrLn $ printf "%s - %s" time msg

recvLoop :: Socket -> Int -> IO String
recvLoop s = go []
  where
    go acc len
      | len == 0  = return acc
      | otherwise = do
          m <- recv s len
          if (length m == 0)
            then return acc
            else go (acc ++ m) (len - length m)

sendLoop :: Socket -> String -> IO ()
sendLoop s m
  | null m  = return ()
  | otherwise = do
      l <- send s m
      sendLoop s (drop l m)

handle :: (Socket, SockAddr) -> IO ()
handle (s, _) = do
  msg <- recvLoop s 4
  case msg of
    "ping" -> info "ping" >> sendLoop s "pong\n"
    _      -> sendLoop s "fail\n"

server :: IORef Bool -> Socket -> IO ()
server ctrl s = do
  cont <- readIORef ctrl
  when cont $ do
    accept s >>= \s -> forkFinally (handle s) (const $ sClose $ fst s)
    server ctrl s
