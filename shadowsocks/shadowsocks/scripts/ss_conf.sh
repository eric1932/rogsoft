#!/bin/sh
export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'

backup_conf(){
	rm -rf /tmp/files
	rm -rf /koolshare/webs/files
	mkdir -p /tmp/files
	ln -sf ln -sf /tmp/files /koolshare/webs/files
	dbus list ss | grep -v "enable" | grep -v "ssid_" | sed 's/=/=\"/' | sed 's/$/\"/g'|sed 's/^/dbus set /' | sed '1 isource /koolshare/scripts/base.sh' |sed '1 i#!/bin/sh' > $KSROOT/webs/files/ssconf_backup.sh
}

backup_tar(){
	rm -rf /tmp/files
	rm -rf /koolshare/webs/files
	mkdir -p /tmp/files
	ln -sf ln -sf /tmp/files /koolshare/webs/files
	echo_date "开始打包..."
	cd /tmp
	mkdir shadowsocks
	mkdir shadowsocks/bin
	mkdir shadowsocks/scripts
	mkdir shadowsocks/webs
	mkdir shadowsocks/res
	echo_date "请等待一会儿..."
	TARGET_FOLDER=/tmp/shadowsocks
	cp /koolshare/scripts/ss_install.sh $TARGET_FOLDER/install.sh
	cp /koolshare/scripts/uninstall_shadowsocks.sh $TARGET_FOLDER/uninstall.sh
	cp /koolshare/scripts/ss_* $TARGET_FOLDER/scripts/
	cp /koolshare/bin/ss-local $TARGET_FOLDER/bin/
	cp /koolshare/bin/ss-redir $TARGET_FOLDER/bin/
	cp /koolshare/bin/ss-tunnel $TARGET_FOLDER/bin/
	cp /koolshare/bin/obfs-local $TARGET_FOLDER/bin/
	cp /koolshare/bin/rss-local $TARGET_FOLDER/bin/
	cp /koolshare/bin/rss-redir $TARGET_FOLDER/bin/
	cp /koolshare/bin/koolgame $TARGET_FOLDER/bin/
	cp /koolshare/bin/pdu $TARGET_FOLDER/bin/
	cp /koolshare/bin/dns2socks $TARGET_FOLDER/bin/
	#cp /koolshare/bin/dnscrypt-proxy $TARGET_FOLDER/bin/
	#cp /koolshare/bin/Pcap_DNSProxy $TARGET_FOLDER/bin/
	cp /koolshare/bin/chinadns $TARGET_FOLDER/bin/
	cp /koolshare/bin/resolveip $TARGET_FOLDER/bin/
	cp /koolshare/bin/haproxy $TARGET_FOLDER/bin/
	cp /koolshare/bin/client_linux_arm7 $TARGET_FOLDER/bin/
	cp /koolshare/bin/speeder* $TARGET_FOLDER/bin/
	cp /koolshare/bin/udp2raw $TARGET_FOLDER/bin/
	cp /koolshare/bin/jq $TARGET_FOLDER/bin/
	cp /koolshare/webs/Module_shadowsocks*.asp $TARGET_FOLDER/webs/
	cp /koolshare/res/icon-shadowsocks.png $TARGET_FOLDER/res/
	cp /koolshare/res/ss-menu.js $TARGET_FOLDER/res/
	cp /koolshare/res/all.png $TARGET_FOLDER/res/
	cp /koolshare/res/gfw.png $TARGET_FOLDER/res/
	cp /koolshare/res/chn.png $TARGET_FOLDER/res/
	cp /koolshare/res/game.png $TARGET_FOLDER/res/
	cp /koolshare/res/shadowsocks.css $TARGET_FOLDER/res/
	cp -r /koolshare/ss $TARGET_FOLDER/
	rm -rf $TARGET_FOLDER/ss/*.json
	tar -czv -f /tmp/shadowsocks.tar.gz shadowsocks/
	rm -rf $TARGET_FOLDER
	mv /tmp/shadowsocks.tar.gz /tmp/files
	echo_date "打包完毕！"
}

remove_now(){
	echo_date 开始清理shadowsocks配置...
	confs=`dbus list ss | cut -d "=" -f 1 | grep -v "version" | grep -v "ssserver_" | grep -v "ssid_" |grep -v "ss_basic_state_china" | grep -v "ss_basic_state_foreign"`
	for conf in $confs
	do
		echo_date 移除$conf
		dbus remove $conf
	done
	echo_date 设置一些默认参数...
	dbus set ss_basic_enable="0"
	dbus set ss_basic_version_local=`cat /koolshare/ss/version` 
	echo_date 尝试关闭shadowsocks...
	sh /koolshare/ss/ssconfig.sh stop
}

remove_silent(){
	echo_date 先清除已有的参数...
	confs=`dbus list ss | cut -d "=" -f 1 | grep -v "version" | grep -v "ssserver_" | grep -v "ssid_" |grep -v "ss_basic_state_china" | grep -v "ss_basic_state_foreign"`
	for conf in $confs
	do
		echo_date 移除$conf
		dbus remove $conf
	done
	echo_date 设置一些默认参数...
	dbus set ss_basic_version_local=`cat /koolshare/ss/version` 
	echo_date "--------------------"
}

restore_sh(){
	echo_date 检测到ss备份文件...
	echo_date 开始恢复配置...
	chmod +x /tmp/upload/ssconf_backup.sh
	sh /tmp/upload/ssconf_backup.sh
	dbus set ss_basic_enable="0"
	dbus set ss_basic_version_local=`cat /koolshare/ss/version` 
	echo_date 配置恢复成功！
}

restore_json(){
	echo_date 检测到ss json配置文件...
	ss_formate=`echo $confs|grep "obfs"`
	if [ -z "$ss_formate" ];then

		servers=$(cat /tmp/ssconf_backup.json |grep -w server|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2)
		ports=`cat /tmp/ssconf_backup.json |grep -w server_port|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		passwords=`cat /tmp/ssconf_backup.json |grep -w password|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		methods=`cat /tmp/ssconf_backup.json |grep -w method|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		remarks=`cat /tmp/ssconf_backup.json |grep -w remarks|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		
		# flush previous test value in the table
		echo_date 尝试移除旧的webtest结果...
		webtest=`dbus list ssconf_basic_webtest_ | sort -n -t "_" -k 4|cut -d "=" -f 1`
			for line in $webtest
			do
				dbus remove "$line"
			done
		
		# flush previous ping value in the table
		echo_date 尝试移除旧的ping测试结果...
		pings=`dbus list ssconf_basic_ping | sort -n -t "_" -k 4|cut -d "=" -f 1`
			for ping in $pings
			do
				dbus remove "$ping"
			done
		
		echo_date 开始导入配置...导入json配置不会覆盖原有配置.
		last_node=`dbus list ssconf_basic_server|cut -d "=" -f 1| cut -d "_" -f 4| sort -nr|head -n 1`
		if [ ! -z "$last_node" ];then
		k=`expr $last_node + 1`
		else
		k=1
		fi
		min=1
		max=`cat /tmp/ssconf_backup.json |grep -wc server`
		while [ $min -le $max ]
		do
		    echo_date "==============="
		    echo_date import node $min
		    echo_date $k
		    
		    server=`echo $servers | awk "{print $"$min"}"`
			port=`echo $ports | awk "{print $"$min"}"`
			password=`echo $passwords | awk "{print $"$min"}"`
			method=`echo $methods | awk "{print $"$min"}"`
			remark=`echo $remarks | awk "{print $"$min"}"`
			
			echo_date $server
			echo_date $port
			echo_date $password
			echo_date $method
			echo_date $remark
			
			dbus set ssconf_basic_server_"$k"="$server"
			dbus set ssconf_basic_port_"$k"="$port"
			dbus set ssconf_basic_password_"$k"=`echo "$password" | base64_encode`
			dbus set ssconf_basic_method_"$k"="$method"
			dbus set ssconf_basic_name_"$k"="$remark"
			dbus set ssconf_basic_use_rss_"$k"=0
			dbus set ssconf_basic_mode_"$k"=2
		    min=`expr $min + 1`
		    k=`expr $k + 1`
		done
		echo_date 导入配置成功！
	else
		echo_date 检测到ssr json配置文件...
		servers=$(cat /tmp/ssconf_backup.json |grep -w server|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2)
		ports=`cat /tmp/ssconf_backup.json |grep -w server_port|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		passwords=`cat /tmp/ssconf_backup.json |grep -w password|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		methods=`cat /tmp/ssconf_backup.json |grep -w method|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		remarks=`cat /tmp/ssconf_backup.json |grep -w remarks|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		obfs=`cat /tmp/ssconf_backup.json |grep -w obfs|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		obfsparam=`cat /tmp/ssconf_backup.json |grep -w obfsparam|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		protocol=`cat /tmp/ssconf_backup.json |grep -w protocol|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		protocolparam=`cat /tmp/ssconf_backup.json |grep -w protocolparam|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|sed 's/protocolparam://g'`
		
		# flush previous test value in the table
		echo_date 尝试移除旧的webtest结果...
		webtest=`dbus list ssconf_basic_webtest_ | sort -n -t "_" -k 4|cut -d "=" -f 1`
			for line in $webtest
			do
				dbus remove "$line"
			done
		
		# flush previous ping value in the table
		echo_date 尝试移除旧的ping测试结果...
		pings=`dbus list ssconf_basic_ping | sort -n -t "_" -k 4|cut -d "=" -f 1`
			for ping in $pings
			do
				dbus remove "$ping"
			done
		
		echo_date 开始导入配置...导入json配置不会覆盖原有配置.
		last_node=`dbus list ssconf_basic_server|cut -d "=" -f 1| cut -d "_" -f 4| sort -nr|head -n 1`
		if [ ! -z "$last_node" ];then
		k=`expr $last_node + 1`
		else
		k=1
		fi
		min=1
		max=`cat /tmp/ssconf_backup.json |grep -wc server`
		while [ $min -le $max ]
		do
		    echo_date "==============="
		    echo_date import node $min
		    echo_date $k
		    
		    server=`echo $servers | awk "{print $"$min"}"`
			port=`echo $ports | awk "{print $"$min"}"`
			password=`echo $passwords | awk "{print $"$min"}"`
			method=`echo $methods | awk "{print $"$min"}"`
			remark=`echo $remarks | awk "{print $"$min"}"`
			obf=`echo $obfs | awk "{print $"$min"}"`
			obfspara=`echo $obfsparam | awk "{print $"$min"}"`
			protoco=`echo $protocol | awk "{print $"$min"}"`
			protocolpara=`echo $protocolparam | awk "{print $"$min"}"`
			
			echo_date $server
			echo_date $port
			echo_date $password
			echo_date $method
			echo_date $remark
			echo_date $obf
			echo_date $obfspara
			echo_date $protoco
			echo_date $protocolpara
			
			dbus set ssconf_basic_server_"$k"="$server"
			dbus set ssconf_basic_port_"$k"="$port"
			dbus set ssconf_basic_password_"$k"=`echo "$password" | base64_encode`
			dbus set ssconf_basic_method_"$k"="$method"
			dbus set ssconf_basic_name_"$k"="$remark"
			dbus set ssconf_basic_rss_obfs_"$k"="$obf"
			dbus set ssconf_basic_rss_obfs_param_"$k"="$obfspara"
			dbus set ssconf_basic_rss_protocol_"$k"="$protoco"
			dbus set ssconf_basic_rss_protocol_para_"$k"="$protocolpara"
			dbus set ssconf_basic_use_rss_"$k"=1
			dbus set ssconf_basic_mode_"$k"=2
		    min=`expr $min + 1`
		    k=`expr $k + 1`
		done
		echo_date 导入配置成功！
	fi
}

restore_now(){
	[ -f "/tmp/upload/ssconf_backup.sh" ] && restore_sh
	[ -f "/tmp/upload/ssconf_backup.json" ] && restore_json
	echo_date 一点点清理工作...
	rm -rf /tmp/ss_conf_*
	echo_date 完成！
}

case $2 in
1)
	echo " " > /tmp/upload/ss_log.txt
	backup_conf
	http_response "$1"
	;;
2)
	echo " " > /tmp/upload/ss_log.txt
	backup_tar >> /tmp/upload/ss_log.txt
	sleep 1
	http_response "$1"
	sleep 2	
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
3)
	echo " " > /tmp/upload/ss_log.txt
	http_response "$1"
	remove_now >> /tmp/upload/ss_log.txt
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
4)
	echo " " > /tmp/upload/ss_log.txt
	http_response "$1"
	remove_silent >> /tmp/upload/ss_log.txt
	restore_now >> /tmp/upload/ss_log.txt
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
esac
