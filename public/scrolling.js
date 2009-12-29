//TODO: This is a copy and paste from script.aculo.us
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

function blindDistance(element)
{
  return element.getDimensions().height;
}

function blindDuration(obj)
{
  return blindDistance(obj) / (diffContentFontSize * linesPerSecondForChanges);
}

function timeoutForAction(callback)
{
  return (function()
  {    
    setTimeout(function()
    {
      callback();
    }, 3 * (1000 / linesPerSecondForChanges));
  });
}

function scrollToDistance(element, scrollOffset)
{
  return Math.abs(document.viewport.getScrollOffsets().top - $(element).cumulativeOffset()[1] + scrollOffset);
}

function scrollOffsetForObject(obj)
{
  console.log(obj);
  var scrollOffset = -(diffContentFontSize * 3) - $('header').getHeight();
  if((obj.cumulativeOffset()[1] + scrollOffset) < 0) scrollOffset = -(obj.cumulativeOffset()[1]);
//  if(scrollOffset < 0) scrollOffset = 0; // Dumb

  return scrollOffset;
}

function scrollToObject(obj, callback)
{
  var scrollOffset = scrollOffsetForObject(obj);
  var duration = (scrollToDistance(obj, scrollOffset) / (diffContentFontSize * linesPerSecondForScrolls));

  if((scrollToDistance(obj, scrollOffset)) <= 0)
  {
    scrollOffset = 0;
    duration = 0;
  }

  Effect.ScrollTo(obj, { duration: duration, offset: scrollOffset, afterFinish: callback });
}
