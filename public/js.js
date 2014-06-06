// jquery functions for rowcounts
$(document).ready(function(){
	$('#loading').hide();

    $("#res_table").tablesorter();
    
    $('#server_select').change(
    		function() {
    			e = this;
				$.post('/get_feeds', {server_id: $(e).val()})
					.done(function (data) {
						$('#feed_select').html(data);
					});
    		});
    $('#server_select2').change(
    		function() {
    			e = this;
				$.post('/get_feeds2', {server_id: $(e).val()})
					.done(function (data) {
						$('#feed_table').html(data);
					});
    		});
    $('#feed_select2').change(
    		function() {
    			e = this;
				$.post('/get_tables', {feed: $(e).val()})
					.done(function (data) {
						$('#tables_table').html(data);
					});
    		});
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

function export_results() {
	var csv = [];
	$('#res_table tr').each(function (index, tr) {
		if (index == 0) return;
		var line = $('td', tr).map(function(index, td){
			if (index == 4) return;
			return $(td).text();
		});
		csv.push([line[0], line[1], line[2], line[3]].join(',') + "\n");
	});
	
	window.URL = window.webkitURL || window.URL;
	var contentType = 'text/csv';
	var csvFile = new Blob(csv, {type: contentType});
	var a = document.createElement('a');
	var filename = $('#update').text() + '_' + $('#feed_select option:selected').text();
	filename = filename.replace(/\s/g,'');
	a.download = filename + '.csv';
	a.href = window.URL.createObjectURL(csvFile);
	a.textContent = 'Download CSV';
	a.dataset.downloadurl = [contentType, a.download, a.href].join(':');
	document.body.appendChild(a);
	$(a).hide();
	a.click();
}

