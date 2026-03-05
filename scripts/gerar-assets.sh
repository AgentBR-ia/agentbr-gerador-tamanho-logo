#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
FONTE_DIR="${ROOT_DIR}/fonte"

if ! command -v sips >/dev/null 2>&1; then
  echo "Erro: sips nao encontrado (macOS)." >&2
  exit 1
fi

if ! command -v iconutil >/dev/null 2>&1; then
  echo "Erro: iconutil nao encontrado (macOS)." >&2
  exit 1
fi

if [[ "$#" -gt 1 ]]; then
  cat >&2 <<MSG
Uso:
  ${0}
  ${0} /caminho/da/sua-logo.png
MSG
  exit 1
fi

OUT_DIR="${ROOT_DIR}/saida"
PNG_DIR="${OUT_DIR}/png"
TAMANHOS_DIR="${PNG_DIR}/tamanhos"
ICO_DIR="${OUT_DIR}/ico"
ICNS_DIR="${OUT_DIR}/icns"
TMP_DIR="${OUT_DIR}/tmp"
TMP_PNG_DIR="${TMP_DIR}/png"
ICONSET_DIR="${TMP_DIR}/app.iconset"

SOURCE_IMAGE=""
if [[ "$#" -eq 1 ]]; then
  SOURCE_IMAGE="$1"
  if [[ ! -f "${SOURCE_IMAGE}" ]]; then
    echo "Erro: arquivo nao encontrado: ${SOURCE_IMAGE}" >&2
    exit 1
  fi
else
  SOURCE_CANDIDATES=()
  while IFS= read -r CANDIDATE; do
    SOURCE_CANDIDATES+=("${CANDIDATE}")
  done < <(
    find "${FONTE_DIR}" -maxdepth 1 -type f \
      \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.heic' -o -iname '*.tiff' \) \
      ! -name '.*' -print | LC_ALL=C sort
  )

  if [[ "${#SOURCE_CANDIDATES[@]}" -eq 0 ]]; then
    cat >&2 <<MSG
Erro: nenhuma imagem encontrada em ${FONTE_DIR}.
Coloque sua logo em fonte/ com qualquer nome (ex.: minha-logo.png)
ou rode com caminho explicito:
  ${0} /caminho/da/sua-logo.png
MSG
    exit 1
  fi

  if [[ "${#SOURCE_CANDIDATES[@]}" -gt 1 ]]; then
    echo "Erro: mais de uma imagem encontrada em ${FONTE_DIR}." >&2
    echo "Arquivos encontrados:" >&2
    for CANDIDATE in "${SOURCE_CANDIDATES[@]}"; do
      echo "  - ${CANDIDATE}" >&2
    done
    echo "Informe o caminho explicito da logo para gerar os assets." >&2
    exit 1
  fi

  SOURCE_IMAGE="${SOURCE_CANDIDATES[0]}"
fi

SOURCE_FILENAME="$(basename "${SOURCE_IMAGE}")"
LOGO_BASE_NAME="${SOURCE_FILENAME%.*}"

mkdir -p "${PNG_DIR}" "${TAMANHOS_DIR}" "${ICO_DIR}" "${ICNS_DIR}"
find "${PNG_DIR}" -mindepth 1 -type f ! -name '.gitkeep' -delete
find "${ICO_DIR}" -mindepth 1 -type f ! -name '.gitkeep' -delete
find "${ICNS_DIR}" -mindepth 1 -type f ! -name '.gitkeep' -delete
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_PNG_DIR}" "${ICONSET_DIR}"

# Tamanhos intermediarios para gerar aliases e derivados.
SIZES=(16 32 64 128 180 192 256 512 1024 2048)
for SIZE in "${SIZES[@]}"; do
  sips -z "${SIZE}" "${SIZE}" "${SOURCE_IMAGE}" --out "${TMP_PNG_DIR}/${SIZE}.png" >/dev/null
done

cp "${TMP_PNG_DIR}/16.png" "${PNG_DIR}/favicon-16x16.png"
cp "${TMP_PNG_DIR}/32.png" "${PNG_DIR}/favicon-32x32.png"
cp "${TMP_PNG_DIR}/180.png" "${PNG_DIR}/apple-touch-icon.png"
cp "${TMP_PNG_DIR}/192.png" "${PNG_DIR}/android-chrome-192x192.png"
cp "${TMP_PNG_DIR}/512.png" "${PNG_DIR}/android-chrome-512x512.png"

# PNGs extras em potencias de 2 ate 2048.
SIZE_VARIANTS=(16 32 64 128 256 512 1024 2048)
for SIZE in "${SIZE_VARIANTS[@]}"; do
  cp "${TMP_PNG_DIR}/${SIZE}.png" "${TAMANHOS_DIR}/${LOGO_BASE_NAME}-${SIZE}x${SIZE}.png"
done

# Iconset padrao do macOS para gerar .icns.
cp "${TMP_PNG_DIR}/16.png" "${ICONSET_DIR}/icon_16x16.png"
cp "${TMP_PNG_DIR}/32.png" "${ICONSET_DIR}/icon_16x16@2x.png"
cp "${TMP_PNG_DIR}/32.png" "${ICONSET_DIR}/icon_32x32.png"
cp "${TMP_PNG_DIR}/64.png" "${ICONSET_DIR}/icon_32x32@2x.png"
cp "${TMP_PNG_DIR}/128.png" "${ICONSET_DIR}/icon_128x128.png"
cp "${TMP_PNG_DIR}/256.png" "${ICONSET_DIR}/icon_128x128@2x.png"
cp "${TMP_PNG_DIR}/256.png" "${ICONSET_DIR}/icon_256x256.png"
cp "${TMP_PNG_DIR}/512.png" "${ICONSET_DIR}/icon_256x256@2x.png"
cp "${TMP_PNG_DIR}/512.png" "${ICONSET_DIR}/icon_512x512.png"
cp "${TMP_PNG_DIR}/1024.png" "${ICONSET_DIR}/icon_512x512@2x.png"

ICNS_OK=0
if iconutil -c icns "${ICONSET_DIR}" -o "${ICNS_DIR}/app.icns" >/dev/null 2>&1; then
  ICNS_OK=1
else
  # Fallback para ambientes onde iconutil falha.
  if sips -s format icns "${TMP_PNG_DIR}/1024.png" --out "${ICNS_DIR}/app.icns" >/dev/null 2>&1; then
    ICNS_OK=1
  fi
fi

# Um .ico principal para websites.
ICO_OK=0
if sips -s format ico "${TMP_PNG_DIR}/256.png" --out "${ICO_DIR}/favicon.ico" >/dev/null 2>&1; then
  ICO_OK=1
fi

rm -rf "${TMP_DIR}"

cat <<MSG
Assets gerados com sucesso:
- PNG:   ${PNG_DIR}
- PNG (tamanhos): ${TAMANHOS_DIR}
- ICO:   ${ICO_DIR}
- ICNS:  ${ICNS_DIR}
- Fonte usada: ${SOURCE_IMAGE}

Arquivos principais:
- ${PNG_DIR}/favicon-16x16.png
- ${PNG_DIR}/favicon-32x32.png
- ${PNG_DIR}/apple-touch-icon.png
- ${PNG_DIR}/android-chrome-192x192.png
- ${PNG_DIR}/android-chrome-512x512.png
- ${TAMANHOS_DIR}/${LOGO_BASE_NAME}-16x16.png ... ${LOGO_BASE_NAME}-2048x2048.png
MSG

if [[ "${ICO_OK}" -eq 1 ]]; then
  echo "- ${ICO_DIR}/favicon.ico"
else
  echo "- Aviso: .ico nao foi gerado neste ambiente."
fi

if [[ "${ICNS_OK}" -eq 1 ]]; then
  echo "- ${ICNS_DIR}/app.icns"
else
  echo "- Aviso: .icns nao foi gerado neste ambiente (tente rodar localmente no macOS)."
fi
