use crate::{cmd, find_closures::SystemClosure};
use evdev::KeyCode;
use std::sync::mpsc;

pub mod input;

#[allow(clippy::unnecessary_wraps)]
pub fn run(closures: Vec<SystemClosure>) -> anyhow::Result<()> {
    let (tx, rx) = mpsc::channel();
    input::read(tx);

    loop {
        if let Ok(ev) = rx.recv() {
            match ev {
                KeyCode::KEY_VOLUMEUP => println!("Volume Up"),
                KeyCode::KEY_VOLUMEDOWN => println!("Volume Down"),
                KeyCode::KEY_POWER => {
                    cmd("poweroff", [])?;
                }
                _ => {
                    dbg!(ev);
                }
            }
        }
    }
}
