
require_relative './lib'


# RSpec.describe :convert_url_to_filename do
#
#     it "works with various inputs" do
#
#       expect(convert_url_to_filename('http://a/b/c')).to eql 'c'
#       expect(convert_url_to_filename('http://a/b/c.mpeg')).to eql 'c.mpeg'
#
#       expect(convert_url_to_filename('http://www.wntk.com/wntk.m3u')).to eql 'wntk.m3u'
#       expect(convert_url_to_filename('http://stream.abacast.net/playlist/entercom-wrkoammp3-64.m3u')).to eql 'entercom-wrkoammp3-64.m3u'
#
#     end
#
# end


RSpec.describe :url_filename do

    it "works with various inputs" do

      expect(convert_url_to_filename('http://a/b/c')).to eql 'c'
      expect(convert_url_to_filename('http://a/b/c.mpeg')).to eql 'c.mpeg'

      expect(convert_url_to_filename('http://www.wntk.com/wntk.m3u')).to eql 'wntk.m3u'
      expect(convert_url_to_filename('http://stream.abacast.net/playlist/entercom-wrkoammp3-64.m3u')).to eql 'entercom-wrkoammp3-64.m3u'

    end

end

