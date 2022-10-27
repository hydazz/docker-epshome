FROM ghcr.io/linuxserver/baseimage-ubuntu:jammy

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="ESPHome version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="hydaz"

# environment settings
ENV \
	PIPFLAGS="--no-cache-dir" \
	PYTHONPATH="${PYTHONPATH}:/pip-packages" \
	PLATFORMIO_GLOBALLIB_DIR=/piolibs

RUN set -xe && \
	echo "**** install runtime packages ****" && \
	apt-get update && \
	apt-get install --no-install-recommends -y \
		iputils-ping \
		openssh-client \
		python3-pip \
		python3 && \
	pip install --no-cache-dir --upgrade \
		cython \
		pip \
		reedsolo \
		setuptools \
		wheel && \
	echo "**** install esphome ****" && \
	mkdir -p \
		/tmp/esphome \
		/piolibs && \
	if [ -z ${VERSION} ]; then \
		VERSION=$(curl -sL https://api.github.com/repos/esphome/esphome/releases/latest | \
			jq -r '.tag_name'); \
	fi && \
	curl -o \
		/tmp/esphome.tar.gz -L \
		"https://github.com/esphome/esphome/archive/${VERSION}.tar.gz" && \
	tar xf \
		/tmp/esphome.tar.gz -C \
		/tmp/esphome --strip-components=1 && \
	cd /tmp/esphome && \
	pip install ${PIPFLAGS} \
		-r requirements.txt \
		-r requirements_optional.txt && \
	python3 docker/platformio_install_deps.py platformio.ini && \
	pip install ${PIPFLAGS} \
		esphome=="${VERSION}" && \
	echo "**** cleanup ****" && \
	for cleanfiles in *.pyc *.pyo; \
  		do \
  		find /usr/local/lib/python3.* -iname "${cleanfiles}" -exec rm -f '{}' + ; \
	done && \
	apt-get clean && \
	rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

# environment settings
ENV HOME="/config/"

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 6052
VOLUME /config
