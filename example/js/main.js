/* Copyright (c) 2016-2018 Molly White */
/* MIT License */
/* Source: https://github.com/molly/wikimedia-timeline */

$( document ).ready( function() {
  $("html").removeClass("no-js");
  $("input:checkbox[name=filter]").click(hideUnchecked);
  $("input:checkbox#all").click(checkAll);
  reflowEntries();
});

function hideUnchecked() {
  var $checkedBoxes = $('input:checkbox[name=filter]:checked');
  if ($checkedBoxes.length > 0) {
    $('input:checkbox#all').prop('checked', false);
  }

  var filterIds = [];
  $checkedBoxes.each(function() {
    filterIds.push(this.id);
  });

  var $timelineEntry = $('.timeline-entry');
  $timelineEntry.each(function() {
    var $this = $(this);
    if (!hasOverlap($this.data('category'), filterIds)) {
      $this.hide();
    } else {
      $this.show();
    }
  });

  reflowEntries();
}

function checkAll() {
  $('input:checkbox[name=filter]').prop("checked", true);
  $('.timeline-entry').each(function() {
    $(this).show();
  });
  reflowEntries();
}

function hasOverlap(categories, ids) {
  return ids.some(function (id) {
    return categories.indexOf(id) >= 0;
  });
}

function reflowEntries() {
  $('.timeline-entry').removeClass("odd even first");
  $('.timeline-entry:visible:first').addClass("first");
  $('.timeline-entry:visible:odd').addClass("odd");
  $('.timeline-entry:visible:even').addClass("even");
}
