#!/bin/bash

set -e

# 确定发行版类型
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Unsupported OS"
    exit 1
fi

# 更换为清华大学镜像源
change_to_tuna_mirrors() {
    case $OS in
        ubuntu | debian)
            sed -i 's|http://.*archive.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list
            sed -i 's|http://security.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list
            apt update
            ;;
        centos)
            sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-*.repo
            sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=https://mirrors.tuna.tsinghua.edu.cn|g' /etc/yum.repos.d/CentOS-*.repo
            yum makecache
            ;;
        rocky)
            sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/Rocky-*.repo
            sed -i 's|^#baseurl=http://dl.rockylinux.org|baseurl=https://mirrors.tuna.tsinghua.edu.cn|g' /etc/yum.repos.d/Rocky-*.repo
            yum makecache
            ;;
        fedora)
            sed -i 's|^metalink=|#metalink=|g' /etc/yum.repos.d/fedora*.repo
            sed -i 's|^#baseurl=https://download.example/pub/fedora|baseurl=https://mirrors.tuna.tsinghua.edu.cn/fedora|g' /etc/yum.repos.d/fedora*.repo
            yum makecache
            ;;
        arch)
            sed -i 's|^Server = .*|Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch|g' /etc/pacman.d/mirrorlist
            pacman -Sy
            ;;
        *)
            echo "Unsupported OS"
            exit 1
            ;;
    esac
}

# 安装必要的依赖项
install_dependencies() {
    case $OS in
        ubuntu | debian)
            apt install -y \
                autoconf \
                bison \
                build-essential \
                curl \
                libxml2-dev \
                libsqlite3-dev \
                libonig-dev \
                libcurl4-openssl-dev \
                libjpeg-dev \
                libpng-dev \
                libwebp-dev \
                libxpm-dev \
                libfreetype6-dev \
                libzip-dev \
                libssl-dev \
                libreadline-dev \
                zlib1g-dev \
                git \
                re2c \
                pkg-config
            ;;
        centos | rocky | fedora)
            yum groupinstall -y "Development Tools"
            yum install -y \
                autoconf \
                bison \
                curl \
                libxml2-devel \
                sqlite-devel \
                oniguruma-devel \
                libcurl-devel \
                libjpeg-devel \
                libpng-devel \
                libwebp-devel \
                freetype-devel \
                libzip-devel \
                openssl-devel \
                readline-devel \
                zlib-devel \
                git \
                re2c \
                pkgconfig
            ;;
        arch)
            pacman -S --noconfirm \
                base-devel \
                autoconf \
                bison \
                curl \
                libxml2 \
                sqlite \
                oniguruma \
                libcurl-compat \
                libjpeg \
                libpng \
                libwebp \
                freetype2 \
                libzip \
                openssl \
                readline \
                zlib \
                git \
                re2c \
                pkgconf
            ;;
        *)
            echo "Unsupported OS"
            exit 1
            ;;
    esac
}

# 拉取 PHP 源代码并编译安装
install_php() {
    git clone https://github.com/php/php-src.git --branch PHP-8.2 --depth=1
    cd php-src
    ./buildconf --force
    ./configure \
        --prefix=/usr/local/php \
        --with-config-file-path=/usr/local/php/etc \
        --enable-mbstring \
        --enable-intl \
        --enable-pcntl \
        --enable-soap \
        --enable-zip \
        --with-curl \
        --with-openssl \
        --with-zlib \
        --with-readline \
        --with-pear \
        --with-jpeg \
        --with-webp \
        --with-freetype
    make -j$(nproc)
    make install
}

# 安装 PHP 扩展
install_extensions() {
    /usr/local/php/bin/pecl channel-update pecl.php.net
    /usr/local/php/bin/pecl install redis
    /usr/local/php/bin/pecl install swoole
    /usr/local/php/bin/pecl install xdebug

cat <<EOL | tee /usr/local/php/etc/php.ini
extension=redis.so
extension=swoole.so
zend_extension=xdebug.so

[xdebug]
xdebug.mode=debug
xdebug.start_with_request=yes
EOL
}

# 设置环境变量
setup_environment() {
    echo 'export PATH="/usr/local/php/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
}

main() {
    change_to_tuna_mirrors
    install_dependencies
    install_php
    install_extensions
    setup_environment
    echo "PHP 8.2 and extensions installed successfully."
}

main
