package API::DirectAdmin::Domain;

use strict;
use Data::Dumper;

use base 'API::DirectAdmin::Component';

our $VERSION = 0.03;

# Return domains list
# INPUT
# connection data for USER, not admin
sub list {
    my ($self ) = @_;

    return $self->directadmin->query(
	command => 'CMD_API_SHOW_DOMAINS',
    )->{list};
}

# Add Domain to user account
# params: domain, php (ON|OFF), cgi (ON|OFF)
sub add {
    my ($self, $params ) = @_;
    
    my %add_params = (
	action => 'create',
    );
    
    my %params = (%$params, %add_params);
    
    #warn 'params ' . Dumper(\%params) if $DEBUG;

    my $responce = $self->directadmin->query(
	params         => \%params,
	command        => 'CMD_API_DOMAIN',
	method	       => 'POST',
	allowed_fields =>
	   'action
	    domain
	    php
	    cgi',
    );
    
    warn 'responce ' . Dumper(\$responce) if $self->{debug};

    warn "Creating domain: $responce->{text}, $responce->{details}" if $self->{debug};
    return $responce;
}

1;
