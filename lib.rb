



def sanitize_filename(filename)

   filename.gsub(/[^0-9A-Za-z.\-_]/, '_')

end


# get the last segment in a url path
# def url_filename(url)
#
#   url.match(/([^\/]*)$/)[1]
#
# end

