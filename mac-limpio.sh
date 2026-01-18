#!/usr/bin/env bash

# Mac Limpio
# Copyright (C) 2026 Guillem Cortés Ovide
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

to_upper() {
  echo "$1" | tr '[:lower:]' '[:upper:]'
}

set -euo pipefail

TOP_N=20
BIG_MB_DEFAULT=1024

hr(){ printf "\n------------------------------------------------------------\n"; }
disk_free(){ df -H / | awk 'NR==2{print $4 " libres de " $2}'; }
pause(){ echo; read -r -p "Pulsa Enter para continuar… " _; }

normalize(){ echo "$1" | xargs; }

# Confirmación 'SI' (acepta si/Si/SI). Devuelve 0 si confirma, 1 si cancela.
confirm_si(){
  local prompt="${1:-Escribe SI para continuar}"
  local ans
  read -r -p "$prompt: " ans
  ans="$(to_upper "$(normalize "${ans:-}")")"
  [[ "$ans" == "SI" ]]
}


# Solo permite rutas dentro de HOME por seguridad (portable para followers)
assert_in_home(){
  local p="$1"
  case "$p" in
    "$HOME"/*) return 0 ;;
    *) echo "🚫 Por seguridad solo se permite actuar dentro de tu HOME ($HOME)."; return 1 ;;
  esac
}


# Evita que alguien mande a la Papelera carpetas "core" del sistema de usuario
is_protected_dir(){
  local p="$1"
  case "$p" in
    "$HOME" | "$HOME/Downloads" | "$HOME/Desktop" | "$HOME/Documents" | "$HOME/Movies" | "$HOME/Library")
      return 0 ;;
    *) return 1 ;;
  esac
}

# Mover a Papelera (seguro, reversible). Funciona con archivos y carpetas.
trash_path(){
  local target="$1"
  [[ -e "$target" ]] || { echo "No existe: $target"; return 1; }
  osascript -e 'on run argv
    set theItem to POSIX file (item 1 of argv)
    tell application "Finder" to delete theItem
  end run' "$target" >/dev/null 2>&1 || { echo "No pude mover a Papelera: $target"; return 1; }
  return 0
}

trash_dir_safe(){
  local p="$1"
  [[ -d "$p" ]] || { echo "No existe o no es carpeta: $p"; return 1; }
  assert_in_home "$p" || return 1

  if is_protected_dir "$p"; then
    echo "🚫 Por seguridad, no movemos a la Papelera esta carpeta: $p"
    echo "👉 En su lugar, elige una subcarpeta concreta (opción 3)."
    return 1
  fi

  echo
  echo "✅ Esto moverá la carpeta a la Papelera (reversible)."
  if ! confirm_si "Escribe SI para continuar"; then
    echo "Cancelado."
    return 0
  fi

  trash_path "$p" && {
    echo "✅ Movido a la Papelera: $p"
    echo "🗑️ Consejo: revisa la Papelera antes de vaciarla para liberar espacio."
  }
}

# Selector por número de subcarpetas dentro de una ruta (usa du, sin dependencias)
select_subdir_and_act(){
  local base="$1"
  [[ -d "$base" ]] || { echo "No existe: $base"; return 1; }
  assert_in_home "$base" || return 1

  # Lista: tamaño + ruta, excluyendo la propia carpeta base
  lines=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && lines+=("$line")
  done < <(du -hd 1 "$base" 2>/dev/null | sort -hr | head -n "$TOP_N" | awk -v b="$base" '$2!=b')

  if (( ${#lines[@]} == 0 )); then
    echo "No hay subcarpetas para seleccionar (o no hay permisos)."
    return 1
  fi

  hr
  echo "Selecciona una carpeta de la lista:"
  echo

  local i=1
  local sizes=()
  local paths=()
  for line in "${lines[@]}"; do
    local sz path
    sz="$(echo "$line" | awk '{print $1}')"
    path="$(echo "$line" | awk '{$1=""; sub(/^ /,""); print}')"
    sizes+=("$sz"); paths+=("$path")
    printf "%2d) %-6s %s\n" "$i" "$sz" "$path"
    ((i++))
  done

  hr
  read -r -p "Número (Enter para cancelar): " sel
  sel="$(normalize "${sel:-}")"
  [[ -z "$sel" ]] && return 0
  [[ "$sel" =~ ^[0-9]+$ ]] || { echo "Selección no válida."; return 1; }

  local idx=$((sel-1))
  (( idx >=0 && idx < ${#paths[@]} )) || { echo "Número fuera de rango."; return 1; }

  local chosen="${paths[$idx]}"
  hr
  echo "📂 Seleccionado: $chosen"
  echo "📦 Tamaño: $(du -sh "$chosen" 2>/dev/null | awk '{print $1}')"
  echo
  echo "¿Qué quieres hacer?"
  echo "  1) Abrir en Finder"
  echo "  2) Mover a la Papelera (recomendado)"
  echo "  3) Volver"
  echo
  read -r -p "Opción: " act
  act="$(normalize "$act")"

  case "$act" in
    1) open_in_finder "$chosen" ;;
    2) trash_dir_safe "$chosen" ;;
    *) ;;
  esac
}

show_top_dirs(){
  local p="$1"
  [[ -d "$p" ]] || { echo "No existe: $p"; return 0; }
  echo "📂 Top carpetas en: $p"
  du -hd 1 "$p" 2>/dev/null | sort -hr | head -"$TOP_N"
}

list_big_files(){
  local p="$1"
  local min_mb="${2:-$BIG_MB_DEFAULT}"
  [[ -d "$p" ]] || { echo "No existe: $p"; return 0; }
  echo "📁 Archivos > ${min_mb}MB en: $p (top $TOP_N)"
  find "$p" -type f -size +"${min_mb}"M -print0 2>/dev/null \
    | xargs -0 ls -lh 2>/dev/null \
    | awk '{print $5 "\t" $9}' \
    | head -"$TOP_N"
}

open_in_finder(){
  local p="$1"
  [[ -e "$p" ]] || { echo "No existe: $p"; return 1; }
  open "$p"
}

print_cd_command(){
  local p="$1"
  echo
  echo "✅ Copia y pega esto en tu terminal:"
  echo
  echo "cd \"${p}\""
  echo
}


# Menú de acciones sobre una ruta
ruta_actions(){
  local p="$1"
  hr
  echo "Ruta: $p"
  echo "Tamaño: $(du -sh "$p" 2>/dev/null | awk '{print $1}')"
  echo
  echo "¿Qué quieres hacer?"
  echo "  1) Abrir en Finder"
  echo "  2) Mostrar comando cd \"ruta\""
  echo "  3) Mover ESTA carpeta a la Papelera (recomendado)"
  echo "  4) Volver"
  echo
  read -r -p "Opción: " a
  a="$(normalize "$a")"

  case "$a" in
    1) open_in_finder "$p" ;;
    2) print_cd_command "$p" ;;
    3) trash_dir_safe "$p" ;;
    *) ;;
  esac
}

# Revisar una ruta y ofrecer acciones (abrir / cd / vaciar)
review_and_actions(){
  local p="$1"
  local label="$2"

  hr
  echo "📂 ${label}: ${p}"
  [[ -d "$p" ]] || { echo "No existe: $p"; return 0; }

  show_top_dirs "$p"

  while true; do
    hr
    echo "¿Qué quieres hacer con esta ruta?"
    echo "  1) Abrir en Finder"
    echo "  2) Mostrar comando: cd \"ruta\""
    echo "  3) Elegir subcarpeta (de la lista) y mover a la Papelera"
    echo "  4) Volver al menú"
    echo
    read -r -p "Opción: " a
    a="$(normalize "$a")"

    case "$a" in
      1) open_in_finder "$p" ;;
      2) print_cd_command "$p" ;;
      3) select_subdir_and_act "$p" ;;
      4) break ;;
      *) echo "❌ Opción no válida." ;;
    esac
  done
}


# Guarda resultados en arrays globales
BIG_FILES_PATHS=()
BIG_FILES_SIZES=()

# Lista archivos grandes y los guarda en arrays para poder elegir por número
collect_big_files(){
  local base="$1"
  local min_mb="$2"

  BIG_FILES_PATHS=()
  BIG_FILES_SIZES=()

  # Usamos find + du para obtener tamaño real y ruta (sin dependencias extra)
  # Nota: puede tardar si tu home es muy grande (normal).
  while IFS= read -r -d '' f; do
    local sz
    sz="$(du -h "$f" 2>/dev/null | awk '{print $1}')"
    [[ -n "$sz" ]] || continue
    BIG_FILES_PATHS+=("$f")
    BIG_FILES_SIZES+=("$sz")
  done < <(find "$base" -type f -size +"${min_mb}"M -print0 2>/dev/null | head -z -n 200)
}

print_big_files_menu(){
  local limit="${1:-20}"
  local total="${#BIG_FILES_PATHS[@]}"

  if (( total == 0 )); then
    echo "✅ No se encontraron archivos por encima del umbral."
    return 1
  fi

  echo "📁 Archivos grandes encontrados (mostrando ${limit} de ${total})"
  hr

  local max="$limit"
  (( total < limit )) && max="$total"

  for ((i=0; i<max; i++)); do
    printf "%2d) %-6s %s\n" "$((i+1))" "${BIG_FILES_SIZES[$i]}" "${BIG_FILES_PATHS[$i]}"
  done

  hr
  echo "Escribe el NÚMERO para actuar sobre ese archivo."
  echo "O escribe: r (recargar), q (volver)"
  echo
  return 0
}

open_parent_folder(){
  local f="$1"
  local dir
  dir="$(dirname "$f")"
  open "$dir"
  echo "📂 Abierto en Finder: $dir"
}

trash_file(){
  local f="$1"
  [[ -e "$f" ]] || { echo "No existe: $f"; return 1; }
  # Finder -> Papelera (seguro)
  osascript -e 'on run argv
    set theFile to POSIX file (item 1 of argv)
    tell application "Finder" to delete theFile
  end run' "$f" >/dev/null 2>&1 || { echo "No pude mover a Papelera: $f"; return 1; }
  echo "✅ Movido a Papelera: $f"
  echo "🗑️ Consejo: revisa la Papelera antes de vaciarla."
}


big_files_interactive(){
  local base="$HOME"
  local mb="$BIG_MB_DEFAULT"

  read -r -p "Tamaño mínimo en MB (Enter=1024): " user_mb
  user_mb="$(echo "${user_mb:-$mb}" | xargs)"
  mb="$user_mb"

  echo
  echo "🔎 Buscando archivos > ${mb}MB en: $base"
  echo "(si tardase, es normal en homes grandes)"
  hr

  collect_big_files "$base" "$mb"

  while true; do
    print_big_files_menu 20 || return 0
    read -r -p "Selección: " sel
    sel="$(echo "$sel" | tr '[:upper:]' '[:lower:]' | xargs)"

    case "$sel" in
      q|exit|salir) return 0 ;;
      r|reload)
        echo "🔄 Recargando lista…"
        collect_big_files "$base" "$mb"
        continue
        ;;
      *)
        # número
        if [[ "$sel" =~ ^[0-9]+$ ]]; then
          local idx=$((sel-1))
          if (( idx < 0 || idx >= ${#BIG_FILES_PATHS[@]} )); then
            echo "❌ Número fuera de rango."
            continue
          fi

          local f="${BIG_FILES_PATHS[$idx]}"
          hr
          echo "Seleccionado: $f"
          echo "Tamaño: ${BIG_FILES_SIZES[$idx]}"
          echo
          echo "¿Qué quieres hacer?"
          echo "  1) Abrir carpeta en Finder"
          echo "  2) Mover a Papelera (recomendado)"
          echo "  3) Volver"
          echo
          read -r -p "Opción: " a
          a="$(echo "$a" | xargs)"

          case "$a" in
            1) open_parent_folder "$f" ;;
            2) trash_file "$f" ;;
            *) ;;
          esac
          hr
        else
          echo "❌ Escribe un número, o r/q."
        fi
        ;;
    esac
  done
}

print_menu(){
  clear 2>/dev/null || true
  echo "🧹 mac-limpio — portable (sin dependencias)"
  echo "💾 Disco: $(disk_free)"
  hr
  echo "REVISAR:"
  echo "  1) Top en Descargas (~/Downloads)"
  echo "  2) Top en Películas/Vídeos (~/Movies)"
  echo "  3) Top en Escritorio (~/Desktop)"
  echo "  4) Top en Documentos (~/Documents)"
  echo "  5) Top en tu usuario (~/)"
  echo "  6) Buscar archivos grandes en tu usuario"
  hr
  echo "ACCIONES:"
  echo "  7) Elegir una ruta manual y (abrir / cd / papelera)"
  echo "  8) Salir"
  echo
}

main(){
  while true; do
    print_menu
    read -r -p "Opción: " opt
    opt="$(normalize "$opt")"

    case "$opt" in
      1) review_and_actions "$HOME/Downloads" "Descargas" ;;
      2) review_and_actions "$HOME/Movies" "Películas/Vídeos" ;;
      3) review_and_actions "$HOME/Desktop" "Escritorio" ;;
      4) review_and_actions "$HOME/Documents" "Documentos" ;;
      5) review_and_actions "$HOME" "Tu usuario (HOME)" ;;
      6) hr; big_files_interactive ; pause ;;

      7)
        echo
        echo "Pega una ruta completa (ej: $HOME/Downloads) y pulsa Enter:"
        read -r -p "Ruta: " p
        p="$(normalize "$p")"
        [[ -n "$p" ]] || { echo "Ruta vacía."; pause; continue; }
        assert_in_home "$p" || { pause; continue; }
        [[ -d "$p" ]] || { echo "No existe o no es carpeta: $p"; pause; continue; }
        ruta_actions "$p"
        pause
        ;;
      8) echo "👋 Saliendo…"; exit 0 ;;
      *) echo "❌ Opción no válida."; pause ;;
    esac
  done
}

main
