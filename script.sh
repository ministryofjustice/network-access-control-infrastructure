#/bin/bash
set -e -x

set_vars() {
  export RADSECPROXY_VERSION=1.9.0
}

install_packages() {
apt update
apt upgrade -y
apt-get remove docker docker-engine docker.io containerd runc -y
apt-get install ca-certificates curl gnupg lsb-release -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

  apt-get update -y

  apt-get install docker-ce docker-ce-cli containerd.io -y
  apt install -y docker-compose
}

disable_logging() {
  systemctl disable systemd-journald.service
}

fetch_certs() {
  mkdir -p ./certs
  chmod 777 ./certs
  aws s3 sync s3://mojo-development-nac-certificate-bucket/ ./certs
}

create_docker_compose() {

cat <<EOF > docker-compose.yml

version: "2.0"

services:
  radsecproxy:
    build:
      context: .
    volumes:
      - './certs:/certs'
    expose:
      - "1812/udp"
      - "2083/tcp"
      - "18120/udp"
    environment:
      EAP_PRIVATE_KEY_PASSWORD: "whatever"
      RADSEC_PRIVATE_KEY_PASSWORD: "whatever"
EOF
}

create_docker_file() {
  cat <<EOF > Dockerfile
FROM alpine:3.13.0

ENV RADSECPROXY_VERSION=1.9.0

RUN apk update && apk upgrade && \
    apk --no-cache --update add --virtual build-dependencies build-base curl gnupg && \
    apk --no-cache add tzdata nettle-dev openssl-dev openssl && \
    adduser -D -u 52000 radsecproxy && \
    curl -sLo radsecproxy-${RADSECPROXY_VERSION}.tar.gz  \
        https://github.com/radsecproxy/radsecproxy/releases/download/${RADSECPROXY_VERSION}/radsecproxy-${RADSECPROXY_VERSION}.tar.gz && \
    curl  -sLo radsecproxy-${RADSECPROXY_VERSION}.tar.gz.asc \
        https://github.com/radsecproxy/radsecproxy/releases/download/${RADSECPROXY_VERSION}/radsecproxy-${RADSECPROXY_VERSION}.tar.gz.asc && \
    curl -sS https://radsecproxy.github.io/fabian.mauchle.asc | gpg --import - && \
    gpg --verify radsecproxy-${RADSECPROXY_VERSION}.tar.gz.asc \
                 radsecproxy-${RADSECPROXY_VERSION}.tar.gz && \
    rm  radsecproxy-${RADSECPROXY_VERSION}.tar.gz.asc && \
    tar xvf radsecproxy-${RADSECPROXY_VERSION}.tar.gz && \
    rm radsecproxy-${RADSECPROXY_VERSION}.tar.gz &&\
    cd radsecproxy-${RADSECPROXY_VERSION} && \
    ./configure --prefix=/ && \
    make && \
    make check && \
    make install && \
    mkdir /var/log/radsecproxy/ /var/run/radsecproxy && \
    touch /var/log/radsecproxy/radsecproxy.log && \
    chown -R radsecproxy:radsecproxy /var/log/radsecproxy /var/run/radsecproxy && \
    apk del build-dependencies && \
    rm -rf /etc/apk/* /var/cache/apk/* /root/.gnupg

RUN touch /var/run/radsecproxy/radsecproxy.pid 

COPY ./radsecproxy.conf /etc/

EXPOSE 18120/udp

CMD openssl rehash /certs && /sbin/radsecproxy -c /etc/radsecproxy.conf -i /var/run/radsecproxy/radsecproxy.pid -f

EOF
}


start_docker_service() {
  sudo systemctl start docker.service
}

create_radsec_proxy_conf() {
  cat <<EOF > radsecproxy.conf

ListenUDP *:18120

LogLevel 5
LogDestination file:///var/log/radsecproxy/radsecproxy.log

LoopPrevention On 

tls defaultServer {
    CACertificatePath       /certs
    CertificateFile         /certs/server.pem
    CertificateKeyFile      /certs/server.pem
    CertificateKeyPassword     "whatever"
}

tls defaultClient {
    CACertificatePath       /certs
    CertificateFile         /certs/client.pem
    CertificateKeyFile      /certs/client.pem
    CertificateKeyPassword     "whatever"
}

server radius {
    type tls
    host 18.168.94.133 
    secret radsec
    tls defaultClient
    CertificateNameCheck off
    tcpkeepalive on
}

client eapol {
    type udp
    host  10.5.0.6
    secret radsec
    tls defaultServer
    CertificateNameCheck off
    tcpkeepalive on
} 

realm * {
    server radius
}

EOF

sed -i 's/ReplaceMe/${load_balancer_ip_address}/g' radsecproxy.conf

}

run_test() {
  docker-compose up --build
}

main() {
  set_vars
  install_packages
  disable_logging
  fetch_certs
  create_docker_compose
  create_docker_file
  start_docker_service
  create_radsec_proxy_conf
  run_test
}

main
