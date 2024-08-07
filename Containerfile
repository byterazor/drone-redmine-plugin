FROM alpine as builder

RUN apk update && apk add --no-cache git openssl openssl-dev make alpine-sdk cmake musl-dev linux-headers

WORKDIR /src

RUN git clone  --recurse-submodules https://gitea.federationhq.de/byterazor/redmine-api-cpp.git

RUN cd redmine-api-cpp && mkdir build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release -DENABLE_TESTS=OFF && make -j 4

FROM alpine:latest

RUN apk update && apk add --no-cache tini bash ca-certificates openssl libgcc libstdc++ libcurl coreutils

COPY --from=builder /src/redmine-api-cpp/build/redmine-cli /usr/local/bin/redmine-cli

ADD plugin.sh /
RUN chmod a+x /plugin.sh


ENTRYPOINT ["/sbin/tini", "--", "/plugin.sh"]