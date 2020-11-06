# FROM cinar/pre as pre
# docker stop cnf || \
# docker build -t cinar/nf --build-arg NF_PAKET_ADI=cnrnssf -f Dockerfile.cinar.nf --no-cache . && \
# docker run --rm --privileged -d --name=ccc cinar/nf && \
# docker exec -it ccc bash

# "apt update" komutuyla /etc/apt/source.list dosyasında tanımlı repoların paket listesi çekilir
# ve /var/lib/apt/lists/ dizinine dosyalanır. Böylece apt install xxx_paketi dediğimizde uzak sunucuda sorgulanmaz
# Tekrar tekrar "apt update" yapmamak için önceki yansıdaki repolara göre oluşturulmuş paket listelerini çekeceğiz
# COPY --from=pre /var/lib/apt/lists/* /var/lib/apt/lists/
# Önceki yansıyı multi-stage yapısında bağlıyoruz
FROM cinar/prod:latest as prod

FROM cinar/prod:latest

ARG NF_PAKET_ADI=cnrnssf
ENV NF_PAKET_ACILACAK_DIZIN=paket
ENV NF_PAKET_KOPYALANACAK_DIZIN=/root

#--------------- Miras ile gelenler -------------------------------
# Aşağıdaki satır FROM ile miras alınan yansıdan geldiği için tekrar eklemeye gerek yok!
# RUN echo "deb [trusted=yes] http://192.168.13.47/debs/ amd64/" >> /etc/apt/sources.list && \
# 
# multi-stage ile farklı bir yansıdaki dosyalar bu yansının içine kopyalanacağı için apt update gereksiz olacak
# COPY --from=pre /var/lib/apt/lists/* /var/lib/apt/lists/
#-------------------------------------------------------------------


# RUN ls /var/lib/apt/
COPY --from=prod /var/lib/apt/* /var/lib/apt/
# RUN ls /var/lib/apt/lists/
# RUN apt update

USER root

WORKDIR /root

RUN apt show $NF_PAKET_ADI

### NF Paketini indir
RUN apt download $NF_PAKET_ADI
### NF Paketinin dosya adının txt dosyasına yaz ve sonraki RUN komutlarında yeni kaplar oluşturulduğunda dosyadan okuyarak işle
RUN apt-cache show ${NF_PAKET_ADI} | grep Filename | cut -d' ' -f2 | head -1 > nf_paket_filename.txt
### NF Paketini dizine aç, postinst dosyasını değiştir
RUN dpkg-deb -R $(cat nf_paket_filename.txt) $NF_PAKET_ACILACAK_DIZIN  && \
    cd $NF_PAKET_ACILACAK_DIZIN/DEBIAN && \
    `awk '{gsub("^systemctl (daemon-reload|start|stop).*", "if [ ! -n $container ]; then "$0"; fi")}1' ./postinst > postinst.yeni` && \
    chmod 755 postinst.yeni && mv postinst.yeni postinst && \
    cd ../..
### NF Paketin olarak yapılandır
RUN dpkg-deb -b $NF_PAKET_ACILACAK_DIZIN $(cat nf_paket_filename.txt)
### NF deb paketini kur
RUN cd $NF_PAKET_KOPYALANACAK_DIZIN && dpkg -i $(cat nf_paket_filename.txt)
### NF Paketini açtığın dizini sil
RUN rm $(cat nf_paket_filename.txt) && rm -r $NF_PAKET_KOPYALANACAK_DIZIN

# .bashrc bir şekilde gitmişse yeniden varsayılanı yaratıyoruz.
RUN if [ ! -f "/root/.bashrc" ]; then /bin/cp /etc/skel/.bashrc ~/; fi
ENTRYPOINT ["/sbin/init"]