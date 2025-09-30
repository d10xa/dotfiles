#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Fasd to Zoxide Migration Script ===${NC}"

# Check if zoxide is installed
if ! command -v zoxide &> /dev/null; then
    echo -e "${YELLOW}Zoxide not found. Please run 'brew bundle --global' first.${NC}"
    exit 1
fi

# Check if fasd exists and has data
if [ -f "$HOME/.fasd" ]; then
    echo -e "${GREEN}Found fasd database at ~/.fasd${NC}"

    # Count entries
    FASD_COUNT=$(wc -l < "$HOME/.fasd")
    echo -e "Total fasd entries: ${FASD_COUNT}"

    # Check if fasd command is available
    if command -v fasd &> /dev/null; then
        echo -e "${GREEN}Migrating top directories from fasd to zoxide...${NC}"

        # Get top 50 directories sorted by frecency
        fasd -Rdl | head -50 | while read -r path; do
            if [ -d "$path" ]; then
                echo -e "  Adding: $path"
                zoxide add "$path" 2>/dev/null || true
            fi
        done

        echo -e "${GREEN}Migration completed!${NC}"
    else
        echo -e "${YELLOW}fasd command not found, attempting raw import...${NC}"

        # Parse fasd database directly (format: path|frecency|timestamp)
        cat "$HOME/.fasd" | sort -rn -t'|' -k2 | head -50 | cut -d'|' -f1 | while read -r path; do
            if [ -d "$path" ]; then
                echo -e "  Adding: $path"
                zoxide add "$path" 2>/dev/null || true
            fi
        done

        echo -e "${GREEN}Raw import completed!${NC}"
    fi

    # Create backup
    BACKUP_FILE="$HOME/.fasd.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$HOME/.fasd" "$BACKUP_FILE"
    echo -e "${GREEN}Backed up fasd database to: $BACKUP_FILE${NC}"

else
    echo -e "${YELLOW}No fasd database found at ~/.fasd${NC}"
    echo -e "Skipping migration - zoxide will build history from scratch"
fi

# Show current zoxide stats
if [ -f "$HOME/.local/share/zoxide/db.zo" ]; then
    echo -e "\n${GREEN}Zoxide database stats:${NC}"
    echo -e "  Database location: ~/.local/share/zoxide/db.zo"
    ZOXIDE_COUNT=$(zoxide query -l 2>/dev/null | wc -l)
    echo -e "  Total paths in zoxide: ${ZOXIDE_COUNT}"
fi

echo -e "\n${GREEN}Migration complete!${NC}"
echo -e "Note: You can safely remove fasd after verifying zoxide works:"
echo -e "  ${YELLOW}brew uninstall fasd${NC}"
echo -e "  ${YELLOW}rm ~/.fasd ~/.fasd-init-zsh${NC}"