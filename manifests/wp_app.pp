define wordpress_site::wp_app (
  $app_name      = $title,
  $theme_package = undef,
) {
  if ! defined(Class['wordpress_site']) {
    fail('Include the wordpress_site class before using the wordpress_site::wp_app defined resource')
  }

  validate_slength($app_name, 15)

  file { "${wordpress_site::wp_dir}/${app_name}":
    ensure => directory,
  }

  exec { "get_${app_name}_wordpress":
    command => "wget -P /tmp http://wordpress.org/latest.tar.gz && tar xzf /tmp/latest.tar.gz -C /tmp && cp -r /tmp/wordpress/* ${wordpress_site::wp_dir}/${app_name}",
    path    => ['/bin', '/usr/bin'],
    creates => "${wordpress_site::wp_dir}/${app_name}/index.php",
    require => File["${wordpress_site::wp_dir}/${app_name}"],
  }

  $themes_dir = "${wordpress_site::wp_dir}/${app_name}/wp-content/themes"

  if $theme_package {
    validate_absolute_path($theme_package)

    exec { "extract_${app_name}_theme_package":
      command => "unzip ${theme_package} -d ${themes_dir}",
      path    => ['/bin', '/usr/bin'],
      creates => "${themes_dir}/${app_name}/index.php",
      require => [
        Exec["get_${app_name}_wordpress"],
        Package['unzip'],
      ]
    }
  }

  $dbname     = $app_name
  $dbuser     = "${app_name}"
  $dbpassword = "${app_name}_jXja7njs3Y"
  $dbhost     = 'localhost'

  mysql::db { $dbname:
    user     => $dbuser,
    password => $dbpassword,
    host     => $dbhost,
    grant    => ['all'],
  }

  file { "${wordpress_site::wp_dir}/${app_name}/wp-config.php":
    ensure  => present,
    content => template('wordpress_site/wp-config.php.erb'),
    require => Exec["get_${app_name}_wordpress"],
  }
}
