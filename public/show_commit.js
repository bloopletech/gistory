function setCommitMetadata(commit)
{
  $('commit_index').innerHTML = commit['index'] + 1;
  $('commit_message').innerHTML = commit['message'];
  $('committer_author_details').innerHTML = commit['author_details'];
  $('committer_date_time').innerHTML = commit['date_time'];
  $('diff_message').innerHTML = commit['diff_message'];
}

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

      console.log(wrapper);
      console.log(wrapper.viewportOffset().top + ", " + blindDistance(wrapper) + ", " + (wrapper.viewportOffset().top + blindDistance(wrapper)) + ", " + document.viewport.getHeight());
      //TODO: bug here if adding a few lines at end of file, should issue a scroll down here but doesn't
      if((wrapper.viewportOffset().top + blindDistance(wrapper)) > document.viewport.getHeight())
      {
        //console.log("issuing a scroll to bottom for an add, taking ", [blindDuration - 0.5, 0].max(), " seconds, with a delay of ", (blindDistance(wrapper) - 0.5 < 0 ? 0 : 0.5), " seconds");
        Effect.ScrollToBottom(wrapper, { duration: [blindDuration(wrapper) - 0.5, 0].max(), delay: (blindDistance(wrapper) - 0.5 < 0 ? 0 : 0.5) });
      }

      wrapper.blindDown({ duration: blindDuration(wrapper), afterFinish: function()
      {
        wrapper.replace(wrapper.innerHTML);
        (timeoutForAction(runNextInQueue))();
      } });

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
