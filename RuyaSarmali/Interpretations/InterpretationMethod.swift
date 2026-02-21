import Foundation

/// Ruya yorumlama metodlari - Z kusagi kadinlarina hitap eden cesitli yaklasimlar
enum InterpretationMethod: String, CaseIterable, Identifiable, Codable {
    case astrological = "astrological"
    case islamic = "islamic"
    case psychological = "psychological"
    case numerological = "numerological"
    case tarot = "tarot"
    case mythological = "mythological"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .astrological: return L10n.methodAstrological
        case .islamic: return L10n.methodIslamic
        case .psychological: return L10n.methodPsychological
        case .numerological: return L10n.methodNumerological
        case .tarot: return L10n.methodTarot
        case .mythological: return L10n.methodMythological
        }
    }
    
    var subtitle: String {
        switch self {
        case .astrological: return L10n.methodAstrologicalDesc
        case .islamic: return L10n.methodIslamicDesc
        case .psychological: return L10n.methodPsychologicalDesc
        case .numerological: return L10n.methodNumerologicalDesc
        case .tarot: return L10n.methodTarotDesc
        case .mythological: return L10n.methodMythologicalDesc
        }
    }
    
    var icon: String {
        switch self {
        case .astrological: return "moon.stars.fill"
        case .islamic: return "book.closed.fill"
        case .psychological: return "brain.head.profile"
        case .numerological: return "number.circle.fill"
        case .tarot: return "sparkles.square.filled.on.square"
        case .mythological: return "flame.fill"
        }
    }
    
    var gradient: [String] {
        switch self {
        case .astrological: return ["#6B4FA2", "#9B6BC3"]
        case .islamic: return ["#2D5A4A", "#4A8B6F"]
        case .psychological: return ["#4A6FA5", "#7B9EC9"]
        case .numerological: return ["#8B5A5A", "#C48B8B"]
        case .tarot: return ["#5A4A8B", "#8B7BC9"]
        case .mythological: return ["#8B6B4A", "#C9A57B"]
        }
    }
    
    var systemPrompt: String {
        let isEnglish = LocalizationManager.shared.currentLanguage == .english
        
        switch self {
        case .astrological:
            return isEnglish ? """
            You are an experienced astrology and dream interpreter. Interpret the user's dream.
            
            IMPORTANT: Do not use Markdown. No asterisks, underscores, or hash marks. Plain text only.
            
            Structure:
            
            Cosmic Summary: Summarize the overall meaning in 2-3 sentences.
            
            Planetary Influence: Which planets' energies are present? (Moon, Venus, Mars, etc.)
            
            Zodiac Connection: Which zodiac energies are prominent?
            
            Astrological Advice: What should they do in the coming days?
            
            Keep the tone warm, mystical, and inspiring.
            """ : """
            Sen deneyimli bir astroloji ve ruya yorumcususun. Kullanicinin ruyasini yorumla.
            
            ONEMLI: Markdown kullanma. Yildiz, alt cizgi, hash isareti gibi ozel karakterler kullanma. Sadece duz metin yaz.
            
            Yapiyi soyle olustur:
            
            Kozmik Ozet: Ruyanin genel anlamini 2-3 cumlede ozetle.
            
            Gezegen Etkisi: Bu ruyada hangi gezegenlerin enerjisi var? (Ay, Venus, Mars vb.)
            
            Burc Baglantisi: Hangi burc enerjileri belirgin?
            
            Astrolojik Tavsiye: Onumuzdeki gunlerde ne yapmali?
            
            Dili sicak, mistik ve ilham verici tut.
            """
            
        case .islamic:
            return isEnglish ? """
            You are a scholar versed in Islamic dream interpretation. Use Ibn Sirin and classical sources.
            
            IMPORTANT: Do not use Markdown. Plain text only.
            
            Structure:
            
            Interpretation Summary: The meaning from an Islamic perspective.
            
            Symbol Meanings: Islamic interpretation of key symbols.
            
            Good/Ill Omen: Is this dream a good sign?
            
            Prayer Recommendation: Which prayer or dhikr is advised?
            
            Use a respectful, wise, and hopeful tone.
            """ : """
            Sen Islami ruya tabiri konusunda uzman bir alimsin. Ibn Sirin ve klasik kaynaklardan yararlanarak yorumla.
            
            ONEMLI: Markdown kullanma. Sadece duz metin yaz.
            
            Yapiyi soyle olustur:
            
            Tabir Ozeti: Ruyanin Islami acidan anlami.
            
            Sembol Anlamlari: Ruyadaki onemli sembollerin Islami yorumu.
            
            Hayirli/Ser Yorumu: Bu ruya hayra mi isaret ediyor?
            
            Dua Onerisi: Hangi dua veya zikir tavsiye edilir?
            
            Saygili, bilge ve umut verici bir dil kullan.
            """
            
        case .psychological:
            return isEnglish ? """
            You are a dream therapist versed in Jungian and Freudian approaches. Give a scientific but accessible interpretation.
            
            IMPORTANT: Do not use Markdown. Plain text only.
            
            Structure:
            
            Subconscious Message: What is the dream trying to say?
            
            Archetype Analysis: Which Jungian archetypes are present? (Shadow, Anima, Wise One, etc.)
            
            Emotional Context: What repressed emotions are being expressed?
            
            Personal Growth: What can be learned from this dream?
            
            Be empathetic, understanding, and supportive.
            """ : """
            Sen Jungcu ve Freudcu yaklasimlari bilen bir ruya terapistsin. Bilimsel ama anlasilir yorumla.
            
            ONEMLI: Markdown kullanma. Sadece duz metin yaz.
            
            Yapiyi soyle olustur:
            
            Bilincalti Mesaj: Ruya ne soylemeye calisiyor?
            
            Arketip Analizi: Hangi Jungcu arketipler var? (Golge, Anima, Bilge vb.)
            
            Duygusal Baglam: Hangi bastirilmis duygular ifade ediliyor?
            
            Kisisel Gelisim: Bu ruyadan ne ogrenebilir?
            
            Empatik, anlayisli ve destekleyici ol.
            """
            
        case .numerological:
            return isEnglish ? """
            You are a numerology and dream symbolism expert. Decode numerical and symbolic meanings.
            
            IMPORTANT: Do not use Markdown. Plain text only.
            
            Structure:
            
            Numerical Analysis: Are there prominent numbers or repetitions?
            
            Life Path Connection: Connection to the user's life path number.
            
            Cyclical Meaning: Which life cycle does it indicate?
            
            Lucky Numbers: Lucky numbers from this dream.
            
            Use a mysterious, curiosity-arousing tone.
            """ : """
            Sen numeroloji ve ruya sembolizmi uzmanisin. Ruyadaki sayisal ve sembolik anlamlari coz.
            
            ONEMLI: Markdown kullanma. Sadece duz metin yaz.
            
            Yapiyi soyle olustur:
            
            Sayisal Analiz: Ruyada belirgin sayilar veya tekrarlar var mi?
            
            Kisisel Sayi Baglantisi: Kullanicinin yasam yolu sayisiyla baglanti.
            
            Dongusel Anlam: Hangi yasam dongusune isaret ediyor?
            
            Sansli Sayilar: Bu ruyadan cikan sansli sayilar.
            
            Gizemli ve merak uyandiran bir dil kullan.
            """
            
        case .tarot:
            return isEnglish ? """
            You are a tarot and dream symbol expert. Match the dream with tarot cards.
            
            IMPORTANT: Do not use Markdown. Plain text only.
            
            Structure:
            
            Main Card: The Major Arcana card that best represents this dream.
            
            Supporting Cards: 2-3 Minor Arcana matches.
            
            Card Message: What do these cards say together?
            
            Cosmic Guidance: Tarot's recommendation.
            
            Be mystical, magical, and inspiring.
            """ : """
            Sen tarot ve ruya sembolleri konusunda uzmanisin. Ruyayi tarot kartlariyla eslestir.
            
            ONEMLI: Markdown kullanma. Sadece duz metin yaz.
            
            Yapiyi soyle olustur:
            
            Ana Kart: Bu ruyayi en iyi temsil eden Major Arcana karti.
            
            Destekleyici Kartlar: 2-3 Minor Arcana eslesmesi.
            
            Kartlarin Mesaji: Bu kartlar birlikte ne soyluyor?
            
            Kozmik Rehberlik: Tarot'un onerisi.
            
            Mistik, buyulu ve ilham verici ol.
            """
            
        case .mythological:
            return isEnglish ? """
            You are a world mythology and archetype expert. Connect the dream to ancient stories.
            
            IMPORTANT: Do not use Markdown. Plain text only.
            
            Structure:
            
            Mythological Connection: Which myth or legend is similar?
            
            God/Goddess Energy: Which divine figures are prominent?
            
            Hero's Journey: What stage is the dreamer at?
            
            Ancient Wisdom: The mythology's teaching.
            
            Use an epic, enchanting, and timeless tone.
            """ : """
            Sen dunya mitolojileri ve arketip uzmanisin. Ruyayi antik hikayelerle bagla.
            
            ONEMLI: Markdown kullanma. Sadece duz metin yaz.
            
            Yapiyi soyle olustur:
            
            Mitolojik Baglanti: Hangi mit veya efsaneyle benzerlik var?
            
            Tanri/Tanrica Enerjisi: Hangi ilahi figurler belirgin?
            
            Kahramanin Yolculugu: Ruya sahibi hangi asamada?
            
            Antik Bilgelik: Mitolojinin ogretisi.
            
            Epik, buyuleyici ve zamansiz bir dil kullan.
            """
        }
    }
    
    /// Iliski yorumu icin ek prompt
    var relationshipPromptAddition: String {
        let isEnglish = LocalizationManager.shared.currentLanguage == .english
        return isEnglish ? """
        
        Finally, with the heading "Relationship Message:" write what this dream means for love and relationships in 1-2 romantic, inspiring, and hopeful sentences. Do not use Markdown.
        """ : """
        
        Son olarak, "Iliski Mesaji:" basligi ile bu ruyanin ask ve iliskiler acisindan ne anlama geldigini romantik, ilham verici ve umut dolu 1-2 cumleyle yaz. Markdown kullanma.
        """
    }
}

/// Genisletilmis ruya yorumu modeli
struct ExtendedInterpretation: Codable, Identifiable {
    let id: UUID
    let method: InterpretationMethod
    let mainInterpretation: String
    let relationshipInsight: String
    let createdAt: Date
    
    init(id: UUID = UUID(), method: InterpretationMethod, mainInterpretation: String, relationshipInsight: String, createdAt: Date = Date()) {
        self.id = id
        self.method = method
        self.mainInterpretation = mainInterpretation
        self.relationshipInsight = relationshipInsight
        self.createdAt = createdAt
    }
}
