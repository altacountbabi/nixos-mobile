use anyhow::anyhow;
use glob::glob;
use std::{
    collections::HashSet,
    path::{Path, PathBuf},
};

#[derive(Debug, Clone)]
pub struct SystemClosure {
    pub name: String,
    pub index: usize,
    pub kernel: PathBuf,
    pub initrd: PathBuf,
}

pub fn find_system_closures(store_path: &Path) -> anyhow::Result<Vec<SystemClosure>> {
    let profiles_dir = store_path.join("nix/var/profiles");
    let pattern = profiles_dir.join("system-*").display().to_string();
    let entries = glob(&pattern)?;

    let mut closures = Vec::new();
    let mut seen_paths = HashSet::new();

    for entry in entries {
        let path = entry?;
        seen_paths.insert(path.clone());
        let name = path
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("unknown")
            .to_string();
        let kernel = path.join("kernel");
        let initrd = path.join("initrd");

        closures.push(SystemClosure {
            name,
            index: closures.len(),
            kernel,
            initrd,
        });
    }

    // Search the nix store if profiles aren't set up yet (usually the case for first boot)
    let pattern = store_path.join("*-nixos-system*").display().to_string();
    let entries = glob(&pattern)?;

    for entry in entries {
        let path = entry?;
        if !seen_paths.contains(&path) {
            let name = path
                .file_name()
                .and_then(|n| n.to_str())
                .unwrap_or("unknown")
                .to_string()
                .split_once('-')
                .unwrap()
                .1
                .to_owned();

            closures.push(SystemClosure {
                name,
                index: closures.len(),
                kernel: path.join("kernel"),
                initrd: path.join("initrd"),
            });
        }
    }

    if closures.is_empty() {
        return Err(anyhow!("Could not find any system closures in rootfs"));
    }

    Ok(closures)
}
