use crate::rootfs;
use anyhow::anyhow;
use glob::{PatternError, glob};
use serde::{Deserialize, Serialize};
use std::{
    fs,
    path::{Path, PathBuf},
};
use tap::Tap;

#[derive(Debug, Clone)]
pub struct SystemClosure {
    pub label: String,
    pub kernel: PathBuf,
    pub initrd: PathBuf,
    pub kernel_params: Vec<String>,
    pub init: PathBuf,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BootSpec {
    #[serde(rename = "org.nixos.bootspec.v1")]
    pub bootspec: Option<BootSpecV1>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BootSpecV1 {
    pub init: PathBuf,
    pub initrd: PathBuf,
    pub kernel: PathBuf,
    #[serde(rename = "kernelParams", default)]
    pub kernel_params: Vec<String>,
    pub label: String,
    pub system: String,
    pub toplevel: PathBuf,
}

pub fn read_boot_json(path: &Path) -> anyhow::Result<SystemClosure> {
    let content = fs::read_to_string(path).map_err(|e| anyhow!("Failed to read boot.json: {e}"))?;

    let boot_spec: BootSpec =
        serde_json::from_str(&content).map_err(|e| anyhow!("Failed to parse boot.json: {e}"))?;

    let bootspec = boot_spec
        .bootspec
        .ok_or(anyhow!("Missing org.nixos.bootspec.v1 in boot.json"))?;

    let rootfs = rootfs();
    let rootfs_prefix = |x: PathBuf| -> PathBuf { rootfs.join(x.strip_prefix("/").unwrap()) };

    Ok(SystemClosure {
        label: bootspec.label,
        kernel: rootfs_prefix(bootspec.kernel),
        initrd: rootfs_prefix(bootspec.initrd),
        kernel_params: bootspec.kernel_params,
        init: bootspec.init,
    })
}

pub fn find_systems() -> anyhow::Result<Vec<SystemClosure>> {
    let store_path = rootfs().join("nix/store");
    let profiles_dir = rootfs().join("nix/var/nix/profiles");

    let has_profiles = {
        let paths = glob_path(profiles_dir.join("system*"));
        match paths {
            Ok(v) => !v.is_empty(),
            Err(_) => false,
        }
    };

    let systems: Vec<SystemClosure> = if has_profiles {
        let system = fs::read_link(profiles_dir.join("system"))?;
        let other_systems = glob_path(profiles_dir.join("system-*"))?.tap_mut(|systems| {
            systems.sort_by(|a, b| {
                let get_index = |x: &PathBuf| -> usize {
                    x.file_name()
                        .unwrap()
                        .display()
                        .to_string()
                        .split('-')
                        .next_back()
                        .expect("Parse system profile index")
                        .parse()
                        .expect("Parse system profile index")
                };

                get_index(a).cmp(&get_index(b))
            });
        });

        vec![system]
            .tap_mut(|systems| systems.extend(other_systems))
            .into_iter()
            .filter_map(|x| read_boot_json(&x.join("boot.json")).ok())
            .filter(|x| !x.label.contains("stage0"))
            .collect()
    } else {
        let paths = glob_path(store_path.join("*-nixos-system*"))?;

        paths
            .into_iter()
            .filter_map(|x| read_boot_json(&x.join("boot.json")).ok())
            .collect()
    };

    if systems.is_empty() {
        return Err(anyhow!("Could not find any system closures in rootfs"));
    }

    // Filter out stage0 specialisation
    let systems = systems
        .into_iter()
        .filter(|x| !x.label.contains("stage0"))
        .collect();

    Ok(systems)
}

fn glob_path(path: PathBuf) -> Result<Vec<PathBuf>, PatternError> {
    Ok(glob(&path.display().to_string())
        .map(|x| x.filter_map(Result::ok))?
        .collect())
}
