#!/bin/bash

# Noms des appareils à tester
DEVICE_NAMES=(
    "iPhone 17"
    "iPad Pro 13-inch (M5)"
)

# Fonction d'affichage avec couleur
log_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

# Parcourir chaque appareil
for NAME in "${DEVICE_NAMES[@]}"; do
    log_info "🔍 Récupération de l'identifiant pour $NAME..."
    
    # Récupérer l'UDID exact du simulateur pour éviter qu'Xcode scanne les appareils physiques (évite l'erreur passcode)
    UDID=$(xcrun simctl list devices -j | python3 -c "import sys, json; data=json.load(sys.stdin); print(next((d['udid'] for k,v in data['devices'].items() for d in v if d['name'] == '$NAME' and d['isAvailable']), ''))")
    
    if [ -z "$UDID" ]; then
        log_error "Impossible de trouver un simulateur valide pour $NAME"
        exit 1
    fi
    
    log_info "🚀 Démarrage des tests (Portrait & Paysage) sur le simulateur : $NAME ($UDID)"
    
    xcodebuild test \
        -project Joiefull/Joiefull.xcodeproj \
        -scheme Joiefull \
        -testPlan Joiefull \
        -destination "platform=iOS Simulator,id=$UDID"
        
    if [ $? -eq 0 ]; then
        log_info "✅ Tests réussis sur $NAME !"
    else
        log_error "❌ Échec des tests sur $NAME."
        exit 1
    fi
done

log_info "🎉 Tous les tests sont passés avec succès sur tous les appareils dans les deux orientations (Portrait et Paysage) !"
exit 0
