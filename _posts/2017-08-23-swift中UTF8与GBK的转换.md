---
title: swift中UTF8与GBK的转换
date: 2017-08-23 15:43:40 +0800
tags: 
- 计算机
- swift
---

昨天遇到了愁人的需求，要将中文字符转换成GBK编码的百分号形式，而swift不支持GBK编码，`String`里的`addPercentEncoding`也是将Unicode字符的编码转换成百分号形式。最后总算找到了解决方法，连着GBK转换成Unicode的方法一起整理一下。

<!-- more -->

---

{:.no_toc}
## 目录

* 目录
{:toc}

> 因为`CFString`、`NSString`以及`String`中实际上是用UTF-16编码（确切地说是2字节的`unsigned short`数组）来储存Unicode字符，而网络传输使用的是UTF-8，不过使用这些类时两种编码切换是无缝的，为了叙述方便我就用Unicode替代，实际上**Unicode是字符集，而不是编码**。

## GBK转Unicode

这种情况一般出现在抓取老网页或者连接旧数据库时，通常获取到的`Data`为GBK编码的字符，由于swift中的`String`不支持GBK编码，不能从GBK编码初始化，而历史久远一些的`NSString`支持GBK，所以使用`NSString`使中介做转换即可：

~~~ swift
//直接扩展一下String，使用能方便些
extension String {
    init?(gbkData: Data) {
        //获取GBK编码，使用GB18030是因为它向下兼容GBK
        let cfEncoding = CFStringEncodings.GB_18030_2000
        let encoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncoding.rawValue))
        //从GBK编码的Data里初始化NSString，返回的NSString是UTF-16编码
        if let str = NSString(data: gbkData, encoding: encoding) {
            self = str as String
        } else {
            return nil
        }
    }
}
~~~

## Unicode转GBK

如上面所说的，`String`和`NSString`不能存GBK编码的字符，不过使用`NSString`的`data(using: UInt)`方法可以将字符转换为GBK编码的二进制，这样读出`Data`里的二进制就能知道符的GBK编码了：

~~~ swift
extension String {
    var percentEncodeWithGBK: String {
        let cfEncoding = CFStringEncodings.GB_18030_2000
            let encoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncoding.rawValue))
            let gbkData = (self as NSString).data(using: encoding)!
            //Data是以字节数组的形式储存二进制的，可以直接转换为Uint8
            let gbkBytes = [UInt8](gbkData)
            //GBK是两字节的
            return NSString(format: "%%%X%%%X", gbkBytes[0], gbkBytes[1]) as String
    }
}
~~~