use hecate_engine::{bind_line, load, save, Bind, Loaded, Overrides};
use serde_json::{from_value, json, Map};
use std::path::Path;

fn fixture(name: &str) -> std::path::PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("tests/fixtures").join(name)
}

fn value(l: &Loaded, name: &str) -> Option<serde_json::Value> {
    l.settings.iter().find(|s| s.entry.name == name).unwrap().value.clone()
}

fn bind<'a>(l: &'a Loaded, keys: &str) -> Option<&'a Bind> {
    l.binds.iter().find(|b| b.keys == keys)
}

#[test]
fn evaluates_and_types_values() {
    let l = load(&fixture("hyprland.lua"), None).unwrap();
    assert_eq!(value(&l, "general.border_size"), Some(json!(3)));
    assert_eq!(value(&l, "general.gaps_out"), Some(json!(9)));
    assert_eq!(value(&l, "decoration.blur.enabled"), Some(json!(false)));
    assert_eq!(value(&l, "general.col.active_border"), Some(json!("rgba(33ccffee)")));
    assert_eq!(value(&l, "general.layout"), None);
    assert_eq!(value(&l, "decoration.rounding"), None);
    assert!(l.ignored.contains(&"decoration.rounding".into()));
    assert!(l.ignored.contains(&"bogus.x".into()));
}

#[test]
fn captures_binds_and_curves() {
    let l = load(&fixture("hyprland.lua"), None).unwrap();
    let q = bind(&l, "SUPER + Q").unwrap();
    let d = q.dispatcher.as_ref().unwrap();
    assert_eq!((d.path.as_str(), d.args.len()), ("window.close", 0));
    assert_eq!((q.description.as_str(), q.section.as_str(), q.dynamic), ("Close it", "Apps", false));

    let t = bind(&l, "SUPER + T").unwrap();
    assert_eq!(t.dispatcher.as_ref().unwrap().args, vec![json!("kitty --x")]);
    assert_eq!(t.opts, json!({ "locked": true }));
    assert_eq!(t.description, "");

    assert!(!bind(&l, "SUPER + P").unwrap().dynamic);
    assert!(!bind(&l, "SUPER + O").unwrap().dynamic);
    let one = bind(&l, "SUPER + 1").unwrap();
    assert!(one.dynamic);
    assert_eq!(one.section, "Workspaces");
    assert_eq!(one.dispatcher.as_ref().unwrap().args, vec![json!({ "workspace": 1 })]);
    assert!(bind(&l, "SUPER + F").unwrap().dynamic);
    assert!(bind(&l, "SUPER + F").unwrap().dispatcher.is_none());
    assert!(bind(&l, "SUPER + Z").is_none());
    assert!(bind(&l, "SUPER + X").is_none());
    assert!(l.unbound.contains(&"SUPER + X".into()));

    assert_eq!(l.curves.len(), 2);
    let c = l.curves.iter().find(|c| c.name == "c").unwrap();
    assert_eq!(c.def["points"], json!([[0.1, 1.1], [0.3, -0.3]]));
    assert_eq!(l.curves.iter().find(|c| c.name == "s").unwrap().def["stiffness"], json!(80));
}

#[test]
fn sandbox_blocks_os_and_runaway_loops() {
    assert!(load(&fixture("evil.lua"), None).is_err());
    assert!(load(&fixture("loop.lua"), None).is_err());
}

#[test]
fn rejects_unsafe_dispatcher_paths() {
    let b: Bind = from_value(json!({ "keys": "A", "dispatcher": { "path": "exit(); os", "args": [] } })).unwrap();
    assert!(bind_line(&b).is_none());
}

#[test]
fn save_round_trips() {
    let mut config = Map::new();
    config.insert("general.border_size".into(), json!(5));
    config.insert("general.layout".into(), json!("ma\"ster"));
    config.insert("general.col.active_border".into(), json!({"colors": ["a", "b"], "angle": 45}));
    let w: Bind = from_value(json!({
        "keys": "SUPER + W",
        "dispatcher": { "path": "exec_cmd", "args": ["a\"b -- c"] },
        "opts": { "locked": true },
        "description": "Do\nthings",
        "section": "Apps",
    }))
    .unwrap();
    let mut curves = Map::new();
    curves.insert("wind".into(), json!({ "type": "bezier", "points": [[0.05, 0.9], [0.1, 1.05]] }));
    let o = Overrides { config, unbound: vec!["SUPER + Q".into()], binds: vec![w], curves };

    let p = std::env::temp_dir().join("hecate_overrides_test.lua");
    save(&p, &o).unwrap();
    let l = load(&p, None).unwrap();
    assert_eq!(value(&l, "general.border_size"), Some(json!(5)));
    assert_eq!(value(&l, "general.layout"), Some(json!("ma\"ster")));
    assert_eq!(value(&l, "general.col.active_border"), Some(json!({"colors": ["a", "b"], "angle": 45})));
    let w = bind(&l, "SUPER + W").unwrap();
    assert_eq!(w.dispatcher.as_ref().unwrap().args, vec![json!("a\"b -- c")]);
    assert_eq!((w.description.as_str(), w.section.as_str()), ("Do things", "Apps"));
    assert_eq!(l.unbound, vec!["SUPER + Q".to_string()]);
    assert_eq!(l.curves[0].def["points"], json!([[0.05, 0.9], [0.1, 1.05]]));

    let merged = load(&fixture("hyprland.lua"), Some(&p)).unwrap();
    assert!(bind(&merged, "SUPER + Q").is_none());
    assert!(bind(&merged, "SUPER + W").is_some());
    assert_eq!(value(&merged, "general.border_size"), Some(json!(5)));
}
