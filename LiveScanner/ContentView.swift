//
//  ContentView.swift
//  LiveScanner
//
//  Created by Manuchim Oliver on 26/04/2023.
//

import SwiftUI
import VisionKit
import UniformTypeIdentifiers

struct ContentView: View {
    
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var text: String = ""
    @State private var buttonText  = "Copy"
    private let pasteboard = UIPasteboard.general
    
    private let textContentTypes: [(title: String, textContentType: DataScannerViewController.TextContentType?)] = [
        ("All", .none),
        ("URL", .URL),
        ("Phone", .telephoneNumber),
        ("Email", .emailAddress),
        ("Address", .fullStreetAddress)
    ]
    
    var body: some View {
        switch vm.dataScannerAccessStatus {
            case .scannerAvailable:
                mainView
                
            case .cameraNotAvailable:
                Text("Your device doesn't have a camera")
                
            case .scannerNotAvailable:
                Text("Your device doesn't have support for scanning barcode with this app")
                
            case .cameraAccessNotGranted:
                Text("Please provide access to the camera in settings")
                
            case .notDetermined:
                Text("Requesting camera access")
        }
    }
    
    private var mainView: some View {
        DataScannerView(
            recognizedItems: $vm.recognizedItems,
            recognizedDataType: vm.recognizedDataType,
            recognizesMultipleItems: vm.recognizesMultipleItems)
        .background { Color.gray.opacity(0.3) }
        .ignoresSafeArea()
        .id(vm.dataScannerViewId)
        .sheet(isPresented: .constant(true)) {
            bottomContainerView
                .background(.ultraThinMaterial)
                .presentationDetents([.medium, .fraction(0.25)])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
                .onAppear {
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let controller = windowScene.windows.first?.rootViewController?.presentedViewController else {
                        return
                    }
                    controller.view.backgroundColor = .clear
                }
        }
        .onChange(of: vm.ScanType) { _ in vm.recognizedItems = [] }
        .onChange(of: vm.textContentType) { _ in vm.recognizedItems = [] }
        .onChange(of: vm.recognizesMultipleItems) { _ in vm.recognizedItems = []}
    }
    
    private var headerView: some View {
        VStack {
            HStack {
                Picker("Scan Type", selection: $vm.ScanType) {
                    Text("Plain Text").tag(ScanType.text)
                    Text("Barcode").tag(ScanType.barcode)
                }.pickerStyle(.segmented)
                
                Toggle("Scan multiple", isOn: $vm.recognizesMultipleItems)
            }.padding(.top)
            
            if vm.ScanType == .text {
                Picker("Text content type", selection: $vm.textContentType) {
                    ForEach(textContentTypes, id: \.self.textContentType) { option in
                        Text(option.title).tag(option.textContentType)
                    }
                }.pickerStyle(.segmented)
            }
            
            Text(vm.headerText).padding(.top)
        }.padding(.horizontal)
    }
    
    private var bottomContainerView: some View {
        VStack {
            headerView
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(vm.recognizedItems) { item in
                        switch item {
                            case .barcode(let barcode):
                                HStack {
                                    Text(barcode.payloadStringValue ?? "Unknown barcode")
                                    
                                    Spacer()
                                    
                                    Button {
                                        copyToClipboard(text: barcode.payloadStringValue ?? "")
                                    } label: {
                                        Label(buttonText, systemImage: "doc.on.doc")
                                    }.buttonStyle(.bordered)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                }
                                    
                                
                            case .text(let text):
                                HStack {
                                    Text(text.transcript)
                                    
                                    Spacer()
                                    
                                    Button {
                                        copyToClipboard(text: text.transcript)
                                    } label: {
                                        Label(buttonText, systemImage: "doc.on.doc")
                                    }.buttonStyle(.bordered)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                }
                                
                            @unknown default:
                                Text("Unknown")
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    func copyToClipboard(text: String) {
        pasteboard.string = text
        
        self.buttonText = "Copied!"
        // self.text = "" // clear the text after copy
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.buttonText = "Copy"
        }
    }
}
