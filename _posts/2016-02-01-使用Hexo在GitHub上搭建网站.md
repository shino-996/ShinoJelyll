---
title: 使用Hexo在GitHub上搭建网站
date: 2016-02-01 15:04:46
tags: 
- 计算机
- 教程
- hexo
---

> 既然本文相当于博客上第一篇正式文章，不记录一下博客是怎么搭建起来的话，也没有更合适的主题了。

<!-- more -->

---

* 目录
{:toc}

> 长文提示，可以点击屏幕右下角的![](http://7xqj9r.com1.z0.glb.clouddn.com/catalogue.jpg)按钮按照章节阅读

### hexo&github

正如文章标题，这个博客托管在`github`上，通过`hexo`框架搭建。github不用多说，github提供的`github pages`项目使得可以将静态网页托管在github上提供网站服务。至于hexo，直接引用它的作者`tommy351`的话：

> A fast, simple & powerful blog framework

一个快速、简洁、强大的静态博客框架。

### 为什么这么选择

很简单，托管在github上就不用自己去买vps，vps要花钱的←_←

hexo使用起来也很简单，配置好之后三个命令就足以应付日常写博客了。现成的博客框架也不用多操心网站的搭建，图方便十几分钟就能搞定；如果喜欢折腾，那么完全可以自己在框架上进行修改，玩几个月都不是问题。

### 配置环境

> 以下操作为`OS X 11.3`系统下进行的，不过不同系统间的差异性应该不大。

无论是否已经搭建成功，都推荐看一看[官方文档] [hexo public doc]，官方文档一定是最好的学习资料。

### 安装node.js&git

OS X自带`git`，不用管，`node.js`建议从[node.js官网] [node js]下载安装器，连`npm`也安装了，省了不少事。

### 安装hexo

之后打开终端，使用npm安装hexo，需要root权限进行某些文件的写入

~~~ sh
$ sudo npm install hexo-cli -g
~~~

### 建立博客文件夹

和博客有关的资源需要放在一个文件夹中，新建一个文件夹后在终端进入该文件夹的目录中进行hexo及npm的初始化

~~~ sh
$ hexo init
$ npm install
~~~

之后打开刚才的文件夹，会看到这样的结构

~~~ text
.
├── _config.yml     //hexo配置文件
├── node_modules     //node.js运行库
├── package.json
├── scaffolds     //markdown模板
├── source     //资源文件夹
└── themes     //主题
~~~

### 试着运行

~~~ sh
$ hexo server
~~~

用浏览器打开`http://0.0.0.0:4000/`，打开的网页就是hexo所生成的，因为我们还没有进行任何修改，所以打开的是hexo默认的`hello world`![](http://7xqj9r.com1.z0.glb.clouddn.com/hexo-hello%20world.jpg)

hexo编译的时候会出现这样的报错：

~~~ sh
{ [Error: Cannot find module './build/Release/DTraceProviderBindings'] code: 'MODULE_NOT_FOUND' }
{ [Error: Cannot find module './build/default/DTraceProviderBindings'] code: 'MODULE_NOT_FOUND' }
{ [Error: Cannot find module './build/Debug/DTraceProviderBindings'] code: 'MODULE_NOT_FOUND' }
~~~

这是因为`dtrace`模块没有安装成功，按照官方文档所说的，换个姿势重新装一遍hexo即可

~~~ sh
$ npm install hexo --no-optional
~~~

不过我觉得一定会有人像我一样多次重装还是报错（我一定不是一个人，对吧）。出现这个问题是因为我朝GFW，所以单纯地重装可能还是装不上dtrace模块，需要更换一下安装源，换成国内的淘宝镜像就行了（马云爸爸真可爱~）

~~~ sh
$ npm install -g cnpm --registry=https://registry.npm.taobao.org
$ npm install hexo --no-optional
~~~
之后需要重新初始化文件夹，就没有报错了。不过dtrace基本用不上，不管报错继续用也不会有什么问题。

### 新建文章

~~~ sh
hexo new '文章名称'
~~~

之后就会在`source/_posts/`下生成一个文件，文件名就是我么所命名的，后缀为`.md`，因为hexo的博客使用`markdown`语法书写，至于怎么写markdown，之后会介绍的。文章名称不加单引号也可以，不过名称中有空格的时候必须加单引号。

~~~ text
---
title: test
date: 2016-03-05 14:56:52
tags:
---
~~~

打开建好的文章后，会看到上面的字样，分别是标题、日期和标签。注意不要更改标题名称，新建文章的时候hexo根据标题建立了目录，更改了文章文件的标题会导致hexo错误。如果想更换标题，只能删掉重建。标签可以任意添加，便于归类文章，不同的主题对标签的实现方法也不一样。如果想写多个标签，可以这样书写

~~~ text
tags:

- tag1
- tag2
- tag3
~~~

### 主题更换

hexo默认的主题是`landscape`，如果不喜欢可以更换，hexo官网上就有不少漂亮的主题，如果还不满意可以自己修改甚至从头做起。下载好的主题放在`themes`文件夹中，之后在hexo的配置文件`_config.yml`中将`theme`后的名称改成想更改的主题名称即可。主题的配置因主题而异，在主题中同样有一个`_config.yml`文件，是配置主题设置的，不要与hexo的配置文件弄混。

### _config.yml配置文件

hexo的相关配置在这个文件中都可以配置，详细介绍一下

~~~ text
# Hexo Configuration
## Docs: https://hexo.io/docs/configuration.html
## Source: https://github.com/hexojs/hexo/

# Site        //网站基本信息
title: Hexo        //网站名称
subtitle:        //副标题
description:        //描述，会被搜索引擎抓取，分享文章的时候也会显示
author: John Doe        //作者
language:        //语言
timezone:        //时区，留空为系统默认时区

# URL        //网站URL信息
## If your site is put in a subdirectory, set url as 'http://yoursite.com/child' and root as '/child/'
url: http://yoursite.com        //网站URL
root: /        //网站根目录，如果整个博客是一个网站的子目录，需要将根目录改为子目录的名称
permalink: :year/:month/:day/:title/        //每篇文章的URL格式
permalink_defaults:        //默认URL格式

# Directory
source_dir: source
public_dir: public
tag_dir: tags
archive_dir: archives
category_dir: categories
code_dir: downloads/code
i18n_dir: :lang
skip_render:

# Writing
new_post_name: :title.md # File name of new posts        //默认新文章的名字
default_layout: post        //默认文章布局
titlecase: false # Transform title into titlecase
external_link: true # Open external links in new tab        //是否在新标签页打开链接
filename_case: 0
render_drafts: false
post_asset_folder: false
relative_link: false
future: true
highlight:        //代码高亮设置
  enable: true        //代码高亮开关
  line_number: true        //是否显示行号
  auto_detect: false        //是否自动判断语言
  tab_replace:        //用空格替换tab

# Category & Tag        //目录与标签设置
default_category: uncategorized
category_map:
tag_map:

# Date / Time format        //日期设置
## Hexo uses Moment.js to parse and display date
## You can customize the date format as defined in
## http://momentjs.com/docs/#/displaying/format/
date_format: YYYY-MM-DD        //日期格式
time_format: HH:mm:ss        //时间格式

# Pagination
## Set per_page to 0 to disable pagination
per_page: 10        //每页的文章数目
pagination_dir: page        //页面路径

# Extensions        //扩展配置，配置主题以及hexo插件信息
## Plugins: https://hexo.io/plugins/
## Themes: https://hexo.io/themes/
theme: landscape        //主题名称

# Deployment        //发布相关配置，需要安装相应插件
## Docs: https://hexo.io/docs/deployment.html
deploy:
  type:

~~~

### 生成网站文件

~~~ sh
$ hexo generate
~~~

之后会生成一个`public`文件夹，文件夹中的文件即为生成的网页文件。

### 将博客部署到github

按照[github pages] [github pages]的说明配置，申请一个github帐号，之后新建项目，注意项目名称为`用户名.github.io`否则之后是无法访问的，一个账户只能建一个github pages。之后将之前的**public**文件夹里的内容都同步到这个项目的**master**分支，之后浏览器访问`用户名.github.io`就能看到hexo的博客界面了。

连接github同步可以直接使用git命令或者[github客户端] [github desktop]，但是这样都需要hexo generate之后再使用git，还是有些麻烦。[hexo-deployer-git] [hexo git]是hexo的一个插件，可以直接使用hexo命令在生成博客文件后部署到github上。插件的github页面上已经有了详细方法，这里只列出一般情况下的流程。

在此之前最好先检查一下用户目录`~/`上是否已经有ssh密钥文件夹`.ssh`，以免影响之前的使用ssh密钥的应用。这个文件夹是隐藏文件夹，可以直接打开finder使用`command + shift + g`快捷键进入该路径查看，也可以使用终端命令显示隐藏文件：

~~~ sh
$ defaults write com.apple.finder AppleShowAllFiles -boolean true ; killall Finder    //显示隐藏文件
$ defaults write com.apple.finder AppleShowAllFiles -boolean false ; killall Finder    //重新隐藏有隐藏属性的文件
~~~

怕记不住命令就干脆用applescript写成应用吧←_←

- 首先进入到博客文件夹，安装hexo-deployer-git

~~~ sh
$ cd 博客文件夹
$ npm install hexo-deployer-git --save
~~~

然后在博客的配置文件`_config.yml`（注意不是主题中的）中添加

~~~ yml
deploy:
  type: git
  repo:
    github: 博客的git地址
    //gitcafe: 可以像这样部署到多个git服务器上
~~~

git地址在git主页中可以看到，注意选择ssh的地址![](http://7xqj9r.com1.z0.glb.clouddn.com/githubSSH地址.jpg)

因为hexo-deployer-git插件使用ssh方式连接github，所以还要配置ssh，至于什么是ssh以及ssh的原理，可以参考我的[github的ssh key部署及原理分析] [ssh]。

- 设置github信息

~~~ sh
$ git config --global user.name "你的用户名"    //注意加引号
$ git config --global user.email 你的邮箱    //不用加引号
~~~
这个信息就是每次提交到github的时候的用户信息。如果是多帐号（比如公司一个自己一个）就不要用`--global`附加指令了，cd到项目文件夹逐一设置。

- 在本地生成ssh密钥

~~~ sh
$ ssh-keygen -C 注册github所用的邮箱
~~~

这里的邮箱必须是在注册帐号时的邮箱，github和gitcafe的文档都是这么规定的。如果两处的注册邮箱不同，那就再生成一个ssh密钥呗，注意避免重复命名覆盖文件~在命令运行的时候会有几处提示，`Enter file in which to save the key`指的是输入生成密钥的路径，默认是`~/.ssh`，也没必要改，回车跳过；`Enter passphrase`是设置密码，设置后每次使用这对密钥都会要求输入密码，嫌麻烦就回车跳过好了（不过OS X由钥匙串应用，挺方便的ww）。

时候进入`~/.ssh`文件夹（终端里cd进去再ls也可以），可以看到`id_rsa`和`id_rsa.pub`两个文件，分别是私钥和公钥，下面就不用多解释了。此时还没有`know_hosts`文件，使用ssh连接后才会生成。

- 之后读取生成密钥的公钥

~~~ sh
$ car ~/id_rsa.pub
~~~

把显示出来的内容复制下来，然后到github的网页上，进入到设置界面，找到ssh key，新建一个key，那刚才的内容粘贴进去。![](http://7xqj9r.com1.z0.glb.clouddn.com/githubSSH公钥添加.jpg)

- 添加之后测试一下

~~~ sh
$ ssh -T git@github.com
~~~

第一次使用ssh连接github会有提示，输入`yes`即可，之后如果出现`success`的字样说明连接正常，ssh配置成功。

现在就可以使用hexo-deployer-git插件了，方法很简单，`hexo generate`之后，再使用`hexo deploy`就可以自动部署了。

### hexo短命令

hexo支持短命令，使用起来不用输入太长的指令，只列出常用的：

~~~ sh
$ hexo s    //相当于hexo server在本机预览网页
$ hexo g    //相当于hexo generate生成静态网页
$ hexo d    //相当于hexo deploy部署网页到服务器
$ hexo g -d    //hexo generate和hexo deploy的结合
~~~

 至此博客已经可以使用了，不过作为自己的博客还是要好好打理一下

### 域名申请

github会为建成的github pages提供一个`用户名.github.io`的二级域名，不过如果想提升逼格（就像我这样的←_←）的可以绑定自己的域名。因为我朝**严格的审查制度**，国内注册的域名，或者是提供web服务的服务器需要进行备份，备份很麻烦，而且总感觉自己的域名备份后就像是上交国家了一样，所以就别在国内申请域名了。我是在[godaddy] [godaddy]上申请的域名，有中文网页，还支持支付宝，促销活动也挺多。

为了保证域名在国内的解析速度，可以使用国内的DNS解析服务，推荐[DNSPod] [dnspod]的DNS解析，速度快，而且免费的功能也完全足够用。需要到域名注册商更换DNS服务器，更换后需要过一段时间才会生效。之后到dnspod的页面添加DNS记录，添加`cname`记录，记录值即为github pages给我们的二级域名![](http://7xqj9r.com1.z0.glb.clouddn.com/dnspod解析.jpg)

之后要让github接受这个域名解析到自己，在根目录下添加一个名为`CNAME`的文件，内容为我们自己的域名。因为hexo每次`generate`之后会删除掉非`generate`命令生成的文件，CNAME文件不能直接放在public目录下。可以把CNAME文件添加到主题文件夹中的`source`文件夹，每次generate都会把source文件夹的内容拷贝到public文件夹。其他想放在public目录但每次generate会删除的文件也可以放进去。

### 网站分析

用于分析网站流量，我使用的是`Google Analytics`。

首先进入[Google Analytics] [google analytics]，没有Google帐号就注册一个。之后添加自己的域名并认证，添加跟踪代码。跟踪代码的添加与模板有关，基本上模板都会提供相应的接口，模板的文档上应该会有所介绍。

这样就可以清楚的了解到网站的访问信息了。虽然在国内Google的分析代码可以运行，不过Google分析的管理网站在被~~**~~了，所以需要翻墙才能看到分析结果。觉得麻烦可以换用过国内的[百度统计] [baidu analytics]或者[站长统计] [zhanzhang analytics]。![](http://7xqj9r.com1.z0.glb.clouddn.com/Google%20Analytics.jpg)

### 搜索引擎

为了增加网站的曝光率，可以向搜索引擎提供`sitemap`，主动让网站出现在搜索引擎的搜索结果中。关于`sitemap`，可以看看[Google的介绍] [google sitemap]。

首先要生成`sitemap`文件，需要安装[hexo sitemap插件] [hexo sitemap]：

~~~ sh
$ npm install hexo-generator-sitemap --save
~~~

同时hexo配置文件`_config.yml`也要进行修改，添加

~~~ yml
sitemap:
 path: sitemap.xml
~~~

`sitemap`换成其他名字也可以。。。这样再次generate在网站根目录就会生成`sitemap.xml`文件，然后到[Google console] [google console]登录，添加属性，也就是要提交sitemap的网站，验证。使用HTML文件验证即可，添加到网站目录，push到github上就可以了。同`CNAME`文件一样，每次generate会删除验证文件，添加到`source`文件夹即可。之后就是等待Google的爬虫根据站点地图的URL光临博客，建立索引，之后就可以在Google上搜索到我们的博客了。

### 评论功能

主题里肯定都会添加评论功能的接口，国内访问该是用[多说][duoshuo]吧，不同的主题配置方法也有出入，没法详细介绍。

### markdown编辑软件

写文章才是搭建博客的目的，hexo中使用markdown格式书写文章，markdown是什么以及markdown语法，[找篇文章] [markdown]看看就好，上手挺容易的，不过工具的确纠结了一阵子，开源免费的都用过了一遍，随后还是投奔了**sublime text**（别问我花没花钱买），预览问题可以通过安装`OmniMarkupPreviewer`插件解决，用到最后才发现，实时预览只会分散注意力，过分关注实际的渲染效果，没法把精力集中在写作本身了。并且sublime text页用习惯了，干什么都用一个工具也方便。OmniMarkupPreviewer的配置以及sublime text的使用可以参考[这篇文章] [sublime markdown]。

以后就可以安心学习、写文章了呢【笑

[github]:https://github.com
[hexo]:https://hexo.io/zh-cn
[github pages]:https://pages.github.com
[hexo doc]:http://ibruce.info/2013/11/22/hexo-your-blog/
[node js]:https://nodejs.org/en/
[hexo public doc]:https://hexo.io/zh-cn/docs/index.html
[github desktop]:https://desktop.github.com
[hexo git]:https://github.com/hexojs/hexo-deployer-git
[ssh]:/2016/02/08/github的ssh-key部署及原理分析/
[godaddy]:https://sg.godaddy.com/zh/
[dnspod]:https://www.dnspod.cn/Products/DNS
[google analytics]:https://www.google.com/analytics/
[google sitemap]:https://support.google.com/webmasters/answer/156184?hl=zh-Hans
[hexo sitemap]:https://github.com/hexojs/hexo-generator-sitemap
[google console]:https://www.google.com/webmasters
[gitcafe]:https://gitcafe.com
[baidu sitemap]:https://github.com/coneycode/hexo-generator-baidu-sitemap
[duoshuo]:http://duoshuo.com
[markdown]:http://www.jianshu.com/p/q81RER
[sublime markdown]:http://blog.leanote.com/post/54bfa17b8404f03097000000
[next]:http://shino.space/2016/02/08/github的ssh-key部署及原理分析/