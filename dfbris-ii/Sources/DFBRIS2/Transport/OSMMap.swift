//
//  OSMMap.swift
//  dfbris-ii
//
//  Created by Tomáš Němec on 24.04.2026.
//
import SwiftUI
import MapKit

struct OSMMap: View {
    
    @State var DefaultPosition = MapCameraPosition.region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 49.19451, longitude: 16.61056), // Brno
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        )
    
    var body: some View {
        Map(position: $DefaultPosition)
    }
}
