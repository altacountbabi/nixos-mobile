use crate::{Args, find_closures::SystemClosure, kexec::kexec, ui::input::InputEvent};
use anyhow::anyhow;
use crossterm::{
    execute,
    terminal::{EnterAlternateScreen, LeaveAlternateScreen, disable_raw_mode, enable_raw_mode},
};
use ratatui::{
    Frame, Terminal,
    backend::CrosstermBackend,
    layout::{Alignment, Constraint, Direction, Layout, Rect},
    style::{Modifier, Style},
    text::{Line, Span},
    widgets::{List, ListItem, ListState, Paragraph},
};
use serde_json::{Value, json};
use std::{collections::HashMap, fs, io, path::PathBuf, sync::mpsc};

mod battery;
mod input;
mod time;

pub fn run(closures: Vec<SystemClosure>, args: Args) -> anyhow::Result<()> {
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let (tx, rx) = mpsc::channel();
    input::read(tx);

    let mut list_state = ListState::default();
    list_state.select(Some(0));

    let selected_closure: Option<SystemClosure> = loop {
        terminal.draw(|f| {
            let area = f.area();
            let [status_bar_area, main_area, footer_area] = Layout::vertical([
                Constraint::Length(1),
                Constraint::Percentage(100),
                Constraint::Length(2),
            ])
            .areas(area);

            status_bar(f, status_bar_area, args.status_bar_config.clone())
                .expect("Render status bar");
            generation_list(f, main_area, &closures, &mut list_state);
            footer(f, footer_area);
        })?;

        if let Ok(ev) = rx.recv() {
            match ev {
                InputEvent::Up => {
                    let selected = list_state.selected().unwrap_or(0);
                    if selected > 0 {
                        list_state.select(Some(selected - 1));
                    }
                }
                InputEvent::Down => {
                    let selected = list_state.selected().unwrap_or(0);
                    if selected < closures.len().saturating_sub(1) {
                        list_state.select(Some(selected + 1));
                    }
                }
                InputEvent::Select => {
                    if let Some(idx) = list_state.selected() {
                        break Some(closures[idx].clone());
                    }
                }
            }
        }
    };

    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen)?;

    if let Some(closure) = selected_closure {
        if args.dry_run {
            println!("Dry run: would boot {}", closure.label);
            return Ok(());
        }

        kexec(closure)?;
    }
    Ok(())
}

fn status_bar(f: &mut Frame, area: Rect, status_bar_config: Option<PathBuf>) -> anyhow::Result<()> {
    let default_status_bar_config = json!([
        2,
        {
            "layout": 50.0,
            "item": "time"
        },
        {
            "layout": 50.0,
            "item": "battery"
        },
        2
    ])
    .to_string();
    let status_bar_config = if let Some(status_bar_config) = status_bar_config {
        fs::read_to_string(status_bar_config).unwrap_or(default_status_bar_config)
    } else {
        default_status_bar_config
    };
    let status_bar_config: Vec<Value> =
        serde_json::from_str(&status_bar_config).unwrap_or_default();

    let mut constraints = Vec::new();
    let mut names = Vec::new();

    for v in status_bar_config {
        match v {
            Value::Number(n) => {
                constraints.push(if n.is_u64() {
                    Constraint::Length(n.as_u64().unwrap() as u16)
                } else {
                    Constraint::Percentage(n.as_f64().unwrap() as u16)
                });
                names.push(None);
            }
            Value::Object(obj) => {
                let layout = obj.get("layout");
                if layout.is_some_and(Value::is_u64) {
                    constraints.push(Constraint::Percentage(
                        layout
                            .and_then(Value::as_u64)
                            .expect("Object must have 'layout' field")
                            as u16,
                    ));
                } else {
                    constraints.push(Constraint::Percentage(
                        layout
                            .and_then(Value::as_f64)
                            .expect("Object must have 'layout' field")
                            as u16,
                    ));
                }

                let name = obj
                    .get("item")
                    .and_then(Value::as_str)
                    .map(str::to_owned)
                    .expect("Object must have 'item' field");

                names.push(Some(name));
            }
            _ => return Err(anyhow!("Unexpected JSON value")),
        }
    }

    let rects = Layout::horizontal(constraints).split(area);

    let mut area_map: HashMap<String, Rect> = HashMap::new();
    for (name_opt, rect) in names.into_iter().zip(rects.iter()) {
        if let Some(name) = name_opt {
            area_map.insert(name, *rect);
        }
    }

    let time_area = area_map.get("time").unwrap();
    let battery_area = area_map.get("battery").unwrap();

    let time_str = time::get_time_string();
    let battery_pct = battery::get_battery_percentage();

    f.render_widget(
        Paragraph::new(Line::from(vec![Span::raw("  "), Span::raw(time_str)])),
        *time_area,
    );

    if let Some(pct) = battery_pct {
        let battery_text = format!("Battery: {pct}%");
        f.render_widget(
            Paragraph::new(Line::from(vec![Span::raw(battery_text)])).alignment(Alignment::Right),
            *battery_area,
        );
    }

    Ok(())
}

fn generation_list(
    f: &mut Frame,
    area: Rect,
    closures: &[SystemClosure],
    list_state: &mut ListState,
) {
    let max_item_width = closures.iter().map(|c| c.label.len()).max().unwrap_or(0) as u16;
    let list_width = (max_item_width + 4).min(area.width);

    let num_items = closures.len() as u16;
    let list_height = num_items.min(area.height);

    let vertical_margin = area.height.saturating_sub(list_height + 2) / 2;

    let content_area = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(vertical_margin),
            Constraint::Length(1),
            Constraint::Length(1),
            Constraint::Length(list_height),
            Constraint::Fill(1),
        ])
        .split(area);

    let title = Line::from(vec![Span::styled(
        "Select Generation",
        Style::default().add_modifier(Modifier::BOLD),
    )]);
    f.render_widget(Paragraph::new(title).centered(), content_area[1]);

    let list_area = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Fill(1),
            Constraint::Length(list_width),
            Constraint::Fill(1),
        ])
        .split(content_area[3])[1];

    let items: Vec<ListItem> = closures
        .iter()
        .map(|c| ListItem::new(c.label.clone()))
        .collect();

    let list = List::new(items)
        .highlight_style(
            Style::default()
                .add_modifier(Modifier::REVERSED)
                .add_modifier(Modifier::BOLD),
        )
        .highlight_symbol("> ");

    f.render_stateful_widget(list, list_area, &mut list_state.clone());
}

fn footer(f: &mut Frame, area: Rect) {
    let [navigate_area, select_area] =
        Layout::vertical([Constraint::Length(1), Constraint::Length(1)]).areas(area);

    f.render_widget(
        Paragraph::new(Span::raw("↑/VolUp ↓/VolDown: Navigate")).centered(),
        navigate_area,
    );
    f.render_widget(
        Paragraph::new(Span::raw("Enter/Power: Select")).centered(),
        select_area,
    );
}
