package API::DirectAdmin::Ip;

require API::DirectAdmin;

use strict;

our $VERSION = 0.01;
our $DEBUG   = '';

# Return list of IP
# INPUT
# Admin connect params
sub list {
    my $params = shift;

    return API::DirectAdmin::query_abstract(
	params  => $params,
	command => 'CMD_API_SHOW_RESELLER_IPS',
    )->{list};
}

# Add Ip
# INPUT
# Admin connect params
# ip = 'IP.AD.DRE.SS'
# status = free|shared|owned (optional)
sub add {
    my $params = shift;
    my %add_params = (
	action   => 'add',
	add      => 'Submit',
	netmask  => '255.255.255.0',
	notify   => 'no',
    );
    
    my %params = (%$params, %add_params);
    
    return API::DirectAdmin::query_abstract(
	params  => \%params,
	method	=> 'POST',
	command => 'CMD_API_IP_MANAGER',
	allowed_fields => 'ip
			   action
			   add
			   netmask
			   notify
			   status',
    );
}

# Delete Ip
# INPUT
# Admin connect params
# select0 = 'IP.AD.DRE.SS'
sub remove {
    my $params = shift;
    my %add_params = (
	action   => 'select',
	delete   => 'Delete',
    );
    
    my %params = (%$params, %add_params);
    
    return API::DirectAdmin::query_abstract(
	params  => \%params,
	method	=> 'POST',
	command => 'CMD_API_IP_MANAGER',
	allowed_fields => 'select0
			   action
			   delete',
    );
}

1;
