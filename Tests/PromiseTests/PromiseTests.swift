//
//  PromiseTests.swift
//
//  Created by Ninh on 10/02/2016.
//  Copyright © 2016 Ninh. All rights reserved.
//

import Dispatch
import Foundation
@testable import Promise
import XCTest

// swiftlint:disable type_body_length
class PromiseTests: XCTestCase {

    static var allTests = [
        ("Promise.init#resolve", testInitResolve),
        ("Promise.init#resolveResolve", testInitResolveResolve),
        ("Promise.init#resolveReject", testInitResolveReject),
        ("Promise.init#resolveThrow", testInitResolveThrow),
        ("Promise.init#reject", testInitReject),
        ("Promise.init#rejectResolve", testInitRejectResolve),
        ("Promise.init#rejectReject", testInitRejectReject),
        ("Promise.init#throw", testInitThrow),
        ("Promise.init#return", testInitReturn),
        ("Promise.init#returnThrow", testInitReturnThrow),
        ("Promise.init#value", testInitValue),
        ("Promise.init#error", testInitError),
        ("Promise.then#value", testThenValue),
        ("Promise.then#promise", testThenPromise),
        ("Promise.then#throw", testThenThrow),
        ("Promise.then#pairVoid", testThenPairVoid),
        ("Promise.then#pairValue", testThenPairValue),
        ("Promise.then#pairPromise", testThenPairPromise),
        ("Promise.then#stress", testThenStress),
        ("Promise.catch#reject", testCatchReject),
        ("Promise.catch#recover", testCatchRecover),
        ("Promise.catch#throw", testCatchThrow),
        ("Promise.finally#basic", testFinallyBasic),
        ("Promise.finally#catch", testFinallyCatch),
        ("Promise.finally#resolve", testFinallyResolve),
        ("Promise.finally#throw", testFinallyThrow),
        ("Promise.finally#reject", testFinallyReject),
        ("Promise.all#basic", testAllBasic),
        ("Promise.all#Int", testAllInt),
        ("Promise.all#Any", testAllAny),
        ("Promise.all#empty", testAllEmpty),
        ("Promise.all#delay", testAllDelay),
        ("Promise.all#reject", testAllReject),
        ("Promise.race#empty", testRaceEmpty),
        ("Promise.race#resolve", testRaceResolve),
        ("Promise.race#reject", testRaceReject)
    ]

    func testInitResolve() {
        expectFulfillment { fulfill in
            Promise<Int> { resolve, _ in
                resolve(1)
            }
            .then { value in
                XCTAssertEqual(value, 1)
            }
            .catch { _ in
                XCTFail("Should not have error")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testInitResolveResolve() {
        expectFatalError("Promise is already settled.") {
            _ = Promise<Int> { resolve, _ in
                resolve(1)
                resolve(2)
            }
        }
    }

    func testInitResolveReject() {
        expectFatalError("Promise is already settled.") {
            _ = Promise<Int> { resolve, reject in
                resolve(1)
                reject(TestError("error2"))
            }
        }
    }

    func testInitResolveThrow() {
        expectFatalError("Promise is already settled.") {
            _ = Promise<Int> { resolve, _ in
                resolve(1)
                throw TestError("test")
            }
        }
    }

    func testInitReject() {
        expectFulfillment { fulfill in
            Promise<Int> { _, reject in
                reject(TestError("test"))
            }
            .then { _ in
                XCTFail("Should not have value")
            }
            .catch { error -> Void in
                XCTAssertEqual((error as! TestError).description, "test")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testInitRejectResolve() {
        expectFatalError("Promise is already settled.") {
            _ = Promise<Int> { resolve, reject in
                reject(TestError("error1"))
                resolve(2)
            }
        }
    }

    func testInitRejectReject() {
        expectFatalError("Promise is already settled.") {
            _ = Promise<Int> { _, reject in
                reject(TestError("error1"))
                reject(TestError("error2"))
            }
        }
    }

    func testInitRejectThrow() {
        expectFatalError("Promise is already settled.") {
            _ = Promise<Int> { _, reject in
                reject(TestError("error1"))
                throw TestError("test")
            }
        }
    }

    func testInitThrow() {
        expectFulfillment { fulfill in
            Promise<Int> { _, _ in
                throw TestError("test")
            }
            .then { _ in
                XCTFail("Should not have value")
            }
            .catch { error -> Void in
                XCTAssertEqual((error as! TestError).description, "test")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testInitReturn() {
        expectFulfillment { fulfill in
            Promise<Int> {
                return 1
            }
            .then { value in
                XCTAssertEqual(value, 1)
            }
            .catch { _ in
                XCTFail("Should not have error")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testInitReturnThrow() {
        expectFulfillment { fulfill in
            Promise<Int> {
                throw TestError("test")
            }
            .then { _ in
                XCTFail("Should not have value")
            }
            .catch { error -> Void in
                XCTAssertEqual((error as! TestError).description, "test")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testInitValue() {
        expectFulfillment { fulfill in
            Promise(value: "test1")
            .then { value in
                XCTAssertEqual(value, "test1")
            }
            .catch { _ in
                XCTFail("Should not have error")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testInitError() {
        expectFulfillment { fulfill in
            Promise<Void>(error: TestError("error1"))
            .then { _ -> Void in
                XCTFail("Should have error")
            }
            .catch { error -> Void in
                XCTAssertEqual((error as! TestError).description, "error1")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testThenValue() {
        expectFulfillment { fulfill in
            Promise(value: "test1")
            .then { value -> String in
                XCTAssertEqual(value, "test1")
                return "test2"
            }
            .then { value -> Promise<String> in
                XCTAssertEqual(value, "test2")
                return Promise<String>(error: TestError("test3"))
            }
            .then { _ -> String in
                XCTFail("Should have error")
                return "error"
            }
            .catch { error -> Void in
                XCTAssertEqual((error as! TestError).description, "test3")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testThenPromise() {
        expectFulfillment { fulfill in
            Promise(value: "test1")
            .then { value -> Promise<String> in
                XCTAssertEqual(value, "test1")
                return Promise(value: "test2")
            }
            .then { value -> Promise<String> in
                XCTAssertEqual(value, "test2")
                return Promise<String>(error: TestError("test3"))
            }
            .then { _ in
                XCTFail("Should have error")
            }
            .catch { error -> Void in
                XCTAssertEqual((error as! TestError).description, "test3")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testThenThrow() {
        expectFulfillment { fulfill in
            Promise(value: "test1")
            .then { value -> String in
                XCTAssertEqual(value, "test1")
                throw TestError("error2")
            }
            .then (fulfillment: { _ -> String in
                XCTFail("Should not have value")
                return "_"
            }, rejection: { error -> String in
                XCTAssertEqual((error as! TestError).description, "error2")
                return "test3"
            })
            .then { value -> Promise<String> in
                XCTAssertEqual(value, "test3")
                throw TestError("error4")
            }
            .catch { error -> Void in
                XCTAssertEqual((error as! TestError).description, "error4")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testThenPairVoid() {
        var testN = 1
        expectFulfillment { fulfill in
            Promise(value: "test1")
            .then { value -> String in
                XCTAssertEqual(value, "test1")
                return "test2"
            }
            .then (fulfillment: { value in
                XCTAssertEqual(value, "test2")
                testN = 3
            }, rejection: { _ in
                XCTFail("Should not have error")
            })
            .then (fulfillment: { _ in
                XCTAssertEqual(testN, 3)
                throw TestError("error4")
            }, rejection: { _ in
                XCTFail("Should not have error")
            })
            .then (fulfillment: { _ in
                XCTFail("Should not have value")
            }, rejection: { error in
                XCTAssertEqual((error as! TestError).description, "error4")
                testN = 5
            })
            .then (fulfillment: { _ in
                XCTAssertEqual(testN, 5)
                throw TestError("error6")
            }, rejection: { _ in
                XCTFail("Should not have error")
            })
            .then (fulfillment: { _ in
                XCTFail("Should not have value")
            }, rejection: { error in
                XCTAssertEqual((error as! TestError).description, "error6")
                throw TestError("error7")
            })
            .catch { error -> Void in
                XCTAssertEqual((error as! TestError).description, "error7")
                fulfill()
            }
        }
    }

    func testThenPairValue() {
        expectFulfillment { fulfill in
            Promise(value: "test1")
            .then { value -> String in
                XCTAssertEqual(value, "test1")
                return "test2"
            }
            .then (fulfillment: { value -> String in
                XCTAssertEqual(value, "test2")
                return "test3"
            }, rejection: { _ -> String in
                XCTFail("Should not have error")
                return "_"
            })
            .then (fulfillment: { value -> String in
                XCTAssertEqual(value, "test3")
                throw TestError("error4")
            }, rejection: { _ -> String in
                XCTFail("Should not have error")
                return "_"
            })
            .then (fulfillment: { _ -> String in
                XCTFail("Should not have value")
                return "_"
            }, rejection: { error -> String in
                XCTAssertEqual((error as! TestError).description, "error4")
                return "test5"
            })
            .then (fulfillment: { value -> String in
                XCTAssertEqual(value, "test5")
                throw TestError("error6")
            }, rejection: { _ -> String in
                XCTFail("Should not have error")
                return "_"
            })
            .then (fulfillment: { _ -> String in
                XCTFail("Should not have value")
                return "_"
            }, rejection: { error -> String in
                XCTAssertEqual((error as! TestError).description, "error6")
                throw TestError("error7")
            })
            .catch { error -> Void in
                XCTAssertEqual((error as! TestError).description, "error7")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testThenPairPromise() {
        expectFulfillment { fulfill in
            Promise(value: "test1")
            .then { value -> String in
                XCTAssertEqual(value, "test1")
                return "test2"
            }
            .then (fulfillment: { value -> Promise<String> in
                XCTAssertEqual(value, "test2")
                return Promise(value: "test3")
            }, rejection: { _ -> Promise<String> in
                XCTFail("Should not have error")
                return Promise(value: "_")
            })
            .then (fulfillment: { value -> Promise<String> in
                XCTAssertEqual(value, "test3")
                throw TestError("error4")
            }, rejection: { _ -> Promise<String> in
                XCTFail("Should not have error")
                return Promise(value: "_")
            })
            .then (fulfillment: { value -> Promise<String> in
                XCTFail("Should not have value")
                return Promise(value: "_")
            }, rejection: { error -> Promise<String> in
                XCTAssertEqual((error as! TestError).description, "error4")
                return Promise(value: "test5")
            })
            .then (fulfillment: { value -> Promise<String> in
                XCTAssertEqual(value, "test5")
                return Promise(error: TestError("error6"))
            }, rejection: { _ -> Promise<String> in
                XCTFail("Should not have error")
                return Promise(value: "_")
            })
            .then (fulfillment: { value -> Promise<String> in
                XCTFail("Should not have value")
                return Promise(value: "_")
            }, rejection: { error -> Promise<String> in
                XCTAssertEqual((error as! TestError).description, "error6")
                throw TestError("error7")
            })
            .then (fulfillment: { value -> Promise<String> in
                XCTFail("Should not have value")
                return Promise(value: "_")
            }, rejection: { error -> Promise<String> in
                XCTAssertEqual((error as! TestError).description, "error7")
                return Promise(error: TestError("error8"))
            })
            .catch { error -> Void in
                XCTAssertEqual((error as! TestError).description, "error8")
            }
            .finally {
                fulfill()
            }
        }
    }

    // swiftlint:disable identifier_name
    func testThenStress() {
        expectFulfillment(timeout: 20) { fulfill in
            var values = [Int]()
            let N = 1000
            var promise = Promise(value: 0)
            for x in 1 ..< N {
                promise = promise.then { y -> Int in
                    values.append(y)
                    XCTAssertEqual(x - 1, y)
                    return x
                }
            }
            promise.then { x in
                values.append(x)
                XCTAssertEqual(values, Array(0 ..< N))
            }
            .catch { _ in
                XCTFail("Should not have error")
            }
            .finally {
                fulfill()
            }
        }
    }
    // swiftlint:enable identifier_name

    func testCatchReject() {
        expectFulfillment { fulfill in
            Promise<Void>(error: TestError("error1"))
            .then { _ -> Void in
                XCTFail("Should have error")
            }
            .catch { error -> Promise<Void> in
                XCTAssertEqual((error as! TestError).description, "error1")
                return Promise<Void>(error: TestError("error2"))
            }
            .catch { error -> Void in
                XCTAssertEqual((error as! TestError).description, "error2")
            }
            .catch { _ -> Promise<Void> in
                XCTFail("Should not have error")
                return Promise<Void>(value: Void())
            }
            .then { _ -> Promise<Void> in
                return Promise<Void>(error: TestError("error3"))
            }
            .catch { error -> Void in
                XCTAssertEqual((error as! TestError).description, "error3")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testCatchRecover() {
        expectFulfillment { fulfill in
            Promise<String>(error: TestError("error1"))
            .then { _ -> String in
                XCTFail("Should have error")
                return "error"
            }
            .catch { error -> Promise<String> in
                XCTAssertEqual((error as! TestError).description, "error1")
                return Promise<String>(value: "recover")
            }
            .then { value in
                XCTAssertEqual(value, "recover")
            }
            .catch { _ in
                XCTFail("Should not have error")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testCatchThrow() {
        expectFulfillment { fulfill in
            Promise<Void>(error: TestError("error1"))
            .then { value -> Promise<Void> in
                XCTFail("Should have error")
                return Promise<Void>(value: Void())
            }
            .catch { error -> Void in
                XCTAssertEqual((error as! TestError).description, "error1")
                throw TestError("error2")
            }
            .catch { error -> Promise<Void> in
                XCTAssertEqual((error as! TestError).description, "error2")
                throw TestError("error3")
            }
            .catch { error -> Void in
                XCTAssertEqual((error as! TestError).description, "error3")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testFinallyBasic() {
        var finalized = false
        expectFulfillment { fulfill in
            Promise(value: "value")
            .finally {
                finalized = true
            }
            .then { value in
                XCTAssertEqual(finalized, true)
                XCTAssertEqual(value, "value")
            }
            .catch { _ in
                XCTFail("Should not have error")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testFinallyCatch() {
        var finalized = false
        expectFulfillment { fulfill in
            Promise<String>(error: TestError("error1"))
            .then { _ -> String in
                XCTFail("Should have error")
                return "error"
            }
            .catch { error -> Promise<String> in
                XCTAssertEqual((error as! TestError).description, "error1")
                return Promise<String>(value: "recover")
            }
            .finally {
                finalized = true
            }
            .then { value in
                XCTAssertEqual(finalized, true)
                XCTAssertEqual(value, "recover")
            }
            .catch { _ in
                XCTFail("Should not have error")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testFinallyResolve() {
        expectFulfillment { fulfill in
            Promise<String>(value: "value")
            .finally {
                return Promise<String>(value: "test")
            }
            .then { value in
                XCTAssertEqual(value, "value")
            }
            .catch { _ in
                XCTFail("Should not have error")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testFinallyThrow() {
        expectFulfillment { fulfill in
            Promise<String>(value: "value")
            .finally { _ -> Void in
                throw TestError("throw1")
            }
            .then { _ in
                XCTFail("Should have error")
            }
            .catch { error in
                XCTAssertEqual((error as! TestError).description, "throw1")
            }
            .finally { _ -> Promise<Void> in
                throw TestError("throw2")
            }
            .then { _ in
                XCTFail("Should have error")
            }
            .catch { error in
                XCTAssertEqual((error as! TestError).description, "throw2")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testFinallyReject() {
        expectFulfillment { fulfill in
            Promise<String>(value: "value")
            .finally {
                return Promise<String>(error: TestError("reject"))
            }
            .then { _ in
                XCTFail("Should have error")
            }
            .catch { error in
                XCTAssertEqual((error as! TestError).description, "reject")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testAllBasic() {
        expectFulfillment { fulfill in
            Promise<Any>.all(Promise(value: 1), Promise(value: "2"), Promise(value: 3.0)).then { values in
                XCTAssertEqual(values.count, 3)
                XCTAssertEqual(values[0] as? Int, 1)
                XCTAssertEqual(values[1] as? String, "2")
                XCTAssertEqual(values[2] as? Double, 3.0)
                fulfill()
            }
            .catch { _ in
                XCTFail("Should not have error")
            }
        }
    }

    func testAllInt() {
        expectFulfillment { fulfill in
            var promises = [Promise<Int>]()

            promises.append(Promise(value: 10)
                .then { value -> Int in
                    XCTAssertEqual(value, 10)
                    return value + 1
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 11)
                    return value + 1
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 12)
                    return value + 1
                }
            )

            promises.append(Promise(value: 20)
                .then { value -> Int in
                    XCTAssertEqual(value, 20)
                    return value + 1
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 21)
                    return value + 1
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 22)
                    return value + 1
                }
            )

            promises.append(Promise(value: 30)
                .then { value -> Int in
                    XCTAssertEqual(value, 30)
                    return value + 1
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 31)
                    return value + 1
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 32)
                    return value + 1
                }
            )

            Promise.all(resolved: promises).then { values in
                XCTAssertEqual(values, [13, 23, 33])
            }
            .catch { _ in
                XCTFail("Should not have error")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testAllAny() {
        expectFulfillment { fulfill in
            var promises = [Promise<Any>]()

            promises.append(Promise(value: 10)
                .then { value -> Int in
                    XCTAssertEqual(value, 10)
                    return value + 1
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 11)
                    return value + 1
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 12)
                    return value + 1
                }
            )

            promises.append(Promise(value: "20")
                .then { value -> String in
                    XCTAssertEqual(value, "20")
                    return String(Int(value)! + 1)
                }
                .then { value -> String in
                    XCTAssertEqual(value, "21")
                    return String(Int(value)! + 1)
                }
                .then { value -> String in
                    XCTAssertEqual(value, "22")
                    return String(Int(value)! + 1)
                }
            )

            promises.append(Promise(value: 30.1)
                .then { value -> Double in
                    XCTAssertEqual(value, 30.1)

                    return (value + 1.0)
                }
                .then { value -> Double in
                    XCTAssertEqual(value, 31.1)

                    return value + 1.0
                }
                .then { value -> Double in
                    XCTAssertEqual(value, 32.1)
                    return value + 1.0
                }
            )

            Promise.all(resolved: promises).then { values in
                XCTAssertEqual(values.count, 3)
                XCTAssertEqual(values[0] as? Int, 13)
                XCTAssertEqual(values[1] as? String, "23")
                XCTAssertEqual(values[2] as? Double, 33.1)
            }
            .catch { _ in
                XCTFail("Should not have error")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testAllEmpty() {
        expectFulfillment { fulfill in
            Promise.all(resolved: [Promise<Int>]()).then { values in
                XCTAssertEqual(values.count, 0)
            }
            .catch { _ in
                XCTFail("Should not have error")
            }
            .finally {
                fulfill()
            }
        }
    }

    func delay(resolve: @escaping (Int) -> Void, value: Int) {
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(50)) {
            resolve(value)
        }
    }

    func testAllDelay() {
        expectFulfillment(timeout: 10) { fulfill in
            var promises = [Promise<Int>]()
            var count = 0

            promises.append(Promise(value: 10)
                .then { value -> Int in
                    XCTAssertEqual(value, 10)
                    return value + 1
                }
                .then { value -> Promise<Int> in
                    XCTAssertEqual(value, 11)
                    return Promise<Int> { resolve, _ in
                        self.delay(resolve: resolve, value: 12)
                    }
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 12)
                    XCTAssertEqual(count, 2) // must be the last
                    return value + 1
                }
            )

            promises.append(Promise(value: 20)
                .then { value -> Int in
                    XCTAssertEqual(value, 20)
                    return value + 1
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 21)
                    return value + 1
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 22)
                    count += 1
                    return value + 1
                }
            )

            promises.append(Promise(value: 30)
                .then { value -> Int in
                    XCTAssertEqual(value, 30)
                    return value + 1
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 31)
                    return value + 1
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 32)
                    count += 1
                    return value + 1
                }
            )

            Promise.all(resolved: promises)
            .then { values in
                XCTAssertEqual(values, [13, 23, 33])
            }
            .catch { _ in
                XCTFail("Should not have error")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testAllReject() {
        expectFulfillment(timeout: 10) { fulfill in
            var promises = [Promise<Int>]()
            var rejected = false

            promises.append(Promise(value: 10)
                .then { value -> Int in
                    XCTAssertEqual(value, 10)
                    return value + 1
                }
                .then { value -> Promise<Int> in
                    XCTAssertEqual(value, 11)
                    return Promise<Int> { resolve, _ in
                        self.delay(resolve: resolve, value: 12)
                    }
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 12)
                    XCTAssertEqual(rejected, true)
                    return value + 1
                }
            )

            promises.append(Promise(value: 20)
                .then { value -> Int in
                    XCTAssertEqual(value, 20)
                    return value + 1
                }
                .then { value -> Promise<Int> in
                    XCTAssertEqual(value, 21)
                    return Promise<Int> { resolve, _ in
                        self.delay(resolve: resolve, value: 22)
                    }
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 22)
                    XCTAssertEqual(rejected, true)
                    return value + 1
                }
            )

            promises.append(Promise(value: 30)
                .then { value -> Int in
                    XCTAssertEqual(value, 30)
                    return value + 1
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 31)
                    return value + 1
                }
                .then { _ -> Int in
                    rejected = true
                    throw TestError("reject")
                }
            )

            Promise.all(resolved: promises)
            .then { _ in
                XCTFail("Should have error")
            }
            .catch { error -> Void in
                XCTAssertEqual((error as! TestError).description, "reject")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testRaceEmpty() {
        expectFatalError("Cannot race with an empty array of promises.") {
            _ = Promise<Int>.race()
        }
    }

    func testRaceResolve() {
        expectFulfillment(timeout: 10) { fulfill in
            var finished = false

            let promise1 = Promise(value: 10)
                .then { value -> Int in
                    XCTAssertEqual(value, 10)
                    return value + 1
                }
                .then { value -> Promise<Int> in
                    XCTAssertEqual(value, 11)
                    return Promise<Int> { resolve, _ in
                        self.delay(resolve: resolve, value: 12)
                    }
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 12)
                    XCTAssertEqual(finished, true)
                    return value + 1
                }

            let promise2 = Promise(value: 20)
                .then { value -> Int in
                    XCTAssertEqual(value, 20)
                    return value + 1
                }
                .then { value -> Promise<Int> in
                    XCTAssertEqual(value, 21)
                    return Promise<Int> { resolve, _ in
                        self.delay(resolve: resolve, value: 22)
                    }
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 22)
                    XCTAssertEqual(finished, true)
                    return value + 1
                }

            let promise3 = Promise(value: 30)
                .then { value -> Int in
                    XCTAssertEqual(value, 30)
                    return value + 1
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 31)
                    return value + 1
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 32)
                    finished = true
                    return value + 1
                }

            Promise.race(promise1, promise2, promise3)
            .then { value in
                XCTAssertEqual(value, 33)
            }
            .catch { _ in
                XCTFail("Should not have error")
            }
            .finally {
                fulfill()
            }
        }
    }

    func testRaceReject() {
        expectFulfillment(timeout: 10) { fulfill in
            var promises = [Promise<Int>]()
            var rejected = false

            promises.append(Promise(value: 10)
                .then { value -> Int in
                    XCTAssertEqual(value, 10)
                    return value + 1
                }
                .then { value -> Promise<Int> in
                    XCTAssertEqual(value, 11)
                    return Promise<Int> { resolve, _ in
                        self.delay(resolve: resolve, value: 12)
                    }
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 12)
                    XCTAssertEqual(rejected, true)
                    return value + 1
                }
            )

            promises.append(Promise(value: 20)
                .then { value -> Int in
                    XCTAssertEqual(value, 20)
                    return value + 1
                }
                .then { value -> Promise<Int> in
                    XCTAssertEqual(value, 21)
                    return Promise<Int> { resolve, _ in
                        self.delay(resolve: resolve, value: 22)
                    }
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 22)
                    XCTAssertEqual(rejected, true)
                    return value + 1
                }
            )

            promises.append(Promise(value: 30)
                .then { value -> Int in
                    XCTAssertEqual(value, 30)
                    return value + 1
                }
                .then { value -> Int in
                    XCTAssertEqual(value, 31)
                    return value + 1
                }
                .then { _ -> Int in
                    rejected = true
                    throw TestError("reject")
                }
            )

            Promise.race(promises: promises)
            .then { _ in
                XCTFail("Should have error")
            }
            .catch { error -> Void in
                XCTAssertEqual((error as! TestError).description, "reject")
            }
            .finally {
                fulfill()
            }
        }
    }
}

extension XCTestCase {
    func expectFulfillment(timeout: Double = 3, testcase: @escaping (@escaping () -> Void) -> Void) {
        let expect = expectation(description: "expectingFulfillment")
        testcase {
            expect.fulfill()
        }
        waitForExpectations(timeout: timeout) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    func expectFatalError(_ message: String, testcase: @escaping () -> Void) {
        let expect = expectation(description: "expectingFatalError")
        var assertionMessage: String? = nil
        FatalError.replaceFatalError { message, _, _ in
            assertionMessage = message
            expect.fulfill()
            self.unreachable()
        }
        DispatchQueue.global(qos: .userInitiated).async(execute: testcase)
        waitForExpectations(timeout: 5) { _ in
            XCTAssertEqual(assertionMessage, message)
            FatalError.restoreFatalError()
        }
    }

    private func unreachable() -> Never {
        repeat {
            RunLoop.current.run()
            sleep(10)
        } while (true)
    }
}

class TestError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
