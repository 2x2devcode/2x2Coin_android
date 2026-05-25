// Copyright (c) 2026 - 2X2Coin Project
// Distributed under the MIT software license
//
// Implementação da Carteira HD para 2X2Coin

#include "hdwallet.h"
#include "../core/base58.h"
#include "../crypto/sha256.h"
#include "../crypto/secp256k1_wrapper.h"
#include <QCryptographicHash>
#include <QMessageAuthenticationCode>
#include <QRandomGenerator>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDataStream>
#include <QDebug>
#include <openssl/ec.h>
#include <openssl/ecdsa.h>
#include <openssl/obj_mac.h>
#include <openssl/sha.h>
#include <openssl/hmac.h>
#include <openssl/ripemd.h>
#include <openssl/evp.h>
#include <openssl/rand.h>


namespace Coin2x2 {

        return QByteArray();
    }
    if (payload.left(8) != QByteArray(kWalletFileMagic, 8)) {
        return QByteArray();
    }
    QByteArray iv = payload.mid(8, 16);
    QByteArray cipher = payload.mid(24);
    EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
    if (!ctx) {
        return QByteArray();
    }
    QByteArray plain(cipher.size() + EVP_MAX_BLOCK_LENGTH, 0);
    int outLen = 0;
    int totalLen = 0;
    if (EVP_DecryptInit_ex(ctx, EVP_aes_256_cbc(), nullptr,
                           reinterpret_cast<const unsigned char*>(key32.constData()),
                           reinterpret_cast<const unsigned char*>(iv.constData())) != 1
        || EVP_DecryptUpdate(ctx,
                             reinterpret_cast<unsigned char*>(plain.data()), &outLen,
                             reinterpret_cast<const unsigned char*>(cipher.constData()),
                             cipher.size()) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return QByteArray();
    }
    totalLen = outLen;
    if (EVP_DecryptFinal_ex(ctx,
                            reinterpret_cast<unsigned char*>(plain.data()) + outLen,
                            &outLen) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return QByteArray();
    }
    EVP_CIPHER_CTX_free(ctx);
    totalLen += outLen;
    plain.resize(totalLen);
    return plain;
}
} // namespace

// ============================================================
// BIP39 - Lista de palavras e geração de mnemônico
// ============================================================
QStringList BIP39::s_wordList;
bool BIP39::s_wordListLoaded = false;

void BIP39::loadWordList() {
    if (s_wordListLoaded) return;
    // Lista BIP39 completa em inglês (2048 palavras)
    // Incluindo apenas as primeiras para demonstração - em produção usar lista completa
    s_wordList = {
        "abandon", "ability", "able", "about", "above", "absent", "absorb", "abstract",
        "absurd", "abuse", "access", "accident", "account", "accuse", "achieve", "acid",
        "acoustic", "acquire", "across", "act", "action", "actor", "actress", "actual",
        "adapt", "add", "addict", "address", "adjust", "admit", "adult", "advance",
        "advice", "aerobic", "afford", "afraid", "again", "age", "agent", "agree",
        "ahead", "aim", "air", "airport", "aisle", "alarm", "album", "alcohol",
        "alert", "alien", "all", "alley", "allow", "almost", "alone", "alpha",
        "already", "also", "alter", "always", "amateur", "amazing", "among", "amount",
        "amused", "analyst", "anchor", "ancient", "anger", "angle", "angry", "animal",
        "ankle", "announce", "annual", "another", "answer", "antenna", "antique", "anxiety",
        "any", "apart", "apology", "appear", "apple", "approve", "april", "arcade",
        "arctic", "area", "arena", "argue", "arm", "armed", "armor", "army",
        "around", "arrange", "arrest", "arrive", "arrow", "art", "artefact", "artist",
        "artwork", "ask", "aspect", "assault", "asset", "assist", "assume", "asthma",
        "athlete", "atom", "attack", "attend", "attitude", "attract", "auction", "audit",
        "august", "aunt", "author", "auto", "autumn", "average", "avocado", "avoid",
        "awake", "aware", "away", "awesome", "awful", "awkward", "axis", "baby",
        "balance", "bamboo", "banana", "banner", "bar", "barely", "bargain", "barrel",
        "base", "basic", "basket", "battle", "beach", "bean", "beauty", "because",
        "become", "beef", "before", "begin", "behave", "behind", "believe", "below",
        "belt", "bench", "benefit", "best", "betray", "better", "between", "beyond",
        "bicycle", "bid", "bike", "bind", "biology", "bird", "birth", "bitter",
        "black", "blade", "blame", "blanket", "blast", "bleak", "bless", "blind",
        "blood", "blossom", "blouse", "blue", "blur", "blush", "board", "boat",
        "body", "boil", "bomb", "bone", "book", "boost", "border", "boring",
        "borrow", "boss", "bottom", "bounce", "box", "boy", "bracket", "brain",
        "brand", "brave", "breeze", "brick", "bridge", "brief", "bright", "bring",
        "brisk", "broccoli", "broken", "bronze", "broom", "brother", "brown", "brush",
        "bubble", "buddy", "budget", "buffalo", "build", "bulb", "bulk", "bullet",
        "bundle", "bunker", "burden", "burger", "burst", "bus", "business", "busy",
        "butter", "buyer", "buzz", "cabbage", "cabin", "cable", "cactus", "cage",
        "cake", "call", "calm", "camera", "camp", "can", "canal", "cancel",
        "candy", "cannon", "canvas", "canyon", "capable", "capital", "captain", "car",
        "carbon", "card", "cargo", "carpet", "carry", "cart", "case", "cash",
        "casino", "castle", "casual", "cat", "catalog", "catch", "category", "cattle",
        "caught", "cause", "caution", "cave", "ceiling", "celery", "cement", "census",
        "century", "cereal", "certain", "chair", "chalk", "champion", "change", "chaos",
        "chapter", "charge", "chase", "chat", "cheap", "check", "cheese", "chef",
        "cherry", "chest", "chicken", "chief", "child", "chimney", "choice", "choose",
        "chronic", "chuckle", "chunk", "cigar", "cinnamon", "circle", "citizen", "city",
        "civil", "claim", "clap", "clarify", "claw", "clay", "clean", "clerk",
        "clever", "click", "client", "cliff", "climb", "clinic", "clip", "clock",
        "clog", "close", "cloth", "cloud", "clown", "club", "clump", "cluster",
        "clutch", "coach", "coast", "coconut", "code", "coffee", "coil", "coin",
        "collect", "color", "column", "combine", "come", "comfort", "comic", "common",
        "company", "concert", "conduct", "confirm", "congress", "connect", "consider", "control",
        "convince", "cook", "cool", "copper", "copy", "coral", "core", "corn",
        "correct", "cost", "cotton", "couch", "country", "couple", "course", "cousin",
        "cover", "coyote", "crack", "cradle", "craft", "cram", "crane", "crash",
        "crater", "crawl", "crazy", "cream", "credit", "creek", "crew", "cricket",
        "crime", "crisp", "critic", "cross", "crouch", "crowd", "crucial", "cruel",
        "cruise", "crumble", "crunch", "crush", "cry", "crystal", "cube", "culture",
        "cup", "cupboard", "curious", "current", "curtain", "curve", "cushion", "custom",
        "cute", "cycle", "dad", "damage", "damp", "dance", "danger", "daring",
        "dash", "daughter", "dawn", "day", "deal", "debate", "debris", "decade",
        "december", "decide", "decline", "decorate", "decrease", "deer", "defense", "define",
        "defy", "degree", "delay", "deliver", "demand", "demise", "denial", "dentist",
        "deny", "depart", "depend", "deposit", "depth", "deputy", "derive", "describe",
        "desert", "design", "desk", "despair", "destroy", "detail", "detect", "develop",
        "device", "devote", "diagram", "dial", "diamond", "diary", "dice", "diesel",
        "diet", "differ", "digital", "dignity", "dilemma", "dinner", "dinosaur", "direct",
        "dirt", "disagree", "discover", "disease", "dish", "dismiss", "disorder", "display",
        "distance", "divert", "divide", "divorce", "dizzy", "doctor", "document", "dog",
        "doll", "dolphin", "domain", "donate", "donkey", "donor", "door", "dose",
        "double", "dove", "draft", "dragon", "drama", "drastic", "draw", "dream",
        "dress", "drift", "drill", "drink", "drip", "drive", "drop", "drum",
        "dry", "duck", "dumb", "dune", "during", "dust", "dutch", "duty",
        "dwarf", "dynamic", "eager", "eagle", "early", "earn", "earth", "easily",
        "east", "easy", "echo", "ecology", "edge", "edit", "educate", "effort",
        "egg", "eight", "either", "elbow", "elder", "electric", "elegant", "element",
        "elephant", "elevator", "elite", "else", "embark", "embody", "embrace", "emerge",
        "emotion", "employ", "empower", "empty", "enable", "enact", "endless", "endorse",
        "enemy", "energy", "enforce", "engage", "engine", "enhance", "enjoy", "enlist",
        "enough", "enrich", "enroll", "ensure", "enter", "entire", "entry", "envelope",
        "episode", "equal", "equip", "erase", "erode", "erosion", "error", "erupt",
        "escape", "essay", "essence", "estate", "eternal", "ethics", "evidence", "evil",
        "evoke", "evolve", "exact", "example", "excess", "exchange", "excite", "exclude",
        "exercise", "exhaust", "exhibit", "exile", "exist", "exit", "exotic", "expand",
        "expire", "explain", "expose", "express", "extend", "extra", "eye", "fable",
        "face", "faculty", "faint", "faith", "fall", "false", "fame", "family",
        "famous", "fan", "fancy", "fantasy", "far", "fashion", "fat", "fatal",
        "father", "fatigue", "fault", "favorite", "feature", "february", "federal", "fee",
        "feed", "feel", "feet", "fellow", "felt", "fence", "festival", "fetch",
        "fever", "few", "fiber", "fiction", "field", "figure", "file", "film",
        "filter", "final", "find", "fine", "finger", "finish", "fire", "firm",
        "first", "fiscal", "fish", "fit", "fitness", "fix", "flag", "flame",
        "flash", "flat", "flavor", "flee", "flight", "flip", "float", "flock",
        "floor", "flower", "fluid", "flush", "fly", "foam", "focus", "fog",
        "foil", "follow", "food", "foot", "force", "forest", "forget", "fork",
        "fortune", "forum", "forward", "fossil", "foster", "found", "fox", "fragile",
        "frame", "frequent", "fresh", "friend", "fringe", "frog", "front", "frost",
        "frown", "frozen", "fruit", "fuel", "fun", "funny", "furnace", "fury",
        "future", "gadget", "gain", "galaxy", "gallery", "game", "gap", "garbage",
        "garden", "garlic", "garment", "gas", "gasp", "gate", "gather", "gauge",
        "gaze", "general", "genius", "genre", "gentle", "genuine", "gesture", "ghost",
        "giant", "gift", "giggle", "ginger", "giraffe", "girl", "give", "glad",
        "glance", "glare", "glass", "glide", "glimpse", "globe", "gloom", "glory",
        "glove", "glow", "glue", "goat", "goddess", "gold", "good", "goose",
        "gorilla", "gospel", "gossip", "govern", "gown", "grab", "grace", "grain",
        "grant", "grape", "grasp", "grass", "gravity", "great", "green", "grid",
        "grief", "grit", "grocery", "group", "grow", "grunt", "guard", "guide",
        "guilt", "guitar", "gun", "gym", "habit", "hair", "half", "hammer",
        "hamster", "hand", "happy", "harsh", "harvest", "hat", "have", "hawk",
        "hazard", "head", "health", "heart", "heavy", "hedgehog", "height", "hello",
        "helmet", "help", "hen", "hero", "hidden", "high", "hill", "hint",
        "hip", "hire", "history", "hobby", "hockey", "hold", "hole", "holiday",
        "hollow", "home", "honey", "hood", "hope", "horn", "hospital", "host",
        "hour", "hover", "hub", "huge", "human", "humble", "humor", "hundred",
        "hungry", "hunt", "hurdle", "hurry", "hurt", "husband", "hybrid", "ice",
        "icon", "ignore", "ill", "illegal", "image", "imitate", "immense", "immune",
        "impact", "impose", "improve", "impulse", "inbox", "income", "increase", "index",
        "indicate", "indoor", "industry", "infant", "inflict", "inform", "inhale", "inject",
        "inner", "innocent", "input", "inquiry", "insane", "insect", "inside", "inspire",
        "install", "intact", "interest", "into", "invest", "invite", "involve", "iron",
        "island", "isolate", "issue", "item", "ivory", "jacket", "jaguar", "jar",
        "jazz", "jealous", "jeans", "jelly", "jewel", "job", "join", "joke",
        "journey", "joy", "judge", "juice", "jump", "jungle", "junior", "junk",
        "just", "kangaroo", "keen", "keep", "ketchup", "key", "kick", "kid",
        "kingdom", "kiss", "kit", "kitchen", "kite", "kitten", "kiwi", "knee",
        "knife", "knock", "know", "lab", "ladder", "lamp", "language", "laptop",
        "large", "later", "laugh", "laundry", "lava", "law", "lawn", "lawsuit",
        "layer", "lazy", "leader", "learn", "leave", "lecture", "left", "leg",
        "legal", "legend", "lemon", "lend", "length", "lens", "leopard", "lesson",
        "letter", "level", "liar", "liberty", "library", "license", "life", "lift",
        "like", "limb", "limit", "link", "lion", "liquid", "list", "little",
        "live", "lizard", "load", "loan", "lobster", "local", "lock", "logic",
        "lonely", "long", "loop", "lottery", "loud", "lounge", "love", "loyal",
        "lucky", "luggage", "lumber", "lunar", "lunch", "luxury", "mad", "magic",
        "magnet", "maid", "main", "mammal", "mango", "mansion", "manual", "maple",
        "marble", "march", "margin", "marine", "market", "marriage", "mask", "master",
        "match", "material", "math", "matter", "maximum", "maze", "meadow", "mean",
        "medal", "media", "melody", "melt", "member", "memory", "mention", "menu",
        "mercy", "merge", "merit", "merry", "mesh", "message", "metal", "method",
        "middle", "midnight", "milk", "million", "mimic", "mind", "minimum", "minor",
        "minute", "miracle", "miss", "mitten", "model", "modify", "mom", "monitor",
        "monkey", "monster", "month", "moon", "moral", "more", "morning", "mosquito",
        "mother", "motion", "motor", "mountain", "mouse", "move", "movie", "much",
        "muffin", "mule", "multiply", "muscle", "museum", "mushroom", "music", "must",
        "mutual", "myself", "mystery", "naive", "name", "napkin", "narrow", "nasty",
        "natural", "nature", "near", "neck", "need", "negative", "neglect", "neither",
        "nephew", "nerve", "nest", "network", "news", "next", "nice", "night",
        "noble", "noise", "nominee", "noodle", "normal", "north", "notable", "note",
        "nothing", "notice", "novel", "now", "nuclear", "number", "nurse", "nut",
        "oak", "obey", "object", "oblige", "obscure", "obtain", "ocean", "october",
        "odor", "off", "offer", "office", "often", "oil", "okay", "old",
        "olive", "olympic", "omit", "once", "onion", "open", "opera", "oppose",
        "option", "orange", "orbit", "orchard", "order", "ordinary", "organ", "orient",
        "original", "orphan", "ostrich", "other", "outdoor", "outside", "oval", "over",
        "own", "oyster", "ozone", "pact", "paddle", "page", "pair", "palace",
        "palm", "panda", "panel", "panic", "panther", "paper", "parade", "parent",
        "park", "parrot", "party", "pass", "patch", "path", "patrol", "pause",
        "pave", "payment", "peace", "peanut", "pear", "peasant", "pelican", "pen",
        "penalty", "pencil", "people", "pepper", "perfect", "permit", "person", "pet",
        "phone", "photo", "phrase", "physical", "piano", "picnic", "picture", "piece",
        "pig", "pigeon", "pill", "pilot", "pink", "pioneer", "pipe", "pistol",
        "pitch", "pizza", "place", "planet", "plastic", "plate", "play", "please",
        "pledge", "pluck", "plug", "plunge", "poem", "poet", "point", "polar",
        "pole", "police", "pond", "pony", "pool", "popular", "portion", "position",
        "possible", "post", "potato", "pottery", "poverty", "powder", "power", "practice",
        "praise", "predict", "prefer", "prepare", "present", "pretty", "prevent", "price",
        "pride", "primary", "print", "priority", "prison", "private", "prize", "problem",
        "process", "produce", "profit", "program", "project", "promote", "proof", "property",
        "prosper", "protect", "proud", "provide", "public", "pudding", "pull", "pulp",
        "pulse", "pumpkin", "punish", "pupil", "purchase", "purity", "purpose", "push",
        "put", "puzzle", "pyramid", "quality", "quantum", "quarter", "question", "quick",
        "quit", "quiz", "quote", "rabbit", "raccoon", "race", "rack", "radar",
        "radio", "rage", "rail", "rain", "raise", "rally", "ramp", "ranch",
        "random", "range", "rapid", "rare", "rate", "rather", "raven", "reach",
        "ready", "real", "reason", "rebel", "rebuild", "recall", "receive", "recipe",
        "record", "recycle", "reduce", "reflect", "reform", "refuse", "region", "regret",
        "regular", "reject", "relax", "release", "relief", "rely", "remain", "remember",
        "remind", "remove", "render", "renew", "rent", "reopen", "repair", "repeat",
        "replace", "report", "require", "rescue", "resemble", "resist", "resource", "response",
        "result", "retire", "retreat", "return", "reunion", "reveal", "review", "reward",
        "rhythm", "ribbon", "rice", "rich", "ride", "ridge", "rifle", "right",
        "rigid", "ring", "riot", "ripple", "risk", "ritual", "rival", "river",
        "road", "roast", "robot", "robust", "rocket", "romance", "roof", "rookie",
        "room", "rose", "rotate", "rough", "royal", "rubber", "rude", "rug",
        "rule", "run", "runway", "rural", "sad", "saddle", "sadness", "safe",
        "sail", "salad", "salmon", "salon", "salt", "salute", "same", "sample",
        "sand", "satisfy", "satoshi", "sauce", "sausage", "save", "say", "scale",
        "scan", "scare", "scatter", "scene", "scheme", "school", "science", "scissors",
        "scorpion", "scout", "scrap", "screen", "script", "scrub", "sea", "search",
        "season", "seat", "second", "secret", "section", "security", "seed", "seek",
        "segment", "select", "sell", "seminar", "senior", "sense", "sentence", "series",
        "service", "session", "settle", "setup", "seven", "shadow", "shaft", "shallow",
        "share", "shed", "shell", "sheriff", "shield", "shift", "shine", "ship",
        "shiver", "shock", "shoe", "shoot", "shop", "short", "shoulder", "shove",
        "shrimp", "shrug", "shuffle", "shy", "sibling", "siege", "sight", "sign",
        "silent", "silk", "silly", "silver", "similar", "simple", "since", "sing",
        "siren", "sister", "situate", "six", "size", "ski", "skill", "skin",
        "skirt", "skull", "slab", "slam", "sleep", "slender", "slice", "slide",
        "slight", "slim", "slogan", "slot", "slow", "slush", "small", "smart",
        "smile", "smoke", "smooth", "snack", "snake", "snap", "sniff", "snow",
        "soap", "soccer", "social", "sock", "solar", "soldier", "solid", "solution",
        "solve", "someone", "song", "soon", "sorry", "soul", "sound", "soup",
        "source", "south", "space", "spare", "spatial", "spawn", "speak", "special",
        "speed", "sphere", "spice", "spider", "spike", "spin", "spirit", "split",
        "spoil", "sponsor", "spoon", "spray", "spread", "spring", "spy", "square",
        "squeeze", "squirrel", "stable", "stadium", "staff", "stage", "stairs", "stamp",
        "stand", "start", "state", "stay", "steak", "steel", "stem", "step",
        "stereo", "stick", "still", "sting", "stock", "stomach", "stone", "stop",
        "store", "storm", "story", "stove", "strategy", "street", "strike", "strong",
        "struggle", "student", "stuff", "stumble", "subject", "submit", "subway", "success",
        "such", "sudden", "suffer", "sugar", "suggest", "suit", "summer", "sun",
        "sunny", "sunset", "super", "supply", "supreme", "sure", "surface", "surge",
        "surprise", "sustain", "swallow", "swamp", "swap", "swear", "sweet", "swift",
        "swim", "swing", "switch", "sword", "symbol", "symptom", "syrup", "table",
        "tackle", "tag", "tail", "talent", "tank", "tape", "target", "task",
        "tattoo", "taxi", "teach", "team", "tell", "ten", "tenant", "tennis",
        "tent", "term", "test", "text", "thank", "that", "theme", "then",
        "theory", "there", "they", "thing", "this", "thought", "three", "thrive",
        "throw", "thumb", "thunder", "ticket", "tilt", "timber", "time", "tiny",
        "tip", "tired", "title", "toast", "tobacco", "today", "together", "toilet",
        "token", "tomato", "tomorrow", "tone", "tongue", "tonight", "tool", "topic",
        "topple", "torch", "tornado", "tortoise", "toss", "total", "tourist", "toward",
        "tower", "town", "toy", "track", "trade", "traffic", "tragic", "train",
        "transfer", "trap", "trash", "travel", "tray", "treat", "tree", "trend",
        "trial", "tribe", "trick", "trigger", "trim", "trip", "trophy", "trouble",
        "truck", "truly", "trumpet", "trust", "truth", "try", "tube", "tuition",
        "tumble", "tuna", "tunnel", "turkey", "turn", "turtle", "twelve", "twenty",
        "twice", "twin", "twist", "two", "type", "typical", "ugly", "umbrella",
        "unable", "unaware", "uncle", "uncover", "under", "undo", "unfair", "unfold",
        "unhappy", "uniform", "unique", "universe", "unknown", "unlock", "until", "unusual",
        "unveil", "update", "upgrade", "uphold", "upon", "upper", "upset", "urban",
        "useful", "useless", "usual", "utility", "vacant", "vacuum", "vague", "valid",
        "valley", "valve", "van", "vanish", "vapor", "various", "vast", "vault",
        "vehicle", "velvet", "vendor", "venture", "venue", "verb", "verify", "version",
        "very", "veteran", "viable", "vibrant", "vicious", "victory", "video", "view",
        "village", "vintage", "violin", "virtual", "virus", "visa", "visit", "visual",
        "vital", "vivid", "vocal", "voice", "void", "volcano", "volume", "vote",
        "voyage", "wage", "wagon", "wait", "walk", "wall", "walnut", "want",
        "warfare", "warm", "warrior", "waste", "water", "wave", "way", "wealth",
        "weapon", "wear", "weasel", "weather", "web", "wedding", "weekend", "weird",
        "welcome", "well", "west", "wet", "whale", "wheat", "wheel", "when",
        "where", "whip", "whisper", "wide", "width", "wife", "wild", "will",
        "win", "window", "wine", "wing", "wink", "winner", "winter", "wire",
        "wisdom", "wise", "wish", "witness", "wolf", "woman", "wonder", "wood",
        "wool", "word", "world", "worry", "worth", "wrap", "wreck", "wrestle",
        "wrist", "write", "wrong", "yard", "year", "yellow", "you", "young",
        "youth", "zebra", "zero", "zone", "zoo"
    };
    s_wordListLoaded = true;
}

const QStringList& BIP39::wordList() {
    loadWordList();
    return s_wordList;
}

QStringList BIP39::generateMnemonic(int wordCount) {
    loadWordList();
    if (s_wordList.size() < 2048) {
        qWarning() << "BIP39: Lista de palavras incompleta, usando lista disponível";
    }

    // Gerar entropia aleatória
    int entropyBits = (wordCount == 12) ? 128 : (wordCount == 15) ? 160 :
                      (wordCount == 18) ? 192 : (wordCount == 21) ? 224 : 256;
    int entropyBytes = entropyBits / 8;

    QByteArray entropy(entropyBytes, 0);
    QRandomGenerator::securelySeeded().fillRange(
        reinterpret_cast<quint32*>(entropy.data()),
        entropyBytes / sizeof(quint32)
    );

    // Calcular checksum
    QByteArray hash = QCryptographicHash::hash(entropy, QCryptographicHash::Sha256);
    int checksumBits = entropyBits / 32;

    // Combinar entropia + checksum em bits
    QVector<bool> bits;
    for (int i = 0; i < entropyBytes; ++i) {
        for (int b = 7; b >= 0; --b) {
            bits.push_back((entropy[i] >> b) & 1);
        }
    }
    for (int b = 7; b >= 8 - checksumBits; --b) {
        bits.push_back((hash[0] >> b) & 1);
    }

    // Converter grupos de 11 bits em índices de palavras
    QStringList mnemonic;
    int listSize = s_wordList.size();
    for (int i = 0; i < wordCount; ++i) {
        int index = 0;
        for (int b = 0; b < 11; ++b) {
            index = (index << 1) | (bits[i * 11 + b] ? 1 : 0);
        }
        mnemonic.append(s_wordList[index % listSize]);
    }

    return mnemonic;
}

bool BIP39::validateMnemonic(const QStringList& words) {
    loadWordList();
    if (words.size() != 12 && words.size() != 15 &&
        words.size() != 18 && words.size() != 21 && words.size() != 24) {
        return false;
    }
    for (const QString& word : words) {
        if (!s_wordList.contains(word.toLower())) {
            return false;
        }
    }
    return true;
}

QByteArray BIP39::mnemonicToSeed(const QStringList& words, const QString& passphrase) {
    QString mnemonic = words.join(QLatin1Char(' '));
    QByteArray salt = QByteArray("mnemonic") + passphrase.toUtf8();
    return Crypto::pbkdf2HmacSha512(mnemonic.toUtf8(), salt, 2048, 64);
}

// ============================================================
// HDWallet - Implementação
// ============================================================
HDWallet::HDWallet(QObject* parent)
    : QObject(parent)
    , m_initialized(false)
    , m_receiveIndex(0)
    , m_changeIndex(0)
{}

HDWallet::~HDWallet() {
    // Limpar dados sensíveis da memória
    m_seed.fill(0);
    m_masterKey.privateKey.fill(0);
}

bool HDWallet::createNew(const QString& passphrase) {
    m_mnemonic = BIP39::generateMnemonic(12);
    m_seed = BIP39::mnemonicToSeed(m_mnemonic, passphrase);

    // Derivar chave mestre BIP32
    QByteArray key = "Bitcoin seed";
    QByteArray I = hmacSha512(key, m_seed);

    m_masterKey.privateKey = I.left(32);
    m_masterKey.chainCode  = I.right(32);
    m_masterKey.depth = 0;
    m_masterKey.childNumber = 0;
    m_masterKey.publicKey = secp256k1PrivToPub(m_masterKey.privateKey);

    m_initialized = m_masterKey.isValid();
    m_receiveIndex = 0;
    m_changeIndex = 0;

    if (m_initialized) {
        Q_EMIT walletCreated();
    }
    return m_initialized;
}

bool HDWallet::restore(const QStringList& mnemonic, const QString& passphrase) {
    if (!BIP39::validateMnemonic(mnemonic)) {
        Q_EMIT errorOccurred("Mnemônico inválido");
        return false;
    }

    m_mnemonic = mnemonic;
    m_seed = BIP39::mnemonicToSeed(mnemonic, passphrase);

    QByteArray key = "Bitcoin seed";
    QByteArray I = hmacSha512(key, m_seed);

    m_masterKey.privateKey = I.left(32);
    m_masterKey.chainCode  = I.right(32);
    m_masterKey.depth = 0;
    m_masterKey.childNumber = 0;
    m_masterKey.publicKey = secp256k1PrivToPub(m_masterKey.privateKey);

    m_initialized = m_masterKey.isValid();
    m_receiveIndex = 0;
    m_changeIndex = 0;

    if (m_initialized) {
        Q_EMIT walletLoaded();
    }
    return m_initialized;
}

HDNode HDWallet::deriveChildKey(const HDNode& parent, uint32_t index) const {
    HDNode child;
    child.depth = parent.depth + 1;
    child.childNumber = index;

    QByteArray data;
    bool hardened = (index & HARDENED) != 0;

    if (hardened) {
        data.append('\x00');
        data.append(parent.privateKey);
    } else {
        data.append(parent.publicKey);
    }

    // Adicionar índice em big-endian
    data.append((char)((index >> 24) & 0xFF));
    data.append((char)((index >> 16) & 0xFF));
    data.append((char)((index >> 8) & 0xFF));
    data.append((char)(index & 0xFF));

    QByteArray I = hmacSha512(parent.chainCode, data);
    QByteArray IL = I.left(32);
    QByteArray IR = I.right(32);

    
    child.chainCode = IR;
    child.privateKey = parent.privateKey;
    if (!Crypto::privateKeyAdd(child.privateKey, IL)) {
        return HDNode();
    }
    
    child.publicKey = Crypto::privateKeyToPublicKey(child.privateKey, true);
    if (child.publicKey.isEmpty()) {
        child.publicKey = secp256k1PrivToPub(child.privateKey);
    }

    // Calcular fingerprint (primeiros 4 bytes do hash160 da chave pública pai)
    QByteArray parentPubHash = hash160(parent.publicKey);
    child.fingerprint = parentPubHash.left(4);

    return child;
}

HDNode HDWallet::derivePath(const QString& path) const {
    HDNode current = m_masterKey;

    QStringList parts = path.split('/');
    for (int i = 1; i < parts.size(); ++i) {
        QString part = parts[i];
        bool hardened = part.endsWith('\'');
        if (hardened) part.chop(1);

        bool ok;
        uint32_t index = part.toUInt(&ok);
        if (!ok) return HDNode();

        if (hardened) index |= HARDENED;
        current = deriveChildKey(current, index);
    }

    return current;
}

HDNode HDWallet::deriveAccount(uint32_t account) const {
    // BIP44: m/44'/coin_type'/account'
    QString path = QString("m/44'/%1'/%2'").arg(COIN_TYPE).arg(account);
    return derivePath(path);
}

QString HDWallet::deriveReceiveAddress(uint32_t index) const {
    if (!m_initialized) return QString();
    // BIP44: m/44'/0'/0'/0/index
    HDNode account = deriveAccount(0);
    HDNode external = deriveChildKey(account, 0);  // external chain
    HDNode key = deriveChildKey(external, index);
    return pubkeyToAddress(key.publicKey);
}

QString HDWallet::deriveChangeAddress(uint32_t index) const {
    if (!m_initialized) return QString();
    // BIP44: m/44'/0'/0'/1/index
    HDNode account = deriveAccount(0);
    HDNode internal = deriveChildKey(account, 1);  // internal chain
    HDNode key = deriveChildKey(internal, index);
    return pubkeyToAddress(key.publicKey);
}

QByteArray HDWallet::derivePrivateKey(uint32_t index, bool change) const {
    if (!m_initialized) return QByteArray();
    HDNode account = deriveAccount(0);
    HDNode chain = deriveChildKey(account, change ? 1 : 0);
    HDNode key = deriveChildKey(chain, index);
    return key.privateKey;
}

QByteArray HDWallet::derivePublicKey(uint32_t index, bool change) const {
    if (!m_initialized) return QByteArray();
    HDNode account = deriveAccount(0);
    HDNode chain = deriveChildKey(account, change ? 1 : 0);
    HDNode key = deriveChildKey(chain, index);
    return key.publicKey;
}

QByteArray HDWallet::hash160(const QByteArray& pubkey) {
    QByteArray sha256 = QCryptographicHash::hash(pubkey, QCryptographicHash::Sha256);
    unsigned char hash_res[20];
    RIPEMD160_CTX ctx;
    RIPEMD160_Init(&ctx);
    RIPEMD160_Update(&ctx, reinterpret_cast<const unsigned char*>(sha256.constData()), sha256.size());
    RIPEMD160_Final(hash_res, &ctx);
    return QByteArray(reinterpret_cast<char*>(hash_res), 20);
}

QString HDWallet::pubkeyToAddress(const QByteArray& pubkey, uint8_t prefix) {
    QByteArray h160 = hash160(pubkey);
    return Base58::pubkeyHashToAddress(h160, prefix);
}

QByteArray HDWallet::hmacSha512(const QByteArray& key, const QByteArray& data) {
    return QMessageAuthenticationCode::hash(data, key, QCryptographicHash::Sha512);
}

QByteArray HDWallet::secp256k1PrivToPub(const QByteArray& privkey) {
    if (privkey.size() != 32) return QByteArray();

    EC_KEY* eckey = EC_KEY_new_by_curve_name(NID_secp256k1);
    if (!eckey) return QByteArray();

    BIGNUM* bn = BN_bin2bn(
        reinterpret_cast<const unsigned char*>(privkey.constData()),
        32, nullptr
    );

    EC_KEY_set_private_key(eckey, bn);

    const EC_GROUP* group = EC_KEY_get0_group(eckey);
    EC_POINT* pubkey_point = EC_POINT_new(group);
    EC_POINT_mul(group, pubkey_point, bn, nullptr, nullptr, nullptr);
    EC_KEY_set_public_key(eckey, pubkey_point);

    // Serializar chave pública comprimida (33 bytes)
    unsigned char pub[33];
    EC_POINT_point2oct(group, pubkey_point,
                       POINT_CONVERSION_COMPRESSED,
                       pub, 33, nullptr);

    EC_POINT_free(pubkey_point);
    BN_free(bn);
    EC_KEY_free(eckey);

    return QByteArray(reinterpret_cast<char*>(pub), 33);
}

bool HDWallet::saveToFile(const QString& filePath, const QString& password) const {
    if (!m_initialized) return false;

    QJsonObject obj;
    obj["version"] = "2.0.2";
    obj["coin"] = "2x2coin";
    obj["mnemonic"] = m_mnemonic.join(" ");
    obj["receive_index"] = (int)m_receiveIndex;
    obj["change_index"] = (int)m_changeIndex;

    QJsonDocument doc(obj);
    QByteArray data = doc.toJson(QJsonDocument::Compact);
    QByteArray key = deriveFileKey(password);
    QByteArray encrypted = encryptWalletPayload(data, key);
    if (encrypted.isEmpty()) {
        return false;
    }

    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly)) return false;
    file.write(encrypted);
    file.close();

    const_cast<HDWallet*>(this)->walletSaved();
    return true;
}

bool HDWallet::loadFromFile(const QString& filePath, const QString& password) {
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) return false;
    QByteArray encrypted = file.readAll();
    file.close();

    QByteArray key = deriveFileKey(password);
    QByteArray data = decryptWalletPayload(encrypted, key);
    if (data.isEmpty()) {
        Q_EMIT errorOccurred("Senha incorreta ou arquivo de carteira inválido");
        return false;
    }

    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isNull()) return false;

    QJsonObject obj = doc.object();
    QStringList mnemonic = obj["mnemonic"].toString().split(" ");
    m_receiveIndex = obj["receive_index"].toInt(0);
    m_changeIndex = obj["change_index"].toInt(0);

    return restore(mnemonic, "");
}

QString HDWallet::exportXPub() const {
    if (!m_initialized) return QString();
    HDNode account = deriveAccount(0);

    QByteArray data;
    data.append(QByteArray("\x04\x88\xB2\x1E", 4));  // xpub prefix
    data.append((char)account.depth);
    data.append(account.fingerprint);
    // child number
    data.append((char)((account.childNumber >> 24) & 0xFF));
    data.append((char)((account.childNumber >> 16) & 0xFF));
    data.append((char)((account.childNumber >> 8) & 0xFF));
    data.append((char)(account.childNumber & 0xFF));
    data.append(account.chainCode);
    data.append(account.publicKey);

    return Base58::encodeCheck(data);
}

} // namespace Coin2x2
