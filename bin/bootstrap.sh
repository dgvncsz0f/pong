#!/bin/sh

apt-get install --yes --force-yes git ghc vim curl unzip daemon dnsutils cabal-install netcat-openbsd dnsmasq

if [ ! -x /usr/local/bin/consul ]
then
  tmpfile=$(mktemp) && {
    trap "rm -f $tmpfile" EXIT
    curl -L -k -s "https://dl.bintray.com/mitchellh/consul/0.5.2_linux_amd64.zip" >"$tmpfile.zip"
    unzip -d /usr/local/bin "$tmpfile.zip"
  }
fi

if [ ! -d /var/lib/pong ]
then
  git clone https://github.com/dgvncsz0f/pong.git /var/lib/pong
fi

if [ ! -x /usr/local/bin/pong ]
then
    (cd "/var/lib/pong" && {
        if [ ! -d "$HOME/.cabal/packages/hackage.haskell.org" ]
        then
            while ! timeout 30 cabal update
            do rm -rf "$HOME/.cabal/packages/hackage.haskell.org"; done
        fi
        cabal sandbox init
        cabal configure -O2
        while ! timeout 30 cabal install --only-dependencies -O2
        do :; done
        cabal build
        cp -a dist/build/pong/pong /usr/local/bin/pong
      })
fi
