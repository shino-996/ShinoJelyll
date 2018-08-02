---
title: github的ssh key部署及原理分析
date: 2016-02-08 11:43:51 +0800
tags: 

- 网络
- ssh
- 计算机

---

最近折腾同时在[github] [github]和[gitcafe] [gitcafe]上同时部署博客并使用hexo的`hexo d -g`命令直接push博客, 其中涉及到了一些ssh的命令. 既然接触了就了解一下ssh的原理, 没有在网上找到完整的资料, 就自己总结一下. 
<!-- more -->

---

{:.no_toc}
## 目录

* 目录
{:toc}

> 以下操作在OS X 10.11.3环境下进行

## 密钥

从最基础的加密开始, 这里借鉴了[这两篇文章] [key]. 在最开始的时候, 计算机通信是明文的, 第三方可以有100种方法让通信进行不下去, 于是人们开始想办法使用加密的方法传输信息. 于是就产生了对信息加密的密钥, 密钥加密可以分为两种：

- 单密钥加密
- 双密钥加密

### 单密钥加密

很容易理解, 就是我们平时所用的密码, 加密和解密用的是一样的密钥. 不过这样会出现一个问题, 如果密钥泄露, 那么信息一定会被破解. 

### 双密钥加密

鉴于但密钥加密的弊端, 产生了非对称的双密钥加密. 产生密钥的时候会产生`公钥`和`私钥`一组密钥, 公钥加密的信息**只能**用私钥解密, 同样, 私钥加密的信息**只能**用公钥解密. 私钥不对外发放, 公钥对外发放, 这样, 即使公钥泄露, 用公钥加密的信息也不会被破解. （那私钥加密的信息怎么办？没事, 后面会解释的ww）

虽然安全性提高了, 但是双密钥加密的算法比单密钥要复杂得多, 了解一下[RSA] [rsa]算法就知道了, 加密和解密的效率会下降, 所以加密传输的方案通常两种加密方法都会使用. 

## ssh

ssh全名为[Secure Shell] [ssh], 是一项创建在应用层和传输层基础上的安全协议, 为计算机上的Shell（壳层）提供安全的传输和使用环境, 是Linux系统的标配（不过iOS上需要装openssh插件, 安卓就不知道了）. 用户与github上传输数据的时候肯定不能明文传输数据了, 可以使用`https`或者`ssh`的加密方式. 

## ssh工作过程

网上的在github上布置ssh key的教程都是只介绍了操作方法, 感觉还是介绍一下原理比较好. ssh的工作原理的信息参考自[这篇博客] [ssh principle]. 

ssh的工作过程可以分为如下几个阶段

- 协议协商阶段
- 服务端认证阶段
- 客户端认证阶段
- 数据传输阶段

这里的客户端就是指我们用户, github相当于服务端

### 协议协商阶段

因为ssh也是有不同版本的, 连接之前需要进行协商. 

1. 服务端打开服务端口（默认为22）, 等待客户端连接
2. 客户端发起TCP连接请求, 服务端接收到该请求后, 向客户端发送包括SSH协议版本信息
3. 客户端接根据该版本信息与自己的版本, 决定将要使用的SSH版本, 并向服务端发送选用的SSH版本信息
4. 服务端检查是否支持客户端的决定使用的SSH版本

### 服务端认证阶段

在此之前先说明一下接下来会出现的几种`key`：

| 名称 | 创建者 | 类型 | 描述 |
|:---:|:------:|:---:|:----:|
| host key | 服务端 | 公钥 | 对服务端进行认证 |
| user key | 客户端 | 公钥 | 对客户端进行认证 |
| server key | 服务端 | 公钥 | 对session key加密 |
| session key | 客户端 | 单钥 | 对传输数据加密 |
|====

1. 协商通过后, 客户端与服务端即建立连接, 服务端立即向客户端发送：

 - host key：用于确认服务端身份
 - server key：用于加密客户端将要生成的`session key`
 - **8字节的**随机数：客户端在下次应答时会发送此随机数, 防止[IP欺诈] [ip spoofing]
 - 服务端支持的加密算法、压缩方式和认证方式

这时, 客户端和服务端会使用Host Key、Server Key和8字节的随机数生成一个128位的[MD5] [md5]值, 作为此次会话的session id（MD5虽然被证实不那么安全, 但是还是有一定应用的）. 使用这个`session key`进行单密钥加密进行数据传输, 既保证了数据安全, 又保证了效率. 

2. 客户端收到信息后, 会将`host key`与自己的`know_hosts`（一般在`~/.ssh/konw_hosts`文件）进行对照. 

3. 之后客户端会将`session key`发送给服务端. 因为到目前为止还是明文传送信息, 所以客户端使用`host key`和`server key`进行**双重加密**. 

4. 服务端对客户端发来的加密session key解密, 与自己生成的session key比对

至此, 服务端认证结束. 这个阶段就是检验服务端是不是服务端. 因为发给客户端的`host key`和`server key`都是公钥, 客户端使用它们加密的`session key`只有用私钥才可以解开, 能解开的**一定是**服务端. 

那么如果有人伪装成服务端把自己生成的公钥发给客户端, 然后用自己的私钥解密呢？这就是客户端将`host key`与自己的`known_hosts`进行比对的原因, 如果发现是陌生的`host key`, 就可以进一步确认是不是伪造的服务端了. 

### 客户端认证阶段

因为双方都拥有session key, 以下的信息传输可以使用session加密传输了. 

客户端已经确定服务端的身份了, 但是服务端还需要确定客户端的身份, ssh提供了几种验证方法, 这里只讲github中使用的SSH-2版本中的`public key`方法：

1. 客户端发起一个Public Key的认证请求, 并发送RSA Key的模数作为标识符. 

2. 服务端检查是否存在请求的客户端的`server key`公钥, 在github里, 这个公钥就是我们上传的那个`ssh key`, github文档里要求生成ssh key的时候加入邮箱作为备注就是为了便于检索. 

3. 检索到`server key`之后, 服务端生成一个随机的256位字符串, 使用`server key`加密, 发送给客户端. 

4. 客户端使用`server key`的私钥对搜到的字符串解密, 然后使用`session key`对解密后的字符串加密, 计算其MD5（减少数据长度）发给服务端. 

5. 服务端使用`session key`对收到的信息解密, 将得到的MD5和自己计算的MD5比对, 确认客户端身份. 

至此, 客户端认证结束, 双方开始进行数据交换. 可以看出, 客户端认证也是利用了不对称的双密钥加密特点, 服务端用公钥发出的信息只有用私钥才能解密, 因此解密并返回正确MD5信息的一定是真正的客户端. 

## 现在回顾一下github的ssh配置

了解原理之后, 布置起来就简单多了. 因为上一篇文章的[将博客部署到github] [github ssh]部分已经介绍了具体流程, 这里就主要介绍其中的原理. 

- git本身的用户名和邮箱配置与ssh无关

- 生成ssh密钥对

生成的密钥即为客户端认证阶段, 服务端验证客户端的`server key`. github只允许使用`public key`的方式验证客户端, 不允许使用密码. 

- 将生成的密钥公钥添加到github

服务端需要事先保留客户端的`server key`公钥, 才能在之后的连接中使用该公钥判断客户端的身份. 

- 第一次连接github

因为是第一次连接, 客户端在验证服务端身份的时候需要手动验证`host key`

~~~ sh
The authenticity of host 'github.com (192.30.252.130)' can't be established.
RSA key fingerprint is SHA256:nThbg6kXUpJWGl7E1IGOCspRomTxdCARLviKw6E5SY8.
Are you sure you want to continue connecting (yes/no)?
~~~

这一步提示就是确认host key的确认选项

确认之后, host key就会加入到`known_hosts`记录中, 此时会有一个提示

~~~ sh
Warning: Permanently added 'github.com,192.30.252.130' (RSA) to the list of known hosts.
Hi 你的用户名! You've successfully authenticated, but GitHub does not provide shell access.
~~~

- 之后的连接, 因为服务端的server key已经保存在客户端的known_hosts记录中, 而客户端的server key公钥也已经上传到服务端, 所以就可以自动互相验证身份, 不必我们去操作什么了. 

## 那么https呢

其实只要仔细思考就会发现, 双密钥加密的方式在安全性上还是有弊端：如果有人伪装成服务端分发自己生成的公钥, 客户端无法判断公钥来源, ssh的判断方法是强行手动核对, 不够优雅, 于是产生了`数字证书`这个概念, https就是应用数字证书的一个案例. 因为hexo目前不支持https, 就直接丢一个[链接] [https]好了（其实让我讲也不一定比别人讲得好）→_→

[github]:https://github.com
[gitcafe]:https://gitcafe.com
[key]:http://www.ruanyifeng.com/blog/2006/12/notes_on_cryptography.html
[rsa]:https://zh.wikipedia.org/wiki/RSA加密演算法
[ssh]:https://zh.wikipedia.org/wiki/Secure_Shell
[ssh principle]:http://erik-2-blog.logdown.com/posts/74081-ssh-principle
[ip spoofing]:https://en.wikipedia.org/wiki/IP_address_spoofing
[md5]:https://zh.wikipedia.org/wiki/MD5
[github ssh]:/2016/02/01/使用Hexo在GitHub上搭建网站/
[deployer]:https://github.com/hexojs/hexo-deployer-git
[https]:http://www.ruanyifeng.com/blog/2011/08/what_is_a_digital_signature.html