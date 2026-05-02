//
//  Events.swift
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

#if !SKIP
import WebKit
import MapKit
#endif

#if SKIP
import android.webkit.WebView
import android.webkit.WebViewClient
import android.content.Intent
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.viewinterop.AndroidView
import com.google.maps.android.compose.__
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
#endif

internal struct EventItem: Identifiable, Decodable {
    let id: String
    let eventName: String
    let eventType: String
    let note: String
    let startDate: String
    let startTime: String
    let endDate: String
    let endTime: String
    let author: String
    let link: String?
    let gps: String?
    let pinned: String?
    let dfb: String?
    let lines: [String]?
}

internal struct ColorsResponse: Decodable {
    let lineAliases: [LineAlias]

    private enum CodingKeys: String, CodingKey {
        case lineAliases = "LineAliases"
    }
}

internal struct LineAlias: Decodable {
    let lineName: String
    let color: String
    let textColor: String

    private enum CodingKeys: String, CodingKey {
        case lineName = "LineName"
        case color = "Color"
        case textColor = "TextColor"
    }
}

// MARK: - Memory Management
private let lineNameRegex = try? NSRegularExpression(pattern: #"Linka ([xX]?\d+|[SRNX]\d*|P\d+|ZVL)"#, options: [])

private func extractLineName(from note: String) -> String? {
    guard let regex = lineNameRegex else { return nil }
    let range = NSRange(note.startIndex..., in: note)
    guard let match = regex.firstMatch(in: note, options: [], range: range),
          let capturedRange = Range(match.range(at: 1), in: note) else {
        return nil
    }
    return String(note[capturedRange])
}

private let eventSessionConfig: URLSessionConfiguration = {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 10 // 10 second timeout
    config.timeoutIntervalForResource = 30 // 30 second total timeout
    config.httpMaximumConnectionsPerHost = 2
    config.urlCache = URLCache(memoryCapacity: 256 * 1024, diskCapacity: 0) // 256 KB only (reduced from 10 MB)
    config.requestCachePolicy = .reloadIgnoringLocalCacheData
    config.waitsForConnectivity = true
    return config
}()

private let eventDateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .medium
    df.timeStyle = .short
    return df
}()

private let eventURLSession = URLSession(configuration: eventSessionConfig)

internal struct EventList: View {
    @State var currentEvents: [EventItem] = []
    @State var pastEvents: [EventItem] = []
    @State var lineColors: [String: Color] = [:]
    @State var lineTextColors: [String: Color] = [:]
    @State var isLoading = true
    @State var showMessage = false
    @State var message = ""
    @State var loadingTask: Task<Void, Never>?
    @State var hasLoadedContent = false
    @State var expandedEventId: String? = nil
    
    // Lazy loading - keep all events but limit rendering
    @State var allCurrentEvents: [EventItem] = []
    @State var allPastEvents: [EventItem] = []
    private let eventsPerPage = 20
    @State var currentEventsPage = 1
    @State var pastEventsPage = 1

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColor("TransportColor", fallback: .blue).opacity(0.24),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .trailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            hero

                            if showMessage {
                                MessageBox(text: message, isVisible: $showMessage)
                            }

                            if isLoading {
                                ProgressView()
                                    .padding(.top, 24)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                section(title: L("Current events"), events: currentEvents, isPast: false, 
                                       totalEvents: allCurrentEvents.count, onLoadMore: loadMoreCurrent)

                                if !pastEvents.isEmpty {
                                    section(title: L("Past events"), events: pastEvents, isPast: true,
                                           totalEvents: allPastEvents.count, onLoadMore: loadMorePast)
                                }
                            }
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(L("Events"))
        }
        .task(id: hasLoadedContent) {
            if !hasLoadedContent {
                await loadContent()
                hasLoadedContent = true
            }
        }
        .onDisappear {
            loadingTask?.cancel()
            loadingTask = nil
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(AppColor("TransportColor", fallback: .blue))

            Text(L("Events"))
                .font(.system(.title2, design: .default))
                .bold()

        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func section(title: String, events: [EventItem], isPast: Bool, totalEvents: Int, onLoadMore: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .bold()

            ForEach(events) { event in
                EventCard(
                    event: event,
                    isPast: isPast,
                    lineColor: badgeColor(for: event),
                    lineTextColor: badgeTextColor(for: event),
                    lineColors: lineColors,
                    lineTextColors: lineTextColors,
                    isExpanded: expandedEventId == event.id,
                    onToggle: { 
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedEventId = expandedEventId == event.id ? nil : event.id
                        }
                    }
                )
            }
            
            // Show "Load More" button if there are more events
            if events.count < totalEvents {
                Button(action: onLoadMore) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down")
                        Text(L("Load more"))
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func loadContent() async {
        isLoading = true
        await loadColors()
        await loadEvents()
        isLoading = false
    }

    private func loadColors() async {
        guard let url = URL(string: "https://www.dopravnifotoakce.cz/dfbris/colors.json") else {
            return
        }

        do {
            let (data, _) = try await eventURLSession.data(from: url)
            let decoded = try JSONDecoder().decode(ColorsResponse.self, from: data)

            var colors: [String: Color] = [:]
            var textColors: [String: Color] = [:]

            for alias in decoded.lineAliases {
                colors[alias.lineName] = color(from: alias.color)
                textColors[alias.lineName] = color(from: alias.textColor)
            }

            lineColors = colors
            lineTextColors = textColors
        } catch {
            message = L("Could not load line colors")
            showMessage = true
        }
    }

    private func loadEvents() async {
        guard let url = URL(string: "https://www.dopravnifotoakce.cz/admin/data/events.json") else {
            return
        }

        do {
            let (data, _) = try await eventURLSession.data(from: url)
            let decoded = try JSONDecoder().decode([EventItem].self, from: data)
            let today = Calendar.current.startOfDay(for: Date())

            let current = decoded
                .filter { endDate(for: $0) >= today }
            
            // Tiers from pod.php: 1. DFB, 2. Pinned, 3. Others
            let dfbEvents = current.filter { $0.dfb == "yes" }.sorted { startDate(for: $0) < startDate(for: $1) }
            let pinnedEvents = current.filter { $0.pinned == "yes" && $0.dfb != "yes" }.sorted { startDate(for: $0) < startDate(for: $1) }
            let otherEvents = current.filter { $0.pinned != "yes" && $0.dfb != "yes" }.sorted { startDate(for: $0) < startDate(for: $1) }
            
            allCurrentEvents = dfbEvents + pinnedEvents + otherEvents
            
            allPastEvents = decoded
                .filter { endDate(for: $0) < today }
                .sorted {
                    let lhsEnd = endDate(for: $0)
                    let rhsEnd = endDate(for: $1)
                    if lhsEnd != rhsEnd { return lhsEnd > rhsEnd }
                    return startDate(for: $0) > startDate(for: $1)
                }
            
            // Initialize with first page
            updatePaginatedEvents()
        } catch {
            message = L("Could not load events")
            showMessage = true
        }
    }
    
    private func updatePaginatedEvents() {
        let currentEnd = currentEventsPage * eventsPerPage
        currentEvents = Array(allCurrentEvents.prefix(currentEnd))
        
        let pastEnd = pastEventsPage * eventsPerPage
        pastEvents = Array(allPastEvents.prefix(pastEnd))
    }
    
    private func loadMoreCurrent() {
        currentEventsPage += 1
        updatePaginatedEvents()
    }
    
    private func loadMorePast() {
        pastEventsPage += 1
        updatePaginatedEvents()
    }

    private func startDate(for event: EventItem) -> Date {
        parseDate(event.startDate)
    }

    private func endDate(for event: EventItem) -> Date {
        parseDate(event.endDate)
    }

    private func parseDate(_ value: String) -> Date {
        let parts = value.split(separator: ".").map(String.init)
        guard parts.count == 3,
              let day = Int(parts[0]),
              let month = Int(parts[1]),
              let year = Int(parts[2]) else {
            return .distantPast
        }

        return Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
    }

    private func color(from hex: String) -> Color {
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

    private func badgeColor(for event: EventItem) -> Color {
        // Priority colors from pod.php logic
        if event.dfb == "yes" { return Color(red: 0.85, green: 0.72, blue: 0.2) } // Gold/DFB
        
        // Type based colors as requested
        let type = event.eventType.lowercased()
        if type.contains("vyluka") || type.contains("výluka") || type.contains("omezení") {
            return Color(red: 0.83, green: 0.0, blue: 0.0) // Deep Red
        } else if type.contains("tras") || type.contains("odklon") {
            return Color(red: 0.0, green: 0.46, blue: 0.75) // Transport Blue
        } else if type.contains("zastáv") || type.contains("přemístění") {
            return Color(red: 0.93, green: 0.49, blue: 0.12) // Orange
        }
        
        if event.pinned == "yes" { return .secondary }
        
        return Color(red: 0.29, green: 0.72, blue: 0.36) // Green (Info)
    }

    private func badgeTextColor(for event: EventItem) -> Color {
        return .white
    }
}

internal struct EventCard: View {
    let event: EventItem
    let isPast: Bool
    let lineColor: Color
    let lineTextColor: Color
    let lineColors: [String: Color]
    let lineTextColors: [String: Color]
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: eventIconName(for: event.eventType))
                    .foregroundStyle(lineTextColor)
                    .padding(6)
                    .background(lineColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(event.eventName))
                        .font(.system(.headline, design: .default))
                        .lineLimit(2)
                        .foregroundStyle(isPast ? .secondary : .primary)
                    
                    if let lines = event.lines, !lines.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(lines, id: \.self) { line in
                                Text(line)
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(lineColors[line] ?? .gray)
                                    .foregroundStyle(lineTextColors[line] ?? .white)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        .padding(.top, 2)
                    }

                    Text(dateLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onToggle()
            }

            if isExpanded {
                Divider()
                    .padding(.vertical, 4)

                Text(LocalizedStringKey(event.eventType))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .foregroundStyle(lineTextColor)
                    .background(lineColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                if !event.note.isEmpty {
                    formattedNoteView(note: event.note)
                }

                if let link = event.link, !link.isEmpty, let url = URL(string: link) {
                    if url.pathExtension.lowercased() == "pdf" {
                        PdfPreview(url: url)
                    } else {
                        Link(destination: url) {
                            Text(link)
                                .font(.caption)
                                .underline()
                        }
                    }
                }

                // We use .identity removal transition to prevent Metal deallocation crashes
                // (MTLDebugDevice notifyExternalReferencesNonZeroOnDealloc) in the Simulator.
                // This stops the Map from trying to render while being destroyed.
                if let gps = event.gps, !gps.isEmpty {
                    EventMap(gps: gps, title: event.eventName)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .transition(.asymmetric(insertion: .opacity, removal: .identity))
                }

                Text(L("Author") + ": \(event.author)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(10)
        .background(.background.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(lineColor.opacity(isPast ? 0.2 : 0.6), lineWidth: (event.dfb == "yes" || event.pinned == "yes") ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
    }

    private var dateLabel: String {
        // Format like the Dart implementation: compact, readable ranges
        let startDateTime = dateTime(fromDate: event.startDate, time: event.startTime)
        let endDateTime = dateTime(fromDate: event.endDate, time: event.endTime)

        if let start = startDateTime, let end = endDateTime {
            let calendar = Calendar.current
            if calendar.isDate(start, inSameDayAs: end) {
                // Same day: show single date with time range
                let datePart = DateFormatter.localizedString(from: start, dateStyle: .medium, timeStyle: .none)
                let startTime = DateFormatter.localizedString(from: start, dateStyle: .none, timeStyle: .short)
                let endTime = DateFormatter.localizedString(from: end, dateStyle: .none, timeStyle: .short)
                return "\(datePart) · \(startTime)–\(endTime)"
            } else {
                // Different days: show full date+time for both
                return "\(eventDateFormatter.string(from: start)) — \(eventDateFormatter.string(from: end))"
            }
        } else if let start = startDateTime {
            return eventDateFormatter.string(from: start)
        } else {
            // Fallback to raw strings
            let start = event.startTime.isEmpty ? event.startDate : "\(event.startDate) \(event.startTime)"
            let end = event.endTime.isEmpty ? event.endDate : "\(event.endDate) \(event.endTime)"
            return "\(start) - \(end)"
        }
    }

    private func dateTime(fromDate date: String, time: String) -> Date? {
        let base = parseDate(date)
        guard base != .distantPast else { return nil }

        if time.isEmpty { return base }

        // Expect time formats like "HH:MM" or "H:MM"
        let comps = time.split(separator: ":").map(String.init)
        guard comps.count >= 2,
              let hour = Int(comps[0]),
              let minute = Int(comps[1]) else {
            return base
        }

        var dc = Calendar.current.dateComponents([.year, .month, .day], from: base)
        dc.hour = hour
        dc.minute = minute
        return Calendar.current.date(from: dc)
    }

    private func parseDate(_ value: String) -> Date {
        let parts = value.split(separator: ".").map(String.init)
        guard parts.count == 3,
              let day = Int(parts[0]),
              let month = Int(parts[1]),
              let year = Int(parts[2]) else {
            return Date.distantPast
        }

        return Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date.distantPast
    }

    private func eventIconName(for type: String) -> String {
        let key = type.lowercased()
        if key.contains("oprava") || key.contains("repair") { return "wrench.fill" }
        if key.contains("vyluka") || key.contains("closed") { return "xmark.octagon.fill" }
        if key.contains("tram") || key.contains("tramvaj") { return "lightrail.fill" }
        if key.contains("bus") || key.contains("autobus") { return "bus.fill" }
        if key.contains("vlak") || key.contains("train") { return "train.side.front.car" }
        return "exclamationmark.triangle.fill"
    }
}

extension EventCard {
    private func badges(from note: String) -> [String] {
        guard let regex = lineNameRegex else { return [] }
        let range = NSRange(note.startIndex..., in: note)
        let matches = regex.matches(in: note, options: [], range: range)
        guard !matches.isEmpty else { return [] }

        var results: [String] = []
        for m in matches {
            if let r = Range(m.range(at: 1), in: note) {
                let s = String(note[r])
                if !results.contains(s) { results.append(s) }
            }
        }
        return results
    }

    @ViewBuilder
    private func formattedNoteView(note: String) -> some View {
        let rawLines = note.components(separatedBy: .newlines)

        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(rawLines.enumerated()), id: \.offset) { _, line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                let content = trimmed.trimmingCharacters(in: .init(charactersIn: "# " ))

                if trimmed.hasPrefix("###") && !content.isEmpty {
                    // Header logic from Flutter _buildFormattedText
                    if let lineNumber = extractLineName(from: content) {
                        // Specialized color badge if line number is detected
                        let bgColor = lineColors[lineNumber] ?? AppColor("TransportColor", fallback: .blue)
                        let txtColor = lineTextColors[lineNumber] ?? .white
                        

                        Text(content)
                            .font(.system(size: 15, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(bgColor)
                            .foregroundStyle(txtColor)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        // Simple bold header
                        Text(LocalizedStringKey(content))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(isPast ? .secondary : .primary)
                    }
                } else if trimmed.hasPrefix("-") {
                    // Bullet points
                    let bulletText = "• " + trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                    Text(LocalizedStringKey(bulletText))
                        .font(.callout)
                        .foregroundStyle(isPast ? .secondary : .primary)
                } else if line.hasPrefix("*https://") {
                    // Link logic: *https://url*
                    let urlString = line.replacingOccurrences(of: "*", with: "").trimmingCharacters(in: .whitespaces)
                    if let url = URL(string: urlString) {
                        Link(urlString, destination: url)
                            .font(.body)
                            .foregroundStyle(.blue)
                            .underline()
                    }
                } else if !trimmed.isEmpty {
                    // Normal text line
                    Text(LocalizedStringKey(line))
                        .font(.callout)
                        .foregroundStyle(isPast ? .secondary : .primary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    // Empty line
                    Spacer().frame(height: 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

internal struct EventMap: View {
    let gps: String
    let title: String

    var body: some View {
        let parts = gps.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        Group {
            if parts.count == 2,
               let latitude = Double(parts[0]),
               let longitude = Double(parts[1]) {
                LocationMap(latitude: latitude, longitude: longitude, title: title)
            }
        }
    }
}

internal struct PdfPreview: View {
    let url: URL
    @State var showPdf = false

    var body: some View {
        Button(action: { showPdf = true }) {
            HStack(spacing: 12) {
                Image(systemName: "doc.richtext")
                    .font(.title3)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("PDF Attachment"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(url.lastPathComponent)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.blue.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.blue.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain) // Prevents standard button highlighting from messing up the layout
        .sheet(isPresented: $showPdf) {
            PdfViewerSheet(url: url)
        }
    }
}

// Simple PDF viewer
#if !SKIP
import WebKit

private struct PDFWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}
#endif

internal struct PdfViewerSheet: View {
    let url: URL
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Group {
                #if !SKIP
                PDFWebView(url: url)
                #else
                AndroidPdfView(url: url)
                #endif
            }
            .navigationTitle(url.lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("Close")) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Link(destination: url) {
                        Image(systemName: "safari")
                    }
                }
            }
        }
    }
}

#if SKIP
private struct AndroidPdfView: View {
    let url: URL

    var body: some View {
        ComposeView { _ in
            let encodedUrl = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url.absoluteString
            let googleDocsUrl = "https://docs.google.com/viewer?embedded=true&url=" + encodedUrl
            
            AndroidView(factory: { context in
                let webView = WebView(context)
                webView.settings.javaScriptEnabled = true
                webView.settings.setSupportZoom(true)
                webView.settings.builtInZoomControls = true
                webView.settings.displayZoomControls = false
                webView.settings.useWideViewPort = true
                webView.settings.loadWithOverviewMode = true
                webView.settings.allowFileAccess = true
                webView.settings.domStorageEnabled = true
                webView.webViewClient = WebViewClient()
                
                webView.loadUrl(googleDocsUrl)
                return webView
            })
        }
    }
}
#endif

#if !SKIP

private struct LocationMap: View {
    let latitude: Double
    let longitude: Double
    let title: String

    var body: some View {
        Map(initialPosition: .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )) {
            Marker(title, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        }
        .onTapGesture {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            mapItem.name = title
            mapItem.openInMaps()
        }
    }
}
#else
private struct LocationMap: View {
    let latitude: Double
    let longitude: Double
    let title: String

    var body: some View {
        ComposeView { context in
            GoogleMap(cameraPositionState: rememberCameraPositionState {
                position = CameraPosition.fromLatLngZoom(LatLng(latitude, longitude), Float(14.0))
            }) {
                Marker(
                    state: MarkerState(position: LatLng(latitude, longitude)),
                    title: title,
                    onClick: { _ in
                        context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("geo:0,0?q=\(latitude),\(longitude)(\(title))")))
                        return true
                    }
                )
            }
        }
    }
}
#endif
