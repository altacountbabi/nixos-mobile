use std::fmt::Write;

pub fn get_time_string() -> String {
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default();

    let secs = now.as_secs();
    let hours = (secs / 3600) % 24;
    let minutes = (secs / 60) % 60;

    let mut time_str = String::new();
    let _ = write!(time_str, "{hours:02}:{minutes:02}");
    time_str
}
