#!/bin/bash
# Test script to verify Python dependency installation fixes
# Run this after HyDE installation on openSUSE or Arch

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╭─ HyDE Python Dependency Test${NC}"
echo -e "${BLUE}│${NC}"

# Function to print test result
print_result() {
    local test_name="$1"
    local result="$2"
    
    if [ "$result" = "pass" ]; then
        echo -e "${GREEN}✓${NC} ${test_name}"
    else
        echo -e "${RED}✗${NC} ${test_name}"
    fi
}

# Function to print warning
print_warning() {
    local test_name="$1"
    echo -e "${YELLOW}⚠${NC} ${test_name}"
}

# Test 1: Distro Detection
echo -e "${BLUE}│ Test 1: Distribution Detection${NC}"
echo -e "${BLUE}│${NC}"

if [ -f "/etc/os-release" ]; then
    distro_id=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
    distro_name=$(grep "^PRETTY_NAME=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
    print_result "Read /etc/os-release" "pass"
    echo -e "${BLUE}│   Distro ID: ${distro_id}${NC}"
    echo -e "${BLUE}│   Pretty Name: ${distro_name}${NC}"
else
    print_result "Read /etc/os-release" "fail"
    exit 1
fi
echo -e "${BLUE}│${NC}"

# Test 2: Python Availability
echo -e "${BLUE}│ Test 2: Python Availability${NC}"
echo -e "${BLUE}│${NC}"

if command -v python3 &>/dev/null; then
    python_version=$(python3 --version 2>&1)
    print_result "python3 available" "pass"
    echo -e "${BLUE}│   Version: ${python_version}${NC}"
else
    print_result "python3 available" "fail"
fi

if command -v python &>/dev/null; then
    print_warning "Fallback python available (Arch legacy)"
else
    print_result "No python fallback (expected on modern systems)" "pass"
fi
echo -e "${BLUE}│${NC}"

# Test 3: Requirements Files
echo -e "${BLUE}│ Test 3: Requirements Files${NC}"
echo -e "${BLUE}│${NC}"

HYDE_LIB_DIR="${HOME}/.local/lib/hyde"
PYUTILS_DIR="${HYDE_LIB_DIR}/pyutils"

if [ -f "${PYUTILS_DIR}/requirements.txt" ]; then
    print_result "requirements.txt exists" "pass"
    req_count=$(grep -c "^[^#]" "${PYUTILS_DIR}/requirements.txt" 2>/dev/null || echo "0")
    echo -e "${BLUE}│   Packages: ${req_count}${NC}"
else
    print_result "requirements.txt exists" "fail"
fi

if [ -f "${PYUTILS_DIR}/requirements.opensuse.txt" ]; then
    print_result "requirements.opensuse.txt exists" "pass"
    req_count=$(grep -c "^[^#]" "${PYUTILS_DIR}/requirements.opensuse.txt" 2>/dev/null || echo "0")
    echo -e "${BLUE}│   Packages: ${req_count}${NC}"
else
    if [[ "$distro_id" == *"opensuse"* ]]; then
        print_warning "requirements.opensuse.txt not found (should be present for openSUSE)"
    else
        print_result "requirements.opensuse.txt not needed (Arch system)" "pass"
    fi
fi
echo -e "${BLUE}│${NC}"

# Test 4: Virtual Environment
echo -e "${BLUE}│ Test 4: Virtual Environment${NC}"
echo -e "${BLUE}│${NC}"

VENV_PATH="${HOME}/.local/state/hyde/pip_env"

if [ -d "$VENV_PATH" ]; then
    print_result "Virtual environment exists" "pass"
    
    if [ -x "${VENV_PATH}/bin/python" ]; then
        venv_version=$(${VENV_PATH}/bin/python --version 2>&1)
        print_result "Virtual environment python is executable" "pass"
        echo -e "${BLUE}│   Version: ${venv_version}${NC}"
    else
        print_result "Virtual environment python is executable" "fail"
    fi
else
    print_warning "Virtual environment not found (may need to run install)"
fi
echo -e "${BLUE}│${NC}"

# Test 5: Core Packages
echo -e "${BLUE}│ Test 5: Core Packages${NC}"
echo -e "${BLUE}│${NC}"

if [ -d "$VENV_PATH" ] && [ -x "${VENV_PATH}/bin/python" ]; then
    PYTHON="${VENV_PATH}/bin/python"
    
    # Test each core package
    for package in loguru requests pulsectl inotify_simple; do
        if $PYTHON -c "import $package" 2>/dev/null; then
            print_result "Package: $package" "pass"
        else
            print_result "Package: $package" "fail"
        fi
    done
else
    print_warning "Virtual environment not available, skipping package tests"
fi
echo -e "${BLUE}│${NC}"

# Test 6: Optional Packages (system-dependent)
echo -e "${BLUE}│ Test 6: Optional Packages (System Bindings)${NC}"
echo -e "${BLUE}│${NC}"

if [ -d "$VENV_PATH" ] && [ -x "${VENV_PATH}/bin/python" ]; then
    PYTHON="${VENV_PATH}/bin/python"
    
    # Test PyGObject
    if $PYTHON -c "import PyGObject" 2>/dev/null; then
        print_result "Package: PyGObject (system binding)" "pass"
    else
        if [[ "$distro_id" == *"opensuse"* ]]; then
            print_warning "Package: PyGObject (requires gobject-introspection-devel on openSUSE)"
        else
            print_warning "Package: PyGObject (not available)"
        fi
    fi
    
    # Test PyQt6
    if $PYTHON -c "import PyQt6" 2>/dev/null; then
        print_result "Package: PyQt6 (system binding)" "pass"
    else
        if [[ "$distro_id" == *"opensuse"* ]]; then
            print_warning "Package: PyQt6 (requires libQt6Core-devel on openSUSE)"
        else
            print_warning "Package: PyQt6 (not available)"
        fi
    fi
    
    # Test XDG (should have fallback)
    if $PYTHON -c "import pyxdg or import PyGObject" 2>/dev/null; then
        print_result "XDG path handling available" "pass"
    else
        print_warning "XDG path handling (using fallback)"
    fi
else
    print_warning "Virtual environment not available, skipping optional package tests"
fi
echo -e "${BLUE}│${NC}"

# Test 7: Distro-Specific Requirements Detection
echo -e "${BLUE}│ Test 7: Distro-Specific Requirements Detection${NC}"
echo -e "${BLUE}│${NC}"

if [ -d "$VENV_PATH" ] && [ -x "${VENV_PATH}/bin/python" ]; then
    PYTHON="${VENV_PATH}/bin/python"
    
    # Check if distro detection is working
    if $PYTHON -c "
import sys
sys.path.insert(0, '${PYUTILS_DIR}')
from pip_env import get_distro_id, get_requirements_file
distro = get_distro_id()
print(f'Detected distro: {distro}')
" 2>/dev/null; then
        print_result "Distro detection working" "pass"
    else
        print_warning "Distro detection test (may not be available)"
    fi
else
    print_warning "Virtual environment not available, skipping distro detection test"
fi
echo -e "${BLUE}│${NC}"

# Summary
echo -e "${BLUE}│ Summary${NC}"
echo -e "${BLUE}│${NC}"

if [ "$distro_id" = "arch" ]; then
    echo -e "${BLUE}│ ${GREEN}Arch Linux${NC} - Full feature set should be available${NC}"
elif [[ "$distro_id" == *"opensuse"* ]]; then
    echo -e "${BLUE}│ ${GREEN}openSUSE${NC} - Core features available (system bindings optional)${NC}"
else
    echo -e "${BLUE}│ ${YELLOW}Other Distribution${NC} - Features depend on packages${NC}"
fi
echo -e "${BLUE}│${NC}"

# Recommendations
echo -e "${BLUE}│ Recommendations${NC}"
echo -e "${BLUE}│${NC}"

if [[ "$distro_id" == *"opensuse"* ]]; then
    if ! python3 -c "import PyGObject" 2>/dev/null; then
        echo -e "${BLUE}│ For full GTK support, install:${NC}"
        echo -e "${BLUE}│   sudo zypper install gobject-introspection-devel${NC}"
    fi
    if ! python3 -c "import PyQt6" 2>/dev/null; then
        echo -e "${BLUE}│ For full Qt support, install:${NC}"
        echo -e "${BLUE}│   sudo zypper install libQt6Core-devel python3-PyQt6${NC}"
    fi
fi

echo -e "${BLUE}│${NC}"
echo -e "${BLUE}╰─ Test Complete${NC}"
echo ""

