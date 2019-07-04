
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
"Document.Record.Function" = "Given name %d";
"""

class TableOfContentsSpec: XCTestCase {
    override func setUp() {
    }

    func testSwiftCodeGen() {
        let result = Rumpelstiltskin.extractStructure(from: testData)
        let code = result.swiftCode()
        let indentedCode = Indentation(indentationType: .spaces(tabSize: 4)).indent(code)
        print(code)
        print(indentedCode)
    }

    func testSwiftCodeGenComplicated() throws {
        guard let strings =
            Bundle(for: type(of: self)).path(forResource: "Strings", ofType: "txt") else {
                fatalError("Error initializing test")
        }

        let fileUrl = URL(fileURLWithPath: strings)
        let fileContent = try Data(contentsOf: fileUrl)
        let fileContentAsString = String(data: fileContent, encoding: .utf8)!
        let result = Rumpelstiltskin.extractStructure(from: fileContentAsString)
        let code = result.swiftCode()
        let indentedCode = Indentation(indentationType: .spaces(tabSize: 4)).indent(code)
        print(indentedCode)
    }

    func testFunctionParsing() {
        let function = Rumpelstiltskin.functionValueBuilder.build(for: "Document.Function.Test", value: "%d Test %@ %f")

        print(function)
    }

    func testIfFunctionParsingApplies() {
       XCTAssertTrue(Rumpelstiltskin.functionValueBuilder.applies(to: "Hallo %d"))
    }
}
