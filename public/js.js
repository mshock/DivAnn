// jquery functions for rowcounts

$(function() {
});

function toggle_table(table_id) {
	$.post('/tables', {table_id: table_id});
	$('#' + table_id).toggleClass('ok err');
	button = $('#' + table_id + '_button');
	if (button.val() == 'enable') {
		button.val('disable');
	} 
	else {
		button.val('enable');
	}	
}