use crate::find_closures::SystemClosure;
use anyhow::Context;
use nix::{
    errno::Errno,
    libc::{SYS_kexec_file_load, syscall},
    sys::reboot::{RebootMode, reboot},
};
use std::{ffi::CString, fs::File, os::fd::AsRawFd};

pub fn kexec(closure: SystemClosure) -> anyhow::Result<()> {
    let kernel = File::open(closure.kernel).context("load kernel")?;
    let initrd = File::open(closure.initrd).context("load initrd")?;
    let cmdline = {
        let mut params = closure.kernel_params.clone();
        params.push(format!("init={}", closure.init.display()));
        let cmdline = params.join(" ");
        CString::new(cmdline)?
    };

    let ret = unsafe {
        syscall(
            SYS_kexec_file_load,
            kernel.as_raw_fd(),
            initrd.as_raw_fd(),
            cmdline.as_bytes_with_nul().len(),
            cmdline.as_ptr(),
            0,
        )
    };

    if ret < 0 {
        return Err(anyhow::Error::from(Errno::last()).context("kexec load kernel"));
    }

    reboot(RebootMode::RB_KEXEC)?;

    Ok(())
}
