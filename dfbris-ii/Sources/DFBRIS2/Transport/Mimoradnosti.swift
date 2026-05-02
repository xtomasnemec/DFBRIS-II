//
//  Mimoradnosti.swift
//  dfbris-ii
//
//  Created by Tomáš Němec on 24.04.2026.
//
import SwiftUI
import Foundation
import SkipFuse

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

internal struct IncidentItem: Identifiable {
    let id: String
    let validFrom: String?
    let validTo: String?
    let title: String
    let cause: String
    let content: String
    let lines: [String]
    let location: String?
    let direction: String?
    let delay: Int
}

private let incidentSessionConfig: URLSessionConfiguration = {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 10
    config.requestCachePolicy = .reloadIgnoringLocalCacheData
    return config
}()

private let incidentURLSession = URLSession(configuration: incidentSessionConfig)

internal struct Mimoradnosti: View {
    @State internal var incidents: [IncidentItem] = []
    @State internal var lineColors: [String: Color] = [:]
    @State internal var lineTextColors: [String: Color] = [:]
    @State internal var isLoading = true
    @State internal var showMessage = false
    @State internal var message = ""
    @State internal var expandedId: String? = nil
    @State internal var refreshTask: Task<Void, Never>?

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                // Pozadí odpovídající EventListu
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColor("TransportColor", fallback: .blue).opacity(0.24),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .trailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if showMessage {
                            MessageBox(text: message, isVisible: $showMessage)
                                .padding(.top, 8)
                        }

                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        } else if incidents.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundStyle(.green)
                                
                                Text(L("No extraordinary events"))
                                    .font(.headline)
                                
                                Text(L("Everything is running smoothly!"))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            ForEach(incidents) { incident in
                                incidentRow(incident)
                            }
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await fetchIncidents()
                }
            }
            .navigationTitle(L("Extraordinary events"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await fetchIncidents() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await loadColors()
            await fetchIncidents()
            
            // Periodic update every minute like in Flutter
            refreshTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 60 * 1_000_000_000)
                    await fetchIncidents()
                }
            }
        }
        .onDisappear {
            refreshTask?.cancel()
        }
    }

    @ViewBuilder
    private func incidentRow(_ incident: IncidentItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            DisclosureGroup(
                isExpanded: Binding(
                    get: { expandedId == incident.id },
                    set: { expandedId = $0 ? incident.id : nil }
                )
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(LocalizedStringKey(incident.content))
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding(.top, 8)
                }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(incident.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    if let direction = incident.direction, !direction.isEmpty {
                        Text(direction)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }

                    Text(incident.cause)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.5, green: 0.0, blue: 0.0))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    if !incident.lines.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(incident.lines, id: \.self) { line in
                                Text(line)
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(lineColors[line] ?? .blue)
                                    .foregroundStyle(lineTextColors[line] ?? .white)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }

                    Text("\(L("Delay")): \(incident.delay) min")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(priorityColor(for: incident.delay))

                    VStack(alignment: .leading, spacing: 2) {
                        if let from = incident.validFrom {
                            Label(from, systemImage: "access.time")
                        }
                        if let to = incident.validTo {
                            Label(to, systemImage: "access.time.filled")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                    if let location = incident.location, !location.isEmpty {
                        Text(location)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func priorityColor(for delay: Int) -> Color {
        if delay >= 15 { return .red }
        if delay >= 10 { return .orange }
        if delay >= 5 { return .yellow }
        return .blue
    }

    private func fetchIncidents() async {
        guard let url = URL(string: "https://www.dpmb.cz/data/Xml/DiEvents/DiEvents.xml") else { return }
        
        do {
            let (data, _) = try await incidentURLSession.data(from: url)
            let parser = XMLParser(data: data)
            let delegate = IncidentXMLDelegate()
            parser.delegate = delegate
            
            if parser.parse() {
                let locale = Locale.current.language.languageCode?.identifier ?? "cs"
                
                incidents = delegate.events.map { raw in
                    let content = (locale == "en" ? raw["ObsahEn"] : raw["ObsahCz"]) ?? ""
                    let cleanContent = content
                        .replacingOccurrences(of: "<p>", with: "")
                        .replacingOccurrences(of: "</p>", with: "")
                        .replacingOccurrences(of: "<strong>", with: "**")
                        .replacingOccurrences(of: "</strong>", with: "**")

                    return IncidentItem(
                        id: raw["IdDi"] ?? UUID().uuidString,
                        validFrom: raw["PlatnostOd"],
                        validTo: raw["PlatnostDo"],
                        title: (locale == "en" ? raw["NadpisEn"] : raw["NadpisCz"]) ?? "",
                        cause: (locale == "en" ? raw["PricinaEn"] : raw["PricinaCz"]) ?? "",
                        content: cleanContent,
                        lines: (raw["Linky"] ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty },
                        location: locale == "en" ? raw["MistoEn"] : raw["MistoCz"],
                        direction: locale == "en" ? raw["SmerEn"] : raw["SmerCz"],
                        delay: Int(raw["Zdrzeni"] ?? "0") ?? 0
                    )
                }.sorted { $0.delay > $1.delay }
            }
            isLoading = false
        } catch {
            message = L("Could not load extraordinary events")
            showMessage = true
            isLoading = false
        }
    }

    private func loadColors() async {
        guard let url = URL(string: "https://www.dopravnifotoakce.cz/dfbris/colors.json") else { return }
        do {
            let (data, _) = try await incidentURLSession.data(from: url)
            let decoded = try JSONDecoder().decode(ColorsResponse.self, from: data)
            
            var colors: [String: Color] = [:]
            var tColors: [String: Color] = [:]
            
            for alias in decoded.lineAliases {
                colors[alias.lineName] = colorFromHex(alias.color)
                tColors[alias.lineName] = colorFromHex(alias.textColor)
            }
            lineColors = colors
            lineTextColors = tColors
        } catch {
            print("Error loading line colors: \(error)")
        }
    }

    private func colorFromHex(_ hex: String) -> Color {
        let normalized = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard normalized.count == 6, let value = Int(normalized, radix: 16) else {
            return .blue
        }
        return Color(
            red: Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >> 8) & 0xFF) / 255.0,
            blue: Double(value & 0xFF) / 255.0
        )
    }
}

private class IncidentXMLDelegate: NSObject, XMLParserDelegate {
    var events: [[String: String]] = []
    private var currentEvent: [String: String]?
    private var currentElement: String = ""
    private var currentValue: String = ""

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "DoprEventId" {
            currentEvent = [:]
        }
        currentValue = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "DoprEventId" {
            if let event = currentEvent {
                events.append(event)
            }
            currentEvent = nil
        } else if var event = currentEvent {
            event[elementName] = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
            currentEvent = event
        }
    }
}
