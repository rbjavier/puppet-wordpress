# Definition: wordpress_site::warp_theme
#
# Installs a vagrant development wordpress site for a theme developed with Yootheme's warp
#
# Parameters:
# - the $parent_dir vagrant shared directory containing all the files of the theme (including the demo files and plugins)
# - the $widgetkit option installs the widgetkit plugin from the theme's wp_plugins directory
#
# Requires:
# - the wordpress_site class
#
define wordpress_site::warp_theme (
  $theme_name = $title,
  $parent_dir = '/vagrant',
  $widgetkit  = false,
) {
  if ! defined(Class['wordpress_site']) {
    fail('Include the wordpress_site class before using the wordpress_site::warp_theme defined resource')
  }

  validate_slength($theme_name, 10)
  validate_absolute_path($parent_dir)
  validate_bool($widgetkit)

  file { "${wordpress_site::wp_dir}/${theme_name}":
    ensure => directory,
  }

  exec { "get_${theme_name}_wordpress":
    command => "wget -P /tmp http://wordpress.org/latest.tar.gz && tar xzf /tmp/latest.tar.gz -C /tmp && cp -r /tmp/wordpress/* ${wordpress_site::wp_dir}/${theme_name}",
    path    => ['/bin', '/usr/bin'],
    creates => "${wordpress_site::wp_dir}/${theme_name}/index.php",
    require => File["${wordpress_site::wp_dir}/${theme_name}"],
  }

  file { "${wordpress_site::wp_dir}/${theme_name}/wp-content/uploads":
    ensure  => link,
    target  => "${parent_dir}/${theme_name}/uploads",
    require => Exec["get_${theme_name}_wordpress"],
  }

  file { "${wordpress_site::wp_dir}/${theme_name}/wp-content/install.php":
    ensure  => link,
    target  => "${parent_dir}/${theme_name}/install.php",
    require => Exec["get_${theme_name}_wordpress"],
  }

  $dbname     = $theme_name
  $dbuser     = "${theme_name}_user"
  $dbpassword = "${theme_name}_jXja7njs3Y"
  $dbhost     = 'localhost'

  mysql::db { $dbname:
    user     => $dbuser,
    password => $dbpassword,
    host     => $dbhost,
    grant    => ['all'],
  }

  file { "${wordpress_site::wp_dir}/${theme_name}/wp-config.php":
    ensure  => present,
    content => template('wordpress_site/wp-config.php.erb'),
    require => Exec["get_${theme_name}_wordpress"],
  }

  file { "${theme_name}_plugins":
    path   => "${wordpress_site::plugins_path}/${theme_name}",
    ensure => directory,
  }

  if $widgetkit {
    $widgetkit_pack = "${wordpress_site::plugins_path}/${theme_name}/widgetkit.zip"

    file { $widgetkit_pack:
      ensure  => present,
      source  => "${parent_dir}/${theme_name}/wp_plugins/widgetkit.zip",
      require => File["${theme_name}_plugins"],
    }

    $widgetkit_dir = "${wordpress_site::wp_dir}/${theme_name}/wp-content/plugins/widgetkit"

    file { $widgetkit_dir:
      ensure  => directory,
      require => Exec["get_${theme_name}_wordpress"],
    }

    exec { "extract_${theme_name}_widgetkit":
      command => "unzip ${widgetkit_pack} -d ${$widgetkit_dir}",
      path    => ['/bin', '/usr/bin'],
      creates => "${widgetkit_dir}/widgetkit.php",
      require => [
                  File[$widgetkit_dir],
                  File[$widgetkit_pack],
                  Package['unzip'],
                  ],
      notify  => File["${widgetkit_dir}/cache"],
    }

    file { "${widgetkit_dir}/cache":
      mode    => 757,
      require => Exec["extract_${theme_name}_widgetkit"],
    }
  }
}
