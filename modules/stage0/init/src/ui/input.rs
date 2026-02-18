use crossterm::event::{self, Event, KeyCode as CrosstermKeyCode};
use evdev::{Device, EventSummary, KeyCode};
use glob::glob;
use std::sync::mpsc::Sender;
use std::thread;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InputEvent {
    Up,
    Down,
    Select,
}

pub fn read(tx: Sender<InputEvent>) {
    read_evdev(tx.clone());
    read_crossterm(tx);
}

fn read_evdev(tx: Sender<InputEvent>) {
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
                                let event = match key {
                                    KeyCode::KEY_VOLUMEUP => Some(InputEvent::Up),
                                    KeyCode::KEY_VOLUMEDOWN => Some(InputEvent::Down),
                                    KeyCode::KEY_POWER => Some(InputEvent::Select),
                                    _ => None,
                                };

                                if let Some(e) = event {
                                    let _ = tx_clone.send(e);
                                }
                            }
                        }
                    }
                }
            });
        }

        Ok(())
    });
}

fn read_crossterm(tx: Sender<InputEvent>) {
    thread::spawn(move || -> anyhow::Result<()> {
        loop {
            if let Event::Key(key) = event::read()? {
                let event = match key.code {
                    CrosstermKeyCode::Up => Some(InputEvent::Up),
                    CrosstermKeyCode::Down => Some(InputEvent::Down),
                    CrosstermKeyCode::Enter => Some(InputEvent::Select),
                    _ => None,
                };

                if let Some(e) = event {
                    let _ = tx.send(e);
                }
            }
        }
    });
}
