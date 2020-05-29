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
	linux-headers \
	make \
	openssl \
	patch \
	wget
RUN \
 echo "**** grabbing source ****" && \
 if [ -z ${NANO_RELEASE+x} ]; then \
	NANO_RELEASE=$(curl -sL 'https://hub.docker.com/v2/repositories/nanocurrency/nano-beta/tags' \
	|jq -r '.results[].name' \
	|grep -Po "V\d+\d+.*" | head -n1); \
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
 sed -i \
	-e '/preconfigured_representatives.emplace_back/d' \
	-e 's/peering-beta.nano.org/localhost/g' \
	-e 's/peering.nano.org/localhost/g' \
	/tmp/src/nano/node/nodeconfig.cpp && \
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

# binlayer
FROM scratch

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

COPY --from=builder /buildout /
