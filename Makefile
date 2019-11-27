.PHONY: package dist clean
OS=$(shell uname)
PLAT=$(shell uname -m)
all: package

package: dist
	luvi dist -o httpd-$(OS)_$(PLAT)

dist:
	mkdir -p dist/deps && cp -a $(LUVIT)/deps/* dist/deps
	cp main.lua init.lua package.lua dist
	cd dist && lit install

docker:
	eval $(docker-machine env)
	docker run -it --rm -v /Users/zhaozg:/Users/zhaozg \
	-e LUVIT=$(LUVIT) \
	centos:6 bash -c "cd $$(pwd) && /Users/zhaozg/work/build/luvit/Linux/luvi/luvi dist -o httpd-linux_x64"

clean:
	rm -rf dist httpd httpd-*
