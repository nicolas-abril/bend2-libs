import Base
import ../xml.bend as XML

def main() -> IO(Unit):
  IO.print(XML.serialize(XML.parse("<svg><title>A &amp; B &#x1f600;</title><text x='1'>one<tspan>two</tspan>three &lt; four</text><rect id='a&amp;b'/></svg>")))

#|<svg><title>A &amp; B 😀</title><text x="1">one<tspan>two</tspan>three &lt; four</text><rect id="a&amp;b"></rect></svg>
