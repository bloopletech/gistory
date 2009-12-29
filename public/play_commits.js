var playbackDirection = 'forward';

function initializePlayback()
{
  // TODO
}

function showHunk(index)
{
  console.log("Playing for " + index);
  hunks[index].action();
}

function showNextHunk(index)
{
  console.log("Playing next for " + index);
  if(playbackDirection == 'forward')
  {
    if(index < hunks.length) showHunk(index + 1);
  }
  else
  {
    if(index > 0) showHunk(index - 1);
  }
}