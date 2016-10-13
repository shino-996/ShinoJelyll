---
title: gitignore 相关的用法
date: 2016-03-24 18:08:16
tags:
- 计算机
- git
---

如果英文好，并且确定不会踩什么坑的话，一个命令就解决，就不用点进来看了，嗯【

~~~
$ git --help gitignore
~~~

<!-- more -->

---

。。。。。。

好吧，虽然gitignore的写法很简单，但是要想灵活使用还是得研究一下的，git help文档中的内容会尽量都提到，同时再结合一下我最近遇到的问题，也当个备忘录用。

> gitignore 的说明及基本使用参照[git官方的说明][gitignore document]或者google，不多说这个了。

#### 忽略文件&目录

gitignore文件本质就是一个忽略列表，想要被忽略的文件或目录直接写在里面就行了

~~~
# 忽略项目根目录的文件
/ignore_file

# 不带斜线代表忽略所有文件夹中的同名文件
# 忽略项目中所有名为 ignore_all\file 的文件
ignore_all_file

# 忽略项目根目录的目录，记得加斜线
/igmore_dir/
~~~

#### 通配符

可以使用星号*来表示“任意”这一概念

~~~
# 忽略护展名为 .tmp 的文件
*.tmp

# 忽略 dir_A 中的所有文件
# 注意这和忽略目录 dir_A 不同，区别在于忽略的是目录中的文件而不是目录本身
/dir_A/*

# 忽略任意目上录下的 file_B 文件，注意是两个星号
**／file_B
~~~

#### 强行不忽略某个文件

可以无视定义的忽略文件规则，不忽略某些文件。但是无法将已经被忽略的目录中的文件重新加入，因为目录被忽略后，git就不管这个目录了...

~~~
# 举个栗子，忽略 all_ignore 目录的所有文件，但是不忽略 except_this 文件
/all_ignore/*
/!except_this

# 错误做法，all_ignore 目录被忽略后，该目录相关的一切都不被处理了。
# /all_ignore/
# !/except_this
~~~

#### 不知道忽略哪些文件

在github上的[gitignore 项目][github gitignore]中有常用的各种工程、语言及IDE的gitignore例子，按需求复制粘贴一下基本就够了，实在有特殊殊需要再自己写。

[gitignore document]:https://git-scm.com/docs/gitignore
[github gitignore]:https://github.com/github/gitignore