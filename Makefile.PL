use inc::Module::Install;
name 'Mojolicious-Plugin-Directory';
all_from 'lib/Mojolicious/Plugin/Directory.pm';

requires 'Mojolicious' => 3.02;

tests 't/*.t';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
