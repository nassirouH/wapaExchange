import Foundation

struct Country: Identifiable, Hashable {
    var id: String { code }
    let code: String
    let name: String
    let flag: String
    let currency: String
}

enum SupportedCountries {
    static let destinations: [Country] = [
        Country(code: "SN", name: "Senegal", flag: "🇸🇳", currency: "XOF"),
        Country(code: "CI", name: "Côte d'Ivoire", flag: "🇨🇮", currency: "XOF"),
        Country(code: "NG", name: "Nigeria", flag: "🇳🇬", currency: "NGN"),
        Country(code: "KE", name: "Kenya", flag: "🇰🇪", currency: "KES"),
        Country(code: "GH", name: "Ghana", flag: "🇬🇭", currency: "GHS"),
        Country(code: "CM", name: "Cameroon", flag: "🇨🇲", currency: "XAF"),
        Country(code: "ML", name: "Mali", flag: "🇲🇱", currency: "XOF"),
        Country(code: "PH", name: "Philippines", flag: "🇵🇭", currency: "PHP"),
        Country(code: "BD", name: "Bangladesh", flag: "🇧🇩", currency: "BDT"),
        Country(code: "IN", name: "India", flag: "🇮🇳", currency: "INR")
    ]

    static let originEUR = Country(code: "EU", name: "Eurozone", flag: "🇪🇺", currency: "EUR")
}
