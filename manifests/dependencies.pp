class usertomcat::dependencies {

  file { "/usr/local/src/tomcat7-apr.patch":
    source => 'puppet:///modules/usertomcat/tomcat7-apr.patch'
  }

  file { "/usr/local/src/tomcat8-apr.patch":
    source => 'puppet:///modules/usertomcat/tomcat8-apr.patch'
  }

}
