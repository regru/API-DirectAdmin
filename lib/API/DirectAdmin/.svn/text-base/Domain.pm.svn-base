package API::DirectAdmin::Domain;

require API::DirectAdmin;

use strict;

use Data::Dumper;

our $VERSION = 0.01;
our $DEBUG   = '';

# Return domains list
# INPUT
# connection data for USER, not admin
sub list {
    my $params = shift;

    return API::DirectAdmin::query_abstract(
	params  => $params,
	command => 'CMD_API_SHOW_DOMAINS',
    )->{list};
}

# Add Domain to user account
# params: domain, php (ON|OFF), cgi (ON|OFF)
sub add {
    my $params = shift;
    
    my %add_params = (
	action => 'create',
    );
    
    my %params = (%$params, %add_params);
    
    warn 'params ' . Dumper(\%params) if $DEBUG;

    my $responce = API::DirectAdmin::query_abstract(
	params         => \%params,
	command        => 'CMD_API_DOMAIN',
	method	       => 'POST',
	allowed_fields =>
	   'action
	    domain
	    php
	    cgi',
    );
    
    warn 'responce ' . Dumper(\$responce) if $DEBUG;

    warn "Creating domain: $responce->{text}, $responce->{details}" if $DEBUG;
    return $responce;
}

1;
