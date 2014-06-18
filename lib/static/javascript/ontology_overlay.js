var $overlay_wrapper;
var $overlay_panel;
var $chosenTermsHashTable = {};

document.observe('dom:loaded', function() {
    agroBasename = $$('.basename')[0].value;
    num = parseInt($$('[name=' + agroBasename + '_spaces]')[0].value);

    for(i = 1; i <= num; i++)
    {
        $chosenTermsHashTable[$$('[name=' + agroBasename + '_' + i + '_authority]')[0].value + $$('[name=' + agroBasename + '_' + i + '_text_value]')[0].value] = 1;
    }
});
function show_overlay() {
    if ( !$overlay_wrapper ) append_overlay();
    document.getElementById('ontology-overlay').style.display = "block";
}

function hide_overlay() {
    document.getElementById('ontology-overlay').style.display = "none";
}

function append_overlay() {
    var pageToShow;

    $overlay_wrapper = $(document.body).insert('<div id="ontology-overlay"></div>');
    $overlay_panel = $$('#ontology-overlay')[0].insert('<div id="overlay-panel"></div>');

    brokerInterfaceUri = $$('.broker-interface-uri')[0].value;

    $$('#overlay-panel')[0].insert('<iframe frameborder="0" scrolling="auto" height="100%" width="100%" style="float:middle" src="' + brokerInterfaceUri + '?thesauri=asfa,agrovoc,plant,nerc&callback=callbackSaveResults"></iframe> <a href="#" class="white-background hide-overlay" style="display:block">Close</a>' );

    attach_overlay_events();
}

function attach_overlay_events() {
    $$('#ontology-overlay A.hide-overlay')[0].observe('click', function(ev) {
        Event.stop(ev);
        hide_overlay();
    });
}

function removeTerm(item) {
    num = parseInt($$('[name=' + agroBasename + '_spaces]')[0].value);
    
    if(num > 0)
    {
        $chosenTermsHashTable[$$('[name=' + agroBasename + '_' + item + '_authority]')[0].value + $$('[name=' + agroBasename + '_' + item + '_text_value]')[0].value] = 0;
        $$('[name=' + agroBasename + '_spaces]')[0].value = (num - 1) + "";
    }
    
    if(num > 1)
    {
        for(var i=item; i < num; i++) {
            var string = $$('[name=' + agroBasename + '_' + i + '_authority]')[0].value = $$('[name=' + agroBasename + '_' + (i + 1) + '_authority]')[0].value;
            var string = $$('[name=' + agroBasename + '_' + i + '_text_value]')[0].value = $$('[name=' + agroBasename + '_' + (i + 1) + '_text_value]')[0].value;
        }
        $$('[name=' + agroBasename + '_' + num + "_authority]")[0].up(1).remove();
    }
    else
    {
        $$('[name=' + agroBasename + '_1_authority]')[0].value = '';
        $$('[name=' + agroBasename + '_1_text_value]')[0].value = '';
    }
}

window.addEventListener("message", function (list){

    added = 0;
    //$$('.ep_form_input_grid_pos').each(function(e){e.up(0).remove()});
    curNum = parseInt($$('[name=' + agroBasename + '_spaces]')[0].value);

    var i = 0;
    if(curNum == 0 && list.data.length != 0)
    {
        i = i + 1;
        added = added + 1;
        $$('[name=' + agroBasename + '_1_authority]')[0].value = list.data[0].authority + "||" + list.data[0].thesaurus;
        $$('[name=' + agroBasename + '_1_text_value]')[0].value = list.data[0].text_value;
        $chosenTermsHashTable[list.data[0].authority + "||" + list.data[i].thesaurus + list.data[0].text_value] = 1;
    }

    for(i; i < list.data.length; i++) {
        if($chosenTermsHashTable[list.data[i].authority + "||" + list.data[i].thesaurus + list.data[i].text_value] == undefined || $chosenTermsHashTable[list.data[i].authority + "||" + list.data[i].thesaurus + list.data[i].text_value] == 0)
        {
            added += 1;
            tempTextBox1 = new Element('input', {name: agroBasename + "_" + (curNum + added) + "_authority", id: agroBasename + "_" + (curNum + added) + "_authority", type: 'text', size:'25', class:'ep_form_text ep_eprints_ontology', onkeypress:"return EPJS_block_enter( event )", readonly: "true"});
            tempTextBox2 = new Element('input', {name: agroBasename + "_" + (curNum + added) + "_text_value", id: agroBasename + "_" + (curNum + added) + "_text_value", type: 'text', size:'25', class:'ep_form_text ep_eprints_ontology', onkeypress:"return EPJS_block_enter( event )", readonly: "true"});

            tempTableRow = new Element('tr');
	    tempNumCell = new Element('td', {valign: "top", id: agroBasename + "_cell_0_" + (curNum + added - 1), class: "ep_form_input_grid_pos"});
	    tempNumCell.innerHTML = (curNum + added) + ". ";
	    tempTableCell1 = new Element('td', {valign: "top", id: agroBasename + "_cell_1_" + (curNum + added - 1)});
	    tempTableCell2 = new Element('td', {valign: "top", id: agroBasename + "_cell_2_" + (curNum + added - 1)});
            tempDelCell = new Element('td', {valign: "top", id: agroBasename + "_cell_3_" + (curNum + added - 1)});
	    tempDelButton = new Element('a', {name: agroBasename + "_del_" + (curNum + added), id: agroBasename + "_del_" + (curNum + added), type: "image", href: "javascript:", title: "Remove Item", src: "/style/images/delete.png", class: "epjs_ajax", onclick: "removeTerm(" + (curNum + added) + ")"});
            tempDelImage = new Element('img', {src: "/style/images/delete.png"});
        
            tempDelCell.insert(tempDelButton);
	    tempDelButton.insert(tempDelImage);

            tempTableCell1.insert(tempTextBox1);
            tempTableCell2.insert(tempTextBox2);

	    tempTableRow.insert(tempNumCell);
	    tempTableRow.insert(tempTableCell1);
	    tempTableRow.insert(tempTableCell2);
            tempTableRow.insert(tempDelCell);

            tempTextBox1.value = (list.data[i].authority + "||" + list.data[i].thesaurus);
            tempTextBox2.value = (list.data[i].text_value);

            $$('.ep_form_input_grid > tbody > *').last().insert({before: tempTableRow});

            $chosenTermsHashTable[list.data[i].authority + list.data[i].text_value] = 1;
        }
    }
    /*
    if(list.data.length == 0) {
        tempTextBox = new Element('input', {name: basename + "_1", id: basename + "_1", type: 'text', size:'60', class:'ep_form_text ep_eprints_ontology', onkeypress:"return EPJS_block_enter( event )"});
        tempTableRow = new Element('tr');
	tempTableCell = new Element('td', {valign: "top", id: basename + "_cell_0_1"});
	tempTableCell.insert(tempTextBox);
        tempTableRow.insert(tempTableCell);

        $$('.ep_form_input_grid > tbody > *').last().insert({before: tempTableRow});
 
    }*/
    $$('input[name=' + agroBasename + '_spaces]')[0].value = added + curNum;
    
    hide_overlay();
});

