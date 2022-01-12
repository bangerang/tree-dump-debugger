/**
*  Tree Dump Debugger
*  Copyright (c) Johan Thorell 2022
*  MIT license, see LICENSE file for details
*/

import Foundation
import UIKit
import SwiftUI
import Combine

// MARK: API
public struct TreeDumpDebugger {
    
    /// Presents a tree dump representation of `value` view on `window`
    ///
    /// - Parameters:
    ///   - value: The value to output.
    ///   - name: A label to use when writing the contents of `value`. When `nil`
    ///     is passed, the label is omitted. The default is `nil`.
    ///   - indent: The number of spaces to use as an indent for each line of the
    ///     output. The default is `0`.
    ///   - maxDepth: The maximum depth to descend when writing the contents of a
    ///     value that has nested components. The default is `Int.max`.
    ///   - maxItems: The maximum number of elements for which to write the full
    ///     contents. The default is `Int.max`.
    ///   - window: The window to present on. When `nil` is passed `keyWindow` is used.
    ///   - visitingNode: Modify the given node. The default is `nil`.
    static public func present<T>(_ value: T,
                                  name: String? = nil,
                                  indent: Int = 0,
                                  maxDepth: Int = .max,
                                  maxItems: Int = .max,
                                  in window: UIWindow? = nil,
                                  visitingNode: ((String) -> String)? = nil) {
        let keyWindow = UIWindow.resolveWindow(window)
        let dumpRepresentable = SwiftDump(value: value, name: name, indent: indent, maxDepth: maxDepth, maxItems: maxItems)
        present(dumpRepresentable, in: keyWindow, visitingNode: visitingNode)
    }
    
    /// Presents a tree dump representation of `dumpRepresentable` view on `window`
    ///
    /// - Parameters:
    ///   - dumpRepresentable: /// An abstraction of something that can perform a dump of a `value`
    ///   - window: The window to present on. When `nil` is passed `keyWindow` is used.
    ///   - visitingNode: Modify the given node. The default is `nil`.
    static public func present(_ dumpRepresentable: TreeDumpRepresentable,
                               in window: UIWindow? = nil,
                               visitingNode: ((String) -> String)? = nil) {
        
        let keyWindow = UIWindow.resolveWindow(window)
        
        let hostingController = makeViewController(with: dumpRepresentable, visitingNode: visitingNode)
        
        var topViewController = keyWindow.rootViewController
        
        while let newTopViewController = topViewController?.presentedViewController {
            topViewController = newTopViewController
        }
        
        topViewController?.present(hostingController, animated: true)
    }
    
    /// Wraps a tree dump view with `value` inside a view controller
    ///
    /// - Parameters:
    ///   - value: The value to output.
    ///   - name: A label to use when writing the contents of `value`. When `nil`
    ///     is passed, the label is omitted. The default is `nil`.
    ///   - indent: The number of spaces to use as an indent for each line of the
    ///     output. The default is `0`.
    ///   - maxDepth: The maximum depth to descend when writing the contents of a
    ///     value that has nested components. The default is `Int.max`.
    ///   - maxItems: The maximum number of elements for which to write the full
    ///     contents. The default is `Int.max`.
    ///   - visitingNode: Modify the given node. The default is `nil`.
    static func makeViewController<T>(with value: T,
                                      name: String? = nil,
                                      indent: Int = 0,
                                      maxDepth: Int = .max,
                                      maxItems: Int = .max,
                                      visitingNode: ((String) -> String)? = nil) -> UIHostingController<DumperTreeView> {
        return UIHostingController(rootView: makeSwiftUIView(with: value, visitingNode: visitingNode))
    }
    
    /// Wraps a tree dump view with `dumpRepresentable` inside a view controller
    ///
    /// - Parameters:
    ///   - dumpRepresentable: /// An abstraction of something that can perform a dump of a `value`
    ///   - visitingNode: Modify the given node. The default is `nil`.
    static func makeViewController(with dumpRepresentable: TreeDumpRepresentable,
                                   visitingNode: ((String) -> String)? = nil) -> UIHostingController<DumperTreeView> {
        return UIHostingController(rootView: makeSwiftUIView(with: dumpRepresentable, visitingNode: visitingNode))
    }
    
    
    /// Makes a SwiftUI tree dump view with `value`
    ///
    /// - Parameters:
    ///   - name: A label to use when writing the contents of `value`. When `nil`
    ///     is passed, the label is omitted. The default is `nil`.
    ///   - indent: The number of spaces to use as an indent for each line of the
    ///     output. The default is `0`.
    ///   - maxDepth: The maximum depth to descend when writing the contents of a
    ///     value that has nested components. The default is `Int.max`.
    ///   - maxItems: The maximum number of elements for which to write the full
    ///     contents. The default is `Int.max`.
    ///   - visitingNode: Modify the given node. The default is `nil`.
    static func makeSwiftUIView<T>(with value: T,
                                   name: String? = nil,
                                   indent: Int = 0,
                                   maxDepth: Int = .max,
                                   maxItems: Int = .max,
                                   visitingNode: ((String) -> String)? = nil) -> DumperTreeView {
        return makeSwiftUIView(with: SwiftDump(value: value), visitingNode: visitingNode)
    }
    
    /// Makes a tree dump view with `dumpRepresentable`
    ///
    /// - Parameters:
    ///   - dumpRepresentable: /// An abstraction of something that can perform a dump of a `value`
    ///   - visitingNode: Modify the given node. The default is `nil`.
    static func makeSwiftUIView(with dumpRepresentable: TreeDumpRepresentable,
                                visitingNode: ((String) -> String)? = nil) -> DumperTreeView {
        let tree = Tree(dumpRepresentable: dumpRepresentable, visitingNode: visitingNode)
        let model = Model(tree: tree)
        return DumperTreeView(model: model)
    }
}

/// An abstraction of something that can perform a dump of a `value`
public protocol TreeDumpRepresentable {
    func makeLine(string: String, lineOutput: (String) -> Void)
    func dump(using tree: inout TreeDumpDebugger.Tree)
}

// MARK: Implementation
extension TreeDumpDebugger {
    
    private struct SearchBar: View {
        
        let searchBarColor = (light: UIColor(red: 229.0/255.0, green: 229.0/255.0, blue: 230.0/255.0, alpha: 1.0),
                              dark: UIColor(red: 44.0/255.0, green: 44.0/255.0, blue: 46.0/255.0, alpha: 1.0))
        
        @Binding var searchText: String
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            ZStack {
                Rectangle()
                    .foregroundColor(colorScheme == .dark ? Color(searchBarColor.dark) : Color(searchBarColor.light))
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search ..", text: $searchText)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                .padding(.leading, 13)
            }
            .frame(height: 40)
            .cornerRadius(13)
            .padding()
        }
    }
    
    struct DumperTreeView: View {
        @ObservedObject fileprivate var model: Model
        @Environment(\.colorScheme) var colorScheme
        
        let backgroundColor = (light: UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 247.0/255.0, alpha: 1.0),
                               dark: UIColor(red: 28.0/255.0, green: 28.0/255.0, blue: 31.0/255.0, alpha: 1.0))
        
        var body: some View {
            NavigationView {
                VStack {
                    if model.loading {
                        ProgressView()
                    } else {
                        SearchBar(searchText: $model.searchText)
                        List(model.nodes, children: \.children) { node in
                            Text(node.value)
                        }
                    }
                }
                .background(colorScheme == .light ? Color(backgroundColor.light) : Color(backgroundColor.dark))
                .navigationTitle("Tree dump debugger")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    Button("Reload") {
                        model.didPressReload()
                    }
                }
            }
        }
    }
}

private extension TreeDumpDebugger {
    class Model: ObservableObject {
        @Published var searchText: String = ""
        @Published private(set) var loading = true
        @Published private(set) var nodes: [TreeDumpDebugger.Node<String>] = []
        private var tree: Tree
        private var cancellable: Cancellable?
        private let dispatchQueue = DispatchQueue(label: "TreeDumpDebugger", qos: .userInitiated)
        
        public init(tree: Tree) {
            self.tree = tree
            cancellable = $searchText.debounce(for: .milliseconds(300), scheduler: RunLoop.main)
                .sink { searchText in
                    self.handleSearch(searchText)
                }
            dump()
        }
        
        public func didPressReload() {
            searchText = ""
            dump()
        }
        
        private func dump() {
            loading = true
            dispatchQueue.sync {
                self.tree.dump()
                DispatchQueue.main.async { [weak self] in
                    self?.loading = false
                }
            }
        }
        
        private func resetTree() {
            nodes = tree.rootNodes
        }
        
        private func handleSearch(_ string: String) {
            if searchText.isEmpty {
                resetTree()
            } else {
                dispatchQueue.sync { [rootNodes = tree.rootNodes, searchText] in
                    let map = rootNodes.map {
                        $0.search(for: searchText)
                    }
                    let searchResult = map.flatMap { $0 }
                    DispatchQueue.main.async { [weak self] in
                        self?.nodes = searchResult
                    }
                }
            }
        }
    }
}

extension TreeDumpDebugger {
    class Node<T>: Identifiable {
        let value: T
        var id: String {
            return String(ObjectIdentifier(self).hashValue)
        }
        var depth: Int = 0
        var children: [Node<T>]?
        weak var parent: Node<T>?
        
        init(value: T) {
            self.value = value
        }
        
        func addChild(_ child: Node<T>) {
            if children == nil {
                children = []
            }
            children?.append(child)
        }
    }
}

extension TreeDumpDebugger.Node where T == String {
    func search(for string: String) -> [TreeDumpDebugger.Node<String>] {
        var result: [TreeDumpDebugger.Node<String>] = []
        if value.lowercased().contains(string.lowercased()) {
            result.append(self)
        }
        if let children = children {
            for child in children {
                result.append(contentsOf: child.search(for: string))
            }
        }
        
        return result
    }
}

extension TreeDumpDebugger {
    public struct Tree: TextOutputStream {
        private var indentDict: [String.Index: [Node<String>]] = [:]
        private var prev: Node<String>?
        private(set) var rootNodes: [Node<String>] = []
        private let dumpRepresentable: TreeDumpRepresentable
        private var visitingNode: ((String) -> String)?
        
        public init(dumpRepresentable: TreeDumpRepresentable, visitingNode: ((String) -> String)? = nil) {
            self.visitingNode = visitingNode
            self.dumpRepresentable = dumpRepresentable
        }
        
        public mutating func dump() {
            indentDict.removeAll()
            rootNodes.removeAll()
            prev = nil
            dumpRepresentable.dump(using: &self)
        }
        
        public mutating func write(_ string: String) {
            dumpRepresentable.makeLine(string: string) { line in
                handleLine(line)
            }
        }
        
        private mutating func handleLine(_ line: String) {
            
            let node: Node<String> = {
                if let visitingNode = visitingNode {
                    let newValue = visitingNode(line)
                    return Node(value: newValue)
                } else {
                    return Node(value: line)
                }
            }()
            
            if rootNodes.isEmpty {
                rootNodes.append(node)
            }
            
            guard let nodeIndentLevel = line.firstIndex(where: { !$0.isWhitespace }) else {
                return
            }
            
            if let prev = prev {
                let prevIndentLevel = prev.value.firstIndex(where: { !$0.isWhitespace })!
                if prevIndentLevel == nodeIndentLevel {
                    node.depth = prev.depth
                    node.parent = prev.parent
                    prev.parent?.addChild(node)
                } else if prevIndentLevel < nodeIndentLevel {
                    node.depth = prev.depth + 1
                    node.parent = prev
                    prev.addChild(node)
                } else {
                    if let sibling = indentDict[nodeIndentLevel]?.popLast() {
                        node.depth = sibling.depth
                        if sibling.parent == nil {
                            rootNodes.append(node)
                        } else {
                            node.parent = sibling.parent
                            sibling.parent?.addChild(node)
                        }
                    }
                }
            }
            
            indentDict[nodeIndentLevel, default: []].append(node)
            prev = node
        }
    }
}

extension TreeDumpDebugger {
    public class SwiftDump<T>: TreeDumpRepresentable {
        let value: T
        let name: String?
        let indent: Int
        let maxDepth: Int
        let maxItems: Int
        
        public init(value: T, name: String? = nil, indent: Int = 0, maxDepth: Int = .max, maxItems: Int = .max) {
            self.value = value
            self.name = name
            self.indent = indent
            self.maxDepth = maxDepth
            self.maxItems = maxItems
        }
        
        private var line = ""
        public func makeLine(string: String, lineOutput: (String) -> Void) {
            line += string
            
            if let last = line.last, last.isNewline {
                line.removeLast() // Remove new line
                lineOutput(line)
                line = ""
            }
        }
        
        public func dump(using tree: inout TreeDumpDebugger.Tree) {
            Swift.dump(value, to: &tree, name: name, indent: indent, maxDepth: maxDepth, maxItems: maxItems)
        }
    }
}

fileprivate extension UIWindow {
    private static var keyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first(where: \.isKeyWindow)
    }
    
    static func resolveWindow(_ window: UIWindow?) -> UIWindow {
        let keyWindow = window ?? keyWindow
        guard let keyWindow = keyWindow else {
            fatalError("Could not resolve key window")
        }
        return keyWindow
    }
}
