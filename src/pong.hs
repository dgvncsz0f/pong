module Main (main) where

import Server
import Ancillary
import Data.UUID
import Data.IORef
import Data.Maybe
import Data.UUID.V1
import Network.Socket
import System.Environment
import Control.Applicative
import System.Posix.Signals.Exts

standaloneServer :: IO Socket
standaloneServer = do
  let hints = defaultHints { addrFlags =  [AI_NUMERICHOST]}
  port     <- readPort
  host     <- readHost
  addrinfo <- head <$> getAddrInfo (Just hints) (Just host) (Just port)
  s <- socket (addrFamily addrinfo) (addrSocketType addrinfo) (addrProtocol addrinfo)
  setSocketOption s ReuseAddr 1
  bind s (addrAddress addrinfo)
  listen s 4
  return s

makeSocket :: Maybe FilePath -> IO Socket
makeSocket Nothing  = standaloneServer
makeSocket (Just p) = do
  fd <- fromIntegral <$> recvFdFrom p
  mkSocket fd AF_INET Stream defaultProtocol Listening

readPath :: IO String
readPath = maybe "/tmp/pong.socket" id . lookup "socket" <$> getEnvironment

readHost :: IO String
readHost = maybe "0.0.0.0" id . lookup "host" <$> getEnvironment

readPort :: IO String
readPort = maybe "9000" id . lookup "port" <$> getEnvironment

main :: IO ()
main = do
  path <- readPath
  mode <- maybe "start" id . listToMaybe <$> getArgs
  ctrl <- newIORef True
  uuid <- maybe "--" toString <$> nextUUID
  s    <- case mode of
            "start" -> makeSocket Nothing
            "clone" -> makeSocket $ Just path
            _       -> error $ "invalid mode: " ++ mode
  installHandler sigTERM (Catch $ writeIORef ctrl False) Nothing
  installHandler sigWINCH (Catch $ sendFdTo path (socketFd s)) Nothing
  server ctrl s uuid
