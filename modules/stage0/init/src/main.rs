#![allow(
    clippy::cast_possible_truncation,
    clippy::cast_sign_loss,
    clippy::too_many_lines,
    clippy::needless_pass_by_value
)]

use crate::find_closures::find_system_closures;
use clap::Parser;
use std::path::PathBuf;

mod find_closures;
mod ui;

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
    let rootfs = PathBuf::from(if args.dry_run { "/" } else { "/sysroot" });

    let closures = find_system_closures(&rootfs.join("nix/store"))?;

    ui::run(closures, args)?;

    Ok(())
}

fn cmd(cmd: &str) -> anyhow::Result<std::process::ExitStatus> {
    Ok(std::process::Command::new("sh")
        .args(["-c", cmd])
        .spawn()?
        .wait()?)
}
