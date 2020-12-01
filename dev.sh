docker-compose -f development.docker-compose.yml build
# docker-compose -f development.docker-compose.yml up -d db redis lb
docker-compose -f development.docker-compose.yml up -d db redis
docker-compose -f development.docker-compose.yml run \
  --use-aliases \
  --service-ports \
  daemon
