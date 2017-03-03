# usertomcat

## Description

A module for debian based systems which offer the command tomcatX-instance-create provided by the package tomcatX-user, where the X should stand for version [7](https://manpages.debian.org/jessie/tomcat7-user/tomcat7-instance-create.2.en.html) or [8](https://manpages.debian.org/jessie/tomcat8-user/tomcat8-instance-create.2.en.html). 

The goal is to install and run different tomcat containers on the same server with the persmissons of different users. This allows better separation of the web applications running on tomcat like differentiated resource control and access management as well as independent operation of the webapps in case of failures. By using the tomcat packaged provided by debian the it is possible to benefit from security updates provided by the package maintainers.

## Usage

```puppet
usertomcat::instance { 'tomcat-jenkins':
  http_port         => '9090',
  control_port      => '9005',
}
```

This would install the packages tomcat7 and tomcat7-user and libtcnative-1. It create a user and a group named "tomcat-jenkins" on the system. The usertomcat directory would be in the /home/tomcat-jenkins/tomcat-jenkins/, where the webapps dir the logs dir etc reside. A symlink to the logs dir is created in /var/logs/tomcat-jenkins. The tomcat will have the APR based native library enabled ([docs](http://tomcat.apache.org/tomcat-8.0-doc/apr.html)).


## Documentation
User and group name and id, tomcat version, jmx port etc. could be configured.
Have a look at the file [instance.pp](manifests/instance.pp) for all configuration options.

The full documentation is available from [GitHub Pages](https://dariah-de.github.io/puppetmodule-usertomcat/).


