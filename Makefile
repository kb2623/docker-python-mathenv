D_IMGAE_NAME:=python-mathenv
D_IMGAE_VERSION:=22022021
SSL_KEY_NAME:=mykey
NB_PASSWORD:=password1234

build: $(SSL_KEY_NAME).key
	docker build \
		--build-arg SSL_KEY_NAME=$(SSL_KEY_NAME) \
		--build-arg NB_PASSWORD=$(NB_PASSWORD) \
		-t $(D_IMGAE_NAME):$(D_IMGAE_VERSION) .

run:
	docker run --rm -it -p 8080:8080 $(D_IMGAE_NAME):$(D_IMGAE_VERSION)

clean:
	docker rmi $(D_IMGAE_NAME):$(D_IMGAE_VERSION)

$(SSL_KEY_NAME).key:
	openssl req -newkey rsa:2048 -nodes -keyout $(SSL_KEY_NAME).key -x509 -out $(SSL_KEY_NAME).pem

ssl_key_clean: $(SSL_KEY_NAME).key $(SSL_KEY_NAME).pem
	rm -f $(SSL_KEY_NAME).key $(SSL_KEY_NAME).pem

