class wordpress_site (
  $wp_dir         = '/opt/wp',
  $mysql_rootpass = '',
) {
  validate_absolute_path($wp_dir)

  ensure_packages(['php5', 'php5-mysql', 'php5-curl', 'php5-gd', 'unzip'])

  Database {
    require => Class['mysql::server'],
  }

  class { 'apache':
    mpm_module => 'prefork',
  }

  include 'apache::mod::php'

  apache::vhost { 'wordpress':
    docroot => '/var/www',
    port    => '80',
    require => File['/var/www'],
  }

  file { $wp_dir:
    ensure => directory,
  }

  file { '/var/www':
    ensure => link,
    force  => true,
    target => "${wp_dir}",
  }

  $plugins_path  = "${wp_dir}/installable_plugins"
  $demo_test_dir = "${wp_dir}/demo_test"

  file { [$plugins_path, $demo_test_dir]:
    ensure  => directory,
    require => File[$wp_dir],
  }
}
