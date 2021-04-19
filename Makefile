D_IMGAE_NAME:=python-mathenv
D_IMGAE_VERSION:=22022021

SSL_KEY_NAME:=mykey

NB_PASSWORD:=password1234
PORT:=8080
CONTAINER_NAME:=python-matenv-container

build: rootfs/$(SSL_KEY_NAME).key
	docker build \
		--build-arg SSL_KEY_NAME=$(SSL_KEY_NAME) \
		-t $(D_IMGAE_NAME):$(D_IMGAE_VERSION) .

run:
	docker run --rm -it \
		-p $(PORT):8080 \
		-e NB_PASSWORD=$(NB_PASSWORD) \
		--name $(CONTAINER_NAME) \
		$(D_IMGAE_NAME):$(D_IMGAE_VERSION)

exec:
	docker exec -it $(CONTAINER_NAME) /bin/bash

clean:
	docker rmi $(D_IMGAE_NAME):$(D_IMGAE_VERSION)

rootfs/$(SSL_KEY_NAME).key:
	openssl req -newkey rsa:2048 -nodes -keyout rootfs/$(SSL_KEY_NAME).key -x509 -out rootfs/$(SSL_KEY_NAME).pem

ssl_key_clean: rootfs/$(SSL_KEY_NAME).key rootfs/$(SSL_KEY_NAME).pem
	rm -f rootfs/$(SSL_KEY_NAME).key rootfs/$(SSL_KEY_NAME).pem

