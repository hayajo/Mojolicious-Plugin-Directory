use inc::Module::Install;
use Module::Install::Repository;
use Module::Install::ReadmePodFromPod;

name 'Mojolicious-Plugin-Directory';
all_from 'lib/Mojolicious/Plugin/Directory.pm';
readme_pod_from 'lib/Mojolicious/Plugin/Directory.pm';

requires 'Mojolicious' => 3.02;

tests 't/*.t';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
