// RegisterPropertyWrappers.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Foundation

protocol _Byte {}
extension UInt8: _Byte {}
extension Character: _Byte {}
extension Bool: _Byte {}

@propertyWrapper
struct AL<T> where T: _Byte {

    private var value: T?

    init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var wrappedValue: T {
        get {
            return value!
        }
        set {
            value = newValue
        }
    }
}

@propertyWrapper
struct AH<T> where T: _Byte {

    private var value: T?

    init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var wrappedValue: T {
        get {
            return value!
        }
        set {
            value = newValue
        }
    }
}

@propertyWrapper
struct AX<T> {

    private var value: T?

    init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var wrappedValue: T {
        get {
            return value!
        }
        set {
            value = newValue
        }
    }
}

@propertyWrapper
struct BL<T> where T: _Byte {

    private var value: T?

    init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var wrappedValue: T {
        get {
            return value!
        }
        set {
            value = newValue
        }
    }
}

@propertyWrapper
struct BH<T> where T: _Byte {

    private var value: T?

    init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var wrappedValue: T {
        get {
            return value!
        }
        set {
            value = newValue
        }
    }
}

@propertyWrapper
struct BX<T> {

    private var value: T?

    init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var wrappedValue: T {
        get {
            return value!
        }
        set {
            value = newValue
        }
    }
}

@propertyWrapper
struct CL<T> where T: _Byte {

    private var value: T?

    init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var wrappedValue: T {
        get {
            return value!
        }
        set {
            value = newValue
        }
    }
}

@propertyWrapper
struct CH<T> where T: _Byte {

    private var value: T?

    init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var wrappedValue: T {
        get {
            return value!
        }
        set {
            value = newValue
        }
    }
}

@propertyWrapper
struct CX<T> {

    private var value: T?

    init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var wrappedValue: T {
        get {
            return value!
        }
        set {
            value = newValue
        }
    }
}

@propertyWrapper
struct DL<T> where T: _Byte {

    private var value: T?

    init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var wrappedValue: T {
        get {
            return value!
        }
        set {
            value = newValue
        }
    }
}

@propertyWrapper
struct DH<T> where T: _Byte {

    private var value: T?

    init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var wrappedValue: T {
        get {
            return value!
        }
        set {
            value = newValue
        }
    }
}


@propertyWrapper
struct DX<T> {

    private var value: T?

    init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var wrappedValue: T {
        get {
            return value!
        }
        set {
            value = newValue
        }
    }
}

@propertyWrapper
struct DS<T> {

    private var value: T?

    init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var wrappedValue: T {
        get {
            return value!
        }
        set {
            value = newValue
        }
    }
}

@propertyWrapper
struct ES<T> {

    private var value: T?

    init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var wrappedValue: T {
        get {
            return value!
        }
        set {
            value = newValue
        }
    }
}

@propertyWrapper
struct DI<T> {

    private var value: T?

    init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var wrappedValue: T {
        get {
            return value!
        }
        set {
            value = newValue
        }
    }
}

@propertyWrapper
struct SI<T> {

    private var value: T?

    init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var wrappedValue: T {
        get {
            return value!
        }
        set {
            value = newValue
        }
    }
}

@propertyWrapper
struct ASCIZ<T> {

    private var value: T?
    let terminator: Character

    init(wrappedValue: T, terminator: Character) {
        self.value = wrappedValue
        self.terminator = terminator
    }

    var wrappedValue: T {
        get {
            return value!
        }
        set {
            value = newValue
        }
    }
}
