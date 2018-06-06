FROM debian:latest

ENV GIT_VERSION 2.17.1
ENV EMACS_VERSION 25.3
ENV RUBY_VERSION 2.5.1
ENV NODE_VERSION 8.9.3
ENV PYTHON_VERSION 3.6.5
ENV GLOBAL_VERSION 6.6.2

RUN apt-get update
RUN apt-get -y install aptitude build-essential python openssh-server sudo supervisor locales
RUN apt-get -y install zlib1g-dev libssl-dev libcurl4-openssl-dev gettext libreadline-dev libbz2-dev libsqlite3-dev
RUN apt-get -y install libxml2-dev re2c libtidy-dev libmariadbclient-dev libpq-dev libmcrypt-dev libpng-dev libjpeg-dev libxslt-dev bison pkg-config
RUN apt-get -y install libncurses-dev gcc g++ make wget xzip
RUN apt-get -y install vim-tiny less gnutls-bin exuberant-ctags

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
RUN chown -R docker:docker /usr/local/rbenv
RUN . /etc/profile && gem install bundler pry

WORKDIR /usr/local
RUN git clone https://github.com/riywo/ndenv.git
RUN git clone https://github.com/riywo/node-build.git ndenv/plugins/node-build
ADD ndenv/ndenv.sh /etc/profile.d/ndenv.sh
RUN . /etc/profile && ndenv install -s ${NODE_VERSION} && ndenv rehash && ndenv global ${NODE_VERSION}
RUN chown -R docker:docker /usr/local/ndenv

WORKDIR /usr/local
RUN git clone https://github.com/yyuu/pyenv.git
ADD pyenv/pyenv.sh /etc/profile.d/pyenv.sh
RUN . /etc/profile && pyenv install -s ${PYTHON_VERSION} && pyenv rehash && pyenv global ${PYTHON_VERSION}
RUN chown -R docker:docker /usr/local/pyenv
RUN . /etc/profile && pip install pygments

WORKDIR /usr/src
RUN wget https://ftp.gnu.org/pub/gnu/global/global-${GLOBAL_VERSION}.tar.gz
RUN tar xzf global-${GLOBAL_VERSION}.tar.gz && cd global-${GLOBAL_VERSION} && ./configure && make install

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
RUN chown -R docker:docker /usr/local/phpenv

RUN mkdir /home/docker/bin
RUN chown docker:docker /home/docker/bin
RUN cd /home/docker/bin ; curl -O https://getcomposer.org/composer.phar
RUN chmod 755 /home/docker/bin/composer.phar
RUN ln -s /home/docker/bin/composer.phar /home/docker/bin/composer

ADD supervisor/supervisord.conf /etc/supervisor/supervisord.conf
ADD supervisor/sshd.conf /etc/supervisor/conf.d/sshd.conf

RUN echo 'export PATH=$PATH:$HOME/bin:$HOME/.composer/vendor/bin' >> /home/docker/.bashrc
RUN echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
RUN locale-gen

EXPOSE 22

RUN apt clean

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
