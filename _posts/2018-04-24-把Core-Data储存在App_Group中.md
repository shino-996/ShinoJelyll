---
title: 把 Core Data 储存在 App Group 中
date: 2018-04-24 16:25:35 +0800
tags: 
- 计算机
- swift
---

最近又看了一遍 Core Data , 顺便把 app 的数据改为了 Core Data 储存, 虽然数据量并不大. 对于在 App Group 中使用 Core Data, 官方文档好像只说了一句话:

> Use Core Data, SQLite, or Posix locks to help coordinate data access in a shared container.

不同于`UserDefaults`, Core Data 中并没有直接使用 Group Identifier 初始化的方法, 网上资料也很少, 记录一下.

<!-- more -->

---

{:.no_toc}
## 目录

* 目录
{:toc}

## 默认的 Core Data 初始化

如果在创建 target 的时候勾选了 Core Data 选项, xcode 会为我们的项目自动添加上 Core Data 相关的代码, 包括`xcdatamodeld`数据模型文件和 Core Data Stack 初始化相关的代码. `AppDelegate`中会多出一个`persistentContainer`属性:

~~~ swift
lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "test")
    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
        if let error = error as NSError? {
            fatalError("Unresolved error \(error), \(error.userInfo)")
        }
    })
    return container
}()
~~~

使用了一个闭包来初始化这个 lazy 属性, 首先实例化了一个`NSPersistentContainer`, 其中的 name 值是我们创建`xcdatamodeld`的文件名, 系统会根据这个文件所定义的模型来创建数据模型, 然后以这个名字在 Main Bundle 中创建数据文件, 我们进行数据的增删改查时所使用的`NSManagedObjectContext`类由这个`persistentContainer`的`viewContext`属性获得.

可以看出这样创建的 Core Data Stack 只能在 Main Bundle 中建立数据文件, 无法在 App Group 中共享.

## `NSPersistentContainer`隐藏了什么

`NSPersistentContainer`这个类其实是为了使 Core Data 的使用变得更加简单, 它隐藏了很多 Core Data 初始化的细节, 我们来看一下 Core Data Stack 中各个类之间的关系(图片来自于 [Core Data][core data]):

![](/source/2018-04-24-把Core-Data储存在App_Group中_core_data_stack)

从底向上看, 数据的储存形式可以是 sqlite, xml 或者是内存, 我们不会手动创建它们, 而是使用`NSPersistentStore`这个类来进行初始化, 也就是图中的持久化储存.

持久化储存上面一层是持久化储存协调器, 用`NSPersistentCoordinator`类来代表, 它负责协调底层的持久化储存和上层的托管对象上下文, 从持久化储存中取出数据线给上下文, 或者将上下文中的改动储存至持久化储存.

再向上就是我们常用的托管对象上下文和托管对象了, 分别是`NSManagedObjectContext`和`NSManagedObject`, 对托管对象的增删改查都是对托管对象上下文进行操作.

除了这些类, 还有一个`NSManagedObjectModel`, 用于管理托管对象的模型, 我们所创建的`xcdatamodeld`文件就是用于初始化这个类的. 如果想在其他的 target 中也使用同一个模弄文件, 需要在 Target Membership 中勾选想要添加的 target:

![](/source/2018-04-24-把Core-Data储存在App_Group中_target_membership)

## 把 Core Data 存到 App Group 中

这样看来, 涉及到的文件只有两个, 模型文件和数据文件. 模型文件我们可以直接添加到每个 target 中, 而数据文件是使用`NSPersistentSrore`来创建的, 所以就不能使用`NSPersistentContainer`来初始化 Core Data , 需要手动创建整个 Core Data Stack.

~~~ swift
let bundle = Bundle(for: DataManager.self)
let model = NSManagedObjectModel.mergedModel(from: [bundle])!
let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.test.shino.space")!
let url = groupURL.appendingPathComponent("data.data")
try! coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
context.persistentStoreCoordinator = coordinator
~~~

首先是初始化数据模型, 模型文件在项目的 mainbundle 或者是 extension 的 bundle 中, 所以使用`Bundle(for: AnyClass)`来获取, 再使用这个模型来初始化待久化储存协调器. 对于持久化储存, 它的初始化需要提供一个 url, 我们使用 App Group Identifier 创建一个 url 给它, 数据文件的名字为`data.data`. 把创建好的持久化储存赋给持久化储存协调器. 最后我们创建一个托管对象上下文, 把这个上下文赋给持久化储存协调器, Core Data Stack 就设置好了, 我们在这个上下文上进行操作的数据就会保存在 App Group 中

## EX: Core Data是怎么实际储存在设备上的

自己手机越狱装了 Filza, 所以顺便看了看文件具体的储存情况. 我在项目的主项目, today extension 和 watch extension 中都添加了 Core Data , 所以这三个 bundle 中都在模型文件, 路径分别为:

~~~ text
/var/Containers/Bundle/Application/你的 App 文件夹

/var/Containers/Bundle/Application/你的 App 文件夹/Plugins/你的 App Extension 文件夹

/var/Containers/Bundle/Application/你的 App 文件夹/Watch/你的 Watch App 文件夹/Plugins/你的 Watch App Extension 文件夹
~~~

实际储存的模型文件名字不变, 后缀名变为`.momd`.

而数据是存在 App Group 中的, 因为共享, 所以只有一个. 注意现在的 watch app 已经变为了独立的 app, 虽然可以和手机 app 使用一个 group identifier, 但是储存是分开的, 数据储存在手表上. 手机上的 Core Data 数据文件路径如下:

~~~ text
/var/mobile/Containers/Shared/AppGroup/你的 APP 文件夹
~~~

数据文件的名称与定义的名称相同.

[core data]:https://objccn.io/products/core-data/