use crate::find_systems::SystemClosure;
use anyhow::Context;
use std::process::Command;

pub fn kexec(closure: SystemClosure) -> anyhow::Result<()> {
    let mut cmd = Command::new("kexec");

    // Build the complete command line
    let mut cmdline_parts = closure.kernel_params.clone();
    cmdline_parts.push(format!("init={}", closure.init.display()));
    let cmdline = cmdline_parts.join(" ");

    // Add kernel with all parameters
    cmd.arg("-l")
        .arg(&closure.kernel)
        .arg("--initrd")
        .arg(&closure.initrd)
        .arg("--command-line")
        .arg(cmdline);

    let output = cmd.output().context("failed to execute kexec-tools")?;

    if !output.status.success() {
        return Err(anyhow::anyhow!(
            "kexec-tools load failed: {}",
            String::from_utf8_lossy(&output.stderr)
        ));
    }

    // Execute the loaded kernel
    Command::new("kexec")
        .arg("-e")
        .output()
        .context("failed to execute kexec -e")?;

    Ok(())
}
