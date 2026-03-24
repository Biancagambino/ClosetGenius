//
//  WeatherManager.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/18/26.
//

import Foundation
import CoreLocation
import Combine

struct WeatherData: Codable {
    let main: MainWeather
    let weather: [Weather]
    let name: String
    
    struct MainWeather: Codable {
        let temp: Double
        let feelsLike: Double
        let tempMin: Double
        let tempMax: Double
        
        enum CodingKeys: String, CodingKey {
            case temp
            case feelsLike = "feels_like"
            case tempMin = "temp_min"
            case tempMax = "temp_max"
        }
    }
    
    struct Weather: Codable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }
}

@MainActor
class WeatherManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentWeather: WeatherData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    private let apiKey = "YOUR_OPENWEATHER_API_KEY" // Replace with actual key
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func fetchWeather() {
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        Task {
            await fetchWeatherData(latitude: location.coordinate.latitude,
                                 longitude: location.coordinate.longitude)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Failed to get location: \(error.localizedDescription)"
    }
    
    private func fetchWeatherData(latitude: Double, longitude: Double) async {
        isLoading = true
        errorMessage = nil
        
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=imperial"
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let weather = try JSONDecoder().decode(WeatherData.self, from: data)
            await MainActor.run {
                self.currentWeather = weather
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch weather: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // Helper to suggest outfit based on weather
    func suggestSeason() -> ClothingItem.Season? {
        guard let temp = currentWeather?.main.temp else { return nil }
        
        switch temp {
        case ..<40:
            return .winter
        case 40..<60:
            return .fall
        case 60..<75:
            return .spring
        case 75...:
            return .summer
        default:
            return nil
        }
    }
    
    func suggestFormality() -> ClothingItem.Formality? {
        guard let weatherCondition = currentWeather?.weather.first?.main else { return nil }
        
        // Suggest more casual for bad weather
        switch weatherCondition.lowercased() {
        case "rain", "drizzle", "thunderstorm", "snow":
            return .casual
        default:
            return nil
        }
    }
    
    func weatherIcon() -> String {
        guard let condition = currentWeather?.weather.first?.main else { return "cloud" }
        
        switch condition.lowercased() {
        case "clear":
            return "sun.max.fill"
        case "clouds":
            return "cloud.fill"
        case "rain", "drizzle":
            return "cloud.rain.fill"
        case "thunderstorm":
            return "cloud.bolt.fill"
        case "snow":
            return "snow"
        default:
            return "cloud"
        }
    }
}
