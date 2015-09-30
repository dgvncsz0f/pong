module Server where

import Data.IORef
import Text.Printf
import Control.Monad
import Network.Socket
import Data.Time.Clock
import Data.Time.Format
import Control.Concurrent
import Control.Applicative

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

handle :: (Socket, SockAddr) -> String -> IO ()
handle (s, _) srvid = do
  msg <- recvLoop s 4
  case msg of
    "ping" -> do
      info "ping"
      sendLoop s (printf "[%s] - pong\n" srvid)
    _      -> sendLoop s (printf "[%s] - fail\n" srvid)

start :: IORef [MVar ()] -> IO (MVar ())
start ref = do
  mvar <- newEmptyMVar
  atomicModifyIORef' ref (\xs -> (mvar : xs, mvar))

signal :: MVar () -> IO ()
signal mvar = putMVar mvar ()

waitall :: IORef [MVar ()] -> IO ()
waitall ref = do
  mvars <- atomicModifyIORef' ref (\xs -> ([], xs))
  mapM_ takeMVar mvars

server :: IORef Bool -> Socket -> String -> IO ()
server ctrl s uuid = do
  cont <- readIORef ctrl
  wait <- newIORef []
  when cont $ do
    mvar <- start wait
    accept s >>= \s -> forkFinally (handle s uuid) (const (signal mvar >> sClose (fst s)))
    server ctrl s uuid
  waitall wait
