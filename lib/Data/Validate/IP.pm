package Data::Validate::IP;

use strict;
use warnings;
use Net::Netmask;
#use Net::IPv6Addr;


require Exporter;
use AutoLoader 'AUTOLOAD';

use constant LOOPBACK   => [qw(127.0.0.0/8)];
use constant TESTNET    => [qw(192.0.2.0/24)];
use constant PRIVATE    => [qw(10.0.0.0/8 172.16.0.0/12 192.168.0.0/16)];
use constant MULTICAST  => [qw(224.0.0.0/4)];
use constant LINKLOCAL  => [qw(169.254.0.0/16)];

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Data::Validate::IP ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
                is_ipv4
                is_private_ipv4
                is_loopback_ipv4
                is_testnet_ipv4
                is_public_ipv4
                is_multicast_ipv4
                is_linklocal_ipv4
);
#                is_ipv6

our $VERSION = '0.07';

#Global, we store this only once
my %MASK;


# Preloaded methods go here.

1;
__END__
# 

=head1 NAME

Data::Validate::IP - ip validation methods

=head1 SYNOPSIS

  use Data::Validate::IP qw(is_ipv4);
  
  if(is_ipv4($suspect)){
        print "Looks like an ip address";
  } else {
        print "Not an ip address\n";
  }
  

  # or as an object
  my $v = Data::Validate::IP->new();
  
  die "not an ip" unless ($v->is_ipv4('domain.com'));

=head1 DESCRIPTION

This module collects ip validation routines to make input validation,
and untainting easier and more readable. 

All functions return an untainted value if the test passes, and undef if
it fails.  This means that you should always check for a defined status explicitly.
Don't assume the return will be true. (e.g. is_username('0'))

The value to test is always the first (and often only) argument.

=head1 FUNCTIONS

=over 4


=item B<new> - constructor for OO usage

  $obj = Data::Validate::IP->new();

=over 4

=item I<Description>

Returns a Data::Validator::IP object.  This lets you access all the validator function
calls as methods without importing them into your namespace or using the clumsy
Data::Validate::IP::function_name() format.

=item I<Arguments>

None

=item I<Returns>

Returns a Data::Validate::IP object

=back

=cut




sub new{
        my $class = shift;
        
        return bless {}, $class;
}


# -------------------------------------------------------------------------------

=pod

=item B<is_ipv4> - does the value look like an ip v4 address?

  is_ipv4($value);
  or
  $obj->is_ipv4($value);


=over 4

=item I<Description>

Returns the untainted ip address if the test value appears to be a well-formed
ip address. 

=item I<Arguments>

=over 4

=item $value

The potential ip to test.

=back

=item I<Returns>

Returns the untainted ip on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

The function does not make any attempt to check whether an ip  
actually exists. It only looks to see that the format is appropriate.

=back

=cut

sub is_ipv4 {
        my $self = shift if ref($_[0]); 
        my $value = shift;
        
        return unless defined($value);
        
        my(@octets) = $value =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;
	return unless (@octets == 4);
	foreach (@octets) {
		return unless ($_ >= 0 && $_ <= 255);
	}
        
        return join('.', @octets);
}

# -------------------------------------------------------------------------------
#
#=pod
#
#=item B<is_ipv6> - does the value look like an ip v6 address?
#                
#  is_ipv6($value);
#                
#=over 4
#
#=item I<Description>  
#
#Returns the untainted ip address if the test value appears to be a well-formed
#ip address.
#
#=item I<Arguments>
#
#=over 4
#
#=item $value
#
#The potential ip to test.
#
#=back
#
#=item I<Returns>
#
#Returns the untainted ip on success, undef on failure.
#
#=item I<Notes, Exceptions, & Bugs>
#
#The function does not make any attempt to check whether an ip
#actually exists. It only looks to see that the format is appropriate.
#All the real work for this is done by Net::IPv6Addr.
#
#=back
#
#=cut
#
#
#
#
#sub is_ipv6 {
#        my $self = shift if ref($_[0]); 
#        my $value = shift;
#        
#        return unless defined($value);
#	my $return = Net::IPv6Addr::is_ipv6($value);;
#	return $return;
#}

=pod

=item B<is_private_ipv4> - is it a valid private ipv4 address 

  is_private_ipv4($value);
  or
  $obj->is_private_ipv4($value);

=over 4

=item I<Description>

Returns the untainted ip address if the test value appears to be a well-formed
private ip address.

=item I<Arguments>

=over 4

=item $value

The potential ip to test.

=back

=item I<Returns>

Returns the untainted ip on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

The function does not make any attempt to check whether an ip
actually exists. 

=item I<From RFC 3330>

   10.0.0.0/8 - This block is set aside for use in private networks.
   Its intended use is documented in [RFC1918].  Addresses within this
   block should not appear on the public Internet.

   172.16.0.0/12 - This block is set aside for use in private networks.
   Its intended use is documented in [RFC1918].  Addresses within this
   block should not appear on the public Internet.

   192.168.0.0/16 - This block is set aside for use in private networks.
   Its intended use is documented in [RFC1918].  Addresses within this
   block should not appear on the public Internet.


=back

=cut


sub is_private_ipv4 {
        my $self = shift if ref($_[0]); 
        my $value = shift;
        
        return unless defined($value);

	my $ip = is_ipv4($value);
	return unless defined $ip;

	return unless Net::Netmask::findNetblock($ip,_mask('private'));
	return $ip;
}

=pod

=item B<is_loopback_ipv4> - is it a valid loopback ipv4 address 

  is_loopback_ipv4($value);
  or
  $obj->is_loopback_ipv4($value);

=over 4

=item I<Description>

Returns the untainted ip address if the test value appears to be a well-formed
loopback ip address.

=item I<Arguments>

=over 4

=item $value

The potential ip to test.

=back

=item I<Returns>

Returns the untainted ip on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

The function does not make any attempt to check whether an ip
actually exists. 

=item I<From RFC 3330>

   127.0.0.0/8 - This block is assigned for use as the Internet host
   loopback address.  A datagram sent by a higher level protocol to an
   address anywhere within this block should loop back inside the host.
   This is ordinarily implemented using only 127.0.0.1/32 for loopback,
   but no addresses within this block should ever appear on any network
   anywhere [RFC1700, page 5].

=back

=cut


sub is_loopback_ipv4 {
        my $self = shift if ref($_[0]); 
        my $value = shift;
        
        return unless defined($value);

	my $ip = is_ipv4($value);
	return unless defined $ip;

	return unless Net::Netmask::findNetblock($ip,_mask('loopback'));
	return $ip;
}

=pod

=item B<is_testnet_ipv4> - is it a valid testnet ipv4 address 

  is_testnet_ipv4($value);
  or
  $obj->is_testnet_ipv4($value);

=over 4

=item I<Description>

Returns the untainted ip address if the test value appears to be a well-formed
testnet ip address.

=item I<Arguments>

=over 4

=item $value

The potential ip to test.

=back

=item I<Returns>

Returns the untainted ip on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

The function does not make any attempt to check whether an ip
actually exists. 

=item I<From RFC 3330>

   192.0.2.0/24 - This block is assigned as "TEST-NET" for use in
   documentation and example code.  It is often used in conjunction with
   domain names example.com or example.net in vendor and protocol
   documentation.  Addresses within this block should not appear on the
   public Internet.

=back

=cut


sub is_testnet_ipv4 {
        my $self = shift if ref($_[0]); 
        my $value = shift;
        
        return unless defined($value);

	my $ip = is_ipv4($value);
	return unless defined $ip;

	return unless Net::Netmask::findNetblock($ip,_mask('testnet'));
	return $ip;
}

=pod

=item B<is_multicast_ipv4> - is it a valid multicast ipv4 address

  is_multicast_ipv4($value);
  or
  $obj->is_multicast_ipv4($value);

=over 4

=item I<Description>

Returns the untainted ip addres if the test value appears to be a well-formed
multicast ip address.

=item I<Arguments>

=over 4

=item $value

The potential ip to test.

=back

=item I<Returns>

Returns the untainted ip on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

The function does not make any attempt to check whether an ip
actually exists.

=item I<From RFC 3330>

   224.0.0.0/4 - This block, formerly known as the Class D address
   space, is allocated for use in IPv4 multicast address assignments.
   The IANA guidelines for assignments from this space are described in
   [RFC3171].

=back

=cut


sub is_multicast_ipv4 {
       my $self = shift if ref($_[0]); 
       my $value = shift;

       return unless defined($value);

       my $ip = is_ipv4($value);
       return unless defined $ip;

       return unless Net::Netmask::findNetblock($ip,_mask('multicast'));
       return $ip;
}


=pod

=item B<is_linklocal_ipv4> - is it a valid link-local ipv4 address

  is_linklocal_ipv4($value);
  or
  $obj->is_linklocal_ipv4($value);

=over 4

=item I<Description>

Returns the untainted ip addres if the test value appears to be a well-formed
link-local ip address.

=item I<Arguments>

=over 4

=item $value

The potential ip to test.

=back

=item I<Returns>

Returns the untainted ip on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

The function does not make any attempt to check whether an ip
actually exists.

=item I<From RFC 3330>

   169.254.0.0/16 - This is the "link local" block.  It is allocated for
   communication between hosts on a single link.  Hosts obtain these
   addresses by auto-configuration, such as when a DHCP server may not
   be found.

=back

=cut


sub is_linklocal_ipv4 {
       my $self = shift if ref($_[0]); 
       my $value = shift;

       return unless defined($value);

       my $ip = is_ipv4($value);
       return unless defined $ip;

       return unless Net::Netmask::findNetblock($ip,_mask('linklocal'));
       return $ip;
}



=pod

=item B<is_public_ipv4> - is it a valid public ipv4 address 

  is_public_ipv4($value);
  or
  $obj->is_public_ipv4($value);

=over 4

=item I<Description>

Returns the untainted ip address if the test value appears to be a well-formed
public ip address.

=item I<Arguments>

=over 4

=item $value

The potential ip to test.

=back

=item I<Returns>

Returns the untainted ip on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

The function does not make any attempt to check whether an ip
actually exists or could truly route.  This is true for any 
non- private/testnet/loopback ip.

=back

=cut


sub is_public_ipv4 {
        my $self = shift if ref($_[0]); 
        my $value = shift;
        
        return unless defined($value);

	my $ip = is_ipv4($value);
	return unless defined $ip;

	#Logic for this is inverted... all values from mask are 'not public'
	return if Net::Netmask::findNetblock($ip,_mask('public'));
	return $ip;
}




#We only want to bother building this once for each type
#We store it globally as it is effectively a constant
sub _mask {
	my $type = (shift);
	return $MASK{$type} if (defined $MASK{$type});
	my @masks;
	if ($type eq 'public') {
		@masks = (LOOPBACK, TESTNET, PRIVATE,MULTICAST,LINKLOCAL);
	} elsif ($type eq 'loopback') {
		@masks = (LOOPBACK);
	} elsif ($type eq 'private') {
		@masks = (PRIVATE);
	} elsif ($type eq 'testnet') {
		@masks = (TESTNET);
	} elsif ($type eq 'multicast') {
		@masks = (MULTICAST);
	} elsif ($type eq 'linklocal') {
		@masks = (LINKLOCAL);
	}
	my $mask = {};
	foreach my $default (@masks) {
		foreach my $range (@{$default}) {
			my $block = Net::Netmask->new($range);
			$block->storeNetblock($mask);
		}   
	}   
	$MASK{$type}= $mask;
	return $MASK{$type};
}


# -------------------------------------------------------------------------------

=back

=head1 SEE ALSO

b<[RFC 3330] [RFC 1918] [RFC 1700]>

=over 4

=item  L<Data::Validate(3)>

=back

=head1 TODO

Add in support for verifying IPv6 addresses.

=head1 AUTHOR

Neil Neely <F<neil@neely.cx>>.

=head1 ACKNOWLEDGEMENTS 

Thanks to Richard Sonnen <F<sonnen@richardsonnen.com>> for writing the Data::Validate module.

Thanks to Matt Dainty <F<matt@bodgit-n-scarper.com>> for adding the is_multicast_ipv4 and is_linklocal_ipv4 code.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2007 Neil Neely.  




This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
