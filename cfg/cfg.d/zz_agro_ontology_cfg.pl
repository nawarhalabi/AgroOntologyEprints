$c->{agro_ontology_broker_uri} = 'http://waisvm-nh1g12.ecs.soton.ac.uk:8080/thesaurussearch/';
$c->{broker_interface_uri} = 'http://waisvm-nh1g12.ecs.soton.ac.uk:8080/ontplugin-demo/collapseablePages.html';
$c->{agro_cache_validity} = 31556926; # Cache validity in seconds. Warning, setting this value to a low value might cause problems when refreshing abstracts as recreating abstracts requires sending http requests to the broker in bulk

#prehaps scan the array and insert it next to subjects, but remember, subjects may not be there...
unshift @{$c->{summary_page_metadata}}, 'agro_subjects';

