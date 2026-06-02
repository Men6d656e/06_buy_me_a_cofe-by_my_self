-include .env
.PHONY: all build test anvil deploy-anvil deploy-sepolia sync-abi serve-node serve-python setup clean clean-all

setup:
	npm install

all: clean build test

clean:
	forge clean

clean-all: clean
	@echo "Removing node_modules..."
	rm -rf node_modules

build:
	forge build

test:
	forge test -vvv

anvil:
	anvil

sync-abi: build
	mkdir -p frontend/constants
	cp out/BuyMeACoffee.sol/BuyMeACoffee.json frontend/constants/BuyMeACoffee.json

deploy-anvil: sync-abi
	@echo "Deploying to Anvil..."
	forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast

deploy-sepolia: sync-abi
	@echo "Deploying to Sepolia..."
	@if [ -z "$(SEPOLIA_RPC_URL)" ]; then echo "SEPOLIA_RPC_URL is not set"; exit 1; fi
	@if [ -z "$(ETHERSCAN_API_KEY)" ]; then echo "Error: ETHERSCAN_API_KEY is not set in .env"; exit 1; fi
	forge script script/Deploy.s.sol:Deploy \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--broadcast \
		--interactives 1 \
		--verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		-vvvv

serve-node:
	./node_modules/.bin/serve frontend

serve-python:
	python3 -m http.server 8000 -d frontend
