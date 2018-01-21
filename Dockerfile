FROM ubuntu:16.04

# Locales
ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8
RUN apt-get update && apt-get install -y locales && locale-gen en_US.UTF-8

# Colors and italics for tmux
COPY xterm-256color-italic.terminfo /root
RUN tic /root/xterm-256color-italic.terminfo
ENV TERM=xterm-256color-italic

# Common packages
RUN apt-get update && apt-get install -y \
      build-essential \
      curl \
      git  \
      iputils-ping \
      jq \
      libncurses5-dev \
      libevent-dev \
      net-tools \
      netcat-openbsd \
      rubygems \
      ruby-dev \
      silversearcher-ag \
      socat \
      software-properties-common \
      tmux \
      tzdata \
      wget \
      zsh 
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true
RUN chsh -s /usr/bin/zsh
COPY andrlik.zsh-theme /root/.oh-my-zsh/themes/andrlik.zsh-theme
COPY zshrc /root/.zshrc

# Install docker
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D &&\
      echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list &&\
      apt-get install -y apt-transport-https &&\
      apt-get update &&\
      apt-get install -y docker-engine
RUN  curl -o /usr/local/bin/docker-compose -L "https://github.com/docker/compose/releases/download/1.18.0/docker-compose-$(uname -s)-$(uname -m)" &&\
      chmod +x /usr/local/bin/docker-compose

# Install go
RUN add-apt-repository ppa:longsleep/golang-backports
RUN apt-get update
RUN apt-get install -y golang-1.8-go
RUN ln -s /usr/lib/go-1.8/bin/go /usr/bin/go


# Install neovim
RUN apt-get install -y \
      autoconf \
      automake \
      cmake \
      g++ \
      libtool \
      libtool-bin \
      pkg-config \
      python3 \
      python3-pip \
      unzip
RUN pip3 install --upgrade pip &&\ 
      pip3 install neovim yapf jedi mistune psutil setproctitle virtualenvwrapper yolk3k
RUN ln -s /usr/bin/python3 /usr/bin/python
WORKDIR /usr/local/src
RUN git clone --depth 1 https://github.com/neovim/neovim.git
WORKDIR /usr/local/src/neovim
RUN git fetch --depth 1 origin tag v0.2.0
RUN git reset --hard v0.2.0
RUN make CMAKE_BUILD_TYPE=Release
RUN make install
RUN rm -rf /usr/local/src/neovim
RUN mkdir -p /root/.config/nvim
WORKDIR /tmp
RUN mkdir -p /root/.random
RUN curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh
RUN sh ./installer.sh /root/.random || echo "Failed."

# Install tmux
WORKDIR /usr/local/src
RUN wget https://github.com/tmux/tmux/releases/download/2.6/tmux-2.6.tar.gz
RUN tar xzvf tmux-2.6.tar.gz
WORKDIR /usr/local/src/tmux-2.6
RUN ./configure
RUN make 
RUN make install
RUN rm -rf /usr/local/src/tmux*

# tmux plugins
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
COPY tmux.conf /root/.tmux.conf
RUN ~/.tmux/plugins/tpm/bin/install_plugins

# vim plugins
COPY init.vim /root/.config/nvim/init.vim 
RUN nvim +UpdateRemotePlugins +qall
RUN echo "export VAULT_ADDR=http://vaultserver:8200" >> /root/.zshrc
RUN wget https://releases.hashicorp.com/vault/0.8.3/vault_0.8.3_linux_amd64.zip && unzip vault_0.8.3_linux_amd64.zip && cp vault /usr/bin/ 

# install node

WORKDIR /usr/local/src
RUN git clone --depth 1 https://github.com/tj/n.git
WORKDIR /usr/local/src/n
RUN make install
RUN n latest

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y yarn

# install cypress dependencies
RUN apt-get install -y xvfb libgtk2.0-0 libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2