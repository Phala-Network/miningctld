#! /usr/bin/env bssh

function finish {
  if [ -n "$P1" -a -e /proc/$P1 ]
  then
    kill $P1
  fi

  if [ -n "$P2" -a -e /proc/$P2 ]
  then
    kill $P2
  fi

  wait $P1 $P2
  exit 0
}

trap finish EXIT

if [ -z $RACK_ENV ] || [ "$RACK_ENV" = "development" ]; then
  RACK_ENV="development"
fi

echo "==========================="
echo "RACK_ENV: $RACK_ENV"
echo "==========================="

if [ "$RACK_ENV" = "production" ]; then
  echo "Building proto..."
  bundle exec rake proto:build

  rm -rf /socket/*

  echo "Starting the server..."
  bundle exec falcon host &
  P1=$!
  sleep 5
  ruby daemon.rb &
  P2=$!
fi

if [ "$RACK_ENV" = "testing" ]; then
  bundle exec falcon serve \
    -b http://0.0.0.0:9292 -n 2 &
  P1=$!
  sleep 5
  ruby daemon.rb &
  P2=$!
fi

if [ "$RACK_ENV" = "development" ]; then
  bundle exec falcon serve \
    -b http://0.0.0.0:9292 -n 2 &
  P1=$!
  sleep 5
  ruby daemon.rb &
  P2=$!
fi

while :
do
  sleep 1
  if ! [ -n "$P1" -a -e /proc/$P1 ]
  then
    finish
  elif ! [ -n "$P2" -a -e /proc/$P2 ]
  then
    finish
  fi
done
