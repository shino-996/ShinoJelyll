---
title: 将 Core Data 数据文件备份成 sqlite 文件
date: 2018-06-08 16:23:31 +0800
tags: 
- 计算机
- swift
---

额我知道 Core Data 默认就是以 sqlite 文件保存的数据...题目上说的意思是将这个数据文件备份出来给其他的 Core Data 栈使用, 比如我的应用场景是把手机上 Core Data 文件同步到手表 app 上(当然数据量很小才这么干).

<!-- more -->

---

{:.no_toc}
## 目录

* 目录
{:toc}

## 直接用原来的 sqlite 文件不行么

不行, 亲测!

如果进到 Core Data 保存的目录下可以看到, 除了 sqlite 文件之外, 还会有预写式日志文件(.whl)和共享内存文件(.shm), 当前的数据可能还在读写, 或许有些还没有写入 .sqlite 文件, 所以仅仅复制 .sqlite 文件是不可取的, 并且 .whl 和 .shm 文件也不好处理. 最好是可以找到 Core Data 自身的相关 API.

## 用得到的 Core Data API

看向 Core Data 栈的底层, 可以发现`NSPersistentCoordinator`类下有一个`migratePersistentStore(_:to:options:withType:)`方法, 该方法会把传入的`NSPersistentStore`文件复制到所传入的新 URL 的位置, 正是我们想要的 API.

不过这个 API 本来是用于转移数据位置的, 会导致原来的`NSPersistentCoordinator`移掉这个`NSPersistentStore`. 我们想要的功能仅仅是把数据复制一下, 而原来的 Core Data 继续生效, 所以还需要再创建一个临时的`NSPersistentCoordinator`指向这个`NSPersistentStore`.

也就是说, 我们要在一个`NSPersistentStore`上建立两个`NSPersistentCoordinator`, 为了不对原来的 Core Data 产生影响, 并且也没有干预原来数据的必要, 我们要设置这个临时的`NSPersistentcoordinator`对`NSPersistentStore`为只读. 同时像上面说的, .whl 和 .shm 文件不好处理, 所以对于转移后的新文件, 我们要关闭日志功能.

## 问题解决

上代码:

~~~ swift
func backupFile() -> URL {
    // 以只有一个文件为例
    let sourceStore = persistentStores.first!
    // 使用原来的数据模型创建一个临时 NSPersistentCoordinator
    let backupCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
    // 设置下面要添加 NSPersistentStore 的配置, 需要保存证为只读
    let options = (sourceStore.options ?? [:]).merging([NSReadOnlyPersistentStoreOption: true]) { $1 }
    // 将原来的 NSPerstentStore 添加进来, 除了配置之外, 其他参数都使用原来的即可
    let backupStore = try! backupCoordinator.addPersistentStore(ofType: sourceStore.type,
                                                                configurationName: sourceStore.configurationName,
                                                                at: sourceStore.url,
                                                                options: options)
    // 设置下面转移文件的配置, 还是设置为只读, 而且关闭日志, 在转移的时候整理原来的数据碎片
    let backupStoreOptions: [AnyHashable: Any] = [NSReadOnlyPersistentStoreOption: true,
                                                  NSSQLitePragmasOption: ["journal_mode": "DELETE"],
                                                  NSSQLiteManualVacuumOption: true]
    // 提供数据要转换到的 URL
    let url = generateUniqueURL()
    // 转移数据, 并且指定一下保存为 sqlite 文件
    try! backupCoordinator.migratePersistentStore(backupStore,
                                                  to: url,
                                                  options: backupStoreOptions,
                                                  withType: NSSQLiteStoreType)
    return url
}
~~~

最后别放了使用之后处理一下生成和备份文件.
