use crate::find_closures::find_system_closures;
use std::{
    path::PathBuf,
    process::{Command, ExitStatus},
};

mod find_closures;
mod ui;

fn main() -> anyhow::Result<()> {
    let rootfs = PathBuf::from("/sysroot");

    let closures = find_system_closures(&rootfs.join("nix/store"))?;

    ui::run(closures)?;

    Ok(())
}

fn cmd<'a>(name: &str, args: impl IntoIterator<Item = &'a str>) -> anyhow::Result<ExitStatus> {
    Ok(Command::new(name).args(args).spawn()?.wait()?)
}
