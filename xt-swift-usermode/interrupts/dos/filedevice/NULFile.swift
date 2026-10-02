// NULFile.java
// XT Copyright © 2025-2026; Electric Bolt Limited.

public class NULFile: BaseFile {

    public convenience init() {
        self.init("NUL", .readWrite, .denyNone, true);
    }

    public override func open() -> Bool {
        return true
    }

    public override func close() -> Bool {
        return false
    }

    public override func getDeviceInformationWord() -> UInt16 {
        return 0x0084
    }
}
