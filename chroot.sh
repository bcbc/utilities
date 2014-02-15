#!/bin/bash
mount=false
unmount=false
version=alpha_0.0.1
usage ()
{
    echo "This thing assumes you've already mounted your root"
    echo "under the /mnt mountpoint. If this is not the case"
    echo "then it won't work. You can mount bind the directories"
    echo "you need with: bash chroot.sh --mount"
    echo "and then chroot with: sudo chroot /mnt"
    echo "then after exiting the chroot you can unmount with:"
    echo "bash chroot.sh --unmount"
    echo "Finally unmount your /mnt manually"
    exit 0
}

for option in "$@"; do
    case "$option" in
    -h | --help)
    usage
    exit 0 ;;
    --version)
    echo "$0: Version $version"
    exit 0 ;;
    --mount)
      mount=true ;;
    --unmount)
      unmount=true ;;
    -*)
    echo "$0: Unrecognized option '$option'. (--help for usage instructions)"
    exit 1
    ;;
    *)
    echo "$0: Unrecognized argument '$option'. (--help for usage instructions)"
    exit 1
    ;;
  esac
done

if [ "$mount" == "true" ] && [ "$unmount" == "true" ]; then
    echo "Error: can't mount and unmount at the same time."
    echo ""
    usage
    exit 1
fi
if [ "$mount" == "false" ] && [ "$unmount" == "false" ]; then
    echo "Error: need to choose either --mount or --unmount"
    echo ""
    usage
    exit 1
fi


if [ "$mount" == "true" ]; then
  for i in dev proc sys dev/pts run; do sudo mount --bind /$i /mnt/$i ; done
fi

if [ "$unmount" == "true" ]; then
  for i in run dev/pts dev proc sys;do sudo umount /mnt/$i; done
fi
