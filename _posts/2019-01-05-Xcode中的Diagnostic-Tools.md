---
title: Xcode 中的 Diagnostic Tools
date: 2019-01-05 13:42:35 +0800
tags: 
- 计算机
---

好久没更新了, 实习做的是 crash 处理和性能提升有关的东西, 底层和 debug 看得比较多, 以后周末有空更一些.

<!-- more -->

{:.no_toc}
## 目录

* 目录
{:toc}

Xcode 中 scheme 设置里面有一栏 Diagnostics 选项, 方便进行调试, 可以分为代码诊断, 内存管理, 和日志三部分, 从这三个角度分析程序潜在的问题.

![](/source/2019-01-05-Xcode中的Diagnostic-Tools-scheme.png)

## 代码诊断

代码诊断分为地址诊断, 线程诊断和未定义行为诊断, 可以在[苹果官网][xocde]上查看详细说明.

### 地址诊断

用于检查内存使用问题, 可以检查以下类型的代码错误:

- 使用被释放的内存

- 重复释放内存

- 释放未申请过的内存

- 将栈内存做为函数返回值

- 使用离开了作用域的栈内存

- 内存越界

其实现原理为重写了 malloc 和 free 的实现, 内存在使用 malloc 申请之前被标记为禁止使用的, malloc 申请内存后, 申请部分的内存标记为可以使用; free 后内存被重新标记为禁止使用. 进行内存访问时, 会先检查内存是否可以使用. 

### 线程诊断

会检查线程上不安全的行为:

- 数据争用

- 使用未初始化的锁

- 线程泄漏

开启线程诊断后, 每次内存调用都会进行线程安全检查. 安全检查会对上述不安全行为进行检查, 比如每个线程都会保存内存访问时的时间戳, 如果对于同一块内存, 多个线程对其访问的时间戳有重叠且其中有写操作, 就判定为数据争用; 使用锁时会先判断其是否已经初始化; 还会检查不使用的线程是否被正确释放掉.

### 未定义行为诊断
对未定义(不好分类)的行为进行检查, 这些行为的名称不太直观, 所以展开来说明. 不过基本上很少会出现这些问题吧...

- 内存对齐

直接对内存地址进行赋值可能会造成内存不对齐的情况

~~~ C
int_8 *buffer = malloc(64);
int_32 *pointer = (int_32 *)(buffer + 1);
*pointer = 123;
~~~

如果内存是32位对齐, 那么 pointer 是从第8位之后写入一个32位数据, 显然内存没有对齐. 推荐的方法是使用 memset 函数, 在编译过程中发现未对齐内存时会生成优化的汇编指令.

- 无效的 boolean 值

使用 int 作为 boolean 进行判断时, 非零的值代表 true, 但编译器可能会对 boolean 进行优化, 只判断它的最后一位是否为0, 造成了逻辑错误.

- 数组越界

语义上的数组越界检查, 和上面的广义的, 本质上的内存越界检查是有区别的.

- 无效的枚举值

使用 int 来表示 enum 使, int 可能会取到 enum 没有定义的值.

- 跳转到控制流之外

比如 switch 语句中的所有 case 都没有命中

- 动态类型错误

~~~ cpp
struct Animal {
    virtual const char *speak() = 0;
};
​
struct Cat: public Animal {
    const char *speak() {
        return "nya";
    }
};
​
struct Dog: public Animal {
    const char *speak() {
        return "woof";
    }
};
​
auto *dog = reinterpret_cast<Dog *>(new Cat);
dog->speak();
~~~

reinterpret_cast 进行了无关类型之间的类型转换, 上面这种不正当地使用多态可能会引起难以预测的行为.

- 浮点数溢出

- 0作除数

- nonnull 相关的检查

- 空指针引用和调用

- 不正确的对象大小

~~~ cpp
struct Base {
    int pad;
};
​
struct Derived: Base {
    int pad2;
};
​
Derived *getDerived() {
    return static_cast<Derived *>(new Base);
}
~~~

还是多态使用的问题, getDerived 返回的指针指向的内存比 Derived 类型所占的内存要小, 当调用 getDerived()->pad2 时会发生错误.

- 左移溢出

- 整型溢出

上述问题并不都会发生错误, 开启了未定义行为诊断后使得代码检查变得更为严格.

地址诊断, 线程诊断, 未定义行为诊断都会在编译阶段增加了额外的代码和检查, 所以勾选后要重新编译.

###主线程检查

会检查 AppKit, UIKit 和其他与 UI 有关的操作是否都在主线程进行, 检查是在 runtime 中进行的, 不需要重新编译, 而且性能损耗较少, 默认是开启的.

## 内存管理

### malloc 填充

已申请的内存填充为 0xAA, 未申请和释放掉的内存填充为 0x55

### malloc 保护页

在申请的大块内存前后会加上保护页, 防止内存越界

### malloc 保护

进行越界的内存读写时, 会直接触发 crash

### 僵尸对象

开启后释放掉的内存只会被标记为僵尸对象, 不会被系统回收, 程序调用被释放的内存时会发生 crash, 打印错误日志.

开启了 malloc 保护页和僵尸对象后, 内存占用会上升, 与实际程序占用内存不符, 所以这勾选这两个选项后, 调试界面的内存占用将不会显示内存占用情况.

##日志

### malloc 调用栈

会记录每一次 malloc 时的函数调用, Debug Memory Tool 使用.

![](/source/2019-01-05-Xcode中的Diagnostic-Tools-malloc-history.png)

启用后, 调试时点击 Debug Memory Tool 后, 右侧可以查看内存 malloc 时的调用栈信息. 除此之外, 使用模拟器调试时, 可以使用命令行工具(不是 lldb 中)malloc_history 查看对应 pid(可以在 xcode log 中找到), 来查看 malloc 调用栈日志.

### 动态链接器 API 调用

开启后可以在 xocde 中输出动态链接器 API 的调用日志

### 动态链接器库加载

开启后可以在 xocde 中输出 dyld 加载动态链接库的日志

[xcode]: https://developer.apple.com/documentation/code_diagnostics?language=objc