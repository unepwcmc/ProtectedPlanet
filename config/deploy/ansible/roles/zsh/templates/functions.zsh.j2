# Test if HTTP compression (RFC 2616 + SDCH) is enabled for a given URL.
# Send a fake UA string for sites that sniff it instead of using the Accept-Encoding header. (Looking at you, ajax.googleapis.com!)
httpcompression() {
  encoding="$(curl -LIs -H 'User-Agent: Mozilla/5 Gecko' -H 'Accept-Encoding: gzip,deflate,compress,sdch' "$1" | grep '^Content-Encoding:')" && echo "$1 is encoded using ${encoding#* }" || echo "$1 is not using any encoding"
}

# All the dig info
digga() {
  dig +nocmd "$1" any +multiline +noall +answer
}

notify() {
  sleep $1 && xmessage -nearmouse "$2"
}

# Moves to, or creates and moves to, a project folder in ~/src/ named
# after the first parameter
p() {
  SRC="$HOME/src/"
  LOC="${SRC}$@" 

  if [ -f $LOC ]
    then
      cd $LOC
  else
    mkdir -p $LOC && cd $LOC
  fi
}
