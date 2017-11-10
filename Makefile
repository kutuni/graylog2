clean:
	docker images -q --filter "dangling=true" | xargs -r docker rmi ;\
	docker rm graylog2-mongo graylog2-elastic graylog2

export:
	docker save elasticsearch:5 | gzip > /opt/dockerimages/elasticsearch.tar.gz ;\
        docker save  mongo:3 | gzip > /opt/dockerimages/mongo-3.tar.gz ;\
        docker save  graylog/graylog:2.3.1-1 | gzip > /opt/dockerimages/graylog2-3-1.tar.gz

import:
	gunzip -c elasticsearch.tar.gz | docker load ;\
        gunzip -c mongo-3.tar.gz | docker load ;\
        gunzip -c graylog2-3-1.tar.gz | docker load

stop:
	docker stop graylog2-mongo graylog2-elastic graylog2

start:
	docker run --name graylog2-mongo \
	    --restart always \
	    -v $(HOME)/graylog2/mongodb:/data/db \
	    -d mongo:3 ;\
    docker run --name graylog2-elastic \
        -p 8200:9200 \
        -p 8300:9300 \
        -v $(HOME)/graylog/elastic:/usr/share/elasticsearch/data \
        -d elasticsearch:5 elasticsearch \
        -E cluster.name="graylog" ;\
    docker run --name graylog2 --link graylog2-mongo:mongo --link graylog2-elastic:elasticsearch \
        -p 9000:9000 \
        -p 12201:12201/udp \
        -p 514:514 \
        -e GRAYLOG_SERVER_JAVA_OPTS="-Duser.timezone=GMT+3" \
        -e GRAYLOG_WEB_ENDPOINT_URI="http://0.0.0.0:9000/api" \
        -e GRAYLOG_REST_LISTEN_URI="http://0.0.0.0:9000/api" \
        -e GRAYLOG_ROOT_TIMEZONE="Etc/GMT-3" \
        -e GRAYLOG_ELASTICSEARCH_HOSTS=http://elasticsearch:9200 \
        --restart always \
        -d graylog2/server:2.4.0-beta.2-1

test:
	echo -e '{"version":"1.1","host":"localhst", "timestamp":1506930716,"short_message":"Auto ftpTree create", "level":6 }\0' | nc -w 1 localhost 12201
