DOCKER_IMAGE := zmkfirmware/zmk-build-arm:stable
CACHE_VOLUME := zmk-charybdis-west-cache
BOARD        := nice_nano_v2

DOCKER_RUN := docker run --rm \
	-v $(CURDIR)/config:/workspace/config:ro \
	-v $(CURDIR)/build:/output \
	-v $(CACHE_VOLUME):/workspace \
	-w /workspace \
	$(DOCKER_IMAGE)

.PHONY: all pull init clean clean-cache

all: pull
	@mkdir -p build
	$(DOCKER_RUN) bash -c '\
		if [ ! -d .west ]; then \
			west init -l config && west update; \
		else \
			west update; \
		fi && \
		west zephyr-export && \
		west build -s zmk/app -p -b $(BOARD) -S nrf52840-nosd -d /tmp/build_left -- \
			-DSHIELD=charybdis_left -DZMK_CONFIG=/workspace/config -DSNIPPET_ROOT=/workspace/config && \
		cp /tmp/build_left/zephyr/zmk.uf2 /output/charybdis_left.uf2 && \
		west build -s zmk/app -p -b $(BOARD) -S nrf52840-nosd -d /tmp/build_right -- \
			-DSHIELD=charybdis_right -DZMK_CONFIG=/workspace/config -DSNIPPET_ROOT=/workspace/config && \
		cp /tmp/build_right/zephyr/zmk.uf2 /output/charybdis_right.uf2'
	@echo "==> build/charybdis_left.uf2 ready"
	@echo "==> build/charybdis_right.uf2 ready"

pull:
	docker pull $(DOCKER_IMAGE)

clean:
	rm -rf build/*.uf2

clean-cache:
	docker volume rm $(CACHE_VOLUME) 2>/dev/null || true
