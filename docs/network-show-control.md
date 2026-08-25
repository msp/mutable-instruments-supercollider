# Show Control — iPad → SuperCollider

**iPad URL: `http://192.168.8.10:8080`**

---

## Start sequence

1. **Power the Shadow.** USB from the laptop. Give it ~30s.
2. **Mac → `netmode show`.** Pins the IP and joins `msp`. Not the venue's network.
3. **iPad → Wi-Fi `msp`.**
4. **Boot SuperCollider.** Server up, synths loaded.
5. **Start Open Stage Control:**

   ```
   cd /Users/shared/development/node/open-stage-control
   node app --send 127.0.0.1:57120 --osc-port 9000 --load /Users/shared/GitHub/mutable-sc/open-stage-control/plaits.json
   ```

6. **iPad → Home Screen shortcut.**

**Check before you walk away:** step 5 must print `http://192.168.8.10:8080`. If that line is missing, the Mac isn't on `msp`. Fix that before anything else.

---

## If it doesn't work

**O-SC doesn't print `192.168.8.10`**
Mac is on the wrong network. Rejoin `msp`. Confirm with `ipconfig getifaddr en0`.

**iPad won't load the page**
Check the Mac first (above). Then confirm the iPad is on `msp` and not something the venue is broadcasting.

**Page loads, faders do nothing**
Not a network problem — OSC runs over loopback. SuperCollider isn't running, or the synths aren't loaded.

**Worked, then died after a few minutes**
If a Wi-Fi uplink is active, disconnect it — `http://192.168.8.1` → INTERNET → Repeater → Disconnect. Single radio, so the uplink and the AP share it. Rule that out before looking anywhere else.

**Terminal can't accept connections**
macOS Local Network permission. System Settings → Privacy & Security → Local Network → enable for Terminal.

---

## Getting online

The show rig needs no internet, but you can add one without disturbing it. The LAN doesn't change — Mac stays `192.168.8.10`, the iPad URL stays the same, O-SC keeps running.

**On:** `http://192.168.8.1` → INTERNET → Repeater → Scan → pick the network → password → Connect.

**Off:** same page → Disconnect. Delete the saved profile if you want it gone.

The iPad may drop off the AP for a few seconds while the radio retunes. It comes back on its own.

If you get a route but no name resolution, the Mac's DNS entry hasn't applied — toggle Wi-Fi off and on.

---

## Reference

| | |
|---|---|
| SSID | `msp` |
| Router admin | `http://192.168.8.1` |
| Router mode | Router, **WAN unplugged** |
| Radio | 2.4 GHz, fixed channel (1/6/11), 20 MHz, WPA2 |
| Mac Wi-Fi IP | `192.168.8.10` — **manual static** |
| Subnet / Gateway | `255.255.255.0` / `192.168.8.1` |
| Mac DNS | `192.168.8.1` |
| iPad | DHCP, automatic |
| O-SC web | port `8080` |
| O-SC → SuperCollider | `127.0.0.1:57120` (loopback) |
| O-SC OSC in | port `9000` |

**No internet is required anywhere in this chain.** If something only works when the studio network is reachable, the config has drifted.

---

## Remember

The Mac's Wi-Fi is **pinned to a static IP**. It will join any other Wi-Fi network and appear connected while nothing actually works — no internet, no DNS, captive portals dead.

### Switching

```
netmode show      # pin to 192.168.8.10, DNS 192.168.8.1, join msp
netmode normal    # back to DHCP for any other Wi-Fi
netmode           # show current mode / ssid / ip / dns
```

Run `netmode` on its own if you're ever unsure which state you're in.

Lives at `scripts/netmode.sh` in this repo, symlinked to `/usr/local/bin/netmode`. SSID, IP, gateway and DNS are variables at the top of the file — edit there if the router config ever changes.

### By hand, if the script isn't available

**System Settings → Network → Wi-Fi → Details → TCP/IP → Configure IPv4**

**Normal Wi-Fi elsewhere** → set to *Using DHCP*, and clear the DNS tab.

**Back to show mode** → set to *Manually*, then:

| Field | Value |
|---|---|
| IP Address | `192.168.8.10` |
| Subnet Mask | `255.255.255.0` |
| Router | `192.168.8.1` |
| DNS | `192.168.8.1` |

DNS is set in the separate **DNS** tab, not on the TCP/IP pane. It does nothing offline and is what makes the Wi-Fi uplink work — leave it in permanently.

---

## Pre-gig soundcheck

Do this once, properly, before you rely on it:

- Ethernet unplugged from the Mac
- Studio network out of range
- Power-cycle the Shadow
- Full start sequence from cold

If the faders move SuperCollider under those conditions, the venue is a non-event.
