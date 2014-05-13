package EPrints::Plugin::Screen::EPMC::AgroTaxonomy;

@ISA = ( 'EPrints::Plugin::Screen::EPMC' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{actions} = [qw( enable disable )];
	$self->{disable} = 0; # always enabled, even in lib/plugins

	$self->{package_name} = "AgroTaxonomy";

	return $self;
}

sub action_enable
{
	my( $self, $skip_reload ) = @_;

	$self->SUPER::action_enable( $skip_reload );

	my $repo = $self->{repository};

	my $db = EPrints::Database->new( $repo );
	$ok = $db->connect;
	$db->create_table( "eprint_agro_cache", ["uri", "thesaurus", "language"], ["uri VARCHAR(50)", "thesaurus VARCHAR(50)", "language VARCHAR(10)", "text_value VARCHAR(50)", "date_created BIGINT(20)"] );
	$db->disconnect;

	EPrints::XML::add_to_xml( $self->_workflow_file, $self->_xml, $self->{package_name} );	

	$self->reload_config if !$skip_reload;
}

sub action_disable
{
	my( $self, $skip_reload ) = @_;

	$self->SUPER::action_disable( $skip_reload );
	my $repo = $self->{repository};

	my $db = EPrints::Database->new( $repo );
	$ok = $db->connect;
	$db->drop_table( "eprint_agro_cache" );
	$db->disconnect;

	EPrints::XML::remove_package_from_xml( $self->_workflow_file, $self->{package_name} );

	$self->reload_config if !$skip_reload;
}

sub _workflow_file
{
	my ($self) = @_;

	return $self->{repository}->config( "config_path" )."/workflows/eprint/default.xml";
}

sub _xml
{
	my ($self) = @_;

	return <<END
<workflow xmlns="http://eprints.org/ep3/workflow" xmlns:epc="http://eprints.org/ep3/control">
	<flow>
		<stage ref="agro_taxonomy"/>
	</flow>
	<stage name="agro_taxonomy">
		<component><field ref="agro_subjects" /></component>
	</stage>
</workflow>
END
}

1;
