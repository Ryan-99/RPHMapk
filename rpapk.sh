#!/bin/bash


WORKDIR=$(pwd)
output=$WORKDIR/output
out=$WORKDIR/out
system=$WORKDIR/system
app=$system/app
framework=$system/framework
apex=$system/apex


if [ -f "DeodexApkList.txt" ]; then
	rm DeodexApkList.txt
fi

if [ ! -d $system ]; then
	mkdir $system
fi

if [ -d $output ]; then
	rm -rf $output/*
else
	mkdir $output
fi

if [ -d $out ]; then
	rm -rf $out/*
else
	mkdir $out
fi

if [ -d $framework ]
then
	echo "framework目录已存在，无需下载"
else
	adb pull /system/framework/ $framework
fi

if [ -d $app ]
then
	echo "app目录已存在，无需下载"
else
	adb pull /system/app/ $app
fi

##没有这个目录会报错
if [ -d $apex ]
then
	echo "apex目录已存在，无需下载"
else
	mkdir -p $apex
	adb pull /apex/com.android.runtime/ $apex/com.android.runtime/
fi

##需要将这个文件单独进行处理才能执行
zframework=$(find $framework -name "*.z.jar")
zname=$(basename -s .z.jar $zframework)
zvdexxs=$(ls $framework/*.z.vdex)
if [ ! -f "$zvdexxs" ]
then
	echo "warning:hadn't found $zvdexxs!"
	exit 0
else
	echo "正在搭建环境。。。。"
	if [ ! -f "$WORKDIR/vdexExtractor/bin/vdexExtractor" ]
	then
		chmod +x $WORKDIR/vdexExtractor/make.sh
		./vdexExtractor/make.sh
	fi
	./vdexExtractor/bin/vdexExtractor -i $zvdexxs
	zcdexx=$(find $framework -name "*.cdex")
	for zcdex in $zcdexx
	do
		if [ ! -f "$zcdex" ]; then
			echo "warning:hadn't found $zcdex!"
			exit 1
		fi
		if [ -f "$zcdex" ]; then
			./vdexExtractor/compact_dex_converter $zcdex
			new_zcdex=$(find $filename -name "*.new")
			j=0
			for new_dex in $new_zcdex
			do
				j=$((j+1))
				mv $new_dex classes$j.dex 
			done
		fi
	done
fi
	zip -m $zframework classes*.dex 1> /dev/null 2> /dev/null



#deodex apk files
(find $WORKDIR/system/app -name "*.apk") > $WORKDIR/DeodexApkList.txt;
cat $WORKDIR/DeodexApkList.txt | while read line;
do
	#echo $line
	filess=${line%}
	filesname=$(basename -s .apk $filess)
	filename=$WORKDIR/out/$filesname

	##反编译odex
	odexxs=$(find `dirname $filess` -name "*.odex")
	for odexx in $odexxs
	do
		if [ ! -f "$odexx" ]; then
			echo "warning:hadn't found $odexx!"
		fi

		if [ -f "$odexx" ]; then
		#echo $filename
    		echo "Deodex $filename ..."
    		java -jar baksmali-2.5.2.jar x $odexx -d $WORKDIR/system -o $filename
    		java -jar smali-2.5.2.jar  a $filename -o $filename/classes.dex
			fi
	done

	##反编译vdex
	vdexxs=$(find `dirname $filess` -name "*.vdex")
	for vdexx in $vdexxs
	do
		if [ ! -f "$vdexx" ]; then
			echo "warning:hadn't found $vdexx!"
		fi

		if [ -f "$vdexx" ]; then
			echo "Devdexing $filesname.vdex"
			cd $WORKDIR/vdexExtractor
			if [ ! -f "$WORKDIR/vdexExtractor/bin/vdexExtractor" ]
			then
				chmod +x make.sh
				./make.sh
			fi
			./bin/vdexExtractor -i $vdexx -o $filename
			cdexxs=$(find $filename -name "*.cdex")
			for cdexx in $cdexxs
			do
				if [ ! -f "$cdexx" ]; then
					echo "warning:hadn't found $cdexx!"
				fi
				if [ -f "$cdexx" ]; then
					./compact_dex_converter $cdexx
					new_cdexx=$(find $filename -name "*.new")
					j=0
					for new_dex in $new_cdexx
					do
						j=$((j+1))
						mv $new_dex $filename/classes$j.dex 
					done
				fi
			done
		fi
	done
 	##打包apk
    cd $filename
    zip -m $filess classes*.dex 1> /dev/null 2> /dev/null
    cd $WORKDIR
	cp $filess $output/$filesname.apk

#clean files

done

rm -rf DeodexJarList.txt
rm -rf DeodexApkList.txt
echo "All Done."
