# Append "$1" to $PATH when not already in.
# Copied from Arch Linux, see #12803 for details.
append_path () {
	case ":$PATH:" in
		*:"$1":*)
			;;
		*)
			PATH="${PATH:+$PATH:}$1"
			;;
	esac
}

append_path "/usr/local/sbin"
append_path "/usr/local/bin"
append_path "/usr/sbin"
append_path "/usr/bin"
append_path "/sbin"
append_path "/bin"
unset -f append_path

export PATH
export PAGER=less
umask 022

PS1='\h:\w\$ '
export PS1

for script in /etc/profile.d/*.sh ; do
	if [ -r "$script" ] ; then
		. "$script"
	fi
done
unset script
