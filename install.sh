#!/bin/bash
#安装CentOS 6.8 mini版之后，yum安装rpm包
#陈俊华 2017.4.15
#version 2:安装aliyun yum源，关闭 selinux iptables ipv6，修改开机启动项 /2018-01-31

#输出
echo_status(){
	echo -e "\033[34m$1 \033[0m"
}

#判断上一步执行是否成功
check_ok(){
	[ $? ] && echo -e "完成\n" || echo_status "失败，请重试" 
}


#判断这个rpm包是否安装 
set_testrpm(){
        if [ "$rpm" == "vim" ]
        then
                testrpm=$(rpm -qa |grep vim-enhanced )
        elif [ "$rpm" == "python-yaml" ]
        then
                testrpm=$(rpm -qa |grep -i pyyaml)
        else
                testrpm=$(rpm -qa |grep ^$rpm)
        fi
}

#删除/root/下的自带文件
rm -f anaconda-ks.cfg  install.log  install.log.syslog 2>/dev/null

#安装rpm包
#安装 aliyun yum 源
echo_status "安装 aliyun yum 源"
rm -f /etc/yum.repos.d/*
curl -o /etc/yum.repos.d/base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
check_ok
#需要安装的包
rpms="wget vim bind-utils bc rsync git httping jq rdate tcpdump traceroute telnet iotop ntp lrzsz screen gcc gcc-c++ unzip sysstat"
#echo -e "\033[34m安装rpm包 \033[0m"
echo_status 安装rpm包
for rpm in $rpms
do
	set_testrpm
	if [ "$testrpm" != "" ]
	then
		echo "$rpm 已安装" 
	else
		echo -n "正在安装 $rpm " 
	        yum install $rpm -y > /dev/null 2>&1
		set_testrpm
		if [ "$testrpm" != "" ] 
		then
			 echo -e "\r\t\t\t 安装成功" 
		else
			 echo -e "\r\t\t\t 安装失败" 
		fi
	fi
done

#安装pip requests,arrow
#echo -e "\033[34m安装pip requests,arrow \033[0m"
#if [ `rpm -qa |grep python-pip` ]
#then
#	pip install requests > /dev/null 2>&1 && echo "requests 安装成功" || echo "requests 安装失败"
#	pip install arrow > /dev/null 2>&1 && echo "arrow 安装成功" || echo "arrow 安装失败"
#else
#	echo "请先安装 python-pip"
#fi


#修改.bashrc
#echo -e "\033[34m修改.bashrc \033[0m"
echo_status 修改.bashrc
bashrc_file="/root/.bashrc"
#sed -i '/rm/s/^/#/g' $bashrc_file && sed -i '/cp/s/^/#/g' $bashrc_file && sed -i "/mv/a alias grep='grep --color=auto'" $bashrc_file && sed -i "/mv/a alias vi='vim'" $bashrc_file &&  echo "$file更改完成,请执行 source .bashrc" ||echo "$file更改失败"
sed -i -e "/rm/s/^/#/g;/cp/s/^/#/g;/mv/a alias grep='grep --color=auto'" -e "/mv/a alias vi='vim'" $bashrc_file &&  echo -e "${bashrc_file}更改完成,请执行 source .bashrc\n" ||echo "${bashrc_file}更改失败"


#同步时间
#echo -e "\033[34m同步时间 \033[0m"
echo_status 同步时间
/usr/sbin/ntpdate -u ntp1.cachecn.net ntp2.cachecn.net && /sbin/hwclock -w
check_ok


#关闭 selinux
echo_status 关闭selinux
selinux_file="/etc/selinux/config"
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' $selinux_file && setenforce 0
check_ok

#关闭防火墙
echo_status 关闭防火墙
service iptables stop
check_ok

#停止IPV6服务
echo_status 停止IPV6服务
service ip6tables stop
check_ok


#精简开机自启动服务，安装最小化服务的机器，初始可以只保留 crond/network/rsyslog/sshd 这4个服务
echo_status 修改chkconfig
for i in `chkconfig --list|grep 3:on |awk '{print $1}'`; do
	chkconfig --level 3 $i off
done
for cursrv in crond rsyslog sshd network; do
	chkconfig --level 3 $cursrv on
done
check_ok



