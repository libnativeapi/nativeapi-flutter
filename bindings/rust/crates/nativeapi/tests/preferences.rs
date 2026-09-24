use nativeapi::preferences::Preferences;
use std::time::{SystemTime, UNIX_EPOCH};

#[test]
fn native_preferences_roundtrip() {
    let scope = format!(
        "nativeapi-rust-ci-{}-{}",
        std::process::id(),
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos()
    );
    let preferences = Preferences::with_scope(&scope).expect("create native preferences");
    // NSUserDefaults also enumerates inherited system defaults on macOS.
    let original_size = preferences.size();
    assert!(preferences.set("greeting", "Hello 世界"));
    assert!(preferences.contains("greeting"));
    assert_eq!(
        preferences.get("greeting", "fallback").as_deref(),
        Some("Hello 世界")
    );
    assert_eq!(preferences.size(), original_size + 1);
    assert!(preferences.keys().contains(&"greeting".to_owned()));
    assert_eq!(
        preferences.all().get("greeting").map(String::as_str),
        Some("Hello 世界")
    );
    assert!(preferences.remove("greeting"));
    assert_eq!(
        preferences.get("greeting", "fallback").as_deref(),
        Some("fallback")
    );
    assert!(preferences.clear());
    assert!(!preferences.contains("greeting"));
    assert!(!preferences.keys().contains(&"greeting".to_owned()));
}
