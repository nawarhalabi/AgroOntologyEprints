#
###################################################################
=pod

=item $input = render_ontology_input( $session, $field, $value, $object  )
=item $output = render_ontology_output( $field, $session, $current_value, $dataset, $staff, $hidden_fields, $object, $basename )

These functions are responsilbe for the input and output of the ontology plugin 
created in Hasselt University. The input function creates a text area with a 
button that calss a java script function "show_overlay()". This functions opens
an iframe containing a plugin and waits for a message from the plugin to add the
agricultural concepts to the text area.
The output function displays the agricutural concepts in different languages
depending on the requirements

=cut
#####################################################################


$c->add_dataset_field(
	"eprint",
	{
		name => 'agro_subjects',
		type => 'compound',
		fields => [
			{
				sub_name => 'authority',
				type => 'longtext',
			},
			{
				sub_name => 'text_value',
				type => 'longtext',
			},
		],
		multiple => 1,
		render_value => 'render_ontology_multiple_output',
		render_input => 'render_ontology_input',
	}

);

sub checkAgroCache { # Find and return the cached agro term if it exists
		
	my ($session, $uri, $thesaurus, $language) = @_;

	#test that parameters have values
	return undef if (
		!defined $uri
		|| !defined $thesaurus
		|| !defined $language
	);

	my $db = $session->database;
	my $res = undef; # Stores the query result after disconnect
	
	my $cmd = $db->prepare_select( 'SELECT * FROM eprint_agro_cache WHERE uri=? AND thesaurus=? AND language=?' );
	$cmd->execute($uri, $thesaurus, $language);
	my $row = $cmd->fetchrow_hashref;
	if(defined $row)
	{
		my $date_created = $row->{date_created};
		my $cacheValidity = $session->config( "agro_cache_validity" );

		#test for cache timeout
		if($date_created + $cacheValidity > time())
		{
			$res = $row->{text_value};
		}
	}

	return $res;
}

sub saveToAgroCache { # Store a new agro term in the cache

	my ($session, $uri, $thesaurus, $language, $text_value) = @_;

        if(defined $uri and defined $thesaurus and defined $language and defined $text_value)
        {
                my $db = $session->database;
		$db->delete_from( "eprint_agro_cache", ["uri", "thesaurus", "language", "text_value"], [$uri, $thesaurus, $language, $text_value] );
		$db->insert( "eprint_agro_cache", ["uri", "thesaurus", "language", "text_value", "date_created"], [$uri, $thesaurus, $language, $text_value, time()] );
        }
}

$c->{render_ontology_multiple_output} = sub
{
	my ($session, $field, $value) = @_;

	require HTTP::Request;         # for http requests
	require LWP::UserAgent;        # 
	my $ua = LWP::UserAgent->new;  # 
	
	require EPrints::XML::DOM;
	
#	use XML::DOM::XPath; # Should be used in future versions to make the package more robust
	
	my $uri = $session->config( "agro_ontology_broker_uri" ); # Get the broker URI

	my $parentElem = $session->make_element( "div", class=>"agricultural-terms" ); # Root element to be returned to the EPrints for rendering

	my $count = 0;
        for($count = 0; $count < scalar(@{$value}); $count++)
        {
		my @temp = split( /\|\|/, @{$value}[$count]->{"authority"} ); # Temp stores the authority string after splitting the thesaurus from the URI
		my $termUri = '';
		
                my $term = $session->make_element( "p", class=>"agricultural-term" );
	
		if($temp[0] =~ /[\/\\:]([^\/\\:]*)$/) # extract the last bit of the uri as the ontology plugin requires it for searching for the term in a specific language
		{
			$termUri = "$1";

			my $cachedTerm = checkAgroCache( $session, $termUri, $temp[1], $session->get_langid() );
			
			if(defined $cachedTerm) # If conecept is in cache
			{
				$term->appendChild( $session->make_text( $cachedTerm ) );
			}
			else
			{
				my $request = HTTP::Request->new( "GET", $uri.$temp[1]."/concept?uri=".$termUri ); #
		        	$request->header( 'Accept-Language' => $session->get_langid() );		   # HTTP request to the broker
				my $response = $ua->request( $request );					   #
			
				my $domTemp = undef;								   #
				my $parser1 = new XML::DOM::Parser;						   # Parse XML response
				eval { $domTemp = $parser1->parse( $response->content ); }; warn $@ if $@;	   #

				my $termFromXML = ""; # The term text value as retreived from the broker

				my $done = 0; #indicates weather a value has been found in hte xml response from the broker
				if(defined $domTemp) # If parsing is successful, look for the term text
				{
					my @tempElemList = $domTemp->getElementsByTagName( "skos:prefLabel" );	#
					my $tempElem = $tempElemList[0] if @tempElemList;			#
					if( defined $tempElem )							# IMPORTANT: We have not used XPath here even though it is more appropriate because the XPath library
					{									# in EPrints has problems dealing with XML namespaces. XPath would make this package more robust
						foreach( $tempElem->getChildNodes )				#
						{								#
                                			$term->appendChild( $session->make_text( $_->getNodeValue ) );
							$termFromXML .= $_->getNodeValue;
						}
						$done = 1;
					}
				}
				if(not defined $domTemp or not $done) # Display error in case it occures showing the XML response from the broker and the error message from parser
				{
					$term->appendChild( $session->make_text( "Could not parse xml from the broker. Please check the broker or the connection with the broker. ".$@."\nresponse-xml from broker:".$response->content ) );
				}
				saveToAgroCache( $session, $termUri, $temp[1], $session->get_langid(), $termFromXML ); # Save concept to cache
			}
			$parentElem->appendChild( $term );
		}
	}
	return $parentElem;
};

$c->{render_ontology_input} = sub
{
	my( $field, $session, $current_value, $dataset, $staff, $hidden_fields, $object, $basename ) = @_;
	
	my $domElem = $session->make_element( "table", border=>"0", cellpadding=>"0", cellspacing=>"0", class=>"ep_form_input_grid" );  # Field container
	my $tbody = $session->make_element( "tbody" );											#
	
	my $brokerInterfaceUri = $session->config( "broker_interface_uri" );

	my $basenameInputHidden = $session->make_element( "input", type=>"hidden",class=>"basename", value=>$basename, name=>$basename."_hidden" ); # Used in JavaScript to determine the name of the field
	my $brokerInterfaceUriInputHidden = $session->make_element( "input", type=>"hidden",class=>"broker-interface-uri", value=>$brokerInterfaceUri, name=>$brokerInterfaceUri."_hidden" ); # Used in JavaScript to determine the name of the field

	$domElem->appendChild( $basenameInputHidden );
	$domElem->appendChild( $brokerInterfaceUriInputHidden );
	$domElem->appendChild( $tbody );

	my $trHeader = $session->make_element( "tr" ); # Header row
	$tbody->appendChild( $trHeader );

	my $emptyTh = $session->make_element( "th", class=>"empty_heading", id=>$basename."_th_0" ); # Headers
	$trHeader->appendChild( $emptyTh );

        my $th1 = $session->make_element( "th", id=>$basename."_th_1" );
	$th1->appendChild( $session->make_text( $session->phrase( "eprint_fieldname_agro_subjects_authority" ) ) );
	$trHeader->appendChild( $th1 );

        my $th2 = $session->make_element( "th", id=>$basename."_th_2" );
	$th2->appendChild( $session->make_text( $session->phrase( "eprint_fieldname_agro_subjects_text_value" ) ) );
        $trHeader->appendChild( $th2 );

	$tbody->appendChild( $trHeader );

	my $count = 0;	
	for($count = 0; $count < scalar(@{$current_value}); $count++) # Foreach value in the field, render a new entry. We use citation files
	{
		my $tr1 = $session->make_element( "tr" );
		$tbody->appendChild( $tr1 );
		
		$tr1->appendChild( $object->render_citation( "agro_field_entry", ( text_value=> [@{$current_value}[$count]->{"text_value"} , "STRING"],
										   authority=> [@{$current_value}[$count]->{"authority"}, "STRING"],
										   row=> [ $count, "STRING" ],
										   basename=> [ $basename, "STRING" ] ), undef ) );
	}
        
        if($count == 0)
        {
		my $tr1 = $session->make_element( "tr" );
                $tbody->appendChild( $tr1 );
		
		$tr1->appendChild( $object->render_citation( "agro_field_entry", ( text_value=> [ '' , "STRING"],
                                                                                   authority=> [ '', "STRING"],
                                                                                   row=> [ 0, "STRING" ],
                                                                                   basename=> [ $basename, "STRING" ] ), undef ) );
        }

	my $spaces = $session->make_element( "input", value=>$count, type=>"hidden", name=>$basename."_spaces" ); # A filed that holds the number of spaces (values) to be stored in this multiple field
	$tbody->appendChild( $spaces );

	my $tr2 = $session->make_element( "tr" );
	$tbody->appendChild( $tr2 );

	my $td3 = $session->make_element( "td", valign=>"top", id=>$basename."_cell_1_".$count );	
	my $tdOffset = $session->make_element( "td", valign=>"top", id=>$basename."_cell_0_".$count );
	$tr2->appendChild( $tdOffset );
	$tr2->appendChild( $td3 );

	my $input = $session->make_element( "input", name=>"_internal_".$basename, value=>$session->phrase( "open_ontology_overlay" ), type=>"button", class=>"ep_form_action_button show-overlay", onclick=>"show_overlay();"  ); # This button creates an iframe that displays the broker's interface
	$td3->appendChild( $input );

	$domElem->appendChild( $session->make_element( "script", type=>"text/javascript", src=>"/javascript/ontology_overlay.js") );
		
	return $domElem;
};
