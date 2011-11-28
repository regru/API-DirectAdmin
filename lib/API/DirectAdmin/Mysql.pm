package API::DirectAdmin::Mysql;

require API::DirectAdmin;

use strict;

use Data::Dumper;

our $VERSION = 0.01;
our $DEBUG   = '';

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
    my $params = shift;
     
     my %add_params = (
	action	 => 'create',
    );
    
    my %params = (%$params, %add_params);
    
    warn 'params ' . Dumper(\%params) if $DEBUG;
    
    my $responce = API::DirectAdmin::query_abstract(
	command        => 'CMD_API_DATABASES',
	method	       => 'POST',
	params         => \%params,
	allowed_fields => 'action
			   name
			   passwd
			   passwd2
			   user',
    );
    
    warn '$responce ' . Dumper(\$responce) if $DEBUG;
    
    return $responce if $responce;    

    return 'FAIL';
}

1;
