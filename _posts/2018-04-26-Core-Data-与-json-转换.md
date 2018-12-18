---
title: Core Data 与 json 转换
date: 2018-04-26 13:18:52 +0800
tags: 
- 计算机
- swift
---

进行网络请求时还是 json 格式使用最多, swift 4 中新添加的`Codable`协议使得自定义格式与 json 转换更加方便, 不过因为 Core Data 中的`NSManagedObject`类的一些小问题, 不能直接遵守`Codable`协议, 所以分享一下自己的方法.

<!-- more -->

---

{:.no_toc}
## 目录

* 目录
{:toc}

## 要使用的`NSManagedObject`类

就拿我正在写的课程表的数据模型来举例吧, 定义了下面两个`NSManagedObject`类:

~~~ swift
final class CourseData: NSManagedObject {
    @NSMananaged var name: String
    @NSManaged var teacher: String
    @NSManaged var time: Set<TimeData>?
}

final class TimeData: NSManagedObject {
    @NSManaged var place: String
    @NSManaged var startseciton: Int64
    @NSManaged var endsetion: Int64
    @NSManaged var week: Int64
    @NSManaged var teachweek: [Int64]
    @NSManaged var course: CourseData
}
~~~

就是常见的课程表数据类型, 课程与上课时间建立了一对多关系. 分成两个类一方面是因为按照上课时间排课程表, 或者显示课程详情; 另一方面也方便通过关系找到对应上课时间的课程信息. 课程类中上课时间属性是可选值, 因为有的课程可能没有上课时间.

## json 格式

因为网络 api 也是我写的, 所以格式和上面基本差不多:

~~~ json
{
    "name": "操作系统",
    "teacher": "teacher"
    "time": [
    {
        "place": "综一 156",
        "startsection": 3,
        "endsection": 4,
        "week": 2,
        "teachweek": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
    },
    {
        "place": "综一 156",
        "startsection": 5,
        "endsection": 6,
        "week": 5,
        "teachweek": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
    }]
}
~~~

课程名与上课时间写在了一起, 并且上课时间是一个数组, 不是上面类中定义的集合.

## 自定义需要与 json 互相转换的键值

可以看到`CourseData`与`TimeData`中都有代表关系的属性, 在与 json 互相转换的过程中不需要包含这两个属性. 而且因为`@NSManaged`的关系, 直接遵守`Codable`属性后也不会转换被它标记的属性, 所以要手动定义哪些属性需要被转换.

`Codable`协议中默认实现了`CodingKey`协议的枚举, 为所有的储存属性添加了键值, 因为上面提到的原因, 现在我们要手动定义这个枚举:

~~~ swift
// CourseData
enum CodingKeys: String, CodingKey {
    case name
    case teacher
    case time
}

// TimeData
enum CodingKeys: String, CodingKey {
    case place
    case startsection
    case endsection
    case week
    case teachweek
}
~~~

需要注意的是目前`Codable`协议无法应用到类的 extension 中, 所以只能在类定义内添加协议要求的方法. 在文章的最后我会放上完整的类定义代码.

## 定义编码

`Codable`协议由`Encodable`和`Decodable`两个协议组成, 分别对应着编码和解码, 我们先来看编码. 编码要求我们实现`encode(to encoder: Encoder) throws`方法. 因为`CourseData`中包含`TimeData`对象, 所以我们先实现`TimeData`的编码:

~~~ swift
// TimeData
func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try! container.encode(place, forKey: .place)
    try! container.encode(startsection, forKey: .startsection)
    try! container.encode(endsection, forKey: .endsection)
    try! container.encode(week, forKey: .week)
    try! container.encode(teachweek, forKey: .teachweek)
}
~~~

首先我们以刚才定义的键值从`encoder`中取得一个`container`, `container`中应该包含键值和其对应的值, 接着我们调用`container`的`encode`方法为每个键赋值, 因为`TimeData`中每个要编码的属性都是可编码的, 所以直接赋值即可. 为了举例方便, 我没有对可能出现的异常进行处理.

对于`CourseData`因为刚定义好`TimeData`的编码方法, 所以`CourseData`中的属性也都可以直接进行编码了:

~~~ swift
// CourseData
func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try! container.encode(name, forKey: .name)
    try! container.encode(teacher, forKey: .teacher)
    if let time = time {
        let timeArray = Array(time)
        try! container.encode(timeArray, forKey: .time)
    }
}
~~~

如果可选值为 nil, 根据 json 的语法, 对应的键也应该没有. 在 Core Data 中关系的储存方式为集合类型, 在转换成 json 的时候要记得转换为数组.

现在我们可以直接使将这两个类转换为 json:

~~~ swift
let encoder = JSONEncoder()
let jsonData = try! encoder.encode(courseData)
let json = String(data: jsonData, encoding: .utf8)!
~~~

## 定义解码

解码协议`Decodable`要求实现指定初始化器`init(from decoder: Decoder) throws`, 但是`NSManagedObject`有两个指定初始化器, 要想再定义其他的初始化器必须调用这两个其中的一个, 所以需要使用一些技巧:

~~~ swift
// TimeData
static var context: NSManagedObjectContext!

required convenience init(from decoder: Decoder) throws {
    self.init(entity: "TimeData", insertInto: TimeData.context)
    let container = try! decoder.container(keyedBy: CodingKeys.self)
    place = try! container.decode(String.self, forKey: .place)
    startsection = try! container.decode(Int64.self, forKey: .startsection)
    endsection = try! container.decode(Int64.self, forKey: .endsection)
    week = try! container.decode(Int64.self, forKey: .week)
    teachweek = try! container.decode([Int64].self, forKey: .teachweek)
}
~~~

为了调用指定初始化器, 我们定义一一个便利初始化器, 为了传入寝室初始化器所需要的参数, 定义了一个类变量. 不过这样做会导致使用这个初始化器之前必须先修改类变量, 为了实现从 json 初始化, 也只能这么做了. 接着还是取出一个`container`不过这次是从里面解码出数据.

对于`CourseData`, 注意取出的`TimeData`不能直接添加到集合中, 集合是为了表示 Core Data 中的一对多关系, 由 Core Data 维护, 直接修改会导致 Core Data 错误, 正确的做法是把`CourseData`添加到每一个`TimeData`的对单关系中:

~~~ swift
// CourseData
static var Context: NSManagedObjectContext!

required convenience init(from decoder: Decoder) throws {
    self.init(entity: "CourseData", insertInto: CourseData.context)
    let container = try! decoder.container(keyedBy: CodingKeys.self)
    name = try! container.decode(String.self, forKey: .name)
    teacher = try! container.decode(String.self, forKey: .teacher)
    TimeData.context = CourseData.context
    if let timeArray = try? container.decode([TimeData].self, forKey: .time) {
        _ = timeArray.map { $0.course = self }
    }
}
~~~

## 更像 Core Data 地调用

这样我们就完成对`Codable`协议的实现, 不过还需要再封装一下解码方法, 因为在插入一个`NSManageObject`的时候要指定`NSManageObjectContext`, 直接调用`init(from decoder: Decoder)`方法可能导致忘记先给`context`赋值而发生程序错误. 所以我们再定义一个`ManagedObject`协议, 规定一下和 json 转换的接口:

~~~ swift
protocol ManagedObject where Self: NSManagedObject {
    static var entityName: String { get }

    static var viewContest: NSManagedObjectContext { get set }

    static func insertNewObject(from json: String, into context: NSManagedObjectContext) -> Self
    
    func exportJson() -> String
}

extension ManagedObject where Self: Codable {
    static func insertNewObject(from json: String, into context: NSManagedObjectContext) -> Self {
        let decoder = JSONDecoder()
        let jsonData = json.data(using: .utf8)!
        Self.viewContext = context
        let newObject = try! decoder.decode(Self.self, from: jsonData)
        return newObject
    }

    func exportJson() -> JSON {
        let encoder = JSONEncoder()
        let jsonData = try! encoder.encode(self)
        let json = String(data: jsonData, encoding: .utf8)!
        return json
    }
}
~~~

定义一下`entityName`是为了避免硬编码字符串, 不方便修改程序. 导出 json 的方法也没什么需要解释的. 从 json 新建一个`NSManagedObject`需要调用`insertNewObject(from json: String, into context: NSManagedObjectContext)`方法, 传入一个 json 的要添加到的context. 因为没什么需要在类中自定义的, 就使用协议扩展实现了默认实现.

提一下`viewContext`属性, 因为`Codable`只能在类定义中实现, 所以类定义中必须包含一个`context`属性. 在协议中不能调用协议中未定义的属性, 所以只好额外定义一个`viewContext`属性. 如果以后`Codable`可以应用在 extension 中, 那就可以直接让`ManagedObject`协议遵守`Codable`, 也不用这么折腾了.

两个类对协议的实现如下:

~~~ swift
// TimeData
static var entityName: String {
    return "TimeData"
}

static var viewContext: NSManagedObjectContext {
    get { return context }
    set { context = newValue }
}

// CourseData
static var entityName: String {
    return "CourseData"
}

static var viewContext: NSManagedObjectContext {
    get { return context }
    set { context = newValue }
}
~~~

最后放一下两个类的完整定义:

~~~ swift
final class CourseData: NSManagedObject, Codable {
    fileprivate static var context: NSManagedObjectContext!
    
    @NSManaged var name: String
    @NSManaged var teacher: String
    @NSManaged var time: Set<TimeData>?
    
    enum CodingKeys: String, CodingKey {
        case name
        case teacher
        case time
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try! container.encode(name, forKey: .name)
        try! container.encode(teacher, forKey: .teacher)
        if let time = time {
            let timeArray = Array(time)
            try! container.encode(timeArray, forKey: .time)
        }
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init(entity: CourseData.entity(), insertInto: CourseData.context)
        let container = try! decoder.container(keyedBy: CodingKeys.self)
        name = try! container.decode(String.self, forKey: .name)
        teacher = try! container.decode(String.self, forKey: .teacher)
        TimeData.context = CourseData.context
        if let timeArray = try? container.decode([TimeData].self, forKey: .time) {
            _ = timeArray.map { $0.course = self }
        }
    }
}

extension CourseData: ManagedObject {
    static var viewContext: NSManagedObjectContext {
        get { return context }
        set { context = newValue }
    }
    
    static var entityName: String {
        return "CourseData"
    }
}

final class TimeData: NSManagedObject, Codable {
    fileprivate static var context: NSManagedObjectContext!
    
    @NSManaged var place: String
    @NSManaged var startsection: Int64
    @NSManaged var endsection: Int64
    @NSManaged var week: Int64
    @NSManaged var teachweek: [Int64]
    @NSManaged var course: CourseData
    
    enum CodingKeys: String, CodingKey {
        case place
        case startsection
        case endsection
        case week
        case teachweek
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try! container.encode(place, forKey: .place)
        try! container.encode(startsection, forKey: .startsection)
        try! container.encode(endsection, forKey: .endsection)
        try! container.encode(week, forKey: .week)
        try! container.encode(teachweek, forKey: .teachweek)
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init(entity: TimeData.entity(), insertInto: TimeData.context)
        let container = try! decoder.container(keyedBy: CodingKeys.self)
        place = try! container.decode(String.self, forKey: .place)
        startsection = try! container.decode(Int64.self, forKey: .startsection)
        endsection = try! container.decode(Int64.self, forKey: .endsection)
        week = try! container.decode(Int64.self, forKey: .week)
        teachweek = try! container.decode([Int64].self, forKey: .teachweek)
    }
}

extension TimeData: ManagedObject {
    static var viewContext: NSManagedObjectContext {
        get { return context }
        set { context = newValue }
    }
    
    static var entityName: String {
        return "TimeData"
    }
}
~~~