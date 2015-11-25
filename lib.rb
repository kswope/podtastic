

# Class for dealing with all the path hassles that are typical of this type of
# program

class PathManager

  attr_accessor :show, :stream, :bucket, :var

  def initialize(args={})

    # name of radio show
    self.show = args[:show]

    # stream of radio show
    self.stream = args[:stream]

    # S3 bucket we are using
    self.bucket = args[:bucket]

    # var area for streams and stuff
    self.var = args[:var]

    raise "show argument required" unless self.show
    raise "stream argument required" unless self.stream
    raise "bucket argument required" unless self.bucket
    raise "var argument required" unless self.var

    @timestamp = Time.now.to_i

  end


  def tmp_dir
    File.join(self.var, show_key)
  end


  def streamed_filepath
    File.join(tmp_dir, streamed_filename)
  end


  def remote_filename
    ext = File.extname(streamed_filename)
    [show_key, ext].join
  end


  def stream_bucket_url
    File.join("https://s3.amazonaws.com", self.bucket, remote_filename)
  end


  def stream_type
    File.open("#{self.tmp_dir}/out.cue").gets.match(/(\w*)$/)[1]
  end



  private # ~~~*~~~*~~~*~~~*~~~*~~~*~~~*~~~*~~~*~~~*~~~*~~~*~~~*~~~*~~~*~~~*


  def sanitize_filename(str)
    str = str.to_s
    str.gsub(/[^0-9A-Za-z]/, '_').downcase
  end


  def streamed_filename
    File.open("#{self.tmp_dir}/out.cue").gets.match(/^FILE \"(.*)\"/)[1]
  end


  # unique filename safe show identifier
  def show_key

    [
      sanitize_filename(self.stream), 
      sanitize_filename(self.show),
      sanitize_filename(@timestamp)
    ].join('_')

  end



end



