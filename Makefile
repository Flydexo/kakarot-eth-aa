.PHONY: build test
cairo_files = $(shell find . -name "*.cairo")

build:
	$(MAKE) clean
	poetry run starknet-compile ./src/kethaa/deployer/deployer.cairo --cairo_path="./src" --output build/deployer.json --cairo_path ./src --abi build/deployer_abi.json
	poetry run starknet-compile ./src/kethaa/account/account.cairo --cairo_path="./src" --account_contract --output build/account.json --cairo_path ./src --abi build/account_abi.json

build-mac:
	$(MAKE) clean
	run starknet-compile ./src/kethaa/deployer/deployer.cairo --cairo_path="./src" --output build/deployer.json --cairo_path ./src --abi build/deployer_abi.json
	run starknet-compile ./src/kethaa/account/account.cairo --cairo_path="./src" --output build/account.json --cairo_path ./src --abi build/account_abi.json

setup:
	poetry install --no-root

test:
	poetry run pytest --log-cli-level=INFO --cov --cov-report=xml ./tests

test-no-log:
	poetry run pytest ./tests

run-test-log:
	poetry run pytest -k $(test) --log-cli-level=INFO -vvv --cov
	
run-test:
	poetry run pytest -k $(test)

run-test-mark-log:
	poetry run pytest -m $(mark) --log-cli-level=INFO -vvv

run-test-mark: 
	poetry run pytest -m $(mark)

format:
	poetry run cairo-format -i ${cairo_files}
	poetry run black tests/.
	poetry run isort tests/.

format-check:
	poetry run cairo-format -c ${cairo_files}
	poetry run black tests/. --check
	poetry run isort tests/. --check

clean:
	rm -rf build
	mkdir build

lint:
	amarna ./src -o lint.sarif -rules unused-imports,dead-store,unknown-decorator,unused-arguments

format-mac:
	cairo-format src/**/*.cairo -i
	black tests/.
	isort tests/.