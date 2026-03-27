import Foundation

extension Double {
    func toDegreesString() -> String {
        String(format: "%.1f°", self * 180 / .pi)
    }
    
    func toSignedString() -> String {
        String(format: self >= 0 ? "+%.1f" : "%.1f", self)
    }
}

extension Date {
    func timeAgoString() -> String {
        let interval = Date().timeIntervalSince(self)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else {
            return self.formatted(date: .omitted, time: .shortened)
        }
    }
}
