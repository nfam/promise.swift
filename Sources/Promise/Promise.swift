//
//  Promise.swift
//
//  Created by Ninh Pham on 21/09/2016.
//  Copyright © 2016 Ninh Pham. All rights reserved.

import class Dispatch.DispatchQueue

/// Represents the eventual completion or failure of an asynchronous operation, and its resulting value.
public class Promise<T> {
    fileprivate let chain: Chain

    fileprivate init(chain: Chain) {
        self.chain = chain
    }
}

// init
extension Promise {

    /// Creates a `Promise` with a closure that is passed two callback closure parameters
    /// to fulfill or reject the `Promise`.
    ///
    /// - Parameters:
    ///   - queue: An optional `DispatchQueue` to execute `body` in. If it is not given,
    ///     the default `DispatchQueue.global()` will be employed instead.
    ///   - body: A closure with two callback closure parameters.
    ///     The `body` initiates some *asynchronous* work, and then, once that completes,
    ///     either calls the first or second callback closure parameters to fulfill or
    ///     reject the promise, respectively.
    ///     If an error is thrown in the `body`, the `Promise` is rejected.
    public convenience init(
        in queue: DispatchQueue? = nil,
        execute body: @escaping (@escaping (T) -> Void, @escaping (Error) -> Void) throws -> Void
    ) {
        self.init(chain: Chain())
        self.chain.append(node: Node(in: queue) { _, completion in
            var state = State.ready
            do {
                try body(
                    /* onFulfilled */ { value in
                        if state != .ready {
                            fatalError("Promise is already settled.")
                        }
                        else {
                            state = .resolved
                            completion(Result(value: value))
                        }
                    },
                    /* onRejected */ { error in
                        if state != .ready {
                            fatalError("Promise is already settled.")
                        }
                        else {
                            state = .rejected
                            completion(Result(error: error))
                        }
                    }
                )
            }
            catch {
                if state != .ready {
                    fatalError("Promise is already settled.")
                }
                else {
                    state = .thrown
                    completion(Result(error: error))
                }
            }
        })
    }

    /// Creates a `Promise` with a closure that returns a value to fulfill the `Promise`.
    ///
    /// - Parameters:
    ///   - queue: An optional `DispatchQueue` to execute `body` in. If it is not given,
    ///     the default `DispatchQueue.global()` will be employed instead.
    ///   - body: A closure with one callback closure parameter.
    ///     The `body` initiates some *asynchronous* work, and then, once that completes,
    ///     returns a value to fulfill the promise.
    ///     If an error is thrown in the `body`, the `Promise` is rejected.
    public convenience init(
        in queue: DispatchQueue? = nil,
        execute body: @escaping () throws -> T
    ) {
        self.init(chain: Chain())
        self.chain.append(node: Node(in: queue) { _, completion in
            do {
                let value = try body()
                completion(Result(value: value))
            }
            catch {
                completion(Result(error: error))
            }
        })
    }

    /// Creates a `Promise` that is fulfilled with a given value.
    ///
    /// - Parameters:
    ///   - queue: An optional `DispatchQueue` to execute `body` in. If it is not given,
    ///     the default `DispatchQueue.global()` will be employed instead.
    ///   - value: A fulfilled `Promise` value.
    public convenience init(in queue: DispatchQueue? = nil, value: T) {
        self.init(chain: Chain())
        self.chain.append(node: Node(in: queue) { _, completion in
            completion(Result(value: value))
        })
    }

    /// Creates a `Promise` that is rejected with a given error.
    ///
    /// - Parameters:
    ///   - queue: An optional `DispatchQueue` to execute `body` in. If it is not given,
    ///     the default `DispatchQueue.global()` will be employed instead.
    ///   - error: A rejected `Promise` reason.
    public convenience init(in queue: DispatchQueue? = nil, error: Error) {
        self.init(chain: Chain())
        self.chain.append(node: Node(in: queue) { _, completion in
            completion(Result(error: error))
        })
    }
}

// all
extension Promise {

    /// Returns a `Promise` that either fulfills when all of the promises
    /// in the iterable parameter have resolved, or rejects as soon as one
    /// of the promises in the iterable parameter rejects.
    ///
    /// - Parameter promises: An iterable of `Promise`` that will either fulfill or reject.
    ///
    /// - Returns: A `Promise` which either fulfills with an array of the values from
    ///   the fulfilled promises in same order as defined in the iterable, or rejects
    ///   with the reason from the first `Promise` in the iterable that rejected.
    public class func all<S>(resolved promises: S) -> Promise<[T]> where S: Sequence, S.Iterator.Element == Promise {
        let promises = Array(promises)
        if promises.isEmpty {
            return Promise<[T]>(value: [T]())
        }

        let promise = Promise<[T]>(chain: Chain())
        promise.chain.append(node: Node { _, completion in
            var results = [(offset: Int, value: T)]()
            var finished = false
            for item in promises.enumerated() {
                item.element.then(in: seriesQueue) { value in
                    if !finished {
                        results.append((offset: item.offset, value: value))
                        if results.count == promises.count {
                            finished = true
                            var values = [T]()
                            for offset in 0 ..< results.count {
                                for result in results where result.offset == offset {
                                    values.append(result.value)
                                }
                            }
                            completion(Result(value: values))
                        }
                    }
                }
                .catch(in: seriesQueue) { error -> Void in
                    if !finished {
                        finished = true
                        completion(Result(error: error))
                    }
                }
            }
        })
        return promise
    }

    /// Returns a `Promise` that either fulfills when all of the promises
    /// in the iterable parameter have resolved, or rejects as soon as one
    /// of the promises in the iterable parameter rejects.
    ///
    /// - Parameter promises: An iterable of `Promise`` that will either fulfill or reject.
    ///
    /// - Returns: A `Promise` which either fulfills with an array of the values from
    ///   the fulfilled promises in same order as defined in the iterable, or rejects
    ///   with the reason from the first `Promise` in the iterable that rejected.
    public class func all(_ promises: Promise<T>...) -> Promise<[T]> {
        return all(resolved: promises)
    }
}

// race
extension Promise {

    /// Returns a `Promise` that fulfills or rejects as soon as one of
    /// the promises in the iterable fulfills or rejects, with the value or
    /// reason from that `Promise`.
    ///
    /// - Parameter promises: An iterable of `Promise`` that will either fulfill or reject.
    ///
    /// - Returns: A `Promise` which either fulfills with the value from the first `Promise`
    ///   in the iterable that fulfilled, or rejects with the reason from the first `Promise`
    ///   in the iterable that rejected.
    public class func race<S>(promises: S) -> Promise<T> where S: Sequence, S.Iterator.Element == Promise {
        let promises = Array(promises)
        guard !promises.isEmpty else {
            fatalError("Cannot race with an empty array of promises.")
        }
        let promise = Promise<T>(chain: Chain())
        promise.chain.append(node: Node { _, completion in
            var finished = false
            for p in promises {
                p.then(in: seriesQueue) { value in
                    if !finished {
                        finished = true
                        completion(Result(value: value))
                    }
                }
                .catch(in: seriesQueue) { error -> Void in
                    if !finished {
                        finished = true
                        completion(Result(error: error))
                    }
                }
            }
        })
        return promise
    }

    /// Returns a `Promise` that fulfills or rejects as soon as one of
    /// the promises in the iterable fulfills or rejects, with the value or
    /// reason from that `Promise`.
    ///
    /// - Parameter promises: An iterable of `Promise`` that will either fulfill or reject.
    ///
    /// - Returns: A `Promise` which either fulfills with the value from the first `Promise`
    ///   in the iterable that fulfilled, or rejects with the reason from the first `Promise`
    ///   in the iterable that rejected.
    public class func race(_ promises: Promise<T>...) -> Promise<T> {
        return race(promises: promises)
    }
}

// then
extension Promise {

    /// Appends a fulfillment closure to the `Promise`, and returns a new `Promise`
    /// resolving to the return value of the executed closure.
    ///
    /// - Parameters:
    ///   - queue: An optional `DispatchQueue` to execute `body` in. If it is not given,
    ///     the default `DispatchQueue.global()` will be employed instead.
    ///   - fulfillment: A closure with a value parameter from the precedent fulfilled
    ///     `Promise`. The `fulfillment` initiates some *asynchronous* work, and then,
    ///     once that completes, returns a value to fulfill the promise.
    ///     If an error is thrown in the `fulfillment`, the `Promise` is rejected.
    ///
    /// - Returns: A `Promise` which either fulfills with the return value,
    ///    or rejects with the error thrown from the `fulfillment.
    public func then<U>(
        in queue: DispatchQueue? = nil,
        fulfillment: @escaping (T) throws -> U
    ) -> Promise<U> {
        self.chain.append(node: Node(in: queue) { result, completion in
            if result.error != nil {
                completion(result)
            }
            else {
                do {
                    if U.self == Void.self {
                        _ = try fulfillment(result.value as! T)
                        completion(voidResult)
                    }
                    else {
                        let value = try fulfillment(result.value as! T)
                        completion(Result(value: value))
                    }
                }
                catch {
                    completion(Result(error: error))
                }
            }
        })
        return Promise<U>(chain: self.chain)
    }

    /// Appends a fulfillment closure to the `Promise`, and returns
    /// the return `Promise` from the executed closure.
    ///
    /// - Parameters:
    ///   - queue: An optional `DispatchQueue` to execute `body` in. If it is not given,
    ///     the default `DispatchQueue.global()` will be employed instead.
    ///   - fulfillment: A closure with a value parameter from the precedent fulfilled
    ///     `Promise`. The `fulfillment` initiates some *asynchronous* work, and then,
    ///     once that completes, returns a `Promise`.
    ///     If an error is thrown in the `fulfillment`, the `Promise` is rejected.
    ///
    /// - Returns: A `Promise` which is either the return `Promise` from `fulfillment`, or
    ///   a new rejected Promise with reason being the error thrown from the `fulfillment`.
    public func then<U>(
        in queue: DispatchQueue? = nil,
        fulfillment: @escaping (T) throws -> Promise<U>
    ) -> Promise<U> {
        self.chain.append(node: Node(in: queue) { result, completion in
            if result.error != nil {
                completion(result)
            }
            else {
                do {
                    let p = try fulfillment(result.value as! T)
                    p.then { value in
                        completion(Result(value: value))
                    }
                    .catch { error in
                        completion(Result(error: error))
                    }
                }
                catch {
                    completion(Result(error: error))
                }
            }
        })
        return Promise<U>(chain: self.chain)
    }

    /// Appends fulfillment and rejection closures to the `Promise`, and returns a new `Promise`
    /// resolving to the return value of the either executed closure.
    ///
    /// - Parameters:
    ///   - queue: An optional `DispatchQueue` to execute `body` in. If it is not given,
    ///     the default `DispatchQueue.global()` will be employed instead.
    ///   - fulfillment: A closure with a value parameter from the precedent fulfilled `Promise`.
    ///     The `fulfillment` initiates some *asynchronous* work, and then,
    ///     once that completes, returns a value to fulfill the promise.
    ///     If an error is thrown in the `fulfillment`, the `Promise` is rejected.
    ///   - rejection: A closure with a reason parameter from the precedent rejected `Promise`.
    ///     The `rejection` initiates some *asynchronous* work, and then,
    ///     once that completes, returns a value to fulfill the promise.
    ///     If an error is thrown in the `rejection`, the `Promise` is rejected.
    ///
    /// - Returns: A `Promise` which either fulfills with the return value,
    ///   or rejects with the error thrown from either `fulfillment` or `rejection`
    ///   which was executed.
    public func then<U>(
        in queue: DispatchQueue? = nil,
        fulfillment: @escaping (T) throws -> U,
        rejection: @escaping (Error) throws -> U
    ) -> Promise<U> {
        self.chain.append(node: Node(in: queue) { result, completion in
            if let error = result.error {
                do {
                    if U.self == Void.self {
                        _ = try rejection(error)
                        completion(voidResult)
                    }
                    else {
                        let value = try rejection(error)
                        completion(Result(value: value))
                    }
                }
                catch {
                    completion(Result(error: error))
                }
            }
            else {
                do {
                    if U.self == Void.self {
                        _ = try fulfillment(result.value as! T)
                        completion(voidResult)
                    }
                    else {
                        let value = try fulfillment(result.value as! T)
                        completion(Result(value: value))
                    }
                }
                catch {
                    completion(Result(error: error))
                }
            }
        })
        return Promise<U>(chain: self.chain)
    }

    /// Appends fulfillment and rejection closures to the `Promise`, and returns
    ///  the return `Promise` from the either executed closure.
    ///
    /// - Parameters:
    ///   - queue: An optional `DispatchQueue` to execute `body` in. If it is not given,
    ///     the default `DispatchQueue.global()` will be employed instead.
    ///   - fulfillment: A closure with a value parameter from the precedent fulfilled `Promise`.
    ///     The `fulfillment` initiates some *asynchronous* work, and then,
    ///     once that completes, returns a `Promise`.
    ///     If an error is thrown in the `fulfillment`, the `Promise` is rejected.
    ///   - rejection: A closure with a reason parameter from the precedent rejected `Promise`.
    ///     The `rejection` initiates some *asynchronous* work, and then,
    ///     once that completes, returns a `Promise`.
    ///     If an error is thrown in the `rejection`, the `Promise` is rejected.
    ///
    /// - Returns: A `Promise` which is either the return `Promise`, or a new rejected Promise
    ///   with reason being the error thrown, from either executed `fulfillment` or `rejection`.
    public func then<U>(
        in queue: DispatchQueue? = nil,
        fulfillment: @escaping (T) throws -> Promise<U>,
        rejection: @escaping (Error) throws -> Promise<U>
    ) -> Promise<U> {
        self.chain.append(node: Node(in: queue) { result, completion in
            if let error = result.error {
                do {
                    let p = try rejection(error)
                    p.then { value in
                        completion(Result(value: value))
                    }
                    .catch { error in
                        completion(Result(error: error))
                    }
                }
                catch {
                    completion(Result(error: error))
                }
            }
            else {
                do {
                    let p = try fulfillment(result.value as! T)
                    p.then { value in
                        completion(Result(value: value))
                    }
                    .catch { error in
                        completion(Result(error: error))
                    }
                }
                catch {
                    completion(Result(error: error))
                }
            }
        })
        return Promise<U>(chain: self.chain)
    }
}

// catch
extension Promise {

    /// Appends a rejection closure to the `Promise`, and returns an no value `Promise`.
    ///
    /// - Parameters:
    ///   - queue: An optional `DispatchQueue` to execute `body` in. If it is not given,
    ///     the default `DispatchQueue.global()` will be employed instead.
    ///   - rejection: A closure with a reason parameter from the precedent rejected `Promise`.
    ///     The `rejection` initiates some *asynchronous* work.
    ///     If an error is thrown in the `rejection`, the `Promise` is rejected.
    /// - Returns: A `Promise` which either fulfills with the no value,
    ///   a new rejected Promise with reason being the error thrown from the `rejection`.
    @discardableResult
    public func `catch`(
        in queue: DispatchQueue? = nil,
        rejection: @escaping (Error) throws -> Void
    ) -> Promise {
        self.chain.append(node: Node(in: queue) { result, completion in
            if let e = result.error {
                do {
                    try rejection(e)
                    completion(voidResult)
                }
                catch {
                    completion(Result(error: error))
                }
            }
            else {
                completion(result)
            }
        })
        return self
    }

    /// Appends a rejection closure to the `Promise`, and returns
    /// the return `Promise` from the executed closure.
    ///
    /// - Parameters:
    ///   - queue: An optional `DispatchQueue` to execute `body` in. If it is not given,
    ///     the default `DispatchQueue.global()` will be employed instead.
    ///   - rejection: A closure with a reason parameter from the precedent rejected `Promise`.
    ///     The `rejection` initiates some *asynchronous* work, and then,
    ///     once that completes, returns a `Promise`.
    ///     If an error is thrown in the `rejection`, the `Promise` is rejected.
    ///
    /// - Returns: A `Promise` which is either the return `Promise`, or a new rejected Promise
    ///   with reason being the error thrown, from the `rejection`.
    public func `catch`(
        in queue: DispatchQueue? = nil,
        rejection: @escaping (Error) throws -> Promise
    ) -> Promise {
        self.chain.append(node: Node(in: queue) { result, completion in
            if let e = result.error {
                do {
                    let p = try rejection(e)
                    p.then { value in
                        completion(Result(value: value))
                    }
                    .catch { error in
                        completion(Result(error: error))
                    }
                }
                catch {
                    completion(Result(error: error))
                }
            }
            else {
                completion(result)
            }
        })
        return self
    }
}

// finally
extension Promise {

    /// Appends a finalizing closure to the `Promise`, and returns an no value `Promise`.
    ///
    /// - Parameters:
    ///   - queue: An optional `DispatchQueue` to execute `body` in. If it is not given,
    ///     the default `DispatchQueue.global()` will be employed instead.
    ///   - finalizing: A closure with no parameter. The `finalizing` is executed the precedent
    ///     `Promise` is settled, whether fulfilled or rejected.
    ///     If an error is thrown in the `finalizing`, the `Promise` is rejected.
    /// - Returns: The precedent `Promise` or a new rejected Promise with reason being
    ///   the error thrown from the `finalizing`.
    @discardableResult
    public func `finally`(
        in queue: DispatchQueue? = nil,
        finalizing: @escaping () throws -> Void
    ) -> Promise {
        self.chain.append(node: Node(in: queue) { result, completion in
            do {
                try finalizing()
                completion(result)
            }
            catch {
                completion(Result(error: error))
            }
        })
        return self
    }

    /// Appends a finalizing closure to the `Promise`, and returns
    /// the return `Promise` from the executed closure.
    ///
    /// - Parameters:
    ////   - queue: An optional `DispatchQueue` to execute `body` in. If it is not given,
    ///     the default `DispatchQueue.global()` will be employed instead.
    ///   - finalizing: A closure with no parameter. The `finalizing` is executed the precedent
    ///     `Promise` is settled, whether fulfilled or rejected. It initiates some *asynchronous* work,
    //      and then, once that completes, returns a `Promise`.
    ///     If an error is thrown in the `finalizing`, the `Promise` is rejected.
    /// - Returns: The precedent `Promise` or a new rejected Promise with reason being
    ///   the error thrown from the `finalizing` or from the return `Promise` of `finalizing``.
    @discardableResult
    public func `finally`(
        in queue: DispatchQueue? = nil,
        finalizing: @escaping () throws -> Promise
    ) -> Promise {
        self.chain.append(node: Node(in: queue) { result, completion in
            do {
                let p = try finalizing()
                p.then { _ in
                    completion(result)
                }
                .catch { error in
                    completion(Result(error: error))
                }
            }
            catch {
                completion(Result(error: error))
            }
        })
        return self
    }
}

// ********************************************************
// PRIVATE
// ********************************************************
private let seriesQueue = DispatchQueue(label: "Promise.series")
private let voidValue: Any = ()
private let voidResult = Result(value: voidValue)

private enum State {
    case ready
    case resolved
    case rejected
    case thrown
}

private struct Result {
    let value: Any
    let error: Error?

    init(value: Any) {
        self.value = value
        self.error = nil
    }

    init(error: Error) {
        self.value = voidValue
        self.error = error
    }
}

private class Node {
    let queue: DispatchQueue
    let exec: (Result, @escaping (Result) -> Void) -> Void
    var next: Node?

    init(in queue: DispatchQueue? = nil, execute body: @escaping (Result, @escaping (Result) -> Void) -> Void) {
        self.queue = queue ?? DispatchQueue.global()
        self.exec = body
    }
}

private class Chain {
    var head: Node?
    var tail: Node?
    var result: Result

    init() {
        self.result = voidResult
    }

    func append(node: Node) {
        seriesQueue.async {
            if let tail = self.tail {
                tail.next = node
                self.tail = node
            }
            else {
                self.head = node
                self.tail = node
                self.tick()
            }
        }
    }

    private func tick() {
        if let node = self.head {
            node.queue.async {
                node.exec(self.result) { result in
                    seriesQueue.async {
                        self.result = result
                        self.head = self.head!.next
                        if self.head != nil {
                            self.tick()
                        }
                        else {
                            self.tail = nil
                        }
                    }
                }
            }
        }
    }
}
