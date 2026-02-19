#![allow(
    clippy::cast_possible_truncation,
    clippy::cast_sign_loss,
    clippy::too_many_lines,
    clippy::needless_pass_by_value,
    clippy::similar_names
)]

use crate::find_closures::find_system_closures;
use clap::Parser;
use std::{path::PathBuf, sync::OnceLock};

mod find_closures;
mod kexec;
mod ui;

static ROOTFS: OnceLock<PathBuf> = OnceLock::new();

fn rootfs() -> PathBuf {
    ROOTFS.get().unwrap().clone()
}

#[derive(Parser)]
#[command(version, about, long_about = None)]
struct Args {
    #[arg(long)]
    status_bar_config: Option<PathBuf>,

    #[arg(long)]
    dry_run: bool,
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();

    ROOTFS.get_or_init(|| PathBuf::from(if args.dry_run { "/" } else { "/sysroot" }));

    let closures = find_system_closures()?;

    ui::run(closures, args)?;

    Ok(())
}
