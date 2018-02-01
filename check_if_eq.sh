#!/bin/bash
#有4列数据，当第一列不等于第二列或者第三列不等于第四列时，输出这一行
#chenjh01 2017.07.25

sum=`cat 1.txt|wc -l`
sum_error=0
for (( i = 1; i < "$sum" ; i++ )); do
	#statements
	txt=`sed -n ''$i'p' 1.txt`
	a=`echo $txt |awk '{print $3}'`
	b=`echo $txt |awk '{print $4}'`
	c=`echo $txt |awk '{print $5}'`
	d=`echo $txt |awk '{print $6}'`
	if [ "$a" != "$c" -o "$b" != "$d" ]; then
		#statements
		echo "$txt"
		sum_error=$(($sum_error+1))
	fi
done
echo -e "$sum \n$sum_error"
