---
title: 使用git将本地Jekyll博客布署到VPS上
date: 2017-07-07 12:05:30 +0800
tags: 
- 计算机
- 教程
- Jekyll
---

从Hexo改成Jekyll已经有相当一段时间了，感觉还是Jekyll相对简结一点，相比于什么都有，我更喜欢什么都没有，自己一点点往上加。之前Hexo上的一个自动布署到VPS或者GitHub上插件很好用，试着写shell脚本实现一下。写得很粗糙，看一下思路就好。

<!-- more -->

---

> 关于Jekyll和git的具本用法没怎么提，网上资源也好找是吧～

{:.no_toc}
## 目录

* 目录
{:toc}

# 思路

![](/source/2017-07-07-使用git将本地Jekyll博客布署到VPS上-mind.jpg)

本地装有Jekyll用来折腾博客，生成网页文件。生成的网页文件发到VPS上，而博客的工程文件传到GitHub上存档。

# VPS上的操作

要安装nginx和git，不多讲。之后建立一个git裸仓库，用于接收本地网页的git push，以及布署git hook进行文件操作。

~~~ sh
vps$ git init name_of_git --bare
~~~

之后进入仓库中git hooks文件夹，新建一个`post-receive`文件。

~~~ sh
vps$ cd name_of_git/hooks
vps$ touch post-receive
~~~

git hooks是git自带的功能，在git不同的阶段会触发不同的git hooks事件，可以在git hooks里写脚本来执行一些需要在git执行时运行的指令。这里用的`post-receive`在仓库接收到`git push`之后触发。

使用vim什么的编辑`post-receive`文件，这里的`jekyll.git`是裸仓库文件，`/usr/local/nginx/HTML`是nginx的网页文件夹。

~~~ sh
#!/bin/sh
# 把仓库新收到的文件复制到临时文件夹
git clone /root/jekyll.git /tmp/jekyll
# 删除旧的网页文件
rm -rf /usr/local/nginx/html/*
# 复制新的网页文件到网页文件夹
cp -r /tmp/jekyll/* /usr/local/nginx/html/
# 删除临时文件
rm -rf /tmp/jekyll
~~~

使用临时文件夹是因为从仓库中取出文件要用到`git clone`，会产生`.git`等隐藏文件夹，强迫症不喜欢这些→_→

之后别忘了给`post-receive`添加运行权限:

~~~ sh
vps$ chmod +x post-receive
~~~

# 本地的操作

在jekyll文件夹里（其他位置也行，不过要相应改路径），建一个脚本文件，名字无所谓。内容如下：

~~~ sh
#!/bin/sh
# 清理后再生成Jekyll网页
bundle exec jekyll clean
bundle exec jekyll build
# 在网页目录建立git
cd _site
git init
# 添加VPS上的裸仓库作为远程仓库
git remote add jekyll root@shino.space:jekyll.git
# 提交并推送，这里的commit信息我定的是提交时间
git add .
commit_time=$(date "+%Y-%m-%d %H:%M:%S")
git commit -m "${commit_time}"
git push -f jekyll master:master
# 删除本地网页文件夹
cd ../
rm -rf _site
# 将Jekyll工程文件提交到GitHub
git add .
git commit -m "$1"
git push github master:master
~~~

VPS上的裸仓库的地址格式为`用户名@VPS地址:目录`，这里的目录为用户目录而不是根目录（别吐槽我用root干这事）。第一次提交到仓库时，因为仓库上没有任何分支，可以在第一次push时执行`git push --set-upstream master`在建立一个master分支，之后再push就按脚本里的来就可以了。

在push到VPS的仓库时，因为每次都是在新生成的网页文件夹中新建的git，所以直接将本地git推送到VPS上的git会报错，所以要用`-f`参数强制push。`git push`后面要加远程仓库的名字，在脚本中VPS上仓库名字用的是`jekyll`，github上仓库的名字我用的是`github`，要对照着进行修改。

至于最后push 到GitHub上的语句中的`$1`，工程文件的commit总得定点有意义的东西吧，就做为参数了。

最后，只要写完博客的md文件，运行一下本地的脚本，生成、布署、备份就都完成了～