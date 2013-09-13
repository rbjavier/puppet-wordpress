# Definition: wordpress_site::wp_app
#
# Installs a wordpress application
#
# Parameters:
# - the $exclude_wp_content option excludes the wp-content directory when extracting the wordpress package
# - the $theme_package is the path to a zip archive of a wordpress theme that will be installed in the wordpress application site
#
# Requires:
# - the wordpress_site class
#
define wordpress_site::wp_app (
  $app_name           = $title,
  $exclude_wp_content = true,
  $theme_package      = undef,
) {
  if ! defined(Class['wordpress_site']) {
    fail('Include the wordpress_site class before using the wordpress_site::wp_app defined resource')
  }

  validate_slength($app_name, 10)
  validate_bool($exclude_wp_content)

  file { "${wordpress_site::wp_dir}/${app_name}":
    ensure => directory,
  }

  if $exclude_wp_content {
    $x_wp_content = 'wp-content'
  }

  exec { "get_${app_name}_wordpress":
    command => "wget -P /tmp http://wordpress.org/latest.tar.gz &&\
               tar xzf /tmp/latest.tar.gz -C /tmp --exclude=${x_wp_content} &&\
               cp -r /tmp/wordpress/* ${wordpress_site::wp_dir}/${app_name}",
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
