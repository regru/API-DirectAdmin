package API::DirectAdmin;

use strict;

use LWP::UserAgent;
use HTTP::Request;
use URI;
use Carp;
use Data::Dumper;

our $VERSION     = 0.01;
our $DEBUG       = '';
our $FAKE_ANSWER = '';

=head1 NAME

API::DirectAdmin - interface to the DirectAdmin Hosting Panel API ( http://www.directadmin.com )

=head1 SYNOPSIS

 use API::DirectAdmin;
 
 my $connection_params = {
    auth_user   => 'admin_name',
    auth_passwd => 'admin_passwd',
    host        => '11.22.33.44',
 };

 ### Get all panel IP
 my $ip_list = API::DirectAdmin::Ip::list( $connection_params );

 unless ($ip_list && ref $ip_list eq 'ARRAY' && scalar @$ip_list) {
    die 'Cannot get ip list from DirectAdmin';
 }

 my $ip  = $ip_list->[0];
 my $dname  = 'perlaround.ru';
 my $user_name = 'user1';
 my $email = 'user1@example.com';
 my $package = 'newpackage';

 my $client_creation_result = API::DirectAdmin::User::create( {
    %{ $connection_params },
    username => $user_name,
    passwd   => 'user_password',
    passwd2  => 'user_password',
    domain   => $dname,
    email    => $email,
    package  => $package,
    ip       => $ip,
 });

 # Switch off account:
 my $suspend_result = API::DirectAdmin::User::disable( {
    %{ $connection_params },
    select0 => $user_name,
 } );

 if ( $suspend_result->{error} == 1 ) {
    die "Cannot  suspend account $suspend_result->{text}";
 }



 # Switch on account
 my $resume_result = API::DirectAdmin::User::enable( {
    %{ $connection_params },
    select0 => $user_name,
 } );

 if ( $resume_result->{error} == 1 ) {
    die "Cannot Resume account $resume_result->{text}";
 }



 # Delete account
 my $delete_result = API::DirectAdmin::User::delete( {
    %{ $connection_params },
    select0 => $user_name,
 } );

 if ( $delete_result->{error} == 1 ) {
    die "Cannot delete account $delete_result->{text}";
 }

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 DEPENDENCIES

This module requires these other modules and libraries:
  LWP::UserAgent
  HTTP::Request
  URI
  Carp 
  Data::Dumper

=head1 COPYRIGHT AND LICENCE

Put the correct copyright and licence information here.

Copyright (C) 2011 by Andrey Kuzmin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

# Filter hash
# STATIC(HASHREF: hash, ARRREF: allowed_keys)
# RETURN: hashref only with allowed keys
sub filter_hash {
    my ($hash, $allowed_keys) = @_;

    confess "Wrong params" unless ref $hash eq 'HASH' && ref $allowed_keys eq 'ARRAY';

    my $new_hash = { };

    foreach my $allowed_key (@$allowed_keys) {
        if (exists $hash->{$allowed_key}) {
            $new_hash->{$allowed_key} = $hash->{$allowed_key};
        }
        elsif (exists $hash->{lc $allowed_key}) {
            $new_hash->{$allowed_key} = $hash->{lc $allowed_key};
        };
    }

    return $new_hash;
}

# all params derived from get_auth_hash
sub query_abstract {
    my %params = @_;

    my $command   = $params{command};
    my $fields    = $params{allowed_fields} || '';

    my $allowed_fields;
    warn 'query_abstract ' . Dumper( \%params ) if $DEBUG;

    confess "Empty params or command" unless $params{params} && $command;

    $fields = "host port auth_user auth_passwd method allow_https command $fields";
    @$allowed_fields = split(' ', $fields);

    my $params = filter_hash( $params{params}, $allowed_fields );

    my $query_string = mk_full_query_string( {
        command => $command,
        %$params,
    } );

    carp Dumper $query_string if $DEBUG;
    
    my $server_answer =  process_query(
        method        => $params{method} || 'GET',
        query_string  => $query_string,
        params 	      => $params,
    );
    
    carp Dumper $server_answer if $DEBUG;

    return $server_answer;
}

# Kill slashes at start / end string
# STATIC(STRING:input_string)
sub kill_start_end_slashes {
    my $str = shift;

    for ($str) {
        s/^\/+//sgi;
        s/\/+$//sgi;
    }

    return $str;
}

# Make full query string 
# STATIC(HASHREF: params)
# params:
# host*
# port*
# param1
# param2 
# ...
sub mk_full_query_string {
    my $params = shift;

    confess "Wrong params: " . Dumper( $params ) unless ref $params eq 'HASH' 
                                                        && scalar keys %$params 
                                                        && $params->{host}
                                                        && $params->{command};

    my $host        = delete $params->{host};
    my $port        = delete $params->{port} || 2222;
    my $allow_https = delete $params->{allow_https};
    my $command     = delete $params->{command};
    my $auth_user   = delete $params->{auth_user};
    my $auth_passwd = delete $params->{auth_passwd};

    $host = kill_start_end_slashes($host);

    my $query_path = ( $allow_https ? 'https' : 'http' ) . "://$auth_user:$auth_passwd\@$host:$port/$command?";
    return $query_path . mk_query_string($params);
}


# Make query string
# STATIC(HASHREF: params)
sub mk_query_string {
    my $params = shift;

    return '' unless ref $params eq 'HASH' && scalar keys %$params;

    my %params = %$params;
    delete $params{auth_user};
    delete $params{auth_passwd};

    my $result = join '&', map { "$_=$params{$_}" } sort keys %params;

    return $result;
}

# Get + deparse
# STATIC(STRING: query_string)
sub process_query {
    my %params = @_;

    my $query_string = $params{query_string};
    my $method 	     = $params{method};
    my $fake_answer  = $API::DirectAdmin::FAKE_ANSWER || '';

    confess "Wrong params" unless $query_string;

    my $answer = $fake_answer ? $fake_answer : mk_query_to_server( $method, $query_string, $params{params}  );
    carp $answer if $answer && $DEBUG;

    return $answer;
}

# Make request to server and get answer
# STATIC (STRING: query_string)
sub mk_query_to_server {
    my ( $method, $url, $params ) = @_;
    
    unless ( $method ~~ [ qw( POST GET ) ] ) {
        confess "Unknown request method: '$method'";
    }

    confess "URL is empty" unless $url;

    my $content;
    my $ua = LWP::UserAgent->new;
    my $request = HTTP::Request->new( $method, $url );
    
    if ( $method eq 'GET' ) {
	my $response = $ua->request( $request );
	$content = $response->content;
    }
    else { # Temporary URL for making request
	my $temp_uri = URI->new('http:');
	$temp_uri->query_form( $params );
	$request->content( $temp_uri->query );
	$request->content_type('application/x-www-form-urlencoded');
	my $response = $ua->request($request);
	$content = $response->content;
    }
    
    warn "Answer: " . $content if $DEBUG;
    
    return $content if $params->{noparse};
    return parse_answer($content);
}

# Parse answer
sub parse_answer {
    my $response = shift;

    return '' unless $response;
    
    my %answer;
    $response =~ s/&#60br&#62|&#\d+//ig; # Some trash from answer
    $response =~ s/\n+/\n/ig;
    my @params = split /&/, $response;
    
    foreach my $param ( @params ) {
	my ($key, $value) = split /=/, $param;
	if ( $key =~ /(.*)\[\]/ ) { # lists
	    push @{ $answer{$1} },  $value;
	}
	else {
	    $answer{$key} = $value;
	}
    }

    return \%answer || '';
}

1;
