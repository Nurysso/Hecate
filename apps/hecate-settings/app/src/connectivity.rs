use cxx_qt::Threading;
use cxx_qt_lib::QString;
use serde_json::{json, Value};
use std::{collections::HashMap, env, fs, pin::Pin, process::Command};

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qproperty(bool, network_available, cxx_name = "networkAvailable")]
        #[qproperty(QString, network_reason, cxx_name = "networkReason")]
        #[qproperty(bool, bluetooth_available, cxx_name = "bluetoothAvailable")]
        #[qproperty(QString, bluetooth_reason, cxx_name = "bluetoothReason")]
        #[qproperty(bool, audio_available, cxx_name = "audioAvailable")]
        #[qproperty(QString, audio_tool, cxx_name = "audioTool")]
        #[qproperty(QString, wifi)]
        #[qproperty(QString, bluetooth)]
        #[qproperty(QString, audio)]
        #[qproperty(QString, wifi_busy, cxx_name = "wifiBusy")]
        #[qproperty(QString, bluetooth_busy, cxx_name = "bluetoothBusy")]
        #[qproperty(QString, wifi_error, cxx_name = "wifiError")]
        #[qproperty(QString, bluetooth_error, cxx_name = "bluetoothError")]
        #[qproperty(QString, audio_error, cxx_name = "audioError")]
        type Connectivity = super::ConnectivityRust;

        #[qinvokable]
        fn refresh(self: Pin<&mut Connectivity>);
        #[qinvokable]
        #[cxx_name = "wifiConnect"]
        fn wifi_connect(self: Pin<&mut Connectivity>, ssid: &QString, password: &QString);
        #[qinvokable]
        #[cxx_name = "wifiDisconnect"]
        fn wifi_disconnect(self: Pin<&mut Connectivity>);
        #[qinvokable]
        #[cxx_name = "btScan"]
        fn bt_scan(self: Pin<&mut Connectivity>);
        #[qinvokable]
        #[cxx_name = "btConnect"]
        fn bt_connect(self: Pin<&mut Connectivity>, mac: &QString);
        #[qinvokable]
        #[cxx_name = "btDisconnect"]
        fn bt_disconnect(self: Pin<&mut Connectivity>, mac: &QString);
        #[qinvokable]
        #[cxx_name = "setVolume"]
        fn set_volume(self: Pin<&mut Connectivity>, volume: f64);
        #[qinvokable]
        #[cxx_name = "toggleMute"]
        fn toggle_mute(self: Pin<&mut Connectivity>);
        #[qinvokable]
        #[cxx_name = "setSink"]
        fn set_sink(self: Pin<&mut Connectivity>, name: &QString);
    }

    impl cxx_qt::Threading for Connectivity {}
}

#[derive(Default)]
pub struct ConnectivityRust {
    network_available: bool,
    network_reason: QString,
    bluetooth_available: bool,
    bluetooth_reason: QString,
    audio_available: bool,
    audio_tool: QString,
    wifi: QString,
    bluetooth: QString,
    audio: QString,
    wifi_busy: QString,
    bluetooth_busy: QString,
    wifi_error: QString,
    bluetooth_error: QString,
    audio_error: QString,
}

type Apply = Box<dyn FnOnce(Pin<&mut qobject::Connectivity>) + Send>;

fn installed(tool: &str) -> bool {
    env::var_os("PATH").is_some_and(|p| env::split_paths(&p).any(|d| d.join(tool).is_file()))
}

fn run(secs: u32, args: &[&str]) -> Result<String, String> {
    let out = Command::new("timeout").arg(secs.to_string()).args(args).output().map_err(|e| format!("{}: {e}", args[0]))?;
    if out.status.success() {
        return Ok(String::from_utf8_lossy(&out.stdout).into_owned());
    }
    if out.status.code() == Some(124) {
        return Err(format!("{} timed out", args[0]));
    }
    let err = String::from_utf8_lossy(&out.stderr).trim().to_string();
    Err(if err.is_empty() { format!("{} failed", args[0]) } else { err })
}

fn qs(s: impl AsRef<str>) -> QString {
    QString::from(s.as_ref())
}

fn split_escaped(line: &str) -> Vec<String> {
    let mut fields = vec![String::new()];
    let mut chars = line.chars();
    while let Some(c) = chars.next() {
        match c {
            '\\' => fields.last_mut().into_iter().for_each(|f| f.extend(chars.next())),
            ':' => fields.push(String::new()),
            c => fields.last_mut().into_iter().for_each(|f| f.push(c)),
        }
    }
    fields
}

fn parse_wifi(text: &str) -> Vec<Value> {
    let mut best: HashMap<String, (bool, i64, bool)> = HashMap::new();
    for line in text.lines() {
        let f = split_escaped(line);
        let [used, ssid, signal, security] = f.as_slice() else { continue };
        if ssid.is_empty() {
            continue;
        }
        let signal = signal.parse().unwrap_or(0);
        let secure = !security.is_empty() && security != "--";
        let e = best.entry(ssid.clone()).or_insert((false, signal, secure));
        e.0 |= used == "*";
        if signal > e.1 {
            e.1 = signal;
            e.2 = secure;
        }
    }
    let mut list: Vec<_> = best.into_iter().collect();
    list.sort_by(|a, b| (b.1 .0, b.1 .1).cmp(&(a.1 .0, a.1 .1)).then(a.0.cmp(&b.0)));
    list.into_iter().map(|(ssid, (connected, signal, secure))| json!({ "ssid": ssid, "signal": signal, "secure": secure, "connected": connected })).collect()
}

fn parse_device(text: &str, kind: &str) -> Option<Value> {
    text.split("\n\n").find_map(|block| {
        let fields: HashMap<String, String> = block
            .lines()
            .filter_map(|l| {
                let mut f = split_escaped(l).into_iter();
                Some((f.next()?, f.collect::<Vec<_>>().join(":")))
            })
            .collect();
        (fields.get("GENERAL.TYPE")? == kind).then(|| {
            let state = fields.get("GENERAL.STATE").map(|s| s.split_once('(').map_or(s.as_str(), |(_, r)| r.trim_end_matches(')'))).unwrap_or("");
            let connection = fields.get("GENERAL.CONNECTION").filter(|c| !c.is_empty() && *c != "--");
            json!({ "iface": fields.get("GENERAL.DEVICE"), "state": state, "connection": connection })
        })
    })
}

fn parse_bt_devices(text: &str) -> Vec<(String, String)> {
    text.lines()
        .filter_map(|l| {
            let rest = l.trim().strip_prefix("Device ")?;
            let (mac, name) = rest.split_once(' ').unwrap_or((rest, ""));
            valid_mac(mac).then(|| (mac.to_string(), if name.is_empty() { mac } else { name }.to_string()))
        })
        .collect()
}

fn parse_bt_connected(info: &str) -> bool {
    info.lines().any(|l| l.trim() == "Connected: yes")
}

fn valid_mac(mac: &str) -> bool {
    let parts: Vec<_> = mac.split(':').collect();
    parts.len() == 6 && parts.iter().all(|p| p.len() == 2 && p.chars().all(|c| c.is_ascii_hexdigit()))
}

fn parse_volume(text: &str) -> Option<(f64, bool)> {
    let rest = text.trim().strip_prefix("Volume:")?.trim();
    let level = rest.split_whitespace().next()?.parse().ok()?;
    Some((level, rest.contains("[MUTED]")))
}

fn parse_pactl_volume(volume: &str, mute: &str) -> Option<(f64, bool)> {
    let pct = volume.split('/').nth(1)?.trim().strip_suffix('%')?.trim().parse::<f64>().ok()?;
    Some((pct / 100.0, mute.trim() == "Mute: yes"))
}

fn parse_sinks(text: &str) -> Vec<Value> {
    let list: Vec<Value> = serde_json::from_str(text).unwrap_or_default();
    list.iter()
        .filter_map(|s| Some(json!({ "name": s["name"].as_str()?, "description": s["description"].as_str().unwrap_or(s["name"].as_str()?) })))
        .collect()
}

fn wifi_snapshot() -> Apply {
    let available = installed("nmcli").then(|| run(3, &["nmcli", "-t", "general", "status"]));
    let state = match &available {
        Some(Ok(_)) => run(5, &["nmcli", "-t", "device", "show"]).and_then(|dev| {
            let list = run(15, &["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"])?;
            let mut out = parse_device(&dev, "wifi").unwrap_or_else(|| json!({}));
            out["networks"] = parse_wifi(&list).into();
            out["wired"] = parse_device(&dev, "ethernet").map_or(Value::Null, |d| d["connection"].clone());
            Ok(out)
        }),
        _ => Ok(json!({})),
    };
    Box::new(move |mut o| {
        let reason = match &available {
            None => "NetworkManager not installed".into(),
            Some(Err(_)) => "NetworkManager isn't running".into(),
            Some(Ok(_)) => String::new(),
        };
        o.as_mut().set_network_available(reason.is_empty());
        o.as_mut().set_network_reason(qs(reason));
        match state {
            Ok(v) => {
                o.as_mut().set_wifi(qs(v.to_string()));
                o.as_mut().set_wifi_error(QString::default());
            }
            Err(e) => o.as_mut().set_wifi_error(qs(e)),
        }
    })
}

fn bluetooth_snapshot() -> Apply {
    let reason = if !installed("bluetoothctl") {
        "Bluetooth tools not installed (bluez-utils)"
    } else if !fs::read_dir("/sys/class/bluetooth").is_ok_and(|mut d| d.next().is_some()) {
        "No Bluetooth adapter found"
    } else {
        ""
    };
    let state = reason.is_empty().then(|| {
        let paired = parse_bt_devices(&run(5, &["bluetoothctl", "devices", "Paired"])?);
        let all = parse_bt_devices(&run(5, &["bluetoothctl", "devices"])?);
        let paired_json: Vec<Value> = paired
            .iter()
            .map(|(mac, name)| {
                let connected = run(5, &["bluetoothctl", "info", mac]).is_ok_and(|i| parse_bt_connected(&i));
                json!({ "mac": mac, "name": name, "connected": connected })
            })
            .collect();
        let nearby: Vec<Value> =
            all.iter().filter(|(mac, _)| !paired.iter().any(|(p, _)| p == mac)).map(|(mac, name)| json!({ "mac": mac, "name": name })).collect();
        Ok::<_, String>(json!({ "paired": paired_json, "nearby": nearby }))
    });
    Box::new(move |mut o| {
        let reason = match &state {
            Some(Err(e)) if e.ends_with("timed out") => "Bluetooth service isn't running",
            _ => reason,
        };
        o.as_mut().set_bluetooth_available(reason.is_empty());
        o.as_mut().set_bluetooth_reason(qs(reason));
        match state {
            Some(Ok(v)) => {
                o.as_mut().set_bluetooth(qs(v.to_string()));
                o.as_mut().set_bluetooth_error(QString::default());
            }
            Some(Err(e)) => o.as_mut().set_bluetooth_error(qs(e)),
            None => {}
        }
    })
}

fn audio_tool() -> &'static str {
    if installed("wpctl") {
        "wpctl"
    } else if installed("pactl") {
        "pactl"
    } else {
        ""
    }
}

fn audio_snapshot() -> Apply {
    let tool = audio_tool();
    let level = match tool {
        "wpctl" => run(3, &["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]).and_then(|t| parse_volume(&t).ok_or_else(|| format!("unexpected wpctl output: {t}"))),
        "pactl" => run(3, &["pactl", "get-sink-volume", "@DEFAULT_SINK@"]).and_then(|v| {
            let m = run(3, &["pactl", "get-sink-mute", "@DEFAULT_SINK@"])?;
            parse_pactl_volume(&v, &m).ok_or_else(|| format!("unexpected pactl output: {v}"))
        }),
        _ => Err(String::new()),
    };
    let (sinks, default) = if installed("pactl") {
        let sinks = run(3, &["pactl", "-f", "json", "list", "sinks"]).map(|t| parse_sinks(&t)).unwrap_or_default();
        (sinks, run(3, &["pactl", "get-default-sink"]).map(|d| d.trim().to_string()).unwrap_or_default())
    } else {
        (vec![], String::new())
    };
    Box::new(move |mut o| {
        o.as_mut().set_audio_available(!tool.is_empty());
        o.as_mut().set_audio_tool(qs(tool));
        match level {
            Ok((volume, muted)) => {
                o.as_mut().set_audio(qs(json!({ "volume": volume, "muted": muted, "sinks": sinks, "default": default }).to_string()))
            }
            Err(e) if !e.is_empty() => o.as_mut().set_audio_error(qs(e)),
            Err(_) => {}
        }
    })
}

fn then(first: Result<String, String>, snapshot: fn() -> Apply, error: fn(Pin<&mut qobject::Connectivity>, QString)) -> Apply {
    let apply = snapshot();
    Box::new(move |mut o| {
        error(o.as_mut(), qs(first.err().unwrap_or_default()));
        apply(o);
    })
}

impl qobject::Connectivity {
    fn job(self: Pin<&mut Self>, work: impl FnOnce() -> Apply + Send + 'static) {
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let apply = work();
            let _ = thread.queue(move |o| apply(o));
        });
    }

    fn refresh(mut self: Pin<&mut Self>) {
        self.as_mut().set_wifi_busy(qs("refresh"));
        self.as_mut().job(|| done_wifi(wifi_snapshot()));
        self.as_mut().job(bluetooth_snapshot);
        self.job(audio_snapshot);
    }

    fn wifi_connect(mut self: Pin<&mut Self>, ssid: &QString, password: &QString) {
        let (ssid, password) = (ssid.to_string(), password.to_string());
        self.as_mut().set_wifi_busy(qs(&ssid));
        self.job(move || {
            let mut args = vec!["nmcli", "device", "wifi", "connect", ssid.as_str()];
            if !password.is_empty() {
                args.extend(["password", password.as_str()]);
            }
            done_wifi(then(run(60, &args), wifi_snapshot, set_wifi_error))
        });
    }

    fn wifi_disconnect(mut self: Pin<&mut Self>) {
        self.as_mut().set_wifi_busy(qs("disconnect"));
        self.job(|| {
            let result = run(5, &["nmcli", "-t", "device", "show"]).and_then(|dev| {
                let iface = parse_device(&dev, "wifi").and_then(|d| d["iface"].as_str().map(String::from)).ok_or("No Wi-Fi device found")?;
                run(15, &["nmcli", "device", "disconnect", &iface])
            });
            done_wifi(then(result, wifi_snapshot, set_wifi_error))
        });
    }

    fn bt_scan(mut self: Pin<&mut Self>) {
        self.as_mut().set_bluetooth_busy(qs("scan"));
        self.job(|| done_bluetooth(then(run(10, &["bluetoothctl", "--timeout", "5", "scan", "on"]).map(|_| String::new()), bluetooth_snapshot, set_bluetooth_error)));
    }

    fn bt_connect(self: Pin<&mut Self>, mac: &QString) {
        self.bt(mac.to_string(), "connect");
    }

    fn bt_disconnect(self: Pin<&mut Self>, mac: &QString) {
        self.bt(mac.to_string(), "disconnect");
    }

    fn bt(mut self: Pin<&mut Self>, mac: String, action: &'static str) {
        if !valid_mac(&mac) {
            self.set_bluetooth_error(qs(format!("Invalid device address: {mac}")));
            return;
        }
        self.as_mut().set_bluetooth_busy(qs(&mac));
        self.job(move || done_bluetooth(then(run(20, &["bluetoothctl", action, &mac]), bluetooth_snapshot, set_bluetooth_error)));
    }

    fn set_volume(self: Pin<&mut Self>, volume: f64) {
        let v = if volume.is_finite() { volume.clamp(0.0, 1.0) } else { 0.0 };
        self.job(move || {
            let result = match audio_tool() {
                "wpctl" => run(3, &["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", &format!("{v:.2}")]),
                "pactl" => run(3, &["pactl", "set-sink-volume", "@DEFAULT_SINK@", &format!("{}%", (v * 100.0).round())]),
                _ => Err("No audio server found".into()),
            };
            then(result, audio_snapshot, set_audio_error)
        });
    }

    fn toggle_mute(self: Pin<&mut Self>) {
        self.job(|| {
            let result = match audio_tool() {
                "wpctl" => run(3, &["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]),
                "pactl" => run(3, &["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"]),
                _ => Err("No audio server found".into()),
            };
            then(result, audio_snapshot, set_audio_error)
        });
    }

    fn set_sink(self: Pin<&mut Self>, name: &QString) {
        let name = name.to_string();
        if name.is_empty() || name.starts_with('-') {
            self.set_audio_error(qs(format!("Invalid output: {name}")));
            return;
        }
        self.job(move || then(run(3, &["pactl", "set-default-sink", &name]), audio_snapshot, set_audio_error));
    }
}

fn set_wifi_error(o: Pin<&mut qobject::Connectivity>, e: QString) {
    o.set_wifi_error(e);
}

fn set_bluetooth_error(o: Pin<&mut qobject::Connectivity>, e: QString) {
    o.set_bluetooth_error(e);
}

fn set_audio_error(o: Pin<&mut qobject::Connectivity>, e: QString) {
    o.set_audio_error(e);
}

fn done_wifi(apply: Apply) -> Apply {
    Box::new(move |mut o| {
        apply(o.as_mut());
        o.set_wifi_busy(QString::default());
    })
}

fn done_bluetooth(apply: Apply) -> Apply {
    Box::new(move |mut o| {
        apply(o.as_mut());
        o.set_bluetooth_busy(QString::default());
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn split_respects_escapes() {
        assert_eq!(split_escaped(r"*:Cafe\:Free:70:WPA2"), ["*", "Cafe:Free", "70", "WPA2"]);
        assert_eq!(split_escaped(r"a\\b:"), [r"a\b", ""]);
    }

    #[test]
    fn wifi_dedupes_and_sorts() {
        let text = " :Home:40:WPA2\n:Open Net:90:\n*:Home:30:WPA2\n :Home:65:WPA2\n :--:10:\n :Cafe\\:Free:80:--\n :Weak:20:WPA3\n";
        let list = parse_wifi(text);
        let ssids: Vec<_> = list.iter().map(|n| n["ssid"].as_str().unwrap_or_default()).collect();
        assert_eq!(ssids, ["Home", "Open Net", "Cafe:Free", "Weak", "--"]);
        assert_eq!(list[0], json!({ "ssid": "Home", "signal": 65, "secure": true, "connected": true }));
        assert_eq!(list[1]["secure"], false);
        assert_eq!(list[2]["secure"], false);
        assert!(parse_wifi(":::\nnot enough\n").is_empty());
    }

    #[test]
    fn device_finds_wifi_block() {
        let text = "GENERAL.DEVICE:enp4s0\nGENERAL.TYPE:ethernet\nGENERAL.STATE:100 (connected)\nGENERAL.CONNECTION:Wired\n\n\
                    GENERAL.DEVICE:wlp2s0\nGENERAL.TYPE:wifi\nGENERAL.HWADDR:AA\\:BB\\:CC\\:DD\\:EE\\:FF\nGENERAL.STATE:100 (connected)\nGENERAL.CONNECTION:Cafe\\:Free\n";
        assert_eq!(parse_device(text, "wifi"), Some(json!({ "iface": "wlp2s0", "state": "connected", "connection": "Cafe:Free" })));
        assert_eq!(parse_device(text, "ethernet").map(|d| d["connection"].clone()), Some(json!("Wired")));
        let idle = "GENERAL.DEVICE:wlan0\nGENERAL.TYPE:wifi\nGENERAL.STATE:30 (disconnected)\nGENERAL.CONNECTION:--\n";
        assert_eq!(parse_device(idle, "wifi"), Some(json!({ "iface": "wlan0", "state": "disconnected", "connection": null })));
        assert_eq!(parse_device("GENERAL.DEVICE:lo\nGENERAL.TYPE:loopback\n", "wifi"), None);
    }

    #[test]
    fn bluetooth_devices_and_info() {
        let text = "Device AA:BB:CC:DD:EE:FF Sony WH-1000XM4\nDevice 11:22:33:44:55:66 \nDevice nope Bad\n[CHG] Controller x\nDevice 12:34:56:78:9A:BC\n";
        assert_eq!(
            parse_bt_devices(text),
            [
                ("AA:BB:CC:DD:EE:FF".into(), "Sony WH-1000XM4".into()),
                ("11:22:33:44:55:66".into(), "11:22:33:44:55:66".into()),
                ("12:34:56:78:9A:BC".into(), "12:34:56:78:9A:BC".into())
            ]
        );
        assert!(parse_bt_connected("Device AA:BB\n\tName: X\n\tPaired: yes\n\tConnected: yes\n"));
        assert!(!parse_bt_connected("\tConnected: no\n"));
        assert!(valid_mac("aa:BB:0c:DD:ee:FF"));
        assert!(!valid_mac("AA:BB:CC:DD:EE") && !valid_mac("AA:BB:CC:DD:EE:GG") && !valid_mac("--help"));
    }

    #[test]
    fn volume_parsers() {
        assert_eq!(parse_volume("Volume: 0.45\n"), Some((0.45, false)));
        assert_eq!(parse_volume("Volume: 1.20 [MUTED]\n"), Some((1.2, true)));
        assert_eq!(parse_volume("garbage"), None);
        let v = "Volume: front-left: 22282 /  34% / -28.18 dB,   front-right: 22282 /  34% / -28.18 dB\n";
        assert_eq!(parse_pactl_volume(v, "Mute: yes\n"), Some((0.34, true)));
        assert_eq!(parse_pactl_volume("nonsense", "Mute: no"), None);
    }

    #[test]
    fn sinks_from_pactl_json() {
        let text = r#"[{"index":57,"name":"alsa_output.usb","description":"USB Mic"},{"index":59,"name":"alsa_output.pci"},{"index":60}]"#;
        assert_eq!(
            parse_sinks(text),
            [json!({ "name": "alsa_output.usb", "description": "USB Mic" }), json!({ "name": "alsa_output.pci", "description": "alsa_output.pci" })]
        );
        assert!(parse_sinks("not json").is_empty());
    }
}
