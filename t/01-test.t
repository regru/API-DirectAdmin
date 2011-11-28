#!/usr/bin/perl -w

use strict;
use warnings;
use lib qw( ./lib );

use Data::Dumper;

our $ONLINE;

BEGIN {
    #$ENV{auth_user}   = 'restest';
    #$ENV{auth_passwd} = '123';
    #$ENV{host}        = '192.168.123.1';
    $ONLINE = $ENV{auth_user} && $ENV{auth_passwd} && $ENV{host};
}

my $manipulate_user = 'zsezse';

use Test::More tests => $ONLINE ? 38 : 38;
my %connection_params = (
    host	=> $ENV{host} || '127.0.0.1',
    auth_user	=> $ENV{auth_user} || 'login',
    auth_passwd => $ENV{auth_passwd} || 'passwd',
);

ok(1, 'Test OK');
use_ok('API::DirectAdmin');

my $func = 'filter_hash';
is_deeply( API::DirectAdmin::filter_hash( {  }, [ ]), {}, $func );
is_deeply( API::DirectAdmin::filter_hash( { aaa => 555, bbb => 111 }, [ 'aaa' ]), { aaa => 555 }, $func );
is_deeply( API::DirectAdmin::filter_hash( { aaa => 555, bbb => 111 }, [ ]), { }, $func );
is_deeply( API::DirectAdmin::filter_hash( { }, [ 'aaa' ]), { }, $func );

$func = 'mk_query_string';
is( API::DirectAdmin::mk_query_string( {  }  ), '', $func );
is( API::DirectAdmin::mk_query_string( ''    ), '', $func );
is( API::DirectAdmin::mk_query_string( undef ), '', $func );
is( API::DirectAdmin::mk_query_string( { aaa => 111, bbb => 222 } ), 'aaa=111&bbb=222', $func );
is( API::DirectAdmin::mk_query_string( { bbb => 222, aaa => 111 } ), 'aaa=111&bbb=222', $func );
is( API::DirectAdmin::mk_query_string( [ ] ), '', $func );
is( API::DirectAdmin::mk_query_string( { dddd => 'dfdf' } ), 'dddd=dfdf', $func );

my $kill_start_end_slashes_test = {
    '////aaa////' => 'aaa',
    'bbb////'     => 'bbb',
    '////ccc'     => 'ccc', 
    ''            => '',
};

for (keys %$kill_start_end_slashes_test) {
    is(
        API::DirectAdmin::kill_start_end_slashes ($_),
        $kill_start_end_slashes_test->{$_},
        'kill_start_end_slashes'
    );
}

$func = 'mk_full_query_string';
is( API::DirectAdmin::mk_full_query_string( { %connection_params, command => 'CMD' } ), 
    'http://'.$connection_params{auth_user}.':'.$connection_params{auth_passwd}.'@'.$connection_params{host}.':2222/CMD?',
    $func
);

is( API::DirectAdmin::mk_full_query_string( { %connection_params, command => 'CMD', allow_https => 1 } ), 
    'https://'.$connection_params{auth_user}.':'.$connection_params{auth_passwd}.'@'.$connection_params{host}.':2222/CMD?',
    $func
);

is( API::DirectAdmin::mk_full_query_string( {
	%connection_params,
	command => 'CMD',
        param1  => 'val1',
        param2  => 'val2',
    } ), 
    'http://'.$connection_params{auth_user}.':'.$connection_params{auth_passwd}.'@'.$connection_params{host}.':2222/CMD?param1=val1&param2=val2',
    $func
);

is( API::DirectAdmin::mk_full_query_string( {
        %connection_params,
        param1      => 'val1',
        param2      => 'val2',
        command     => 'CMD',
	allow_https => 1, 
    } ), 
    'https://'.$connection_params{auth_user}.':'.$connection_params{auth_passwd}.'@'.$connection_params{host}.':2222/CMD?param1=val1&param2=val2',
    $func
);

use_ok('API::DirectAdmin::Ip');

$API::DirectAdmin::FAKE_ANSWER = ! $ONLINE ? { list => ['127.0.0.1'], error => 0 } : undef;

my $ip_list = API::DirectAdmin::Ip::list( \%connection_params );

my $main_shared_ip = $ip_list->[0];
ok($ip_list && ref $ip_list eq 'ARRAY' && scalar @$ip_list, 'API::DirectAdmin::Ip::list');

my %answer = (
    text    => "User $manipulate_user created",
    error   => 0,
    details => 'Unix User created successfully
Users System Quotas set
Users data directory created successfully
Domains directory created successfully
Domains directory created successfully in users home
Domain Created Successfully');
$API::DirectAdmin::FAKE_ANSWER = ! $ONLINE ? \%answer : undef;

use_ok('API::DirectAdmin::User');

my $result = API::DirectAdmin::User::create(
    {
	%connection_params,
	username => $manipulate_user,
	domain   => 'zse1.ru',
	passwd   => 'qwerty',
	passwd2  => 'qwerty',
	email    => 'test@example.com',
	ip       => '127.0.0.1',
	package  => 'newpackage',
    }
);
is_deeply( $result, \%answer, 'API::DirectAdmin::User::create' );

%answer = (
  text    => 'Cannot Create Account',
  error   => 1,
  details => 'That username already exists on the system'
);
	
$API::DirectAdmin::FAKE_ANSWER = ! $ONLINE ? \%answer : undef;

$result = API::DirectAdmin::User::create(
    {
	%connection_params,
	username => $manipulate_user,
	domain   => 'zse1.ru',
	passwd   => 'qwerty',
	passwd2  => 'qwerty',
	email    => 'test@example.com',
	ip       => '127.0.0.1',
	package  => 'newpackage',
    }
);
is_deeply( $result, \%answer, 'API::DirectAdmin::User::create repeat');

%answer = (
    text 	=> 'Password Changed',
    error 	=> 0,
    details 	=> 'Password successfully changed'
);

$API::DirectAdmin::FAKE_ANSWER = ! $ONLINE ? \%answer : undef;

$result = API::DirectAdmin::User::change_password(
    {
	%connection_params,
	user => $manipulate_user,
	pass => 'sdfdsfsdfhsdfj',
    }
);
is_deeply( $result, \%answer, 'API::DirectAdmin::User::change_password');

%answer = (
    text 	=> 'Success',
    error 	=> 0,
    details 	=> 'All selected Users have been suspended',
);

$API::DirectAdmin::FAKE_ANSWER = ! $ONLINE ? \%answer : undef;

$result = API::DirectAdmin::User::disable(
    {
	%connection_params,
	user   => $manipulate_user,
	reason => 'test reason1',
    }
);
is_deeply( $result, \%answer, 'API::DirectAdmin::User::disable');

$API::DirectAdmin::FAKE_ANSWER = ! $ONLINE ? \%answer : undef;

$result = API::DirectAdmin::User::enable(
    {
	%connection_params,
	user => $manipulate_user,
    }
);
is_deeply( $result, \%answer, 'API::DirectAdmin::User::enable');

$API::DirectAdmin::FAKE_ANSWER = ! $ONLINE ? { list => ['default','admin'], error => 0, } : undef;

$result = API::DirectAdmin::User::list(
    {
	%connection_params,
    }
);
ok( ref $result eq 'ARRAY' && scalar @$result, 'API::DirectAdmin::User::list');

%answer = (
    text 	=> 'No such package newpackage on server',
    error 	=> 1,
);

$API::DirectAdmin::FAKE_ANSWER = ! $ONLINE ? \%answer : undef;

$result = API::DirectAdmin::User::change_package(
    {
	%connection_params,
	user    => $manipulate_user,
	package => 'newpackage',
    }
);

is_deeply( $result, \%answer, 'API::DirectAdmin::User::change_package');

%answer = (
    text 	=> 'Users deleted',
    error 	=> 0,
    details 	=> "User $manipulate_user Removed",
);

$API::DirectAdmin::FAKE_ANSWER = ! $ONLINE ? \%answer : undef;

$result = API::DirectAdmin::User::delete(
    {
	%connection_params,
	user => $manipulate_user,
    }
);
is_deeply( $result, \%answer, 'API::DirectAdmin::User::delete');

%answer = (
    text 	=> 'Error while deleting Users',
    error 	=> 1,
    details 	=> "User $manipulate_user did not exist on the server.  Removing it from your list.",
);

$API::DirectAdmin::FAKE_ANSWER = ! $ONLINE ? \%answer : undef;

$result = API::DirectAdmin::User::delete(
    {
	%connection_params,
	user => $manipulate_user,
    }
);
is_deeply( $result, \%answer , 'API::DirectAdmin::User::delete repeat');

# Mysql тесты

use_ok('API::DirectAdmin::Mysql');

$connection_params{auth_user} .= '|' . $manipulate_user;

%answer = (
    text 	=> 'Database Created',
    error 	=> 0,
    details 	=> 'Database Created',
);

$API::DirectAdmin::FAKE_ANSWER = ! $ONLINE ? \%answer : undef;

$result = API::DirectAdmin::Mysql::adddb(
    {
        %connection_params,
        name     => 'default',
        user     => 'default',
        passwd   => 'default_pass',
        passwd2  => 'default_pass',
    }
);
is_deeply( $result, \%answer, 'API::DirectAdmin::Mysql::adddb');

use_ok('API::DirectAdmin::Domain');

my $addondomain = 'ssssss.ru';

%answer = (
    text 	=> 'Domain Created',
    error 	=> 0,
    details 	=> 'Domain Created Successfully'
);

$API::DirectAdmin::FAKE_ANSWER = ! $ONLINE ? \%answer : undef;
$result = API::DirectAdmin::Domain::add(
    {
        %connection_params,
        domain => $addondomain,
        php => 'ON',
        cgi => 'ON',
    }
);
is_deeply( $result, \%answer  , 'API::DirectAdmin::Domain::add');

%answer = (
    text 	=> 'Cannot create that domain',
    error 	=> 1,
    details 	=> 'That domain already exists'
);

$API::DirectAdmin::FAKE_ANSWER = ! $ONLINE ? \%answer : undef;
$result = API::DirectAdmin::Domain::add(
    {
        %connection_params,
        domain => $addondomain,
        php => 'ON',
        cgi => 'ON',
    }
);
is_deeply( $result, \%answer  , 'API::DirectAdmin::Domain::add repeat');

