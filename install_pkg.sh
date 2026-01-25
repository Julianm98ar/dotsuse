#!/usr/bin/env bash
# shellcheck disable=SC2154
# shellcheck disable=SC1091
#|---/ /+----------------------------------------+---/ /|#
#|--/ /-| Script to install pkgs from input list |--/ /-|#
#|-/ /--| Prasanth Rangan                        |-/ /--|#
#|/ /---+----------------------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

flg_DryRun=${flg_DryRun:-0}
export log_section="package"

# For Arch-based distributions, setup AUR helper
# For openSUSE, OBS is integrated into zypper
case "${DISTRO_ID}" in
arch | manjaro | endeavouros)
    "${scrDir}/install_aur.sh" "${getAur}" 2>&1
    chk_list "aurhlpr" "${aurList[@]}"
    ;;
opensuse | opensuse-leap | opensuse-tumbleweed)
    # OBS is integrated into zypper, no additional setup needed
    print_log -sec "OBS" -stat "integrated" "openSUSE OBS is handled by zypper"
    ;;
esac

listPkg="${1:-"${scrDir}/pkg_core.lst"}"
repoPkg=()
aurhPkg=()
ofs=$IFS
IFS='|'

#-----------------------------#
# remove blacklisted packages #
#-----------------------------#
if [ -f "${scrDir}/pkg_black.lst" ]; then
    grep -v -f <(grep -v '^#' "${scrDir}/pkg_black.lst" | sed 's/#.*//;s/ //g;/^$/d') <(sed 's/#.*//' "${scrDir}/install_pkg.lst") >"${scrDir}/install_pkg_filtered.lst"
    mv "${scrDir}/install_pkg_filtered.lst" "${scrDir}/install_pkg.lst"
fi

while read -r pkg deps; do
    pkg="${pkg// /}"
    if [ -z "${pkg}" ]; then
        continue
    fi

    if [ -n "${deps}" ]; then
        deps="${deps%"${deps##*[![:space:]]}"}"
        while read -r cdep; do
            pass=$(cut -d '#' -f 1 "${listPkg}" | awk -F '|' -v chk="${cdep}" '{if($1 == chk) {print 1;exit}}')
            if [ -z "${pass}" ]; then
                if pkg_installed "${cdep}"; then
                    pass=1
                else
                    break
                fi
            fi
        done < <(xargs -n1 <<<"${deps}")

        if [[ ${pass} -ne 1 ]]; then
            print_log -warn "missing" "dependency [ ${deps} ] for ${pkg}..."
            continue
        fi
    fi

    if pkg_installed "${pkg}"; then
        print_log -y "[skip] " "${pkg}"
    elif pkg_available "${pkg}"; then
        # Get repository info (pm.sh handles both pacman and zypper)
        case "${DISTRO_ID}" in
        arch | manjaro | endeavouros)
            repo=$(pacman -Si "${pkg}" 2>/dev/null | awk -F ': ' '/Repository / {print $2}' | tr '\n' ' ')
            ;;
        opensuse | opensuse-leap | opensuse-tumbleweed)
            repo=$(zypper info "${pkg}" 2>/dev/null | awk -F ': ' '/Repository / {print $2}' | tr '\n' ' ')
            ;;
        *)
            repo="unknown"
            ;;
        esac
        print_log -b "[queue] " "${pkg}" -b " :: " -g "${repo}"
        repoPkg+=("${pkg}")
    elif aur_available "${pkg}"; then
        print_log -b "[queue] " "${pkg}" -b " :: " -g "aur/obs"
        aurhPkg+=("${pkg}")
    else
        print_log -r "[error] " "unknown package ${pkg}..."
    fi
done < <(cut -d '#' -f 1 "${listPkg}")

IFS=${ofs}

install_packages() {
    local -n pkg_array=$1
    local pkg_type=$2
    local install_cmd=$3

    if [[ ${#pkg_array[@]} -gt 0 ]]; then
        print_log -b "[install] " "$pkg_type packages..."
        if [ "${flg_DryRun}" -eq 1 ]; then
            for pkg in "${pkg_array[@]}"; do
                print_log -b "[pkg] " "${pkg}"
            done
        else
            # Use pm.sh wrapper for universal package manager support
            ${install_cmd} ${use_default:+"$use_default"} "${pkg_array[@]}"
        fi
    fi
}

echo ""
install_packages repoPkg "repository" "${pacmanCmd} install"
echo ""

# Only prompt for AUR/OBS on Arch-based systems (where aurhlpr is available)
case "${DISTRO_ID}" in
arch | manjaro | endeavouros)
    install_packages aurhPkg "aur" "${aurhlpr}"
    ;;
opensuse | opensuse-leap | opensuse-tumbleweed)
    if [[ ${#aurhPkg[@]} -gt 0 ]]; then
        print_log -b "[install] " "obs packages via zypper..."
        if [ "${flg_DryRun}" -eq 1 ]; then
            for pkg in "${aurhPkg[@]}"; do
                print_log -b "[pkg] " "${pkg}"
            done
        else
            ${pacmanCmd} install ${use_default:+"$use_default"} "${aurhPkg[@]}"
        fi
    fi
    ;;
esac
