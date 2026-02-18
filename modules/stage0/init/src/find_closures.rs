use anyhow::anyhow;
use glob::glob;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone)]
pub struct SystemClosure {
    pub name: String,
    pub kernel: PathBuf,
    pub initrd: PathBuf,
}

pub fn find_system_closures(store_path: &Path) -> anyhow::Result<Vec<SystemClosure>> {
    let profiles_dir = store_path.join("nix/var/nix/profiles");
    let pattern = profiles_dir.join("system-*").display().to_string();
    let entries = glob(&pattern)?;

    let mut closures: Vec<SystemClosure> = entries
        .filter_map(Result::ok)
        .filter_map(closure_from_path)
        .collect();

    if closures.is_empty() {
        let pattern = store_path.join("*-nixos-system*").display().to_string();
        let entries = glob(&pattern)?;

        closures = entries
            .filter_map(Result::ok)
            .filter_map(closure_from_path)
            .collect();
    }

    if closures.is_empty() {
        return Err(anyhow!("Could not find any system closures in rootfs"));
    }

    Ok(closures)
}

fn extract_name(path: &Path) -> String {
    path.file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("unknown")
        .to_string()
        .split_once('-')
        .map(|(_, name)| name.to_owned())
        .unwrap_or_default()
}

fn is_valid_closure(path: &Path) -> bool {
    !path.to_string_lossy().contains(".drv")
}

fn closure_from_path(path: PathBuf) -> Option<SystemClosure> {
    if !is_valid_closure(&path) {
        return None;
    }

    let name = extract_name(&path);
    if name.is_empty() {
        return None;
    }

    Some(SystemClosure {
        name,
        kernel: path.join("kernel"),
        initrd: path.join("initrd"),
    })
}
