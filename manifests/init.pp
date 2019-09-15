# This class manages networking on different Operating systems
# It provives entry points to define, via Hiera data, hashes of
# interfaces, routes, rules and tables.
# The version 4 of this module also introduces backward incompatible
# defines to manage such objects, but allows to use previous style
# syntax by setting to true the telegant legacy params.
# With default settings with class does not manage any resource.

# @summary Data entrypoint for different network related defines
#
# @param hostname If set the network::hostname class is included and the
#   system's hostname configured
#
# @param host_conf_template The .epp or .erb template to use as content
#   of the /etc/host.conf file. If undef (as default) the file is not managed.
# @param host_conf_options A custom hash of options to use inside the
#   host_conf_template to parametrise values to interpolate.
#   In a .epp template refer to them with <%= $options['key'] %>
#   In a .erb template refer to them with <%= @host_conf_options['key'] %>
#
# @param nsswitch_conf_template The .epp or .erb template to use as content
#   of the /etc/nsswitch file. If undef (as default) the file is not managed.
# @param nsswitch_conf_options A custom hash of options to use inside the
#   nsswitch_conf_template to parametrise values to interpolate.
#   In a .epp template refer to them with <%= $options['key'] %>
#   In a .erb template refer to them with <%= @nsswitch_conf_options['key'] %>
#
# @param interfaces_hash An hash of interfaces to configure.
#   This is not actually a class parameter, but a key looked up using the
#   merge behaviour configured via $interfaces_merge_behaviour.
#   If $interfaces_legacy is false (default) the define network::interface
#   is declared for each element of this hash.
#   If $interfaces_legacy is true then the hash values are iterated over
#   the define network::legacy::interface
# @param interfaces_legacy Allows usage backwards compatible hiera data by
#   using the network::legacy::interface define which is a copy of the
#   network::interface define on version 3 of this module
# @param interfaces_merge_behaviour Defines the lookup method to use to
#   retrieve via hiera the $interfaces_hash
# @param interfaces_defaults An hash of default settings to merge with
#   the settings of each element of the $interfaces_hash
#   Useful to consolidate duplicated data in Hiera.
#
# @param routes_hash An hash of routes to configure.
#   This is not actually a class parameter, but a key looked up using the
#   merge behaviour configured via $routes_merge_behaviour.
#   If $routes_legacy is false (default) the define network::route
#   is declared for each element of this hash.
#   If $routes_legacy is true then the hash values are iterated over
#   the define network::legacy::route
# @param routes_legacy Allows usage backwards compatible hiera data by
#   using the network::legacy::route define which is a copy of the
#   network::route define on version 3 of this module
# @param routes_merge_behaviour Defines the lookup method to use to
#   retrieve via hiera the $routes_hash
# @param routes_defaults An hash of default settings to merge with
#   the settings of each element of the $routes_hash
# 
# @param rules_hash An hash of rules to configure.
#   This is not actually a class parameter, but a key looked up using the
#   merge behaviour configured via $rules_merge_behaviour.
#   If $rules_legacy is false (default) the define network::rule
#   is declared for each element of this hash.
#   If $rules_legacy is true then the hash values are iterated over
#   the define network::legacy::rule
# @param rules_legacy Allows usage backwards compatible hiera data by
#   using the network::legacy::rule define which is a copy of the
#   network::rule define on version 3 of this module
# @param rules_merge_behaviour Defines the lookup method to use to
#   retrieve via hiera the $rules_hash
# @param rules_defaults An hash of default settings to merge with
#   the settings of each element of the $rules_hash
# 
# @param tables_hash An hash of tables to configure.
#   This is not actually a class parameter, but a key looked up using the
#   merge behaviour configured via $tables_merge_behaviour.
#   If $tables_legacy is false (default) the define network::table
#   is declared for each element of this hash.
#   If $tables_legacy is true then the hash values are iterated over
#   the define network::legacy::table
# @param tables_legacy Allows usage backwards compatible hiera data by
#   using the network::legacy::table define which is a copy of the
#   network::table define on version 3 of this module
# @param tables_merge_behaviour Defines the lookup method to use to
#   retrieve via hiera the $tables_hash
# @param tables_defaults An hash of default settings to merge with
#   the settings of each element of the $tables_hash
# 
# @param service_restart_exec The command to use to restart network
#   service when configuration changes occurs. Used with the default
#   setting for $config_file_notify
# @param config_file_notify The Resource to trigger when a configuration
#   change occurs. Default is Exec[$service_restart_exec], set to undef
#   or false or an empty string to not add any notify param on
#   config files resources (so no network change is automatically applied)
#   Note that if you configure a custom resource reference you must provide it
#   in your own profiles.
# @param config_file_per_interface If to configure interfaces in a single file
#   or having a single configuration file for each interface.
#   Default is true whenever a single file per interface is supported.
#
class network (
  Optional[String] $hostname = undef,

  Optional[String]                    $host_conf_template = undef,
  Hash                                $host_conf_options  = {},

  Optional[String]                $nsswitch_conf_template = undef,
  Hash                            $nsswitch_conf_options  = {},

  Boolean $use_netplan                                    = false,
  # This "param" is looked up in code according to interfaces_merge_behaviour
  # Optional[Hash]              $interfaces_hash            = undef,
  Boolean                     $interfaces_legacy          = false,
  Enum['first','hash','deep'] $interfaces_merge_behaviour = 'first',
  Hash                        $interfaces_defaults        = {},

  # This "param" is looked up in code according to routes_merge_behaviour
  # Optional[Hash]              $routes_hash                = undef,
  Boolean                     $routes_legacy              = false,
  Enum['first','hash','deep'] $routes_merge_behaviour     = 'first',
  Hash                        $routes_defaults            = {},

  # This "param" is looked up in code according to rules_merge_behaviour
  # Optional[Hash]              $rules_hash                 = undef,
  Boolean                     $rules_legacy               = false,
  Enum['first','hash','deep'] $rules_merge_behaviour      = 'first',
  Hash                        $rules_defaults             = {},

  # This "param" is looked up in code according to tables_merge_behaviour
  # Optional[Hash]              $tables_hash                = undef,
  Boolean                     $tables_legacy          = false,
  Enum['first','hash','deep'] $tables_merge_behaviour = 'first',
  Hash                        $tables_defaults        = {},

  String $service_restart_exec                         = 'service network restart',
  Variant[Resource,String[0,0],Undef,Boolean] $config_file_notify  = true,
  Boolean $config_file_per_interface                   = true,
) {

  $manage_config_file_notify = $config_file_notify ? {
    true            => "Exec[${service_restart_exec}]",
    false           => undef,
    ''              => undef,
    undef           => undef,
    default         => $config_file_notify,
  }

  # Exec to restart interfaces
  exec { $service_restart_exec :
    command     => $service_restart_exec,
    alias       => 'network_restart',
    refreshonly => true,
    path        => $::path,
  }

  if $hostname {
    contain '::network::hostname'
  }

  # Manage /etc/host.conf if $host_conf_template is set
  if $host_conf_template {
    $host_conf_template_type=$host_conf_template[-4,4]
    $host_conf_content = $host_conf_template_type ? {
      '.epp'  => epp($host_conf_template,{ options => $host_conf_options }),
      '.erb'  => template($host_conf_template),
      default => template($host_conf_template),
    }
    file { '/etc/host.conf':
      ensure => present,
      content => $host_conf_content,
      notify  => $manage_config_file_notify,
    }
  }

  # Manage /etc/nsswitch.conf if $nsswitch_conf_template is set
  if $nsswitch_conf_template {
    $nsswitch_conf_template_type=$nsswitch_conf_template[-4,4]
    $nsswitch_conf_content = $nsswitch_conf_template_type ? {
      '.epp'  => epp($nsswitch_conf_template,{ options => $nsswitch_conf_options}),
      '.erb'  => template($nsswitch_conf_template),
      default => template($nsswitch_conf_template),
    }
    file { '/etc/nsswitch.conf':
      ensure => present,
      content => $nsswitch_conf_content,
      notify  => $manage_config_file_notify,
    }
  }

  # Declare network interfaces based on network::interfaces_hash
  $interfaces_hash = lookup('network::interfaces_hash',Hash,$interfaces_merge_behaviour,{})
  $interfaces_hash.each |$k,$v| {
    if $interfaces_legacy {
      network::legacy::interface { $k:
        * => $interfaces_defaults + $v,
      }
    } else {
      network::interface { $k:
        * => $interfaces_defaults + $v,
      }
    }
  }

  # Declare network routes based on network::routes_hash
  $routes_hash = lookup('network::routes_hash',Hash,$routes_merge_behaviour,{})
  $routes_hash.each |$k,$v| {
    if $routes_legacy {
      network::legacy::route { $k:
        * => $routes_defaults + $v,
      }
    } else {
      network::route { $k:
        * => $routes_defaults + $v,
      }
    }
  }

  # Declare network rules based on network::rules_hash
  $rules_hash = lookup('network::rules_hash',Hash,$rules_merge_behaviour,{})
  $rules_hash.each |$k,$v| {
    if $rules_legacy {
      network::legacy::rule { $k:
        * => $rules_defaults + $v,
      }
    } else {
      network::rule { $k:
        * => $rules_defaults + $v,
      }
    }
  }

  # Declare network tables based on network::tables_hash
  $tables_hash = lookup('network::tables_hash',Hash,$tables_merge_behaviour,{})
  $tables_hash.each |$k,$v| {
    if $tables_legacy {
      network::legacy::routing_table { $k:
        * => $tables_defaults + $v,
      }
    } else {
      network::table { $k:
        * => $tables_defaults + $v,
      }
    }
  }

}
