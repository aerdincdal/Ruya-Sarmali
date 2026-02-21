import SwiftUI

/// Ruh hali enum - gunluk mood takibi icin
enum DreamMood: String, CaseIterable, Identifiable, Codable {
    case happy = "happy"
    case sad = "sad"
    case anxious = "anxious"
    case tired = "tired"
    case loving = "loving"
    case confused = "confused"
    case peaceful = "peaceful"
    case excited = "excited"
    
    var id: String { rawValue }
    
    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .sad: return "😢"
        case .anxious: return "😰"
        case .tired: return "😴"
        case .loving: return "🥰"
        case .confused: return "😕"
        case .peaceful: return "😌"
        case .excited: return "🤩"
        }
    }
    
    var title: String {
        switch self {
        case .happy: return "Mutlu"
        case .sad: return "Huzunlu"
        case .anxious: return "Kaygili"
        case .tired: return "Yorgun"
        case .loving: return "Asik"
        case .confused: return "Kafasi Karisik"
        case .peaceful: return "Huzurlu"
        case .excited: return "Heyecanli"
        }
    }
    
    var gradient: [Color] {
        switch self {
        case .happy: return [Color(hex: 0xFFD700), Color(hex: 0xFFA500)]
        case .sad: return [Color(hex: 0x4682B4), Color(hex: 0x191970)]
        case .anxious: return [Color(hex: 0xFF6347), Color(hex: 0xFF4500)]
        case .tired: return [Color(hex: 0x708090), Color(hex: 0x2F4F4F)]
        case .loving: return [Color(hex: 0xFF69B4), Color(hex: 0xFF1493)]
        case .confused: return [Color(hex: 0x9370DB), Color(hex: 0x6A5ACD)]
        case .peaceful: return [Color(hex: 0x98FB98), Color(hex: 0x3CB371)]
        case .excited: return [Color(hex: 0xFF6B6B), Color(hex: 0xEE82EE)]
        }
    }
}

/// Mood secim komponenti
struct MoodSelectorView: View {
    @Binding var selectedMood: DreamMood?
    let onSelect: (DreamMood) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "face.smiling.fill")
                    .foregroundColor(Color(hex: 0xE6B6FF))
                Text("Bugun nasil hissediyorsun?")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(DreamMood.allCases) { mood in
                    MoodButton(
                        mood: mood,
                        isSelected: selectedMood == mood,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedMood = mood
                                onSelect(mood)
                            }
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct MoodButton: View {
    let mood: DreamMood
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: mood.gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                    } else {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 56, height: 56)
                    }
                    
                    Text(mood.emoji)
                        .font(.title)
                }
                
                Text(mood.title)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(isSelected ? 1 : 0.6))
                    .lineLimit(1)
            }
            .scaleEffect(isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

/// Mood takibi gorunumu - ruyadan once
struct MoodTrackerCard: View {
    @Binding var currentMood: DreamMood?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let mood = currentMood {
                    Text(mood.emoji)
                        .font(.title2)
                    Text("Bugun \(mood.title) hissediyorsun")
                        .font(.subheadline)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.white.opacity(0.5))
                    Text("Ruh halini sec")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                if currentMood != nil {
                    Button(action: { currentMood = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(currentMood != nil 
                    ? LinearGradient(colors: currentMood!.gradient.map { $0.opacity(0.3) }, startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [Color.white.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

/// Haftalik mood ozeti
struct WeeklyMoodSummary: View {
    let moodHistory: [(Date, DreamMood)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bu Haftaki Ruh Halin")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { day in
                    VStack(spacing: 4) {
                        if day < moodHistory.count {
                            Text(moodHistory[day].1.emoji)
                                .font(.title3)
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 24, height: 24)
                        }
                        
                        Text(dayLabel(for: day))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func dayLabel(for index: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -6 + index, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "tr_TR")
        return String(formatter.string(from: date).prefix(2))
    }
}
