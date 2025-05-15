#!/bin/bash

# Airframes Feed Diagnostic Tool v1.0.0
# This script helps diagnose connectivity issues with Airframes feed services
#
# Usage: curl -sSL https://scripts.airframes.sh/feed/diagnose.sh | bash
#    or: wget -qO- https://scripts.airframes.sh/feed/diagnose.sh | bash

# Setup trap to clean up temporary files on exit and handle interrupts gracefully
# Trap function to ensure we show results even if terminated early
show_results_on_exit() {
    # Clean up temporary files
    rm -f /tmp/airframes_* 2>/dev/null
    rm -rf /tmp/airframes_*/ 2>/dev/null
    rm -f ./airframes_* 2>/dev/null
    rm -rf ./airframes_*/ 2>/dev/null
    
    # Make sure to return success status if SIGINT or similar triggered this trap
    trap '' INT TERM
    
    # Don't print summary if we were interrupted very early
    if [ -z "${SUMMARY_TOTAL+x}" ] || [ -z "${SUMMARY_PASSED+x}" ]; then
        always_print "\n${YELLOW}Diagnostic was interrupted too early. No results available.${RESET}"
        return
    fi
    
    # First create empty variables if they don't exist
    if [ -z "${SUCCESS_PORT_LIST+x}" ]; then SUCCESS_PORT_LIST=""; fi
    if [ -z "${FAILED_PORT_LIST+x}" ]; then FAILED_PORT_LIST=""; fi
    if [ -z "${PORT_CONNECTIVITY_PASSED+x}" ]; then PORT_CONNECTIVITY_PASSED=0; fi
    if [ -z "${PORT_CONNECTIVITY_TOTAL+x}" ]; then PORT_CONNECTIVITY_TOTAL=0; fi
    
    # Make sure PORT_SUMMARY is initialized
    if [ -z "${PORT_SUMMARY+x}" ]; then
        if [ "$PORT_CONNECTIVITY_PASSED" -gt 0 ]; then
            PORT_SUMMARY="Port Connectivity: ${GREEN}$PORT_CONNECTIVITY_PASSED of $PORT_CONNECTIVITY_TOTAL available${RESET}"
        else
            PORT_SUMMARY="Port Connectivity: ${RED}No ports available${RESET}"
        fi
    fi
    
    # Use the comprehensive test summary function
    display_test_summary
    
    # Final conclusion
    echo
    always_print "${BOLD}${BLUE}=======================================${RESET}"
    always_print "${BOLD}${BLUE}= DIAGNOSTIC COMPLETE               =${RESET}"
    always_print "${BOLD}${BLUE}=======================================${RESET}"
    always_print "${DARK_GREY}Generated: $(date)${RESET}"
    always_print "${DARK_GREY}Please send this output to support@airframes.io if you need assistance.${RESET}"
    echo
    
    # Add a newline to clear any hanging port check indicators
    echo
    
    # Explicitly exit to ensure we return proper exit code
    exit 0
}

# Add flag to track if we've displayed a summary
SUMMARY_DISPLAYED=false

# Improved signal handling to ensure we always show the diagnostic summary, but only once
trap 'if [ "$SUMMARY_DISPLAYED" != "true" ]; then display_test_summary; SUMMARY_DISPLAYED=true; fi; exit 1' SIGINT SIGTERM SIGQUIT SIGHUP
trap show_results_on_exit EXIT

# Set strict mode
set -eo pipefail

# Debug mode - set AF_DIAGNOSE_DEBUG=true to enable verbose output
DEBUG_MODE=false
if [ "${AF_DIAGNOSE_DEBUG}" = "true" ] || [ "${AF_DIAGNOSE_DEBUG}" = "TRUE" ]; then
    DEBUG_MODE=true
fi

# Function to print debug information (only shown if debug mode is enabled)
debug_print() {
    if [ "$DEBUG_MODE" = "true" ]; then
        echo -e "$@"
    fi
}

# Function to always print, regardless of debug mode
always_print() {
    echo -e "$@"
}

# Function to print section success in non-debug mode
print_section_result() {
    local section_name=$1
    local status=$2  # "success", "failed", "warning", "skipped"
    
    # Only show the result labels in debug mode
    if [ "$DEBUG_MODE" = "true" ]; then
        case "$status" in
            success)
                echo -e "${GREEN}[SUCCESS]${RESET}"
                ;;
            failed)
                echo -e "${RED}[FAILED]${RESET}"
                ;;
            warning)
                echo -e "${YELLOW}[WARNING]${RESET}"
                ;;
            skipped)
                echo -e "${YELLOW}[SKIPPED]${RESET}"
                ;;
        esac
    fi
    # In non-debug mode, we don't show any output at all
}

# Color definitions
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
DARK_GREY="\033[0;90m" # Dark grey for supporting notices
BOLD="\033[1m"
RESET="\033[0m"

# Function to display a comprehensive test summary at any point
display_test_summary() {
    # Display a comprehensive test summary
    echo -e "${BOLD}${MAGENTA}╔═════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${MAGENTA}║    ${BOLD}${GREEN}AIRFRAMES DIAGNOSTIC SUMMARY${RESET}${BOLD}${MAGENTA}     ║${RESET}"
    echo -e "${BOLD}${MAGENTA}╚═════════════════════════════════════╝${RESET}"
    
    # DNS Summary
    if [ -n "${DNS_SUCCESS+x}" ]; then
        if [ "$DNS_SUCCESS" = "true" ]; then
            echo -e "DNS: ${GREEN}Resolves to $DNS_ADDRESS${RESET}"
        else
            echo -e "DNS: ${RED}Resolution failed${RESET}"
        fi
    else
        echo -e "DNS: ${YELLOW}Not tested${RESET}"
    fi
    
    # Ping Summary
    if [ -n "${PING_SUCCESS+x}" ]; then
        if [ "$PING_SUCCESS" = "true" ]; then
            echo -e "Ping: ${GREEN}Successful${RESET}"
        else
            echo -e "Ping: ${RED}Failed${RESET}"
        fi
    else
        echo -e "Ping: ${YELLOW}Not tested${RESET}"
    fi
    
    # Port Summary
    echo -e "$PORT_SUMMARY"
    
    # Available Ports
    if [ -n "${SUCCESS_PORT_LIST}" ]; then
        echo -e "Available ports: ${GREEN}${SUCCESS_PORT_LIST}${RESET}"
    fi
    
    # Unavailable Ports
    if [ -n "${FAILED_PORT_LIST}" ]; then
        echo -e "Unavailable ports: ${RED}${FAILED_PORT_LIST}${RESET}"
    fi
    
    # Overall statistics
    echo -e "\n${BOLD}${BLUE}Tests Summary:${RESET}"
    echo -e "${GREEN}Passed:${RESET} $SUMMARY_PASSED"
    echo -e "${RED}Failed:${RESET} $SUMMARY_FAILED"
    if [ "$SUMMARY_SKIPPED" -gt 0 ]; then
        echo -e "${YELLOW}Skipped:${RESET} $SUMMARY_SKIPPED"
    fi
    echo -e "${BOLD}Total:${RESET} $SUMMARY_TOTAL"
    
    # Support contact information
    echo -e "\n${DARK_GREY}Please send this output to support@airframes.io if you need assistance.${RESET}"
    
    # Mark that we've displayed the summary
    SUMMARY_DISPLAYED=true
}

# Get installation command based on platform
get_install_command() {
    local tool=$1
    
    case "$DETECTED_PLATFORM" in
        linux)
            if command -v apt-get >/dev/null 2>&1; then
                echo "sudo apt-get update && sudo apt-get install -y $tool"
            elif command -v yum >/dev/null 2>&1; then
                echo "sudo yum install -y $tool"
            elif command -v dnf >/dev/null 2>&1; then
                echo "sudo dnf install -y $tool"
            elif command -v zypper >/dev/null 2>&1; then
                echo "sudo zypper install -y $tool"
            elif command -v pacman >/dev/null 2>&1; then
                echo "sudo pacman -S $tool"
            else
                echo "Install $tool using your package manager"
            fi
            ;;
        macos)
            if command -v brew >/dev/null 2>&1; then
                echo "brew install $tool"
            else
                echo "Install Homebrew (https://brew.sh) and then run: brew install $tool"
            fi
            ;;
        wsl)
            echo "sudo apt-get update && sudo apt-get install -y $tool"
            ;;
        windows)
            if command -v choco >/dev/null 2>&1; then
                echo "choco install $tool"
            else
                echo "Install Chocolatey (https://chocolatey.org/install) and then run: choco install $tool"
            fi
            ;;
        *)
            echo "Install $tool using your system's package manager"
            ;;
    esac
}

# Detect platform
detect_platform() {
    # Determine the operating system
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Check if this is WSL (Windows Subsystem for Linux)
        if grep -qi microsoft /proc/version 2>/dev/null; then
            DETECTED_PLATFORM="wsl"
        else
            DETECTED_PLATFORM="linux"
        fi
        
        # Get more specific OS information
        if [ -f /etc/os-release ]; then
            DETECTED_OS=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
            DETECTED_VERSION=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        DETECTED_PLATFORM="macos"
        DETECTED_OS="macos"
        DETECTED_VERSION=$(sw_vers -productVersion)
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        DETECTED_PLATFORM="windows"
        DETECTED_OS="windows"
        # Windows version detection is more complex, omit for now
    else
        DETECTED_PLATFORM="unknown"
        DETECTED_OS="unknown"
    fi
}

# Detect installed tools and print installation instructions if needed
detect_tools() {
    # Required tools
    echo -e "${BLUE}Checking required tools...${RESET}"
    
    # Initialize flag for missing tools
    MISSING_TOOLS=false

    # DNS lookup tools (prioritized)
    DNS_TOOL=""
    if command -v dig >/dev/null 2>&1; then
        DNS_TOOL="dig"
        echo -e "${GREEN}Found DNS tool:${RESET} ${DNS_TOOL}"
    elif command -v host >/dev/null 2>&1; then
        DNS_TOOL="host"
        echo -e "${GREEN}Found DNS tool:${RESET} ${DNS_TOOL}"
    elif command -v nslookup >/dev/null 2>&1; then
        DNS_TOOL="nslookup"
        echo -e "${GREEN}Found DNS tool:${RESET} ${DNS_TOOL}"
    else
        # Only show error if all three DNS tools are missing
        echo -e "${RED}Missing DNS tools.${RESET} Please install one of: dig, host, or nslookup"
        echo -e "${YELLOW}Installation:${RESET} $(get_install_command bind-utils) or $(get_install_command dnsutils)"
        MISSING_TOOLS=true
    fi
    
    # Ping check
    PING_AVAILABLE=false
    if command -v ping >/dev/null 2>&1; then
        PING_AVAILABLE=true
        echo -e "${GREEN}Found connectivity tool:${RESET} ping"
    else
        echo -e "${RED}Missing ping.${RESET} Please install ping"
        echo -e "${YELLOW}Installation:${RESET} $(get_install_command iputils-ping)"
        MISSING_TOOLS=true
    fi
    
    # Traceroute tools (prioritized)
    TRACE_TOOL=""
    if command -v traceroute >/dev/null 2>&1; then
        TRACE_TOOL="traceroute"
        echo -e "${GREEN}Found tracing tool:${RESET} ${TRACE_TOOL}"
    elif command -v tracepath >/dev/null 2>&1; then
        TRACE_TOOL="tracepath"
        echo -e "${GREEN}Found tracing tool:${RESET} tracepath"
    else
        echo -e "${RED}Missing traceroute.${RESET} Please install traceroute or tracepath"
        echo -e "${YELLOW}Installation:${RESET} $(get_install_command traceroute)"
        MISSING_TOOLS=true
    fi
    
    # Connection testing tools (prioritized)
    CONNECT_TOOL=""
    if command -v nc >/dev/null 2>&1; then
        CONNECT_TOOL="nc"
        echo -e "${GREEN}Found connection tool:${RESET} nc"
    elif command -v ncat >/dev/null 2>&1; then
        CONNECT_TOOL="ncat"
        echo -e "${GREEN}Found connection tool:${RESET} ncat"
    elif command -v netcat >/dev/null 2>&1; then
        CONNECT_TOOL="netcat"
        echo -e "${GREEN}Found connection tool:${RESET} netcat"
    elif command -v telnet >/dev/null 2>&1; then
        CONNECT_TOOL="telnet"
        echo -e "${GREEN}Found connection tool:${RESET} telnet"
    else
        echo -e "${RED}Missing connection testing tool.${RESET} Please install nc, ncat, netcat, or telnet"
        echo -e "${YELLOW}Installation:${RESET} $(get_install_command netcat)"
        MISSING_TOOLS=true
    fi
    
    # Timeout command for long-running processes
    TIMEOUT_TOOL=""
    if command -v timeout >/dev/null 2>&1; then
        TIMEOUT_TOOL="timeout"
        echo -e "${GREEN}Found timeout tool:${RESET} ${TIMEOUT_TOOL}"
    elif command -v gtimeout >/dev/null 2>&1; then
        TIMEOUT_TOOL="gtimeout"
        echo -e "${GREEN}Found timeout tool:${RESET} gtimeout"
    fi
    
    echo
    
    # Exit if tools are missing
    if [ "$MISSING_TOOLS" = "true" ]; then
        echo -e "${RED}ERROR: Critical tools are missing.${RESET}"
        echo -e "${YELLOW}Please install the missing tools listed above before running this script.${RESET}"
        echo -e "${YELLOW}Exiting because required tools are not available.${RESET}"
        exit 1
    fi
}

# Target hostname
TARGET="feed.airframes.io"

# Maximum timeout values (seconds)
DNS_TIMEOUT=5
PING_TIMEOUT=10
TRACE_TIMEOUT=5
CONNECT_TIMEOUT=2
PING_COUNT=3

# Initialize summary variables
SUMMARY_TOTAL=0
SUMMARY_PASSED=0
SUMMARY_FAILED=0
SUMMARY_SKIPPED=0

# Detect platform and tools
detect_platform

# Banner
echo -e "${BOLD}${MAGENTA}╔═════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${MAGENTA}║    ${BOLD}${GREEN}AIRFRAMES FEED DIAGNOSTIC TOOL${RESET}${BOLD}${MAGENTA}   ║${RESET}"
echo -e "${BOLD}${MAGENTA}╚═════════════════════════════════════╝${RESET}"
always_print "${CYAN}Time: $(date)${RESET}"
always_print "${CYAN}System: $(uname -a)${RESET}"
always_print "${CYAN}Platform: ${DETECTED_PLATFORM}${RESET}"
always_print "${CYAN}OS: ${DETECTED_OS} ${DETECTED_VERSION}${RESET}"
echo

# Detect required tools and exit if missing
detect_tools

# Section: DNS resolution check
echo -e "${BLUE}Checking DNS resolution for ${TARGET}...${RESET}"
DNS_SUCCESS=false
DNS_OUTPUT=""
DNS_ADDRESS=""

# Attempt DNS resolution
case "$DNS_TOOL" in
    dig)
        if [ -n "$TIMEOUT_TOOL" ]; then
            DNS_OUTPUT=$($TIMEOUT_TOOL $DNS_TIMEOUT dig +short "$TARGET" 2>&1)
        else
            DNS_OUTPUT=$(dig +short "$TARGET" 2>&1)
        fi
        if [ $? -eq 0 ] && [ -n "$DNS_OUTPUT" ]; then
            DNS_SUCCESS=true
            DNS_ADDRESS=$DNS_OUTPUT
        fi
        ;;
    host)
        if [ -n "$TIMEOUT_TOOL" ]; then
            DNS_OUTPUT=$($TIMEOUT_TOOL $DNS_TIMEOUT host "$TARGET" 2>&1)
        else
            DNS_OUTPUT=$(host "$TARGET" 2>&1)
        fi
        if [ $? -eq 0 ] && [[ "$DNS_OUTPUT" =~ "has address" ]]; then
            DNS_SUCCESS=true
            DNS_ADDRESS=$(echo "$DNS_OUTPUT" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}')
        fi
        ;;
    nslookup)
        if [ -n "$TIMEOUT_TOOL" ]; then
            DNS_OUTPUT=$($TIMEOUT_TOOL $DNS_TIMEOUT nslookup "$TARGET" 2>&1)
        else
            DNS_OUTPUT=$(nslookup "$TARGET" 2>&1)
        fi
        if [ $? -eq 0 ] && [[ "$DNS_OUTPUT" =~ "Address:" ]]; then
            DNS_SUCCESS=true
            DNS_ADDRESS=$(echo "$DNS_OUTPUT" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | tail -1)
        fi
        ;;
esac

# Display DNS result
if [ "$DNS_SUCCESS" = "true" ]; then
    echo -e "${GREEN}DNS resolution successful:${RESET} $DNS_ADDRESS"
    SUMMARY_PASSED=$((SUMMARY_PASSED + 1))
    debug_print "DNS lookup output:\n$DNS_OUTPUT"
    print_section_result "DNS" "success"
else
    echo -e "${RED}DNS resolution failed${RESET}"
    echo -e "$DNS_OUTPUT"
    SUMMARY_FAILED=$((SUMMARY_FAILED + 1))
    print_section_result "DNS" "failed"
fi
SUMMARY_TOTAL=$((SUMMARY_TOTAL + 1))
echo

# Section: Ping connectivity test
if [ "$PING_AVAILABLE" = "true" ]; then
    echo -e "${BLUE}Testing ping connectivity to ${TARGET}...${RESET}"
    PING_SUCCESS=false
    PING_OUTPUT=""
    
    # Handle different ping options based on platform
    case "$DETECTED_PLATFORM" in
        macos)
            if [ -n "$TIMEOUT_TOOL" ]; then
                PING_OUTPUT=$($TIMEOUT_TOOL $PING_TIMEOUT ping -c $PING_COUNT "$TARGET" 2>&1)
            else
                PING_OUTPUT=$(ping -c $PING_COUNT "$TARGET" 2>&1)
            fi
            ;;
        linux)
            if [ -n "$TIMEOUT_TOOL" ]; then
                PING_OUTPUT=$($TIMEOUT_TOOL $PING_TIMEOUT ping -c $PING_COUNT -W 2 "$TARGET" 2>&1)
            else
                PING_OUTPUT=$(ping -c $PING_COUNT -W 2 "$TARGET" 2>&1)
            fi
            ;;
        *)
            if [ -n "$TIMEOUT_TOOL" ]; then
                PING_OUTPUT=$($TIMEOUT_TOOL $PING_TIMEOUT ping -c $PING_COUNT "$TARGET" 2>&1)
            else
                PING_OUTPUT=$(ping -c $PING_COUNT "$TARGET" 2>&1)
            fi
            ;;
    esac
    
    # Check if ping was successful
    if [ $? -eq 0 ]; then
        PING_SUCCESS=true
        PING_STATS=$(echo "$PING_OUTPUT" | grep -E 'min.+avg.+max.+mdev|round-trip')
        echo -e "${GREEN}Ping successful.${RESET} $PING_STATS"
        SUMMARY_PASSED=$((SUMMARY_PASSED + 1))
        debug_print "Ping output:\n$PING_OUTPUT"
        print_section_result "Ping" "success"
    else
        echo -e "${RED}Ping failed:${RESET}"
        echo -e "$PING_OUTPUT"
        SUMMARY_FAILED=$((SUMMARY_FAILED + 1))
        print_section_result "Ping" "failed"
    fi
    SUMMARY_TOTAL=$((SUMMARY_TOTAL + 1))
else
    echo -e "${YELLOW}Skipping ping test (ping not available)${RESET}"
    SUMMARY_SKIPPED=$((SUMMARY_SKIPPED + 1))
    print_section_result "Ping" "skipped"
fi
echo

# Section: Traceroute connectivity test
if [ -n "$TRACE_TOOL" ]; then
    echo -e "${BLUE}Tracing route to ${TARGET}...${RESET}"
    TRACE_OUTPUT=""
    TRACE_SUCCESS=false
    
    # Use a stricter timeout and fewer max hops to prevent hanging
    TRACE_MAX_HOPS=8  # Limit to 8 hops to prevent long traces
    
    # Handle different traceroute options based on tool and platform
    case "$TRACE_TOOL" in
        traceroute)
            if [ -n "$TIMEOUT_TOOL" ]; then
                # Use a shorter timeout and fewer hops
                TRACE_OUTPUT=$($TIMEOUT_TOOL $TRACE_TIMEOUT traceroute -w 1 -q 1 -m $TRACE_MAX_HOPS "$TARGET" 2>&1 & pid=$!; sleep $TRACE_TIMEOUT; if ps -p $pid > /dev/null; then kill $pid 2>/dev/null; echo "Traceroute timed out after ${TRACE_TIMEOUT}s (showing partial results)"; fi; wait $pid 2>/dev/null)
            else
                # No timeout tool, use background process with manual timeout
                TRACE_OUTPUT=$(traceroute -w 1 -q 1 -m $TRACE_MAX_HOPS "$TARGET" 2>&1 & pid=$!; sleep $TRACE_TIMEOUT; if ps -p $pid > /dev/null; then kill $pid 2>/dev/null; echo "Traceroute timed out after ${TRACE_TIMEOUT}s (showing partial results)"; fi; wait $pid 2>/dev/null)
            fi
            ;;
        tracepath)
            if [ -n "$TIMEOUT_TOOL" ]; then
                # Use a shorter timeout and fewer hops
                TRACE_OUTPUT=$($TIMEOUT_TOOL $TRACE_TIMEOUT tracepath -m $TRACE_MAX_HOPS "$TARGET" 2>&1 & pid=$!; sleep $TRACE_TIMEOUT; if ps -p $pid > /dev/null; then kill $pid 2>/dev/null; echo "Tracepath timed out after ${TRACE_TIMEOUT}s (showing partial results)"; fi; wait $pid 2>/dev/null)
            else
                # No timeout tool, use background process with manual timeout
                TRACE_OUTPUT=$(tracepath -m $TRACE_MAX_HOPS "$TARGET" 2>&1 & pid=$!; sleep $TRACE_TIMEOUT; if ps -p $pid > /dev/null; then kill $pid 2>/dev/null; echo "Tracepath timed out after ${TRACE_TIMEOUT}s (showing partial results)"; fi; wait $pid 2>/dev/null)
            fi
            ;;
    esac
    
    # Check if we got any useful output
    if [ -n "$TRACE_OUTPUT" ]; then
        TRACE_SUCCESS=true
        # Count this as a success in the summary
        SUMMARY_PASSED=$((SUMMARY_PASSED + 1))
        print_section_result "Traceroute" "success"
    else
        # Count a failure if we got no output
        SUMMARY_FAILED=$((SUMMARY_FAILED + 1))
        print_section_result "Traceroute" "failed"
    fi
    
    # Always increment total test count
    SUMMARY_TOTAL=$((SUMMARY_TOTAL + 1))
    
    # This test always provides useful information even if it doesn't reach destination
    echo -e "${YELLOW}Trace results (limited to ${TRACE_MAX_HOPS} hops):${RESET}"
    echo -e "$TRACE_OUTPUT"
    
    # If we have no output at all, indicate a failure
    if [ -z "$TRACE_OUTPUT" ]; then
        echo -e "${RED}Trace failed to produce any output.${RESET}"
    fi
    
    debug_print "Trace details captured for analysis."
else
    echo -e "${YELLOW}Skipping traceroute (traceroute/tracepath not available)${RESET}"
    SUMMARY_SKIPPED=$((SUMMARY_SKIPPED + 1))
    print_section_result "Traceroute" "skipped"
fi
echo

# Section: Port connectivity tests
echo -e "${BLUE}Testing connectivity to common Airframes ports...${RESET}"
PORT_CONNECTIVITY_PASSED=0
PORT_CONNECTIVITY_TOTAL=0
SUCCESS_PORT_LIST=""
FAILED_PORT_LIST=""

# Port definitions with protocol information - all ports
declare -A PORT_INFO
# UDP Ports
PORT_INFO[5550]="acarsdec - VHF/ACARS UDP"
PORT_INFO[5552]="dumpvdl2-udp - VHF/VDL UDP"
PORT_INFO[5555]="vdlm2dec - VHF/VDL UDP"
PORT_INFO[5561]="jaero-c-acars - Satcom-C-Band/ACARS UDP"
PORT_INFO[5581]="jaero-l-acars - Satcom-L-Band/ACARS UDP"
# TCP Ports
PORT_INFO[5553]="dumpvdl2-tcp - VHF/VDL TCP"
PORT_INFO[5556]="dumphfdl-tcp - HF/HFDL TCP"
PORT_INFO[5590]="iridium-toolkit-acars-tcp - Satcom-L-Band/ACARS TCP"
PORT_INFO[5599]="ais-aiscatcher-http - VHF/AIS HTTP"

# Test all TCP ports with a very simple, direct approach that won't hang
echo "Testing TCP ports with very short timeouts..."

# Set a very short timeout for connection attempts
CONN_TIMEOUT=${CONNECT_TIMEOUT:-1}

# Test each TCP port one by one with strict timeouts
for port in 5553 5556 5590 5599; do
    # Simple direct port check using timeout and bash /dev/tcp
    if timeout $CONN_TIMEOUT bash -c "echo >/dev/tcp/$TARGET/$port" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Port $port (${PORT_INFO[$port]})${RESET}"
        PORT_CONNECTIVITY_PASSED=$((PORT_CONNECTIVITY_PASSED + 1))
        SUCCESS_PORT_LIST="$SUCCESS_PORT_LIST $port"
    else
        echo -e "  ${RED}✗ Port $port (${PORT_INFO[$port]})${RESET}"
        FAILED_PORT_LIST="$FAILED_PORT_LIST $port"
    fi
    PORT_CONNECTIVITY_TOTAL=$((PORT_CONNECTIVITY_TOTAL + 1))
    # Small sleep to ensure output is flushed - prevents hanging appearance
    sleep 0.1
done

# Mark that we've tested all ports
echo -e "Port testing complete."

# Update summary for port connectivity
if [ "$PORT_CONNECTIVITY_PASSED" -gt 0 ]; then
    PORT_SUMMARY="Port Connectivity: ${GREEN}$PORT_CONNECTIVITY_PASSED of $PORT_CONNECTIVITY_TOTAL TCP ports accessible${RESET}"
    print_section_result "Ports" "success"
    # Count port connectivity as a successful test in the overall summary
    SUMMARY_PASSED=$((SUMMARY_PASSED + 1))
else
    PORT_SUMMARY="Port Connectivity: ${RED}No TCP ports accessible${RESET}"
    print_section_result "Ports" "failed"
    SUMMARY_FAILED=$((SUMMARY_FAILED + 1))
fi
SUMMARY_TOTAL=$((SUMMARY_TOTAL + 1))
echo

# Ensure we display the final summary
display_test_summary
