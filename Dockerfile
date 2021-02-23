FROM debian:bullseye-slim

ARG SSL_KEY_NAME=mykey
ARG USER=jupyter
ARG USER_HOME=/home/${USER}
ARG NB_PASSWORD=password1234

# Install base packages
RUN apt update \
 && apt install --no-install-recommends -y bash git gcc g++ gdb make neovim python-is-python3 pipenv fonts-firacode nodejs npm

# Required packages for python
ADD Pipfile /root/Pipfile
# Install packages
RUN cd /root \
 && pipenv lock -r > requirements.txt \
 && pip install -r requirements.txt

# Create user
RUN useradd -m -d ${USER_HOME}/ -s /bin/bash ${USER}

USER ${USER}
WORKDIR ${USER_HOME}
SHELL ["/bin/bash", "-c"]

# Jupyter notebook settings
ADD --chown=${USER}:${USER} jupyter_notebook_config.py ${USER_HOME}/.jupyter/jupyter_notebook_config.py
# Server key
ADD --chown=${USER}:${USER} ${SSL_KEY_NAME}.pem ${USER_HOME}/.jupyter/${SSL_KEY_NAME}.pem
ADD --chown=${USER}:${USER} ${SSL_KEY_NAME}.key ${USER_HOME}/.jupyter/${SSL_KEY_NAME}.key
# Update configuration
RUN sed -i "s/##NB_PASSWORD##/$(python -c 'import sys; from IPython.lib import passwd; print(passwd(sys.argv[1]))' ${NB_PASSWORD})/g" ${USER_HOME}/.jupyter/jupyter_notebook_config.py
RUN sed -i -r "s|##USER_HOME##|${USER_HOME}|g" ${USER_HOME}/.jupyter/jupyter_notebook_config.py
RUN sed -i "s/##SSL_KEY_NAME##/${SSL_KEY_NAME}/g" ${USER_HOME}/.jupyter/jupyter_notebook_config.py

USER ${USER}
WORKDIR ${USER_HOME}
SHELL ["/bin/bash", "-c"]
EXPOSE 8080
ENTRYPOINT ["bash", "-c"]
CMD ["jupyter lab"]
