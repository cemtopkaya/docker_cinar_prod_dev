FROM ubuntu:xenial AS cnrbox

RUN echo "deb [trusted=yes] http://192.168.13.47/debs/ amd64/" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get -y install \
        python \
        libncurses5-dev \
        libxml2-dev \
        libreadline-dev \
        libssl-dev \
        libsasl2-dev \
        uuid-dev  \
        dpdk \
        dkms \
        nettle-dev \
        libicu55 --allow-unauthenticated \
        boost-all  --allow-unauthenticated \
        boost-all-dev --allow-unauthenticated \
        certificate  --allow-unauthenticated \
        cinarloggersink  --allow-unauthenticated \
        cpp-jwt  --allow-unauthenticated \
        g3log  --allow-unauthenticated \
        libevent  --allow-unauthenticated \
        libnghttp2-asio  --allow-unauthenticated \
        mongo-c-driver  --allow-unauthenticated \
        mongo-cxx-driver  --allow-unauthenticated \
        nlohmann-json  --allow-unauthenticated \
        libprometheuscpp  --allow-unauthenticated
   
FROM ubuntu:xenial AS cnrnrf
WORKDIR  "/opt/cinar/"
RUN echo "deb [trusted=yes] http://192.168.13.47/debs/ amd64/" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get -y install \
        cinarcodegenerator --allow-unauthenticated \
        cinarframework-dbg --allow-unauthenticated \
        cinarnnrfaccesstoken.15.201906-Interworking.dbg --allow-unauthenticated \
        cinarnnrfnfdiscovery.15.201906-Interworking.dbg --allow-unauthenticated \
        cinarnnrfnfmanagement.15.201906-Interworking.dbg --allow-unauthenticated \
        cinarnnssfnssaiavailability.15.201906-Interworking.dbg --allow-unauthenticated \
        cinarnnssfnsselection.15.201906-Interworking.dbg --allow-unauthenticated \
        cinarnnefnorthboundassessionwithqos.15.201906-Interworking.dbg --allow-unauthenticated \
        cinarnnefnorthboundcpprovisioning.15.201906-Interworking.dbg --allow-unauthenticated \
        cinarnnefnorthbounddevicetriggering.15.201906-Interworking.dbg --allow-unauthenticated \
        cinarnnefnorthboundmonitoringevent.15.201906-Interworking.dbg --allow-unauthenticated \
        cinarnnefnorthboundpfdmanagement.15.201906-Interworking.dbg  --allow-unauthenticated \
        cinarnnefnorthboundtrafficinfluence.15.201906-Interworking.dbg  --allow-unauthenticated \
        cinarnnefpfdmanagement.15.201906-Interworking.dbg  --allow-unauthenticated
     
COPY --from=cnrbox /usr/lib /usr/lib
COPY --from=cnrbox /lib/x86_64-linux-gnu /lib/x86_64-linux-gnu

RUN  echo "/opt/cinar/lib" > /etc/ld.so.conf.d/cinar.conf && \
     /sbin/ldconfig

ENV container docker

ARG NF_PAKET_ADI=cnrnssf
ENV NF_PAKET_ACILACAK_DIZIN=paket
ENV NF_PAKET_KOPYALANACAK_DIZIN=/root

USER root 

WORKDIR /root

RUN apt update

RUN apt download $NF_PAKET_ADI

RUN export NF_PAKET_FILENAME=$(apt-cache show $NF_PAKET_ADI | grep Filename | cut -d' ' -f2 | head -1) && \
    dpkg-deb -R $NF_PAKET_FILENAME $NF_PAKET_ACILACAK_DIZIN && \
    cd $NF_PAKET_ACILACAK_DIZIN/DEBIAN && \
    echo  `awk '{gsub("systemctl (daemon-reload|start).*", "if [ ! -n $container ]; then "$0"; fi")}1' ./postinst > postinst.yeni` && \
    chmod 755 postinst.yeni && mv postinst.yeni postinst && \
    cd ../.. && dpkg-deb -b $NF_PAKET_ACILACAK_DIZIN $NF_PAKET_FILENAME && \
    cd $NF_PAKET_KOPYALANACAK_DIZIN && \
    dpkg -i $NF_PAKET_FILENAME

ENTRYPOINT ["/sbin/init"]