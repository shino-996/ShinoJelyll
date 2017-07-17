---
title: OpenWrt/LEDE路由器上的IPv6设置
date: 2017-07-17 14:13:54 +0800
tags: 
- 计算机
- 教程
- Linux
---

路由器上一直用的IPv6 NAT的方式进行IPv6上网，因为LEDE更新了版本，就没保留置更新了系统，顺便整理一下之前路由器上的配置。中继的方式之前测试过，所以也会提一下。

<!-- more -->

---

很多学校校园网都有IPv6，但因为国内没普及，路由器通常不支持，只能直插网线用电脑上。如果想折腾的话可以刷个OpenWrt或者LEDE系统，为了简单，能在LUCI里配置的都在LUCI里配置。

**总有人瞎JB婊学校的网怎么怎么样，矫情！学校网络不能说完美，但这么多人接入的情况下表现一点也不差，和别的地方对比一下就知道了**

> 下面的配置在LEDE 17.01.2 系统上配置，OpenWrt系统配置相同，不知道这两个东西是啥的直接关掉网页就好

> 有些操作需要ssh到路由器上，自己想办法弄→_→

{:.no_toc}
## 目录

* 目录
{:toc}

## IPv6 NAT

### 需要的软件包

能过`Luci`或者`opkg`安装`kmod-ipt-nat6`和`ip6tables`（这个是系统内置的）。

> 如果你也是大连理工的同学，那只能用这种方式上网了，学校现在一个端口只分配一个IPv6地址。

NAT（网络地址转换）本身是为了解决IPv4地址不够的技术，IPv6地址是绝对够用的，所以这时NAT显然是多余的。不过只有一个IPv6地址，但多台设备要上网的情况也是存在的，只能用NAT解决，[RFC 6204][rfc]中也明确提到了IPv6确实也有NAT方案。LEDE固件本身对IPv6支持很好，稍加配置就可以了。

### WAN口配置

学校的IPv6是双栈，自动获取的。路由器默认就已经添加了一个`WAN6`接口，协议为`DHCPv6`，生效后会获得一个全球单播IPv6地址。如果没有这个接口就新建一个吧。

### LAN口配置

默认也应该是设置好的，`LAN`接口会有一个本地链路IPv6地址，相当于IPv4的内网地址。这个地址是根据接口总界面下`IPv6 ULA前缀`生成的，要中以通过修改前缀来改变路由LAN口IP。

![](/source/2017-07-17-OpenWrt/LEDE路由器上的IPv6设置-接口.jpg)

### DHCP配置

默认这个也都是已经配置好了的。在LAN口的DHCP配置的IPv6配置中，`路由器广告模式`和`DHCPv6服务`均选择`服务器模式`，并勾选`即使没有可用的公共前缀也广播默认路由`。至于`DHCPv6模式`，选哪个都行……`有状态`类似于IPv4的DHCP，`无状态`是IPv6特有的，不多提。

![](/source/2017-07-17-OpenWrt/LEDE路由器上的IPv6设置-NAT.jpg)

### 防火墙设置

上面的配置好后（嗯……其实上面的默认都是弄好的，下面才是开始），在`网络->防火墙->自定义规则`中添加一条`ip6tables -t nat -A POSTROUTING -o eth0.2 -j MASQUERADE`，然后重启防火墙。这是把内网所有的IPv6请求都转发到路由器的外网，再通过路由器的外网IPv6与外网通信。`eth0.2`为外网接口，根据实际情况修改。

### 添加默认路由

上面的都弄好后有时内网设备还是ping不通IPv6，在我的学校是这样的：虽然每个端口都分配一个全球单播IPv6地址（理解为外网IP），但是网关却是本地链路的（理解为内网IP），而内网被转发的IPv6流量需要一个全球单播地址，需要手动添加。

在路由器上使用`traceroute6`命令，查看第一跳的地址，比如：

~~~ sh
lede$ traceroute6 shino.space
traceroute to shino.space (2001:19f0:6001:5b:5400:ff:fe59:1a6d), 30 hops max, 16 byte packets
 1  2001:da8:a800:2182::1 (2001:da8:a800:2182::1)  0.840 ms  0.840 ms  0.740 ms
~~~

可以看到第一跳的IP是`2001:da8:a800:2182::1`，为了方便开机启动，在`/etc/hotplug.d/iface/`文件夹中创建一个启动脚本，比如`90-ipv6`注意命名格式，内容如下：

~~~ sh
#!/bin/sh

[ "$ACTION" = ifup ] || exit 0
route -A inet6 add default gw 2001:da8:a800:2182::1
~~~

当网络打开后就自动添加这个网关，网关地址根据实际结修改。有人会把这个命令添加到`rc.local`文件或者LUCI中启动项界面最下面的本地启动脚本中，有时并不能保证执行顺序，可能会失败。别忘了添加执行权限。

~~~ sh
lede$ chmod +x 90-ipv6
~~~

重启路由，之后就可以用了。

## IPv6 中继

之前学校一个端口可以分配多个IPv6地址，所以直接中继IPv6，相当于路由器对于Ipv4是路由器，对于IPv6只是交换机，虽然现在不能用了，还是记录一下，可能别的学校可以用呢。

WAN口配置不变，LAN口把`IPv6 ULA前缀`去掉，也不要添加LAN口IPv6地址，在DHCP配置中，把`路由器广告服务`、`DHCPv6服务`、`NDP-代理`都改为`中继模式`。

![](/source/2017-07-17-OpenWrt/LEDE路由器上的IPv6设置-中继.jpg)

之后再编辑路由器的`/etc/config/dhcp`文件，在`config dhcp 'lan'`字段下添加`option master 1`：

~~~ text
config dhcp 'lan'
        option interface 'lan'
        option start '100'
        option limit '150'
        option leasetime '12h'
        option dhcpv6 'relay'
        option ra 'relay'
        option ndp 'relay'
        option master '1'
~~~

NAT中提到的防火墙和网关都不用设置，这样就搞定了，每个设备都会分得一个全球单播地址。

[rfc]: https://tools.ietf.org/html/rfc6204