
require_relative '../lib'


RSpec.describe :sanitize_filename do

  it "works with various inputs" do
    expect(sanitize_filename('asdf')).to eql 'asdf'
    expect(sanitize_filename('a.sdf')).to eql 'a.sdf'
    expect(sanitize_filename('a sdf')).to eql 'a_sdf'
    expect(sanitize_filename('a/sdf')).to eql 'a_sdf'
    expect(sanitize_filename('a|sdf')).to eql 'a_sdf'
    expect(sanitize_filename('http://www.wntk.com/wntk.m3u')).to \
      eql 'http___www.wntk.com_wntk.m3u'
    expect(sanitize_filename('http://stream.abacast.net/playlist/entercom-wrkoammp3-64.m3u')).to \
      eql 'http___stream.abacast.net_playlist_entercom-wrkoammp3-64.m3u'
  end

end


# RSpec.describe :url_filename do
#
#     it "works with various inputs" do
#
#       expect(url_filename('http://a/b/c')).to eql 'c'
#       expect(url_filename('http://a/b/c.mpeg')).to eql 'c.mpeg'
#
#       expect(url_filename('http://www.wntk.com/wntk.m3u')).to eql 'wntk.m3u'
#       expect(url_filename('http://stream.abacast.net/playlist/entercom-wrkoammp3-64.m3u')).to eql 'entercom-wrkoammp3-64.m3u'
#
#     end
#
# end

