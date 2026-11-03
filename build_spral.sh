#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
REPO_URL="https://github.com/ralna/spral.git"
TARGET_COMMIT="80bc843ac3847d4a783a0e11213715a70175aee6"
BUILD_DIR="build_meson"
INSTALL_DIR="$(pwd)/spral_install"

echo "=== 1. Clonage du dépôt SPRAL ==="
if [ -d "spral" ]; then
    echo "Le dossier 'spral' existe déjà. Mise à jour..."
    cd spral
else
    git clone "$REPO_URL" spral
    cd spral
fi

echo "=== 2. Basculement sur le commit $TARGET_COMMIT ==="
git checkout "$TARGET_COMMIT"

echo "=== 3. Configuration avec Meson (Bibliothèque statique) ==="
# On configure Meson pour compiler des bibliothèques statiques par défaut
meson setup "$BUILD_DIR" \
    --buildtype=release \
    --default-library=static \
    -Dc_link_args="-L/unopy-0.4.16/dependencies/lib -lblas -llapack" \
    -Dcpp_link_args="-L/unopy-0.4.16/dependencies/lib -lblas -llapack" \
    -Dfortran_link_args="-L/unopy-0.4.16/dependencies/lib -lblas -llapack" \
    --prefix="$INSTALL_DIR"

echo "=== 4. Compilation ==="
meson compile -C "$BUILD_DIR"

echo "=== 5. Installation locale ==="
meson install -C "$BUILD_DIR"

echo "=== Terminé ! ==="
echo "La bibliothèque statique et les en-têtes ont été installés dans : $INSTALL_DIR"
echo "Fichiers générés :"
find "$INSTALL_DIR" -name "*.a" -o -name "*.mod"
