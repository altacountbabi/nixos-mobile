use crate::rootfs;
use anyhow::anyhow;
use glob::glob;
use serde::{Deserialize, Serialize};
use std::{
    fs,
    path::{Path, PathBuf},
};

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

pub fn find_system_closures() -> anyhow::Result<Vec<SystemClosure>> {
    let store_path = rootfs().join("nix/store");
    let profiles_dir = store_path.join("nix/var/nix/profiles");
    let pattern = profiles_dir.join("system-*").display().to_string();
    let entries = glob(&pattern)?;

    let mut closures: Vec<SystemClosure> = entries
        .filter_map(Result::ok)
        .filter_map(|x| read_boot_json(&x.join("boot.json")).ok())
        .collect();

    if closures.is_empty() {
        let pattern = store_path.join("*-nixos-system*").display().to_string();
        let entries = glob(&pattern)?;

        closures = entries
            .filter_map(Result::ok)
            .filter_map(|x| read_boot_json(&x.join("boot.json")).ok())
            .collect();
    }

    if closures.is_empty() {
        return Err(anyhow!("Could not find any system closures in rootfs"));
    }

    Ok(closures)
}
