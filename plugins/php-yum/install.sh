#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

curPath=`pwd`
rootPath=$(dirname "$curPath")
rootPath=$(dirname "$rootPath")
serverPath=$(dirname "$rootPath")

install_tmp=${rootPath}/tmp/mw_install.pl

if id www &> /dev/null ;then 
    echo "www UID is `id -u www`"
    echo "www Shell is `grep "^www:" /etc/passwd |cut -d':' -f7 `"
else
    groupadd www
	# useradd -g www -s /sbin/nologin www
	useradd -g www -s /bin/bash www
fi

action=$1
type=$2

if [ "${2}" == "" ];then
	echo '缺少安装脚本...' > $install_tmp
	exit 0
fi 

if [ ! -d $curPath/versions/$2 ];then
	echo '缺少安装脚本2...' > $install_tmp
	exit 0
fi



#获取信息和版本
# bash /www/server/mdsever-web/scripts/getos.sh
bash ${rootPath}/scripts/getos.sh
OSNAME=`cat ${rootPath}/data/osname.pl`
VERSION_ID=`cat /etc/*-release | grep VERSION_ID | awk -F = '{print $2}' | awk -F "\"" '{print $2}'`


if [ "$OSNAME" == "centos" ];then
	rpm -Uvh http://rpms.remirepo.net/enterprise/remi-release-${VERSION_ID}.rpm
fi


# rpm -Uvh http://rpms.remirepo.net/fedora/remi-release-31.rpm
if [ "$OSNAME" == "fedora" ];then
	rpm -Uvh http://rpms.remirepo.net/fedora/remi-release-${VERSION_ID}.rpm
fi



if [ "${action}" == "uninstall" ] && [ -d ${serverPath}/php-yum/${type} ];then
	#初始化 
	cd ${rootPath} && python3 ${rootPath}/plugins/php-yum/index.py stop ${type}
	cd ${rootPath} && python3 ${rootPath}/plugins/php-yum/index.py initd_uninstall ${type}
fi

cd ${curPath} && sh -x $curPath/versions/$2/install.sh $1

if [ "${action}" == "install" ] && [ -d ${serverPath}/php-yum/${type} ];then
	# 安装通用扩展
	echo "install PHP-YUM[${PHP_VER}] extend start"
	cd ${rootPath}/plugins/php-yum/versions && bash common.sh ${PHP_VER} install gd
	cd ${rootPath}/plugins/php-yum/versions && bash common.sh ${PHP_VER} install iconv
	cd ${rootPath}/plugins/php-yum/versions && bash common.sh ${PHP_VER} install exif
	cd ${rootPath}/plugins/php-yum/versions && bash common.sh ${PHP_VER} install intl
	cd ${rootPath}/plugins/php-yum/versions && bash common.sh ${PHP_VER} install mcrypt
	cd ${rootPath}/plugins/php-yum/versions && bash common.sh ${PHP_VER} install openssl
	cd ${rootPath}/plugins/php-yum/versions && bash common.sh ${PHP_VER} install gettext
	echo "install PHP-YUM[${PHP_VER}] extend end"

	#初始化 
	cd ${rootPath} && python3 ${rootPath}/plugins/php-yum/index.py start ${type}
	cd ${rootPath} && python3 ${rootPath}/plugins/php-yum/index.py initd_install ${type}
fi


