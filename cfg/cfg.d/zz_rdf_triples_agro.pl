
$c->{rdf}->{xmlns}->{agro} = "http://example.org/agro/";

$c->add_dataset_trigger( "eprint", EP_TRIGGER_RDF, sub {
	my( %o ) = @_;
	my $eprint = $o{"dataobj"};
	my $eprint_uri = "<".$eprint->uri.">";

	foreach my $agro_subject ( @{$eprint->get_value( "agro_subjects" )} )
	{
		my $agro_uri = "<".$agro_subject->{authority}.">";
		$o{graph}->add( 
			  subject => $agro_uri,
			predicate => "rdf:type",
			   object => "agro:AgroThingy" );
		$o{graph}->add( 
			  subject => $agro_uri,
			predicate => "rdfs:label",
			   object => $agro_subject->{text_value},
			     type => "xsd:string" );
		$o{graph}->add( 
			  subject => $eprint_uri,
			predicate => "dct:subject",
			   object => $agro_uri );
	}

} );

