//
//  ContentView.swift
//  RumpelstiltskinSPM-Example
//
//  Created by Martin Albrecht on 05.09.24.
//

import SwiftUI
import SPMExamplePackage

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(Localizations.Buttons.Example) {}

            Text(Localizations.LongerText.NoMultiline)

            // Messages localized inside a SPM package
            Text(SPMExamplePackage.exampleSPMString)
            Text(SPMExamplePackage.exampleSPMString2)

            Button(Localizations.Accessibility.Button(value1: "Some Value")) {}
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
