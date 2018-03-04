//
//  FatalError.swift
//
//  Created by Ninh on 21/09/2016.
//  Copyright © 2016 Ninh. All rights reserved.
//

struct FatalError {

    // 1
    static var fatalErrorClosure: (String, StaticString, UInt) -> Never = defaultFatalErrorClosure

    // 2
    private static let defaultFatalErrorClosure = { Swift.fatalError($0, file: $1, line: $2) }

    // 3
    static func replaceFatalError(closure: @escaping (String, StaticString, UInt) -> Never) {
        fatalErrorClosure = closure
    }

    // 4
    static func restoreFatalError() {
        fatalErrorClosure = defaultFatalErrorClosure
    }
}

func fatalError(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> Never {
    FatalError.fatalErrorClosure(message(), file, line)
}
