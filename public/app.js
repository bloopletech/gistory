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

var diffContentFontSize = 0;
var queue = [];

function blindDistance(element)
{
  return element.getDimensions().height;
}

function blindDuration(obj)
{
  return blindDistance(obj) / (diffContentFontSize * linesPerSecondForChanges);
}

//Queue functions
function runNextInQueue()
{
  if(queue.length > 0) (queue.shift())(); 
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

//Scrolling functions
function scrollToDistance(element, scrollOffset)
{
  return Math.abs(document.viewport.getScrollOffsets().top - $(element).cumulativeOffset()[1] + scrollOffset);
}

function scrollOffsetForObject(obj)
{
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

//  console.log("issuing a scroll to obj ", obj, ", offset to obj ", obj.cumulativeOffset(), " offset by ", scrollOffset,
//   "px taking ", duration, "seconds, total page height", $$("body")[0].getHeight(), "px");

  Effect.ScrollTo(obj, { duration: duration, offset: scrollOffset, afterFinish: callback });
}


//Commit functions
function addHunk(startIndex, lines)
{
  $("diff").setStyle({ 'paddingTop': $('header').getHeight() + "px" });
  queue.push(function()
  {
    var wrapper = (new Element('div')).update(lines).hide();
    var insertPoint = $('diff_content').down(startIndex - 1);

    scrollToObject(insertPoint, function()
    {
      insertPoint.insert({ 'after': wrapper });

      wrapper.blindDown({ duration: blindDuration(wrapper), afterFinish: function()
      {
        wrapper.replace(wrapper.innerHTML);
        (timeoutForAction(runNextInQueue))();
      } });

      if(blindDistance(wrapper) > document.viewport.getHeight())
      {
        //console.log("issuing a scroll to bottom for an add, taking ", [blindDuration - 0.5, 0].max(), " seconds, with a delay of ", (blindDistance(wrapper) - 0.5 < 0 ? 0 : 0.5), " seconds");
        Effect.ScrollToBottom(wrapper, { duration: [blindDuration(wrapper) - 0.5, 0].max(), delay: (blindDistance(wrapper) - 0.5 < 0 ? 0 : 0.5) });
      }
    });
  });
}

function removeHunk(startIndex, lineCount)
{
  $("diff").setStyle({ 'paddingTop': $('header').getHeight() + "px" });
  queue.push(function()
  {
    var removePoint = new Element('div');
    $('diff_content').down(startIndex).insert({ 'before': removePoint });

    for(var i = 0; i < lineCount; i++) removePoint.insert({ 'bottom': $('diff_content').immediateDescendants()[startIndex + 1] });

    scrollToObject(removePoint, timeoutForAction(function()
    {
      removePoint.blindUp({ duration: blindDuration(removePoint), afterFinish: timeoutForAction(function()
      {
        removePoint.remove();
        if(queue.length > 0) (queue.shift())();
      }) });
    }));
  });
}

document.observe("dom:loaded", function()
{
  diffContentFontSize = $('diff_first_line').getHeight();
  new Ajax.Request("/commit/0", { method: 'get' });
});