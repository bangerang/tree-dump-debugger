/**
*  Tree Dump Debugger
*  Copyright (c) Johan Thorell 2022
*  MIT license, see LICENSE file for details
*/

import SwiftUI

struct ContentView: View {
    enum Examples: String, CaseIterable {
        case present = "Present on key window"
        case swiftUI = "Present as SwiftUI modal"
    }
    
    @State var showSwiftUIModal = false
    
    var body: some View {
        NavigationView {
            List(Examples.allCases, id: \.self) { example in
                switch example {
                case .present:
                    Button(example.rawValue) {
                        TreeDumpDebugger.present(TreeDumpDebugger.SwiftDump(value: exampleData))
                    }
                case .swiftUI:
                    Button(example.rawValue) {
                        showSwiftUIModal = true
                    }.sheet(isPresented: $showSwiftUIModal) {
                        TreeDumpDebugger.makeSwiftUIView(with: ["foo": "bar", 122: [122, 45, 4]])
                    }
                }
            }
            .navigationTitle("Examples")
        }
    }
}

class TestC {
    internal init(foo: Int) {
        self.foo = foo
    }
    let foo: Int
}
struct TestB {
    var number: Int
    var c: TestC
}
class TestA {
    internal init(myProperty: String, b: TestB) {
        self.myProperty = myProperty
        self.b = b
    }
    
    var myProperty: String
    let b: TestB
    let foo = ["foo1", "foo2", "foo3", "foo4", "foo5", "foo6", "foo7", "foo8", "foo9", "foo10"]
    let foo1 = ["foo1", "foo2", "foo3", "foo4", "foo5", "foo6", "foo7", "foo8", "foo9", "foo10"]
    let foo2 = ["foo1", "foo2", "foo3", "foo4", "foo5", "foo6", "foo7", "foo8", "foo9", "foo10"]
    let foo3 = ["foo1", "foo2", "foo3", "foo4", "foo5", "foo6", "foo7", "foo8", "foo9", "foo10"]
}

var exampleData = TestA(myProperty: "This is a string", b: TestB(number: 122, c: TestC(foo: 345)))
