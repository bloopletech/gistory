document.observe("dom:loaded", function()
{
  new Ajax.Request("/commit/0", { method: 'get' });
});