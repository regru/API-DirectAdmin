package API::DirectAdmin;

use strict;

use LWP::UserAgent;
use HTTP::Request;
use URI;
use Carp;
use Data::Dumper;

our $VERSION = 0.03;
our $DEBUG   = '';
our $FAKE_ANSWER = '';

# for init subclasses
init_components(
    domain => 'Domain',
    mysql  => 'Mysql',
    user   => 'User',
    dns    => 'DNS',
    ip     => 'Ip',
);

# init
sub new {
    my $class = shift;
    $class = ref ($class) || $class;
    
    my $self = {
        auth_user   => '',
        auth_passwd => '',
        host        => '',
        ip          => '',
        debug       => $DEBUG,
	allow_https => 1,
	fake_answer => $FAKE_ANSWER,
        (@_)
    };

    confess "Required auth_user!"   unless $self->{auth_user};
    confess "Required auth_passwd!" unless $self->{auth_passwd};
    confess "Required host!"        unless $self->{host};

    return bless $self, $class;
}


# initialize components
sub init_components {
    my ( %c ) = @_;
    my $caller = caller;

    for my $alias (  keys %c ) {

        my $item = $c{$alias};

        my $sub = sub {
            my( $self ) = @_;
            $self->{"_$alias"} ||= $self->load_component($item);
            return $self->{"_$alias"} || confess "Not implemented!";
        };
        
        no strict 'refs';
 
        *{"$caller\::$alias"} = $sub;
    }
}

# loads component package and creates object
sub load_component {
    my ( $self, $item ) = @_;

    my $pkg = ref($self) . '::' . $item;

    my $module = "$pkg.pm";
       $module =~ s/::/\//g;

    local $@;
    eval { require $module };
    if ( $@ ) {
	confess "Failed to load $pkg: $@";
    }

    return $pkg->new(directadmin => $self);

}

# Filter hash
# STATIC(HASHREF: hash, ARRREF: allowed_keys)
# RETURN: hashref only with allowed keys
sub filter_hash {
    my ($self, $hash, $allowed_keys) = @_;
    
    return {} unless defined $hash;
    
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
    my ( $self, %params ) = @_;

    my $command   = delete $params{command};
    my $fields    = $params{allowed_fields} || '';

    my $allowed_fields;
    warn 'query_abstract ' . Dumper( \%params ) if $self->{debug};

    confess "Empty command" unless $command;

    $fields = "host port auth_user auth_passwd method allow_https command $fields";
    @$allowed_fields = split /\s+/, $fields;

    my $params = $self->filter_hash( $params{params}, $allowed_fields );

    my $query_string = $self->mk_full_query_string( {
        command => $command,
        %$params,
    } );

    carp Dumper $query_string if $self->{debug};
    
    my $server_answer =  $self->process_query(
        method        => $params{method} || 'GET',
        query_string  => $query_string,
        params 	      => $params,
    );
    
    carp Dumper $server_answer if $self->{debug};

    return $server_answer;
}

# Kill slashes at start / end string
# STATIC(STRING:input_string)
sub kill_start_end_slashes {
    my ($self ) = @_;

    for ( $self->{host} ) {
        s/^\/+//sgi;
        s/\/+$//sgi;
    }

    return 1;
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
    my ( $self, $params ) = @_;

    confess "Wrong params: " . Dumper( $params ) unless ref $params eq 'HASH' 
                                                        && scalar keys %$params
                                                        && $self->{host}
                                                        && $params->{command};

    $self->{allow_https} = ( defined $params->{allow_https} && $params->{allow_https} == 0 ) ? 0 : 1;
    delete $params->{allow_https};
    
    my $host        = $self->{host};
    my $port        = $self->{port} || 2222;
    my $command     = delete $params->{command};
    my $auth_user   = $self->{auth_user};
    my $auth_passwd = $self->{auth_passwd};

    $self->kill_start_end_slashes();

    my $query_path = ( $self->{allow_https} == 1 ? 'https' : 'http' ) . "://$auth_user:$auth_passwd\@$host:$port/$command?";
    return $query_path . $self->mk_query_string($params);
}

# Make query string
# STATIC(HASHREF: params)
sub mk_query_string {
    my ($self, $params) = @_;

    return '' unless ref $params eq 'HASH' && scalar keys %$params;

    my %params = %$params;

    my $result = join '&', map { "$_=$params{$_}" } sort keys %params;

    return $result;
}

# Get + deparse
# STATIC(STRING: query_string)
sub process_query {
    my ( $self, %params ) = @_;

    my $query_string = $params{query_string};
    my $method 	     = $params{method};

    confess "Empty query string" unless $query_string;

    my $answer = $self->{fake_answer} ? $self->{fake_answer} : $self->mk_query_to_server( $method, $query_string, $params{params} );
    carp $answer if $self->{debug};

    return $answer;
}

# Make request to server and get answer
# STATIC (STRING: query_string)
sub mk_query_to_server {
    my ( $self, $method, $url, $params ) = @_;
    
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
    
    warn "Answer: " . $content if $self->{debug};
    
    return $content if $params->{noparse};
    return $self->parse_answer($content);
}

# Parse answer
sub parse_answer {
    my ($self, $response) = @_;

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

__END__


=head1 NAME

API::DirectAdmin - interface to the DirectAdmin Hosting Panel API ( http://www.directadmin.com )

=head1 SYNOPSIS

 use API::DirectAdmin;
 
 my %auth = (
    auth_user   => 'admin_name',
    auth_passwd => 'admin_passwd',
    host        => '11.22.33.44',
 );

 # init
 my $da = API::DirectAdmin->new(%auth);

 ### Get all panel IP
 my $ip_list = $da->ip->list();

 unless ($ip_list && ref $ip_list eq 'ARRAY' && scalar @$ip_list) {
    die 'Cannot get ip list from DirectAdmin';
 }

 my $ip  = $ip_list->[0];
 my $dname  = 'perlaround.ru';
 my $user_name = 'user1';
 my $email = 'user1@example.com';
 my $package = 'newpackage';

 my $client_creation_result = $da->user->create( {
    username => $user_name,
    passwd   => 'user_password',
    passwd2  => 'user_password',
    domain   => $dname,
    email    => $email,
    package  => $package,
    ip       => $ip,
 });

 # Switch off account:
 my $suspend_result = $da->user->disable( {
    select0 => $user_name,
 } );

 if ( $suspend_result->{error} == 1 ) {
    die "Cannot  suspend account $suspend_result->{text}";
 }



 # Switch on account
 my $resume_result = $da->user->enable( {
    select0 => $user_name,
 } );

 if ( $resume_result->{error} == 1 ) {
    die "Cannot Resume account $resume_result->{text}";
 }



 # Delete account
 my $delete_result = $da->user->delete( {
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

Copyright (C) 2012 by Andrey "Chips" Kuzmin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
