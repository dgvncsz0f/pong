{-# LANGUAGE ForeignFunctionInterface #-}

module Ancillary where

import Foreign
import Foreign.C
import Network.Socket hiding (recvFd, sendFd)
import System.Directory
import Control.Exception
import System.Posix.Types
import Control.Applicative

sendFd :: Fd -> Fd -> IO ()
sendFd s fd =
  throwErrnoIfMinus1_ "sendFD" $ csend_fd (fromIntegral s) (fromIntegral fd)

recvFd :: Fd -> IO Fd
recvFd s =
  alloca $ \fd -> do
    throwErrnoIfMinus1_ "recvFd" $ crecv_fd (fromIntegral s) fd
    fromIntegral <$> peek fd

socketFd :: Socket -> Fd
socketFd = fromIntegral . fdSocket

recvFdFrom :: FilePath -> IO Fd
recvFdFrom path = bracket create destroy (\s -> bracket (fst <$> accept s) sClose (recvFd . socketFd))
    where
      destroy s = do
        removeFile path
        sClose s

      create = do
        s <- socket AF_UNIX Stream defaultProtocol
        bind s (SockAddrUnix path)
        listen s 1
        return s

sendFdTo :: FilePath -> Fd -> IO ()
sendFdTo path fd = bracket create sClose (\s -> sendFd (socketFd s) fd)
    where
      create = do
        s <- socket AF_UNIX Stream defaultProtocol
        connect s (SockAddrUnix path)
        return s

foreign import ccall "ancillary.h send_fd"
  csend_fd :: CInt -> CInt -> IO CInt

foreign import ccall "ancillary.h recv_fd"
  crecv_fd :: CInt -> Ptr CInt -> IO CInt
