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

$c->{render_ontology_multiple_output} = sub
{
	my ($session, $field, $value) = @_;

	require HTTP::Request;         #for http requests
	require LWP::UserAgent;        #//
	my $ua = LWP::UserAgent->new;  #//
	
	use XML::Parser;
	
	my $uri = $session->config('agro_ontology_broker_uri');
	my $parser = new XML::Parser(Style => 'Tree');

	my $parentElem = $session->make_element( "div", class=>"agricultural-terms" );	

	my $count = 0;
        for($count = 0; $count < scalar(@{$value}); $count++)
        {
		my @temp = split( /\|\|/, @{$value}[$count]->{"authority"} ); #Temp stores the authority string after splitting the thesaurus from the URI
		my $termUri = '';
		
                my $term = $session->make_element( "p", class=>"agricultural-term" );
	
		if(@temp[0] =~ /[\/\\:]([^\/\\:]*)$/)
		{
			$termUri = "$1";

			my $request = HTTP::Request->new( "GET", $uri.@temp[1]."/concept?uri=".$termUri);
		        $request->header( 'Accept-Language' => $session->get_langid() );
			my $response = $ua->request( $request );
			
			my @parsed = undef;
			eval { @parsed = $parser->parse($response->content); }; warn $@ if $@;
			
			if(defined @parsed and defined @parsed[0] and defined @{@parsed[0]}[1] and defined @{@{@parsed[0]}[1]}[4] and defined @{@{@{@parsed[0]}[1]}[4]}[4] and defined @{@{@{@{@parsed[0]}[1]}[4]}[4]}[2])
			{
				$term->appendChild( $session->make_text( @{@{@{@{@parsed[0]}[1]}[4]}[4]}[2] ) );
				$parentElem->appendChild( $term );
			}
		}
	}
	return $parentElem;
};

$c->{render_ontology_input} = sub
{
	my( $field, $session, $current_value, $dataset, $staff, $hidden_fields, $object, $basename ) = @_;
	
	my $domElem = $session->make_element( "table", border=>"0", cellpadding=>"0", cellspacing=>"0", class=>"ep_form_input_grid" );
	my $tbody = $session->make_element( "tbody" );
	
	my $basenameInputHidden = $session->make_element( "input", type=>"hidden",class=>"basename", value=>$basename, name=>$basename."_hidden" );

	$domElem->appendChild( $basenameInputHidden );

	$domElem->appendChild( $tbody );
	

	my $trHeader = $session->make_element( "tr" );
	$tbody->appendChild( $trHeader );
	my $emptyTh = $session->make_element( "th", class=>"empty_heading", id=>$basename."_th_0" );
	$trHeader->appendChild( $emptyTh );

        my $th1 = $session->make_element( "th", id=>$basename."_th_1" );
	$th1->appendChild( $session->make_text( "Authority" ) );
	$trHeader->appendChild( $th1 );

        my $th2 = $session->make_element( "th", id=>$basename."_th_2" );
	$th2->appendChild( $session->make_text( "Term" ) );
        $trHeader->appendChild( $th2 );

	$tbody->appendChild( $trHeader );

	my $count = 0;	
	for($count = 0; $count < scalar(@{$current_value}); $count++)
	{
		my $tr1 = $session->make_element( "tr" );
		$tbody->appendChild( $tr1 );
		
		my $numTd = $session->make_element( "td", valign=>"top", id=>$basename."_cell_0_".$count, class=>"ep_form_input_grid_pos" );
		$tr1->appendChild( $numTd );

		$numTd->appendChild( $session->make_text( ($count + 1).". " ) );	
	
		my $td1 = $session->make_element( "td", valign=>"top", id=>$basename."_cell_1_".$count );
		$tr1->appendChild( $td1 );
		
		my $input1 = $session->make_element( "input", value=>@{$current_value}[$count]->{"authority"}, onkeypress=>"return EPJS_block_enter( event )", name=>$basename."_".($count + 1)."_authority", id=>$basename."_".($count + 1)."_authority", type=>"text", class=>"ep_form_text ep_eprints_ontology", size=>"25", readonly=>"true" );
	
		my $td2 = $session->make_element( "td", valign=>"top", id=>$basename."_cell_2_".$count );
		$tr1->appendChild( $td2 );

		my $input2 = $session->make_element( "input", value=>@{$current_value}[$count]->{"text_value"}, onkeypress=>"return EPJS_block_enter( event )", name=>$basename."_".($count + 1)."_text_value", id=>$basename."_".($count + 1)."_text_value", type=>"text", class=>"ep_form_text ep_eprints_ontology", size=>"25", readonly=>"true" );


		my $delTd = $session->make_element( "td", valign=>"top", id=>$basename."_cell_3_".$count );
		$tr1->appendChild( $delTd );
		
		my $delInput = $session->make_element( "a", name=>$basename."_del_".($count + 1), id=>$basename."_del_".($count + 1), type=>"image", href=>"javascript:", title=>"Remove Item",src=>"/style/images/minus.png", class=>"epjs_ajax", onclick=>"removeTerm(".($count + 1).")" ); 
		my $delImg = $session->make_element( "img", src=>"/style/images/delete.png" );
		
		$delTd->appendChild( $delInput );
		$delInput->appendChild( $delImg );

		$td1->appendChild( $input1 );
		$td2->appendChild( $input2 );
	}
        
        if($count == 0)
        {
		my $tr1 = $session->make_element( "tr" );
                $tbody->appendChild( $tr1 );

                my $numTd = $session->make_element( "td", valign=>"top", id=>$basename."_cell_0_".$count, class=>"ep_form_input_grid_pos" );
                $tr1->appendChild( $numTd );

                $numTd->appendChild( $session->make_text( ($count + 1).". " ) );

                my $td1 = $session->make_element( "td", valign=>"top", id=>$basename."_cell_1_".$count );
                $tr1->appendChild( $td1 );

                my $input1 = $session->make_element( "input", onkeypress=>"return EPJS_block_enter( event )", name=>$basename."_".($count + 1)."_authority", id=>$basename."_".($count + 1)."_authority", type=>"text", class=>"ep_form_text ep_eprints_ontology", size=>"25" );

                my $td2 = $session->make_element( "td", valign=>"top", id=>$basename."_cell_2_".$count );
                $tr1->appendChild( $td2 );

                my $input2 = $session->make_element( "input", onkeypress=>"return EPJS_block_enter( event )", name=>$basename."_".($count + 1)."_text_value", id=>$basename."_".($count + 1)."_text_value", type=>"text", class=>"ep_form_text ep_eprints_ontology", size=>"25" );


                my $delTd = $session->make_element( "td", valign=>"top", id=>$basename."_cell_3_".$count );
                $tr1->appendChild( $delTd );

                my $delInput = $session->make_element( "a", name=>$basename."_del_".($count + 1), id=>$basename."_del_".($count + 1), type=>"image", href=>"javascript:", title=>"Remove Item",src=>"/style/images/minus.png", class=>"epjs_ajax", onclick=>"removeTerm(".($count + 1).")" );
                my $delImg = $session->make_element( "img", src=>"/style/images/delete.png" );

                $delTd->appendChild( $delInput );
                $delInput->appendChild( $delImg );

                $td1->appendChild( $input1 );
                $td2->appendChild( $input2 );
        }

	my $spaces = $session->make_element( "input", value=>$count, type=>"hidden", name=>$basename."_spaces" );
	$tbody->appendChild( $spaces );

	my $tr2 = $session->make_element( "tr" );
	$tbody->appendChild( $tr2 );

	my $td3 = $session->make_element( "td", valign=>"top", id=>$basename."_cell_1_".$count );	
	my $tdOffset = $session->make_element( "td", valign=>"top", id=>$basename."_cell_0_".$count );
	$tr2->appendChild( $tdOffset );
	$tr2->appendChild( $td3 );

	my $input3 = $session->make_element( "input", name=>"_internal_".$basename, value=>"Lookup Terms", type=>"button", class=>"ep_form_action_button show-overlay", onclick=>"show_overlay();"  );
	$td3->appendChild( $input3 );

	$domElem->appendChild( $session->make_element( "script", type=>"text/javascript", src=>"/javascript/ontology_overlay.js") );
		
	return $domElem;
};
