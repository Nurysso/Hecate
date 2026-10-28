use cxx_qt::CxxQtType;
use cxx_qt_lib::QString;
use hecate_engine::{bind_line, curve_line, literal, load, save, Bind, Overrides};
use serde_json::{json, Value};
use std::{pin::Pin, fs, io::Write, path::PathBuf, process::Command};

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        type Backend = super::BackendRust;

        #[qinvokable]
        fn load(self: Pin<&mut Backend>) -> QString;
        #[qinvokable]
        fn set(self: Pin<&mut Backend>, name: &QString, json: &QString);
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
    }
}

#[derive(Default)]
pub struct BackendRust {
    overrides: Overrides,
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

fn load_json(o: &mut Overrides) -> mlua::Result<Value> {
    let path = overrides();
    if path.exists() {
        *o = load(&path, None)?.into();
    }
    let extra = (!hooked() && path.exists()).then_some(path.as_path());
    let mut out = serde_json::to_value(load(&config(), extra)?).map_err(mlua::Error::external)?;
    out["hooked"] = hooked().into();
    Ok(out)
}

fn apply(o: &Overrides, code: &str) {
    let _ = save(&overrides(), o);
    let _ = Command::new("hyprctl").args(["eval", code]).status();
}

impl qobject::Backend {
    fn load(mut self: Pin<&mut Self>) -> QString {
        let out = load_json(&mut self.as_mut().rust_mut().overrides).unwrap_or_else(|e| json!({ "error": e.to_string() }));
        QString::from(out.to_string())
    }

    fn set(mut self: Pin<&mut Self>, name: &QString, json: &QString) {
        let (Ok(v), name) = (serde_json::from_str::<Value>(&json.to_string()), name.to_string()) else {
            return;
        };
        let o = &mut self.as_mut().rust_mut().overrides;
        o.config.insert(name.clone(), v.clone());
        apply(o, &format!("hl.config({{ [{name:?}] = {} }})", literal(&v)));
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
        apply(o, &(code + &line));
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
        apply(o, &line);
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
        let font = fs::read_to_string(home(".config/hecate/hecate.toml")).ok().and_then(|s| {
            let line = s.lines().find(|l| l.trim_start().starts_with("font"))?;
            Some(line.split('"').nth(1)?.to_string())
        });
        QString::from(json!({ "colors": colors, "font": font }).to_string())
    }
}
