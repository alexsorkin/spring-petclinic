## Running petclinic in docker
```
	git clone https://github.com/alexsorkin/spring-petclinic.git
	cd spring-petclinic
	make prepare
	make archiva
	make docker MIRROR=archiva
	docker-compose up
```
