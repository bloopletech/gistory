require 'rack'

module Kernel
  def h(str)
    Rack::Utils.escape_html(str)
  end
end

class String
  def ucfirst
    out = self
    out[0] = out[0..0].upcase if length > 0
    out
  end
end
