# Configure TFTP
# @api private
class tftp::config {
  if $tftp::manage_root_dir {
    ensure_resource('file', $tftp::root, { 'ensure' => 'directory' })
  }

  case $facts['os']['family'] {
    'FreeBSD', 'DragonFly': {
      augeas { 'set root directory':
        context => '/files/etc/rc.conf',
        changes => "set tftpd_flags '\"-s ${tftp::root}\"'",
      }
    }
    'Debian': {
      file { '/etc/default/tftpd-hpa':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('tftp/tftpd-hpa.erb'),
      }
    }
    'Archlinux': {
      systemd::dropin_file { 'tftpd-socket-override.conf':
        unit    => 'tftpd.socket',
        content => epp('tftp/tftp.socket-override.epp'),
      }
      systemd::dropin_file { 'tftpd-service-override.conf':
        unit    => 'tftpd.service',
        content => epp('tftp/tftp.service-override-arch.epp'),
        require => Systemd::Dropin_file['tftpd-socket-override.conf'],
      }
    }
    'RedHat': {
      systemd::dropin_file { 'tftp-socket-override.conf':
        unit    => 'tftp.socket',
        content => epp('tftp/tftp.socket-override.epp'),
      }
      systemd::dropin_file { 'tftp-service-override.conf':
        unit    => 'tftp.service',
        content => epp('tftp/tftp.service-override-el.epp'),
        require => Systemd::Dropin_file['tftp-socket-override.conf'],
      }
    }
    default: {
      notify { "Unsupported platform: ${facts['os']['family']}, the tftp service will run with with default parameters": }
    }
  }
}
