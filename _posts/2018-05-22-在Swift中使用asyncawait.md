---
title: 在 Swift 中使用 async/await
date: 2018-05-22 13:06:23 +0800
tags: 
- 计算机
- swift
---
用 nodejs 写了点东西才发现入理异步不仅仅是 Promise 这点东西, 在 ES7 标准中, async/await 的引入使得可以像写同步代码一样写异步. 虽然 Swift 目前没有在语言层面上支持 Promise 和 async/await, 不过有 [PromiseKit][promisekit] 和 [AwaitKit][awaitkit] 这样的库来简化我们的异步代码.

<!-- more -->

---

{:.no_toc}
## 目录

* 目录
{:toc}

## 接下来一直用这个例子

比如我们要登录网站取得用户的信息, 需要三个步骤:

- 取得登录 token

- 登录通过用户验证

- 取得信息

~~~ swift
let url = URL(string: "https://theurl.com")!
URLSession.shared.dataTask(with: url) { data, _, error in
    if let error = error {
        print(error)
        return
    }
    guard let data = data else {
        return;
    }
    let token = fetchToken(data)
    let request = URLRequest(from: token)
    URLSession.shared.dataTask(with: request) { data, _, error in
        if let error = error {
            print(error)
            return
        }
        guard let data = data else {
            return;
        }
        let auth = fetchAuth(data)
        let request = URLRequest(from: auth)
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print(error)
                return
            }
            guard let data = data else {
                return;
                let info = fetchInfo(data);
                print(info);
            }
        }.resume()
    }.resume()
}.resume()
~~~

一共进行了三次异步请求, 因为每一步都需要上一步的数据, 所以只能把下一步的请求放在上一步请求的回调闭包中.

## 使用 Promise 解开嵌套闭包

在刚接触 Promise 的时候就写过一篇相关的[文章][promise], 主要是讲 Promise 内部是怎么把嵌套调用变成链式调用的, 这里主要讲一下 Promise 的思想.

在异步调用的回调函数中, 我们要处理两种情况: 回调成功和失败, 如果回调成功, 回调函数中应该会有一个我们希望得到的一个传入参数; 失败的话会传入一个`Error`. 也就是说, 回调函数的传入参数可以是一个枚举:

~~~ swift
enum result {
    case success(WishType)
    case failed(Error)
}
~~~

Promise 把这个过程封装了起来, 它允许传入两个函数, 对应着回调成功和失败, 两个函数的参数分别是`WishType`和`Error`. 这两个函数是 Promise 生成的, 在使用过程用我们跟据调用是否成功来选择调用哪一个. 使用`then`函数可以向 Promise 添加新的异步调用, 对应着回调`fullfill`函数, 并再返回一个 Promise. 使用`catch`函数相当于传入了一个`rejected`函数, 进行错误处理.

`then`与`catch`的函数类型和`fullfill`与`rejected`的并不一样, Promise 内部实现了它们之前的转换. 需要注意的是, 并不是`then`函数触发了异步调用的开始, Promise 实例化的时候, 异步调用就已经开始了, `then`和`catch`只是指写了当 Promise 调用成功或失败后, 下一步应该做什么.(这制杖的语法高亮还把catch标红了...)

~~~ swift
struct Promise<WishType> {
    init(resolver: (_ fullfill: @escaping(WishType) -> Void, _ rejected: @escaping(Error) -> Void) -> Void) {
        ......
    }

    func then<NextType>(_ body: (WishType) -> NextType) -> Promise<NextType> {
        ......
    }

    func `catch`(_ body: (Error) -> Void) {
        ......
    }
}
~~~

使用 Promise, 就可以把上面例子中的多层嵌套解开了:

~~~ swift
let url = URL(string: "https://theurl.com")!
Promise<Data> { resolver in
    URLSession.shared.dataTask(with: url) { data, _, error in
        if let error = error {
            resolver.rejected(error)
        }
        if let data = data {
            resolver.fullfill(data)
        }
    }.resume()
}.then { data in
    let token = fetchToken(data)
    let request = URLRequest(from: token)
    return Promise<Data> { resolver in
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                resolver.rejected(error)
            }
            if let data = data {
                resolver.fullfill(data)
            }
        }.resume()
    }
}.then { data in
    let auth = fetchAuth(data)
    let request = URLRequest(fron: auth)
    return Promise<data> { resolver in
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                resolver.rejected(error)
            }
            if let data = data {
                resolver.fullfill(data)
            }
        }.resume()
    }
}.then { data in
    let info = fetchInfo(data)
    print(info)
}.catch { error in
    print(error)
}

~~~

可以看到之前的多重嵌套回调已经变成了链式的函数调用. 额, 变得这么长是因为定义 Promise 的写了不少...如果使用 PromiseKit, `URLsession`这处常用的异步函数都已经封装好了 Promise, 这里手动定义是为了更好地理解 Promise.

## 使用 async/await 把 Promise 变成同步代码

虽然 Promise 使得异步调用不必写多重嵌套回调, 不过这种链式函数调用的方式还是和一般的同步执行代码有一定的区别, 我们最终希望可以变成这样的同步形式的代码:

~~~ swift
let url = URL(string: "https://theurl.com")!
let tokenData = URLSession.shared.dataTask(with: url).resume()
let token = fetchToken(tokenData)
let authData = URLSession.shared.dataTask(with: URLRequest(from: tkoen)).resume()
let auth = fetchAuth(authData)
let infoData = URLSession.shared.dataTask(with: URLRequest(from: auth)).resume()
let info = fetchInfo(infoData)
print(info)
~~~

借助 AwaitKit, 我们真的可以以这种形式来写异步代码. async/await 是基于 Promise 的, `async`其实就是对 Promise 进行了封装, 可以更方便地定义 Promise:

~~~ swift
func tokenPromise(_ url: URL)throws -> Promise<Data> {
    return async {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                throw error
            }
            return data!
        }.resume()
    }
}

func authPromise(_ request: URLRequest)throws -> Promise<Data> {
    return async {
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                throw error
            }
            return data!
        }.resume()
    }
}

func infoPromise(_ request: URLRequest)throws -> Promise<Data> {
    return async {
        URLSession.shared.dataTask(with request) { data, _, error in
            if let error = error {
                throw error
            }
            return data!
        }.resume()
    }
}
~~~

再使用`await`函数把异步函数变为同步函数, 写出同步形式的代码:

~~~ swift
let url = URL(string: "https://theurl.com")!
do {
    let tokenData = try await(tokenPromise(url))
    let token = fetchToken(tokenData)
    let authData = try await(authPromise(URLRequest(form: token)))
    let auth = fetchAuth(authData)
    let infoData = try await(infoPromise(URLRequest(from: auth)))
    let info = fetchInfo(infoData)
    print(info)
}.catch(let error) {
    print(error)
}
~~~

可以看到调用异步函数, 处理异常都变成了同步的方式.

`await` 内部实现使用了信号量来阻塞线程, 使得异步调用结束之前当前线程不会向下运行: 

~~~ swift
func await<T>(_ promise: Promise<T>)throws -> T {
    let queue = DispatchQueue(label: "await.asyncqueue", attributes: .concurrent)
    let semaphore = DispatchSemaphore(value: 0)
    let result: T?
    let error: Error?
    promise.then(on: queue) {
        result = $0
        semaphore.signal()
    }.catch(on: queue) {
        error = $0
        semaphore.signal()
    }
    _ = semaphore.wait(timeout: .distabtFuture)
    guard let result = result else {
        throw error!
    }
    return result
}
~~~

使用了数值为0的信号量阻塞当前线程, 创建了一个后台线程来运行异步调用, 异步回调运行结束的时候再解开信号量. 要注意的是这里并没有用 PromiseKit 中的`ensure`函数保证`semaphore.signal()`的运行, 是因为`ensure`会在`catch`之前运行, 这样会使得线程在`catch`之前就解除阴塞, 无法正常抛出错误.

因为 Swift 对于解决回调地狱还没有语言层面上的支持, Promise 还好, async/await 这种还只能使用函数而不是关键字的方式来实现, 不过在未来的 Swift 5 中有望得到原生的支持.

[promisekit]: https://github.com/mxcl/PromiseKit
[awaitkit]: https://github.com/yannickl/AwaitKit
[promise]: https://shino.space/2017/使用函数式swift解决回调地狱
