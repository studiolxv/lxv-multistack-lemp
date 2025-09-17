add_mkcert_ca_root_to_trust() {
    case "$(uname -s)" in
        Darwin)
            status_msg "🔍 macOS detected — ensuring mkcert root CA is trusted… sudo required"

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
                running_msg "% sudo mkcert -install"
                sudo mkcert -install
                MKCERT_HANDLED_FIREFOX=1
            else
                # Fallback: import mkcert's root CA if present on disk
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
        ;;

        Linux)
            status_msg "Linux detected — ensuring mkcert root CA is trusted… sudo required"
            if command -v mkcert >/dev/null 2>&1; then
                running_msg "% sudo mkcert -install || true"
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

        MINGW*|MSYS*|CYGWIN*)
            # Windows (Git Bash/MSYS2/Cygwin) — use mkcert to add to Windows Certificate Store
            status_msg "🪟 Windows detected — ensuring mkcert root CA is trusted… admin may be required"
            if command -v mkcert >/dev/null 2>&1; then
                line_break
                running_msg "% mkcert -install"
                # mkcert on Windows adds the root to Cert:\\LocalMachine\\Root and user stores automatically
                mkcert -install || true
                MKCERT_HANDLED_FIREFOX=1
            else
                line_break
                warning_msg "mkcert not found. Install it, e.g.: 'winget install FiloSottile.mkcert' or 'choco install mkcert', then run 'mkcert -install'."

                # Best-effort fallback if a rootCA.pem is already present in the default mkcert CAROOT
                # Try to locate CAROOT via PowerShell and import it into the Windows Root store
                if command -v powershell.exe >/dev/null 2>&1; then
                    PS_CMD='${Env:CAROOT = if ($Env:CAROOT) { $Env:CAROOT } else { Join-Path $Env:LOCALAPPDATA "mkcert" }; $pem = Join-Path $Env:CAROOT "rootCA.pem"; if (Test-Path $pem) { try { Import-Certificate -FilePath $pem -CertStoreLocation Cert:\\LocalMachine\\Root | Out-Null; exit 0 } catch { exit 1 } } else { exit 2 } }'
                    powershell.exe -NoProfile -Command "$PS_CMD" >/dev/null 2>&1 || true
                fi
            fi

            # Verify presence of mkcert root in Windows Root store
            if command -v powershell.exe >/dev/null 2>&1; then
                powershell.exe -NoProfile -Command "if (Get-ChildItem Cert:\\LocalMachine\\Root | Where-Object { $_.Subject -like '*mkcert*' }) { exit 0 } else { exit 1 }" >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    success_msg "mkcert root CA is in the Windows Root store."
                else
                    warning_msg "mkcert root CA not found in the Windows Root store. Browser trust may still fail."
                fi
            fi

            MKCERT_HANDLED_FIREFOX=1
            # mkcert usually handles Firefox profiles automatically on Windows; only attempt manual NSS fix if forced.
            if [ "${FORCE_NSS_FIX:-0}" = "1" ]; then
                firefox_nss_add_mkcert_root
            fi
        ;;

        FreeBSD|OpenBSD|NetBSD)
            status_msg "BSD detected — ensuring mkcert root CA is trusted… root may be required"
            if command -v mkcert >/dev/null 2>&1; then
                running_msg "% sudo mkcert -install || doas mkcert -install"
                # Prefer sudo, fall back to doas if available
                if command -v sudo >/dev/null 2>&1; then
                    sudo mkcert -install || true
                    elif command -v doas >/dev/null 2>&1; then
                    doas mkcert -install || true
                else
                    mkcert -install || true
                fi
                MKCERT_HANDLED_FIREFOX=1
            else
                warning_msg "mkcert not found. Install via pkg (e.g., 'pkg install mkcert nss') and run 'mkcert -install'."
            fi
            MKCERT_HANDLED_FIREFOX=1
            if [ "${FORCE_NSS_FIX:-0}" = "1" ]; then
                firefox_nss_add_mkcert_root
            fi
        ;;

        *)
            warning_msg "Unsupported OS detected. Manual mkcert CA root installation may be required."
        ;;
    esac
}


