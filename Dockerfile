# buildtime stage
FROM lsiobase/alpine:3.11 as builder

ARG NANO_RELEASE
ARG THREADS=2

SHELL ["/bin/bash", "-c"]
RUN \
 echo "**** install build packages ****" && \
 apk add \
	cmake \
	curl \
	g++ \
	gcc \
	git \
	grep \
	jq \
	linux-headers \
	make \
	openssl \
	patch \
	wget
RUN \
 echo "**** grabbing source ****" && \
 if [ -z ${NANO_RELEASE+x} ]; then \
	NANO_RELEASE=$(curl -sL "https://api.github.com/repos/nanocurrency/nano-node/tags" \
	| jq -r '.[].name' \
	| grep -Po "V(\d+\.)+\d+[A-Z][A-Z].*" | head -n1); \
 fi && \
 git clone https://github.com/nanocurrency/nano-node.git /tmp/src && \
 cd /tmp/src && \
 git checkout ${NANO_RELEASE} && \
 git submodule update --init --recursive && \
 echo ${NANO_RELEASE} > /release
RUN \
 echo "**** building boost ****" && \
 cd /tmp/src && \
 /bin/bash util/build_prep/bootstrap_boost.sh -m -B 1.70 && \
 mkdir /tmp/build
COPY /buildroot /
RUN \
 echo "**** patching and compiling node software ****" && \
 patch /tmp/src/nano/secure/common.cpp < /common.patch.beta && \
 echo "" > /tmp/src/rep_weights_live.bin && \
 echo "" > /tmp/src/rep_weights_beta.bin && \
 cd /tmp/build && \
 cmake /tmp/src \
	-DCI_BUILD=OFF \
	-DBOOST_ROOT=/usr/local/boost \
	-DACTIVE_NETWORK=nano_live_network \
	-DNANO_POW_SERVER=OFF && \
 make nano_node -j ${THREADS}
RUN \
 echo "**** organizing software ****" && \
 mkdir -p \
	/buildout/usr/bin \
	/buildout/etc && \
 mv \
	/tmp/build/nano_node \
	/buildout/usr/bin/ && \
 mv /tmp/src/api /buildout/usr/bin/api || : && \
 echo live > /buildout/etc/nano-network

# add local script
COPY /root /buildout/

# runtime stage
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

COPY --from=builder /buildout /

# ports and volumes
EXPOSE 7075/udp 7075/tcp 7076 7077
VOLUME /config
