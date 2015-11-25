
require_relative '../lib'




RSpec.describe PathManager do


  it 'requires args' do

    expect {
      PathManager.new()
    }.to raise_error /show/

    expect {
      PathManager.new(show:'abc show')
    }.to raise_error /stream/

    expect {
      PathManager.new(show:'abc show', 
                      stream:'http://wntk.com/wntkm3u')
    }.to raise_error /bucket/

    expect {
      PathManager.new(show:'abc show', 
                      stream:'http://wntk.com/wntkm3u', 
                      bucket:'podtastic')
    }.to raise_error /var/

    expect {
      PathManager.new(show:'abc show', 
                      stream:'http://wntk.com/wntkm3u', 
                      bucket:'podtastic',
                      var: '/tmp')
    }.to_not raise_error

  end


  it 'has initialized instance variables' do

    paths = PathManager.new(show:'the fu show', 
                            stream:'http://www.wntk.com/wntk.m3u',
                            bucket:'podtastic',
                            var:'/tmp')

    expect(paths.show).to eql 'the fu show'
    expect(paths.stream).to eql 'http://www.wntk.com/wntk.m3u'
    expect(paths.bucket).to eql 'podtastic'
    expect(paths.var).to eql '/tmp'

  end



  describe 'with initialized oject' do


    let(:paths){ 
      PathManager.new(show:'abc show', 
                      stream:'http://wntk.com/wntk.m3u', 
                      bucket:'podtastic',
                      var:'/tmp/podtastic') 
    }


    context 'private methods' do


      it 'sanitizes strings to be filenames' do

        expect(paths.send(:sanitize_filename, 'asdf')).to eql 'asdf'
        expect(paths.send(:sanitize_filename, 'a/sdf')).to eql 'a_sdf'
        expect(paths.send(:sanitize_filename, 'a|sdf')).to eql 'a_sdf'
        expect(paths.send(:sanitize_filename, 'a.sdf')).to eql 'a_sdf'

        before = 'http://www.wntk.com/wntk.m3u'
        after  = 'http___www_wntk_com_wntk_m3u' 
        expect(paths.send(:sanitize_filename, before)).to eql(after)

        before = 'http://stream.abacast.net/playlist/entercom-wrkoammp3-64.m3u'
        after  = 'http___stream_abacast_net_playlist_entercom_wrkoammp3_64_m3u' 
        expect(paths.send(:sanitize_filename, before)).to eql(after)

      end

      it 'returns a streams unique id' do
        key = 'http___wntk_com_wntk_m3u_abc_show'
        expect(paths.send(:show_key)).to eql key
      end

      it 'returns a streams local filename' do
        file = double(gets:'FILE "out.mp3" MP3')
        expect(File).to receive(:open).and_return(file)
        expect(paths.send(:streamed_filename)).to eql 'out.mp3'
      end

    end


    context 'public methods' do


      it 'returns unique tmp dur' do
        expect(paths.tmp_dir).to eql '/tmp/podtastic/http___wntk_com_wntk_m3u_abc_show'
      end


      it 'returns local path of streamed file' do

        file = double(gets:'FILE "out.mp3" MP3')
        expect(File).to receive(:open).and_return(file)

        expect(paths.streamed_filepath).to eql '/tmp/podtastic/http___wntk_com_wntk_m3u_abc_show/out.mp3'

      end


      it 'returns the stream bucket url' do

        file = double(gets:'FILE "out.mp3" MP3')
        expect(File).to receive(:open).with('/tmp/podtastic/http___wntk_com_wntk_m3u_abc_show/out.cue').and_return(file)

        url =  'https://s3.amazonaws.com/podtastic/http___wntk_com_wntk_m3u_abc_show.mp3'
        expect(paths.stream_bucket_url).to eql url

      end


      it 'returns a streams remote filename' do
        file = double(gets:'FILE "out.mp3" MP3')
        expect(File).to receive(:open).and_return(file)
        expect(paths.remote_filename).to eql 'http___wntk_com_wntk_m3u_abc_show.mp3'
      end


      it 'returns a streams remote file type' do
        file = double(gets:'FILE "out.mp3" MP3')
        expect(File).to receive(:open).and_return(file)
        expect(paths.stream_type).to eql 'MP3'
      end


    end


  end


end


