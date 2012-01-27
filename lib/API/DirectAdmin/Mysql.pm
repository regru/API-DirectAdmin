package API::DirectAdmin::Mysql;

use strict;
use Data::Dumper;
use Carp;

use base 'API::DirectAdmin::Component';

our $VERSION = 0.03;

# Create database for user
# Connection data MUST BE for user: auth_user => 'admin_login|user_login'
# auth_passwd => 'admin_passwd'
#    INPUT
#    host 	=> 'HOST',
#    auth_user 	=> 'USERNAME_LOGIN',
#    auth_passwd => 'USERNAME_PASSWD',
#    name	=> 'DBNAME',
#    passwd	=> 'DBPASSWD',
#    passwd2	=> 'DBPASSWD',
#    user	=> 'DBLOGIN',
sub adddb {
    my ($self, $params ) = @_;
     
     my %add_params = (
	action	 => 'create',
    );
    
    my %params = (%$params, %add_params);
    
    carp 'params ' . Dumper(\%params) if $self->{debug};
    
    my $responce = $self->directadmin->query(
	command        => 'CMD_API_DATABASES',
	method	       => 'POST',
	params         => \%params,
	allowed_fields => 'action
			   name
			   passwd
			   passwd2
			   user',
    );
    
    carp '$responce ' . Dumper(\$responce) if $self->{debug};
    
    return $responce if $responce;    

    return 'FAIL';
}

1;
