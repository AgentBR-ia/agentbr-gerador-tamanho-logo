#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
FONTE_DIR="${ROOT_DIR}/fonte"

OUT_DIR="${ROOT_DIR}/saida"
PNG_DIR="${OUT_DIR}/png"
TAMANHOS_DIR="${PNG_DIR}/tamanhos"
ICO_DIR="${OUT_DIR}/ico"
ICNS_DIR="${OUT_DIR}/icns"
SVG_DIR="${OUT_DIR}/svg"
TMP_DIR="${OUT_DIR}/tmp"
TMP_PNG_DIR="${TMP_DIR}/png"
ICONSET_DIR="${TMP_DIR}/app.iconset"

WARNINGS=()

usage() {
  cat <<MSG
Uso:
  ${0} [--install-deps] [caminho/da/logo]

Exemplos:
  ${0}
  ${0} /caminho/da/sua-logo.png
  ${0} --install-deps
  ${0} --install-deps /caminho/da/sua-logo.png
MSG
}

add_warning() {
  WARNINGS+=("$1")
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

run_as_admin() {
  if [[ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]]; then
    "$@"
    return $?
  fi

  if have_cmd sudo; then
    sudo -n "$@"
    return $?
  fi

  "$@"
}

detect_platform() {
  local uname_s
  uname_s="$(uname -s 2>/dev/null || echo unknown)"

  case "${uname_s}" in
    Darwin*) echo "macos" ;;
    Linux*) echo "linux" ;;
    CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
    *) echo "unknown" ;;
  esac
}

install_svg_dependencies() {
  local platform="$1"

  if [[ "${platform}" == "macos" ]]; then
    if have_cmd brew; then
      if brew install imagemagick potrace; then
        return 0
      fi
      add_warning "Falha ao instalar imagemagick/potrace via brew."
      return 1
    fi

    add_warning "brew nao encontrado no macOS para auto-instalacao."
    return 1
  fi

  if [[ "${platform}" == "linux" ]]; then
    if have_cmd apt-get; then
      if run_as_admin apt-get update && run_as_admin apt-get install -y imagemagick potrace; then
        return 0
      fi
      add_warning "Falha ao instalar imagemagick/potrace via apt-get."
      return 1
    fi

    if have_cmd dnf; then
      if run_as_admin dnf install -y ImageMagick potrace; then
        return 0
      fi
      add_warning "Falha ao instalar imagemagick/potrace via dnf."
      return 1
    fi

    if have_cmd yum; then
      if run_as_admin yum install -y ImageMagick potrace; then
        return 0
      fi
      add_warning "Falha ao instalar imagemagick/potrace via yum."
      return 1
    fi

    if have_cmd pacman; then
      if run_as_admin pacman -Sy --noconfirm imagemagick potrace; then
        return 0
      fi
      add_warning "Falha ao instalar imagemagick/potrace via pacman."
      return 1
    fi

    add_warning "Nenhum gerenciador de pacotes suportado encontrado no Linux (apt/dnf/yum/pacman)."
    return 1
  fi

  if [[ "${platform}" == "windows" ]]; then
    local im_ok=0
    local pt_ok=0

    if have_cmd winget; then
      if winget install --id ImageMagick.ImageMagick -e --accept-source-agreements --accept-package-agreements --silent; then
        im_ok=1
      else
        add_warning "Falha ao instalar ImageMagick via winget."
      fi
    elif have_cmd choco; then
      if choco install imagemagick -y; then
        im_ok=1
      else
        add_warning "Falha ao instalar ImageMagick via choco."
      fi
    else
      add_warning "winget/choco nao encontrados para instalar ImageMagick no Windows."
    fi

    if have_cmd choco; then
      if choco install potrace -y; then
        pt_ok=1
      else
        add_warning "Falha ao instalar potrace via choco."
      fi
    else
      add_warning "choco nao encontrado para instalar potrace no Windows."
    fi

    if [[ "${im_ok}" -eq 1 && "${pt_ok}" -eq 1 ]]; then
      return 0
    fi

    return 1
  fi

  add_warning "Plataforma nao reconhecida para auto-instalacao de dependencias SVG."
  return 1
}

select_raster_tool() {
  if have_cmd sips; then
    echo "sips"
    return
  fi

  if have_cmd magick; then
    echo "magick"
    return
  fi

  if have_cmd convert; then
    echo "convert"
    return
  fi

  echo "none"
}

select_vector_raster_tool() {
  if have_cmd magick; then
    echo "magick"
    return
  fi

  if have_cmd convert; then
    echo "convert"
    return
  fi

  echo "none"
}

resize_square() {
  local tool="$1"
  local src="$2"
  local size="$3"
  local out="$4"

  case "${tool}" in
    sips)
      sips -z "${size}" "${size}" "${src}" --out "${out}" >/dev/null
      ;;
    magick)
      magick "${src}" -resize "${size}x${size}!" "${out}" >/dev/null 2>&1
      ;;
    convert)
      convert "${src}" -resize "${size}x${size}!" "${out}" >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

generate_ico() {
  local tool="$1"
  local src="$2"
  local out="$3"

  case "${tool}" in
    sips)
      sips -s format ico "${src}" --out "${out}" >/dev/null
      ;;
    magick)
      magick "${src}" -define icon:auto-resize=16,32,48,64,128,256 "${out}" >/dev/null 2>&1
      ;;
    convert)
      convert "${src}" -define icon:auto-resize=16,32,48,64,128,256 "${out}" >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

convert_to_bmp() {
  local src="$1"
  local out="$2"

  if have_cmd sips; then
    sips -s format bmp "${src}" --out "${out}" >/dev/null
    return
  fi

  if have_cmd magick; then
    magick "${src}" "${out}" >/dev/null 2>&1
    return
  fi

  if have_cmd convert; then
    convert "${src}" "${out}" >/dev/null 2>&1
    return
  fi

  return 1
}

get_dimensions() {
  local src="$1"

  if have_cmd sips; then
    local w h
    w="$(sips -g pixelWidth "${src}" | awk '/pixelWidth:/{print $2}' | tail -n1)"
    h="$(sips -g pixelHeight "${src}" | awk '/pixelHeight:/{print $2}' | tail -n1)"
    if [[ -n "${w}" && -n "${h}" ]]; then
      echo "${w} ${h}"
      return 0
    fi
  fi

  if have_cmd magick; then
    magick identify -format "%w %h" "${src}" 2>/dev/null
    return $?
  fi

  if have_cmd identify; then
    identify -format "%w %h" "${src}" 2>/dev/null
    return $?
  fi

  echo "1024 1024"
  return 1
}

get_source_mime() {
  local src="$1"
  local ext
  ext="${src##*.}"
  ext="$(printf '%s' "${ext}" | tr '[:upper:]' '[:lower:]')"

  case "${ext}" in
    png) echo "image/png" ;;
    jpg|jpeg) echo "image/jpeg" ;;
    webp) echo "image/webp" ;;
    heic) echo "image/heic" ;;
    tif|tiff) echo "image/tiff" ;;
    svg) echo "image/svg+xml" ;;
    bmp) echo "image/bmp" ;;
    gif) echo "image/gif" ;;
    *) echo "application/octet-stream" ;;
  esac
}

capture_top_left_bg_color() {
  local src="$1"
  local probe_bmp="${TMP_DIR}/bg_probe.bmp"

  if ! convert_to_bmp "${src}" "${probe_bmp}"; then
    echo "#FFFFFF"
    return 1
  fi

  if python3 - "${probe_bmp}" <<'PY'
import struct
import sys

path = sys.argv[1]

try:
    with open(path, "rb") as f:
        data = f.read()

    if data[:2] != b"BM":
        print("#FFFFFF")
        raise SystemExit(1)

    offset = struct.unpack_from("<I", data, 10)[0]
    width = struct.unpack_from("<i", data, 18)[0]
    height = struct.unpack_from("<i", data, 22)[0]
    bpp = struct.unpack_from("<H", data, 28)[0]

    w = abs(width)
    h = abs(height)
    if w == 0 or h == 0:
        print("#FFFFFF")
        raise SystemExit(1)

    row_stride = ((bpp * w + 31) // 32) * 4

    x = 0
    y = 0
    row_index = y if height < 0 else (h - 1 - y)
    pos = offset + row_index * row_stride + x * (bpp // 8)

    if bpp >= 32:
        b, g, r, a = data[pos:pos+4]
    elif bpp >= 24:
        b, g, r = data[pos:pos+3]
        a = 255
    else:
        print("#FFFFFF")
        raise SystemExit(1)

    if a == 0:
        print("#FFFFFF")
    else:
        print(f"#{r:02X}{g:02X}{b:02X}")
except Exception:
    print("#FFFFFF")
    raise
PY
  then
    return 0
  fi

  echo "#FFFFFF"
  return 1
}

create_embed_svg() {
  local out="$1"
  local include_bg="$2"
  local width="$3"
  local height="$4"
  local bg_color="$5"
  local source_mime="$6"
  local source_file="$7"

  {
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s">\n' "${width}" "${height}" "${width}" "${height}"
    if [[ "${include_bg}" -eq 1 ]]; then
      printf '  <rect width="100%%" height="100%%" fill="%s" />\n' "${bg_color}"
    fi
    printf '  <image href="data:%s;base64,' "${source_mime}"
    base64 < "${source_file}" | tr -d '\r\n'
    printf '" width="%s" height="%s" preserveAspectRatio="xMidYMid meet" />\n' "${width}" "${height}"
    printf '</svg>\n'
  } > "${out}"
}

make_vector_mask() {
  local tool="$1"
  local src="$2"
  local out="$3"

  case "${tool}" in
    magick)
      magick "${src}" -alpha extract -colorspace Gray -threshold 1% "${out}" >/dev/null 2>&1
      ;;
    convert)
      convert "${src}" -alpha extract -colorspace Gray -threshold 1% "${out}" >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

create_svg_with_background_from_vector() {
  local vector_in="$1"
  local vector_out="$2"
  local bg_color="$3"

  python3 - "${vector_in}" "${vector_out}" "${bg_color}" <<'PY'
import re
import sys

src, dst, color = sys.argv[1:4]
text = open(src, "r", encoding="utf-8", errors="ignore").read()
match = re.search(r"<svg\b[^>]*>", text, flags=re.IGNORECASE)
if not match:
    raise SystemExit(1)
insert = f"\n  <rect width=\"100%\" height=\"100%\" fill=\"{color}\" />\n"
text = text[:match.end()] + insert + text[match.end():]
with open(dst, "w", encoding="utf-8") as f:
    f.write(text)
PY
}

INSTALL_DEPS=0
SOURCE_ARG=""

for ARG in "$@"; do
  case "${ARG}" in
    --install-deps)
      INSTALL_DEPS=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "Erro: opcao desconhecida: ${ARG}" >&2
      usage >&2
      exit 1
      ;;
    -*)
      echo "Erro: opcao desconhecida: ${ARG}" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -n "${SOURCE_ARG}" ]]; then
        echo "Erro: informe no maximo um caminho de logo." >&2
        usage >&2
        exit 1
      fi
      SOURCE_ARG="${ARG}"
      ;;
  esac
done

PLATFORM="$(detect_platform)"

if [[ "${INSTALL_DEPS}" -eq 1 ]]; then
  NEED_IM=1
  NEED_POT=1

  if have_cmd magick || have_cmd convert; then
    NEED_IM=0
  fi

  if have_cmd potrace; then
    NEED_POT=0
  fi

  if [[ "${NEED_IM}" -eq 1 || "${NEED_POT}" -eq 1 ]]; then
    install_svg_dependencies "${PLATFORM}" || true
  fi
fi

RASTER_TOOL="$(select_raster_tool)"
VECTOR_RASTER_TOOL="$(select_vector_raster_tool)"

POTRACE_OK=0
if have_cmd potrace; then
  POTRACE_OK=1
fi

SOURCE_IMAGE=""
if [[ -n "${SOURCE_ARG}" ]]; then
  SOURCE_IMAGE="${SOURCE_ARG}"
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
      \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.heic' -o -iname '*.tiff' -o -iname '*.svg' \) \
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

mkdir -p "${PNG_DIR}" "${TAMANHOS_DIR}" "${ICO_DIR}" "${ICNS_DIR}" "${SVG_DIR}"
find "${PNG_DIR}" -mindepth 1 -type f ! -name '.gitkeep' -delete
find "${ICO_DIR}" -mindepth 1 -type f ! -name '.gitkeep' -delete
find "${ICNS_DIR}" -mindepth 1 -type f ! -name '.gitkeep' -delete
find "${SVG_DIR}" -mindepth 1 -type f ! -name '.gitkeep' -delete
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_PNG_DIR}" "${ICONSET_DIR}"

WIDTH="1024"
HEIGHT="1024"
if DIMENSIONS="$(get_dimensions "${SOURCE_IMAGE}")"; then
  WIDTH="$(printf '%s' "${DIMENSIONS}" | awk '{print $1}')"
  HEIGHT="$(printf '%s' "${DIMENSIONS}" | awk '{print $2}')"
else
  add_warning "Nao foi possivel detectar dimensoes da imagem; usando 1024x1024 para SVG."
fi

BG_COLOR="#FFFFFF"
if BG_CAPTURED="$(capture_top_left_bg_color "${SOURCE_IMAGE}" 2>/dev/null)"; then
  if [[ "${BG_CAPTURED}" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
    BG_COLOR="${BG_CAPTURED}"
  fi
else
  add_warning "Nao foi possivel captar cor de fundo automaticamente; usando #FFFFFF."
fi

SOURCE_MIME="$(get_source_mime "${SOURCE_IMAGE}")"

SVG_SEM_EMBED="${SVG_DIR}/${LOGO_BASE_NAME}-sem-fundo-embed.svg"
SVG_COM_EMBED="${SVG_DIR}/${LOGO_BASE_NAME}-com-fundo-embed.svg"
SVG_SEM_MAIN="${SVG_DIR}/${LOGO_BASE_NAME}-sem-fundo.svg"
SVG_COM_MAIN="${SVG_DIR}/${LOGO_BASE_NAME}-com-fundo.svg"

create_embed_svg "${SVG_SEM_EMBED}" 0 "${WIDTH}" "${HEIGHT}" "${BG_COLOR}" "${SOURCE_MIME}" "${SOURCE_IMAGE}"
create_embed_svg "${SVG_COM_EMBED}" 1 "${WIDTH}" "${HEIGHT}" "${BG_COLOR}" "${SOURCE_MIME}" "${SOURCE_IMAGE}"

cp "${SVG_SEM_EMBED}" "${SVG_SEM_MAIN}"
cp "${SVG_COM_EMBED}" "${SVG_COM_MAIN}"

VECTOR_OK=0
SVG_SEM_VETOR="${SVG_DIR}/${LOGO_BASE_NAME}-sem-fundo-vetor.svg"
SVG_COM_VETOR="${SVG_DIR}/${LOGO_BASE_NAME}-com-fundo-vetor.svg"

if [[ "${POTRACE_OK}" -eq 1 && "${VECTOR_RASTER_TOOL}" != "none" ]]; then
  VECTOR_MASK="${TMP_DIR}/vector-mask.pgm"
  VECTOR_RAW="${TMP_DIR}/vector-raw.svg"

  if make_vector_mask "${VECTOR_RASTER_TOOL}" "${SOURCE_IMAGE}" "${VECTOR_MASK}" \
    && potrace "${VECTOR_MASK}" -s -o "${VECTOR_RAW}" >/dev/null 2>&1 \
    && cp "${VECTOR_RAW}" "${SVG_SEM_VETOR}" \
    && create_svg_with_background_from_vector "${VECTOR_RAW}" "${SVG_COM_VETOR}" "${BG_COLOR}"; then
    VECTOR_OK=1
    cp "${SVG_SEM_VETOR}" "${SVG_SEM_MAIN}"
    cp "${SVG_COM_VETOR}" "${SVG_COM_MAIN}"
  else
    add_warning "Falha ao vetorizar SVG; mantendo versoes embed como principais."
  fi
else
  if [[ "${POTRACE_OK}" -ne 1 ]]; then
    add_warning "potrace nao encontrado; gerando SVG embed (com backup)."
  fi
  if [[ "${VECTOR_RASTER_TOOL}" == "none" ]]; then
    add_warning "ImageMagick (magick/convert) nao encontrado; vetorizacao indisponivel."
  fi
fi

PNG_OK=0
if [[ "${RASTER_TOOL}" != "none" ]]; then
  PNG_OK=1

  SIZES=(16 32 64 128 180 192 256 512 1024 2048)
  for SIZE in "${SIZES[@]}"; do
    if ! resize_square "${RASTER_TOOL}" "${SOURCE_IMAGE}" "${SIZE}" "${TMP_PNG_DIR}/${SIZE}.png"; then
      PNG_OK=0
      add_warning "Falha ao gerar PNG ${SIZE}x${SIZE} com a ferramenta ${RASTER_TOOL}."
      break
    fi
  done

  if [[ "${PNG_OK}" -eq 1 ]]; then
    cp "${TMP_PNG_DIR}/16.png" "${PNG_DIR}/favicon-16x16.png"
    cp "${TMP_PNG_DIR}/32.png" "${PNG_DIR}/favicon-32x32.png"
    cp "${TMP_PNG_DIR}/180.png" "${PNG_DIR}/apple-touch-icon.png"
    cp "${TMP_PNG_DIR}/192.png" "${PNG_DIR}/android-chrome-192x192.png"
    cp "${TMP_PNG_DIR}/512.png" "${PNG_DIR}/android-chrome-512x512.png"

    SIZE_VARIANTS=(16 32 64 128 256 512 1024 2048)
    for SIZE in "${SIZE_VARIANTS[@]}"; do
      cp "${TMP_PNG_DIR}/${SIZE}.png" "${TAMANHOS_DIR}/${LOGO_BASE_NAME}-${SIZE}x${SIZE}.png"
    done
  fi
else
  add_warning "Nenhuma ferramenta raster encontrada (sips/magick/convert); PNG/ICO/ICNS nao serao gerados."
fi

ICO_OK=0
if [[ "${PNG_OK}" -eq 1 ]]; then
  if generate_ico "${RASTER_TOOL}" "${TMP_PNG_DIR}/256.png" "${ICO_DIR}/favicon.ico"; then
    ICO_OK=1
  else
    add_warning "Falha ao gerar favicon.ico."
  fi
fi

ICNS_OK=0
if [[ "${PLATFORM}" == "macos" ]]; then
  if [[ "${PNG_OK}" -eq 1 ]]; then
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

    if have_cmd iconutil && iconutil -c icns "${ICONSET_DIR}" -o "${ICNS_DIR}/app.icns" >/dev/null 2>&1; then
      ICNS_OK=1
    elif have_cmd sips && sips -s format icns "${TMP_PNG_DIR}/1024.png" --out "${ICNS_DIR}/app.icns" >/dev/null 2>&1; then
      ICNS_OK=1
    else
      add_warning "Falha ao gerar app.icns no macOS (iconutil/sips)."
    fi
  fi
else
  add_warning "Geracao de .icns pulada: suportada apenas em macOS."
fi

rm -rf "${TMP_DIR}"

cat <<MSG
Assets gerados:
- PNG:            ${PNG_DIR}
- PNG (tamanhos): ${TAMANHOS_DIR}
- SVG:            ${SVG_DIR}
- ICO:            ${ICO_DIR}
- ICNS:           ${ICNS_DIR}
- Fonte usada:    ${SOURCE_IMAGE}

Arquivos principais:
- ${PNG_DIR}/favicon-16x16.png
- ${PNG_DIR}/favicon-32x32.png
- ${PNG_DIR}/apple-touch-icon.png
- ${PNG_DIR}/android-chrome-192x192.png
- ${PNG_DIR}/android-chrome-512x512.png
- ${TAMANHOS_DIR}/${LOGO_BASE_NAME}-16x16.png ... ${LOGO_BASE_NAME}-2048x2048.png
- ${SVG_SEM_MAIN}
- ${SVG_COM_MAIN}
- ${SVG_SEM_EMBED}
- ${SVG_COM_EMBED}
MSG

if [[ "${VECTOR_OK}" -eq 1 ]]; then
  echo "- ${SVG_SEM_VETOR}"
  echo "- ${SVG_COM_VETOR}"
else
  echo "- Aviso: SVG vetorial nao gerado; versoes embed permanecem como principais."
fi

if [[ "${ICO_OK}" -eq 1 ]]; then
  echo "- ${ICO_DIR}/favicon.ico"
else
  echo "- Aviso: .ico nao foi gerado neste ambiente."
fi

if [[ "${ICNS_OK}" -eq 1 ]]; then
  echo "- ${ICNS_DIR}/app.icns"
else
  echo "- Aviso: .icns nao foi gerado neste ambiente."
fi

if [[ "${#WARNINGS[@]}" -gt 0 ]]; then
  echo
  echo "Avisos adicionais:"
  for WARN in "${WARNINGS[@]}"; do
    echo "- ${WARN}"
  done
fi
