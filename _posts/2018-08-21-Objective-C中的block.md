---
title: Objective-C 中的 block
date: 2018-08-21 22:08:58 +0800
tags: 
- 计算机
- objc
---

看完了 swift 中的闭包, 自然又重新看了一下 Objective-C 中的 block, 之前因为没写过, 所以浏览一遍就过去了, 现在发现了解一下实现对于理解 swift 有很大的好处, 毕竟 swift 简化了太多底层的东西.

<!-- more -->

---

{:.no_toc}
## 目录

* 目录
{:toc}

block 其实并不是 Objective-C 的语法, 而是苹果对于C语言的扩充, 所以完全可以在C文件中写 block, 然后使用 clang 来编译:

~~~ sh
$ clang block.c -o block
~~~

编译通过, 而且正常运行. 虽然 swift 不像 objc 是翻译成 C 再编译的, 但关于 block 与闭包的思想是相近的.

## block 的基本形式

只考虑函数特性的话, block 与函数指针的形式基本一致

~~~ objc
// 函数指针
// 声明
void (*foo)(void);
// 使用
foo();
(*foo)();
// 数组
void (*foo[5])(void);
// 作为函数参数, bar 为函数名, param 为作为参数的函数指针
void bar(void (*param)(void)) { }
// 作为函数返回值, foo 为函数名
void (*foo(void))(void) { }

// block
// 声明
void (^block)(void);
// 使用
block();
// 数组
void (^block[5])(void);
// 作为函数参数
void bar(void (^param)(void)) { }
// 作为函数返回值
void (^foo(void))(void) { }
~~~

因为 block 并不是指针, 所以调用 block 时不可以像函数指针一样使用`*`, 其他形式与函数指针都是一致的. 当然, 为了便于读写, 一般会使用`typedef`简化, 上面把 block 作为返回值的函数如果这样写会看起来会方便很多

~~~ objc
typedef void (^block)(void);
block foo(void) { }
~~~

定义 block 时, 返回值可以跟据 block 内容推断出来, 所以可以省略, 而参数列表为空时, 也可能省略

~~~ objc
void (^block)(void) = ^void (void) {
    // something
}

void (^block)(void) = ^ {
    // something
}
~~~

上面两个 block 的定义是等价的.

## block 的值捕获

和函数指针不同的是, block 可以捕获外部的值, 在C语言中, 变量按照储存方式分为全局变量, 全局静态变量, 局部静态变量, 自动变量, block 对它们的捕获方式如下:

- 对于全局变量和所有静态变量, block 以引用的形式进行捕获
- 对于自动变量, block 进行值捕获, 即复制自动变量的副本

~~~ objc
int global = 0;
static int static_global = 10;

void foo() {
    static int static_local = 100;
    int local = 1000
    void (^block)(void) ^ {
        cout << global << ", " << static_global << ", " << static_local << ", " << local << endl;
    };
    ++global;
    ++static_global;
    ++static_local;
    ++local;
    block();
}
~~~

运行`foo()`后, 除了`local`之外, 其他变量都为原来值加一, 因为只有自动变量没有进行值引用. 在 block 中, 自动变量是复制到 block 中进行储存的, 而其他种类的变量以指针的形式进行调用. 同时, 复制到 block 中的自动变量无法修改, 如果要用 block 修改外部的自动变量, 可以在声明自动变量时, 使用`__block`标识符:

~~~ objc
__block int local = 10;

void (^block)(void) ^ {
    ++local;
}
~~~

这样就可以修改外部的自动变量`local`. 可以看出, swift 中的闭包默认的捕获行为与自动变量加了`__block`的 block 相同.

## block 也是对象

和上一篇 swift 中的闭包一样, 也就是说 block 也是引用类型, 同样可能会发生循环引用问题, 原理和处理方式同闭包类似, 不过多介绍了.

## block 储存方式

在C语言中, 存储区分为字面区, 全局区, 栈区和堆区, 字面区储存的都是常量所以不能储存 block, 不过其他位置都可以, 也就是说 block 有三种储存形式, 全局block(`_NSConcreteGlobalBlock`), 栈block(`_NSConcreteStackBlock`)和堆block(`_NSConcreteMallocBlock`). 分辨规则如下:

- 没有使用外部捕获的自动变量的 block 均为全局block
- 其他情况定义的 block 类型与相应位置定义的变量类型一致

国为栈block在离开作用域后会和栈变量一样释放内存, 所以在非 ARC 环境下涉及栈block的赋值要小心处理.

## ARC 下的 block

上面提了非 ARC 环境下栈block可能会出现空指针问题, 也就是说 ARC 会对block对象进行其他处理. 在 objc 中, 可以调用`[block copy]`创建一个堆block, 对于栈block, 调用`copy`方法会将它复制到堆上, 而对于堆block, 调用`copy`方法不会再进行复制, 而只是将引用计数加一.

和自动插入`retain`, `release`一样, ARC 会适当地在代码中插入`copy`, 当把栈block赋值给强引用对象(`__strong`)或者作为函数返回值时, 会自动进行 cpoy, 在调用 gcd 之类的 cocoa 框架时, 也会复制 block. 考虑下面的例子:

~~~ objc
void (^block[5])(void);

for (int i = 0; i < 5; ++i) {
    block[i] = ^ {
        cout << i + 1 << endl;
    };
}

for (int i = 0; i < 5; ++i) {
    block[i]();
}
~~~

在 MRC 下, 输出值是五排`5`, 并且因为栈block实际已经释放了, 只是那块内存还没有被使用上, 所以没报错. 而在 ARC 下, 因为数组`block`默认是强引用对象, 所以在第一个循环中会将栈block复制到堆上再赋给`block`数组, 输出结果就是`1 2 3 4 5`.

## block 的实现

了解 block 的实现对理解 block 行为有很大帮助, 使用 clang 可以将含 block 的代码转换成 C++ 源码, 可以从中看出 block 的具体实现. 不过我这里就不看了, 定性了解就好orz

### block 本质是对象

上面也说了, 这很好理解, block 对象中也包含了捕获的自动变量, 没有使用的变量不会出现在对象中. 因为实际上 objc, C++ 的类都可以翻译成C语言的结构体, block 也不例外, 所以 block 的调用实际上也是类似于函数指针一样的调用.

### block 捕获的变量

block 使用值复制的方式捕获自动变量, 使用指针方式捕获静态变量和全局变量, 在自动变量声明前加入`__block`后, 自动变量的声明也会变成结构体, 也就是原来的自动变量也变成了一个对象, block 中包含对这个对象的引用, 这样就可以在 block 中修改外部的自动变量.

### block 的复制

调用`copy`方法会复制 block, 那么在对栈block进行复制时, 会在栈和堆上出现两个一样的 block, 如何判断调用时使用哪个 block? 在 block 结构体中, 有一个`__forwarding`变量, 它通常指向 block 自身, 在对栈block复制时, 栈block的`__forwarding`会指向堆block, 这样就能保证任何时候都可以访问同一个 block.

### block 中对象的所有权

在引用计数中, A 对 B 的所有权代表 A 是否会改变 B 的引用计数. 看一个在 ARC 环境下的例子:

~~~ objc
void (^block)(id);
{
    id array = [[NSMutableArray alloc] init];
    block = ^(id object) {
        [array addObject: object];
        cout << "array count: " << [array count] << endl;
    };
}
block([[NSObject alloc] init]);
block([[NSObject alloc] init]);
block([[NSObject alloc] init]);
~~~

输出为:

~~~ text
array count: 1
array count: 2
array count: 3
~~~

正常情况`array`在离开作用域后会立刻析构, 但上面的例子看起来是在`block`未析构时, `array`也未析构. 首先`array`是自动变量, 可以看作是一个`NSMutableArray`的指针, 在`block`捕获它时, 是进行值复制的. `array`是默认的强引用类型, 所以有复制的时候, 复制的值也是强引用, 也就是说在捕获的同时, `block`也拥有了`array`的所有权, 所以即使当`array`离开作用域 release 之后, `block`扔持有`array`指向的`NSMutableArray`. 如果在`array`前加入`__block`也一样, 只不过可以进一步修改`array`的指向.

注意的是 block 对对象的持有是对于强引用的, 对于弱引用, 为了不破坏弱引用的意义, block 不会持有弱引用所指向的对象. 比如下面的输出就都是0:

~~~ objc
void (^block)(id);
{
    id array = [[NSMutableArrayalloc] init];
    id __weak weakArray = array;
    block = ^(id object) {
        [weakArray addObject: object];
        cout << "array count: " << [weakArray count] << endl;
    };
}
block([[NSObject alloc] init]);
block([[NSObject alloc] init]);
block([[NSObject alloc] init]);
~~~