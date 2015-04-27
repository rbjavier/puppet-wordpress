class wordpress_site (
  $wp_dir         = '/opt/wp',
  $mysql_rootpass = '',
) {
  validate_absolute_path($wp_dir)

  ensure_packages(['php5', 'php5-mysql', 'php5-curl', 'php5-gd', 'unzip'])

  exec { "get_wp-cli":
    command => "wget -P /tmp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar &&\
               mv /tmp/wp-cli.phar /usr/local/bin/wp",
    path    => ['/bin', '/usr/bin'],
    creates => "/usr/local/bin/wp",
  }

  file { "/usr/local/bin/wp":
    ensure  => present,
    mode    => '+x',
    require => Exec['get_wp-cli'],
  }

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

  $demo_test_dir = "${wp_dir}/demo_test"

  file { $demo_test_dir:
    ensure  => directory,
    require => File[$wp_dir],
  }
}
