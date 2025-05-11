import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var filterButton: UIButton!

    let locationManager = CLLocationManager()
    var selectedCategory = "restaurant" // İlk açılışta restoranlar gösterilsin

    override func viewDidLoad() {
        super.viewDidLoad()

        // Konum izinleri ve başlatma
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        mapView.showsUserLocation = true

        // Filtre butonu görünümü
        var config = UIButton.Configuration.filled()
        config.title = "Filtrele"
        config.image = UIImage(systemName: "plus")
        config.imagePadding = 6
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        filterButton.configuration = config
    }

    // Konum güncellendiğinde haritayı odakla ve yerleri getir
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)

        fetchNearbyPlaces(for: selectedCategory)
    }

    // Filtre butonuna tıklanınca kategori seç
    @IBAction func filterButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Kategori Seç", message: nil, preferredStyle: .actionSheet)

        let categories = [
            ("Restoran", "restaurant"),
            ("Kafe", "cafe"),
            ("Hastane", "hospital"),
            ("ATM", "atm"),
            ("Eczane", "pharmacy")
        ]

        for (title, type) in categories {
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                self.selectedCategory = type
                self.fetchNearbyPlaces(for: type)
            })
        }

        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
        }

        present(alert, animated: true)
    }

    // Seçilen kategoriye göre API isteği yap
    func fetchNearbyPlaces(for category: String) {
        guard let location = locationManager.location else {
            print("❗️ Konum alınamadı")
            return
        }

        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        let radius = 1500
        let apiKey = "AIzaSyAsngUw5OXMiFZ4X0nie3-UVo9NHhSEB30"

        let urlStr = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(lat),\(lng)&radius=\(radius)&type=\(category)&key=\(apiKey)"
        guard let url = URL(string: urlStr) else {
            print("❗️ URL hatalı")
            return
        }

        mapView.removeAnnotations(mapView.annotations)

        print("🔍 Seçilen kategori: \(category)")

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("❗️ API hatası: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("❗️ Veri alınamadı")
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]] {

                    print("📌 Gelen yer sayısı: \(results.count)")

                    for place in results {
                        if let name = place["name"] as? String,
                           let geometry = place["geometry"] as? [String: Any],
                           let loc = geometry["location"] as? [String: Double],
                           let lat = loc["lat"],
                           let lng = loc["lng"] {

                            DispatchQueue.main.async {
                                let annotation = MKPointAnnotation()
                                annotation.title = name
                                annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                                self.mapView.addAnnotation(annotation)
                            }
                        }
                    }
                }
            } catch {
                print("❗️ JSON çözümleme hatası: \(error.localizedDescription)")
            }
        }.resume()
    }
}
