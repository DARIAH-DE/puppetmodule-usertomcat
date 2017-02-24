# == Define: usertomcat::create
#
# Create a new user and tomcat-home and add tomcat-user-instance
# uses debian package tomcat7-user
#
# === Parameters
#
# [*gid*]
#   the group id of new user
#
# [*uid*]
#   the user id of new user
#
# [*http_port*]
#   which port should tomcat listen on
#
# [*control_port*]
#   the tomcat control port
#
# [*jmx_port*]
#   port for java jmx management, defaults to undef, in which case no jmx port will be openend
#
# [*xmx*]
#   java max memory allocation (Xmx), default: 128m
#
# [*xms*]
#   java inital memory allocation (Xms), default: 32m
#
# [*user*]
#   user which the service belongs to (will be created), defaults to $name if not set 
#
# [*group*]
#   usergroup which the service belongs to (will be created), defaults to $name if not set 
#
# [*additional_java_opts*]
#   additional opts to be passed to tomcat as JAVA_OPTS
#
# [*init_dependencies*]
#   services which should be started before this tomcat, added as dependency to init.d script, separate with whitespace if more than one
# [*collectd_enabled*]
#   collect stats with collect, needs jmx_port to be set
#
# TODO:
#   install libapr1 and integrate with tomcat-conf
#      in conf/server.conf
#   <!--APR library loader. Documentation at /docs/apr.html -->
#   <Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on" />
#
define usertomcat::create (
  $gid,
  $uid,
  $http_port,
  $control_port,
  $jmx_port             = undef,
  $xmx                  = '128m',
  $xms                  = '32m',
  $group                = $name,
  $user                 = $name,
  $tomcat_version       = '7',
  $additional_java_opts = undef,
  $init_dependencies    = '',
  $collectd_enabled     = false,
) {

  require 'usertomcat::dependencies'

  ensure_packages(["tomcat${tomcat_version}", "tomcat${tomcat_version}-user", "libtcnative-1"])

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
    ensure  => present,
    content => template("usertomcat/etc/init.d/tomcat${tomcat_version}.Debian.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    before  => Service[$name],
    notify  => Service[$name],
  }

  file { "/etc/default/${name}":
    ensure  => present,
    content => template("usertomcat/etc/default/tomcat${tomcat_version}.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    before  => Service[$name],
    notify  => Service[$name],
  }

  file {"/var/log/${name}":
    ensure  => link,
    target  => "/home/${user}/${name}/logs",
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
    dateformat   => '.%Y-%m-%d'
  }

  if $collectd_enabled {
    collectd::plugin::genericjmx::connection { $name:
        host            => $fqdn,
        service_url     => "service:jmx:rmi:///jndi/rmi://localhost:${jmx_port}/jmxrmi",
        collect         => [ 'memory-heap', 'memory-nonheap', 'process_cpu_load' ],
        instance_prefix => "${name}-",
    }
  }

}
