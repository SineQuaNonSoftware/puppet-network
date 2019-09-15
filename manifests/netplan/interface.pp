# Define network::netplan::interface
#
# Define to manage an interface via netplan
#
define network::netplan::interface (
  Enum['present','absent'] $ensure = 'present',

  String $interface_name    = $title,
  String $config_file_name  = "50-${title}.yaml",
  String $interface_type    = 'ethernet',
  Hash   $interface_options = {},

  Stdlib::Absolutepath $config_dir_path = '/etc/netplan',
  Optional[String]$reload_command  = undef,

  String $renderer = 'networkd',
  Numeric $version = 2,

  Boolean $dhcp4        = false,
  Boolean $dhcp6        = false,

  Optional[Stdlib::MAC]             $macaddress = getvar("networking.interfaces.${interface_name}.mac"),
  Variant[Undef,Network::NetplanAddresses] $addresses  = undef,
  Variant[Undef,Array]              $routes     = undef,
  Optional[Stdlib::IP::Address::V4] $gateway4   = undef,
  Optional[Stdlib::IP::Address::V6] $gateway6   = undef,
  Optional[Array]        $nameservers_addresses = undef,
  Optional[Array]           $nameservers_search = undef,

  Optional[String] $file_content                = undef,
  Optional[String] $file_source                 = undef,

) {

  # Define how to restart network service
  $network_notify = pick_default($reload_command, $::network::manage_config_file_notify)

  $match_values = $macaddress ? {
    undef   => {},
    default => {
      match   => {
        macaddress => $macaddress,
      }
    }
  }

  if $nameservers_addresses or $nameservers_search {
    $nameservers_values = {
      addresses => $nameservers_addresses,
      search    => $nameservers_search,
    }
  } else {
    $nameservers_values = {}
  }
  $default_values = {
    dhcp4     => $dhcp4,
    dhcp6     => $dhcp6,
    addresses => $addresses,
    gateway4  => $gateway4,
    gateway6  => $gateway6,
    routes    => $routes,
  }

  $netplan_data = {
    'network' => {
      'version'            => $version,
      "${interface_type}s" => {
        $interface_name => delete_undef_values($default_values + $match_values + $nameservers_values + $interface_options),
      }
    }
  }

  $real_file_content = $file_source ? {
    undef   => pick($file_content,to_yaml($netplan_data)),
    default => undef,
  }
  file { "${config_dir_path}/${config_file_name}":
    ensure  => $ensure,
    content => $real_file_content,
    source  => $file_source,
    notify  => $network_notify,
  }

}
