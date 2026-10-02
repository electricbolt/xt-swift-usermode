// DirectoryTranslationTests.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Testing
import Foundation

class DirectoryTranslationTests {

    @Test func testTranslation() throws {
        #expect(DirectoryTranslation.normalize("/") == "")
        #expect(DirectoryTranslation.normalize("/abc/def") == "/abc/def")
        #expect(DirectoryTranslation.normalize("/abc/../def") == "/def")
        #expect(DirectoryTranslation.normalize("/abc/def/../../ghi") == "/ghi")
        #expect(DirectoryTranslation.normalize("./abc/def/../../ghi") == "/ghi")
        #expect(DirectoryTranslation.normalize("./abc/./def") == "/abc/def")
    }
}
