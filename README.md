# Arch Linux Installation Guide

OS like Arch Linux allow great deal of flexibility and customization.
Installation of such a system can be thought as building of unique system
from scratch. Here I provide instructions how to re-create my own Arch Linux
system (mostly for my later self, but you can use them as well).

1. [Keyboard layout](#keyboard-layout)
2. [Partition](#partition)
3. [Swap](#swap)
4. [File systems](#file-systems)
5. [Mount directories](#mount-directories)
6. [Pacstrap](#pacstrap)
7. [File system table](#file-system-table)
8. [GRUB](#grub)
9. [Play the root Ansible playbook](#playing-the-root-ansible-playbook)
10. [Set passwords](#set-passwords)
11. [Reboot](#reboot)

This text has been placed into public domain by its author, Mark Karpov.

## Keyboard layout

To use Dvorak in the Arch Linux shell, execute:

```
# loadkeys dvorak
```

## Partition

Boot into installation medium, use `lsblk` to see list of available disks
and partitions. Start `fdisk` with desired device (not partition!) as the
first parameter:

```
# fdisk /dev/sdx
```

Generally, you need to create several partitions for your new system:

* Partition of the root directory, i.e. where everything except for users'
  personal data will be stored (type: `83 Linux Filesystem`).

* Partition of the home directory — all users' data will be stored there
  (type: `83 Linux Filesystem`).

* If you have UEFI motherboard, you will need a `EFI Paritition`. You need
  only one such partition for any number of coexisting operating systems. If
  there is already installed Windows system, you do not need to create one,
  just use the existing partition (type: `ef EFI`).

* If you have BIOS motherboard, create a boot partition, `100 Mb` should be
  enough.

* Optionally, you can create a swap partition (type: `82 Linux swap / Solaris`).

Once you have formed a decent partition table, write it out and exit
`fdisk`. You need to remember purpose of every partition because we will use
them for the next steps.

## Swap

In case if you have created a swap partition, it's time to make swap and
turn it on (replace `x` and `Y` to match your swap partition):

```
# mkswap /dev/sdxY
# swapon /dev/sdxY
```

## File systems

Now we need to create file systems for some of our partitions. Creating a
file system will wipe out all files on given partition, so be careful.

Create file systems in partitions for root and home with `mkfs.ext4`:

```
# mkfs.ext4 /dev/sdxY
```

BIOS motherboards' boot needs `ext2` filesystem.

UEFI motherboards should have EFI partition that has FAT32 file system (do
not execute this command if Windows is already installed or else you will
kill it):

```
# mkfs.fat -F32 /dev/sdxY
```

## Mount directories

Now mount directories:

```
# mount /dev/sdxY /mnt # root partition
# mkdir /mnt/{boot,home}
# mount /dev/sdxY /mnt/boot
# mount /dev/sdxY /mnt/home
```

If you have a UEFI motherboard mount filesystem on the EFI partition to
`/mnt/boot`.

## Pacstrap

It's time to use `pacstrap` script that will install basic packages. But
first, you should check you internet connection:

```
# ping 8.8.8.8
```

If there is no internet connection, get it (start `dhcpcd.service`)! Edit
`/etc/pacman.d/mirrorlist` and pull up nearest server. Then refresh package
databases and install basic packages:

```
# pacman -Syy
# pacstrap /mnt base{,-devel}
```

## File system table

```
# genfstab -U -p /mnt > /mnt/etc/fstab
```

Make sure that `/mnt/etc/fstab` contains correct information about mounting
points. If you have something to add to the list of things mounted by
default, here is the template:

```
partition dir filesystem defaults 0 1
```

`defaults 0 1` should be put literally.

## GRUB

I prefer to use GRUB for boot. Let's login into our brand new Arch Linux
system and install it:

```
# arch-chroot /mnt /bin/bash
# pacman -S grub
```

If you have BIOS motherboard, run these commands (`/dev/sdx` is the device
where to search for other OSes):

```
# pacman -S os-prober
# grub-install --target=i386-pc --recheck /dev/sdx
```

If you have UEFI motherboard, run these commands (replace `$esp` with your
actual EFI boot mounted directory such as `/boot`):

```
# pacman -S dosfstools efibootmgr
# grub-install --target=x86_64-efi --efi-directory=$esp --bootloader-id=arch_grub --recheck
```

Generate `grub.cfg`:

```
# grub-mkconfig -o /boot/grub/grub.cfg
```

Edit it as you wish (remove that submenu and set timeout to 0 if you don't
want dual boot machine). If you have BIOS motherboard, GRUB should have
found other operating systems, however if you have UEFI motherboard you need
to manually create record for Windows (if you care at all):

```
if [ "${grub_platform}" == "efi" ]; then
menuentry "Windows Vista/7/8/8.1" {
    insmod part_gpt
    insmod fat
    insmod search_fs_uuid
    insmod chain
    search --fs-uuid --set=root $hints_string $fs_uuid
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
}
fi
```

So, this is menu entry for Windows. Here is how to find out values
of `$hints_strings`:

```
# grub-probe --target=hints_string $esp/EFI/Microsoft/Boot/bootmgfw.efi
```

For `$fs_uuid` use:

```
# grub-probe --target=fs_uuid $esp/EFI/Microsoft/Boot/bootmgfw.efi
```

## Play the root Ansible playbook

Install `git` and `ansible`:

```
# pacman -S git ansible
```

Clone contents of this repo to `/tmp` directory:

```
# git clone https://github.com/mrkkrp/arch-workstation.git /tmp/arch-workstation
```

`cd` into the repo, edit `vars/vars.yml` as needed, and play the root playbook:

```
# cd /tmp/arch-workstation/
# ansible-playbook root-playbook.yml
```

## Set passwords

As a root, set passwords for `root` and the normal user:

```
# passwd
# passwd normal_user_name
```

## Reboot

Now, it's time to reboot:

```
# exit
# umount /mnt/boot
# umount /mnt/home
# umount /mnt
# swapoff /dev/sdxY # use your swap partition, if you've created one
# reboot
```
