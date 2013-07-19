define wordpress_site::warp_demo_pack (
  $theme,
  $build,
  $package,
) {
  include wordpress_site

  validate_absolute_path($package)

  $parent_dir = "${wordpress_site::demo_test_dir}/${theme}"
  $root_dir   = "${parent_dir}/${build}"

  file { [$parent_dir, $root_dir]:
    ensure => directory,
  }

  $dbname     = "${theme}_${build}"
  $dbuser     = "root"
  $dbpassword = $wordpress_site::mysql_root_password
  $dbhost     = 'localhost'

  database { $dbname:
    charset => 'utf8',
  }

  $test_docroot = "${root_dir}/test_${theme}"

  file { $test_docroot:
    ensure => directory,
  }

  exec { "extract_${theme}_${build}_package":
    command => "unzip ${package} -d ${test_docroot}",
    path    => ['/bin', '/usr/bin'],
    creates => "${test_docroot}/index.php",
    require => File[$test_docroot],
    notify  => Exec["chmod_{theme}_{build}_wkcache"],
  }

  file { "${test_docroot}/wp-config.php":
    ensure  => present,
    content => template('wordpress_site/wp-config.php.erb'),
    require => File[$test_docroot],
  }

  exec { "chmod_{theme}_{build}_wkcache":
    command     => "chmod o+w ${test_docroot}/wp-content/plugins/widgetkit/cache",
    path        => ['/bin', '/usr/bin'],
    onlyif      => "test -d ${test_docroot}/wp-content/plugins/widgetkit/cache",
    refreshonly => true,
  }
}
