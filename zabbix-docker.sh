#!/bin/bash

################################
#                              #
# Open firewall ports:         #
# TCP: 8080, 10051, 10050      #
# UDP: 162                     #
#                              #
################################

# Create directories for files and libs
mkdir -p /home/zabbix/lib /home/zabbix/grafana-storage /etc/home/zabbix/tmp

# Copy files to directory
cp ./lib/psqlodbcw.so /home/zabbix/lib

# Directories permissions
chown -R 472:472 /home/zabbix/grafana-storage
chmod 666 /etc/home/zabbix/tmp

# Create docker compose file
cat <<EOF > /home/zabbix/docker-compose.yaml
services:
  zabbix-server:
    container_name: "zabbix-server"
    image: zabbix/zabbix-server-pgsql:alpine-7.2-latest
    restart: always
    ports:
      - 10051:10051
    networks:
      - monitor-net
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - /home/zabbix/lib/psqlodbcw.so:/usr/lib/psqlodbcw.so:ro
    environment:
      ZBX_CACHESIZE: 4096M
      ZBX_HISTORYCACHESIZE: 1024M
      ZBX_HISTORYINDEXCACHESIZE: 1024M
      ZBX_TRENDCACHESIZE: 1024M
      ZBX_VALUECACHESIZE: 1024M
      DB_SERVER_HOST: "db"
      DB_PORT: 5432
      POSTGRES_USER: "zabbix"
      POSTGRES_PASSWORD: "zabbix123"
      POSTGRES_DB: "zabbix_db"
    stop_grace_period: 30s
    labels:
      com.zabbix.description: "Zabbix server with PostgreSQL database support"
      com.zabbix.company: "Zabbix LLC"
      com.zabbix.component: "zabbix-server"
      com.zabbix.dbtype: "pgsql"
      com.zabbix.os: "alpine"

  zabbix-web-nginx-pgsql:
    container_name: "zabbix-web"
    image: zabbix/zabbix-web-nginx-pgsql:alpine-7.2-latest
    restart: always
    ports:
      - 8080:8080
      - 8443:8443
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - /etc/home/zabbix/cert/:/usr/share/zabbix/conf/certs/:ro
    networks:
      - monitor-net
    environment:
      ZBX_SERVER_HOST: "zabbix-server"
      DB_SERVER_HOST: "db"
      DB_PORT: 5432
      POSTGRES_USER: "zabbix"
      POSTGRES_PASSWORD: "zabbix123"
      POSTGRES_DB: "zabbix_db"
      ZBX_MEMORYLIMIT: "1024M"
      PHP_TZ: "America/Sao_Paulo"
    depends_on:
      - zabbix-server
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/ping"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 30s
    stop_grace_period: 10s
    labels:
      com.zabbix.description: "Zabbix frontend on Nginx web-server with PostgreSQL database support"
      com.zabbix.company: "Zabbix LLC"
      com.zabbix.component: "zabbix-frontend"
      com.zabbix.webserver: "nginx"
      com.zabbix.dbtype: "pgsql"
      com.zabbix.os: "alpine"

  zabbix-db-agent:
    container_name: "zabbix-agent"
    image: zabbix/zabbix-agent:alpine-7.2-latest
    depends_on:
      - zabbix-server
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - /run/docker.sock:/var/run/docker.sock
    environment:
      ZBX_HOSTNAME: "zabbix-agent"
      ZBX_SERVER_HOST: "172.18.0.1"
      ZBX_ENABLEREMOTECOMMANDS: "1"
      #ZBX_UNSAFEUSERPARAMETERS: "1"
    ports:
      - 31999:31999
      - 10050:10050
    networks:
      - monitor-net
    stop_grace_period: 5s

  db:
    container_name: "zabbix_db"
    image: postgres:17-alpine3.21
    restart: always
    volumes:
     - zbx_db16:/var/lib/postgresql/data
    ports:
     - 5432:5432
    networks:
     - monitor-net
    environment:
     POSTGRES_USER: "zabbix"
     POSTGRES_PASSWORD: "zabbix123"
     POSTGRES_DB: "zabbix_db"

  zabbix-proxy:
    container_name: "zabbix-proxy"
    image: zabbix/zabbix-proxy-sqlite3:alpine-7.2-latest
    depends_on:
      - zabbix-server
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - /etc/home/zabbix/tmp:/tmp/zabbix:rw
    environment:
      ZBX_HOSTNAME: "zabbix-proxy"
      ZBX_SERVER_HOST: "zabbix-server"
      ZBX_ENABLEREMOTECOMMANDS: "1"
      ZBX_DB_NAME: "/tmp/zabbix/zabbix_proxy.db"
      #ZBX_ACTIVESERVERS: "zabbix-server"
      #ZBX_PROXYMODE
      #ZBX_LOGREMOTECOMMANDS=0 # Available since 3.4.0
      #ZBX_SOURCEIP=
      #ZBX_HOSTNAMEITEM=system.hostname
      #ZBX_PROXYLOCALBUFFER=0
      #ZBX_PROXYOFFLINEBUFFER=1
      #ZBX_PROXYHEARTBEATFREQUENCY=60 # Deprecated since 6.4.0
      #ZBX_CONFIGFREQUENCY=3600 # Deprecated since 6.4.0
      #ZBX_PROXYCONFIGFREQUENCY=10 # Available since 6.4.0
      #ZBX_DATASENDERFREQUENCY=1
      #ZBX_STARTPOLLERS=5
      #ZBX_STARTPREPROCESSORS=3 # Available since 4.2.0
      #ZBX_STARTIPMIPOLLERS=0
      #ZBX_STARTPOLLERSUNREACHABLE=1
      #ZBX_STARTTRAPPERS=5
      #ZBX_STARTPINGERS=1
      #ZBX_STARTDISCOVERERS=1
      #ZBX_STARTHISTORYPOLLERS=1 # Available since 5.4.0 till 6.0.0
      #ZBX_STARTHTTPPOLLERS=1
      #ZBX_STARTODBCPOLLERS=1 # Available since 6.0.0
      #ZBX_JAVAGATEWAY=zabbix-java-gateway
      #ZBX_JAVAGATEWAYPORT=10052
      #ZBX_STARTJAVAPOLLERS=0
      #ZBX_STATSALLOWEDIP= # Available since 4.0.5
      #ZBX_STARTVMWARECOLLECTORS=0
      #ZBX_VMWAREFREQUENCY=60
      #ZBX_VMWAREPERFFREQUENCY=60
      #ZBX_VMWARECACHESIZE=8M
      #ZBX_VMWARETIMEOUT=10
      #ZBX_ENABLE_SNMP_TRAPS=false
      #ZBX_LISTENIP=
      #ZBX_LISTENPORT=10051
      #ZBX_LISTENBACKLOG=
      #ZBX_HOUSEKEEPINGFREQUENCY=1
      #ZBX_CACHESIZE=8M
      #ZBX_STARTDBSYNCERS=4
      #ZBX_HISTORYCACHESIZE=16M
      #ZBX_HISTORYINDEXCACHESIZE=4M
      #ZBX_TRAPPERTIMEOUT=300
      #ZBX_UNREACHABLEPERIOD=45
      #ZBX_UNAVAILABLEDELAY=60
      #ZBX_UNREACHABLEDELAY=15
      #ZBX_LOGSLOWQUERIES=3000
      #ZBX_TLSCONNECT=unencrypted
      #ZBX_TLSACCEPT=unencrypted
      #ZBX_TLSCAFILE=
      #ZBX_TLSCA=
      #ZBX_TLSCRLFILE=
      #ZBX_TLSCRL=
      #ZBX_TLSSERVERCERTISSUER=
      #ZBX_TLSSERVERCERTSUBJECT=
      #ZBX_TLSCERTFILE=
      #ZBX_TLSCERT=
      #ZBX_TLSKEYFILE=
      #ZBX_TLSKEY=
      #ZBX_TLSPSKIDENTITY=
      #ZBX_TLSPSKFILE=
      #ZBX_TLSPSK=
      #ZBX_TLSCIPHERALL= # Available since 4.4.7
      #ZBX_TLSCIPHERALL13= # Available since 4.4.7
      #ZBX_TLSCIPHERCERT= # Available since 4.4.7
      #ZBX_TLSCIPHERCERT13= # Available since 4.4.7
      #ZBX_TLSCIPHERPSK= # Available since 4.4.7
      #ZBX_TLSCIPHERPSK13= # Available since 4.4.7
      #ZBX_WEBDRIVERURL= # Available since 7.0.0
      #ZBX_STARTBROWSERPOLLERS=1 # Available since 7.0.0
    ports:
      - 10052:10052
    networks:
      - monitor-net
    stop_grace_period: 5s

  grafana:
    container_name: "grafana"
    image: grafana/grafana-enterprise
    restart: always
    volumes:
     - /home/zabbix/grafana-storage:/var/lib/grafana
    user: "472:472"
    ports:
     - 3000:3000
    networks:
     - monitor-net
    environment:
     GF_DEFAULT_TIMEZONE: "America/Sao_Paulo"
     GF_PLUGINS_PREINSTALL: "alexanderzobnin-zabbix-app"

networks:
  monitor-net:
   driver: bridge
volumes:
  zbx_db16:
  grafana-storage: {}
EOF

# Compose docker environment
docker compose -f /home/zabbix/docker-compose.yaml up -d

# Verify docker processes
watch -n1 "docker ps"