add_ssl_certificate_to_trust() {
    crt_file=${LEMP_TRAEFIK_DOMAIN_SSL_CRT_FILE}
    domain=${LEMP_SERVER_DOMAIN}
    
    # Sanity checks
    if [ -z "$crt_file" ]; then
        warning_msg "SSL certificate path is empty (LEMP_TRAEFIK_DOMAIN_SSL_CRT_FILE)."
        return 1
    fi
    if [ ! -f "$crt_file" ]; then
        warning_msg "SSL certificate file not found: $crt_file"
        return 1
    fi
    
    case "$(uname -s)" in
        Darwin)
            status_msg "Adding ${domain} certificate to System keychain (SSL trust only, not as a root)…"
            
            # Remove any existing certificate for this CN from System keychain
            if security find-certificate -c "$domain" /Library/Keychains/System.keychain >/dev/null 2>&1; then
                status_msg "Removing existing ${domain} certificate from System keychain…"
                sudo security delete-certificate -c "$domain" /Library/Keychains/System.keychain >/dev/null 2>&1 || true
            fi
            
            # Import the leaf cert and trust it for SSL only (do NOT use -r trustRoot)
            # -d: add to admin (system) trust domain
            # -p ssl: set policy to SSL
            # -k: target keychain
            if sudo security add-trusted-cert -d -p ssl -k /Library/Keychains/System.keychain "$crt_file" >/dev/null 2>&1; then
                success_msg "Certificate added and trusted for SSL in System keychain."
            else
                warning_msg "Failed to set SSL trust via security(1). You may need to open Keychain Access and set 'Always Trust' for SSL manually."
                return 1
            fi
        ;;
        
        Linux)
            warning_msg "Linux: trusting an individual *leaf* cert system-wide is uncommon."
            warning_msg "Recommend trusting the mkcert root CA instead (run: mkcert -install), or configure browser NSS trust with certutil if necessary."
        ;;
        
        FreeBSD|OpenBSD|SunOS)
            warning_msg "BSD/Solaris: leaf cert system trust is uncommon. Trust the mkcert root CA, or adjust per-application trust settings."
        ;;
        
        CYGWIN*|MINGW*|MSYS*)
            warning_msg "Windows (POSIX shell): importing a leaf into Windows trust requires certmgr/PowerShell."
            warning_msg "Use: certmgr.msc (GUI) or PowerShell: Import-Certificate -FilePath 'path\\to\\cert.cer' -CertStoreLocation Cert:\\LocalMachine\\Root (for CA) or …\\TrustedPeople (for leaf)."
        ;;
        
        *)
            warning_msg "Unknown OS: unable to automate leaf trust. Please import the certificate manually."
        ;;
    esac
}
export -f add_ssl_certificate_to_trust

firefox_nss_add_mkcert_root() {
    # Requires certutil (from NSS tools)
    if ! command -v certutil >/dev/null 2>&1; then
        info_msg "certutil not found; skipping Firefox/NSS trust setup."
        return 0
    fi
    
    # Skip unless explicitly forced; mkcert generally handles NSS trust automatically
    if [ "${FORCE_NSS_FIX:-0}" != "1" ]; then
        info_msg "Skipping manual Firefox/NSS import (mkcert normally handles this). Set FORCE_NSS_FIX=1 to force."
        return 0
    fi
    
    # Locate mkcert's CAROOT and root CA PEM
    CA_ROOT="$(mkcert -CAROOT 2>/dev/null)"
    [ -z "$CA_ROOT" ] && CA_ROOT="$HOME/Library/Application Support/mkcert"
    PEM="$CA_ROOT/rootCA.pem"
    
    if [ ! -f "$PEM" ]; then
        warning_msg "mkcert rootCA.pem not found; run 'mkcert -install' first."
        return 1
    fi
    
    # Gather Firefox profile directories (macOS + Linux)
    profiles=""
    if [ -d "$HOME/Library/Application Support/Firefox/Profiles" ]; then
        for d in "$HOME/Library/Application Support/Firefox/Profiles"/*; do
            [ -d "$d" ] && profiles="$profiles\n$d"
        done
    fi
    if [ -d "$HOME/.mozilla/firefox" ]; then
        for d in "$HOME/.mozilla/firefox"/*.default* "$HOME/.mozilla/firefox"/*.dev-edition-default "$HOME/.mozilla/firefox"/*.release; do
            [ -d "$d" ] && profiles="$profiles\n$d"
        done
    fi
    
    # Nothing to do
    if [ -z "$profiles" ]; then
        info_msg "No Firefox profiles found; skipping NSS trust setup."
        return 0
    fi
    
    added_any=false
    printf '%s\n' "$profiles" | while IFS= read -r profile; do
        [ -z "$profile" ] && continue
        db="sql:$profile"
        
        # Ensure the NSS DB is readable; handle SEC_ERROR_BAD_DATABASE gracefully
        if ! certutil -L -d "$db" >/dev/null 2>&1; then
            if [ -f "$profile/cert9.db" ] || [ -f "$profile/key4.db" ] || [ -f "$profile/cert8.db" ] || [ -f "$profile/key3.db" ]; then
                warning_msg "Firefox NSS database appears unreadable (SEC_ERROR_BAD_DATABASE): $profile"
                warning_msg "Close Firefox completely and consider restoring this profile's cert DB (backup first):"
                example_msg "rm -f '$profile/cert9.db' '$profile/key4.db'  # (or older DBM: cert8.db/key3.db)"
                example_msg "certutil -N -d 'sql:$profile'    # reinitialize empty DB (interactive)"
                continue
            fi
        fi
        
        # Try to add with a stable nickname; if it exists, skip adding
        if certutil -L -d "$db" | grep -i "mkcert" >/dev/null 2>&1; then
            info_msg "mkcert root already present in: $profile"
            added_any=true
            continue
        fi
        
        if certutil -A -n "mkcert" -t "C,," -i "$PEM" -d "$db" >/dev/null 2>&1; then
            success_msg "Added mkcert root CA to Firefox profile: $profile"
            added_any=true
        else
            warning_msg "Failed to add mkcert root CA to Firefox profile: $profile"
        fi
    done
    
    # Hint if nothing was added (subshell may hide state; provide guidance regardless)
    info_msg "If Firefox still shows untrusted certs, close Firefox completely and retry after running: mkcert -install"
    return 0
}

export -f firefox_nss_add_mkcert_root

add_mkcert_ca_root_to_trust() {
    case "$(uname -s)" in
        Darwin)
            status_msg "🔍 macOS detected — ensuring mkcert root CA is trusted…"
            
            # Quit Keychain Access if running (prevents UI trust prompts)
            if pgrep -x "Keychain Access" >/dev/null 2>&1; then
                line_break
                status_msg "Closing Keychain Access…"
                osascript -e 'quit app "Keychain Access"' 2>/dev/null || killall "Keychain Access" 2>/dev/null
                sleep 1
            fi
            
            # Prefer mkcert to install the local root CA properly
            if command -v mkcert >/dev/null 2>&1; then
                line_break
                status_msg "Running: mkcert -install"
                sudo mkcert -install
                MKCERT_HANDLED_FIREFOX=1
            else
                # Fallback: import mkcert's root CA if present on disk
                # (mkcert stores its CA here)
                CA_ROOT="$(mkcert -CAROOT 2>/dev/null)"
                if [ -n "$CA_ROOT" ] && [ -f "$CA_ROOT/rootCA.pem" ]; then
                    line_break
                    status_msg "Adding mkcert rootCA.pem to System keychain…"
                    sudo security add-trusted-cert -d -r trustRoot \
                    -k /Library/Keychains/System.keychain "$CA_ROOT/rootCA.pem"
                    MKCERT_HANDLED_FIREFOX=1
                else
                    line_break
                    warning_msg "mkcert not found. Install/trust the local root CA manually or run: mkcert -install"
                fi
            fi
            
            # Verify the mkcert root is present (by common name match)
            if security find-certificate -a -c "mkcert" /Library/Keychains/System.keychain >/dev/null 2>&1; then
                line_break
                success_msg "mkcert root CA is in the System keychain."
            else
                line_break
                warning_msg "mkcert root CA not found in System keychain. Browser trust may still fail."
            fi
            
            MKCERT_HANDLED_FIREFOX=1
            # mkcert usually handles Firefox NSS trust itself. Only run manual NSS fix if forced.
            if [ "${FORCE_NSS_FIX:-0}" = "1" ]; then
                firefox_nss_add_mkcert_root
            fi
            
            # NOTE: Do NOT attempt to trust the leaf/domain cert as a root.
            # Traefik should just use ${LEMP_TRAEFIK_DOMAIN_SSL_CRT_FILE} + its key.
        ;;
        
        Linux)
            status_msg "Linux detected — ensuring mkcert root CA is trusted…"
            if command -v mkcert >/dev/null 2>&1; then
                sudo mkcert -install || true
                MKCERT_HANDLED_FIREFOX=1
            else
                warning_msg "mkcert not found. Install mkcert and run 'mkcert -install'."
            fi
            MKCERT_HANDLED_FIREFOX=1
            # mkcert usually handles Firefox NSS trust itself. Only run manual NSS fix if forced.
            if [ "${FORCE_NSS_FIX:-0}" = "1" ]; then
                firefox_nss_add_mkcert_root
            fi
        ;;
        
        *) : ;;  # other OSes handled elsewhere
    esac
}

export -f add_mkcert_ca_root_to_trust
