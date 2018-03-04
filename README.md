# Promise

[![swift][swift-badge]][swift-url]
![platform][platform-badge]
[![build][travis-badge]][travis-url]
[![codecov][codecov-badge]][codecov-url]
![license][license-badge]

[swift-url]: https://swift.org
[swift-badge]: https://img.shields.io/badge/Swift-3.1%20%7C%204.0-orange.svg?style=flat
[platform-badge]: https://img.shields.io/badge/Platforms-Linux%20%7C%20macOS%20%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-lightgray.svg?style=flat
[travis-badge]: https://travis-ci.org/nfam/promise.swift.svg
[travis-url]: https://travis-ci.org/nfam/promise.swift
[codecov-badge]: https://codecov.io/gh/nfam/promise.swift/branch/master/graphs/badge.svg
[codecov-url]: https://codecov.io/gh/nfam/promise.swift/branch/master
[license-badge]: https://img.shields.io/github/license/nfam/promise.swift.svg

> An minimal Promise Library for Swift.

## Table of Contents
- [Install](#install)
- [API](#api)
    * [Creating a `Promise`](#creating-a-promise)
        + [Promise((resolve,reject))](#promise-resolve-reject)
        + [Promise(return)](#promise-return)
        + [Promise(value)](#promise-value)
        + [Promise(error)](#promise-error)
    * [Type Methods](#type-methods)
        + [Promise.all](#promis-eall)
        + [Promise.race](#promise-race)
    * [Instance Methods](#instance-methods)
        + [promise.then](#promise-then)
        + [promise.catch](#promise-catch)
        + [promise.finally](#promise-finally)

---


## Install
```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/nfam/promise.swift.git", majorVersion: 0)
    ]
)
```

## API
API is similar to the standard Promise in [JavaScript](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise).

### <a id="creating-a-promise"></a> Creating a `Promise`
---
#### <a id="promise-resolve-reject"></a> Promise((resolve,reject))
Creates a `Promise` with a closure that is passed two callback closure parameters to fulfill or reject the `Promise`.
The `body` initiates some *asynchronous* work, and then, once that completes,
either calls the first or second callback closure parameters to fulfill or
reject the promise, respectively.
If an error is thrown in the `body`, the `Promise` is rejected.
```swift
init<T>(
    in queue: DispatchQueue? = nil,
    execute body: ((T) -> Void, (Error) -> Void) -> Void
)
```

#### <a id="promise-return"></a> Promise(return)
Creates a `Promise` with a closure that returns a value to fulfill the `Promise`.
The `body` initiates some *asynchronous* work, and then, once that completes,
returns a value to fulfill the promise.
If an error is thrown in the `body`, the `Promise` is rejected.
```swift
init<T>(
    in queue: DispatchQueue? = nil,
    execute body: () throws -> T
)
```

#### <a id="promise-value"></a> Promise(value)
Creates a `Promise` that is fulfilled with a given value.
```swift
init<T>(in queue: DispatchQueue? = nil, value: T)
```

#### <a id="promise-error"></a> Promise(error)
Creates a `Promise` that is rejected with a given error.
```swift
init(in queue: DispatchQueue? = nil, error: Error)
```

### <a id="type-methods"></a> Type Methods
---

#### <a id="promise-all"></a> Promise.all
Returns a `Promise` that either fulfills when all of the promises
in the iterable parameter have resolved, or rejects as soon as one
of the promises in the iterable parameter rejects.
```swift
Promise.all<S>(resolved promises: S) -> Promise<[T]> where S: Sequence, S.Iterator.Element == Promise
Promise.all(_ promises: Promise<T>...) -> Promise<[T]>
```

#### <a id="promise-race"></a> Promise.race
Returns a `Promise` that fulfills or rejects as soon as one of
the promises in the iterable fulfills or rejects, with the value or
reason from that `Promise`.
```swift
Promise.race<S>(promises: S) -> Promise<T> where S: Sequence, S.Iterator.Element == Promise
Promise.race(_ promises: Promise<T>...) -> Promise<T>
```

### <a id="instance-methods"></a> Instance Methods
---

#### <a id="promise-then"></a> promise.then
Appends fulfillment and/or rejection closures to the `Promise`, and returns a new `Promise`
resolving to the return value of the either executed closure.
```swift
func then<U>(
    in queue: DispatchQueue? = nil,
    fulfillment: (T) throws -> U
) -> Promise<U>

func then<U>(
    in queue: DispatchQueue? = nil,
    fulfillment: (T) throws -> Promise<U>
) -> Promise<U>

func then<U>(
    in queue: DispatchQueue? = nil,
    fulfillment: (T) throws -> U,
    rejection: (Error) throws -> U
) -> Promise<U>

func then<U>(
    in queue: DispatchQueue? = nil,
    fulfillment: (T) throws -> Promise<U>,
    rejection: (Error) throws -> Promise<U>
) -> Promise<U>
```

#### <a id="promise-catch"></a> promise.catch
Appends a rejection handler callback to the promise, and returns a new promise resolving to the return value of the callback if it is called, or to its original fulfillment value if the promise is instead fulfilled. The Promise returned by catch() is rejected if onRejected throws an error or returns a Promise which is itself rejected; otherwise, it is resolved.
```swift
promise.catch { error in
    ...
}
```

#### <a id="promise-finally"></a> promise.finally
Appends a handler to the promise, and returns a new promise which is resolved when the original promise is resolved. The handler is called when the promise is settled, whether fulfilled or rejected.
> However, please note: a throw (or returning a rejected promise) in the finally callback will reject the new promise with that rejection reason.
```swift
promise.finally {
    ...
}
```
