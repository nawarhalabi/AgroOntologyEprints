$c->{agro_ontology_broker_uri} = 'http://waisvm-nh1g12.ecs.soton.ac.uk:8080/thesaurussearch/nerc/concept?uri=4_2';

#prehaps scan the array and insert it next to subjects, but rememner, subjects may not be there...
unshift @{$c->{summary_page_metadata}}, 'agro_subjects';

