FROM debian:bullseye-slim

ARG SSL_KEY_NAME=mykey
ARG USER=jupyter
ARG USER_HOME=/home/${USER}
ARG PYTHON_VERSION_MAJOR=3
ARG PYTHON_VERSION_MINOR_FIRST=8
ARG PYTHON_VERSION_MINOR_SECOND=2

ARG PYTHON_BUILD_DEPD=zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev libbz2-dev

ENV NB_PASSWORD=password1234
ENV PYTHON_VERSION=${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR_FIRST}.${PYTHON_VERSION_MINOR_SECOND}

# Build and install python
RUN apt update \
 && apt install --no-install-recommends -y bash git curl build-essential ca-certificates ${PYTHON_BUILD_DEPD} \
 && cd /opt \
 && curl -O https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz \
 && tar -xf Python-${PYTHON_VERSION}.tar.xz \
 && cd Python-${PYTHON_VERSION} \
 && ./configure --enable-optimizations \
 && make -j 4 \
 && make install \
 && update-alternatives --install /usr/bin/python python /usr/local/bin/python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR_FIRST} 0 \
 && update-alternatives --install /usr/bin/python${PYTHON_VERSION_MAJOR} python${PYTHON_VERSION_MAJOR} /usr/local/bin/python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR_FIRST} 0 \
 && update-alternatives --install /usr/bin/pip pip /usr/local/bin/pip${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR_FIRST} 0 \
 && update-alternatives --install /usr/bin/pip${PYTHON_VERSION_MAJOR} pip${PYTHON_VERSION_MAJOR} /usr/local/bin/pip${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR_FIRST} 0 \
 && apt remove -y ${PYTHON_BUILD_DEPD} \
 && rm -rf /opt/Python-${PYTHON_VERSION}

# Required packages for python
ADD rootfs/Pipfile /root/Pipfile
# Update pip, install pipenv and install packages
RUN apt install --no-install-recommends -y tmux npm neovim fonts-firacode nodejs libjs-mathjax universal-ctags openssh-client pandoc \
 && pip install --upgrade pip \
 && pip install pipenv \
 && cd /root \
 && pipenv lock -r > requirements.txt \
 && pip install -r requirements.txt

# Make skel dir
ADD rootfs/.bashrc /etc/skel/.bashrc
ADD rootfs/.tmux.conf /etc/skel/.tmux.conf
ADD rootfs/init.vim /etc/skel/.config/nvim/init.vim
RUN curl -fLo /etc/skel/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
 && git clone https://github.com/chris-marsh/pureline.git /etc/skel/.config/pureline

# Create user
RUN useradd -m -d ${USER_HOME}/ -s /bin/bash ${USER}

# Add jupyter init script
ADD rootfs/jupyter_myinit /usr/local/bin/jupyter_myinit
RUN chmod a+x /usr/local/bin/jupyter_myinit

USER ${USER}
WORKDIR ${USER_HOME}
SHELL ["/bin/bash", "-c"]

# Jupyter notebook settings
ADD --chown=${USER}:${USER} rootfs/jupyter_server_config.py ${USER_HOME}/.jupyter/jupyter_server_config.py
ADD --chown=${USER}:${USER} rootfs/jupyter_notebook_config.py ${USER_HOME}/.jupyter/jupyter_notebook_config.py
# Server key
ADD --chown=${USER}:${USER} rootfs/${SSL_KEY_NAME}.pem ${USER_HOME}/.jupyter/${SSL_KEY_NAME}.pem
ADD --chown=${USER}:${USER} rootfs/${SSL_KEY_NAME}.key ${USER_HOME}/.jupyter/${SSL_KEY_NAME}.key
# Update configuration
RUN sed -i -r "s|##USER_HOME##|${USER_HOME}|g" ${USER_HOME}/.jupyter/jupyter_server_config.py \
 && sed -i "s/##SSL_KEY_NAME##/${SSL_KEY_NAME}/g" ${USER_HOME}/.jupyter/jupyter_server_config.py

USER ${USER}
WORKDIR ${USER_HOME}
EXPOSE 8080
ENTRYPOINT ["bash", "-c"]
CMD ["jupyter_myinit"]
