//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation

private var temporaryFileCounter = 0

private let temporaryDirectoryName = "com.wire.zmessaging.ZMTemporaryFileListForBackgroundRequests"

/// List of files currently used for the background upload
class TemporaryFileListForBackgroundRequests {
    
    private var taskToTemporaryFile = ZMTaskIdentifierMap()
    
    /// Creates a temporary file from the data and returns its URL
    func temporaryFile(withBodyData bodyData: Data) -> URL? {
        temporaryFileCounter += 1
        let directory = self.createTemporaryFolder()
        let url = directory.appendingPathComponent("\(temporaryFileCounter).bodydata")
        do {
            try bodyData.write(to: url)
            return url
        } catch {
            return nil
        }
    }
    
    func setTemporaryFile(_ fileURL: URL, forTaskIdentifier taskId: UInt) {
        self.taskToTemporaryFile[taskId] = fileURL
    }
    
    func deleteFile(forTaskID taskId: UInt) {
        guard let url = self.taskToTemporaryFile[taskId] as? URL else {
            return
        }
        try! FileManager.default.removeItem(at: url)
        self.taskToTemporaryFile.removeObject(forTaskIdentifier: taskId)
    }
    
    private func createTemporaryFolder() -> URL {
        let directoryPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(temporaryDirectoryName)
        try! FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: [
            FileAttributeKey.protectionKey.rawValue : FileProtectionType.completeUntilFirstUserAuthentication,
            ])
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var url = URL(fileURLWithPath: directoryPath)
        try! url.setResourceValues(resourceValues)
        return url
    }
}
