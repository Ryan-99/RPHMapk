# RPHMapk

# 还原华为鸿蒙系统中 `system/app` 中 `apk`文件

脚本调用了 `baksmali-2.5.2,jar` `smali-2.5.2.jar` `vdexExtractor` `compact_dex_converter` 脚本来实现功能

**使用脚本前，请确保adb已经连接**

```shell
sudo bash rpapk.sh
```

输出apk文件保存在 `output` 文件中

## 脚本原理

使用 `adb pull` 将系统中的文件复制到本地

```shell
adb pull /system/app $app
adb pull /system/framework $framework

adb pull /apex/com.android.runtime $apex 
#这个文件夹是因为在baksmali时会报错，不报错可以不要
```

使用 `baksmali` 和 `smali` 还原 odex 文件为 dex

```shell
java -jar baksmali-2.5.2.jar x $filename.odex -o output/$filename -d $system/
java -jar smali-2.5.2.jar a output/$filname -o $filename/$filename.dex
```

使用 `vdexExtract` 将 vdex 文件还原为 cdex

```shell
cd vdexExtract/bin
./vdexExtract -i $vdex -o out/$filename
```

使用 `compact_dex_converter` 将 cdex 还原为 dex

```shell
./compact_dex_converter $cdex
```

将文件后缀改为 dex 

```shell
mv $cdex classes$j.dex
```

将dex文件打包进apk中

```shell
zip -m $apk classes*.dex
```

如果需要进行安装，请自行签名
