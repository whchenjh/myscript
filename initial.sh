#!/bin/bash
# -------------------------------------------------------------------------------
# Date:         2018.09.06
# Author:       whchenjh
# Description:  安装 CentOS mini 版之后进行初始化操作
# -------------------------------------------------------------------------------

VERSION="0.0.1"
LAST_MODIFIED="2018.09.06"
LOG_DIR="/opt/"
OS_RELEASE=`sed 's/.* \([0-9.]*\) .*/\1/' /etc/redhat-release`
YUM="mirrors.aliyun.com"

[ $UID -ne 0 ] && echo '只有root用户才可以使用本脚本.' && exit 1

# 输出信息
function f_info(){
    if [ -z "$2" ]; then
        echo -e "`date`: $1" >> $LOG_DIR/initial.log
        echo -e "$1"
        return 0
    fi
    # OK
    if [ "$1" == '0' ]; then
        # Print green message
        [ ! -z "$2" ] && echo -e "\033[32m$2\033[0m"  
        echo -e "`date`: OK:$2" >>$LOG_DIR/initial.log
        return 0
    fi
    # WARN
    if [ "$1" == 'warn' ]; then
        # Print yellow message
        echo -e "\\033[0;33m警告: $2\\033[0;39m" 
        echo -e "`date`: WARNNING: $2" >>$LOG_DIR/initial.log
        return 1
    # ERR
    else    
        # Print red message
        echo -e "\\033[0;31m错误($1):$2\\033[0;39m" 
        echo -e "`date`: ERROR($1):$2" >>$LOG_DIR/initial.log
        exit 1
    fi
} # end f_info

# 检查服务器版本
function f_ChkRelease(){
    # Release check 
    [ ! -f /etc/redhat-release ] && f_info 11 "Sorry, only support CentOS/RedHat 5.x."
    grep -q "Red Hat" /etc/redhat-release && RedHat=yes
    grep -q "CentOS"  /etc/redhat-release && CentOS=yes
    [ "$RedHat" == 'yes' ] && case $OS_RELEASE in 
        5) OS_VSN=rhel5 ;;
        5.2) OS_VSN=rhel5.2 ;;
        5.3) OS_VSN=rhel5.3 ;;
        5.4) OS_VSN=rhel5.4 ;;
        5.5) OS_VSN=rhel5.5 ;;
        5.6) OS_VSN=rhel5.6 ;;
        6)   OS_VSN=rhel6; VER6=yes ;;
        6*)  OS_VSN=rhel6; VER6=yes ;;
        *) f_info 12 "抱歉，目前不支持 RedHat $OS_RELEASE 版本的初始化." ;;
    esac
    [ "$CentOS" == "yes" ] && case $OS_RELEASE in 
        5.2) OS_VSN=cent5.2 ;;
        5.3) OS_VSN=cent5.3 ;;
        5.4) OS_VSN=cent5.4 ;;
        5.5) OS_VSN=cent5.5 ;;
        5.6) OS_VSN=cent5.6 ;;
        5.7) OS_VSN=cent5.7 ;;
        5.8) OS_VSN=cent5.8 ;;
        6)   OS_VSN=cent6; VER6=yes ;;
        6.*) OS_VSN=cent6; VER6=yes ;;
        7.*) OS_VSN=cent7; VER7=yes ;;
        *) f_info 13 "抱歉，目前不支持 CentOS $OS_RELEASE 版本的初始化." ;;
    esac
    return 0
} # end f_ChkRelease

# 删除系统安装文件
function f_DelDefultFile(){
    f_info "删除系统安装文件..."
    if [ "$OS_RELEASE" = "6.*" ]; then
        rm -f /root/anaconda-ks.cfg  /root/install.log  /root/install.log.syslog 
    elif [ "$OS_RELEASE" = "7.*" ]; then
        rm -f /root/anaconda-ks.cfg 
    fi
} # end f_DelDefultFile

# 设置yum源
function f_SetYum(){
    f_info "移动本机原有yum源..."
    repo_dir="/etc/yum.repos.d/"
    mkdir $repo_dir/bak
    mv $repo_dir/*repo $repo_dir/bak
    [ $? -eq 0 ] || f_info 21 "移动yum源失败"
    f_info "下载 YUM 源..."
    if [ "$OS_RELEASE" = "6.*" ]; then
        curl -o /etc/yum.repos.d/base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
        curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
    elif [ "$OS_RELEASE" = "7.*" ]; then
        curl -o /etc/yum.repos.d/base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
        curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
    fi
    [ $? -eq 0 ] || f_info 22 "下载yum源失败"
} # end f_SetYum

function f_InstallRpm(){
    f_info "安装rpm包..."
    yum install -y wget vim bind-utils bc rsync git httping jq rdate tcpdump traceroute \
    telnet iotop ntp lrzsz screen gcc gcc-c++ unzip sysstat man man-pages-zh-CN.noarch subversion \
    bash-completion yum-plugin-priorities net-tools |tee -a $LOG_DIR/yum-install.log
    [ $? -eq 0 ] || f_info 31 "yum install failed."
} # end f_InstallRpm

function f_OffService(){
    f_info "关闭 selinux..."
    selinux_file="/etc/selinux/config"
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' $selinux_file && setenforce 0
    if [ "$OS_VSN" = "cent6" ]; then
        f_info "关闭 iptables..."
        service iptables stop
        f_info "精简开机启动，只保留 crond/network/rsyslog/sshd 4个服务..."
        for i in `chkconfig --list|grep 3:on |awk '{print $1}'`; do
            chkconfig --level 3 $i off
        done
        for cursrv in crond rsyslog sshd network; do
            chkconfig --level 3 $cursrv on
        done
        chkconfig |grep "3:on"
    elif [ "$OS_VSN" = "cent7" ]; then
        f_info "关闭 iptables ..."
        systemctl stop firewalld.service
        systemctl disable firewalld.service
        f_info "关闭 postfix ..."
        systemctl stop postfix.service
        systemctl disable postfix.service
	f_info "关闭 chrond ..."
	systemctl stop chronyd.service
	systemctl disable chronyd.service
    fi
}

function f_InitBasic_Cent7() {
    f_info "--------- 进入basic_Cent7初始化 ----------"
    [ -x /bin/rpm ] || f_info 41 'rpm 命令未找到.'
    rpm -q yum &>/dev/null || f_info 42 'yum 命令未找到.'
    # Set default boot level
    f_info "设置系统启动级别为: 3"
    rm '/etc/systemd/system/default.target'
    ln -s '/usr/lib/systemd/system/multi-user.target' '/etc/systemd/system/default.target'
    # Set default character set
    f_info "设置默认语言\$LANG 为 en_US.UTF-8..."
    export LANG=en_US.UTF-8
    sed -i '/^LANG=/s/=.*/="en_US.UTF-8"/' /etc/locale.conf
    # Set timezone
    f_info "设置默认时区: Asia/Shanghai"
    timedatectl set-timezone Asia/Shanghai
    # del file
    f_info "删除系统安装文件..."
    rm -f /root/anaconda-ks.cfg 
    # yum
    f_info "移动本机原有yum源..."
    repo_dir="/etc/yum.repos.d"
    mkdir $repo_dir/bak
    mv $repo_dir/*repo $repo_dir/bak
    [ $? -eq 0 ] || f_info 21 "移动yum源失败"
    curl -o /etc/yum.repos.d/base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
    curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
    [ $? -eq 0 ] || f_info 22 "下载yum源失败"
}

function f_InitBasic(){
    f_info "--------- 进入basic初始化 ----------"
    [ -x /bin/rpm ] || f_info 51 'rpm 命令未找到.'
    rpm -q yum &>/dev/null || f_info 52 'yum 命令未找到.'
    f_info "设置默认语言\$LANG 为 en_US.UTF-8..."
    export LANG=en_US.UTF-8
    sed -i '/^LANG=/s/=.*/="en_US.UTF-8"/' /etc/sysconfig/i18n
    # Set timezone
    f_info "设置默认时区: Asia/Shanghai"
    echo -e "ZONE=\"Asia/Shanghai\"\nUTC=true\nARC=false" >/etc/sysconfig/clock
    /bin/cp -a /usr/share/zoneinfo/Asia/Shanghai /etc/localtime 2>/dev/null
    # del file
    f_info "删除系统安装文件..."
    rm -f /root/anaconda-ks.cfg  /root/install.log  /root/install.log.syslog 
    # yum
    f_info "移动本机原有yum源..."
    repo_dir="/etc/yum.repos.d/"
    mkdir $repo_dir/bak
    mv $repo_dir/*repo $repo_dir/bak
    [ $? -eq 0 ] || f_info 21 "移动yum源失败"
    curl -o /etc/yum.repos.d/base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
    curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
    [ $? -eq 0 ] || f_info 22 "下载yum源失败"
}

function f_ChangeBashrc(){
    f_info "修改 .bashrc ..."
    bashrc_file="/root/.bashrc"
    sed -i -e "/rm/s/^/#/g;/cp/s/^/#/g; \
    /mv/a alias grep='grep --color=auto'\nalias vi='vim'\nalias cman='man -M /usr/share/man/zh_CN'" \
    -e '$a export HISTTIMEFORMAT="%F %T "' $bashrc_file
    [ $? -eq 0 ] || f_info 61 "修改失败"
    source $bashrc_file
} # end f_ChangeBashrc


#------------------------------------------------------------------------------------------------
HELP_TEXT="
程序版本: $VERSION 最后更新: $LAST_MODIFIED 
使用方法: sh initial.bin [ 选项 ]
--basic
    安装基本标准程序包
" # end help info.

#------------------------------------------------------------------------------------------------

# pre check 
[ $# -eq 0 ] && echo "$HELP_TEXT" && exit 2
[ $# -ne 1 ] && echo '只支持单一选项.' && exit 3
f_ChkRelease
Cent7_opts_regex='(basic|hostname)'
Cent7_supported_opts=`echo "$1" | grep -E "$Cent7_opts_regex"`
if [ "$VER7" == "yes" ] && [ -z $Cent7_supported_opts ]; then
    echo "CentOS7 不支持 --$Cent7_opt_regex 以外的选项"
    exit 3
fi

#------------------------------------------------------------------------------------------------

OPTION=$1
case $OPTION in 
    --basic)    
        f_ChkRelease
        if [ "$VER7" == "yes" ]; then
            f_InitBasic_Cent7
        else
            f_InitBasic
        fi
        #f_DelDefultFile
        #f_SetYum
        f_InstallRpm
        f_OffService
        f_ChangeBashrc
    ;;
    *)
        echo "initial.sh: 选项错了 -- \"$1\""
        echo "$HELP_TEXT"
        exit 1
    ;;
esac
