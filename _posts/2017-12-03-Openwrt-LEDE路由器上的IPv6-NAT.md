---
title: Openwrt / LEDE路由器上的IPv6 NAT
date: 2017-12-03 17:02:46 +0800
tags: 
- 计算机
- 教程
- Linux
---

之前写过使用 LEDE 路由器使内网设备使用 IPv6 的方法, 不过关于 NAT 部分有一些细节没有解释清楚, 这学期开了网络课(虽然没什么关系), 把 IPv6 详细地学习了一遍, 于是再开一篇文章具体解释一下 IPv6 NAT 的设置及原理.

<!-- more -->

---

这篇主要是讲原理, 如果想直接看配置方法可以直接看[之前我写的配置方法][old_post].

{:.no_toc}
## 目录

* 目录
{:toc}

## 为什么要使用 IPv6 NAT

使用 NAT 对于速度影响很大, 而且有悖于 IPv6 的设计意图. 但是在些情况只有路由器可以获得**全球单播地址**, 比如我的学校对静态地址配置限制了 MAC, 这种情况不得不使用 NAT 来让内网设备使用 IPv6. 所以在可以使用中继方式使用 IPv6 的情况下, 最好不要使用 NAT.

## 一些基础 IPv6 地址知识

IPv6 地址分为单播地址, 多播地址和任播地址, 这里只说一会配置会用到的单播地址. 单播地址可分为如下几类:

- 全球单播地址 Global unicast address

可看作 IPv4 中公网 IP, 范围从 2000::/3 到 3fff::/3, 前48位为全球路由前缀, 之后的16位为子网ID, 最后64位为接口ID. 可以把前64位看作是 IPv4 的网络位, 后64位看作为主机位.

- 本地地址 Unique local address

可看作 IPv4 中的私有 IP (192.168.0.0/24这种), 范围从 fc00::/7 到 fdff::/7, 同样前64位为路由前缀, 后64位为接口ID, 通常为fd开头. 通常会把**本地地址**称为 ULA.

- 本地链路地址 Link local address

有点类似 IPv4 中 169.254.0.0/8 网段的地址, 但作用又不太一样. 每个接口都有一个**本地链路地址**, 用于本地链路间通信, 并且只能在本地链路中使用, 在邻居发现协议中起着重要的作用. 范围从 fe80::/10 到 febf::/10, 后64位接口ID.

此外的 ::1 本地环路地址, :: 任意地址等同 IPv4 中的概念相同, 以及在隧道中会用到 IPv4 转译地址就不细解释了. 通常一个接口会有多个 IPv6 地址.

## WAN 接口配置

![](/source/2017-12-03-Openwrt-LEDE路由器上的IPv6-NAT-接口)

通常外网这头不会出现问题...添加一个用于 IPv6 的外网接口, 设置成 DHCPv6 (或者对应的 IPv6 接入方式).

## LAN 接口地址配置

![](/source/2017-12-03-Openwrt-LEDE路由器上的IPv6-NAT-路由前缀)

LEDE 系统里通过配置ULA前缀来配置LAN接口的 IP, 也就是**本地地址**, 同时 LAN 接口下的分配长度(修改路由前缀长度), 分配提示(前缀子网ID)和 IPv6 suffix (路由器的内网 IP)可以进一步对此进行修改.

## 内网地址分配

![](/source/2017-12-03-Openwrt-LEDE路由器上的IPv6-NAT-DHCPv6)

LEDE 使用 odhcpd 对内网设备分配 IPv6 地址, 对应于 IPv4 的 DHCP, 对于 IPv6 地址有两种分配方式:

- 有状态

IPv6 中也有 DHCPv6 进行内网地址的自动配置. DHCP 分配的地址由路由器进行分配管理, 是一种有状态的分配方式.

- 无状态

IPv6 还可以通过邻居发现协议进行无状态地址分配, 路由器只向内网设备给出路由前缀等信息, IPv6 地址由内网的设备跟据路由前缀进行组配, 路由器中不保留每个内网设备的 IP 分配状态.

设置过程中还要注意设置`总是广播默认路由`, **本地地址**应该只用于在内网通信, 不应该被路由器转发到外网, 所以 [RFC7084][rfc] 中提到当路由器的内网地址中(可以有**本地地址**和**全球单播地址**等多个地址)没有和外网地址前缀相同的时候, 不应该将路由器做为默认网关来转发流量. 我们现在的情况是内网分配不到全球单播地址而且需要和外网通信, 所以要强制路由器做内网的默认网关.

 具体的 odhcpd 的配置文件说明可以参考 [github][odhcpd], LEDE 系统中关于路由前缀的配置在`/etc/config/network`中, 内网地址分配配置在`/etc/config/dhcp`中.

## LEDE 中的原生 NAT 说明

虽然 LEDE 系统原生就支持 IPv6, 但是网上各种各样的配置方法都很复杂, 并不像 IPv4 的 NAT 一样几乎不需要配置. 原因嘛, emmmm, odhcpd 给内网分配置**本地地址**的目的是为了让不在同一本地链路的内网设置在不使用**全球单播地址**的情况下进行通信, 即使用了 NAT 的与外部网络隔离的作用, 而不是让内网的设备共用唯一的外网**全球单播地址**. 条件允许的情况下, 路由器会通过前缀委派(prefix delegate)将外网的路由前缀分发到内网, 内网设置生成接口ID与前缀组装成一个**全球单播地址**. 这样每台内网机器除了有一个**本地地址**进行内部通信之外, 还有一个**全球单播地址**与外网进行通信, 显然和我们想像的 NAT 点不一样. 在我的使用环境下, 路由分到的地址的路由前缀已经是64位, 即无法再向下分配子网, 而且对于**全球单播地址**的分配限制了 MAC, 内网的设备是分不到**全球单播地址**的.

因此, 在我们配置的 IPv6 NAT 中, odhcpd 起到的作用只是给内网设置分配好**本地地址**, 真正起到作用的是 kmod-ipt-nat6 内核模块的NAT转发和 ip6tables 的流量分流.

## ip6tables 设置

如上面所说, 现在内网的设备只有**本地地址**, 无法与外网通信, 所以需要使用 ip6tables 将内网流量转发到外网做 SNAT, 再具体一些就是: 

- 允许对内网流量进行转发

对于内网发到路由器上的流量, 根据其目的地址进行路由选择, 防火墙设置上要允许对这部分流量中需要直接发到外网的部分进行转发.

- 对转发的内网流量进行追踪

通常进行网络通信的主机是要互相收发数据的, 所以路由器需要对转发出去内网流量(主要指转发时使用的外网 IP 端口, 工作在第四层传输层)进行记录, 将所需的外网流量转发给对应的内网设备.

- 将转发流量的源地址改为路由器外网地址

**本地地址**是无法用于公网区域通信的, 所以转发流量出路由器之前要将源地址改为路由器的外网地址.

操作就是在防火墙规则下添加三条规则:

~~~ sh
lede$ ip6tables -A FORWARD -i br-lan -j ACCEPT
lede$ ip6tables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
lede$ ip6tables -t nat -A POSTROUTING -o eth0.2 -j MASQUERADE
~~~

三条规则作用与上面解释顺序相同, 其中`br-lan`, `eth0.2`分别为内网网桥和外网接口.

## 路由表设置

网上所有的教程(包括我之前写的orz)都只是写了这一步的操作, 但没有解释这么做的原因, 我自己查了好多资料才弄明白. ip6tables 设置好 IPv6 防火墙之后网络地址转换可以正常工作, 但是内网的流量还是不可以转发到外网, 这和 iptables 中数据流向过程中的路由选择有关.

iptables 的设置是按照表和链这种二维结构进行配置的, 在 LEDE 中, 结构如下:

- mangle 表: PREROUTING, POSTROUTING, FORWARD, INPUT, OUTPUT

- nat 表: PREROUTING, POSTROUTING, OUTPUT

- filter 表: INPUT, FORWARD, OUTPUT

![](/source/2017-12-03-Openwrt-LEDE路由器上的IPv6-NAT-iptables)

数据流向如上图所示, 现在看一下路由选择的过程, 我从自己的路由上看到的路由表如下:

~~~ 
lede$ ip -6 route
default from 2001:da8:a800:2182::/64 via fe80::5a69:6cff:fe91:13ba dev eth0.2  proto static  metric 512  pref medium
2001:da8:a800:2182::/64 dev eth0.2  proto static  metric 256  pref medium
fd00::/64 dev br-lan  proto static  metric 1024  pref medium
unreachable fd00::/64 dev lo  proto static  metric 2147483647  error -148 pref medium
fe80::/64 dev eth0  proto kernel  metric 256  pref medium
fe80::/64 dev br-lan  proto kernel  metric 256  pref medium
fe80::/64 dev eth0.2  proto kernel  metric 256  pref medium
fe80::/64 dev wlan0  proto kernel  metric 256  pref medium
~~~

关键在于第一条的默认网关, 可以看到, 默认网关中限制了只有源地址为 2001: 的数据可以通过网关经过 eth0.2 接口流出路由器, 这里的 2001: 前缀为我的路由器所分配的**全球单播地址**的路由前缀, eth0.2 为路由器的外网接口. 这是因为路由器设置网关时, 为了避免多余的流量经外网流出路由器, 限制了只有源地址为外网 IP 的流量才可以流出. 我们将内网流量的源地址改为外网地址是在 POSTROUTING 链中进行的, 而从上面的 iptables 数据流向图中可以看出, NAT 流量经过 FORWARD 链, 要流出路由器时, 在 POSROUTING 链前的路由选择中会因为匹配不到路由表上的条目被丢弃.

这里使用的查看路由表使用的是`ip -6 route`命令, `route -A inet6`命令查看的路由表不全面, 看不到源地址信息, 所以不使用. 

知道问题原因就好办了, 只要添加上一条允许任何源地址的流量经外网接口流出默认网关即可:

~~~ sh
lede$ ip -6 route add default via fe80::5a69:6cff:fe91:13ba dev eth0.2
~~~

至此, 内网设备可以正常使用 IPv6 访问网络, 最后附上一张流程图作为总结:

![](/source/2017-12-03-Openwrt-LEDE路由器上的IPv6-NAT-总流程)

[old_post]: /2017/OpenWrt-LEDE路由器上的IPv6设置/
[odhcpd]: https://github.com/openwrt/odhcpd/blob/master/README
[rfc]: https://tools.ietf.org/html/rfc7084