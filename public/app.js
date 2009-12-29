var diffContentFontSize = 0;
var queue = [];
var hunks = [];
var firstCommitPlayTriggered = false;

//Queue functions
function runNextInQueue()
{
  if(queue.length > 0) (queue.shift())(); 
}

document.observe("dom:loaded", function()
{
  diffContentFontSize = $('diff_first_line').getHeight();
});
