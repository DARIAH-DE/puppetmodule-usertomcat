class usertomcat::jolokia {

    staging::file { 'jolokia.war':
      source  => "https://repo1.maven.org/maven2/org/jolokia/jolokia-war/1.3.7/jolokia-war-1.3.7.war",
      target  => "/var/cache/jolokia.war",
    }

}
