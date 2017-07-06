---
title: 从零开始搭建shadowsocks科学上网系统（客户端篇）
date: 2017-07-06 13:00:16 +0800
tags:
- 计算机
- 教程
- Linux
---

shadowsocks客户端是覆盖全平台的，网上的教程也不少，这里只说一下网上基本没提到过的macOS上的配置。

<!-- more -->

---

[从零开始搭建shadowsocks科学上网系统（服务器篇）][server]

这个四月份好漫长啊（坚持月更【）

{:.no_toc}
## 目录

* 目录
{:toc}

## 一些通用的配置

除了OpenWrt/LEDE路由器上的配置有些复杂外，其他平台上的设置基本上是一样的，先统一说一下一些参数。

### 服务器

填IP和域名都可以，不过shadowsocks服务器域名的解析应该用的是本地的DNS（毕竟还没有连上代理），所以尽量填IP吧。

### 端口

服务器端如果是自己搭的，尽量把端口设置为80或443这种常用端口，因为有的网络环境会限制一些端口，8080，25这种非HTTP端口也可以。

### 算法&密码

现在所有平台的客户端都支持AEAD加密算法，推荐AEAD。另外shadowsocks基本上没有什么多用户的概念，如果是多人使用多个密码的话一般就是开多个端口，每个端口设置一个密码。

### 全局&自动代理

全局代理指全局的SOCKS代理，所有流量都走代理端口。自动代理一般使用PAC文件，黑名单指在黑名单内域名走代理，不在黑名单内的不走代理；白名单相反，只有在白名单内的域名不走代理。如果代理流量有限制，最好使用黑名单，不限制流量的话，白名单更好一些。黑名单一般都是用著名的[gfwlist][gfwlist]，白名单个人推荐[这个][whitelist]。

## Android、Windows、OpenWrt/LEDE端

[Android端][android]，[Windows端][windows]都在github上有各自的应用，没什么可多说的。OpenWrt/LEDE路由器的话，参考[这篇文章][lede]，讲得非常全了。

## macOS端

github上的GUI版本不怎么能满足我的使用需求，所以我用的是shadowocks-libev。

### 安装shadowsocks-libev

使用[homebrew][homebrew]安装即可，没必要手动编译源码。没安装homebrew的用户，需要先到App Store下载[Xcode][xcode]，之后在终端运行：

~~~ sh
local$ /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
~~~

其实就是运行一个ruby脚本。用homebrew来管理macOS上的命令行工具是不错的选择，软件包更新也跟得上。安装好homebrew后就可以安装shadowsocks-libev：

~~~ sh
local$ brew update    #更新homebrew软件源
local$ brew install shadowsocks-libev
~~~

### 开机自动启动

安装之后我们会看到终端中提示这样的信息：

~~~ text
To have launchd start shadowsocks-libev now and restart at login:
  brew services start shadowsocks-libev
Or, if you don't want/need a background service you can just run:
  /usr/local/opt/shadowsocks-libev/bin/ss-local -c /usr/local/etc/shadowsocks-libev.json
~~~

这是告诉我们开机自动运行shadowsocks的方法，和手动运行的方法。开机自动运行使用的是homebrew提供的服务，相当于执行了下面的命令：

~~~ sh
local$ ss-local -c /usr/local/etc/shadowsocks-libev.json
~~~

ss-local是shadowsocks-libev中的客户端命令。可以看出，homebrew安装shadowsocks时在`/usr/local/etc/`路径下建立了配置文件，供开机启动shadowsocks服务用，只要编辑这个文件就可以了。使用vim或是文本编辑器都可以，这可是macOS，不是没有GUI的Linux VPS了【

~~~ json
{
    "server":"server_ip",
    "server_port":8088,
    "local_port":1080,
    "password":"password",
    "timeout":5,
    "method":"chacha20-ietf-poly1305",
    "mode":"tcp_and_udp"
}
~~~

同服务器上的配置文件基本一至，不过多了一个`local_port`，这是因为上面说的本地要开一个端口用于把流量转发到shadowsocks服务器，所以要显式地写明端口，如果不写会默认1080端口。之后就可以启用shadowsocks的homebrew服务：

~~~ sh
local$ brew services start shadowsocks-libev
~~~

可以看到成功的提示信息。

### 全局代理

现在我们已经在本地开了一个socks代理，在系统设置里填上这个端口就可以使用全局代理：

![](/source/2017-07-06-从零开始搭建shadowsocks科学上网系统（客户端篇）-socks.jpg)

### 白名单

当然，平时我们不会使用全局代理的，所以接下来要配置上面提到过的PAC自动代理。

首先下载[域名白名单][whitelist]，要使用的是里面的PAC文件。如果本地代理端口不是默认的1080，下好的PAC文件还需要编辑一下脚本上使用的socks端口：

~~~ js
var proxy = new Array( "SOCKS5 127.0.0.1:port;")
~~~

将代理端口改为我们上面设置的本地端口。

因为10.12开始macOS不允许使用本地文件路么作为PAC文件路径，所以要把PAC文件放在网络环境下才可以正常使用，使用macOS自带的网页服务器即可。将PAC文件复制到`/Library/WebServer/Documents/`目录下，之后启用网页服务：

~~~ sh
local$ sudo apachectl start
~~~~

输入密码后，在浏览器中输入`http://localhost`可以看到`It works!`字样即为启动成功，接着在网络设置中自动代理的地址填写白名单的地址即可。

![](/source/2017-07-06-从零开始搭建shadowsocks科学上网系统（客户端篇）-pac.jpg)

**目前在macOS 10.13 BETA版本中，safari对PAC代理支持有问题，无法使用自动代理，其他浏览器正常**

### 代理切换

白名单模式已经足够满足日常需求了，不过总会有像我这样爱折腾的，在寝室我用路由器挂代理，在外面用电脑里的自动代理，就涉及到代理的切换。可以在网络设置添加一个网络位置，通过切换网络位置来切换代理方式，不过在切换网络位置的时候会断开wifi，显得不够优雅【。我现在使用`networksetup`命令来切换代理，这个命令实际上就相当于我们有网络没置中进行的设置的命令行形式。

~~~ sh
# 打开PAC
local$ networksetup -setautoproxyurl Wi-Fi http://127.0.0.1:80/whitelist.pac

#关闭PAC
local$ networksetup -setautoproxystate Wi-Fi off

# 打开socks
local$ networksetup -setsocksfirewallproxy Wi-Fi localhost 1080 on

# 关闭socks
local$ networksetup -setsocksfirewallproxy Wi-Fi localhost 1080 off
~~~

应该一下子就能看明白怎么使用，其中`Wi-Fi`是网络接口的服务名称，如果用的是wifi就不用改了，可以在网络设置右边看到各个接口的名称，PAC文件的位置和socks端口对应修改就好了。

可以把这几个命令写成脚本，因为我也使用[Alfred][alfred]，所以就写了个Alfred的[workflow][workflow]，用Alfred的可以直接下载使用。更改网络设置需要root权限，所以会提示输入密码。

[server]: /2017/从零开始搭建shadowsocks科学上网系统-服务器篇 
[gfwlist]: https://github.com/gfwlist/gfwlist
[whitelist]: https://github.com/R0uter/gfw_domain_whitelist
[android]: https://github.com/shadowsocks/shadowsocks-android
[windows]: https://github.com/shadowsocks/shadowsocks-windows
[lede]: https://cokebar.info/archives/978
[homebrew]: https://brew.sh/
[xcode]: https://itunes.apple.com/us/app/xcode/id497799835?mt=12
[alfred]: https://www.alfredapp.com/
[workflow]: https://github.com/shino-996/ChangeProxy