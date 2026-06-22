//
//  UILib.swift
//  dfbris-ii
//
//  Created by Tomáš Němec on 24.04.2026.
//
import SwiftUI

#if TARGET_OS_ANDROID
@inline(__always)
func L(_ key: String) -> String {
    key
}

@inline(__always)
func AppColor(_ name: String, fallback: Color) -> Color {
    Color(name, bundle: .module)
}
#else
@inline(__always)
func L(_ key: String.LocalizationValue) -> String {
    String(localized: key)
}

@inline(__always)
func AppColor(_ name: String, fallback: Color) -> Color {
    Color(name, bundle: .module)
}
#endif

#if SKIP_BRIDGE && (os(Android) || ROBOLECTRIC)
extension Foundation.Bundle {
    convenience init?(path: String, moduleName: String? = nil, moduleBundle: (() -> AnyDynamicObject)? = nil) {
        self.init(path: path)
    }
}
#endif


// submenu

struct VButtonStack<Destination: View>: View {

    var name: String
    var symbol: String
    var destination: Destination
    var tintColorName: String? = nil
    var tintFallback: Color = .accentColor

    var resolvedTint: Color {
        if let tintColorName {
            return AppColor(tintColorName, fallback: tintFallback)
        }
        return tintFallback
    }

    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack {
                Text(name)
                    .font(.system(size: 22))
                Spacer()
                Image(symbol)
            }
            .padding()
            .frame(width: 370)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        resolvedTint.opacity(0.06),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
        }
        .tint(resolvedTint)
    }
}

// tlacitka na socialni site
@MainActor //nevim bez tyhle kokotiny to nejede
struct SocialLink: View {

    var name: String
    var link: String
    var image: String

    var body: some View {
        if let url = URL(string: link) {
            Link(destination: url) {
                VStack {
#if TARGET_OS_ANDROID
                    Image(image, bundle: .module)
                        .frame(width: 30, height: 30)
#else
                    Image(image, bundle: .module)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
#endif
                    Text(name)
                        .font(.system(size: 10, weight: .regular, design: .default))
                }
                .frame(width: 60, height: 60)
#if TARGET_OS_ANDROID
                .padding()
#else
                .safeAreaPadding()
#endif
                .background(.gray.opacity(0.1))
                .cornerRadius(14)
            }
        } else {
            VStack {
#if TARGET_OS_ANDROID
                Image(image, bundle: .module)
                    .frame(width: 30, height: 30)
#else
                Image(image, bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
#endif
                Text(name)
                    .font(.system(size: 10, weight: .regular, design: .default))
            }
            .frame(width: 60, height: 60)
#if TARGET_OS_ANDROID
            .padding()
#else
            .safeAreaPadding()
#endif
            .background(.gray.opacity(0.1))
            .cornerRadius(14)
        }
    }
}

struct MessageBox: View {
    let text: String

    @Binding var isVisible: Bool

    var body: some View {
        if isVisible {
            Text(text)
                .padding()
                .background(.red.opacity(0.2))
                .cornerRadius(12)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.easeInOut) {
                            isVisible = false
                        }
                    }
                }
                .transition(.opacity)
        }
    }
}

extension Color {
    init(hex: String) {
        let normalized = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        if normalized.count == 6, let value = Int(normalized, radix: 16) {
            self.init(
                red: Double((value >> 16) & 0xFF) / 255.0,
                green: Double((value >> 8) & 0xFF) / 255.0,
                blue: Double(value & 0xFF) / 255.0
            )
        } else {
            self = .blue // Fallback color
        }
    }
}

// MARK: - Date Extension
extension Date {
    /// Parses strings in format "DD.MM.YYYY"
    static func fromDottedString(_ value: String) -> Date {
        let parts = value.split(separator: ".").map(String.init)
        guard parts.count == 3,
              let day = Int(parts[0]),
              let month = Int(parts[1]),
              let year = Int(parts[2]) else {
            return .distantPast
        }
        return Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
    }
}
