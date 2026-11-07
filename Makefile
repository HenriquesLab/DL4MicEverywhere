build:
	pyinstaller launcher.spec

locks:
	python3 .tools/python_tools/requirements_lock.py ensure-all --repo-root .
	python3 .tools/python_tools/requirements_lock.py ensure --source docker/converter-requirements.txt --python-version 3.9 --lock docker/converter-requirements.lock.txt --profile none --repo-root .

check-locks:
	python3 .tools/python_tools/requirements_lock.py check-all --repo-root .
	python3 .tools/python_tools/requirements_lock.py check --source docker/converter-requirements.txt --python-version 3.9 --lock docker/converter-requirements.lock.txt --profile none --repo-root .

base-locks:
	python3 .tools/python_tools/base_image_lock.py --repo-root . ensure-all

refresh-base-locks:
	python3 .tools/python_tools/base_image_lock.py --repo-root . refresh-all

check-base-locks:
	python3 .tools/python_tools/base_image_lock.py --repo-root . check-all --require-platform-metadata
