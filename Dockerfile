FROM php:7.4-fpm

# set the environment variables
ENV EVENTS noninteractive
ENV TERM xterm

USER root

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    unzip \
    git \
    curl \
    nano \
    git \
    screen \
    net-tools \
    mariadb-client \
    sudo 

RUN docker-php-ext-install mysqli && \
    docker-php-ext-install pdo_mysql

# install generic services
RUN apt-get -y install openssh-server

# configure root user
RUN usermod --password "`openssl passwd root`" root
RUN sed -i -e 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

COPY ./.docker/settings/cli.php.ini    /etc/php/7.4/cli/php.ini
COPY ./.docker/settings/fpm.php.ini    /etc/php/7.4/fpm/php.ini

# Configure PHP-FPM
COPY ./.docker/settings/fpm.www.conf /etc/php7/php-fpm.d/www.conf
#COPY ./.docker/settings/php.ini /etc/php7/conf.d/custom.ini

# Install Node
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs

# Setup document root
RUN mkdir -p /var/www
#RUN php -v

# Add application
WORKDIR /var/www

# Install composer from the official image
COPY --from=composer /usr/bin/composer /usr/bin/composer


# Add user for laravel application
RUN groupadd -g 1000 www
RUN useradd -u 1000 -ms /bin/bash -g www www

#  Add new user docker to sudo group
RUN adduser www sudo

# Ensure sudo group users are not 
# asked for a password when using 
# sudo command by ammending sudoers file
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> \
/etc/sudoers

# Copy existing application directory contents
COPY . /var/www

# Copy existing application directory permissions
COPY --chown=www:www . /var/www

# install the runables
COPY ./.docker/runables/deploy.sh /opt/deploy.sh
COPY ./.docker/runables/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /opt/deploy.sh

# start command
ENTRYPOINT ["docker-entrypoint.sh"]

# Change current user to www
USER www

# Expose port 9000 and start php-fpm server
EXPOSE 9000
CMD ["php-fpm"]
