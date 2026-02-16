use evdev::{Device, EventSummary, KeyCode};
use glob::glob;
use std::{sync::mpsc::Sender, thread};

pub fn read(tx: Sender<KeyCode>) {
    thread::spawn(move || -> anyhow::Result<()> {
        for entry in glob("/dev/input/event*")? {
            let Ok(mut device) = Device::open(entry?) else {
                continue;
            };
            let supported = device.supported_keys().is_some_and(|keys| {
                keys.iter().any(|x| {
                    matches!(
                        x,
                        KeyCode::KEY_VOLUMEUP | KeyCode::KEY_VOLUMEDOWN | KeyCode::KEY_POWER
                    )
                })
            });

            if !supported {
                continue;
            }

            let tx_clone = tx.clone();
            thread::spawn(move || {
                loop {
                    if let Ok(events) = device.fetch_events() {
                        for ev in events {
                            if let EventSummary::Key(_, key, 0) = ev.destructure() {
                                let _ = tx_clone.send(key);
                            }
                        }
                    }
                }
            });
        }

        Ok(())
    });
}
