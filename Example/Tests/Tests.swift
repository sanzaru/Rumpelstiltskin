
import Rumpelstiltskin
import XCTest

let testData = """
"ErrorMessages.EmptyCredentials" = "Fields empty. Please fill out all required fields.";
"ErrorMessages.WrongCredentials" = "Wrong credentials. Please try again.";
"ErrorMessages.NoConnection" = "Cannot connect to server. Are you offline?";
"ErrorMessages.UnknownError" = "An unknown error has occurred";
"Document.Record.DocumentNumber" = "Document number";
"Document.Record.DocumentCode" = "Document code";
"Document.Record.Surname" = "Surname";
"Document.Record.GivenNames" = "Given names";
"Document.Record.Gender" = "Gender";
"Document.Record.DateOfBirth" = "Date of birth";
"Document.Record.DateOfExpiry" = "Date of expiry";
"Document.Record.Nationality" = "Nationality";
"Document.Record.IssuingState" = "Issuing state";
"Document.Record.PrimaryIdentifier" = "Surname";
"Document.Record.SecondaryIdentifier" = "Given name";
"""

class TableOfContentsSpec: XCTestCase {
    override func setUp() {
    }

    func testStringParsing() {
        let result = Rumpelstiltskin.extractStructure(from: testData)
        let code = result.swiftCode()
        print(code)
    }
}
