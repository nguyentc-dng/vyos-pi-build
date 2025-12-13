
container:
	sudo rm -rf vyos-build
	git clone -b current --single-branch https://github.com/vyos/vyos-build
	sudo docker build --platform linux/arm64 vyos-build/docker -t vyos/vyos-build:current-arm64

img-local:
	sudo docker run --rm -t --platform linux/arm64 --privileged -v "$(shell pwd)":/vyos -v /dev:/dev --sysctl net.ipv6.conf.lo.disable_ipv6=0 --sysctl net.ipv4.conf.lo.forwarding=1 localhost/vyos/vyos-build:current-arm64 /bin/bash -c 'cd /vyos; /bin/bash -x build-image.sh'

img-registry:
	sudo docker run --rm -t --platform linux/arm64 --privileged -v "$(shell pwd)":/vyos -v /dev:/dev --sysctl net.ipv6.conf.lo.disable_ipv6=0 --sysctl net.ipv4.conf.lo.forwarding=1 vyos/vyos-build:current-arm64 /bin/bash -c 'cd /vyos; /bin/bash -x build-image.sh'
