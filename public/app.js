Effect.ScrollToBottom = function(element)
{
  var options = arguments[1] || { },
  scrollOffsets = document.viewport.getScrollOffsets(),
  elementOffsets = $(element).cumulativeOffset()[1] + $(element).getHeight();

  if (options.offset) elementOffsets[1] += options.offset;

  if(elementOffsets == scrollOffsets.top) return;
/*  console.log($(element).cumulativeOffset()[1]);
  console.log($(element).getHeight());
  console.log(scrollOffsets.top);
  console.log(elementOffsets);*/
  return new Effect.Tween(null,
    scrollOffsets.top,
    elementOffsets,
    options,
    function(p){ scrollTo(scrollOffsets.left, p.round()); }
  );
};

function scrollToDistance(element, scrollOffset)
{
  return Math.abs($(element).cumulativeOffset()[1] + scrollOffset - document.viewport.getScrollOffsets().top);
}

function blindDistance(element)
{
  return element.getDimensions().height;
}

var diffContentFontSize = 0;

document.observe("dom:loaded", function()
{
  diffContentFontSize = parseFloat($('diff_content').getStyle("fontSize"));
  new Ajax.Request("/commit/0", { method: 'get' });
});