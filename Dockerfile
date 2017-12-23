FROM debian:latest

ENV GIT_VERSION 2.15.1
ENV EMACS_VERSION 25.3
ENV RUBY_VERSION 2.4.2
ENV NODE_VERSION 8.9.3
ENV PYTHON_VERSION 3.6.4

RUN apt-get update
RUN apt-get -y install aptitude build-essential python openssh-server sudo supervisor locales
RUN apt-get -y install zlib1g-dev libssl-dev libcurl4-openssl-dev gettext libreadline-dev libbz2-dev libsqlite3-dev
RUN apt-get -y install libxml2-dev re2c libtidy-dev libmariadbclient-dev libpq-dev libmcrypt-dev libpng-dev libjpeg-dev libxslt-dev bison pkg-config
RUN apt-get -y install libncurses-dev gcc g++ make wget xzip

WORKDIR /usr/src

RUN useradd -m -d /home/docker -u 1000 -s /bin/bash docker
RUN chown -R docker:docker /home/docker
RUN mkdir /var/run/sshd
RUN echo 'docker ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN echo 'docker:docker' | chpasswd

RUN wget https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.xz
RUN tar xJf git-${GIT_VERSION}.tar.xz && cd git-${GIT_VERSION} && ./configure --without-tcltk && make install

RUN wget http://ftp.jaist.ac.jp/pub/GNU/emacs/emacs-${EMACS_VERSION}.tar.xz
RUN tar xJf emacs-${EMACS_VERSION}.tar.xz
WORKDIR /usr/src/emacs-${EMACS_VERSION}
RUN CLFAGS=-no-pie ./configure \
    --without-toolkit-scroll-bars \
    --without-xaw3d \
    --without-sound \
    --without-pop \
    --without-xpm \
    --without-tiff \
    --without-rsvg \
    --without-gconf \
    --without-gsettings \
    --without-selinux \
    --without-gpm \
    --without-makeinfo \
    --without-imagemagick \
    --without-x && make install

RUN git config --global http.sslVerify false

RUN git clone https://github.com/cask/cask.git /usr/local/cask
RUN echo 'export PATH=$PATH:/usr/local/cask/bin' > /etc/profile.d/cask.sh

WORKDIR /usr/local
RUN git clone https://github.com/sstephenson/rbenv.git
RUN git clone https://github.com/sstephenson/ruby-build.git rbenv/plugins/ruby-build
ADD rbenv/rbenv.sh /etc/profile.d/rbenv.sh
RUN . /etc/profile && rbenv install -s ${RUBY_VERSION} && rbenv rehash && rbenv global ${RUBY_VERSION}

WORKDIR /usr/local
RUN git clone https://github.com/riywo/ndenv.git
RUN git clone https://github.com/riywo/node-build.git ndenv/plugins/node-build
ADD ndenv/ndenv.sh /etc/profile.d/ndenv.sh
RUN . /etc/profile && ndenv install -s ${NODE_VERSION} && ndenv rehash && ndenv global ${NODE_VERSION}

WORKDIR /usr/local
RUN git clone https://github.com/yyuu/pyenv.git
ADD pyenv/pyenv.sh /etc/profile.d/pyenv.sh
RUN . /etc/profile && pyenv install -s ${PYTHON_VERSION} && pyenv rehash && pyenv global ${PYTHON_VERSION}

RUN apt -y install libssl1.0-dev autoconf
ENV PHP_VERSION 7.1.12
WORKDIR /tmp
RUN curl -sSL https://raw.github.com/CHH/phpenv/master/bin/phpenv-install.sh | bash
RUN mv /root/.phpenv /usr/local/phpenv
WORKDIR /usr/local
RUN git clone https://github.com/CHH/php-build.git phpenv/plugins/php-build
ADD phpenv/phpenv.sh /etc/profile.d/phpenv.sh
ADD phpenv/default_configure_options phpenv/plugins/php-build/share/php-build/default_configure_options
RUN . /etc/profile && phpenv install ${PHP_VERSION} && phpenv rehash && phpenv global ${PHP_VERSION}

ADD supervisor/supervisord.conf /etc/supervisor/supervisord.conf
ADD supervisor/sshd.conf /etc/supervisor/conf.d/sshd.conf

EXPOSE 22

RUN apt clean

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
