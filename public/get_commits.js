document.observe("dom:loaded", function()
{
  new Ajax.Request("/commits", { method: 'get', onComplete: function()
  {
    initializePlayback();
    if(hunks.length > 0) showHunk(0);
    // initialize the seek bar with number of commits, and graphs etc.
    // start playing
  } });
});