#!/bin/bash
#check_fcd_request_time_500ms_.sh v0.1
#脚本置于crontab内，每5分钟执行一次，读取当前的最新日志文件进行分析

now=`date +%Y%m%d`
nowtime=`date +%H:%M:%S`
period=`date --date='5 minutes ago'`
work_dir=/cache/logs/heka-data/$now
last_filelog=`ls -lsrt ${work_dir}/ | tail -n1 | awk '{print $10}'`
#echo ${last_filelog}
#echo $now
#echo $period
now_min=`date +%M`
#此步操作是方便取出分钟数，但不以0开头，这样方便比较大小。
MM=`echo $[1$now_min-100]`


#取当前时间的精准分钟和秒数，方便取时间段的日志。
timenew=`date +%d/%b/%G`

timenew=`LC_ALL="C" date +%d/%b/%G`
#timebefore=`date --date='5 minutes ago' +%H:%M:%S`

#echo $timebefore
#echo $nowtime

timebefore_awk=[$timenew:$timebefore
nowtime_awk=[$timenew:$nowtime

#echo ${timebefore_awk}
#echo ${nowtime_awk}


#处理当前日志前4:59及之前的逻辑，如果有20条慢回源日志，则打印相关信息;;另外，阀值为500毫秒，请自行调整。
if [ $MM -lt 5 ];then
#echo "当前时间小于或等于4"分钟
#perl -lne '/((\S+ ){10})(\"[^\"]+\" \"[^\"]+\" )(.*)/;print $1.$4' /cache/logs/heka-data/`date +%Y%m%d`/`date +%Y%m%d%H`.log | awk '{if(($20)>2000)print $0}'
    count=`grep ".*/otv.*\.ts.*" ${work_dir}/${last_filelog} | grep "FCACHE_MISS" | perl -lne '/((\S+ ){10})(\"[^\"]+\" \"[^\"]+\" )(.*)/;print $1.$4' | awk '{if(($20)>500)print $0}' | wc -l`
    if [ $count -ge 20 ];then
        echo "当前回源条数为":$count
	echo "当前回源条数大于或等于20条，请注意！"
    else 
        echo "没有问题，回源条数是正常范围之内的！"
    fi
fi

#处理当前日志5:00-59:59之前的逻辑，判断当前时间与之前的5分钟之内日志，如果有20条慢回源日志，则打印相关信息;另外，阀值为500毫秒，请自行调整。
if [ $MM -ge 5 ];then
    count=` grep ".*/otv.*\.ts.*"  ${work_dir}/${last_filelog} | grep "FCACHE_MISS" | grep -v "m3u8" | awk ' $4 >= "'${timebefore_awk}'" && $4 <= "'${nowtime_awk}'" ' | perl -lne '/((\S+ ){10})(\"[^\"]+\" \"[^\"]+\" )(.*)/;print $1.$4' | awk '{if(($20)>500)print $0}' | wc -l`
    echo "当前回源条数为":$count
    #echo ${timebefore}
    #echo ${nowtime}
    #echo ${timenew}
    #echo $count
    if [ $count -ge 20 ];then
        echo "当前回源条数大于或等于20条，请注意！"
    else 
        echo "没有问题，回源条数是正常范围之内的！"
    fi      
fi

