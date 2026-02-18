use sysfs::api::psu::{list_power_supplies, power_supply};

pub fn get_battery_percentage() -> Option<u8> {
    for name in list_power_supplies() {
        if let Ok(capacity) = power_supply::capacity(&name) {
            return Some((capacity * 100.0) as u8);
        }
    }

    None
}
