// jquery functions for rowcounts
$(document).ready(function(){
	$('#loading').hide();
});


function toggle_table(e, table_id) {
	$.post('/tables', {table_id: table_id});
	$('#' + table_id).toggleClass('ok err');
	if ($(e).val() == 'enable') {
		$(e).val('disable');
	} 
	else {
		$(e).val('enable');
	}	
}

function toggle_feed(e, feed_id) {
	$.post('/feeds', {feed_id: feed_id});
	$('#' + feed_id).toggleClass('ok err');
	
	if ($(e).val() == 'enable') {
		$(e).val('disable');
	} 
	else {
		$(e).val('enable');
	}	
}

function refresh_counts(e, table_id, server_id) {
	$(e).val('loading...');
	$(e).attr('disabled', true);
	var $row = $(e).closest('tr');
	$row.removeClass('ok err');
	$row.addClass('wait');
	$.post('/counts_json', {table_id: table_id, server: server_id})
		.done(function (data) {
			var obj = jQuery.parseJSON(data);
			$('#count1_' + table_id).html(obj.rc1);
			$('#count2_' + table_id).html(obj.rc2);
			$('#diff_' + table_id).html(obj.diff);
			$(e).val('refresh');
			$(e).attr('disabled', false);
			$row.removeClass('wait');
			if (obj.diff == 0) {
				$row.toggleClass('ok');
			}
			else {
				$row.toggleClass('err');
			}
		}, 'json');
}

function run_counts(e) {
	$(e).val('loading...');
	$(e).attr('disabled', true);
	$('#results').hide();
	$('#loading').show();
	$.post('/counts_json2', {server_id: $('#server_select').val(), feed_id: $('#feed_select').val()})
		.done(function (data) {
			$(e).val('Run Now');
			$(e).attr('disabled', false);
			$('#loading').hide();
			$('#results').html(data);
			$('#results').show();
	});
}