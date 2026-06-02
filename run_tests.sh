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

# Parcourir chaque appareil pour obtenir les UDIDs
DESTINATIONS=""
for NAME in "${DEVICE_NAMES[@]}"; do
    log_info "🔍 Récupération de l'identifiant pour $NAME..."
    
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
=======
    DESTINATIONS="$DESTINATIONS -destination \"platform=iOS Simulator,id=$UDID\""
done

log_info "🚀 Démarrage des tests combinés..."

# Supprimer le dossier de résultats précédent s'il existe
rm -rf combined_result.xcresult

# Utiliser eval pour étendre correctement la chaîne DESTINATIONS
eval xcodebuild test \
    -project Joiefull/Joiefull.xcodeproj \
    -scheme Joiefull \
    -testPlan Joiefull \
    -resultBundlePath combined_result.xcresult \
    $DESTINATIONS

if [ $? -eq 0 ]; then
    log_info "✅ Tests réussis !"
    log_info "🎉 Tous les tests sont passés avec succès sur tous les appareils dans les deux orientations (Portrait et Paysage) !"
    
    # Afficher la couverture de ContentView.swift
    xcrun xccov view --report combined_result.xcresult | grep "ContentView.swift"
    
    exit 0
else
    log_error "❌ Échec des tests."
    exit 1
fi
>>>>>>> 85145f2 (test(tests): add UI and unit tests)
