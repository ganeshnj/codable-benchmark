import XCTest
@testable import BenchmarkCodable

final class BenchmarkCodableTests: XCTestCase {
    let metadata = Metadata(id: "77297a02-4d17-45bf-a5b0-d846024ddc2c", documentVersion: 15129)
    func testEncodableDecodablePerformance() {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try! encoder.encode(metadata)
        measure {
            do {
                for _ in 0..<1000 {
                    let decoded = try decoder.decode(Metadata.self, from: data)
//                    XCTAssertEqual(metadata, decoded)
                }
            } catch {
                XCTFail("Failed to encode/decode: \(error)")
            }
        }
    }

    func testMemoryBindingPerformance() {
        let data = metadata.data()
        measure {
            for _ in 0..<1000 {
                let decoded = Metadata.make(data: data)
//                XCTAssertEqual(metadata, decoded)
            }
        }
    }
}

struct Metadata: Codable, Equatable {
    let id: String
    let documentVersion: Int64

    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case documentVersion = "document_version"
    }

    func data() -> Data {
        var data = Data()
        // first 4 bytes are document version
        let documentVersionBytes = withUnsafeBytes(of: documentVersion) { Data($0) }
        data.append(documentVersionBytes)

        // next 32 bytes are id
        let idBytes = id.data(using: .utf8)!
        data.append(idBytes)
        return data
    }

    static func make(data: Data) -> Metadata {
        // first 8 bytes are document version
        let documentVersion = data.withUnsafeBytes { $0.load(as: Int64.self) }

        // next 36 bytes are id
        let id = String(data: data[8..<44], encoding: .utf8)!

        return Metadata(id: id, documentVersion: documentVersion)
    }
}
