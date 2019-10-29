# Rumpelstiltskin

[![Version](https://img.shields.io/cocoapods/v/Rumpelstiltskin.svg?style=flat)](https://cocoapods.org/pods/Rumpelstiltskin)
[![Platform](https://img.shields.io/cocoapods/p/Rumpelstiltskin.svg?style=flat)](https://cocoapods.org/pods/Rumpelstiltskin)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
* Swift 5.*

## Usage

Create a new run script phase whithin your Xcode project build phases.

```
echo "Rumpelstiltskin begins to dance around fire"
# Get base path to project
BASE_PATH="$PROJECT_DIR/$PROJECT_NAME"

# Get path to Generator script
GENERATOR_PATH="${PODS_ROOT}/Rumpelstiltskin/main.swift"

# Get path to main localization file (usually english).
SOURCE_PATH="$BASE_PATH/SupportingFiles/Base.lproj/Localizable.strings"

OUTPUT_PATH="$BASE_PATH/Vendor/Localizations.swift"

# Add permission to generator for script execution
chmod 755 "$GENERATOR_PATH"

# Will only re-generate script if something changed
if [ "$SOURCE_PATH" -nt "$OUTPUT_PATH" ]; then
"$GENERATOR_PATH" "$SOURCE_PATH" "$OUTPUT_PATH"
echo "Regenerated strings structure"
fi
```

If you run Rumpelstiltskin for the first time you will have to add the newly generated `Localizations.swift` to your 
project. From then on the file will be updated automatically whenever the `Localizable.strings` file is changed.

## Installation

Rumpelstiltskin is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Rumpelstiltskin'
```

## Author

Christian Braun

## License

Rumpelstiltskin is available under the MIT license. See the LICENSE file for more info.
