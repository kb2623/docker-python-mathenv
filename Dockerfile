FROM debian:bullseye-slim

ARG SSL_KEY_NAME=mykey
ARG USER=jupyter
ARG USER_HOME=/home/$(USER)
ARG NB_PASSWORD=password1234

# Install base packages
RUN apt update \
 && apt install --no-install-recommends -y bash git gcc g++ gdb make neovim python-is-python3 pipenv fonts-firacode nodejs npm

# Create user
RUN useradd -m -d $(USER_HOME)/ -s /bin/bash $(USER)

SHELL ["/bin/bash", "-c"]
USER $(USER)
WORKDIR $(USER_HOME)

# Required packages for python
ADD Pipfile $(USER_HOME)/Pipfile
# Install packages
RUN pipenv install

# Jupyter notebook settings
ADD jupyter_notebook_config.py $(USER_HOME)/.jupyter/jupyter_notebook_config.py
# Server key
ADD $(SSL_KEY_NAME).pem $(USER_HOME)/.jupyter/$(SSL_KEY_NAME).pem
ADD $(SSL_KEY_NAME).key $(USER_HOME)/.jupyter/$(SSL_KEY_NAME).key
# Update configuration
RUN sed -i 's/##NB_PASSWORD##/'$(python -c "import os; from notebook.auth import passwd; passwd(os.getenv('NB_PASSWORD'))")'/g' $(USER_HOME)/.jupyter/jupyter_notebook_config.py
RUN sed -i 's/##USER_HOME##/'$(USER_HOME)'/g' $(USER_HOME)/.jupyter/jupyter_notebook_config.py
RUN sed -i 's/##SSL_KEY_NAME##/'$(SSL_KEY_NAME)'/g' $(USER_HOME)/.jupyter/jupyter_notebook_config.py

EXPOSE 8080
ENTRYPOINT ["bash"]
