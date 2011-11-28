package API::DirectAdmin::User;

require API::DirectAdmin;

use strict;

our $VERSION = 0.01;
our $DEBUG = '';

# Return list of users (only usernames)
sub list {
    my $params = shift;

    return API::DirectAdmin::query_abstract(
	params  => $params,
	command => 'CMD_API_SHOW_ALL_USERS',
    )->{list};
}

# Create a New User
# params: username, domain, passwd, passwd2, package, ip, email
sub create {
    my $params = shift;
    
    my %add_params = (
	action   => 'create',
	add      => 'submit',
	notify 	 => 'no',
    );
    
    my %params = (%$params, %add_params);

    my $responce = API::DirectAdmin::query_abstract(
	params         => \%params,
	command        => 'CMD_API_ACCOUNT_USER',
	allowed_fields =>
	   'action
	    add
	    notify
	    username
	    domain
	    passwd
	    passwd2
	    package
	    ip
	    email',
    );

    warn "Creating account: $responce->{text}, $responce->{details}" if $DEBUG;
    return $responce;
}

# Suspend user
# params: select0
sub disable {
    my $params = shift;
     
     my %add_params = (
	suspend	 => 'Suspend',
	location => 'CMD_SELECT_USERS',
    );
    
    my %params = (%$params, %add_params);
    
     my $responce = API::DirectAdmin::query_abstract(
	command        => 'CMD_API_SELECT_USERS',
	method	       => 'POST',
	params         => \%params,
	allowed_fields => 'location
			   suspend
			   select0',
    );

    warn "Suspend account: $responce->{text}, $responce->{details}" if $DEBUG;
    return $responce;
}

# Unsuspend user
# params: select0
sub enable {
    my $params = shift;
     
     my %add_params = (
	suspend	 => 'Unsuspend',
	location => 'CMD_SELECT_USERS',
    );
    
    my %params = (%$params, %add_params);
    
    my $responce = API::DirectAdmin::query_abstract(
	command        => 'CMD_API_SELECT_USERS',
	method	       => 'POST',
	params         => \%params,
	allowed_fields => 'location
			   suspend
			   select0',
    );

    warn "Unsuspend account: $responce->{text}, $responce->{details}" if $DEBUG;
    return $responce;    
    
}

# Delete user
# params: select0
sub delete {
    my $params = shift;
     
     my %add_params = (
	confirmed => 'Confirm',
	delete    => 'yes',
    );
    
    my %params = (%$params, %add_params);

    my $responce = API::DirectAdmin::query_abstract(
	command        => 'CMD_API_SELECT_USERS',
	method	       => 'POST',
	params         => \%params,
	allowed_fields => 'confirmed
			   delete
			   select0',
    );

    warn "Delete account: $responce->{text}, $responce->{details}" if $DEBUG;
    return $responce;
}

# Change passwd
# params: username, passwd, passwd2
sub change_password {
    my $params = shift;

    my $responce = API::DirectAdmin::query_abstract(
	command        => 'CMD_API_USER_PASSWD',
	method	       => 'POST',
	params         => $params,
	allowed_fields => 'passwd
			   passwd2
			   username',
    );

    warn "Change passwd account: $responce->{text}, $responce->{details}" if $DEBUG;
    return $responce;
}

# Change package for user
# params: user, package
sub change_package {
    my $params = shift;
    
    my $package =  $params->{package};
    
    
    unless ( $API::DirectAdmin::FAKE_ANSWER ) {
	unless ( $package ~~ show_packages($params) ) {
	    return {error => 1, text => "No such package $package on server"};
	} 
    }
    
    my %add_params = (
	action => 'package',
    );
    
    my %params = (%$params, %add_params);
    
    my $responce = API::DirectAdmin::query_abstract(
	command        => 'CMD_API_MODIFY_USER',
	method	       => 'POST',
	params         => \%params,
	allowed_fields => 'action
			   package
			   user',
    );
    
    warn "Change package: $responce->{text}, $responce->{details}" if $DEBUG;
    return $responce;
}

# Show a list of user packages
# no params
sub show_packages {
    my $params = shift;

    my $responce = API::DirectAdmin::query_abstract(
	command => 'CMD_API_PACKAGES_USER',
	params  => $params,
    )->{list};
    
    warn "Show packages" if $DEBUG;
    return $responce;
}

1;
