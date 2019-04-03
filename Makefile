.PHONY: package dist clean
OS=$(shell uname)
PLAT=$(shell uname -m)
all: package

package: dist
	luvi dist -o httpd-$(OS)_$(PLAT)

dist:
	mkdir -p dist/docs
	cp *.lua dist
	mkdir -p dist/deps && cp -a $(LUVIT)/deps/* dist/deps
	cd dist && lit install

clean:
	rm -rf dist httpd
