FROM lsiodev/nano-beta:latest as binstage
FROM lsiobase/alpine:3.11

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

# Default env with insecure genesis block
ENV \
PEER_HOST=localhost \
LIVE_GENESIS_PUB=19D3D919475DEED4696B5D13018151D1AF88B2BD3BCFF048B45031C1F36D1858 \
LIVE_GENESIS_ACCOUNT=nano_18gmu6engqhgtjnppqam181o5nfhj4sdtgyhy36dan3jr9spt84rzwmktafc \
LIVE_GENESIS_WORK=820cc9d17342799c \
LIVE_GENESIS_SIG=012B814F60A97B9C40D066C3C104383C335633D74A0566E0A0C6D1DDA7BBFA4011547AA0374B6B3146F290352E5EC6C81551032583219F8A372C236DD65BA90D

RUN \
 echo "**** install packages ****" && \
 apk add --no-cache \
	curl \
	nodejs \
	openssl \
	p7zip && \
 echo "**** clean up ****" && \
 rm -rf \
	/tmp/*

# copy in files
COPY --from=binstage / /
COPY /root /

# ports and volumes
EXPOSE 7075/udp 7075/tcp 7076 7077
VOLUME /config
