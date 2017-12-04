---
title: 从零开始搭建shadowsocks科学上网系统（服务器篇）
date: 2017-03-02 15:43:00 +0800
tags:
- 计算机
- 教程
- Linux
---

早就想整理一篇科学上网资势，但一直咕咕咕到现在，正好有人向我要教程，那就写全一点，免得以后重新布署的时候再看别的文档。因为想到会写很长，服务器和客户端分开写，这篇主要是在VPS上搭建[shadowsocks][shadowsocks.org]服务器。

<!-- more -->

---

[从零开始搭建shadowsocks科学上网系统（客户端篇）][client]

虽然网上有许多配置脚本，但我还是喜欢手动配置，因为这样比较原汁原味，而且可定制性高。虽说是从零开始，但是一些简单的终端操作这样的前置技能还是要掌握的，我尽量把我当时遇到的小问题都写出来。

> 全文以macOS环境为例，Windows环境下自备[PuTTY][putty]进行ssh连接用

{:.no_toc}
## 目录

* 目录
{:toc}

## 创建VPS

各个VPS提供商官网上教程都写得很详细了，所以就不一步一步地介绍了。

### 服务商

我现在用的是[Digital Ocean][digitalocean]上的，还有[vultr][vultr]上的也不错，VPS里的高富帅[linode][linode]也开了5刀的套餐，也可以试一下。如果要在Digital Ocean上购买的话，能走一下[我的邀请链接][digitalocean code]就太好了，再到网上搜一下优惠码，可以免费用上几个月。

### 地区节点

因为在太平洋有直达洛杉矶的海底光缆，所以洛杉矶节点的速度还是可以的，不过我家里的铁通连新加坡节点速度也不慢，可以实际[测一下速][digitalocean speed]（需要flash）来选择合适的节点。

### 系统

关于系统，我当时选的是64位的Debian 8.7，如果是小白的话，还是暂时和我选一样的吧，要不一会编译可能会出问题。

### ssh密钥

创建VPS的时候要选择一个连接VPS用的ssh密钥，不要用密码，更不能每次都用网页上的access网页连接……Digital Ocean是不能在网上生成密钥的，只能上传本地密钥。在本地可以使用`ssh-keygen`命令生成密钥对：

~~~ sh
local$ ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f filename
~~~

因为下面要涉及到本地的shell和VPS上的shell环境，所以用`local$`代表本地shell，`vps$`代表VPS上的shell。上面的命令中，`-t`代表加密算法，这里使用rsa；`-b`是生成密钥的位数，`-C`后可以接一些注释，这里写的邮箱是因为github上推荐这样生成gihub用的ssh密钥，生成一个密钥可以在gihub上和VPS上同时使用；`-f`指生成的密钥名称。在生成的过程中会有一步提示：

~~~ sh
Enter passphrase (empty for no passphrase):
~~~

这一步是要求设置使用私钥时的密码，不想设置的话回车跳过就好。之后就会生成一个名为`filename`的私钥和名为`filename.pub`的公钥。我们要上传的是公钥，也就是`filename.pub`，输出公钥内容:

~~~ sh
local$ cat filename.pub
~~~

可以在账户的设置界面添加公钥，也可以在新建VPS时新建（其实就是添加公钥）。新建VPS时勾选上我们上传的公钥，就可以使用ssh密钥、而不是密码登录了。

### 连接VPS

创建好之后，会得到VPS的IP，使用上面提到的私钥连接VPS

~~~ sh
local$ ssh root@IP -i filename
~~~

`root`即VPS的root账户，`-i`为指定连接用的私钥。连接时会提示：

~~~ text
The authenticity of host '***' can't be established.
RSA key fingerprint is SHA256:***.
Are you sure you want to continue connecting (yes/no)?
~~~

这是在ssh连接过程中验证连接的服务器身份，输入`yes`继续。之后就可以看到登录后的界面了。

上面的连接命令，每次都要指定密钥的路径，很麻烦，如果你像我一样其本只用这一个ssh密钥，可以修改ssh配置，将这个密钥设置为默认密钥。ssh客户端配置文件为`~/etc/ssh/ssh_config`，添加`IdentityFile`项，后面接密钥路径，之后连接ssh默认用这个密钥，不用再加上`-i`选项了。

如果对于Linux系统不熟，可以先看一下[这个][linux]，了解一下文件和文件夹的操作，方便下面安装shadowsocks。

## 搭建编译环境

虽说会放出release版本直接安装，但有时会遇到release版本make失败（我就遇到过），搭好环境有备无患。我们装的Debian 8.7，也就是Jessie版本默认软件源上没有编译shadowsocks-libev要用到的`libmbedtls-dev`软件包，所以先添加它的软件源：

~~~ sh
vps$ sh -c 'printf "deb http://httpredir.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list'
~~~

手动在`/etc/apt/sources.list.d/jessie-backports.list`里添加记录`deb http://httpredir.debian.org/debian jessie-backports main`也可以。之后就可以正常安装一会编译要用到的环境了：

~~~ sh
vps$ apt-get update
vps$ apt-get install --no-install-recommends gettext build-essential autoconf libtool libpcre3-dev asciidoc xmlto libev-dev libudns-dev automake libmbedtls-dev
~~~

最新版的shadowsocks-libev采用了新的加密算法，它的依赖包`libsodium`通过apt-get得到的版本太旧了，需要找源码安装：

~~~ sh
vps$ apt-get update    #更新软件包目录
vps$ apt-get install git-all    #娄装git
vps$ git clone https://github.com/jedisct1/libsodium.git    #下载源码
vps$ cd libsodium/    #进入项目文件夹
vps$ ./autogen.sh    #运行配置脚本
vps$ ./configure    #配置编译环境
vps$ make    #编译
vps$ make install    #安装
vps$ ldconfig    #重新加载动态连接库
~~~

## 安装shadowsocks-libev

shadowsocks的服务端也分[python][shadowsocks python]版本、[go][shadowsocks go]版本以及C语言写的[shadowsocks-libev][shadowsocks-libev]，因为libev版更新快，而且C语言编写的运行效率更高些，所以采用libev版。

### 安装预编译包

在shadowsocks-libev的[github项目][shadowsocks-libev]上有release预编译版本，可以直接安装（以目前的3.0.3版本为例）：

~~~ sh
#下载预编译文件
vps$ wget https://github.com/shadowsocks/shadowsocks-libev/releases/download/v3.0.3/shadowsocks-libev-3.0.3.tar.gz
vps$ tar zxf shadowsocks-libev-3.0.3.tar.gz    #解压缩
vps$ cd shadowsocks    #进入项目文件夹
vps$ ./configure    #配置安装
vps$ make
vps$ make install
~~~

### 编译源码安装

~~~ sh
vps$ git clone https://github.com/shadowsocks/shadowsocks-libev.git #下载源码
vps$ cd shadowsocks-libev/    #进入项目目录
vps$ git submodule update --init    #下载git子模块
vps$ ./autogen.sh    #生成配置文件
vps$ ./configure    #配置编译环境
vps$ make     #编译
vps$ make install    #安装
~~~

这样就装好了，shadowsocks-libev中常用的命令有`ss-server`、`ss-local`、`ss-redir`、`ss-tunnel`等，服务端我们只用`ss-server`。关于使用方法，可以`man shadowsocks-libev`或者`man ss-server`来查看，下面只会提到必要用法。

## 编辑配置文件

一般为了方便，会将shadowsocks设置的参数写成配置文件，配置文件为json格式，服务端可以使用的key如下：

|key|说明|
|:-:|:-:|
|server|服务器IP|
|server_port|服务端口|
|password|密码|
|method|加密算法|
|timeout|超时|
|mode|代理协议|

服务器IP如果设为`0.0.0.0`则绑定所有IP；代理协议指的是代理TCP还是UDP，至于加密算法，3.0以上版本的shadowsocks目前支持18种算法，但推荐使用以下支持AEAD加密的：

- chacha20-ietf-poly1305
- aes-256-gcm
- aes-192-gcm
- aes-128-gcm

至于原因可以参考[这篇文章][aead]这里以我常用的配置文件为例：

~~~ sh
vps$ touch config.json    #新建文件
vps$ vim config.json    #编辑文件
~~~

至于vim的使用，来！[点我30s入门][vim]，文件内容如下：

~~~ json
{
    "server":"0.0.0.0",    //服务器IP，0.0.0.0代表绑定服务器的所有IP
    "server_port":8088,    //服务端口
    "password":"password",    //密码
    "timeout":"5",    //超时重连
    "method":"chacha20-ietf-poly1305",    //加密方式
    "mode":"tcp_and_udp"    //代理TCP和UDP
}
~~~

配置文件为json格式，`//`后为注释，方便说明加的，实际配置文件里不能写注释（看那个红色就知道不能加）。这里我用的是在移动设备上性能相对效好的`chacha20-ietf-poly1305`。因为只有shadowsocks-libev更新了AEAD加密，所以为了兼容可以改为`chacha20`等非AEAD加密算法。

## 运行shadowsocks-libev

~~~ sh
vps$ ss-server -c config.json
~~~

可以看到服务在前台运行，`-c`后面接配置文件。若要后台运行，可以加上`-f`参数，后面接一个pid文件名，运行后会生成这个pid文件，里面保存着这个后台`ss-server`进程的pid。

~~~ sh
vps$ ss-server -c config.json -f proxy.pid
~~~

如果想开多个端口，可以使用多个配置文件+多个pid文件的方式来管理。这样服务端就完成了。

[client]: /2017/从零开始搭建shadowsocks科学上网系统-客户端篇
[shadowsocks.org]:https://shadowsocks.org/en/index.html
[putty]:http://www.putty.org
[digitalocean]:https://www.digitalocean.com
[vultr]:https://www.vultr.com
[linode]:https://www.linode.com
[digitalocean code]:https://m.do.co/c/1efa93bb0b16
[digitalocean speed]:http://speedtest-sfo1.digitalocean.com
[linux]:http://billie66.github.io/TLCL/book/zh/index.html
[shadowsocks python]:https://github.com/shadowsocks/shadowsocks
[shadowsocks go]:https://github.com/shadowsocks/shadowsocks-go
[shadowsocks-libev]:https://github.com/shadowsocks/shadowsocks-libev
[aead]:https://blessing.studio/why-do-shadowsocks-deprecate-ota/
[vim]:http://wiki.ubuntu.org.cn/Vim用户操作指南