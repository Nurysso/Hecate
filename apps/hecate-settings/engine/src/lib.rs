use mlua::{Function, HookTriggers, Lua, LuaOptions, LuaSerdeExt, MultiValue, StdLib, Table, Value as LuaValue};
use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};
use std::{
    cell::RefCell,
    collections::{HashMap, HashSet},
    fs,
    path::Path,
    rc::Rc,
};

const SCHEMA: &str = include_str!("../../../scripts/config_schema.json");

const SANDBOX: &str = r#"
local function proxy() return setmetatable({}, { __index = proxy, __call = proxy }) end
hl = proxy()
local function dsp(path)
    return setmetatable({}, {
        __index = function(_, k) return dsp(path and path .. "." .. k or k) end,
        __call = function(_, ...) return { __dsp = path, args = { ... } } end,
    })
end
hl.dsp = dsp()
print = function() end
dofile, loadfile = nil, nil
"#;

#[derive(Serialize, Deserialize)]
pub struct Entry {
    pub name: String,
    #[serde(rename = "type")]
    pub kind: String,
    pub default: Value,
    pub description: String,
    pub category: String,
    pub is_dynamic: bool,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub min: Option<f64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub max: Option<f64>,
}

#[derive(Serialize)]
pub struct Setting {
    #[serde(flatten)]
    pub entry: Entry,
    pub value: Option<Value>,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct Dispatcher {
    pub path: String,
    pub args: Vec<Value>,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct Bind {
    pub keys: String,
    pub dispatcher: Option<Dispatcher>,
    #[serde(default)]
    pub opts: Value,
    #[serde(default)]
    pub description: String,
    #[serde(default)]
    pub section: String,
    #[serde(default)]
    pub dynamic: bool,
    #[serde(skip)]
    origin: Option<(String, i32)>,
}

#[derive(Serialize)]
pub struct Curve {
    pub name: String,
    pub def: Value,
}

#[derive(Serialize)]
pub struct Loaded {
    pub settings: Vec<Setting>,
    pub ignored: Vec<String>,
    pub binds: Vec<Bind>,
    pub unbound: Vec<String>,
    pub curves: Vec<Curve>,
}

#[derive(Default)]
pub struct Overrides {
    pub config: Map<String, Value>,
    pub unbound: Vec<String>,
    pub binds: Vec<Bind>,
    pub curves: Map<String, Value>,
}

impl From<Loaded> for Overrides {
    fn from(l: Loaded) -> Self {
        Overrides {
            config: l.settings.into_iter().filter_map(|s| s.value.map(|v| (s.entry.name, v))).collect(),
            unbound: l.unbound,
            binds: l.binds,
            curves: l.curves.into_iter().map(|c| (c.name, c.def)).collect(),
        }
    }
}

fn flatten(prefix: &str, v: Value, leaves: &HashSet<&str>, out: &mut Map<String, Value>) {
    match v {
        Value::Object(m) if !leaves.contains(prefix) && !m.is_empty() => {
            for (k, v) in m {
                let key = if prefix.is_empty() { k } else { format!("{prefix}.{k}") };
                flatten(&key, v, leaves, out);
            }
        }
        v => {
            out.insert(prefix.into(), v);
        }
    }
}

fn fits(kind: &str, v: &Value) -> bool {
    match kind {
        "bool" => v.is_boolean(),
        "int" => v.is_i64() || v.is_u64(),
        "float" => v.is_number(),
        "string" => v.is_string(),
        _ => true,
    }
}

fn comment(line: &str) -> Option<&str> {
    let (mut quote, mut escaped) = (None, false);
    for (i, c) in line.char_indices() {
        match (quote, c) {
            (Some(_), _) if escaped => escaped = false,
            (Some(_), '\\') => escaped = true,
            (Some(q), c) if c == q => quote = None,
            (None, '"' | '\'') => quote = Some(c),
            (None, '-') if line[i..].starts_with("--") => return Some(line[i + 2..].trim()),
            _ => {}
        }
    }
    None
}

fn one_line(s: &str) -> String {
    s.replace(['\n', '\r'], " ")
}

pub fn load(config: &Path, overrides: Option<&Path>) -> mlua::Result<Loaded> {
    let schema: Vec<Entry> = serde_json::from_str(SCHEMA).map_err(mlua::Error::external)?;
    let lua = Lua::new_with(StdLib::TABLE | StdLib::STRING | StdLib::MATH, LuaOptions::default())?;
    lua.set_memory_limit(256 << 20)?;
    lua.set_hook(HookTriggers::new().every_nth_instruction(10_000_000), |_, _| {
        Err(mlua::Error::runtime("config exceeded its instruction budget"))
    });
    lua.load(SANDBOX).exec()?;
    let os = lua.create_table()?;
    os.set("getenv", lua.create_function(|_, k: String| Ok(std::env::var(k).ok()))?)?;
    lua.globals().set("os", os)?;

    let calls = Rc::new(RefCell::new(Vec::<Value>::new()));
    let sink = calls.clone();
    let hl: Table = lua.globals().get("hl")?;
    hl.raw_set(
        "config",
        lua.create_function(move |lua, t: LuaValue| {
            sink.borrow_mut().push(lua.from_value(t)?);
            Ok(())
        })?,
    )?;

    let binds = Rc::new(RefCell::new(Vec::<Bind>::new()));
    let unbound = Rc::new(RefCell::new(Vec::<String>::new()));
    let curves = Rc::new(RefCell::new(Vec::<Curve>::new()));
    let sources = Rc::new(RefCell::new(HashMap::<String, String>::new()));

    let (b, u) = (binds.clone(), unbound.clone());
    hl.raw_set(
        "unbind",
        lua.create_function(move |_, keys: String| {
            b.borrow_mut().retain(|x| x.keys != keys);
            u.borrow_mut().push(keys);
            Ok(())
        })?,
    )?;

    let b = binds.clone();
    hl.raw_set(
        "bind",
        lua.create_function(move |lua, (keys, action, opts): (String, LuaValue, Option<LuaValue>)| {
            let dispatcher = match &action {
                LuaValue::Table(t) => t.raw_get::<Option<String>>("__dsp")?.and_then(|path| {
                    let args = t.raw_get::<Table>("args").ok()?;
                    let args = args.sequence_values::<LuaValue>().map(|v| lua.from_value(v?)).collect::<mlua::Result<_>>();
                    Some(Dispatcher { path, args: args.ok()? })
                }),
                _ => None,
            };
            let origin = (1..).map_while(|l| lua.inspect_stack(l)).find_map(|d| {
                let s = d.source();
                (s.what == "main").then(|| (s.source.unwrap_or_default().trim_start_matches(['=', '@']).to_string(), d.curr_line()))
            });
            let opts = opts.and_then(|o| lua.from_value(o).ok()).unwrap_or(Value::Null);
            b.borrow_mut().push(Bind {
                keys: keys.clone(),
                dispatcher,
                opts,
                description: String::new(),
                section: String::new(),
                dynamic: false,
                origin,
            });
            let unbind: Function = lua.globals().get::<Table>("hl")?.raw_get("unbind")?;
            let remove = lua.create_function(move |_, _: MultiValue| unbind.call::<()>(keys.clone()))?;
            let handle = lua.create_table()?;
            handle.set("unbind", remove.clone())?;
            handle.set("remove", remove)?;
            Ok(handle)
        })?,
    )?;

    let c = curves.clone();
    hl.raw_set(
        "curve",
        lua.create_function(move |lua, (name, def): (String, LuaValue)| {
            let def = lua.from_value(def)?;
            let mut c = c.borrow_mut();
            match c.iter_mut().find(|x| x.name == name) {
                Some(x) => x.def = def,
                None => c.push(Curve { name, def }),
            }
            Ok(())
        })?,
    )?;

    let root = config.parent().unwrap_or(Path::new(".")).to_path_buf();
    let srcs = sources.clone();
    lua.globals().set(
        "require",
        lua.create_function(move |lua, name: String| {
            if name.contains("..") || !name.chars().all(|c| c.is_alphanumeric() || c == '_' || c == '.') {
                return Err(mlua::Error::runtime(format!("bad module name: {name}")));
            }
            let path = root.join(name.replace('.', "/")).with_extension("lua");
            let src = fs::read_to_string(path).map_err(mlua::Error::external)?;
            srcs.borrow_mut().insert(name.clone(), src.clone());
            lua.load(src).set_name(name).call::<LuaValue>(())
        })?,
    )?;

    let run = |path: &Path, name: &str| -> mlua::Result<()> {
        let src = fs::read_to_string(path).map_err(mlua::Error::external)?;
        sources.borrow_mut().insert(name.into(), src.clone());
        lua.load(src).set_name(name).exec()
    };
    run(config, "hyprland.lua")?;
    if let Some(o) = overrides {
        run(o, "hecate_overrides")?;
    }

    let sources = sources.borrow();
    let mut binds = binds.take();
    let mut seen = HashMap::new();
    for b in &binds {
        *seen.entry(b.origin.clone()).or_insert(0) += 1;
    }
    for b in &mut binds {
        b.dynamic = b.dispatcher.is_none() || (b.origin.is_some() && seen[&b.origin] > 1);
        if let Some((name, line)) = &b.origin {
            let lines: Vec<&str> = sources.get(name).map(|s| s.lines().collect()).unwrap_or_default();
            let at = (*line as usize).saturating_sub(1).min(lines.len());
            b.description = lines.get(at).and_then(|l| comment(l)).unwrap_or_default().into();
            b.section = lines[..at].iter().rev().find_map(|l| l.trim().strip_prefix("--/")).unwrap_or_default().trim().into();
        }
    }

    let leaves: HashSet<&str> = schema.iter().map(|e| e.name.as_str()).collect();
    let mut set = Map::new();
    for call in calls.take() {
        flatten("", call, &leaves, &mut set);
    }

    let mut ignored = vec![];
    let settings = schema
        .into_iter()
        .map(|entry| {
            let value = match set.remove(&entry.name) {
                Some(v) if !entry.is_dynamic && fits(&entry.kind, &v) => Some(v),
                Some(_) => {
                    ignored.push(entry.name.clone());
                    None
                }
                None => None,
            };
            Setting { entry, value }
        })
        .collect();
    ignored.extend(set.into_iter().map(|(k, _)| k));
    Ok(Loaded { settings, ignored, binds, unbound: unbound.take(), curves: curves.take() })
}

pub fn literal(v: &Value) -> String {
    match v {
        Value::Null => "nil".into(),
        Value::String(s) => format!("{s:?}"),
        Value::Array(a) => format!("{{{}}}", a.iter().map(literal).collect::<Vec<_>>().join(", ")),
        Value::Object(m) => format!("{{{}}}", m.iter().map(|(k, v)| format!("[{k:?}] = {}", literal(v))).collect::<Vec<_>>().join(", ")),
        v => v.to_string(),
    }
}

pub fn bind_line(b: &Bind) -> Option<String> {
    let d = b.dispatcher.as_ref()?;
    if !d.path.split('.').all(|s| !s.is_empty() && s.chars().all(|c| c.is_ascii_alphanumeric() || c == '_')) {
        return None;
    }
    let args = d.args.iter().map(literal).collect::<Vec<_>>().join(", ");
    let opts = if b.opts.is_null() { String::new() } else { format!(", {}", literal(&b.opts)) };
    let desc = if b.description.is_empty() { String::new() } else { format!(" -- {}", one_line(&b.description)) };
    Some(format!("hl.bind({:?}, hl.dsp.{}({args}){opts}){desc}", b.keys, d.path))
}

pub fn curve_line(name: &str, def: &Value) -> String {
    format!("hl.curve({name:?}, {})", literal(def))
}

/// Writes the whole override set; require it last from hyprland.lua so it shadows earlier values.
pub fn save(path: &Path, o: &Overrides) -> std::io::Result<()> {
    let config: String = o.config.iter().map(|(k, v)| format!("    [{k:?}] = {},\n", literal(v))).collect();
    let mut out = format!("hl.config({{\n{config}}})\n");
    for k in &o.unbound {
        out += &format!("hl.unbind({k:?})\n");
    }
    let mut section = "";
    for b in &o.binds {
        if b.section != section {
            section = &b.section;
            out += &format!("--/ {}\n", one_line(section));
        }
        out.extend(bind_line(b).map(|l| l + "\n"));
    }
    for (name, def) in &o.curves {
        out += &curve_line(name, def);
        out.push('\n');
    }
    fs::write(path, out)
}
