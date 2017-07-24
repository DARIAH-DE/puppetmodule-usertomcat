# Create a new user and tomcat-home and add tomcat-user-instance
# uses debian package tomcat7-user
#
# @param gid
#   the group id of new user
#
# @param uid
#   the user id of new user
#
# @param http_port
#   which port should tomcat listen on
#
# @param control_port
#   the tomcat control port
#
# @param jmx_port
#   port for java jmx management, defaults to undef, in which case no jmx port will be openend
#
# @param xmx
#   java max memory allocation (Xmx), default: 128m
#
# @param xms
#   java inital memory allocation (Xms), default: 32m
#
# @param user
#   user which the service belongs to (will be created), defaults to $name if not set
#
# @param group
#   usergroup which the service belongs to (will be created), defaults to $name if not set
#
# @param additional_java_opts
#   additional opts to be passed to tomcat as JAVA_OPTS
#
# @param init_dependencies
#   services which should be started before this tomcat, added as dependency to init.d script, separate with whitespace if more than one
#
# @param collectd_enabled
#   collect stats with collect, needs jmx_port to be set
#
# @param collectd_enabled
#   collect stats with telegraf, installs jolokia.war in webapp dir
#
define usertomcat::instance (
  $http_port,
  $control_port,
  $gid                  = undef,
  $uid                  = undef,
  $jmx_port             = undef,
  $xmx                  = '128m',
  $xms                  = '32m',
  $group                = $name,
  $user                 = $name,
  $tomcat_version       = '7',
  $additional_java_opts = undef,
  $init_dependencies    = undef,
  $collectd_enabled     = false,
  $telegraf_enabled     = false,
) {

  require 'usertomcat::dependencies'

  ensure_packages(["tomcat${tomcat_version}", "tomcat${tomcat_version}-user", 'libtcnative-1'])

  # Check if group and user are already existing.
  # Just in case we have two tomcats using the same user and group
  # (e.g. tgcrud and tgcrud-public or group ULSB is already existing :-)
  if ! defined(Group[$group]) {
    group { $group:
      ensure =>  present,
      gid    =>  $gid,
    }
  }
  if ! defined(User[$user]) {
    user { $user:
      ensure     => present,
      uid        => $uid,
      gid        => $gid,
      shell      => '/bin/bash',
      home       => "/home/${user}",
      managehome => true,
    }
  }

  exec { "create_${name}":
    path    => ['/usr/bin','/bin','/usr/sbin'],
    command => "tomcat${tomcat_version}-instance-create -p ${http_port} -c ${control_port} /home/${user}/${name}",
    creates => "/home/${user}/${name}",
    user    => $user,
    require => Package["tomcat${tomcat_version}-user"],
  }
  ~>
  exec { "patching_${name}_for_apr":
    path        => ['/usr/bin','/bin','/usr/sbin'],
    command     => "patch /home/${user}/${name}/conf/server.xml < /usr/local/src/tomcat${tomcat_version}-apr.patch",
    refreshonly => true,
    require     => File["/usr/local/src/tomcat${tomcat_version}-apr.patch"],
  }

  file { "/etc/init.d/${name}":
    ensure  => file,
    content => template("usertomcat/etc/init.d/tomcat${tomcat_version}.Debian.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    before  => Service[$name],
    notify  => Service[$name],
  }

  file { "/etc/default/${name}":
    ensure  => file,
    content => template("usertomcat/etc/default/tomcat${tomcat_version}.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    before  => Service[$name],
    notify  => Service[$name],
  }

  file {"/var/log/${name}":
    ensure => link,
    target => "/home/${user}/${name}/logs",
  }

  service { $name:
    ensure  => running,
    enable  => true,
    require => Exec["create_${name}"],
  }

  logrotate::rule { $name:
    path         => "/home/${user}/${name}/logs/catalina.out",
    require      => Exec["create_${name}"],
    rotate       => 365,
    rotate_every => 'week',
    compress     => true,
    copytruncate => true,
    missingok    => true,
    ifempty      => true,
    dateext      => true,
    dateformat   => '.%Y-%m-%d',
  }

  if $collectd_enabled {
    collectd::plugin::genericjmx::connection { $name:
      host            => $facts['networking']['fqdn'],
      service_url     => "service:jmx:rmi:///jndi/rmi://localhost:${jmx_port}/jmxrmi",
      collect         => [ 'memory-heap', 'memory-nonheap', 'process_cpu_load' ],
      instance_prefix => "${name}-",
    }
  }

  if $telegraf_enabled {

    require 'usertomcat::jolokia'

    file { "/home/${user}/${name}/webapps/jolokia.war":
      source => '/var/cache/jolokia.war',
    }

    telegraf::input { "jolokia_${name}_mem":
      plugin_type => 'jolokia',
      options     => {
        'context' => '/jolokia/',
      },
      sections    => {
        'jolokia.servers' => {
          'name'   => $name,
          'host' => '127.0.0.1',
          'port' => $http_port,
        },
        'jolokia.metrics' => {
          'name' => 'heap_memory_usage',
          'mbean' => 'java.lang:type=Memory',
          'attribute' => 'HeapMemoryUsage',
        },
      },
    }

    telegraf::input { "jolokia_${name}_cpu":
      plugin_type => 'jolokia',
      options     => {
        'context' => '/jolokia/',
      },
      sections    => {
        'jolokia.servers' => {
          'name'   => $name,
          'host' => '127.0.0.1',
          'port' => $http_port,
        },
        'jolokia.metrics' => {
          'name' => 'process_cpu_load',
          'mbean' => 'java.lang:type=OperatingSystem',
          'attribute' => 'ProcessCpuLoad',
        },
      },
    }

  }

}
