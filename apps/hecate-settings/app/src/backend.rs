use cxx_qt::CxxQtType;
use cxx_qt_lib::QString;
use hecate_engine::{bind_line, curve_line, literal, load, save, Bind, Overrides};
use serde_json::{json, Map, Value};
use std::{collections::HashMap, pin::Pin, fs, io::Write, path::PathBuf, process::Command};
use toml_edit::{value, Array, DocumentMut};

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qproperty(bool, is_dirty, cxx_name = "isDirty")]
        type Backend = super::BackendRust;

        #[qinvokable]
        fn load(self: Pin<&mut Backend>) -> QString;
        #[qinvokable]
        fn set(self: Pin<&mut Backend>, name: &QString, json: &QString);
        #[qinvokable]
        fn apply(self: Pin<&mut Backend>);
        #[qinvokable]
        fn revert(self: Pin<&mut Backend>);
        #[qinvokable]
        #[cxx_name = "setBind"]
        fn set_bind(self: Pin<&mut Backend>, old: &QString, json: &QString);
        #[qinvokable]
        #[cxx_name = "setCurve"]
        fn set_curve(self: Pin<&mut Backend>, name: &QString, json: &QString);
        #[qinvokable]
        fn hook(self: &Backend);
        #[qinvokable]
        fn theme(self: &Backend) -> QString;
        #[qinvokable]
        #[cxx_name = "openWallpaper"]
        fn open_wallpaper(self: &Backend);
        #[qinvokable]
        fn sysinfo(self: &Backend) -> QString;
        #[qinvokable]
        fn layout(self: &Backend, section: &QString) -> QString;
        #[qinvokable]
        #[cxx_name = "setLayout"]
        fn set_layout(self: &Backend, section: &QString, json: &QString) -> bool;
        #[qinvokable]
        fn monitors(self: &Backend) -> QString;
        #[qinvokable]
        #[cxx_name = "applyMonitorLayout"]
        fn apply_monitor_layout(self: &Backend, name: &QString, x: i32, y: i32, width: i32, height: i32, scale: f64, refresh: f64) -> bool;
    }
}

#[derive(Default)]
pub struct BackendRust {
    overrides: Overrides,
    base: Map<String, Value>,
    pending: Map<String, Value>,
    is_dirty: bool,
}

const HOOK: &str = "require(\"hecate_overrides\")";

fn home(rel: &str) -> PathBuf {
    PathBuf::from(std::env::var("HOME").unwrap_or_default()).join(rel)
}

fn config() -> PathBuf {
    home(".config/hypr/hyprland.lua")
}

fn overrides() -> PathBuf {
    home(".config/hypr/hecate_overrides.lua")
}

fn hooked() -> bool {
    fs::read_to_string(config()).is_ok_and(|s| s.contains("hecate_overrides"))
}

fn load_json(r: &mut BackendRust) -> mlua::Result<Value> {
    let path = overrides();
    if path.exists() {
        r.overrides = load(&path, None)?.into();
    }
    let extra = (!hooked() && path.exists()).then_some(path.as_path());
    let mut loaded = load(&config(), extra)?;
    for s in &mut loaded.settings {
        r.base.insert(s.entry.name.clone(), s.value.clone().unwrap_or_else(|| s.entry.default.clone()));
        if let Some(v) = r.pending.get(&s.entry.name) {
            s.value = Some(v.clone());
        }
    }
    let mut out = serde_json::to_value(loaded).map_err(mlua::Error::external)?;
    out["hooked"] = hooked().into();
    Ok(out)
}

fn eval(code: &str) {
    let _ = Command::new("hyprctl").args(["eval", code]).status();
}

fn persist(o: &Overrides, code: &str) {
    let _ = save(&overrides(), o);
    eval(code);
}

fn same(a: &Value, b: &Value) -> bool {
    let num = |v: &Value| v.as_f64().or_else(|| v.as_str()?.trim().parse().ok());
    match (num(a), num(b)) {
        (Some(x), Some(y)) => x == y,
        _ => a == b,
    }
}

#[cfg(test)]
#[test]
fn same_ignores_number_form() {
    assert!(same(&json!("5"), &json!(5)));
    assert!(same(&json!(1.0), &json!(1)));
    assert!(same(&json!("5,10,5,10"), &json!("5,10,5,10")));
    assert!(!same(&json!("5"), &json!(6)));
    assert!(!same(&json!(true), &json!(1)));
}

impl qobject::Backend {
    fn load(mut self: Pin<&mut Self>) -> QString {
        let out = load_json(&mut self.as_mut().rust_mut()).unwrap_or_else(|e| json!({ "error": e.to_string() }));
        QString::from(out.to_string())
    }

    fn set(mut self: Pin<&mut Self>, name: &QString, json: &QString) {
        let (Ok(v), name) = (serde_json::from_str::<Value>(&json.to_string()), name.to_string()) else {
            return;
        };
        eval(&format!("hl.config({{ [{name:?}] = {} }})", literal(&v)));
        let mut r = self.as_mut().rust_mut();
        if r.base.get(&name).is_some_and(|b| same(b, &v)) {
            r.pending.remove(&name);
        } else {
            r.pending.insert(name, v);
        }
        let dirty = !r.pending.is_empty();
        self.set_is_dirty(dirty);
    }

    fn apply(mut self: Pin<&mut Self>) {
        let mut r = self.as_mut().rust_mut();
        let pending = r.pending.clone();
        r.overrides.config.extend(pending.clone());
        if save(&overrides(), &r.overrides).is_err() {
            return;
        }
        r.base.extend(pending);
        r.pending.clear();
        self.set_is_dirty(false);
    }

    fn revert(mut self: Pin<&mut Self>) {
        let mut r = self.as_mut().rust_mut();
        let pending = std::mem::take(&mut r.pending);
        let fields: String = pending.keys().filter_map(|k| Some(format!("[{k:?}] = {}, ", literal(r.base.get(k)?)))).collect();
        if !fields.is_empty() {
            eval(&format!("hl.config({{ {fields}}})"));
        }
        self.set_is_dirty(false);
    }

    fn set_bind(mut self: Pin<&mut Self>, old: &QString, json: &QString) {
        let (old, Ok(bind)) = (old.to_string(), serde_json::from_str::<Option<Bind>>(&json.to_string())) else {
            return;
        };
        let line = match &bind {
            Some(b) => match bind_line(b) {
                Some(line) => line,
                None => return,
            },
            None => String::new(),
        };
        let o = &mut self.as_mut().rust_mut().overrides;
        let mut code = String::new();
        if !old.is_empty() {
            o.binds.retain(|b| b.keys != old);
            if !o.unbound.contains(&old) {
                o.unbound.push(old.clone());
            }
            code = format!("hl.unbind({old:?})\n");
        }
        o.binds.extend(bind);
        persist(o, &(code + &line));
    }

    fn set_curve(mut self: Pin<&mut Self>, name: &QString, json: &QString) {
        let (name, Ok(def)) = (name.to_string(), serde_json::from_str::<Value>(&json.to_string())) else {
            return;
        };
        if name.is_empty() || !def.is_object() {
            return;
        }
        let o = &mut self.as_mut().rust_mut().overrides;
        let line = curve_line(&name, &def);
        o.curves.insert(name, def);
        persist(o, &line);
    }

    fn hook(&self) {
        if !overrides().exists() {
            let _ = save(&overrides(), &self.overrides);
        }
        if !hooked() {
            let _ = fs::OpenOptions::new().append(true).open(config()).and_then(|mut f| writeln!(f, "\n{HOOK}"));
        }
    }

    fn theme(&self) -> QString {
        let colors: Option<Value> = fs::read_to_string(home(".cache/hecate/theme.json")).ok().and_then(|s| serde_json::from_str(&s).ok());
        let font = read_toml()["theme"]["font"].as_str().map(String::from);
        let wallpaper = fs::canonicalize(home(".cache/hecate/wallpaper")).ok();
        QString::from(json!({ "colors": colors, "font": font, "wallpaper": wallpaper }).to_string())
    }

    fn open_wallpaper(&self) {
        let _ = Command::new("qs").args(["ipc", "call", "hecate", "toggle", "wallpaper"]).spawn();
    }

    fn sysinfo(&self) -> QString {
        let read = |p: &str| fs::read_to_string(p).unwrap_or_default();
        let stdout = |cmd: &str, args: &[&str]| {
            Command::new(cmd).args(args).output().map(|o| String::from_utf8_lossy(&o.stdout).into_owned()).unwrap_or_default()
        };
        let release = read("/etc/os-release");
        let os = release.lines().find_map(|l| l.strip_prefix("PRETTY_NAME=")).unwrap_or("Linux").trim_matches('"');
        let meminfo = read("/proc/meminfo");
        let ram_kb = meminfo.lines().find_map(|l| l.strip_prefix("MemTotal:")?.trim().strip_suffix("kB")?.trim().parse::<u64>().ok());
        let hyprland = serde_json::from_str::<Value>(&stdout("hyprctl", &["version", "-j"])).ok().and_then(|v| v["version"].as_str().map(String::from));
        let disk = stdout("df", &["-B1", "--output=size", "/"]).lines().nth(1).and_then(|l| l.trim().parse::<u64>().ok());
        let doc = read_toml();
        QString::from(
            json!({
                "os": os,
                "kernel": read("/proc/sys/kernel/osrelease").trim(),
                "hyprland": hyprland,
                "hecate": doc["metadata"]["version"].as_str(),
                "ram": ram_kb.map(|k| k * 1024),
                "disk": disk,
            })
            .to_string(),
        )
    }

    fn layout(&self, section: &QString) -> QString {
        let section = section.to_string();
        let doc = read_toml();
        let mut out = json!({});
        for &z in zones(&section) {
            out[z] = doc[&section][z].as_array().map(|a| a.iter().filter_map(|v| v.as_str()).collect::<Vec<_>>()).unwrap_or_default().into();
        }
        let mut available: Vec<String> = match zones(&section) {
            [] => vec![],
            _ => fs::read_dir(home(&format!(".config/quickshell/modules/{section}/widgets")))
                .into_iter()
                .flatten()
                .flatten()
                .filter_map(|e| widget_name(&e.file_name().into_string().ok()?))
                .collect(),
        };
        available.sort();
        out["available"] = available.into();
        QString::from(out.to_string())
    }

    fn set_layout(&self, section: &QString, json: &QString) -> bool {
        let Ok(names) = serde_json::from_str::<HashMap<String, Vec<String>>>(&json.to_string()) else {
            return false;
        };
        let Some(out) = fs::read_to_string(hecate_toml()).ok().and_then(|s| with_layout(&s, &section.to_string(), &names)) else {
            return false;
        };
        fs::write(hecate_toml(), out).is_ok()
    }
}

impl qobject::Backend {
    fn monitors(&self) -> QString {
        let raw = Command::new("hyprctl").args(["monitors", "-j"]).output().map(|o| o.stdout).unwrap_or_default();
        QString::from(parse_monitors(&raw).to_string())
    }

    fn apply_monitor_layout(&self, name: &QString, x: i32, y: i32, width: i32, height: i32, scale: f64, refresh: f64) -> bool {
        let code = monitor_line(&name.to_string(), x, y, width, height, scale, refresh);
        Command::new("hyprctl").args(["eval", &code]).output().is_ok_and(|o| o.status.success())
    }
}

fn parse_monitors(raw: &[u8]) -> Value {
    let list: Vec<Value> = serde_json::from_slice(raw).unwrap_or_default();
    list.iter()
        .map(|m| {
            json!({
                "name": m["name"], "width": m["width"], "height": m["height"], "x": m["x"], "y": m["y"],
                "scale": m["scale"], "refreshRate": m["refreshRate"], "transform": m["transform"],
            })
        })
        .collect()
}

fn monitor_line(name: &str, x: i32, y: i32, width: i32, height: i32, scale: f64, refresh: f64) -> String {
    format!("hl.monitor({{ output = {name:?}, mode = \"{width}x{height}@{refresh}\", position = \"{x}x{y}\", scale = {scale} }})")
}

fn hecate_toml() -> PathBuf {
    home(".config/hecate/hecate.toml")
}

fn read_toml() -> DocumentMut {
    fs::read_to_string(hecate_toml()).ok().and_then(|s| s.parse().ok()).unwrap_or_default()
}

fn widget_name(file: &str) -> Option<String> {
    let mut c = file.strip_suffix(".qml")?.chars();
    Some(c.next()?.to_lowercase().chain(c).collect())
}

fn zones(section: &str) -> &'static [&'static str] {
    match section {
        "bar" => &["left", "center", "right"],
        "desktop" => &["left", "right"],
        _ => &[],
    }
}

fn with_layout(src: &str, section: &str, names: &HashMap<String, Vec<String>>) -> Option<String> {
    let mut doc: DocumentMut = src.parse().ok()?;
    if zones(section).is_empty() {
        return None;
    }
    for &zone in zones(section) {
        if let Some(list) = names.get(zone) {
            doc[section][zone] = value(list.iter().collect::<Array>());
        }
    }
    Some(doc.to_string())
}

#[cfg(test)]
#[test]
fn monitors_parse_and_format() {
    let raw = br#"[{"id":0,"name":"HDMI-A-1","width":1920,"height":1080,"refreshRate":60.0,"x":0,"y":0,"scale":1.25,"transform":1,"focused":true}]"#;
    let m = &parse_monitors(raw)[0];
    assert_eq!((m["name"].as_str(), m["width"].as_i64(), m["scale"].as_f64(), m["transform"].as_i64()), (Some("HDMI-A-1"), Some(1920), Some(1.25), Some(1)));
    assert!(m.get("focused").is_none());
    assert_eq!(parse_monitors(b"garbage"), json!([]));
    assert_eq!(
        monitor_line("DP-1", -1920, 0, 2560, 1440, 1.5, 143.912),
        r#"hl.monitor({ output = "DP-1", mode = "2560x1440@143.912", position = "-1920x0", scale = 1.5 })"#
    );
    assert!(monitor_line("HDMI-A-1", 0, 0, 1920, 1080, 1.0, 60.0).contains("@60\", position = \"0x0\", scale = 1 "));
}

#[cfg(test)]
#[test]
fn with_layout_keeps_the_rest() {
    let src = "# top\n[bar]\nleft = [\"a\"]\nright = [\n  \"b\",\n]\n\n[widgets.clock]\nformat = \"x\" # keep\n";
    let zones = HashMap::from([("right".to_string(), vec!["b".to_string(), "c".to_string()]), ("bogus".to_string(), vec![])]);
    let out = with_layout(src, "bar", &zones).unwrap();
    assert!(out.contains("# top") && out.contains("format = \"x\" # keep") && out.contains("left = [\"a\"]"));
    assert!(out.contains("right = [\"b\", \"c\"]") && !out.contains("bogus"));
    assert_eq!(widget_name("Windows.qml").as_deref(), Some("windows"));
    assert!(with_layout("not = [toml", "bar", &zones).is_none());
    assert!(with_layout(src, "../x", &zones).is_none());
    let desk = "[desktop]\nleft = [\"clock\"]\nright = []\n\n[desktop.clock]\ntwelve_hour = true\n";
    let moved = HashMap::from([("left".to_string(), vec![]), ("right".to_string(), vec!["clock".to_string()]), ("center".to_string(), vec!["x".to_string()])]);
    let out = with_layout(desk, "desktop", &moved).unwrap();
    assert!(out.contains("left = []") && out.contains("right = [\"clock\"]") && out.contains("twelve_hour = true") && !out.contains("center"));
}
