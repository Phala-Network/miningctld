FROM parity/subkey:latest

FROM ruby:2.7-slim-buster

WORKDIR /root
COPY --from=0 /usr/local/bin /usr/local/bin

RUN apt-get install apt-transport-https
# RUN sed -i 's#http://deb.debian.org#https://mirrors.163.com#g' /etc/apt/sources.list
# RUN sed -i 's#http://security.debian.org#https://mirrors.163.com#g' /etc/apt/sources.list

RUN apt-get update

RUN apt-get install -y \
    bash \
    build-essential \
    git-core \
    redis-tools \
    default-libmysqlclient-dev \
    tzdata \
    zlib1g-dev liblzma-dev libgmp-dev patch \
    protobuf-compiler \
    curl

ENV LANG C.UTF-8

# RUN gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/
# RUN bundle config mirror.https://rubygems.org https://gems.ruby-china.com/

WORKDIR /usr/src/app

COPY Gemfile .
COPY Gemfile.lock .

RUN bundle install

WORKDIR /usr/src/app/daemon
ENV PATH="/usr/local/bin:${PATH}"

CMD ["bash", "./start.sh"]
