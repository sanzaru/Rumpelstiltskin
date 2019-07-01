
import Rumpelstiltskin
import XCTest

let testData = """
"ErrorMessages.EmptyCredentials" = "Fields empty. Please fill out all required fields.";
"ErrorMessages.WrongCredentials" = "Wrong credentials. Please try again.";
"ErrorMessages.NoConnection" = "Cannot connect to server. Are you offline?";
"ErrorMessages.UnknownError" = "An unknown error has occurred";
"""

class TableOfContentsSpec: XCTestCase {
    override func setUp() {
    }

    func testStringParsing() {
        let result = Rumpelstiltskin.extractStructure(from: testData)
        print(result.description)
    }
}
